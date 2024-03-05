/*
 * Place override
 * 
 * We override the whole "Rights side of the tracks"
 * Possible rewrite is to make use that we don't mess up any other script 
 * working on the same resources.
 *
 */
import "relay/DNALab.ash";
{
    buffer page_text = visit_url();

    if (page_text.contains_text("<b>Mimic DNA Bank</b>")) {
        page_text = handlePermBank(page_text);
    }

	page_text.write();	
}
