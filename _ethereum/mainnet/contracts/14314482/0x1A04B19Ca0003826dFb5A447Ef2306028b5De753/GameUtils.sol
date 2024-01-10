// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ITicTacToe.sol";
// import "./console.sol";

/// @title GameUtils
library GameUtils {

	/// @dev When the player attempts a change that is not valid for the current GameState
	error InvalidGameState();

	/// @dev When the player attempts to make an invalid move
	error InvalidMove();

	/// @dev When a player attempts to make multiple moves within the same block for the same game
	error NoMagic();

	/// Represents one of the game players
	enum GamePlayer {
		Contract, Owner
	}

	/// Represents the storage of a game, suitable for the contract to make choices
	struct GameInfo {
		ITicTacToe.GameState state;
		uint8 moves;
		uint8[9] board;
		uint40 blockNumber; // The block number of the last move. To save gas, not updated on a win/lose/tie
		ITicTacToe.GameHistory history;
	}

	/// @dev Constant for reporting an invalid index
	uint256 internal constant INVALID_MOVE_INDEX = 0xFF;

	/// Returns whether the bits under test match the bits being tested for
	/// @param bits The bits to test
	/// @param matchBits The bits being tested for
	/// @return Whether the bits under test match the bits being tested for
	function bitsMatch(uint256 bits, uint256 matchBits) internal pure returns (bool) {
		return (bits & matchBits) == matchBits;
	}

	/// Returns an ITicTacToe.Game from the supplied GameInfo
	/// @param gameInfo The GameInfo structure to convert
	/// @return game The converted Game structure
	function gameFromGameInfo(GameInfo memory gameInfo) internal pure returns (ITicTacToe.Game memory game) {
		game.state = gameInfo.state;
		game.history = gameInfo.history;
		game.moves = new uint8[](gameInfo.moves);
		for (uint256 move = 0; move < gameInfo.moves; move++) {
			game.moves[move] = gameInfo.board[move];
		}
	}

	/// Returns an GameInfo from the supplied ITicTacToe.Game
	/// @param game The ITicTacToe.Game structure to convert
	/// @return gameInfo The converted GameInfo structure
	function gameInfoFromGame(ITicTacToe.Game memory game) internal pure returns (GameInfo memory gameInfo) {
		gameInfo.state = game.state;
		gameInfo.history = game.history;
		gameInfo.moves = uint8(game.moves.length);
		for (uint256 move = 0; move < game.moves.length; move++) {
			gameInfo.board[move] = game.moves[move];
		}
	}

	/// Returns the index of the desired position in the GameInfo's board array
	/// @param gameInfo The GameInfo to examine
	/// @param position The position to search
	/// @return The index within the board array of the result, or `INVALID_MOVE_INDEX` if not found
	function indexOfPosition(GameInfo memory gameInfo, uint256 position) internal pure returns (uint256) {
		for (uint256 index = gameInfo.moves; index < gameInfo.board.length; index++) {
			if (position == gameInfo.board[index]) {
				return index;
			}
		}
		return INVALID_MOVE_INDEX;
	}

	/// Returns a new initialized GameUtils.GameInfo struct using the existing GameHistory
	/// @param history The history of games to attach to the new instance
	/// @param seed An initial seed for the contract's first move
	/// @param blockNumber A optional value to use as the initial block number, which will be collapsed to uint40
	/// @return A new intitialzed GameUtils.GameInfo struct
	function initializeGame(ITicTacToe.GameHistory memory history, uint256 seed, uint256 blockNumber) internal pure returns (GameUtils.GameInfo memory) {
		uint8 firstMove = uint8(seed % 9);
		uint8[9] memory board;
		board[0] = firstMove;
		for (uint256 i = 1; i < 9; i++) {
			board[i] = i <= firstMove ? uint8(i-1) : uint8(i);
		}
		return GameUtils.GameInfo(ITicTacToe.GameState.InPlay, 1, board, uint40(blockNumber), history);
	}

	/// Returns the bits representing the player's moves
	/// @param gameInfo The GameInfo structure
	/// @param gamePlayer The GamePlayer for which to generate the map
	/// @return map A single integer value representing a bitmap of the player's moves
	function mapForPlayer(GameInfo memory gameInfo, GamePlayer gamePlayer) internal pure returns (uint256 map) {
		// These are the bits for each board position
		uint16[9] memory positionsToBits = [256, 128, 64, 32, 16, 8, 4, 2, 1];
		for (uint256 index = uint256(gamePlayer); index < gameInfo.moves; index += 2) {
			uint256 position = gameInfo.board[index];
			map += positionsToBits[position];
		}
	}

	/// Updates the GameInfo structure based on the positionIndex being moved
	/// @param gameInfo The GameInfo structure
	/// @param positionIndex The index within the board array representing the desired move
	function performMove(GameInfo memory gameInfo, uint256 positionIndex) internal pure {
		uint8 movePosition = gameInfo.moves & 0x0F;
		uint8 nextPosition = gameInfo.board[positionIndex];
		gameInfo.board[positionIndex] = gameInfo.board[movePosition];
		gameInfo.board[movePosition] = nextPosition;
		gameInfo.moves += 1;
	}

	/// Returns whether the player has won based on its playerMap
	/// @param playerMap The bitmap of the player's moves
	/// @return Whether the bitmap represents a winning game
	function playerHasWon(uint256 playerMap) internal pure returns (bool) {
		// These are winning boards when bits are combined
		uint16[8] memory winningBits = [448, 292, 273, 146, 84, 73, 56, 7];
		for (uint256 index = 0; index < winningBits.length; index++) {
			if (bitsMatch(playerMap, winningBits[index])) {
				return true;
			}
		}
		return false;
	}

	/// Processes a move on an incoming GameInfo structure and returns a resulting GameInfo structure
	/// @param gameInfo The incoming GameInfo structure
	/// @param position The player's attempted move
	/// @param seed A seed used for randomness
	/// @return A resulting GameInfo structure that may also include the contract's move if the game continues
	function processMove(GameUtils.GameInfo memory gameInfo, uint256 position, uint256 seed) internal view returns (GameUtils.GameInfo memory) {
		if (gameInfo.state != ITicTacToe.GameState.InPlay) revert InvalidGameState();
		// console.log("block number %d vs %d", gameInfo.blockNumber, block.number);
		if (gameInfo.blockNumber >= block.number) revert NoMagic();
		uint256 positionIndex = indexOfPosition(gameInfo, position);
		if (positionIndex == INVALID_MOVE_INDEX) revert InvalidMove();
		// console.log("Playing position:", position); //, positionIndex, gameInfo.moves);
		performMove(gameInfo, positionIndex);

		if (gameInfo.moves < 4) { // No chance of winning just yet
			uint256 openSlot = uint8(seed % (9 - gameInfo.moves));
			// console.log(" - random move:", gameInfo.board[openSlot + gameInfo.moves]);
			performMove(gameInfo, openSlot + gameInfo.moves);
			gameInfo.blockNumber = uint40(block.number);
		} else /* if (gameInfo.moves < 9) */ { // Owner or Contract may win
			uint256 ownerMap = mapForPlayer(gameInfo, GamePlayer.Owner);
			if (playerHasWon(ownerMap)) {
				gameInfo.state = ITicTacToe.GameState.OwnerWon;
				gameInfo.history.wins += 1;
			} else {
				bool needsMove = true;
				uint256 contractMap = mapForPlayer(gameInfo, GamePlayer.Contract);
				// If the Contract has an imminent win, take it.
				for (uint256 openSlot = gameInfo.moves; openSlot < 9; openSlot++) {
					if (winableMove(contractMap, gameInfo.board[openSlot])) {
						// console.log(" - seizing move:", gameInfo.board[openSlot]); //, gameInfo.moves);
						performMove(gameInfo, openSlot);
						needsMove = false;
						break;
					}
				}
				if (needsMove) {
					// If the Owner has an imminent win, block it.
					for (uint256 openSlot = gameInfo.moves; openSlot < 9; openSlot++) {
						if (winableMove(ownerMap, gameInfo.board[openSlot])) {
							// console.log(" - blocking move:", gameInfo.board[openSlot]); //, gameInfo.moves);
							performMove(gameInfo, openSlot);
							needsMove = false;
							break;
						}
					}
				}
				if (needsMove) {
					uint256 openSlot = uint8(seed % (9 - gameInfo.moves));
					// console.log(" - random move:", gameInfo.board[openSlot + gameInfo.moves]);
					performMove(gameInfo, openSlot + gameInfo.moves);
				}
				if (playerHasWon(mapForPlayer(gameInfo, GamePlayer.Contract))) {
					gameInfo.state = ITicTacToe.GameState.ContractWon;
					gameInfo.history.losses += 1;
				} else if (gameInfo.moves > 8) {
					gameInfo.state = ITicTacToe.GameState.Tie;
					gameInfo.history.ties += 1;
				} else {
					gameInfo.blockNumber = uint40(block.number);
				}
			}
		}
		return gameInfo;
	}

	/// Returns whether the next position would result in a winning board if applied
	/// @param playerMap The bitmap representing the player's current moves
	/// @param nextPosition The next move being considered
	/// @return Whether the next position would result in a winning board
	function winableMove(uint256 playerMap, uint256 nextPosition) internal pure returns (bool) {
		if (nextPosition == 0) {
			return bitsMatch(playerMap, 192) || bitsMatch(playerMap, 36) || bitsMatch(playerMap, 17);
		} else if (nextPosition == 1) {
			return bitsMatch(playerMap, 320) || bitsMatch(playerMap, 18);
		} else if (nextPosition == 2) {
			return bitsMatch(playerMap, 384) || bitsMatch(playerMap, 20) || bitsMatch(playerMap, 9);
		} else if (nextPosition == 3) {
			return bitsMatch(playerMap, 260) || bitsMatch(playerMap, 24);
		} else if (nextPosition == 4) {
			return bitsMatch(playerMap, 257) || bitsMatch(playerMap, 130) || bitsMatch(playerMap, 68) || bitsMatch(playerMap, 40);
		} else if (nextPosition == 5) {
			return bitsMatch(playerMap, 65) || bitsMatch(playerMap, 48);
		} else if (nextPosition == 6) {
			return bitsMatch(playerMap, 288) || bitsMatch(playerMap, 80) || bitsMatch(playerMap, 3);
		} else if (nextPosition == 7) {
			return bitsMatch(playerMap, 144) || bitsMatch(playerMap, 5);
		} else /* if (nextPosition == 8) */ {
			return bitsMatch(playerMap, 272) || bitsMatch(playerMap, 72) || bitsMatch(playerMap, 6);
		}
	}
}
