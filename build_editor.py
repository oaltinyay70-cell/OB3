import sqlite3
import json
import os

db_path = "/Users/ozgur/.gemini/antigravity/playground/tidal-comet/assets/db/drone_commander_cards.db"
html_path = "/Users/ozgur/.gemini/antigravity/playground/tidal-comet/scenario_editor.html"

conn = sqlite3.connect(db_path)
c = conn.cursor()

# Get Drones
try:
    c.execute("SELECT name FROM drones ORDER BY id")
    drones = [row[0] for row in c.fetchall()]
except Exception:
    drones = ["Bayraktar TB2", "MQ-9 Reaper", "Unknown"]

# Get Combat Cards
try:
    c.execute("SELECT name, attribute_effect FROM combat_cards ORDER BY id")
    combat_cards = [f"{row[0]} ({row[1]})" for row in c.fetchall()]
except Exception:
    combat_cards = [
        "AGGRESSIVE STRIKE PROFILE (+2)", "CLEAR SKIES (+2)", "TAILWIND (+1)", 
        "BURST TRANSMISSION (+1)", "GROUND HUGGING (+1 VLOW/LOW)", "WHITEOUT (-2)", 
        "LOST SIGNAL (-2)", "FOG OF WAR (-2)", "STATIC (-1)", "UPDRAFT (-1)", 
        "GHOST SIGNAL (-1 no FO)", "THERMAL SPIKE (Alt +1)", "STRATOSPHERIC (Alt +2)", 
        "TOP GUN (Force HIGH)", "DIVE DIVE DIVE (Alt -1)", "DEAD DROP (Alt -1)", 
        "NOSEDIVE (Alt -2)", "DECK LEVEL (Force VLOW)", "NO EVENT (Blank)"
    ]

# Get Target Cards
try:
    c.execute("SELECT card_number, card_name, card_type FROM target_cards ORDER BY card_number")
    target_cards = [f"[{row[0]}] {row[1]} ({row[2]})" for row in c.fetchall()]
except Exception as e:
    target_cards = ["Failed to load from DB: " + str(e)]

# Get Threat Cards
try:
    c.execute("SELECT card_number, card_name, card_type FROM threat_cards ORDER BY card_number")
    threat_cards = [f"[{row[0]}] {row[1]} ({row[2]})" for row in c.fetchall()]
except Exception as e:
    threat_cards = ["Failed to load from DB: " + str(e)]

conn.close()

html_content = f"""<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>OB3 Advanced Scenario Editor (v3.0 DB Linked)</title>
    <style>
        body {{ font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif; background-color: #1e1e1e; color: #f4f4f4; max-width: 900px; margin: 0 auto; padding: 20px; }}
        h1 {{ border-bottom: 1px solid #333; padding-bottom: 10px; color: #fff; }}
        .form-group {{ margin-bottom: 20px; }}
        label {{ display: block; margin-bottom: 5px; font-weight: bold; color: #aaa; }}
        input[type="text"], textarea, select, input[type="number"] {{ width: 100%; padding: 10px; background-color: #2d2d2d; border: 1px solid #444; color: #fff; border-radius: 4px; box-sizing: border-box; font-family: inherit; }}
        input[type="number"] {{ width: 80px; text-align: center; margin-left: 10px; }}
        textarea {{ height: 80px; resize: vertical; }}
        .btn {{ background-color: #007acc; color: white; padding: 12px 20px; border: none; border-radius: 4px; cursor: pointer; font-size: 16px; font-weight: bold; width: 100%; margin-top: 20px;}}
        .btn:hover {{ background-color: #005999; }}
        .section-title {{ font-size: 1.2em; color: #007acc; margin-top: 30px; margin-bottom: 15px; border-bottom: 1px solid #333; padding-bottom: 5px; }}
        
        .grid-container {{ display: grid; grid-template-columns: 1fr 1fr; gap: 10px; background: #252525; padding: 15px; border-radius: 6px; border: 1px solid #333; }}
        .checkbox-row {{ display: flex; align-items: center; margin-bottom: 8px; }}
        .checkbox-row input[type="checkbox"] {{ margin-right: 10px; width: 18px; height: 18px; }}
        .card-row {{ display: flex; justify-content: space-between; align-items: center; margin-bottom: 8px; border-bottom: 1px solid #333; padding-bottom: 5px;}}
        
        .objective-box {{ background: #252525; padding: 15px; border-radius: 6px; border: 1px solid #333; margin-bottom: 15px;}}
        
        #output-container {{ margin-top: 30px; display: none; margin-bottom: 50px;}}
        pre {{ background-color: #111; padding: 15px; border-radius: 4px; overflow-x: auto; border: 1px solid #333; white-space: pre-wrap;}}
        .copy-btn {{ margin-top: 10px; background-color: #2ea043; }}
        .copy-btn:hover {{ background-color: #238636; }}
        
        .flex-row {{ display: flex; gap: 15px; align-items: flex-end;}}
    </style>
</head>
<body>

    <h1>OB3 Scenario Editor - v3.0 (DB Linked)</h1>
    <p>Target and Threat decks are now populated directly from the game database.</p>

    <!-- BASIC INFO -->
    <div class="form-group">
        <label>Scenario Name</label>
        <input type="text" id="s_name" value="The Milk run">
    </div>
    <div class="form-group">
        <label>Scenario Subtitle</label>
        <input type="text" id="s_subtitle">
    </div>
    <div class="form-group">
        <label>Scenario Visuals (Path/URL/Description)</label>
        <input type="text" id="s_visuals" placeholder="e.g. assets/scenarios/milk_run_map.png">
    </div>
    <div class="form-group">
        <label>Scenario Main Text (Briefing)</label>
        <textarea id="s_briefing"></textarea>
    </div>

    <!-- DRONES -->
    <div class="section-title">Allowed Drones</div>
    <div style="text-align: right; margin-bottom: 5px;">
        <button onclick="toggleAll('drone', true)" style="background: none; color: #007acc; border: none; cursor: pointer;">Select All</button> | 
        <button onclick="toggleAll('drone', false)" style="background: none; color: #007acc; border: none; cursor: pointer;">Deselect All</button>
    </div>
    <div class="grid-container" id="drone-container"></div>

    <!-- OBJECTIVES -->
    <div class="section-title">Objectives</div>
    
    <div class="objective-box">
        <label style="color: #fff">Primary Objective</label>
        <div class="flex-row" style="margin-bottom: 10px;">
            <div style="flex-grow:1">
                <label style="font-size: 0.8em; font-weight: normal;">Target required to kill</label>
                <select id="obj_p_card">
                    <option value="ANY TANK">Any TANK Type</option>
                    <option value="ANY RADAR">Any RADAR Type</option>
                    <option value="ANY SAM">Any SAM Type</option>
                    <option value="ANY HQ">Any HQ Type</option>
                    <option value="ANY INFANTRY">Any INFANTRY Type</option>
                    <option disabled>──────────</option>
                    <!-- DB targets injected here via JS -->
                </select>
            </div>
            <div>
                <label style="font-size: 0.8em; font-weight: normal;">Quantity</label>
                <input type="number" id="obj_p_qty" value="1" min="1" max="99" style="margin-left: 0;">
            </div>
        </div>
        <label style="font-size: 0.8em; font-weight: normal;">Objective Text Explanation</label>
        <input type="text" id="obj_p_text" placeholder="e.g. Destroy the primary enemy armor column">
    </div>

    <div class="objective-box">
        <label style="color: #fff">Secondary Objective</label>
        <div class="flex-row" style="margin-bottom: 10px;">
            <div style="flex-grow:1">
                <label style="font-size: 0.8em; font-weight: normal;">Target required to kill</label>
                <select id="obj_s_card">
                    <option value="NONE">None</option>
                    <option value="ANY TANK">Any TANK Type</option>
                    <option value="ANY RADAR">Any RADAR Type</option>
                    <option value="ANY SAM">Any SAM Type</option>
                    <option value="ANY HQ">Any HQ Type</option>
                    <option value="ANY INFANTRY">Any INFANTRY Type</option>
                    <option value="ALL TARGETS">Clear the board</option>
                    <option disabled>──────────</option>
                    <!-- DB targets injected here via JS -->
                </select>
            </div>
            <div>
                <label style="font-size: 0.8em; font-weight: normal;">Quantity</label>
                <input type="number" id="obj_s_qty" value="1" min="1" max="99" style="margin-left: 0;">
            </div>
        </div>
        <label style="font-size: 0.8em; font-weight: normal;">Objective Text Explanation</label>
        <input type="text" id="obj_s_text" placeholder="e.g. Eliminate early warning radar for bonus VP">
    </div>

    <!-- COMBAT DECK -->
    <div class="section-title">Combat Deck Composition</div>
    <div class="grid-container" id="combat-container"></div>

    <!-- TARGET DECK -->
    <div class="section-title">Target Deck Composition</div>
    <div style="text-align: right; margin-bottom: 5px;">
        <button onclick="setAll('tc', 0)" style="background: none; color: #007acc; border: none; cursor: pointer;">Zero All</button> | 
        <button onclick="setAll('tc', 1)" style="background: none; color: #007acc; border: none; cursor: pointer;">1 of Each</button>
    </div>
    <div class="grid-container" id="target-container"></div>

    <!-- THREAT DECK -->
    <div class="section-title">Threat Deck Composition</div>
    <div style="text-align: right; margin-bottom: 5px;">
        <button onclick="setAll('th', 0)" style="background: none; color: #007acc; border: none; cursor: pointer;">Zero All</button> | 
        <button onclick="setAll('th', 1)" style="background: none; color: #007acc; border: none; cursor: pointer;">1 of Each</button>
    </div>
    <div class="grid-container" id="threat-container"></div>

    <!-- SPECIAL RULES -->
    <div class="section-title">Special Rules</div>
    <div class="form-group">
        <textarea id="s_special" placeholder="e.g. Fuel consumption is doubled">None</textarea>
    </div>

    <button class="btn" onclick="generateOutput()">Generate Scenario Data</button>

    <div id="output-container">
        <h3>Generated Output (Copy this to the agent):</h3>
        <pre id="output-text"></pre>
        <button class="btn copy-btn" onclick="copyToClipboard()">Copy to Clipboard</button>
        <span id="copy-status" style="margin-left: 10px; color: #2ea043; display: none;">Copied!</span>
    </div>

    <script>
        const drones = {json.dumps(drones)};
        const combatCards = {json.dumps(combat_cards)};
        const targetCards = {json.dumps(target_cards)};
        const threatCards = {json.dumps(threat_cards)};

        // Render Drones
        const droneCont = document.getElementById('drone-container');
        drones.forEach((d, i) => {{
            droneCont.innerHTML += `
                <div class="checkbox-row">
                    <input type="checkbox" id="drone_${{i}}" class="drone-cb" checked data-name="${{d}}">
                    <label for="drone_${{i}}" style="margin:0; font-weight:normal; color:#ddd">${{d}}</label>
                </div>
            `;
        }});

        function toggleAll(type, state) {{
            document.querySelectorAll(`.${{type}}-cb`).forEach(cb => cb.checked = state);
        }}
        
        function setAll(prefix, val) {{
            document.querySelectorAll(`.${{prefix}}-num`).forEach(inp => {{
                inp.value = val;
                const cb = document.getElementById(inp.id.replace('num', 'cb'));
                if (cb) cb.checked = (val > 0);
                inp.disabled = (val == 0);
            }});
        }}

        // Render Decks function
        function renderDeck(containerId, prefix, cards, defaultActiveIdx, defaultQty) {{
            const cont = document.getElementById(containerId);
            cards.forEach((card, i) => {{
                // for combat deck NO EVENT
                const isDefault = defaultActiveIdx && card.includes(defaultActiveIdx);
                const qty = isDefault ? 10 : defaultQty;
                const chk = qty > 0 ? "checked" : "";
                const dis = qty > 0 ? "" : "disabled";
                
                cont.innerHTML += `
                    <div class="card-row" style="flex-direction: column; align-items: flex-start;">
                        <div class="checkbox-row" style="margin:0; width: 100%; margin-bottom: 5px;">
                            <input type="checkbox" id="${{prefix}}_cb_${{i}}" class="${{prefix}}-cb" ${{chk}} onchange="toggleNum('${{prefix}}_num_${{i}}', this.checked)">
                            <label for="${{prefix}}_cb_${{i}}" style="margin:0; font-weight:normal; color:#aaa; font-size:0.85em; width:100%; white-space: normal;" title="${{card.replace(/"/g, '&quot;')}}">${{card}}</label>
                        </div>
                        <div style="display: flex; align-items: center; justify-content: space-between; width: 100%;">
                            <span style="font-size: 0.7em; color: #666;">Copies:</span>
                            <input type="number" id="${{prefix}}_num_${{i}}" class="${{prefix}}-num" value="${{qty}}" min="1" max="50" ${{dis}} data-name="${{card.replace(/"/g, '&quot;')}}" style="width: 50px; padding: 5px; height: 25px;">
                        </div>
                    </div>
                `;
            }});
        }}

        function toggleNum(id, isChecked) {{
            const el = document.getElementById(id);
            el.disabled = !isChecked;
            if (isChecked && el.value == 0) el.value = 1;
        }}

        // Render Deck lists
        renderDeck('combat-container', 'cc', combatCards, 'NO EVENT', 0);
        renderDeck('target-container', 'tc', targetCards, null, 0);
        renderDeck('threat-container', 'th', threatCards, null, 0);

        // Populate Objective dropdowns with Target cards
        const pCard = document.getElementById('obj_p_card');
        const sCard = document.getElementById('obj_s_card');
        targetCards.forEach(tc => {{
            pCard.innerHTML += `<option value="${{tc}}">${{tc}}</option>`;
            sCard.innerHTML += `<option value="${{tc}}">${{tc}}</option>`;
        }});

        function getDeckString(prefix) {{
            const arr = [];
            document.querySelectorAll(`.${{prefix}}-cb:checked`).forEach(cb => {{
                const numInput = document.getElementById(cb.id.replace('cb', 'num'));
                const qty = numInput.value;
                const name = numInput.getAttribute('data-name');
                if (qty > 0) arr.push(`- ${{qty}}x ${{name}}`);
            }});
            return arr.length > 0 ? arr.join("\\n") : "None";
        }}

        function generateOutput() {{
            const getVal = (id) => document.getElementById(id).value.trim() || 'N/A';
            
            const selectedDrones = [];
            const isAllDrones = document.querySelectorAll('.drone-cb:not(:checked)').length === 0;
            if (isAllDrones) {{
                selectedDrones.push("ALL DRONES ALLOWED");
            }} else {{
                document.querySelectorAll('.drone-cb:checked').forEach(cb => {{
                    selectedDrones.push("- " + cb.getAttribute('data-name'));
                }});
            }}

            const md = `### SCENARIO DEFINITION: ${{getVal('s_name')}}

**Subtitle:** ${{getVal('s_subtitle')}}
**Visuals/Map:** ${{getVal('s_visuals')}}

**Briefing/Main Text:** 
${{getVal('s_briefing')}}

**Allowed Drones:** 
${{selectedDrones.length === 0 ? "NONE SELECTED" : (isAllDrones ? "ALL DRONES ALLOWED" : selectedDrones.join("\\n"))}}

#### OBJECTIVES:
**Primary:** 
- Target Required: ${{getVal('obj_p_card')}} x${{getVal('obj_p_qty')}}
- Narrative: ${{getVal('obj_p_text')}}

**Secondary:** 
- Target Required: ${{getVal('obj_s_card')}} x${{getVal('obj_s_qty')}}
- Narrative: ${{getVal('obj_s_text')}}

#### DECK COMPOSITION:
**Combat Deck:**
${{getDeckString('cc')}}

**Target Deck:**
${{getDeckString('tc')}}

**Threat Deck:**
${{getDeckString('th')}}

**Special Rules:**
${{getVal('s_special')}}`;

            document.getElementById('output-text').textContent = md;
            document.getElementById('output-container').style.display = 'block';
            window.scrollTo(0, document.body.scrollHeight);
        }}

        function copyToClipboard() {{
            const text = document.getElementById('output-text').textContent;
            navigator.clipboard.writeText(text).then(() => {{
                const status = document.getElementById('copy-status');
                status.style.display = 'inline';
                setTimeout(() => status.style.display = 'none', 2000);
            }});
        }}
    </script>
</body>
</html>
"""

with open(html_path, "w", encoding="utf-8") as f:
    f.write(html_content)

print(f"Successfully generated {html_path} with DB bindings.")
