var _debug_mode = true;

// initialize Smile in debug mode
s = new smile(_debug_mode);

// check if setup properly
if (s.working()) {
	
	// feed it some strings!
	s.analyze("That is a game");
	s.analyze("That is a game <3");
	s.analyze("The game is good");
	s.analyze("The game is great :D");
	s.analyze("The game is not good");
	s.analyze("The game is bad");
	s.analyze("The game is bad and awful and I hate it ugh");
	s.analyze("The game is not bad");
	s.analyze("THE GAME IS SO GOOD");
	s.analyze("At first I didn't like the game, but then I found myself starting to like it");
	s.analyze("I love love love this game");
	s.analyze("This is a pretty cool game");
	s.analyze("I dislike the game >:(");
	s.analyze("I would not say I dislike the game");
	s.analyze("I dont actually like this game");
	s.analyze("This game makes me happy");
}