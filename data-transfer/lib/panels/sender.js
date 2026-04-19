const { senderClientPack } = require('../ui-lang');

function renderSenderPanelHtml(lang) {
  const t = senderClientPack(lang);
  const packJson = JSON.stringify(t).replace(/</g, '\\u003c');
  return `
            <script>window.__DT_SENDER__=${packJson};</script>
            <div style="display:flex;align-items:center;margin-bottom:10px;">
            <button type="button" title="${t.menuTitle}" aria-label="${t.menuAria}"
            style="padding:10px 14px;font-size:22px;margin-right:10px;color:#111;background:#f5f5f5;border:1px solid #bbb;border-radius:6px;cursor:pointer;box-sizing:border-box;line-height:1;"
            onclick="senderToggleMenu()">☰</button>
            <h3 style="margin:0;font-size:28px;color:#111;"><button type="button" style="display:inline;background:none;border:none;padding:0;font:inherit;cursor:pointer;color:#111;" onclick="dtShowTab('home')">Data transfer</button> · Sender</h3>
            </div>

            <div id="senderMenu" style="display:none;margin-bottom:10px;">
            <button type="button" style="width:100%;padding:15px;font-size:18px;margin-bottom:10px;color:#111;background:#f5f5f5;border:1px solid #ccc;border-radius:6px;cursor:pointer;text-align:left;box-sizing:border-box;"
            onclick="dtShowTab('home')">${t.home}</button>

            <button type="button" style="width:100%;padding:15px;font-size:18px;margin-bottom:10px;color:#111;background:#f5f5f5;border:1px solid #ccc;border-radius:6px;cursor:pointer;text-align:left;box-sizing:border-box;"
            onclick="document.getElementById('senderFileInput').click()">${t.pickFile}</button>
            <input type="file" id="senderFileInput" style="display:none">

            <button type="button" style="width:100%;padding:15px;font-size:18px;margin-bottom:10px;color:#111;background:#f5f5f5;border:1px solid #ccc;border-radius:6px;cursor:pointer;text-align:left;box-sizing:border-box;"
            onclick="sendFileOut()">${t.uploadOut}</button>

            <button type="button" style="width:100%;padding:15px;font-size:18px;margin-bottom:10px;color:#111;background:#e8f5e9;border:1px solid #81c784;border-radius:6px;cursor:pointer;text-align:left;box-sizing:border-box;"
            onclick="sendFileIncoming()">${t.uploadIncoming}</button>
            </div>

            <p style="margin:0 0 6px 0;font-size:12px;color:#555;line-height:1.35;">${t.hint}</p>
            <div id="senderDropZone" title="${t.dropTitle}"
            style="margin:0 0 10px 0;padding:14px;border:2px dashed #aaa;border-radius:8px;text-align:center;font-size:14px;color:#444;cursor:pointer;background:#fafafa;">
            ${t.dropLine}</div>
            <div id="dtUploadProgressWrap" style="display:none;margin:0 0 10px 0;">
              <div style="height:10px;background:#ddd;border-radius:5px;overflow:hidden;">
                <div id="dtUploadProgressBar" style="height:100%;width:0;background:#2e7d32;transition:width .12s;"></div>
              </div>
              <div id="dtUploadProgressTxt" style="font-size:12px;color:#555;margin-top:4px;"></div>
            </div>
            <textarea id="senderData" style="display:block;width:100%;min-height:200px;height:min(55vh,480px);font-size:16px;padding:12px;border:1px solid #ccc;border-radius:6px;box-sizing:border-box;color:#111;background:#fff;"></textarea><br>
            <input type="file" id="senderPasteFile" style="display:none">

            <button type="button" style="width:100%;padding:14px;font-size:16px;margin-bottom:10px;color:#111;background:#f5f5f5;border:1px solid #ccc;border-radius:6px;cursor:pointer;text-align:left;box-sizing:border-box;"
            onclick="send()">${t.sendText}</button>

            <button type="button" style="width:100%;padding:15px;font-size:18px;margin-top:10px;text-align:left;color:#111;background:#f5f5f5;border:1px solid #ccc;border-radius:6px;cursor:pointer;box-sizing:border-box;"
            onclick="clearBox()">${t.clear}</button>

            <button type="button" style="width:100%;padding:15px;font-size:18px;margin-top:10px;text-align:left;color:#111;background:#f5f5f5;border:1px solid #ccc;border-radius:6px;cursor:pointer;box-sizing:border-box;"
            onclick="dtShowTab('reader')">Reader</button>

            <a href="#" onclick="dtShowTab('home');return false;" style="position:fixed;bottom:20px;right:20px;background:#222;color:#fff;width:52px;height:52px;border-radius:50%;display:flex;align-items:center;justify-content:center;font-size:26px;text-decoration:none;box-shadow:0 2px 8px rgba(0,0,0,.2);z-index:9999;">🏠</a>

        <script>
        function senderI18n() { return window.__DT_SENDER__ || {}; }
        var DT_SENDER_DRAFT_KEY = 'dataTransferSenderDraft';
        function senderToggleMenu() {
          const m = document.getElementById('senderMenu');
          m.style.display = m.style.display === 'none' ? 'block' : 'none';
        }

        function senderRestoreDraft() {
          try {
            var ta = document.getElementById('senderData');
            if (!ta) return;
            var s = localStorage.getItem(DT_SENDER_DRAFT_KEY);
            if (s != null && s !== '') ta.value = s;
          } catch (e) {}
        }

        var senderSaveDraftTm = null;
        function senderSaveDraft() {
          try {
            var ta = document.getElementById('senderData');
            if (!ta) return;
            localStorage.setItem(DT_SENDER_DRAFT_KEY, ta.value);
          } catch (e) {}
        }

        function senderScheduleSaveDraft() {
          clearTimeout(senderSaveDraftTm);
          senderSaveDraftTm = setTimeout(senderSaveDraft, 400);
        }

        senderRestoreDraft();
        (function senderBindDraft() {
          var ta = document.getElementById('senderData');
          if (!ta) return;
          ta.addEventListener('input', senderScheduleSaveDraft);
          ta.addEventListener('blur', senderSaveDraft);
        })();

        function dtShowUploadProgress(show) {
          var w = document.getElementById('dtUploadProgressWrap');
          if (w) w.style.display = show ? 'block' : 'none';
          var bar = document.getElementById('dtUploadProgressBar');
          if (bar) bar.style.width = '0';
          var tx = document.getElementById('dtUploadProgressTxt');
          if (tx) tx.textContent = '';
        }
        function dtSetUploadProgress(loaded, total) {
          var bar = document.getElementById('dtUploadProgressBar');
          var tx = document.getElementById('dtUploadProgressTxt');
          var i = senderI18n();
          if (!bar || !tx) return;
          var pct = total > 0 ? Math.min(100, Math.round((100 * loaded) / total)) : 0;
          bar.style.width = pct + '%';
          tx.textContent = total > 0 ? (pct + '% · ' + Math.round(loaded / 1024) + ' / ' + Math.round(total / 1024) + ' KiB') : (i.uploading || '');
        }

        function uploadBlobWithProgress(url, f, extraHeaders) {
          var i = senderI18n();
          var h = Object.assign({ 'x-filename': f.name || 'upload.bin' }, extraHeaders || {});
          return new Promise(function(resolve, reject) {
            var xhr = new XMLHttpRequest();
            xhr.open('POST', url);
            Object.keys(h).forEach(function(k) {
              xhr.setRequestHeader(k, h[k]);
            });
            xhr.upload.onprogress = function(ev) {
              if (ev.lengthComputable) dtSetUploadProgress(ev.loaded, ev.total);
            };
            xhr.onload = function() {
              var t = xhr.responseText || '';
              if (xhr.status >= 200 && xhr.status < 300) resolve(t);
              else reject(new Error(t || String(xhr.status)));
            };
            xhr.onerror = function() {
              reject(new Error(i.netErr || 'Network error'));
            };
            xhr.send(f);
          });
        }

        function uploadFileTo(url, f, okMsg) {
          dtShowUploadProgress(true);
          dtSetUploadProgress(0, f.size || 1);
          uploadBlobWithProgress(url, f, {})
            .then(function(t) {
              dtShowUploadProgress(false);
              alert(okMsg || t);
            })
            .catch(function(err) {
              dtShowUploadProgress(false);
              alert(err.message || String(err));
            });
        }

        document.addEventListener('paste', function(e) {
          if (e.clipboardData && e.clipboardData.files.length > 0) {
            const f = e.clipboardData.files[0];
            uploadFileTo('/upload', f);
          }
        });

        (function senderDropZoneInit() {
          var z = document.getElementById('senderDropZone');
          var inp = document.getElementById('senderFileInput');
          if (!z || !inp) return;
          z.addEventListener('click', function() { inp.click(); });
          ['dragenter', 'dragover'].forEach(function(ev) {
            z.addEventListener(ev, function(e) {
              e.preventDefault();
              e.stopPropagation();
              z.style.background = '#e3f2fd';
              z.style.borderColor = '#1976d2';
            });
          });
          z.addEventListener('dragleave', function(e) {
            e.preventDefault();
            z.style.background = '#fafafa';
            z.style.borderColor = '#aaa';
          });
          z.addEventListener('drop', function(e) {
            e.preventDefault();
            e.stopPropagation();
            z.style.background = '#fafafa';
            z.style.borderColor = '#aaa';
            var f = e.dataTransfer && e.dataTransfer.files && e.dataTransfer.files[0];
            if (!f) return;
            uploadFileTo('/upload', f);
          });
        })();

        function sendFileOut(){
          var i = senderI18n();
          const f = document.getElementById('senderFileInput').files[0];
          if(!f){ alert(i.noFile || ''); return; }
          uploadFileTo('/upload', f);
        }

        function sendFileIncoming(){
          var i = senderI18n();
          const f = document.getElementById('senderFileInput').files[0];
          if(!f){ alert(i.noFile || ''); return; }
          uploadFileTo('/incoming', f);
        }

        function send() {
          fetch('/sfs', {
            method: 'POST',
            headers: { 'Content-Type': 'text/plain; charset=utf-8' },
            body: document.getElementById('senderData').value
          }).then(function(r) {
            return r.text().then(function(t) {
              if (!r.ok) throw new Error(t || r.status);
              alert(t);
            });
          }).catch(function(err) { alert(err.message || String(err)); });
        }

        function clearBox() {
          try {
            var ta = document.getElementById('senderData');
            if (ta) ta.value = '';
            localStorage.removeItem(DT_SENDER_DRAFT_KEY);
          } catch (e) {
            document.getElementById('senderData').value = '';
          }
        }
        </script>
  `;
}

module.exports = { renderSenderPanelHtml };
