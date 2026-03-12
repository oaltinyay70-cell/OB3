import sqlite3
import os
import glob

DB_PATH = "/Users/ozgur/.gemini/antigravity/playground/tidal-comet/assets/db/ob3.db"
ARTIFACTS_DIR = "/Users/ozgur/.gemini/antigravity/brain/cf68186a-400b-4ecd-b33c-5c57d6bf2b30"

# (table, column, glob_pattern, card_number_or_None)
MAPPINGS = [
    # Card Backs
    ("target_cards", "back_image", "card_back_target_*.png", None),
    ("threat_cards", "back_image", "card_back_threat_*.png", None),
    ("combat_cards", "back_image", "card_back_combat_*.png", None),

    # Batch 1: Tanks
    ("target_cards", "image", "card_gold_t90_v3_*.png", "TCTA001"),
    ("target_cards", "image", "card_gold_t34_v3_*.png", "TCTA002"),
    ("target_cards", "image", "card_gold_t80u_v3_*.png", "TCTA003"),
    ("target_cards", "image", "card_gold_t72b3_v3_*.png", "TCTA004"),
    ("target_cards", "image", "card_gold_leo2a6_v3_*.png", "TCTA005"),

    # Batch 2: SAM Targets
    ("target_cards", "image", "card_target_s400a_v2_*.png", "TCSA002"),
    ("target_cards", "image", "card_target_buk_v2_*.png", "TCSA003"),
    ("target_cards", "image", "card_target_tor_v2_*.png", "TCSA006"),
    ("target_cards", "image", "card_target_pantsir_v2_*.png", "TCSA013"),

    # Batch 2: CAP Threats
    ("threat_cards", "image", "card_threat_mig29_v2_*.png", "THCAP004"),
    ("threat_cards", "image", "card_threat_su27_v2_*.png", "THCAP003"),
    ("threat_cards", "image", "card_threat_f16_v2_*.png", "THCAP011"),
    ("threat_cards", "image", "card_threat_f4e_v2_*.png", "THCAP015"),

    # Batch 3: AFV & Artillery
    ("target_cards", "image", "card_target_bmp2_v2_*.png", "TCAF002"),
    ("target_cards", "image", "card_target_btr82_v2_*.png", "TCAF004"),
    ("target_cards", "image", "card_target_gvozdika_v2_*.png", "TCAR017"),
    ("target_cards", "image", "card_target_bm21_v2_*.png", "TCAR004"),

    # Batch 4: HQ, Personnel & VIP
    ("target_cards", "image", "card_target_bunker_fix_*.png", "TCHB001"),
    ("target_cards", "image", "card_target_squad_fix_*.png", "TCPE001"),
    ("target_cards", "image", "card_target_general_fix_*.png", "TCVI006"),
    ("target_cards", "image", "card_target_truck_fix_*.png", "TCTR001"),

    # Batch 5: Combat Events
    ("combat_cards", "image", "card_combat_world_*.png", "CC001"),
    ("combat_cards", "image", "card_combat_comms_*.png", "CC002"),
    ("combat_cards", "image", "card_combat_cap_*.png", "CC006"),
    ("combat_cards", "image", "card_combat_local_*.png", "CC013"),
]


def main():
    if not os.path.exists(DB_PATH):
        print(f"ERROR: Database not found at {DB_PATH}")
        return

    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()
    print(f"Connected: {DB_PATH}")
    print(f"Mappings: {len(MAPPINGS)}")
    print("=" * 60)

    ok, skip, fail = 0, 0, 0

    for table, column, pattern, card_num in MAPPINGS:
        label = f"{card_num or 'ALL'} -> {table}.{column}"
        matches = glob.glob(os.path.join(ARTIFACTS_DIR, pattern))

        if not matches:
            print(f"  [SKIP] {label} — no file for '{pattern}'")
            skip += 1
            continue

        latest = max(matches, key=os.path.getmtime)
        with open(latest, 'rb') as f:
            blob = f.read()

        try:
            if card_num is None:
                cursor.execute(f"UPDATE {table} SET {column} = ?", (blob,))
            else:
                cursor.execute(
                    f"UPDATE {table} SET {column} = ? WHERE card_number = ?",
                    (blob, card_num),
                )
            n = cursor.rowcount
            if n > 0:
                print(f"  [OK]   {label} — {n} row(s), {len(blob):,}b")
                ok += 1
            else:
                print(f"  [WARN] {label} — 0 rows (card_number not in DB?)")
                fail += 1
        except Exception as e:
            print(f"  [FAIL] {label} — {e}")
            fail += 1

    conn.commit()
    conn.close()
    print("=" * 60)
    print(f"Done. OK={ok} SKIP={skip} FAIL={fail}")


if __name__ == "__main__":
    main()
