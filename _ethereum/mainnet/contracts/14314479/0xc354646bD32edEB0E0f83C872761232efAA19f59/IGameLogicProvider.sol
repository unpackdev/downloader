// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC165.sol";
import "./GameUtils.sol";

/// @title Provides support for the TicTacDao game
interface IGameLogicProvider is IERC165 {

	/// @dev When the game tokenId does not exist
	error NonexistentGame();

	/// @dev When total game quantity has been reached (see you on secondary markets)
	error SoldOut();

	/// Creates the specified number of newly initialized games
	/// @dev May throw SoldOut if the quantity results in too many games
	/// @param quantity The number of games to create
	/// @return startingGameId The starting gameId of the set
	function createGames(uint256 quantity) external returns (uint256 startingGameId);

	/// Processes the player's move and updates the state
	/// @dev May throw NonexistentGame, or InvalidMove if the position is invalid given the state
	/// @param gameId The token id of the game
	/// @param position The position of the player's next move
	/// @return resultingState The resulting state of the game
	function processMove(uint256 gameId, uint256 position) external returns (ITicTacToe.GameState resultingState);

	/// Restarts a game
	/// @param gameId The token id of the game to restart
	function restartGame(uint256 gameId) external;

	/// Returns the `ITicTacToe.Game` info for the specified `tokenId`
	/// @param gameId The token id of the game
	function ticTacToeGame(uint256 gameId) external view returns (ITicTacToe.Game memory);

	/// Returns the total number of games currently stored by the contract
	function totalGames() external view returns (uint256);
}
