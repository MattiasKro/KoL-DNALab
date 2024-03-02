/*
 * Place override
 * 
 * We override the whole "Rights side of the tracks"
 * Possible rewrite is to make use that we don't mess up any other script 
 * working on the same resources.
 *
 */

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

buffer replaceSelector(buffer pageBuffer, string searchFor, buffer selector) {
    int keyPos = index_of(pageBuffer, searchFor, 0);
    int startPos = index_of(pageBuffer, "<select name", keyPos);
    int endPos = index_of(pageBuffer, "</select>", startPos) + length("</select>");
    return replace(pageBuffer, startPos, endPos, to_string(selector));
}

buffer handlePermBank(buffer page_text) {
    // Example picker: 
    // Available monster: <option value="269">an angry piñata </option> 
    // Not available    : <option value="1800" disabled="">an angry mushroom guy (74 samples required)</option>

    // Find all possible eggs
    monster [int] availabeEmbryos;
    monster [int] unfinishedEmbryos;
    matcher eggmatcher = create_matcher("<option *?value\=\"(.*?)\"*?>.*?</option>", page_text);
    while (find(eggmatcher)) {
        string mnumstr =  group(eggmatcher,1);
        if (mnumstr.length() > 0) {
            boolean disabled = (mnumstr.index_of("disabled") > 0);
            if (mnumstr.index_of('"') > 0) {
                mnumstr = substring(mnumstr, 0, mnumstr.index_of('"'));
            }
            int mnum = to_int(mnumstr);
            monster m = to_monster(mnum);
            if (disabled) {
                unfinishedEmbryos[mnum] = m;
            } else {
                availabeEmbryos[mnum] = m;
            }
        } 
    }
    sort availabeEmbryos by value.name;

    familiar fam = to_familiar(299); // Chest mimic is 299, and we can't reach this page wuthout having one.
    page_text.replace_string("100 xp", "<font color=\"green\"><b>" + to_int(fam.experience) + " xp</b></font>");

    page_text = replaceSelector(page_text, "Extract an egg containing the dna of", makeMonsterPicker(availabeEmbryos, "mid"));

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
