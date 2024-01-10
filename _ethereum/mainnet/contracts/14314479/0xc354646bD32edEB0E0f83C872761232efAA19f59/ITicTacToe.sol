// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title ITicTacToe interface
interface ITicTacToe {

	/// Represents the state of a Game
	enum GameState {
		InPlay, OwnerWon, ContractWon, Tie
	}

	/// Contains aggregated information about game results
	struct GameHistory {
		uint32 wins;
		uint32 losses;
		uint32 ties;
		uint32 restarts;
	}

	/// Contains information about a TicTacToe game
	struct Game {
		uint8[] moves;
		GameState state;
		GameHistory history;
	}
}
