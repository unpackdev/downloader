// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

////////////////////////////////////////////////////////////////////////////////
///              ░▒█▀▀▄░█▀▀█░▒█▀▀█░█▀▀▄░▒█▀▄▀█░▄█░░▒█▄░▒█░▒█▀▀▀              ///
///              ░▒█░▒█░█▄▀█░▒█▄▄█▒█▄▄█░▒█▒█▒█░░█▒░▒█▒█▒█░▒█▀▀▀              ///
///              ░▒█▄▄█░█▄▄█░▒█░░░▒█░▒█░▒█░░▒█░▄█▄░▒█░░▀█░▒█▄▄▄              ///
////////////////////////////////////////////////////////////////////////////////

import "./IERC721.sol";

/// @title Dopamine DAO Auction House Token
/// @notice Any contract implementing the provided interface can be integrated
///  into the Dopamine DAO Auction House platform. Although originally intended
///  only for the Dopamine ERC-721 tab, it is possible that the auction platform 
///  will be reused for English auctions of other NFTs.
interface IDopamineAuctionHouseToken is IERC721 {

    function mint() external returns (uint256);

}
