"""Побудова часових діаграм (у стилі GTKWave) з VCD-файлу симуляції GHDL."""
import re, sys
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt

VCD = sys.argv[1] if len(sys.argv) > 1 else "tb_i2c.vcd"

# ---------------- простий парсер VCD (лише верхній scope tb_i2c) -------------
ids, sigs = {}, {}
scope = []
t = 0
with open(VCD) as f:
    in_defs = True
    for line in f:
        line = line.strip()
        if not line:
            continue
        if in_defs:
            if line.startswith("$scope"):
                scope.append(line.split()[2])
            elif line.startswith("$upscope"):
                scope.pop()
            elif line.startswith("$var") and scope == ["tb_i2c"]:
                p = line.split()
                name = p[4]
                name = re.sub(r"\[.*\]", "", name)
                if p[3] not in ids:
                    ids[p[3]] = name
                    sigs[name] = []
            elif line.startswith("$enddefinitions"):
                in_defs = False
            continue
        if line[0] == "#":
            t = int(line[1:]) / 1e9  # fs -> us
        elif line[0] in "bB":
            val, ident = line[1:].split()
            if ident in ids:
                v = val.replace("H", "1").replace("L", "0")
                sigs[ids[ident]].append((t, int(v, 2) if set(v) <= {"0", "1"} else None))
        else:
            val, ident = line[0], line[1:]
            if ident in ids:
                v = {"0": 0, "1": 1, "H": 1, "L": 0}.get(val.upper(), None)
                sigs[ids[ident]].append((t, v))

T_END = max(tv[-1][0] for tv in sigs.values() if tv)


def value_at(name, tq):
    v = None
    for tt, vv in sigs[name]:
        if tt > tq:
            break
        v = vv
    return v


def steps(name, t0, t1):
    tv = sigs[name]
    xs, ys = [t0], [value_at(name, t0)]
    for tt, vv in tv:
        if t0 < tt < t1:
            xs += [tt, tt]
            ys += [ys[-1], vv]
    xs.append(t1)
    ys.append(ys[-1])
    return xs, ys


BG, GRID, FG, BUS, TXT = "#000000", "#203020", "#2bff2b", "#ffd84d", "#e8e8e8"


def plot(rows, t0, t1, fname, title, annot=None, figw=13):
    n = len(rows)
    fig, ax = plt.subplots(figsize=(figw, 0.62 * n + 1.3))
    fig.patch.set_facecolor(BG)
    ax.set_facecolor(BG)
    for i, (name, kind) in enumerate(rows):
        y0 = (n - 1 - i) * 1.0
        if kind == "bit":
            xs, ys = steps(name, t0, t1)
            ys2 = [y0 + 0.1 + 0.65 * (v if v is not None else 0.5) for v in ys]
            ax.plot(xs, ys2, color=FG, lw=1.1)
        else:
            xs = [t0] + [tt for tt, _ in sigs[name] if t0 < tt < t1] + [t1]
            for a, b in zip(xs[:-1], xs[1:]):
                v = value_at(name, (a + b) / 2)
                ax.fill_between([a, b], y0 + 0.12, y0 + 0.72, color=BUS, alpha=0.15, lw=0)
                ax.plot([a, b], [y0 + 0.12] * 2, color=BUS, lw=0.9)
                ax.plot([a, b], [y0 + 0.72] * 2, color=BUS, lw=0.9)
                ax.plot([a, a], [y0 + 0.12, y0 + 0.72], color=BUS, lw=0.9)
                if (b - a) > (t1 - t0) * 0.03:
                    ax.text((a + b) / 2, y0 + 0.42, f"{v:02X}" if v is not None else "X",
                            color=TXT, ha="center", va="center", fontsize=8, family="monospace")
        ax.text(t0 - (t1 - t0) * 0.006, y0 + 0.42, name, color=TXT, ha="right",
                va="center", fontsize=9, family="monospace")
    if annot:
        for x, label, col in annot:
            ax.axvline(x, color=col, lw=0.7, ls="--", alpha=0.8)
            ax.text(x, n + 0.05, label, color=col, ha="center", va="bottom", fontsize=7.5,
                    family="monospace")
    ax.set_xlim(t0, t1)
    ax.set_ylim(-0.1, n + (0.6 if annot else 0.1))
    ax.set_yticks([])
    ax.tick_params(colors=TXT, labelsize=8)
    for s in ax.spines.values():
        s.set_color(GRID)
    ax.grid(axis="x", color=GRID, lw=0.6)
    ax.set_xlabel("час, мкс", color=TXT, fontsize=9)
    ax.set_title(title, color=TXT, fontsize=10)
    fig.subplots_adjust(left=0.11, right=0.99, top=0.9 if not annot else 0.86, bottom=0.12)
    fig.savefig(fname, dpi=160, facecolor=BG)
    plt.close(fig)
    print("saved", fname)


def edges(name, t0, t1, rising=True):
    out, prev = [], value_at(name, t0)
    for tt, vv in sigs[name]:
        if t0 < tt < t1:
            if rising and prev == 0 and vv == 1:
                out.append(tt)
            if not rising and prev == 1 and vv == 0:
                out.append(tt)
            prev = vv
    return out


def decode(t0, t1):
    """Розмітка бітів: значення SDA на кожному фронті SCL + START/STOP."""
    ann = []
    for tt, vv in sigs["sda"]:
        if max(t0, 1.0) < tt < t1 and value_at("scl", tt) == 1:
            ann.append((tt, "STOP" if vv == 1 else "START", "#ff6060"))
    rises = edges("scl", t0, t1)
    if len(rises) > 9:
        rises = rises[:len(rises) // 9 * 9]  # останній фронт належить STOP
    labels = []
    for k, r in enumerate(rises):
        pos = k % 9
        b = value_at("sda", r + 0.5)
        if pos == 8:
            labels.append((r, "ACK" if b == 0 else "NACK", "#5fd0ff"))
        else:
            labels.append((r, str(b), TXT))
    return ann + labels


def tx_windows():
    """Межі транзакцій за сигналом busy."""
    w, start = [], None
    for tt, vv in sigs["busy"]:
        if vv == 1:
            start = tt
        elif vv == 0 and start is not None:
            w.append((start, tt))
            start = None
    return w


W = tx_windows()
print("transactions:", [(round(a, 2), round(b, 2)) for a, b in W])
r = edges("scl", W[0][0], W[0][1])
print("SCL period, us:", round(r[2] - r[1], 3), "-> f =", round(1e3 / (r[2] - r[1]), 2), "kHz")

overview = [("scl", "bit"), ("sda", "bit"), ("start", "bit"), ("busy", "bit"),
            ("done", "bit"), ("ack_error", "bit"), ("rx_valid", "bit"),
            ("rx_data", "bus"), ("data_rd", "bus")]
plot(overview, 0, T_END, "fig_overview.png",
     "Загальна часова діаграма: 4 тестові транзакції (Т1 запис 0xA5, Т2 читання 0x3C, Т3 NACK, Т4 запис 0x05)")

detail = [("scl", "bit"), ("sda", "bit"), ("m_sda_oe", "bit"), ("s_sda_oe", "bit"),
          ("busy", "bit"), ("data_wr", "bus"), ("rx_valid", "bit"), ("rx_data", "bus")]
a, b = W[0]
plot(detail, a - 3, b + 3, "fig_t1_write.png",
     "Тест 1: запис 0xA5 у Slave 0x55 — адреса 1010101 + W(0), ACK, дані 10100101, ACK",
     annot=decode(a - 3, b + 3))

detail2 = [("scl", "bit"), ("sda", "bit"), ("m_sda_oe", "bit"), ("s_sda_oe", "bit"),
           ("busy", "bit"), ("tx_data", "bus"), ("done", "bit"), ("data_rd", "bus")]
a, b = W[1]
plot(detail2, a - 3, b + 3, "fig_t2_read.png",
     "Тест 2: читання з Slave 0x55 — адреса 1010101 + R(1), ACK, дані 00111100 від Slave, NACK Master",
     annot=decode(a - 3, b + 3))

detail3 = [("scl", "bit"), ("sda", "bit"), ("m_sda_oe", "bit"), ("s_sda_oe", "bit"),
           ("busy", "bit"), ("done", "bit"), ("ack_error", "bit")]
a, b = W[2]
plot(detail3, a - 3, b + 3, "fig_t3_nack.png",
     "Тест 3: звернення до відсутньої адреси 0x23 — NACK, ack_error = 1, одразу STOP",
     annot=decode(a - 3, b + 3))

# збільшений фрагмент: START + перші біти (видно чверті періоду)
a, _ = W[0]
zoom = [("clk", "bit"), ("scl", "bit"), ("sda", "bit"), ("start", "bit"), ("busy", "bit")]
plot(zoom, a - 0.3, a + 0.6, "fig_clk_start.png",
     "Фрагмент: імпульс start і початок транзакції (системний такт 50 МГц)", figw=11)
zoom2 = [("scl", "bit"), ("sda", "bit")]
plot(zoom2, a, a + 32, "fig_start_zoom.png",
     "Умова START (SDA↓ при SCL=1) та перші біти адреси; період SCL = 10 мкс (100 кГц)",
     annot=decode(a, a + 32), figw=11)
