// SPDX-License-Identifier: GPL-3.0

/// @title Interface for ShinyMinter

/*********************************
 * ･ﾟ･ﾟ✧.・･ﾟshiny.club・✫・゜･ﾟ✧ *
 *********************************/

pragma solidity ^0.8.9;

import "./IShinySeeder.sol";

interface IShinyMinter {

    event ShinyMinted(uint256 indexed tokenId, address purchaser, uint256 amount, uint16 shinyChanceBasisPoints);

    function mint() external payable;

    function reconfigureShiny(uint256 tokenId, IShinySeeder.Seed memory newSeed) external payable returns (IShinySeeder.Seed memory);

    function updateReconfigureCost(uint256 newReconfigureCost) external;

    function updateShinyDAO(address newShinyDAO) external;

    function updatePurchasePriceRecipient(address newRecipient) external;

    function pause() external;

    function unpause() external;
}