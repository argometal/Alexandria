const { readerClientPack } = require('../ui-lang');

function renderReaderPanelHtml(lang) {
  const t = readerClientPack(lang);
  const packJson = JSON.stringify(t).replace(/</g, '\\u003c');
  return `
            <script>window.__DT_READER__=${packJson};</script>
            <div style="display:flex;align-items:center;margin-bottom:10px;flex-wrap:wrap;gap:8px;">
            <button type="button" title="${t.menuTitle}" aria-label="${t.menuAria}"
            style="padding:10px 14px;font-size:22px;margin-right:10px;color:#111;background:#f5f5f5;border:1px solid #bbb;border-radius:6px;cursor:pointer;box-sizing:border-box;line-height:1;"
            onclick="readerToggleMenu()">☰</button>
            <h3 style="margin:0;font-size:28px;color:#111;"><button type="button" style="display:inline;background:none;border:none;padding:0;font:inherit;cursor:pointer;color:#111;" onclick="dtShowTab('home')">Data transfer</button> · Reader</h3>
            </div>

            <div style="margin-bottom:10px;font-size:14px;">
              <label style="margin-right:8px;color:#333;">${t.folderLabel}</label>
              <select id="dtReaderBucket" onchange="readerSetBucket(this.value)" style="font-size:15px;padding:6px 10px;border-radius:6px;border:1px solid #ccc;">
                <option value="out">${t.optOutFast}</option>
                <option value="incoming">${t.optIncoming}</option>
              </select>
            </div>

            <div id="readerMenu" style="display:none;margin-bottom:10px;">
            <button type="button" style="width:100%;padding:15px;font-size:18px;margin-bottom:10px;color:#111;background:#f5f5f5;border:1px solid #ccc;border-radius:6px;cursor:pointer;text-align:left;box-sizing:border-box;"
            onclick="dtShowTab('home')">${t.home}</button>

            <button type="button" style="width:100%;padding:15px;font-size:18px;margin-bottom:10px;color:#111;background:#f5f5f5;border:1px solid #ccc;border-radius:6px;cursor:pointer;text-align:left;box-sizing:border-box;"
            onclick="loadFiles()">${t.refreshList}</button>
            </div>

            <button type="button" style="width:100%;padding:14px;font-size:16px;margin-bottom:10px;color:#111;background:#f5f5f5;border:1px solid #ccc;border-radius:6px;cursor:pointer;text-align:left;box-sizing:border-box;"
            onclick="loadFiles()">${t.refreshFiles}</button>

            <ul id="readerFiles" style="list-style:none;padding:0;margin:0 0 10px 0;max-height:min(220px,35vh);overflow-y:auto;"></ul>

            <textarea id="readerViewer" style="width:100%;min-height:200px;height:min(55vh,480px);font-size:16px;color:#111;background:#fff;border:1px solid #ccc;border-radius:6px;box-sizing:border-box;padding:8px;"></textarea><br>

            <button type="button" style="width:100%;padding:15px;font-size:18px;margin-top:10px;text-align:left;color:#111;background:#f5f5f5;border:1px solid #ccc;border-radius:6px;cursor:pointer;box-sizing:border-box;"
            onclick="window.scrollTo({top:0,behavior:'smooth'})">${t.top}</button>

            <button type="button" style="width:100%;padding:15px;font-size:18px;margin-top:10px;text-align:left;color:#111;background:#f5f5f5;border:1px solid #ccc;border-radius:6px;cursor:pointer;box-sizing:border-box;"
            onclick="dtShowTab('sender')">Sender</button>

            <a href="#" onclick="dtShowTab('home');return false;" style="position:fixed;bottom:20px;right:20px;background:#222;color:#fff;width:52px;height:52px;border-radius:50%;display:flex;align-items:center;justify-content:center;font-size:26px;text-decoration:none;box-shadow:0 2px 8px rgba(0,0,0,.2);z-index:9999;">🏠</a>

            <script>
            function readerToggleMenu() {
            const m = document.getElementById('readerMenu');
            m.style.display = m.style.display === 'none' ? 'block' : 'none';
            }
            </script>

            <script>
            let activeFileName = null;
            var READER_POLL_MS = 8000;
            var readerBucket = 'out';

            function readerI18n() {
              return window.__DT_READER__ || {};
            }

            function readerApiBase() {
              return '/files?bucket=' + encodeURIComponent(readerBucket);
            }

            function readerSetBucket(b) {
              readerBucket = b === 'incoming' ? 'incoming' : 'out';
              try {
                var u = new URL(location.href);
                u.searchParams.set('bucket', readerBucket);
                if (history.replaceState) history.replaceState(null, '', u.pathname + u.search);
              } catch (e) {}
              activeFileName = null;
              loadFiles();
            }

            async function loadFiles() {
            const res = await fetch(readerApiBase());
            const files = await res.json();
            const ul = document.getElementById('readerFiles');
            const i = readerI18n();
            ul.innerHTML = '';
            var show = files.slice(0, 12);
            show.forEach(name => {
              const li = document.createElement('li');
              li.style.marginBottom = '10px';

              const btn = document.createElement('button');
              btn.style.width = '100%';
              btn.style.padding = '12px';
              btn.style.fontSize = '16px';
              btn.style.textAlign = 'left';
              btn.style.color = '#111';
              btn.style.border = '1px solid #ccc';
              btn.style.borderRadius = '6px';
              btn.style.cursor = 'pointer';
              btn.style.background = activeFileName === name ? '#e3f2fd' : '#f5f5f5';
              btn.textContent = name;
              btn.onclick = (ev) => openFile(name, ev.currentTarget);

              const dl = document.createElement('button');
              dl.style.width = '100%';
              dl.style.padding = '10px';
              dl.style.fontSize = '14px';
              dl.style.marginTop = '6px';
              dl.style.textAlign = 'left';
              dl.style.color = '#111';
              dl.style.border = '1px solid #ccc';
              dl.style.borderRadius = '6px';
              dl.style.cursor = 'pointer';
              dl.style.background = '#f5f5f5';
              dl.textContent = (i.downloadPrefix || 'Download ') + name;
              dl.onclick = () => location.href = '/download?name=' + encodeURIComponent(name) + '&bucket=' + encodeURIComponent(readerBucket);

              li.appendChild(btn);
              li.appendChild(dl);
              ul.appendChild(li);
            });
            if (files.length > 12) {
              var more = document.createElement('li');
              more.style.fontSize = '12px';
              more.style.color = '#666';
              more.style.padding = '6px';
              more.textContent = (i.morePrefix || '…') + (files.length - 12) + (i.moreSuffix || '');
              ul.appendChild(more);
            }
          }

          async function openFile(name, sourceBtn) {
            const res = await fetch('/read?name=' + encodeURIComponent(name) + '&bucket=' + encodeURIComponent(readerBucket));
            const text = await res.text();
            document.getElementById('readerViewer').value = text;
            activeFileName = name;
            document.querySelectorAll('#readerFiles button').forEach(b => {
              b.style.background = '#f5f5f5';
              b.style.color = '#111';
            });
            if (sourceBtn) {
              sourceBtn.style.background = '#e3f2fd';
              sourceBtn.style.color = '#111';
            }
          }

          async function bootReader() {
            try {
              var u = new URL(location.href);
              var b = u.searchParams.get('bucket');
              if (b === 'incoming') {
                readerBucket = 'incoming';
                var sel = document.getElementById('dtReaderBucket');
                if (sel) sel.value = 'incoming';
              }
            } catch (e) {}
            const files = await fetch(readerApiBase()).then(r => r.json());
            if (files.length > 0) {
              await openFile(files[0]);
            }
            loadFiles();
            try {
              const p = new URLSearchParams(window.location.search || '');
              const openName = p.get('open');
              if (openName) {
                await openFile(openName);
              }
            } catch (e) {}
          }

            bootReader();
            setInterval(loadFiles, READER_POLL_MS);

          </script>
  `;
}

module.exports = { renderReaderPanelHtml };
