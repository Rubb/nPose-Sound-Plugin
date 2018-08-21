integer SOUND_META_BROADCAST_CURRENT=-2348;
integer SOUND_META_BROADCAST_LAST=-2349;

vector TextColor=<1.0, 1.0, 1.0>;
float TextAlpha=1.0;

setText(string text) {
	llSetText(text, TextColor, TextAlpha);
}

setImage(key imageUuid) {
	if(imageUuid) {
		llSetTexture(imageUuid, 0);
	}
	else {
		llSetTexture(TEXTURE_PLYWOOD, 0);
	}
}

default {
	state_entry() {
		setText("");
		setImage(NULL_KEY);
	}
	link_message(integer sender_num, integer num, string str, key id) {
		if(num==SOUND_META_BROADCAST_CURRENT) {
			if(llJsonValueType(str, [])==JSON_OBJECT) {
				string text;
				if(llJsonValueType(str, ["title"])!=JSON_INVALID) {
					text+="Title: " + llJsonGetValue(str, ["title"]) + "\n";
				}
				if(llJsonValueType(str, ["artist"])!=JSON_INVALID) {
					text+="Artist: " + llJsonGetValue(str, ["artist"]) + "\n";
				}
				if(llJsonValueType(str, ["_length_string"])!=JSON_INVALID) {
					text+="Length: " + llJsonGetValue(str, ["_length_string"]) + "\n";
				}
				if(llJsonValueType(str, ["image_uuid"])!=JSON_INVALID) {
					setImage((key)llJsonGetValue(str, ["image_uuid"]));
				}
				setText(text);
			}
		}
		else if(num==SOUND_META_BROADCAST_LAST) {
			if(llJsonValueType(str, [])==JSON_OBJECT) {
				setText("");
				setImage(NULL_KEY);
			}
		}
	}
}
