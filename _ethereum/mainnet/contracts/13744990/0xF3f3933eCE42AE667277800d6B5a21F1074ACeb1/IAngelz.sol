// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.10;

interface IAngelz {
  // struct to store each token's traits
  struct AngelHuman {
    bool human;
    uint8 angelicIndex;
  }

  function getPaidTokens() external view returns (uint256);

  function getTokenTraits(uint256 tokenId)
    external
    view
    returns (AngelHuman memory);
}
