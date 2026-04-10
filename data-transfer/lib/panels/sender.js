function renderSenderPanelHtml() {
  return `
            <div style="display:flex;align-items:center;margin-bottom:10px;">
            <button type="button" title="Menú" aria-label="Menú"
            style="padding:10px 14px;font-size:22px;margin-right:10px;color:#111;background:#f5f5f5;border:1px solid #bbb;border-radius:6px;cursor:pointer;box-sizing:border-box;line-height:1;"
            onclick="senderToggleMenu()">☰</button>
            <h3 style="margin:0;font-size:28px;color:#111;"><button type="button" style="display:inline;background:none;border:none;padding:0;font:inherit;cursor:pointer;color:#111;" onclick="dtShowTab('home')">Data transfer</button> · Sender</h3>
            </div>

            <div id="senderMenu" style="display:none;margin-bottom:10px;">
            <button type="button" style="width:100%;padding:15px;font-size:18px;margin-bottom:10px;color:#111;background:#f5f5f5;border:1px solid #ccc;border-radius:6px;cursor:pointer;text-align:left;box-sizing:border-box;"
            onclick="dtShowTab('home')">Inicio</button>

            <button type="button" style="width:100%;padding:15px;font-size:18px;margin-bottom:10px;color:#111;background:#f5f5f5;border:1px solid #ccc;border-radius:6px;cursor:pointer;text-align:left;box-sizing:border-box;"
            onclick="document.getElementById('senderFileInput').click()">Elegir archivo</button>
            <input type="file" id="senderFileInput" style="display:none">

            <button type="button" style="width:100%;padding:15px;font-size:18px;margin-bottom:10px;color:#111;background:#f5f5f5;border:1px solid #ccc;border-radius:6px;cursor:pointer;text-align:left;box-sizing:border-box;"
            onclick="sendFileOut()">Subir → out/</button>

            <button type="button" style="width:100%;padding:15px;font-size:18px;margin-bottom:10px;color:#111;background:#e8f5e9;border:1px solid #81c784;border-radius:6px;cursor:pointer;text-align:left;box-sizing:border-box;"
            onclick="sendFileIncoming()">Subir → incoming/ (debug-pack)</button>
            </div>

            <p style="margin:0 0 6px 0;font-size:12px;color:#555;line-height:1.35;">Subida por streaming (sin cargar todo en RAM en el cliente). <code>incoming/</code> siempre usa nombre único. Cabecera opcional <code>X-DT-Stable-Name: 1</code> en <code>out/</code> restaura nombre fijo (sobrescribe).</p>
            <textarea id="senderData" style="display:block;width:100%;min-height:200px;height:min(55vh,480px);font-size:16px;padding:12px;border:1px solid #ccc;border-radius:6px;box-sizing:border-box;color:#111;background:#fff;"></textarea><br>
            <input type="file" id="senderPasteFile" style="display:none">

            <button type="button" style="width:100%;padding:14px;font-size:16px;margin-bottom:10px;color:#111;background:#f5f5f5;border:1px solid #ccc;border-radius:6px;cursor:pointer;text-align:left;box-sizing:border-box;"
            onclick="send()">Enviar texto</button>

            <button type="button" style="width:100%;padding:15px;font-size:18px;margin-top:10px;text-align:left;color:#111;background:#f5f5f5;border:1px solid #ccc;border-radius:6px;cursor:pointer;box-sizing:border-box;"
            onclick="clearBox()">Vaciar</button>

            <button type="button" style="width:100%;padding:15px;font-size:18px;margin-top:10px;text-align:left;color:#111;background:#f5f5f5;border:1px solid #ccc;border-radius:6px;cursor:pointer;box-sizing:border-box;"
            onclick="dtShowTab('reader')">Reader</button>

            <a href="#" onclick="dtShowTab('home');return false;" style="position:fixed;bottom:20px;right:20px;background:#222;color:#fff;width:52px;height:52px;border-radius:50%;display:flex;align-items:center;justify-content:center;font-size:26px;text-decoration:none;box-shadow:0 2px 8px rgba(0,0,0,.2);z-index:9999;">🏠</a>

        <script>
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

        function uploadBlob(url, f, extraHeaders) {
          var h = Object.assign({ 'x-filename': f.name || 'upload.bin' }, extraHeaders || {});
          return fetch(url, { method: 'POST', headers: h, body: f }).then(function(r) {
            return r.text().then(function(t) {
              if (!r.ok) throw new Error(t || r.status);
              return t;
            });
          });
        }

        document.addEventListener('paste', function(e) {
        if (e.clipboardData && e.clipboardData.files.length > 0) {
            const f = e.clipboardData.files[0];
            uploadBlob('/upload', f).then(alert).catch(function(err) { alert(err.message || String(err)); });
        }
        });

        function sendFileOut(){
          const f = document.getElementById('senderFileInput').files[0];
          if(!f){ alert('Sin archivo'); return; }
          uploadBlob('/upload', f).then(alert).catch(function(err) { alert(err.message || String(err)); });
        }

        function sendFileIncoming(){
          const f = document.getElementById('senderFileInput').files[0];
          if(!f){ alert('Sin archivo'); return; }
          uploadBlob('/incoming', f).then(alert).catch(function(err) { alert(err.message || String(err)); });
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
