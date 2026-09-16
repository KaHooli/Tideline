// Bridges Safari's live bookmark tree (browser.bookmarks) to the Tideline app, which
// cannot read Safari's bookmarks on its own. Native messaging is routed automatically to
// the containing app's SafariWebExtensionHandler — no host manifest is needed, unlike
// Chrome/Firefox native messaging.
//
// NOTE: verify `background.service_worker` is the correct key for this WebKit/Safari
// version — Safari's MV3 background execution model has shifted between releases, and
// this hasn't been run against an actual Safari build yet (see project README).

async function syncTreeToApp() {
  const [rootNode] = await browser.bookmarks.getTree();
  const folder = toTidelineFolder(rootNode);
  return browser.runtime.sendNativeMessage("tideline", {
    type: "syncSnapshot",
    folder
  });
}

// browser.bookmarks nodes use {id, title, url?, children?}; Tideline's BookmarkFolder /
// BookmarkNode Codable shape distinguishes folders from bookmarks explicitly.
function toTidelineFolder(node) {
  return {
    id: node.id,
    title: node.title || "Untitled",
    children: (node.children || []).map(toTidelineNode)
  };
}

function toTidelineNode(node) {
  if (node.url) {
    return {
      bookmark: {
        id: node.id,
        title: node.title || node.url,
        url: node.url,
        dateAdded: node.dateAdded ? new Date(node.dateAdded).toISOString() : new Date().toISOString(),
        tags: [],
        parentFolderID: node.parentId ?? null
      }
    };
  }
  return { folder: toTidelineFolder(node) };
}

async function applyPendingOperations(operations) {
  for (const operation of operations) {
    if (operation.deleteBookmark) {
      await browser.bookmarks.remove(operation.deleteBookmark.id);
    } else if (operation.replaceTree) {
      await applyFolderDiff(operation.replaceTree);
    }
  }
}

// Applies a synthesized folder tree (as produced by TidelineCore's FolderSorter) on top
// of Safari's real bookmarks. FolderSorter never changes a Bookmark's id — it only
// regroups existing bookmarks into brand-new folders — so every `bookmark` node here is
// assumed to reference a real, existing Safari bookmark, and every `folder` node is new.
// That means the diff only ever needs to CREATE folders and MOVE existing bookmarks into
// them; it never deletes or recreates a bookmark, which would lose Safari's own bookmark
// id and any per-bookmark state (e.g. cached favicon) that isn't modeled here.
//
// This does NOT delete the (now likely empty) folders bookmarks were moved out of —
// deleting folders is destructive and, unlike creating/moving, isn't easily undone if a
// folder held something this sync missed. Left-behind empty folders are a cosmetic
// cleanup the user can do in Safari; a "delete empty folders" pass could be added later
// as an explicit, separate, user-confirmed operation.
//
// Where the new top-level folder gets created is unverified: Safari's real tree root
// (`getTree()[0].id`) usually isn't a valid `parentId` for `bookmarks.create` in
// WebExtension implementations, so this targets the root's first child instead (normally
// the bookmarks bar / Favorites). Confirm this against a real Safari install — if the
// sorted folder lands somewhere unexpected, this is the place to fix.
async function applyFolderDiff(targetFolder) {
  const [root] = await browser.bookmarks.getTree();
  const topLevelParentId = root.children?.[0]?.id ?? root.id;
  await createFolderContents(targetFolder, topLevelParentId);
}

async function createFolderContents(folderSnapshot, parentId) {
  const created = await browser.bookmarks.create({
    parentId,
    title: folderSnapshot.title
  });

  for (const node of folderSnapshot.children) {
    if (node.folder) {
      await createFolderContents(node.folder, created.id);
    } else if (node.bookmark) {
      await browser.bookmarks.move(node.bookmark.id, { parentId: created.id });
    }
  }
}

// Full sync cycle, run on popup open and on demand: drain whatever the app queued up
// while the extension wasn't running, apply it to Safari's real bookmarks, clear the
// queue, then push a fresh snapshot back to the app.
async function syncNow() {
  const { operations } = await browser.runtime.sendNativeMessage("tideline", {
    type: "fetchPendingOperations"
  });

  if (operations?.length) {
    await applyPendingOperations(operations);
    await browser.runtime.sendNativeMessage("tideline", { type: "clearPendingOperations" });
  }

  return syncTreeToApp();
}

browser.runtime.onMessage.addListener((message) => {
  if (message?.type === "requestSync") {
    return syncNow();
  }
});

browser.bookmarks.onCreated.addListener(() => syncTreeToApp());
browser.bookmarks.onRemoved.addListener(() => syncTreeToApp());
browser.bookmarks.onChanged.addListener(() => syncTreeToApp());
browser.bookmarks.onMoved.addListener(() => syncTreeToApp());
