# Smile
Sentiment Analysis for GameMaker Studio 2.3. Because... why not? Smile for GameMaker Studio 2.3 is based largely off the [vaderSentiment project](https://github.com/vaderSentiment/vaderSentiment-js)

![.gif of Smile, GameMaker Language Sentiment Analysis, in action](https://raw.githubusercontent.com/zbanack/smile/master/demo.png)

## Setup

First, download the `lexicon.json` and `flavors.json` files and place them in Included Files.

Second, import the `Smile.gml`.

Third, in a GameMaker object, construct a new `smile` object, with an optional first argument bool for debug mode
```
s = new smile(?debug_mode);
```

Check to ensure that Smile has been initialized successfully with the following check:
```
if (s.working()) {
  // ...
}
```

Finally, feed it some strings! Each `analyze` call will return a value in range of (-1, 1), with -1 being very negative, 0 being neutral, and 1 being very positive.

```
s = new smile(_debug_mode);

if (s.working()) {
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
```

## Author
- Initial work by Zack Banack <[@zackbanack](https://www.twitter.com/zackbanack>

## GameMaker Studio 1.4 version (outdated, unoptimized)
- See my older [GameMaker Language Sentiment Analysis repo](https://github.com/zbanack/GameMaker-Language-Sentiment-Analysis) for a version of sentiment analysis that works in older version of GameMaker Studio.
