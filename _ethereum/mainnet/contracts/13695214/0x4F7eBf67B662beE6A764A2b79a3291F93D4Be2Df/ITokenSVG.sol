// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ITokenSVG {
  struct TokenInfo {
    int128 x;
    int128 y;
    uint256 tokenId;
    bool hasTokenId;
  }

  struct Meta {
    int128 x;
    int128 y;
    uint256 tokenId;
    string slogan;
    bool isPeople;
    bool isBuidler;
    TokenInfo invite;
    TokenInfo[] mintedAndInvitedList;
    string[] neighbors;
  }

  function getCoordinatesStrings(int128 x, int128 y)
    external
    pure
    returns (string memory sx, string memory sy);

  function tokenMeta(Meta memory meta)
    external
    pure
    returns (string memory result);
}
