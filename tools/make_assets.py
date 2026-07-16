#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
make_assets.py -- pipeline de generation des assets graphiques du fighting game.

Ce script (headless, Pillow uniquement) :
  1. construit la feuille de sprites 128x128 (assets/sheet.png) :
       - Volt  : bloc 24x32 en (0,0)   -- dessine a la main (voir note plus bas)
       - Torque: bloc 24x32 en (24,0)  -- extrait automatiquement depuis
                 images/Character_Torque.png (fond gris uni)
       - tuiles de decor 8x8 a partir de l'index sprite 64
  2. exporte assets/volt.png, assets/torque.png, assets/sheet.png
  3. injecte les sections __gfx__ / __map__ dans main.p8 (remplace si deja
     presentes -> le script est idempotent)

Note sur Volt : la source (images/Interface.png) montre Volt debout sur un
FOND NON UNI (mur peche + bitume, memes teintes que la peau/le short), donc
un flood-fill automatique produirait des pixels parasites du mur colles a la
silhouette (bras, jambes). On applique donc le repli assume prevu par le
brief : Volt est dessine a la main ci-dessous, comme un tableau 24x32
d'indices de palette, fidele a la description (dreadlocks noires, peau,
debardeur vert, short beige, baskets rouges, pistolet).

Relancer ce script produit exactement le meme main.p8 (idempotence verifiee
par un second run + diff dans le rapport de la tache).
"""

import os
import numpy as np
from PIL import Image

# ---------------------------------------------------------------------------
# Chemins
# ---------------------------------------------------------------------------
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
IMAGES_DIR = os.path.join(ROOT, "images")
ASSETS_DIR = os.path.join(ROOT, "assets")
MAIN_P8 = os.path.join(ROOT, "main.p8")

TORQUE_SRC = os.path.join(IMAGES_DIR, "Character_Torque.png")

os.makedirs(ASSETS_DIR, exist_ok=True)

# ---------------------------------------------------------------------------
# Palette PICO-8 (index -> RGB)
# ---------------------------------------------------------------------------
PALETTE = [
    (0x00, 0x00, 0x00),  # 0  noir
    (0x1D, 0x2B, 0x53),  # 1  bleu nuit
    (0x7E, 0x25, 0x53),  # 2  violet fonce
    (0x00, 0x87, 0x51),  # 3  vert fonce
    (0xAB, 0x52, 0x36),  # 4  marron
    (0x5F, 0x57, 0x4F),  # 5  gris fonce
    (0xC2, 0xC3, 0xC7),  # 6  gris clair
    (0xFF, 0xF1, 0xE8),  # 7  blanc casse
    (0xFF, 0x00, 0x4D),  # 8  rouge
    (0xFF, 0xA3, 0x00),  # 9  orange
    (0xFF, 0xEC, 0x27),  # 10 jaune
    (0x00, 0xE4, 0x36),  # 11 vert clair
    (0x29, 0xAD, 0xFF),  # 12 bleu clair
    (0x83, 0x76, 0x9C),  # 13 mauve
    (0xFF, 0x77, 0xA8),  # 14 rose (= cle de transparence)
    (0xFF, 0xCC, 0xAA),  # 15 peche
]
TRANSPARENT_IDX = 14
PALETTE_ARR = np.array(PALETTE, dtype=np.float64)


def closest_palette_index(rgb, exclude=None):
    """Indice de palette le plus proche (distance ponderee luminance)."""
    weights = np.array([0.30, 0.59, 0.11])
    diff = PALETTE_ARR - np.array(rgb, dtype=np.float64)
    dist = np.sum(weights * diff * diff, axis=1)
    if exclude is not None:
        dist = dist.copy()
        dist[exclude] = np.inf
    return int(np.argmin(dist))


def quantize_rgb_array(rgb_arr):
    """Quantifie un array (H,W,3) uint8/float en array (H,W) d'indices palette,
    entierement vectorise (pas de boucle python par pixel)."""
    h, w, _ = rgb_arr.shape
    flat = rgb_arr.reshape(-1, 3).astype(np.float64)
    weights = np.array([0.30, 0.59, 0.11])
    # distance de chaque pixel a chacune des 16 couleurs -> (N,16)
    diff = flat[:, None, :] - PALETTE_ARR[None, :, :]
    dist = np.sum(weights * diff * diff, axis=2)
    idx = np.argmin(dist, axis=1)
    return idx.reshape(h, w)


def grid_to_rgb_image(grid):
    """grid: array (H,W) d'indices 0-15 -> Image RGB."""
    h, w = grid.shape
    out = np.zeros((h, w, 3), dtype=np.uint8)
    for i, col in enumerate(PALETTE):
        out[grid == i] = col
    return Image.fromarray(out)


def grid_to_hex_rows(grid):
    """grid (H,W) d'indices 0-15 -> liste de H chaines hex (1 char/pixel)."""
    rows = []
    for y in range(grid.shape[0]):
        rows.append("".join("{:x}".format(int(v)) for v in grid[y]))
    return rows


# ---------------------------------------------------------------------------
# Extraction de Torque (fond gris uni -> segmentation par tolerance +
# flood-fill pour ne garder que la silhouette connectee au bord, miroir
# horizontal pour qu'il regarde a droite, redimensionnement dans 24x32).
# ---------------------------------------------------------------------------
def largest_connected_component(mask):
    """Etiquetage de composantes connexes 4-connexes en pur python/BFS (pas de
    scipy dispo) ; ne garde que la plus grande (= la silhouette du
    personnage, en ecartant les petits artefacts deconnectes du fond, comme
    une paillette/watermark isolee dans l'image source)."""
    from collections import deque
    h, w = mask.shape
    visited = np.zeros_like(mask, dtype=bool)
    best = None
    best_size = 0
    ys, xs = np.where(mask)
    seeds = list(zip(ys.tolist(), xs.tolist()))
    for sy, sx in seeds:
        if visited[sy, sx]:
            continue
        comp = []
        q = deque([(sy, sx)])
        visited[sy, sx] = True
        while q:
            cy, cx = q.popleft()
            comp.append((cy, cx))
            for ny, nx in ((cy - 1, cx), (cy + 1, cx), (cy, cx - 1), (cy, cx + 1)):
                if 0 <= ny < h and 0 <= nx < w and mask[ny, nx] and not visited[ny, nx]:
                    visited[ny, nx] = True
                    q.append((ny, nx))
        if len(comp) > best_size:
            best_size = len(comp)
            best = comp
    out = np.zeros_like(mask)
    if best:
        cy, cx = zip(*best)
        out[np.array(cy), np.array(cx)] = True
    return out


def flood_fill_background_mask(im_rgb, bg_color, tol, factor=4):
    """Renvoie un masque bool plein-format (H,W) = True la ou le pixel
    appartient a la silhouette du personnage (fond gris retire par
    flood-fill depuis les bords, puis ne garde que la plus grande composante
    connexe pour ecarter les artefacts isoles). Calcule sur une version
    sous-echantillonnee (rapide, largement suffisant vu qu'on redimensionne
    ensuite dans un tout petit 24x32) puis remonte a la resolution d'origine
    par plus-proche-voisin."""
    w, h = im_rgb.size
    small = im_rgb.resize((max(1, w // factor), max(1, h // factor)), Image.BILINEAR)
    arr = np.array(small).astype(np.int32)
    diff = np.abs(arr - np.array(bg_color, dtype=np.int32)).sum(axis=2)
    bg_like = diff < tol

    connected = np.zeros_like(bg_like)
    connected[0, :] = bg_like[0, :]
    connected[-1, :] = bg_like[-1, :]
    connected[:, 0] |= bg_like[:, 0]
    connected[:, -1] |= bg_like[:, -1]

    while True:
        prev = connected
        d = prev.copy()
        d[1:, :] |= prev[:-1, :]
        d[:-1, :] |= prev[1:, :]
        d[:, 1:] |= prev[:, :-1]
        d[:, :-1] |= prev[:, 1:]
        connected = d & bg_like
        connected |= prev
        if np.array_equal(connected, prev):
            break

    fg_small = ~connected
    fg_small = largest_connected_component(fg_small)

    small_mask_img = Image.fromarray((fg_small * 255).astype(np.uint8))
    full_mask_img = small_mask_img.resize((w, h), Image.NEAREST)
    return np.array(full_mask_img) > 127


def extract_torque(target_w=24, target_h=32):
    im = Image.open(TORQUE_SRC).convert("RGB")
    w, h = im.size
    arr = np.array(im)

    # couleur de fond : mediane des pixels de bordure (fond gris uni mesure).
    border = np.concatenate([
        arr[0:20, :].reshape(-1, 3), arr[-20:, :].reshape(-1, 3),
        arr[:, 0:20].reshape(-1, 3), arr[:, -20:].reshape(-1, 3),
    ])
    bg_color = tuple(int(v) for v in np.median(border, axis=0))

    fg_mask = flood_fill_background_mask(im, bg_color, tol=45, factor=4)

    ys, xs = np.where(fg_mask)
    if len(xs) == 0:
        raise RuntimeError("extraction Torque : aucune silhouette detectee")
    x0, x1 = xs.min(), xs.max()
    y0, y1 = ys.min(), ys.max()

    crop_rgb = arr[y0:y1 + 1, x0:x1 + 1, :]
    crop_mask = fg_mask[y0:y1 + 1, x0:x1 + 1]

    # miroir horizontal : la source pointe le fusil vers la gauche, on veut
    # que Torque regarde/pointe vers la DROITE dans la feuille de sprites.
    crop_rgb = crop_rgb[:, ::-1, :]
    crop_mask = crop_mask[:, ::-1]

    cw, ch = crop_rgb.shape[1], crop_rgb.shape[0]
    scale = min(target_w / cw, target_h / ch)
    new_w = max(1, round(cw * scale))
    new_h = max(1, round(ch * scale))

    rgba = np.dstack([crop_rgb, (crop_mask * 255).astype(np.uint8)])
    rgba_img = Image.fromarray(rgba).resize((new_w, new_h), Image.LANCZOS)
    rgba_resized = np.array(rgba_img)

    canvas_idx = np.full((target_h, target_w), TRANSPARENT_IDX, dtype=np.int64)
    off_x = (target_w - new_w) // 2
    off_y = target_h - new_h  # aligne les pieds en bas du canevas

    rgb_part = rgba_resized[:, :, :3]
    alpha_part = rgba_resized[:, :, 3]
    quant = quantize_rgb_array(rgb_part.astype(np.float64))

    fg_alpha = alpha_part > 127
    # collision avec la cle de transparence : re-choisit la 2e meilleure
    # couleur (hors 14) pour les pixels de silhouette concernes.
    collide = fg_alpha & (quant == TRANSPARENT_IDX)
    if np.any(collide):
        ys2, xs2 = np.where(collide)
        for yy, xx in zip(ys2, xs2):
            quant[yy, xx] = closest_palette_index(rgb_part[yy, xx], exclude=TRANSPARENT_IDX)

    r = rgb_part[:, :, 0].astype(np.float64)
    g = rgb_part[:, :, 1].astype(np.float64)
    b = rgb_part[:, :, 2].astype(np.float64)

    # bandana rouge : sur la feuille redimensionnee a 24x32, le ton brique
    # source (~159,70,54) est objectivement plus proche de 4 (marron) que de
    # 8 (rouge) en distance ponderee luminance -- mais 8 est la couleur
    # signature du perso. Regle ciblee : tout pixel de teinte rouge-brique
    # marquee (r>110 et r>1.5*g) devient 8, restreint au tiers superieur du
    # sprite (bandana) pour ne pas capturer la peau du visage plus bas.
    top_third = np.zeros_like(quant, dtype=bool)
    top_third_rows = off_y + np.arange(new_h) < target_h / 3
    top_third[top_third_rows, :] = True
    bandana = fg_alpha & top_third & (r > 110) & (r > 1.5 * g)
    quant[bandana] = 8

    # hoodie/jean indigo : le style source a des contours noirs epais ; en
    # redescendant a 24x32 (LANCZOS), les zones de tissu s'assombrissent par
    # melange avec ces contours et finissent plus proches de 1 (bleu nuit)
    # que de 13 (indigo, la couleur attendue du vetement). On corrige apres
    # coup : un pixel quantifie en 1 mais dont la luminance d'origine reste
    # au-dessus d'un plancher "ombre/contour" est reclasse en 13 ; en dessous
    # (~contour/pli tres sombre) il reste 1.
    lum = 0.30 * r + 0.59 * g + 0.11 * b
    navy_to_indigo = fg_alpha & (quant == 1) & (lum > 40) & (~bandana)
    quant[navy_to_indigo] = 13

    region = canvas_idx[off_y:off_y + new_h, off_x:off_x + new_w]
    region[fg_alpha] = quant[fg_alpha]

    return canvas_idx


# ---------------------------------------------------------------------------
# Volt : dessine a la main (voir note d'en-tete -- fond source non uni).
# On construit la silhouette par blocs (tete/dreads/torse/bras/short/jambes/
# baskets/pistolet) puis on ajoute un contour noir automatique sur les bords
# exterieurs de la silhouette (tout pixel non-transparent adjacent a un
# pixel transparent, a l'interieur du canevas, devient couleur 0).
# ---------------------------------------------------------------------------
def draw_volt(target_w=24, target_h=32):
    g = np.full((target_h, target_w), TRANSPARENT_IDX, dtype=np.int64)

    def rect(x0, y0, x1, y1, c):
        g[y0:y1 + 1, x0:x1 + 1] = c

    def px(x, y, c):
        g[y, x] = c

    SKIN = 4
    HAIR = 0
    SHIRT = 3
    SHIRT_HI = 11
    SHORTS = 15
    SHOE = 8
    SHOE_SOLE = 7
    GUN = 5
    GUN_HI = 6
    EYE_HI = 7

    # dreadlocks : masse haute + meches tombant sur les cotes, effilees vers
    # le bas (largeur decroissante + quelques crans) plutot qu'un bloc
    # rectangulaire plein.
    # NB : on evite tout pixel non-transparent dans la zone (x<=7, y<=7) --
    # c'est le sprite 0, que stage.lua traite comme "case vide" de la map
    # (palt(14,true) puis map(...) : une case a 0 doit rester transparente
    # pour laisser voir le ciel derriere). les meches restent donc a x>=8
    # pour les rangees y<=7.
    rect(8, 1, 16, 3, HAIR)

    # meche gauche : large en haut (contre la tete), effilee jusqu'a 1px,
    # avec un cran (pixel transparent) pour separer les brins.
    left_strand = {
        4: (8, 9), 5: (8, 9), 6: (8, 9), 7: (8, 8),
        8: (7, 8), 9: (6, 7), 10: (6, 7), 11: (6, 6),
        12: (6, 6), 13: (7, 7),
    }
    for row, (c0, c1) in left_strand.items():
        rect(c0, row, c1, row, HAIR)
    px(6, 9, TRANSPARENT_IDX)  # cran : separe la meche en deux brins

    # meche droite : symetrique, effilee elle aussi.
    right_strand = {
        4: (16, 17), 5: (16, 17), 6: (17, 17), 7: (17, 17),
        8: (17, 18), 9: (18, 18), 10: (18, 18), 11: (17, 17),
    }
    for row, (c0, c1) in right_strand.items():
        rect(c0, row, c1, row, HAIR)
    px(17, 9, TRANSPARENT_IDX)  # cran : separe la meche en deux brins

    # tete (peau)
    rect(10, 3, 15, 8, SKIN)
    # oeil (regard vers la droite, sens de la marche)
    px(13, 6, HAIR)
    px(14, 6, EYE_HI)  # petit reflet clair juste a cote de l'oeil
    # cou
    rect(11, 9, 13, 9, SKIN)

    # torse (debardeur vert, liseret clair sur le cote)
    rect(8, 10, 16, 18, SHIRT)
    rect(8, 10, 9, 18, SHIRT_HI)

    # bras arriere (gauche), le long du corps
    rect(6, 11, 7, 19, SKIN)
    rect(5, 18, 7, 19, GUN)

    # bras avant (droit), tendu vers l'avant avec le pistolet
    rect(17, 11, 18, 13, SKIN)
    rect(18, 13, 21, 15, SKIN)
    rect(21, 13, 23, 15, GUN)
    px(22, 14, GUN_HI)

    # short beige (cargo)
    rect(8, 19, 16, 24, SHORTS)

    # jambes (peau), espace transparent entre les deux
    rect(8, 25, 11, 29, SKIN)
    rect(13, 25, 16, 29, SKIN)

    # baskets (rouge, semelle claire)
    rect(8, 30, 11, 30, SHOE)
    rect(13, 30, 16, 30, SHOE)
    rect(8, 31, 11, 31, SHOE_SOLE)
    rect(13, 31, 16, 31, SHOE_SOLE)

    # contour noir : uniquement sur les bords ou le voisin EST DANS LE
    # CANEVAS et vaut la couleur de transparence (on ne veut pas "manger"
    # les pixels qui touchent le bord du sprite, ex. semelles en bas).
    fg = g != TRANSPARENT_IDX
    out = g.copy()
    h, w = g.shape
    for y in range(h):
        for x in range(w):
            if not fg[y, x]:
                continue
            touches_bg = False
            for ny, nx in ((y - 1, x), (y + 1, x), (y, x - 1), (y, x + 1)):
                if 0 <= ny < h and 0 <= nx < w and not fg[ny, nx]:
                    touches_bg = True
                    break
            if touches_bg:
                out[y, x] = HAIR  # 0 = noir, utilise comme couleur de contour
    return out


# ---------------------------------------------------------------------------
# Tuiles de decor 8x8, indices sprite 64+ (index = row*16+col dans la feuille
# 128x128, tuile 8x8 -> 16 tuiles par ligne). Chaque fonction renvoie un
# array (8,8) d'indices de palette. Le "bruit" (grain, usure, fissures) est
# entierement deterministe (formules modulo sur x/y) pour garantir
# l'idempotence du script (pas de random non seede).
# ---------------------------------------------------------------------------
def tile_facade_rose():
    t = np.full((8, 8), 15, dtype=np.int64)
    for y in range(8):
        for x in range(8):
            if (x + y) % 5 == 0:
                t[y, x] = 8
            elif (x * 3 + y) % 7 == 0:
                t[y, x] = 2
    return t


def _window(bg):
    t = np.full((8, 8), bg, dtype=np.int64)
    t[1:7, 1:7] = 4
    t[2:6, 2:6] = 1
    t[2:6, 0] = 0
    t[2:6, 7] = 0
    return t


def tile_window_rose():
    return _window(15)


def tile_facade_ocre():
    t = np.full((8, 8), 9, dtype=np.int64)
    for y in range(8):
        for x in range(8):
            if (x + y) % 4 == 0:
                t[y, x] = 10
            elif (x * 2 + y) % 9 == 0:
                t[y, x] = 4
    return t


def tile_window_ocre():
    return _window(9)


def tile_facade_turquoise():
    t = np.full((8, 8), 12, dtype=np.int64)
    for y in range(8):
        for x in range(8):
            if (x + y) % 5 == 0:
                t[y, x] = 4
            elif (x * 3 + y) % 8 == 0:
                t[y, x] = 15
    return t


def tile_window_turquoise():
    return _window(12)


def tile_porte_bois():
    t = np.full((8, 8), 4, dtype=np.int64)
    t[0, :] = 0
    t[:, 0] = 0
    t[:, 7] = 0
    t[7, :] = 0
    t[4, 5] = 10  # poignee
    return t


def tile_tole_rouillee():
    t = np.zeros((8, 8), dtype=np.int64)
    for y in range(8):
        for x in range(8):
            c = 6 if x % 2 == 0 else 5
            if (x * 5 + y * 3) % 11 == 0:
                c = 4
            elif (x * 5 + y * 3) % 13 == 0:
                c = 9
            t[y, x] = c
    return t


def tile_mur_beton():
    t = np.full((8, 8), 6, dtype=np.int64)
    for y in range(8):
        for x in range(8):
            if (x * 7 + y * 3) % 9 == 0:
                t[y, x] = 5
    return t


def tile_graffiti_a():
    t = np.full((8, 8), 6, dtype=np.int64)
    blobs = [(2, 2, 8), (3, 2, 8), (5, 3, 12), (5, 4, 12), (2, 5, 10), (3, 5, 10), (6, 6, 8)]
    for x, y, c in blobs:
        t[y, x] = c
    return t


def tile_graffiti_b():
    t = np.full((8, 8), 6, dtype=np.int64)
    blobs = [(1, 3, 9), (2, 3, 9), (4, 2, 3), (5, 2, 3), (3, 5, 2), (4, 5, 2), (6, 4, 9)]
    for x, y, c in blobs:
        t[y, x] = c
    return t


def tile_corniche():
    t = np.full((8, 8), 15, dtype=np.int64)
    t[3:6, :] = 4
    t[6, :] = 4
    t[7, :] = 0
    return t


def tile_bitume():
    t = np.full((8, 8), 5, dtype=np.int64)
    for y in range(8):
        for x in range(8):
            if (x * 3 + y * 7) % 10 == 0:
                t[y, x] = 6
    return t


def tile_bitume_fissure():
    t = tile_bitume()
    for x in range(8):
        y1 = x
        if 0 <= y1 < 8:
            t[y1, x] = 0
        y2 = 7 - x
        if 0 <= y2 < 8 and x % 3 != 0:
            t[y2, x] = 0
    return t


def tile_trottoir():
    t = np.full((8, 8), 6, dtype=np.int64)
    t[0, :] = 15
    t[7, :] = 0
    return t


def tile_guirlande():
    t = np.full((8, 8), TRANSPARENT_IDX, dtype=np.int64)
    t[2, 0:4] = 0
    t[3, 4:8] = 0
    t[3, 2] = 9
    t[2, 2] = 10
    t[4, 2] = 9
    t[4, 6] = 9
    t[3, 6] = 10
    t[5, 6] = 9
    return t


def _bresenham(x0, y0, x1, y1):
    pts = []
    dx, dy = abs(x1 - x0), -abs(y1 - y0)
    sx = 1 if x0 < x1 else -1
    sy = 1 if y0 < y1 else -1
    err = dx + dy
    x, y = x0, y0
    while True:
        pts.append((x, y))
        if x == x1 and y == y1:
            break
        e2 = 2 * err
        if e2 >= dy:
            err += dy
            x += sx
        if e2 <= dx:
            err += dx
            y += sy
    return pts


def _polyline(points):
    pts = []
    for i in range(len(points) - 1):
        pts.extend(_bresenham(*points[i], *points[i + 1]))
    return pts


def build_palm_crown_16():
    """Couronne de palmier 16x16 (avant decoupe en 4 tuiles 8x8) : palmes
    RETOMBANTES rayonnant depuis un coeur commun en haut-centre (x=8), chacune
    dessinee en 2 segments (vers l'exterieur puis retombant) pour la
    silhouette caracteristique d'un palmier, plutot qu'un cone de sapin."""
    g = np.full((16, 16), TRANSPARENT_IDX, dtype=np.int64)

    apex = (8, 1)
    fronds = [
        [apex, (2, 0), (0, 3)],     # gauche quasi-horizontale, retombante
        [apex, (13, 0), (15, 3)],   # droite quasi-horizontale, retombante
        [apex, (3, 1), (0, 7)],     # gauche mi-hauteur, forte retombee
        [apex, (12, 1), (15, 7)],   # droite mi-hauteur, forte retombee
        [(8, 2), (4, 4), (1, 10)],  # gauche basse, retombee prononcee
        [(8, 2), (11, 4), (14, 10)],  # droite basse, retombee prononcee
        [apex, (7, 5), (5, 9)],     # quasi verticale, leger devers gauche
        [apex, (9, 5), (11, 9)],    # quasi verticale, leger devers droit
    ]
    for f in fronds:
        for x, y in _polyline(f):
            if 0 <= x < 16 and 0 <= y < 16:
                g[y, x] = 3
                # epaissit legerement la palme (silhouette plus lisible)
                if y + 1 < 16 and g[y + 1, x] == TRANSPARENT_IDX:
                    g[y + 1, x] = 3

    # coeur du palmier : jonction sombre ou les palmes rejoignent le tronc
    for x, y in [(8, 0), (8, 1), (7, 1), (9, 2)]:
        g[y, x] = 0

    return g


_PALM_CROWN_16 = build_palm_crown_16()


def tile_palm_crown_tl():
    return _PALM_CROWN_16[0:8, 0:8].copy()


def tile_palm_crown_tr():
    return _PALM_CROWN_16[0:8, 8:16].copy()


def tile_palm_crown_bl():
    return _PALM_CROWN_16[8:16, 0:8].copy()


def tile_palm_crown_br():
    return _PALM_CROWN_16[8:16, 8:16].copy()


def tile_palm_trunk():
    # le coeur de la couronne est en x=8 du panneau 16x16, soit x=0 de la
    # moitie droite (tuiles 81/97, colonne map 14) : le tronc colle donc au
    # bord GAUCHE de sa tuile pour tomber exactement sous ce point.
    t = np.full((8, 8), TRANSPARENT_IDX, dtype=np.int64)
    t[:, 0] = 4
    t[:, 1] = 4
    for y in range(0, 8, 2):
        t[y, 1] = 0
    return t


def tile_mur_violet():
    t = np.full((8, 8), 2, dtype=np.int64)
    for y in range(8):
        for x in range(8):
            if (x * 4 + y * 5) % 9 == 0:
                t[y, x] = 1
    return t


# tuile 64 = row*16+col ; toutes nos tuiles vivent en rangees 4-6 (y 32-55).
TILES = {
    64: tile_facade_rose(),
    65: tile_window_rose(),
    66: tile_facade_ocre(),
    67: tile_window_ocre(),
    68: tile_facade_turquoise(),
    69: tile_window_turquoise(),
    70: tile_porte_bois(),
    71: tile_tole_rouillee(),
    72: tile_mur_beton(),
    73: tile_graffiti_a(),
    74: tile_graffiti_b(),
    75: tile_corniche(),
    76: tile_bitume(),
    77: tile_bitume_fissure(),
    78: tile_trottoir(),
    79: tile_guirlande(),
    80: tile_palm_crown_tl(),
    81: tile_palm_crown_tr(),
    82: tile_palm_trunk(),
    83: tile_mur_violet(),
    96: tile_palm_crown_bl(),
    97: tile_palm_crown_br(),
}


# ---------------------------------------------------------------------------
# Composition de la feuille 128x128
# ---------------------------------------------------------------------------
def build_sheet():
    sheet = np.zeros((128, 128), dtype=np.int64)

    volt = draw_volt()
    torque = extract_torque()
    sheet[0:32, 0:24] = volt
    sheet[0:32, 24:48] = torque

    for idx, tile in TILES.items():
        row, col = divmod(idx, 16)
        y0, x0 = row * 8, col * 8
        sheet[y0:y0 + 8, x0:x0 + 8] = tile

    return sheet, volt, torque


# ---------------------------------------------------------------------------
# Composition de la map 16x16 (contrat) -> map complete 128x32 (reste = 0)
# ---------------------------------------------------------------------------
def build_map():
    m = np.zeros((32, 128), dtype=np.int64)

    def put(col, row, idx):
        m[row, col] = idx

    def fill(col0, col1, row0, row1, idx):
        m[row0:row1 + 1, col0:col1 + 1] = idx

    # guirlande lumineuse
    fill(3, 12, 1, 1, 79)

    # batiment rose/ocre (cols 0-5)
    fill(0, 5, 4, 4, 75)          # corniche
    fill(0, 5, 5, 7, 64)          # facade rose
    for (c, r) in [(1, 5), (3, 5), (1, 6), (3, 6)]:
        put(c, r, 65)
    fill(0, 5, 8, 8, 71)          # auvent tole
    fill(0, 5, 9, 11, 66)         # facade ocre
    put(2, 10, 70)
    put(2, 11, 70)
    put(4, 9, 67)

    # batiment turquoise (cols 9-12)
    fill(9, 12, 5, 5, 75)         # corniche
    fill(9, 12, 6, 11, 68)        # facade turquoise
    for (c, r) in [(10, 6), (12, 6), (10, 8), (12, 8)]:
        put(c, r, 69)
    put(11, 10, 70)
    put(11, 11, 70)

    # mur violet entre les batiments
    fill(6, 8, 9, 11, 83)

    # mur graffiti + palmier (cols 13-15)
    fill(13, 15, 8, 8, 72)
    put(13, 9, 73); put(14, 9, 74); put(15, 9, 73)
    put(13, 10, 74); put(14, 10, 73); put(15, 10, 74)
    fill(13, 15, 11, 11, 72)
    # palmier plus grand : couronne montee d'une rangee (3-4), tronc allonge
    # (5-7) ; le tronc (colonne 14) tombe sous le coeur de la couronne, cf.
    # tile_palm_trunk()/build_palm_crown_16().
    put(13, 3, 80); put(14, 3, 81)
    put(13, 4, 96); put(14, 4, 97)
    put(14, 5, 82); put(14, 6, 82); put(14, 7, 82)

    # sol
    fill(0, 15, 12, 12, 78)       # trottoir
    fill(0, 15, 13, 15, 76)       # bitume
    for row in range(13, 16):
        for col in range(0, 16):
            if (col + row) % 4 == 0:
                put(col, row, 77)

    return m


# ---------------------------------------------------------------------------
# Injection __gfx__ / __map__ dans main.p8 (remplace les sections existantes
# -> idempotent). Le reste du fichier (header + __lua__ + #include) n'est pas
# touche.
# ---------------------------------------------------------------------------
def strip_section(lines, header):
    """Retire la section `header` (de la ligne d'en-tete jusqu'a la prochaine
    ligne __xxx__ ou l'EOF), le cas echeant. Renvoie la nouvelle liste de
    lignes."""
    if header not in lines:
        return lines
    start = lines.index(header)
    end = start + 1
    while end < len(lines) and not (lines[end].startswith("__") and lines[end].endswith("__")):
        end += 1
    return lines[:start] + lines[end:]


def inject_sections(gfx_rows, map_rows):
    with open(MAIN_P8, "r", encoding="utf-8", newline="") as f:
        content = f.read()
    lines = content.replace("\r\n", "\n").split("\n")
    # retire un eventuel dernier element vide issu du split (fin de fichier
    # sur un \n) pour eviter de dupliquer des lignes vides a chaque run.
    while lines and lines[-1] == "":
        lines.pop()

    lines = strip_section(lines, "__gfx__")
    lines = strip_section(lines, "__map__")

    lines.append("__gfx__")
    lines.extend(gfx_rows)
    lines.append("__map__")
    lines.extend(map_rows)

    new_content = "\n".join(lines) + "\n"
    with open(MAIN_P8, "w", encoding="utf-8", newline="\n") as f:
        f.write(new_content)


# ---------------------------------------------------------------------------
# main
# ---------------------------------------------------------------------------
def main():
    sheet, volt, torque = build_sheet()
    m = build_map()

    assert sheet.shape == (128, 128)
    assert set(np.unique(sheet).tolist()) <= set(range(16))

    volt_img = grid_to_rgb_image(volt)
    torque_img = grid_to_rgb_image(torque)
    sheet_img = grid_to_rgb_image(sheet)

    volt_img.save(os.path.join(ASSETS_DIR, "volt.png"))
    torque_img.save(os.path.join(ASSETS_DIR, "torque.png"))
    sheet_img.save(os.path.join(ASSETS_DIR, "sheet.png"))

    gfx_rows = grid_to_hex_rows(sheet)
    assert len(gfx_rows) == 128 and all(len(r) == 128 for r in gfx_rows)

    map_rows = []
    for row in range(32):
        map_rows.append("".join("{:02x}".format(int(v)) for v in m[row]))
    assert len(map_rows) == 32 and all(len(r) == 256 for r in map_rows)

    inject_sections(gfx_rows, map_rows)

    print("assets ecrits :")
    print("  -", os.path.join(ASSETS_DIR, "volt.png"), volt_img.size)
    print("  -", os.path.join(ASSETS_DIR, "torque.png"), torque_img.size)
    print("  -", os.path.join(ASSETS_DIR, "sheet.png"), sheet_img.size)
    print("  -", MAIN_P8, "(sections __gfx__ / __map__ mises a jour)")
    print()
    print("Import manuel alternatif depuis PICO-8 (si tu preferes ne pas")
    print("relancer ce script) :")
    print("  1. lance PICO-8, `load main.p8`")
    print("  2. Esc -> onglet sprite editor")
    print("  3. commande console : import assets/sheet.png")
    print("  4. `save main.p8` pour re-ecrire les sections gfx/map propres")


if __name__ == "__main__":
    main()
