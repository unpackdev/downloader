// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @dev When governor calls are invalid
error CallNotAllowed();

/// @dev Wallets who create new games (i.e. initial mint) should have enough funds to play at least 3 moves per game
error FundsTooLowForGameplay(); // Balances are not considered during actual gameplay or token transfers

/// @dev When the message sender does not own the game
error GameNotOwned();

/// @dev When a supplied index is out of bounds
error IndexOutOfBounds();

/// @dev When the price for a game is not correct
error InvalidPriceSent();

/// @dev When mint quantity is too high or too low
error InvalidQuantity();

/// @dev Do not allow code to re-enter
error NoReentrancy();
