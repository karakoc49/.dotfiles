#!/usr/bin/env python3
"""Kapanan Claude Code oturumunun HAM transkriptini Obsidian notuna yazar.

Kullanim: obsidian_transcript.py <session_id> <transcript_path> <cwd>

Hicbir LLM cagrisi yapmaz. Baslik, transkriptin icindeki `ai-title` kaydindan
gelir (oturum sirasinda Claude Code zaten uretmistir). Mesaj ve arac icerikleri
KIRPILMAZ. PR bilgisi `pr-link` kayitlarindan okunur, PR basligi once transkriptteki
`gh pr create --title` cagrisindan, bulunamazsa `gh pr view` ile tamamlanir.
"""
import base64
import json
import os
import re
import subprocess
import sys
import time
import unicodedata
from datetime import datetime, timezone

# --- Ayarlar ---------------------------------------------------------------
# Iki yol da env ile ezilebilir — kuru calistirma/test icin (varsayilan: gercek vault).
VAULT_DIR = os.environ.get("OBSIDIAN_DUMP_VAULT") or os.path.expanduser("~/myhub/Claude")
BASE_DIR = os.environ.get("OBSIDIAN_DUMP_BASE") or os.path.expanduser("~/.claude/obsidian-dump")
STATE = os.path.join(BASE_DIR, "state-raw.tsv")
LOCK_DIR = os.path.join(BASE_DIR, "state-raw.lock")
# Notlar ay klasorune yazilir; up zinciri: oturum -> ay MOC'u -> [[Claude]] -> [[HOME]]
UP_NOTE = "[[Claude]]"
TR_MONTHS = ["Ocak", "Şubat", "Mart", "Nisan", "Mayıs", "Haziran",
             "Temmuz", "Ağustos", "Eylül", "Ekim", "Kasım", "Aralık"]

# Katmanli tag: type/ notun turu (oturum notlari icin hep type/session),
# topic/ ise neyle ilgili oldugu. Ikisi de KURAL BAZLI turetilir — LLM yok.
# Tag'ler INGILIZCE: vault icerigi Turkce ama tag'ler yapisal veri, LLM'in
# ve Obsidian'in tutarli okumasi icin tek dilde tutuluyor.
# Calisilan dizin adi -> konu/ karsiligi (listede yoksa dizin adinin slug'i kullanilir).
# Deger None ise o dizin bilinen bir PROJEDIR ama adi bir KONSEPT soylemez
# (urun/musteri adi) — konu/ tag'i uretilmez, proje bilgisi zaten project: alaninda.
# Deger doluysa repo adi konsepti dogrudan veriyordur (bora-ai-ocr -> ocr).
PROJE_KONU = {
    # ~/ARCH/Projects/BORA — asil calisma alani
    "arch-saas-platform": None, "boraai-landing-pagev2": None,
    "arch-mobile-app-v1": "mobile", "arch-mobile-app-v2": "mobile",
    "arch-micro-services": "microservices", "arch-micro-services-api": "microservices",
    "bora-ai-ocr": "ocr", "bora-ai-gabim": "gabim", "boraai-mobiliz-etl": "etl",
    "boraai-notifications": "notification", "boraai-voiceagent": "voice",
    "arch-mobil-imza": "e-signature", "boraai-mobil-imza": "e-signature",
    "server-conf": "infra", "arch-veri-seti-otomasyonu": "dataset",
    # ~/ARCH/Projects — diger. BORA/EDA/pakis/brokerplus GRUP klasoru, proje degil:
    # tabloya girmezler ki altlarindaki gercek proje adi ezilmesin.
    "arch-linear-bot": "linear", "mali-musavirlik-takip": None,
    "brokerpluscrm": None, "brokerplus-rag": "rag", "brokerplus-rpa": "rpa",
    "avenis": None, "ito": None,
    # vault / makine
    "myhub": "obsidian", "desktop": None,
}
# Oturum basligindaki anahtar kelime -> konu/ (birden fazlasi eslesebilir, en fazla 2 alinir)
SLUG_KONU = [
    (r'izin|leave|hak-?edis', "leave"), (r'masraf|expense|fis-|receipt', "expense"),
    (r'\bocr\b', "ocr"), (r'belge|dokuman|readme|kural', "document"),
    (r'ticket|support|destek', "ticket"), (r'imza|signature', "e-signature"),
    (r'linear|issue|epic', "linear"), (r'obsidian|vault|dump|myhub', "obsidian"),
    (r'hook|claude-md|skill|agent', "claude-code"),
    (r'branch|worktree|\bpr\b|merge|commit', "git"),
    (r'cron|n8n|otomas|automation', "automation"),
    (r'\brag\b|graph|embedding|semantic', "rag"),
    (r'wireshark|paket|nmap|guvenlik|security', "security"),
    (r'mobil|react-native|app-gelistirme', "mobile"),
    (r'migration|migrasyon|gabim|kuba', "migration"),
    (r'python|uv-|venv', "python"), (r'prod|deploy|kurulum|server|onprem', "infra"),
    (r'bot|slack', "bot"), (r'utts|petrol', "utts"),
    (r'yetki|permission|auth|rol-', "auth"), (r'rapor|report|excel', "reporting"),
]
# Esikler LLM maliyeti icin degil, vault'u onemsiz oturumlarla sismekten korumak icin.
MIN_BYTES = 4096         # bu boyutun altindaki transcript'ler atlanir
MIN_USER_MSGS = 2        # bu sayidan az gercek kullanici mesaji varsa atlanir
GH_LOOKUP = os.environ.get("OBSIDIAN_DUMP_NO_GH") != "1"

# Sohbet disi arayuz/durum kayitlari — nota yazilmaz.
SKIP_TYPES = {
    "file-history-snapshot", "file-history-delta", "queue-operation",
    "mode", "permission-mode", "last-prompt", "ai-title", "pr-link",
}

SESSION_ID, TRANSCRIPT, SRC_CWD = (sys.argv + ["", "", ""])[1:4]
HOME = os.path.expanduser("~")


def log(msg):
    stamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    print(f"[{stamp}] [{SESSION_ID}] {msg}", flush=True)


def die(msg, code=0):
    log(msg)
    sys.exit(code)


# --- Yardimcilar -----------------------------------------------------------
TR_MAP = str.maketrans("çğıöşüÇĞİIÖŞÜâîû", "cgiosucgiiosuaiu")


def slugify(text, max_words=6):
    text = (text or "").translate(TR_MAP)
    text = unicodedata.normalize("NFKD", text).encode("ascii", "ignore").decode()
    words = re.findall(r"[a-zA-Z0-9]+", text.lower())
    return "-".join(words[:max_words])


def fence(text, lang=""):
    """Icerikteki en uzun backtick dizisinden bir uzun cit — icerik hic bozulmaz."""
    text = text if text is not None else ""
    longest = max((len(m) for m in re.findall(r"`+", text)), default=0)
    bar = "`" * max(3, longest + 1)
    return f"{bar}{lang}\n{text}\n{bar}"


def callout(kind, title, body, collapsed=True):
    out = [f"> [!{kind}]{'-' if collapsed else ''} {title}"]
    for line in body.split("\n"):
        out.append("> " + line if line else ">")
    return "\n".join(out)


def local_time(iso):
    if not iso:
        return None
    try:
        return datetime.fromisoformat(iso.replace("Z", "+00:00")).astimezone()
    except ValueError:
        return None


def tilde(path):
    return path.replace(HOME + "/", "~/") if path else path


def yaml_str(value):
    return '"' + str(value).replace('\\', '\\\\').replace('"', '\\"') + '"'


# Kimlik bilgisi desenleri — meta/lint.py icindeki SECRETS ile ayni liste;
# orada desen eklersen buraya da ekle. Maske '<' ile baslar: lint'in
# [^'"<>\s] siniflari maskelenmis metne eslesmez, yani not lint'ten temiz gecer.
SECRET_RX = [
    ("google-api-key", re.compile(r'AIza[0-9A-Za-z_\-]{25,}'), False),
    ("jwt", re.compile(r'eyJ[A-Za-z0-9_\-]{15,}\.[A-Za-z0-9_\-]{15,}'), False),
    ("secret", re.compile(r'(_SECRET\s*=\s*[\'"])[^\'"<>\s]{8,}'), True),
    ("apikey", re.compile(r'(apiKey\s*:\s*[\'"])[^\'"<>\s]{8,}'), True),
]
masked = 0


def mask_secrets(text):
    """Kimlik bilgilerini nota yazmadan once gizler — vault Syncthing ile senkronlaniyor."""
    global masked
    for tag, rx, keep_prefix in SECRET_RX:
        text, n = rx.subn((r"\1" if keep_prefix else "") + f"<gizlendi:{tag}>", text)
        masked += n
    return text


VAULT_ROOT = os.path.dirname(VAULT_DIR)
IMG_DIR = ""             # ay klasoru hesaplandiktan sonra doldurulur
img_seq = 0
img_bytes = 0
EXT = {"image/jpeg": "jpg", "image/png": "png", "image/gif": "gif", "image/webp": "webp"}


def save_image(block):
    """base64 gorsel -> vault icinde gercek dosya; geriye Obsidian embed'i doner.

    Base64'u not govdesine gommek notu kullanilamaz hale getirirdi (tek ekran
    goruntusu ~400 KB metin); dosyaya yazinca gorsel Obsidian'da gercekten gorunur.
    """
    global img_seq, img_bytes
    src = block.get("source") or {}
    if src.get("type") != "base64" or not src.get("data"):
        return f"`[{block.get('type', 'blok')}: gömülemedi]`"
    img_seq += 1
    name = f"{SESSION_ID[:8]}-{img_seq:03d}.{EXT.get(src.get('media_type'), 'bin')}"
    path = os.path.join(IMG_DIR, name)
    try:
        raw = base64.b64decode(src["data"])
        os.makedirs(IMG_DIR, exist_ok=True)
        with open(path, "wb") as fh:
            fh.write(raw)
        img_bytes += len(raw)
    except (ValueError, OSError) as exc:
        return f"`[görsel yazılamadı: {exc}]`"
    return f"![[{os.path.relpath(path, VAULT_ROOT)}]]"


def parts_of(content):
    """Icerigi (metin, gorsel-embed listesi) olarak ayirir.

    Gorseller fence DISINDA kalmali, yoksa Obsidian embed'i kod blogu sanip yazi olarak basar.
    """
    if isinstance(content, str):
        return content, []
    if not isinstance(content, list):
        return ("" if content is None else str(content)), []
    text, embeds = [], []
    for block in content:
        if not isinstance(block, dict):
            text.append(str(block))
        elif block.get("type") == "text":
            text.append(block.get("text", ""))
        elif block.get("type") == "image":
            embeds.append(save_image(block))
        else:
            text.append(f"[{block.get('type', 'blok')}]")
    return "\n".join(text), embeds


def text_of(content):
    return parts_of(content)[0]


def render_tool_input(name, inp):
    """Arac girdisi — hicbir alan kirpilmaz."""
    if not isinstance(inp, dict):
        return fence(str(inp))
    if name == "Bash" and "command" in inp:
        body = fence(inp["command"], "bash")
        extra = {k: v for k, v in inp.items() if k not in ("command", "description")}
        if extra:
            body += "\n" + fence(json.dumps(extra, ensure_ascii=False, indent=2), "json")
        return body
    if name in ("Write", "NotebookEdit") and "content" in inp:
        return f"**{tilde(inp.get('file_path', ''))}**\n" + fence(str(inp["content"]))
    if name == "Edit":
        return (f"**{tilde(inp.get('file_path', ''))}**\n"
                "*eski:*\n" + fence(str(inp.get("old_string", ""))) +
                "\n*yeni:*\n" + fence(str(inp.get("new_string", ""))))
    if name == "Read" and "file_path" in inp:
        rest = {k: v for k, v in inp.items() if k != "file_path"}
        line = f"**{tilde(inp['file_path'])}**"
        return line + (f" `{json.dumps(rest, ensure_ascii=False)}`" if rest else "")
    return fence(json.dumps(inp, ensure_ascii=False, indent=2), "json")


def tool_label(name, inp):
    if not isinstance(inp, dict):
        return name
    for key in ("description", "command", "file_path", "pattern", "prompt", "query", "skill"):
        val = inp.get(key)
        if isinstance(val, str) and val.strip():
            one = " ".join(val.split())
            return f"{name} · {one[:110]}" + ("…" if len(one) > 110 else "")
    return name


# --- On kontrol ------------------------------------------------------------
os.makedirs(BASE_DIR, exist_ok=True)
if not TRANSCRIPT or not os.path.isfile(TRANSCRIPT):
    die(f"SKIP transcript yok: {TRANSCRIPT}")

size = os.path.getsize(TRANSCRIPT)


def iter_entries():
    with open(TRANSCRIPT, encoding="utf-8", errors="replace") as fh:
        for line in fh:
            line = line.strip()
            if not line:
                continue
            try:
                yield json.loads(line)
            except json.JSONDecodeError:
                continue


user_msgs = 0
first_ts = None          # ay klasoru gorseller yazilmadan once gerekli — burada bulunur
for e in iter_entries():
    if first_ts is None and e.get("timestamp"):
        first_ts = local_time(e["timestamp"])
    c = (e.get("message") or {}).get("content")
    if (e.get("type") == "user" and not e.get("isMeta")
            and isinstance(c, str) and not c.lstrip().startswith("<")):
        user_msgs += 1

if size < MIN_BYTES or user_msgs < MIN_USER_MSGS:
    die(f"SKIP esik alti (size={size}B, user_msgs={user_msgs})")

# --- Ay klasoru: not da gorseller de bunun altina yazilir ------------------
day_dt = first_ts or datetime.now()
day = day_dt.strftime("%Y-%m-%d")
month = day_dt.strftime("%m-%Y")
month_dir = os.path.join(VAULT_DIR, month)
IMG_DIR = os.path.join(month_dir, "attachments")

# --- Dedup: ayni oturum yeniden kapandiysa ayni notu guncelle ---------------
prev_note, prev_size = "", 0
if os.path.exists(STATE):
    with open(STATE, encoding="utf-8") as fh:
        for line in fh:
            cols = line.rstrip("\n").split("\t")
            if len(cols) == 3 and cols[0] == SESSION_ID:
                prev_note, prev_size = cols[1], int(cols[2] or 0)
if prev_size and size <= prev_size:
    die(f"SKIP zaten islendi (size={size}B <= {prev_size}B)")
if prev_note:
    log(f"Transcript buyumus ({prev_size}B -> {size}B), not guncellenecek: {prev_note}")

# --- Tek gecis: govdeyi tmp'ye yaz, meta'yi topla --------------------------
tmp_body = os.path.join(BASE_DIR, f"body-{SESSION_ID[:8]}.tmp")
tool_names = {}          # tool_use_id -> arac adi
pr_title_pending = {}    # tool_use_id -> `gh pr create --title` basligi
pr_titles = {}           # pr no -> baslik
prs = {}                 # pr no -> (url, repo)
branches, created_branches = [], []
last_ts = None
ai_title = ""
n_user = n_assistant = n_tool = 0
last_speaker = None

TITLE_RE = re.compile(r"--title\s+(\"(?:[^\"\\]|\\.)*\"|'[^']*'|\S+)")
PULL_RE = re.compile(r"https://github\.com/([^/\s]+/[^/\s]+)/pull/(\d+)")
NEWBRANCH_RE = re.compile(r"git\s+(?:checkout\s+-b|switch\s+-c)\s+([^\s;&|)'\"]+)")

with open(tmp_body, "w", encoding="utf-8") as out:
    def emit(block):
        out.write(mask_secrets(block).rstrip("\n") + "\n\n")

    def speaker_header(who, ts, side):
        global last_speaker
        key = (who, side)
        if last_speaker == key:
            return
        last_speaker = key
        clock = ts.strftime("%H:%M") if ts else ""
        icon, name = ("👤", "Sen") if who == "user" else ("🤖", "Claude")
        tail = " · ↳ alt-ajan" if side else ""
        emit(f"### {icon} {name} · {clock}{tail}")

    for entry in iter_entries():
        etype = entry.get("type")
        ts = local_time(entry.get("timestamp"))
        if ts:
            first_ts = first_ts or ts
            last_ts = ts

        # "HEAD" = detached/git disi dizin artigi, dal bilgisi degil.
        branch = entry.get("gitBranch")
        if branch and branch != "HEAD" and branch not in branches:
            branches.append(branch)

        if etype == "ai-title" and entry.get("aiTitle"):
            ai_title = entry["aiTitle"]
            continue

        if etype == "pr-link" and entry.get("prNumber"):
            prs[int(entry["prNumber"])] = (entry.get("prUrl", ""), entry.get("prRepository", ""))
            continue

        if etype in SKIP_TYPES:
            continue

        side = bool(entry.get("isSidechain"))
        msg = entry.get("message") or {}
        content = msg.get("content")

        # --- Kullanici ---
        if etype == "user":
            if isinstance(content, str):
                stripped = content.lstrip()
                if not stripped:
                    continue
                if stripped.startswith("<") or entry.get("isMeta"):
                    emit(callout("bug", "⚙️ sistem / komut", fence(content)))
                    last_speaker = None
                else:
                    speaker_header("user", ts, side)
                    emit(content)
                    n_user += 1
                continue
            if isinstance(content, list):
                for block in content:
                    if not isinstance(block, dict):
                        continue
                    if block.get("type") == "tool_result":
                        tid = block.get("tool_use_id", "")
                        name = tool_names.get(tid, "arac")
                        body, embeds = parts_of(block.get("content"))
                        if tid in pr_title_pending:
                            hit = PULL_RE.search(body)
                            if hit:
                                pr_titles[int(hit.group(2))] = pr_title_pending.pop(tid)
                        flag = "❌ " if block.get("is_error") else ""
                        inner = fence(body) + ("\n" + "\n".join(embeds) if embeds else "")
                        emit(callout("abstract", f"⤷ {flag}{name} sonucu", inner))
                        last_speaker = None
                    elif block.get("type") == "image":
                        speaker_header("user", ts, side)
                        emit(save_image(block))
                    elif block.get("type") == "text" and block.get("text", "").strip():
                        speaker_header("user", ts, side)
                        emit(block["text"])
                        n_user += 1
            continue

        # --- Asistan ---
        if etype == "assistant":
            if isinstance(content, str):
                if content.strip():
                    speaker_header("assistant", ts, side)
                    emit(content)
                    n_assistant += 1
                continue
            for block in content if isinstance(content, list) else []:
                if not isinstance(block, dict):
                    continue
                btype = block.get("type")
                if btype == "text":
                    if block.get("text", "").strip():
                        speaker_header("assistant", ts, side)
                        emit(block["text"])
                        n_assistant += 1
                elif btype == "thinking":
                    if block.get("thinking", "").strip():
                        speaker_header("assistant", ts, side)
                        emit(callout("quote", "🧠 Düşünme", block["thinking"]))
                        last_speaker = ("assistant", side)
                elif btype == "tool_use":
                    name = block.get("name", "arac")
                    inp = block.get("input") or {}
                    tool_names[block.get("id", "")] = name
                    speaker_header("assistant", ts, side)
                    emit(callout("abstract", f"🔧 {tool_label(name, inp)}",
                                 render_tool_input(name, inp)))
                    last_speaker = ("assistant", side)
                    n_tool += 1
                    if name == "Bash" and isinstance(inp, dict):
                        cmd = inp.get("command", "")
                        for b in NEWBRANCH_RE.findall(cmd):
                            if b not in created_branches:
                                created_branches.append(b)
                        if "gh pr create" in cmd:
                            hit = TITLE_RE.search(cmd)
                            if hit:
                                raw = hit.group(1)
                                if raw[:1] in "\"'":
                                    raw = raw[1:-1]
                                pr_title_pending[block.get("id", "")] = raw.replace('\\"', '"')
            continue

        # --- Diger (system/attachment vb.) ---
        if etype == "system" and entry.get("subtype") == "away_summary":
            body = text_of(entry.get("content") or msg.get("content"))
            if body.strip():
                emit(callout("info", "🕗 oturum özeti (sistem)", fence(body)))
                last_speaker = None

# --- PR basliklarini tamamla (gh, LLM degil) -------------------------------
if GH_LOOKUP:
    for num, (url, repo) in prs.items():
        if num in pr_titles or not repo:
            continue
        try:
            res = subprocess.run(
                ["gh", "pr", "view", str(num), "--repo", repo, "--json", "title", "-q", ".title"],
                capture_output=True, text=True, timeout=8)
            if res.returncode == 0 and res.stdout.strip():
                pr_titles[num] = res.stdout.strip()
        except (OSError, subprocess.SubprocessError):
            pass

# --- Basliklar ve dosya adi ------------------------------------------------
title = ai_title.strip() or f"Claude oturumu {day}"
slug = slugify(ai_title) or slugify(title) or "oturum"
# Worktree'de calisildiysa dizin adi DAL adidir (…/arch-saas-platform/.claude/worktrees/arch-196).
# Hem proje hem cwd repo koku olur: worktree gecicidir, silinince yol olu kalirdi.
# Dal bilgisi zaten branch: alaninda kalici duruyor.
repo_dir = re.sub(r'/\.claude/worktrees/[^/]+.*$', '', SRC_CWD.rstrip("/")) if SRC_CWD else ""
# Repo icindeki bir alt dizinde calisildiysa (…/arch-saas-platform/graphify-out) projeye cek.
if (repo_dir and os.path.basename(repo_dir).lower() not in PROJE_KONU
        and os.path.basename(os.path.dirname(repo_dir)).lower() in PROJE_KONU):
    repo_dir = os.path.dirname(repo_dir)
SRC_CWD = repo_dir
project = os.path.basename(repo_dir) if repo_dir else ""

# topic/ tag'leri: repo adi bir konsept soyluyorsa ondan 1 + oturum basligindan kalani.
# PROJE_KONU'da deger None ise urun/musteri adidir — tag uretilmez (proje: alaninda zaten var).
proje_slug = slugify(project, max_words=4)
konular = []
if proje_slug:
    k = PROJE_KONU[proje_slug] if proje_slug in PROJE_KONU else proje_slug
    if k:
        konular.append(k)
for rx, k in SLUG_KONU:
    if len(konular) >= 3:
        break
    if re.search(rx, slug, re.I) and k not in konular:
        konular.append(k)
tags = ["type/session"] + [f"topic/{k}" for k in konular]

note_path = prev_note if prev_note and os.path.isfile(prev_note) else ""
if not note_path:
    note_path = os.path.join(month_dir, f"{day}-{slug}.md")
    if os.path.exists(note_path):
        note_path = os.path.join(month_dir, f"{day}-{slug}-{SESSION_ID[:8]}.md")

# --- Frontmatter -----------------------------------------------------------
fm = ["---", f'up: "[[{month}]]"', f"tags: [{', '.join(tags)}]", f"date: {day}"]
if project:
    fm.append(f"project: {project}")
if SRC_CWD:
    fm.append(f"cwd: {yaml_str(tilde(SRC_CWD))}")
if branches:
    fm.append(f"branch: {yaml_str(branches[-1])}")
if created_branches:
    fm.append("branch_created: [" + ", ".join(yaml_str(b) for b in created_branches) + "]")
if prs:
    nums = sorted(prs)
    fm.append("pr: [" + ", ".join(str(n) for n in nums) + "]")
    fm.append(f"pr_url: {yaml_str(prs[nums[-1]][0])}")
    if pr_titles.get(nums[-1]):
        fm.append(f"pr_title: {yaml_str(pr_titles[nums[-1]])}")
    if prs[nums[-1]][1]:
        fm.append(f"repo: {yaml_str(prs[nums[-1]][1])}")
fm += [f"session: {SESSION_ID}", f"messages: {n_user + n_assistant}", "---", ""]

head = ["\n".join(fm), f"# {day} · {title}", ""]

# PR blogu — basligin hemen altinda, en buyuk gorunur oge
for num in sorted(prs):
    url, repo = prs[num]
    label = pr_titles.get(num, "")
    head.append(f"## 🔀 PR #{num}" + (f" — {label}" if label else ""))
    line = f"> **[{repo}#{num}]({url})**" if url else f"> **{repo}#{num}**"
    if created_branches:
        line += " · dal " + ", ".join(f"`{b}`" for b in created_branches)
    elif branches:
        line += f" · dal `{branches[-1]}`"
    head.append(line + "\n")

meta_bits = []
if first_ts and last_ts:
    meta_bits.append(f"{first_ts:%Y-%m-%d %H:%M} → {last_ts:%H:%M}")
meta_bits.append(f"{n_user} kullanıcı / {n_assistant} asistan mesajı · {n_tool} araç çağrısı")
if SRC_CWD:
    meta_bits.append(f"`{tilde(SRC_CWD)}`")
if branches:
    meta_bits.append("dal `" + "` → `".join(branches) + "`")
meta_bits.append(f"oturum `{SESSION_ID[:8]}`")
head.append("**Oturum:** " + " · ".join(meta_bits))
head.append("\n---\n")

foot = ["\n---\n", "*Ham döküm — mesaj ve araç içerikleri kırpılmadan yazıldı; "
        "yalnızca arayüz/durum kayıtları (dosya anlık görüntüleri, kuyruk ve mod "
        "değişiklikleri) hariç tutuldu.*"]
if img_seq:
    foot.append(f"*{img_seq} görsel `Claude/attachments/` altına yazıldı "
                f"({img_bytes // 1024} KB).*")
foot = "\n".join(foot) + "\n"

os.makedirs(month_dir, exist_ok=True)
# Ay MOC'u: notun up hedefi. Yoksa acilir — vault sozlesmesi her notun HOME'a
# ulasan bir up zinciri olmasini ister.
moc_path = os.path.join(month_dir, f"{month}.md")
if not os.path.exists(moc_path):
    with open(moc_path, "w", encoding="utf-8") as moc:
        moc.write(f'---\nup: "{UP_NOTE}"\ntags: [type/moc]\n'
                  f'date: {day_dt:%Y-%m}\n---\n\n'
                  f'# 🗓️ Claude · {TR_MONTHS[day_dt.month - 1]} {day_dt.year}\n\n'
                  f'{day_dt.year} {TR_MONTHS[day_dt.month - 1]} ayının Claude Code oturumları.\n\n'
                  '## Oturumlar (otomatik)\n'
                  '```dataview\n'
                  'TABLE WITHOUT ID file.link AS "Oturum", project AS "Proje", '
                  'branch AS "Dal", pr AS "PR", messages AS "Mesaj"\n'
                  'WHERE file.folder = this.file.folder AND date\n'
                  'SORT date DESC\n'
                  '```\n')
    log(f"ay MOC'u olusturuldu: {moc_path}")

with open(note_path, "w", encoding="utf-8") as note:
    note.write("\n".join(head) + "\n")
    with open(tmp_body, encoding="utf-8") as body:
        for chunk in iter(lambda: body.read(1 << 20), ""):
            note.write(chunk)
    note.write(foot)
os.remove(tmp_body)

# --- State (mkdir kilidi: es zamanli iki SessionEnd'i ayirir) --------------
for _ in range(100):
    try:
        os.mkdir(LOCK_DIR)
        break
    except FileExistsError:
        time.sleep(0.2)
else:
    log("UYARI state kilidi alinamadi, state guncellenmedi")
    LOCK_DIR = None

if LOCK_DIR:
    rows = []
    if os.path.exists(STATE):
        with open(STATE, encoding="utf-8") as fh:
            rows = [r for r in fh.read().splitlines() if not r.startswith(SESSION_ID + "\t")]
    rows.append(f"{SESSION_ID}\t{note_path}\t{size}")
    with open(STATE, "w", encoding="utf-8") as fh:
        fh.write("\n".join(rows) + "\n")
    os.rmdir(LOCK_DIR)

log(f"OK not yazildi: {note_path} ({os.path.getsize(note_path)}B, "
    f"user={n_user}, assistant={n_assistant}, tool={n_tool}, "
    f"gorsel={img_seq} ({img_bytes // 1024}KB), maskelenen sir={masked}, "
    f"pr={sorted(prs) or '-'})")

# Vault sozlesmesi: .md yazildiktan sonra lint — sonuc sadece log'a duser.
lint = os.path.join(os.path.dirname(VAULT_DIR), "meta", "lint.py")
if os.path.isfile(lint):
    try:
        res = subprocess.run([sys.executable, lint], capture_output=True, text=True, timeout=120)
        log("lint: " + " | ".join(res.stdout.strip().splitlines()[-3:]))
    except (OSError, subprocess.SubprocessError) as exc:
        log(f"lint calistirilamadi: {exc}")
