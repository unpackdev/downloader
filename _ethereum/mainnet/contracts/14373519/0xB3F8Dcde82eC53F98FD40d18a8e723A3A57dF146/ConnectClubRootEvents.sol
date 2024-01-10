// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./RootMintableERC1155.sol";

/**
 * @title ConnectClubRootEvents
 * ConnectClubRootEvents - a root contract for connect.club events.
 */
contract ConnectClubRootEvents is RootMintableERC1155 {
  constructor()
  RootMintableERC1155(
    "https://static.test.connect.lol/nft/events/",
    0x2d641867411650cd05dB93B59964536b1ED5b1B7,
    "ConnectClubEvents",
    "CCE"
  ) {}

  function contractURI() public pure returns (string memory) {
    return "https://connect.club/";
  }
}
