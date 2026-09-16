const statusEl = document.getElementById("status");
const syncButton = document.getElementById("sync-button");

async function runSync() {
  statusEl.textContent = "Syncing…";
  syncButton.disabled = true;
  try {
    await browser.runtime.sendMessage({ type: "requestSync" });
    statusEl.textContent = "Synced just now.";
  } catch (error) {
    statusEl.textContent = `Sync failed: ${error.message}`;
  } finally {
    syncButton.disabled = false;
  }
}

syncButton.addEventListener("click", runSync);
runSync();
