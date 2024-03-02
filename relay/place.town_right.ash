/*
 * Place override
 * 
 * We override the whole "Rights side of the tracks"
 * Possible rewrite is to make use that we don't mess up any other script 
 * working on the same resources.
 *
 */
string __DNA_EGGSATRACTOR = "Extract an egg containing the dna of";
string __DONATE_EGG = "Donate the egg of";

record MonsterWrapper {
    monster m;
    boolean available;
    int progress;
};

buffer makeMonsterPicker(monster [int] monsterList, string name) {
    buffer result;
    result.append("\t\t<select name=\"" + name + "\">\n");
    result.append("<option value=\"\">-- select a monster --</option>");
    foreach key, m in monsterList {
        result.append("\t\t\t<option value=\"" + to_string(m.id) + "\">" + m.name + "</option>\n");
    }
	result.append("\t\t</select>\n");
    return result;
}

buffer makeMonsterPicker(MonsterWrapper [int] monsterList, string name) {
    buffer result;
    result.append("\t\t<select name=\"" + name + "\">\n");
    result.append("<option value=\"\">-- select a monster --</option>");
    foreach key, m in monsterList {
        string disabled = (m.available) ? "" : " disabled";
        string progress = (m.progress > 0) ? " (" + to_string(m.progress) + " samples required)": "";
        result.append("\t\t\t<option value=\"" + to_string(m.m.id) + "\"" + disabled + ">" + m.m.name + progress + "</option>\n");
    }
	result.append("\t\t</select>\n");
    return result;
}

buffer extractSelector(buffer pageBuffer, string searchFor) {
    buffer result;
    int keyPos = index_of(pageBuffer, searchFor, 0);
    int startPos = index_of(pageBuffer, "<select name", keyPos);
    int endPos = index_of(pageBuffer, "</select>", startPos) + length("</select>");
    result.append(substring(to_string(pageBuffer), startPos, endPos));
    return result;
}

buffer replaceSelector(buffer pageBuffer, string searchFor, buffer selector) {
    int keyPos = index_of(pageBuffer, searchFor, 0);
    int startPos = index_of(pageBuffer, "<select name", keyPos);
    int endPos = index_of(pageBuffer, "</select>", startPos) + length("</select>");
    return replace(pageBuffer, startPos, endPos, to_string(selector));
}

int extractProgress(string text) {
    int result = 0;
    if (text.contains_text("samples required)")) {
        int endPos = text.index_of("samples required");
        int startPos = text.last_index_of("(", endPos);
        if (endPos > 0) {
            string progressString = text.substring(startPos + 1, endPos);
            result = to_int(progressString);
        }
    }
    return result;
}

buffer handlePermBank(buffer page_text) {
    // Example picker: 
    // Available monster: <option value="269">an angry piñata </option> 
    // Not available    : <option value="1800" disabled="">an angry mushroom guy (74 samples required)</option>

    // Find all possible eggs
    MonsterWrapper [int] availabeEmbryos;
    MonsterWrapper [int] unfinishedEmbryos;
    if (page_text.contains_text(__DNA_EGGSATRACTOR)) {
        familiar fam = to_familiar(299); // Chest mimic is 299, and we can't reach this page wuthout having one.
        page_text.replace_string("100 xp", "<font color=\"green\"><b>" + to_int(fam.experience) + " xp</b></font>");

        buffer eggPicker = extractSelector(page_text, __DNA_EGGSATRACTOR);
        matcher eggmatcher = create_matcher("<option *?value\=\"(.*?)\"*?>(.*?)</option>", eggPicker);
        while (find(eggmatcher)) {
            string mnumstr =  group(eggmatcher,1);
            if (mnumstr.length() > 0) {
                boolean disabled = (mnumstr.index_of("disabled") > 0);
                if (mnumstr.index_of('"') > 0) {
                    mnumstr = substring(mnumstr, 0, mnumstr.index_of('"'));
                }
                int mnum = to_int(mnumstr);
                monster m = to_monster(mnum);
                MonsterWrapper thisMonster;
                thisMonster.m = m;
                thisMonster.progress = 0;
                if (disabled) {
                    unfinishedEmbryos[mnum] = thisMonster;
                    thisMonster.available = false;
                    thisMonster.progress = extractProgress(group(eggmatcher,2));
                } else {
                    availabeEmbryos[mnum] = thisMonster;
                    thisMonster.available = true;
                }
            } 
        }
        sort availabeEmbryos by value.m.name;
        sort unfinishedEmbryos by value.progress;

        page_text = replaceSelector(page_text, __DNA_EGGSATRACTOR, makeMonsterPicker(availabeEmbryos, "mid"));

        int insertPos = last_index_of(to_string(page_text), "</form>") + length("</form>");
        page_text.insert(insertPos, 
            "<p>DNA samples to complete " + makeMonsterPicker(unfinishedEmbryos, "noc") + "</p></form>");
    }

    MonsterWrapper [int] eggs;
    if (page_text.contains_text(__DONATE_EGG)) {
        buffer eggPicker = extractSelector(page_text, __DONATE_EGG);
        matcher eggmatcher = create_matcher("<option *?value\=\"(.*?)\">.*?</option>", eggPicker);
        while (find(eggmatcher)) {
            string mnumstr =  group(eggmatcher,1);
            if (mnumstr.length() > 0) {
                int mnum = to_int(mnumstr);
                monster mm = to_monster(mnum);
                MonsterWrapper m;
                m.m = mm;
                m.progress = 0;
                if (availabeEmbryos[mnum].m.id > 0) {
                    m.available = false;
                } else {
                    m.available = true;
                }
                eggs[mnum] = m;
            }
        }
        sort eggs by value.progress;
        page_text = replaceSelector(page_text, __DONATE_EGG, makeMonsterPicker(eggs, "mid"));
    }

    return page_text;
}

void main()
{
    buffer page_text = visit_url();

    if (page_text.contains_text("<b>Mimic DNA Bank</b>")) {
        page_text = handlePermBank(page_text);
    }

	page_text.write();	
}
