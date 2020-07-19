/**
 * Smile - Sentiment Analysis in GameMaker Studio 2.3
 *
 * @author	Zack Banack <zackbanack.com>
 * @credit	Largely based off the vaderSentiment project <https://github.com/vaderSentiment/vaderSentiment-js>
 * @version 0.9
 *
 * @desc	Construct a `new smile()` object, and feed it strings of text via `analyze()`
 *				smile will output a number between -1 (very negative) and 1 (very positive); 0 is neutral
 *
 * Note that the lexicon included contains some VERY bad language that the authors of this project
 *	do not support, condone, or use. Unfortunately, to better gauge sentiment, one needs data sets containing all types of language
 *
 */
 
// file directories
#macro	DIR_LEXICON			working_directory + "lexicon.json"
#macro	DIR_FLAVORS			working_directory + "flavors.json"

// magic numbers
#macro	MAX_WORD_LENGTH		16
#macro	NORMALIZED_ALPHA	15

// weights
#macro	B_INCR				0.293
#macro	B_DECR				-0.293
#macro	N_SCALOR			-0.74
#macro	C_INCR				1.733

// types of tokens a word can be
enum TokenType {
	LEXICON,
	NEUTRAL,
	BOOSTER_POSITIVE,
	BOOSTER_NEGATIVE,
	NEGATOR
}

// global initialization check
gml_pragma("global", "global.__smile_initialized=false");

/// @function	smile
/// @desc		smile struct
/// @param		{?bool=false}	start in debug mode
/// @returns	{struct}
function smile() constructor {
	
	// prevent multi-initializations
	if (global.__smile_initialized) return false;
	
	// debug mode
	_debug = argument_count > 0 ? argument[0] : false;
	
	// data structures
	static _smile			= self,
		dictionary			= array_create(MAX_WORD_LENGTH, -1),
		boosters_positive	= ds_list_create(),
		boosters_negative	= ds_list_create(),
		negators			= ds_list_create(),
		draw_stack			= [];
		
	// initialize one dictionary per word length for faster lookups
	for(var i = MAX_WORD_LENGTH-1; i>=0; i--) {
		dictionary[i] = ds_map_create();	
	}
	
	/// @function	working
	/// @desc		used for determining whether smile has been initialized
	static working = function() {
		return global.__smile_initialized;	
	}

	/// @function	read_file
	/// @desc		extracts strings from file
	static read_file = function(fname) {
		
		if (!file_exists(fname)) return undefined;
		
		var file, contents;
		file = file_text_open_read(fname);
		contents = "";
		
		while(!file_text_eof(file))
			contents += file_text_readln(file);	
		
		file_text_close(file);
		
		return contents;
	}
	
	/// @function	json_map
	/// @desc		pushes file-parsed json contents into dictionaries
	/// @param		{map}	json-parsed map
	/// @returns	{bool}	truthy	-	whether the dictionary was constructed successfully
	static json_map = function(json) {
		
		if (!ds_map_exists(json, "lexicon")) return false;

		var lexicon = json[? "lexicon"];
		
		if (!ds_exists(lexicon, ds_type_list)) return false;
		
		for(var i = 0; i < ds_list_size(lexicon); i++) {
			
			var entry = ds_list_find_value(lexicon, i);
			
			if (!ds_exists(entry, ds_type_list)) continue;
			if (ds_list_size(entry) != 2) continue;
			
			// check for word-value pair
			var word, value;
			word	= ds_list_find_value(entry, 0);
			value	= ds_list_find_value(entry, 1);
			
			if (!is_string(word) || is_string(value)) continue;
			
			var len = string_length(word);
			
			// limit word lengths
			if (len>=MAX_WORD_LENGTH || len<1) continue;
			
			ds_map_set(dictionary[len], word, value);
			
		}
		
		return true;
		
	}
	
	/// @function	free
	/// @desc		frees Smile from memory
	static free = function() {

		ds_list_destroy(boosters_positive);
		ds_list_destroy(boosters_negative);
		ds_list_destroy(negators);	
		
		for(var i = 0; i < MAX_WORD_LENGTH; i++) {
			ds_map_destroy(dictionary[i]);
		}
		
		global.__smile_initialized = false;
		
		show_debug_message("Freed Smile");
		
		delete _smile;
		
	}
	
	/// @function	init_lexicon
	/// @desc		initializes lexicon data structures by reading the text file->populating maps
	/// @returns	{bool}	truthy	-	whether the lexicon was initialized successfully
	static init_lexicon = function() {
		
		var contents, map;
		contents	= read_file(DIR_LEXICON);
		
		if (is_undefined(contents)) return false;
		
		map	= json_decode(contents);
		
		if (!ds_exists(map, ds_type_map)) return false;
		
			if (json_map(map)) {
				
				ds_map_destroy(map);
				return true;
				
			}
			
		return false;
			
	}
	
	/// @function	json_list
	/// @desc		pushes file-parsed json contents into lists
	/// @returns	{bool}	truthy	-	whether the list was constructed successfully
	static json_list = function(map, list, key) {
		
		if (!ds_map_exists(map, key)) return false;

		var lst = map[? key];
		
		if (!ds_exists(lst, ds_type_list)) return false;
		
		ds_list_copy(list, lst);

		return true;
		
	}
	
	/// @function	tokenize
	/// @desc		tokenizes all words in a string, separated by space delimiters
	/// @TODO		add more delimiters, like commas and puncuation
	/// @returns	{array}	array of strings to tokenize
	static tokenize = function(str) {
		
		var del = " ";
		return explode(str + del, del);	
		
	}
	
	/// @function	explode
	/// @desc		splits a string into an array based on delimiters
	/// @param		{string}	str	-	string to explode
	/// @param		{string}	del	-	delimiter used in string separation
	/// @returns	{array}	array of strings
	static explode = function(str, del) {
		
		var occurrences = string_count(del, str)
	    var arr = array_create(occurrences, "");
	    var len = string_length(del);
		
		for(var i = 0; i < occurrences; i++) {
	        var pos = string_pos(del, str) - 1;
	        arr[i] = string_copy(str, 1, pos);
	        str = string_delete(str, 1, pos + len);			
		}
		
	    return arr;
		
	}

	
	/// @function	init_flavors
	/// @desc		initializes 'flavor' (boosters, negators)by reading the text file->populating respective lists
	/// @returns	{bool}	truthy	-	whether the flavors were initialized successfully
	static init_flavors = function() {
		
		var contents, map;
		contents	= read_file(DIR_FLAVORS);
		
		if (is_undefined(contents)) return false;
		
		map			= json_decode(contents);
		
		if (!ds_exists(map, ds_type_map)) return false;
		
		// check to ensure all lists have been populated
		var success = (json_list(map, boosters_positive, "boosters_pos")
						&& json_list(map, boosters_negative, "boosters_neg")
						&& json_list(map, negators, "negators"));
				
		ds_map_destroy(map);
			
		return success;

	}
	
	/// @function	normalize
	/// @param		{real}	score	-	score to normalize
	/// @desc		levels out the accumulated sentiment score from -1 to 1 using an alpha
	/// @returns	{real}	number between -1 and 1
	static normalize = function(_score) {

		return clamp(_score / sqrt(_score * _score + NORMALIZED_ALPHA), -1, 1);

	}
	
	/// @function	elapsed
	/// @param		{real}	start	-	when the timer started
	/// @desc		helper for formatting elapsed microseconds
	/// @returns	{string}	time-formatted string
	static elapsed = function(start) {
		
		return string_format((get_timer() - start) / 1000000, 8, 8) + "s";
		
	}
	
	/// @function	init
	/// @desc		Smile startup script; preps all necessary data structures
	static init = function() {
		
		var time = get_timer();
		
		var pass = true;
		
		if (!init_lexicon()) {
			show_debug_message("[!] Failed to initialize Smile lexicon");
			pass = false;
		}
		
		if (!init_flavors()) {
			show_debug_message("[!] Failed to initialize Smile flavors");
			pass = false;
		}
		
		// failed to initialize successfully
		if (!pass) {
			free();
			return;
		}
		
		global.__smile_initialized = true;
		show_debug_message("Initialized Smile in " + string(elapsed(time)));
		
	}
	
	/// @function	sentiment_string
	/// @param		{real}	score	-	value between -1 and 1
	/// @desc		interprets the score into easily-readable strings
	/// @returns	{strring}	string most closely associated with sentiment score
	static sentiment_string = function(_score) {
		
		var arr = ["Very negative", "Negative", "Neutral", "Positive", "Very positive"];
		
		return arr[floor(((_score+1)/2)*array_length_1d(arr))];
		
	}
	
	/// @function	analyze
	/// @param		{string}	input	-	string to analyze sentiment of
	/// @desc		this is where the magic happens; analyze strings of text!
	/// @returns	{real}	score between -1 and 1
	static analyze = function(input) {
		
		var time = get_timer();
	
		var tokens = tokenize(input);
		
		var applying_negator = false;
		
		var sum_positive, sum_negative, neutral_count, sum_score;
		sum_positive	= 0;
		sum_negative	= 0;
		neutral_count	= 0;
		sum_score		= 0;
		
		// iterate over all the tokens
		for(var i = 0; i < array_length_1d(tokens); i++) {
			
			var token = new Token(tokens[i], self);
			
			var negated, boosted, _score;
			negated			= false;
			boosted			= 0;
			_score			= token._score;
			
			// negate score
			if (applying_negator) _score *= N_SCALOR;
			
			if (token.uppercase) _score *= C_INCR;
			
			// handle different types of tokens
			switch(token.classification) {
				case(TokenType.NEGATOR):
					applying_negator = !applying_negator;
				break;
				case(TokenType.BOOSTER_POSITIVE):
					sum_score+=B_INCR;
				break;
				case(TokenType.BOOSTER_NEGATIVE):
					sum_score-=B_INCR;
				break;
				case(TokenType.LEXICON):
					applying_negator = false
				break;
			}
			
		    if (_score > 0) {
		        sum_positive += _score + 1;
		    } else if (_score < 0) {
		        sum_negative += _score - 1;
		    } else {
		        neutral_count += 1;
		    }
    
		    sum_score += _score;
			
			token.free();
		}
		
		var normalized_score = normalize(sum_score);
		
		// debug output
		if (_debug) {
		
			var score_total, score_positive, score_negative, score_neutral, result_string;
			score_total		= sum_positive + abs(sum_negative) + neutral_count;
			score_positive	= abs(sum_positive / score_total) * 100;
			score_negative	= abs(sum_negative / score_total) * 100;
			score_neutral	= abs(neutral_count / score_total) * 100;
			result_string	= sentiment_string(normalized_score);
			
			var lapse = elapsed(time);
		
			show_debug_message("Analyzed sentiment in " + string(lapse) +
				"\nInput: `" + string(input) + "`" +
				"\nTokens: " + string(tokens) +
				"\nSentiment: `" + string(result_string) + "` (" + string(normalized_score) + "), a=" + string(NORMALIZED_ALPHA) +
				"\nComposition: Positive = " + string(score_positive) + "%, Negative = " + string(score_negative) + "%, Neutral = " + string(score_neutral) + "%");
				
			draw_stack[array_length_1d(draw_stack)] = [input, normalized_score, result_string, lapse];
				
		}
		
		return normalized_score;
		
	}
	
	/// @function	draw
	/// @desc		debug rendering to the screen
	static draw = function() {
		
		if (!_debug) return;
		
		draw_set_halign(fa_left);
		draw_set_valign(fa_top);
		draw_set_alpha(1);
		
		draw_set_color(c_white);
		draw_text(32, 32, "Smile - Sentiment Analysis in GameMaker Studio 2.3 by @zackbanack");
		
		for(var i = 0; i < array_length_1d(draw_stack); i++) {
			
			var str, _score, result, lapse;
			str		= draw_stack[i][0];
			_score	= draw_stack[i][1];
			result	= draw_stack[i][2];
			lapse	= draw_stack[i][3];
			
			draw_set_color(make_color_hsv((1+_score)*64, 255, 255));
			draw_text(32, 32 * (i+3), "[" + string(_score) + ", " + string(result) + "]");
			draw_text(32 + 256, 32 * (i+3), str);
			
			draw_set_color(c_ltgray);
			draw_text(32 + 960, 32 * (i+3), lapse);
			
		}
	}

	init();
}

/// @function	Token
/// @param		{string}	token name
/// @param		{parent}	token parent; smile struct
/// @desc		token struct
/// @returns	{struct}
function Token(_name, _parent) constructor {
	
	_token = self;
	
	uppercase		= false;
	_score			= 0;
	classification	= TokenType.NEUTRAL;
	
	name = _name;
	parent = _parent;
	
	/// @function	get_sentiment
	/// @desc		gets the individual sentiment value of a word
	/// @returns	{real}	sentiment of token
	static get_sentiment = function() {
		
		var cleaned, len, dict;
		cleaned = string_clean(name);
		len = string_length(cleaned);
		
		// invalid word length
		if (len>=MAX_WORD_LENGTH || len<1) return 0;
		
		// look up word in string length-sized dictionary
		dict = parent.dictionary[len];
		if (!ds_map_exists(dict, cleaned)) return 0;
		
		return ds_map_find_value(dict, cleaned);
		
	}
	
	/// @function	is_uppercase
	/// @desc		determines whether a word is in caps or not
	/// @returns	{bool}	truthy	-	whether the string passed is uppercase
	static is_uppercase = function() {
		
		return string_upper(name) == name;
		
	}
	
	/// @function	string_clean
	/// @param		{string}	string to clean
	/// @desc		cleans a string
	/// @returns	{string}	cleaned string
	static string_clean = function(str) {
		
		var input, output;
		input = string_lower(str);
	
		return input;
	
		// @UNUSED, strips all non a-z characters from string
		/*output = "";
		
		for(var i = 1; i <= string_length(input); i++) {
			
			var char, order;
			char = string_char_at(input, i);
			order = ord(char);
			
			if ((order>=97 && order<=122) || order == 32) {
				output += char;
			}
			
		}
		
		return output;*/
	
	}
	
	/// @function	classify
	/// @desc		classifies the token's text into a token type
	/// @returns	{int}	TokenType enum
	static classify = function() {
		
		if (is_undefined(name)) return TokenType.NEUTRAL;
		
		if (_score != 0) return TokenType.LEXICON;
		
		if (ds_list_find_index(parent.negators, name) >=0) {
			return TokenType.NEGATOR;	
		}
		else if (ds_list_find_index(parent.boosters_positive, name) >=0) {
			return TokenType.BOOSTER_POSITIVE;	
		}
		else if (ds_list_find_index(parent.boosters_negative, name) >=0) {
			return TokenType.BOOSTER_NEGATIVE;	
		}
		
		return TokenType.NEUTRAL;
	}
	
	/// @function	init
	/// @desc		initializes token
	static init = function() {
		uppercase			= is_uppercase();
		_score				= get_sentiment();
		classification		= classify(_score);
	}
	
	/// @function	free
	/// @desc		frees the token frrom memory
	static free = function() {
		
		delete _token;
		
	}
	
	init();
	
}