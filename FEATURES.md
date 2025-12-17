# FEATURES

## General Game

Quick review of Bingo.
Bingo is a game where players have one (or more) square cards of a 5 x 5 grid.
Each column has a header: B I N G O.
Each row in each column has numbers in the header range.
The center spot is usually 'free'.

The game is played by the game runner distributing cards to players.
The game runner then radmonly selects a number, normally named the Header and a value.
IE B-7, I-17, N-37, G-57, O-67

The player then marks their card based on the called number.
The first person who gets 5 in a row calls out BINGO, and wins.

### How does this work

Each card has 24 unique values, normally the center element is free.
No number can be duplicated on the card.
The values are unsorted.

The game runner announces each picked value.
Giving some time for the players to pick and mark their cards.
Maybe 30-45 seconds.

### Typical numbers are

* B  1-15
* I 16-30
* N 31-45
* G 46-60
* O 61-75

### Wow implementation

Need a game runner, and players.

A game runner would:
* Anounce a new game to Guild, Raid or Party `/bingo guild|raid|party`
* Build and send cards to players
	* A game client will be sent a card
	* A player will be whispered a formatted card
	* Players can return and request new cards anytime.
* Pick and call out values to the choosen chat
	* Also send values to clients
		* Clients could see a list of values called
		* Allow the user to mark their cards.
* Listen for people to put in chat "BINGO"
	* Affirm that they are a winner
	* Since the runner knows a client's cards, can confirm a win
	* Announce a confirmed winner, or reject their call

When a new game is called, a client my reuse or replace cards.
(Keep a players cards in memory)

