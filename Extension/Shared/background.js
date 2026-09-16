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

// Rebuilding the whole tree from scratch (remove-all + recreate) would blow away Safari's
// own IDs and any state that isn't modeled here; a real diff/merge against the existing
// tree is a known TODO — see README "Known limitations".
async function applyFolderDiff(_targetFolder) {
  throw new Error("applyFolderDiff is not implemented yet — see README Known limitations");
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
