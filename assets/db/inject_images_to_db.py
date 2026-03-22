import sqlite3, glob, os

DB = '/Users/ozgur/.gemini/antigravity/playground/tidal-comet/assets/db/ob3.db'
DIR = '/Users/ozgur/.gemini/antigravity/brain/cf68186a-400b-4ecd-b33c-5c57d6bf2b30'

MAPPINGS = [
    # Card Backs
    ('target_cards', 'back_image', 'card_back_target_*.png', None),
    ('threat_cards', 'back_image', 'card_back_threat_*.png', None),
    ('combat_cards', 'back_image', 'card_back_combat_*.png', None),

    # Batch 1: Tanks
    ('target_cards', 'image', 'card_gold_t90_v3_*.png', 'TCTA001'),
    ('target_cards', 'image', 'card_gold_t34_v3_*.png', 'TCTA002'),
    ('target_cards', 'image', 'card_gold_t80u_v3_*.png', 'TCTA003'),
    ('target_cards', 'image', 'card_gold_t72b3_v3_*.png', 'TCTA004'),
    ('target_cards', 'image', 'card_gold_leo2a6_v3_*.png', 'TCTA005'),

    # Batch 2: SAM Targets
    ('target_cards', 'image', 'card_target_s400a_v2_*.png', 'TCSA002'),
    ('target_cards', 'image', 'card_target_buk_v2_*.png', 'TCSA003'),
    ('target_cards', 'image', 'card_target_tor_v2_*.png', 'TCSA006'),
    ('target_cards', 'image', 'card_target_pantsir_v2_*.png', 'TCSA013'),

    # Batch 2: CAP Threats (FIXED card_numbers)
    ('threat_cards', 'image', 'card_threat_mig29_v2_*.png', 'THCAP004'),
    ('threat_cards', 'image', 'card_threat_su27_v2_*.png', 'THCAP003'),
    ('threat_cards', 'image', 'card_threat_f16_v2_*.png', 'THCAP011'),
    ('threat_cards', 'image', 'card_threat_f4e_v2_*.png', 'THCAP008'),  # was THCAP015

    # Batch 3: AFV & Artillery
    ('target_cards', 'image', 'card_target_bmp2_v2_*.png', 'TCAF002'),
    ('target_cards', 'image', 'card_target_btr82_v2_*.png', 'TCAF004'),
    ('target_cards', 'image', 'card_target_gvozdika_v2_*.png', 'TCAR017'),
    ('target_cards', 'image', 'card_target_bm21_v2_*.png', 'TCAR004'),

    # Batch 4: HQ, Personnel & VIP (FIXED card_number)
    ('target_cards', 'image', 'card_target_bunker_fix_*.png', 'TCHB001'),
    ('target_cards', 'image', 'card_target_squad_fix_*.png', 'TCPE001'),
    ('target_cards', 'image', 'card_target_general_fix_*.png', 'TCVI006'),
    ('target_cards', 'image', 'card_target_truck_fix_*.png', 'TCTK004'),  # was TCTR001

    # Batch 5: Original Combat Events
    ('combat_cards', 'image', 'card_combat_world_*.png', 'CC001'),
    ('combat_cards', 'image', 'card_combat_comms_*.png', 'CC002'),
    ('combat_cards', 'image', 'card_combat_cap_*.png', 'CC006'),
    ('combat_cards', 'image', 'card_combat_local_*.png', 'CC013'),

    # Batch 6: NEW Combat Cards (19 cards)
    ('combat_cards', 'image', 'card_combat_aggressive_*.png', 'NEW_CC_01'),
    ('combat_cards', 'image', 'card_combat_whiteout_*.png', 'NEW_CC_02'),
    ('combat_cards', 'image', 'card_combat_tailwind_*.png', 'NEW_CC_03'),
    ('combat_cards', 'image', 'card_combat_static_*.png', 'NEW_CC_04'),
    ('combat_cards', 'image', 'card_combat_lostsignal_*.png', 'NEW_CC_05'),
    ('combat_cards', 'image', 'card_combat_clearskies_*.png', 'NEW_CC_06'),
    ('combat_cards', 'image', 'card_combat_groundhug_*.png', 'NEW_CC_07'),
    ('combat_cards', 'image', 'card_combat_updraft_*.png', 'NEW_CC_08'),
    ('combat_cards', 'image', 'card_combat_ghostsignal_*.png', 'NEW_CC_09'),
    ('combat_cards', 'image', 'card_combat_burst_*.png', 'NEW_CC_10'),
    ('combat_cards', 'image', 'card_combat_fogofwar_*.png', 'NEW_CC_11'),
    ('combat_cards', 'image', 'card_combat_thermalspike_*.png', 'NEW_CC_12'),
    ('combat_cards', 'image', 'card_combat_dive_*.png', 'NEW_CC_13'),
    ('combat_cards', 'image', 'card_combat_deaddrop_*.png', 'NEW_CC_14'),
    ('combat_cards', 'image', 'card_combat_stratospheric_*.png', 'NEW_CC_15'),
    ('combat_cards', 'image', 'card_combat_nosedive_*.png', 'NEW_CC_16'),
    ('combat_cards', 'image', 'card_combat_decklevel_*.png', 'NEW_CC_17'),
    ('combat_cards', 'image', 'card_combat_topgun_*.png', 'NEW_CC_18'),
    ('combat_cards', 'image', 'card_combat_noevent2_*.png', 'NEW_CC_19'),
]

conn = sqlite3.connect(DB)
c = conn.cursor()
print(f'Connected: {DB}')
print(f'Mappings: {len(MAPPINGS)}')
print('=' * 60)
ok, skip, fail = 0, 0, 0

for table, col, pat, cnum in MAPPINGS:
    label = f'{cnum or "ALL"} -> {table}.{col}'
    matches = glob.glob(os.path.join(DIR, pat))
    if not matches:
        print(f'  [SKIP] {label}')
        skip += 1
        continue
    latest = max(matches, key=os.path.getmtime)
    with open(latest, 'rb') as f:
        blob = f.read()
    if cnum is None:
        c.execute(f'UPDATE {table} SET {col} = ?', (blob,))
    else:
        c.execute(f'UPDATE {table} SET {col} = ? WHERE card_number = ?', (blob, cnum))
    n = c.rowcount
    if n > 0:
        print(f'  [OK]   {label} — {n} row(s), {len(blob):,}b')
        ok += 1
    else:
        print(f'  [WARN] {label} — 0 rows')
        fail += 1

conn.commit()
conn.close()
print('=' * 60)
print(f'Done. OK={ok} SKIP={skip} FAIL={fail}')
