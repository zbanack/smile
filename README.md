# Smile 😊😡

Sentiment Analysis for GameMaker Studio 2.3. ...because Zack insists on using GML for everything. 

Largely based off the [vaderSentiment project](https://github.com/vaderSentiment/vaderSentiment-js).

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

If in Smile debug mode, you can output results to the screen in the GUI layer by calling
```
s.draw();
```

You can free Smile from memory at any time by calling
```
s.free();
```

## TODO
- Clean up code, add more comments, JSdoc headers
- Add more delimiters, so non-space characters like commas and punctuation marks are considered separate tokens
- Contraction, or lack thereof, support
- Double negatives are faulty
- 'Tone' and more complex sentence structure/English language expressions that I don't have the time nor energy to tackle (e.g. "At first I didn't like thing, but then it started to grow on me" is analyzed as negative in Smile, but it should be closer to neutral; "grow on me" isn't deemed as anything important here)
- Typos, compounds, and character->symbol replacements aren't considered

## Notice
Please note that the lexicon included contains some VERY bad language that the authors of this project do not support, condone, nor use. Unfortunately, to better gauge sentiment, one needs data sets containing all types of language.

## Author
- Initial work by Zack Banack [<@zackbanack>](https://www.twitter.com/zackbanack>

## GameMaker Studio 1.4 version (outdated, unoptimized)
- See my older [GameMaker Language Sentiment Analysis repo](https://github.com/zbanack/GameMaker-Language-Sentiment-Analysis) for a version of sentiment analysis that works in older version of GameMaker Studio.
