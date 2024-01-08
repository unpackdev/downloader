// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @dev When cloud quantity is too high or too low
error InvalidQuantity();

/// @dev When the price for cloud formation is not correct
error InvalidPriceSent();

/// @dev When the maximum number of clouds has been met
error NoMoreClouds();

/// @dev When the cloud tokenId does not exist
error NonexistentCloud();

/// @dev When minting block hasn't yet been reached
error NotOpenForMinting();

/// @dev When Reveal is false
error NotYetRevealed();

/// @dev Only owners of other 100% on-chain projects: Anonymice & TwoBitBears are whitelisted
error NotWhitelisted();

/// @dev Only available to shareholders
error OnlyShareholders();
