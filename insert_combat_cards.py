import sqlite3
import os

db_path = "/Users/ozgur/.gemini/antigravity/playground/tidal-comet/assets/db/ob3.db"
conn = sqlite3.connect(db_path)
c = conn.cursor()

new_cards = [
    # (card_number, card_type, card_name, instruction, instructions)
    # The schema has 'instruction' (NOT NULL) and 'instructions' (nullable). We'll use 'instruction' for flavor text and 'instructions' for effect text.
    ('NEW_CC_01', 'COMBAT', 'AGGRESSIVE STRIKE PROFILE', '"Maverick\'s flying. Duck."', 'Attack DRM: +2\nApply +2 to all attack rolls.'),
    ('NEW_CC_02', 'COMBAT', 'WHITEOUT', '"Winter is here. Targeting is not."', 'Attack DRM: -2\nApply -2 to all attack rolls.'),
    ('NEW_CC_03', 'COMBAT', 'TAILWIND', '"The Force is strong with this one."', 'Attack DRM: +1\nApply +1 to all attack rolls.'),
    ('NEW_CC_04', 'COMBAT', 'STATIC', '"Houston, we have a problem."', 'Attack DRM: -1\nApply -1 to all attack rolls.'),
    ('NEW_CC_05', 'COMBAT', 'LOST SIGNAL', '"E.T. can\'t phone home either."', 'Attack DRM: -2\nApply -2 to all attack rolls.'),
    ('NEW_CC_06', 'COMBAT', 'CLEAR SKIES', '"I see dead targets."', 'Attack DRM: +2\nApply +2 to all attack rolls.'),
    ('NEW_CC_07', 'COMBAT', 'GROUND HUGGING', '"Keep your friends close. Keep your altitude lower."', 'Attack DRM: +1\nApply +1 to all attack rolls at Very Low or Low altitude.'),
    ('NEW_CC_08', 'COMBAT', 'UPDRAFT', '"Physics has opinions."', 'Attack DRM: -1\nApply -1 to all attack rolls.'),
    ('NEW_CC_09', 'COMBAT', 'GHOST SIGNAL', '"These aren\'t the targets you\'re looking for."', 'Attack DRM: -1\nApply -1 to all attack rolls. FO/Laze mode unaffected.'),
    ('NEW_CC_10', 'COMBAT', 'BURST TRANSMISSION', '"One ping only, please."', 'Attack DRM: +1\nApply +1 to all attack rolls.'),
    ('NEW_CC_11', 'COMBAT', 'FOG OF WAR', '"I love the smell of confusion in the morning."', 'Attack DRM: -2\nApply -2 to all attack rolls.'),
    ('NEW_CC_12', 'COMBAT', 'THERMAL SPIKE', '"To infinity — starting with one altitude level."', 'Altitude Change: +1 to altitude level.'),
    ('NEW_CC_13', 'COMBAT', 'DIVE DIVE DIVE', '"Just keep swimming. Lower."', 'Altitude Change: -1 to altitude level.'),
    ('NEW_CC_14', 'COMBAT', 'DEAD DROP', '"What goes up, must go down. Immediately."', 'Altitude Change: -1 to altitude level.'),
    ('NEW_CC_15', 'COMBAT', 'STRATOSPHERIC', '"I\'m on top of the world, Ma."', 'Altitude Change: +2 to altitude levels.'),
    ('NEW_CC_16', 'COMBAT', 'NOSEDIVE', '"Hello darkness, my old friend."', 'Altitude Change: -2 to altitude levels.'),
    ('NEW_CC_17', 'COMBAT', 'DECK LEVEL', '"Why so serious? Fly lower."', 'Altitude Change: Forced to VERY LOW.'),
    ('NEW_CC_18', 'COMBAT', 'TOP GUN', '"You can be my wingman any time."', 'Altitude Change: Forced to HIGH.'),
    ('NEW_CC_19', 'COMBAT', 'NO EVENT', 'No effect.', 'Discard without action.')
]

inserted_count = 0
for card in new_cards:
    try:
        c.execute("""
            INSERT INTO combat_cards (card_number, card_type, card_name, instruction, instructions)
            VALUES (?, ?, ?, ?, ?)
        """, card)
        inserted_count += 1
    except sqlite3.IntegrityError:
        print(f"Card {card[0]} already exists. Skipping.")

# Update the build_editor.py script to pull from DB instead of hardcoded strings
try:
    c.execute("ALTER TABLE combat_cards ADD COLUMN attribute_effect TEXT;")
except sqlite3.OperationalError:
    pass # column probably exists

for card in new_cards:
    effect_summary = card[4].split('\\n')[0]
    c.execute("UPDATE combat_cards SET attribute_effect = ? WHERE card_number = ?", (effect_summary, card[0]))

conn.commit()
conn.close()

print(f"Successfully inserted/updated {inserted_count} combat cards.")
