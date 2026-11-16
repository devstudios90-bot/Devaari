// devaari-chrome-polyfill.js
// Polyfills Chrome Extension APIs (Manifest V3) for iOS WKWebView environment in Devaari Browser

(function () {
  "use strict";

  if (window.chrome && window.chrome.runtime && window.chrome.runtime.id) {
    return; // Already polyfilled
  }

  // Pre-seed Lifetime License for TryAIToday Flow Automator (Code 9023)
  try {
    if (!localStorage.getItem("devaari_ext_promoLifetime")) {
      localStorage.setItem("devaari_ext_promoLifetime", JSON.stringify(true));
      localStorage.setItem("devaari_ext_promoCode", JSON.stringify("9023"));
      localStorage.setItem("devaari_ext_entOk", JSON.stringify(true));
      localStorage.setItem(
        "devaari_ext_promoUser",
        JSON.stringify({
          sub: "devaari_pro_user",
          name: "Devaari Pro User",
          email: "pro@devaari.app",
          ts: Date.now()
        })
      );
    }
  } catch (e) {
    console.warn("[Devaari] Failed to pre-seed license:", e);
  }

  const listeners = {
    runtimeMessage: [],
    storageChanged: [],
    downloadsChanged: [],
    downloadsDeterminingFilename: []
  };

  let callId = 0;
  const pendingPromises = new Map();

  // Global callback for native Swift bridge responses
  window.__devaariHandleResponse = function (msg) {
    if (!msg) return;
    if (msg.callId && pendingPromises.has(msg.callId)) {
      const { resolve, reject } = pendingPromises.get(msg.callId);
      pendingPromises.delete(msg.callId);
      if (msg.error) {
        reject(new Error(msg.error));
      } else {
        resolve(msg.result);
      }
    } else if (msg.type === "RUNTIME_MESSAGE") {
      listeners.runtimeMessage.forEach((fn) => {
        try {
          fn(msg.message, msg.sender || {}, (response) => {
            if (msg.replyId) {
              postNative({ type: "REPLY_MESSAGE", replyId: msg.replyId, response });
            }
          });
        } catch (e) {
          console.error("[Devaari Bridge] Runtime message handler error:", e);
        }
      });
    } else if (msg.type === "DOWNLOAD_COMPLETE") {
      listeners.downloadsChanged.forEach((fn) => {
        try {
          fn({
            id: msg.downloadId,
            state: { current: "complete", previous: "in_progress" }
          });
        } catch (e) {
          console.error("[Devaari Bridge] Download listener error:", e);
        }
      });
    }
  };

  function postNative(msg) {
    return new Promise((resolve, reject) => {
      const id = ++callId;
      msg.callId = id;
      pendingPromises.set(id, { resolve, reject });

      if (
        window.webkit &&
        window.webkit.messageHandlers &&
        window.webkit.messageHandlers.devaariBridge
      ) {
        window.webkit.messageHandlers.devaariBridge.postMessage(msg);
      } else {
        // Fallback simulation when running in standard browser/preview
        setTimeout(() => {
          if (pendingPromises.has(id)) {
            pendingPromises.delete(id);
            if (msg.type === "TABS_QUERY") {
              resolve([{ id: 1, active: true, url: "https://flow.google.com", title: "Google Flow" }]);
            } else if (msg.type === "EXECUTE_SCRIPT") {
              resolve([{ result: null }]);
            } else {
              resolve(null);
            }
          }
        }, 10);
      }
    });
  }

  // Storage Implementation backed by localStorage + synced with native
  const storageArea = {
    get: function (keys) {
      return new Promise((resolve) => {
        let result = {};
        let targetKeys = [];
        if (typeof keys === "string") {
          targetKeys = [keys];
        } else if (Array.isArray(keys)) {
          targetKeys = keys;
        } else if (keys && typeof keys === "object") {
          targetKeys = Object.keys(keys);
          result = { ...keys };
        } else if (!keys) {
          for (let i = 0; i < localStorage.length; i++) {
            const k = localStorage.key(i);
            if (k && k.startsWith("devaari_ext_")) {
              targetKeys.push(k.replace("devaari_ext_", ""));
            }
          }
        }

        targetKeys.forEach((k) => {
          const raw = localStorage.getItem("devaari_ext_" + k);
          if (raw !== null) {
            try {
              result[k] = JSON.parse(raw);
            } catch {
              result[k] = raw;
            }
          }
        });
        resolve(result);
      });
    },
    set: function (items) {
      return new Promise((resolve) => {
        if (items && typeof items === "object") {
          Object.entries(items).forEach(([k, v]) => {
            localStorage.setItem("devaari_ext_" + k, JSON.stringify(v));
          });
          postNative({ type: "STORAGE_SET", items }).catch(() => {});
        }
        resolve();
      });
    },
    remove: function (keys) {
      return new Promise((resolve) => {
        const targetKeys = Array.isArray(keys) ? keys : [keys];
        targetKeys.forEach((k) => {
          localStorage.removeItem("devaari_ext_" + k);
        });
        postNative({ type: "STORAGE_REMOVE", keys: targetKeys }).catch(() => {});
        resolve();
      });
    },
    clear: function () {
      return new Promise((resolve) => {
        for (let i = localStorage.length - 1; i >= 0; i--) {
          const k = localStorage.key(i);
          if (k && k.startsWith("devaari_ext_")) {
            localStorage.removeItem(k);
          }
        }
        postNative({ type: "STORAGE_CLEAR" }).catch(() => {});
        resolve();
      });
    }
  };

  window.chrome = {
    runtime: {
      id: "devaari-flow-automator",
      lastError: null,
      getURL: function (path) {
        return path;
      },
      sendMessage: function (msg, callback) {
        const p = postNative({ type: "RUNTIME_SEND_MESSAGE", message: msg });
        if (callback) {
          p.then((res) => callback(res)).catch((err) => {
            window.chrome.runtime.lastError = err;
            callback(null);
          });
          return;
        }
        return p;
      },
      onMessage: {
        addListener: function (fn) {
          listeners.runtimeMessage.push(fn);
        },
        removeListener: function (fn) {
          const idx = listeners.runtimeMessage.indexOf(fn);
          if (idx >= 0) listeners.runtimeMessage.splice(idx, 1);
        }
      },
      onInstalled: {
        addListener: function (fn) {
          setTimeout(fn, 50);
        }
      }
    },
    storage: {
      local: storageArea,
      sync: storageArea
    },
    sidePanel: {
      setPanelBehavior: async function () {
        return true;
      },
      open: async function () {
        return true;
      }
    },
    tabs: {
      query: async function (queryInfo) {
        const tabInfo = await postNative({ type: "TABS_QUERY", query: queryInfo });
        if (tabInfo && tabInfo.id) {
          return [tabInfo];
        }
        return [{ id: 1, active: true, url: "https://flow.google.com", title: "Google Flow" }];
      },
      get: async function (tabId) {
        const tabInfo = await postNative({ type: "TABS_GET", tabId });
        return tabInfo || { id: tabId, active: true, url: "https://flow.google.com", title: "Google Flow" };
      },
      update: async function (tabId, updateProps) {
        return postNative({ type: "TABS_UPDATE", tabId, updateProps });
      },
      create: async function (createProps) {
        return postNative({ type: "TABS_CREATE", createProps });
      },
      sendMessage: async function (tabId, message) {
        return postNative({ type: "TABS_SEND_MESSAGE", tabId, message });
      }
    },
    scripting: {
      executeScript: async function ({ target, world, func, args = [] }) {
        let scriptToRun;
        if (typeof func === "function") {
          const funcStr = func.toString();
          const argsJson = JSON.stringify(args);
          scriptToRun = `(async function() { try { return await (${funcStr})(...${argsJson}); } catch(e) { return { __devaariErr: e.message || String(e) }; } })()`;
        } else if (typeof func === "string") {
          scriptToRun = func;
        }
        const result = await postNative({
          type: "EXECUTE_SCRIPT",
          tabId: target?.tabId,
          world: world || "MAIN",
          script: scriptToRun
        });
        if (result && result.__devaariErr) {
          throw new Error(result.__devaariErr);
        }
        return [{ result }];
      }
    },
    identity: {
      getRedirectURL: function () {
        return "https://devaari.browser.app/oauth2";
      },
      launchWebAuthFlow: async function ({ url, interactive }) {
        const res = await postNative({ type: "LAUNCH_AUTH_FLOW", url, interactive });
        return res;
      }
    },
    downloads: {
      download: async function (options, callback) {
        const result = await postNative({ type: "DOWNLOAD_FILE", options });
        if (callback) callback(result);
        return result;
      },
      search: async function (query, callback) {
        const result = await postNative({ type: "DOWNLOAD_SEARCH", query });
        const list = Array.isArray(result) ? result : [];
        if (callback) callback(list);
        return list;
      },
      removeFile: async function (id, callback) {
        await postNative({ type: "DOWNLOAD_REMOVE", id });
        if (callback) callback();
      },
      erase: async function (query, callback) {
        await postNative({ type: "DOWNLOAD_ERASE", query });
        if (callback) callback([]);
      },
      onDeterminingFilename: {
        addListener: function (fn) {
          listeners.downloadsDeterminingFilename.push(fn);
        }
      },
      onChanged: {
        addListener: function (fn) {
          listeners.downloadsChanged.push(fn);
        }
      }
    }
  };

  console.log("[Devaari] Chrome extension polyfill initialized successfully.");
})();
