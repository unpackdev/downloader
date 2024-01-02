
// SPDX-License-Identifier: BSD-3
pragma solidity ^0.8.17;


import "./IERC721Enumerable.sol";

struct DarkEchelonConfig {
  uint16 burnId;
  bool canMigrate;
  bool isOsEnabled;
  string tokenURIPrefix;
  string tokenURISuffix;

  IERC721Enumerable principal;
}

struct DarkEchelonContainer {
  DarkEchelonConfig config;
}

struct ERC721Data {
  // Token name
  string _name;

  // Token symbol
  string _symbol;

  mapping(uint256 tokenId => address) _tokenApprovals;

  mapping(address owner => mapping(address operator => bool)) _operatorApprovals;
}

struct Owner{
  uint16 balance;
  uint16 purchased;
}

struct OwnerContainer {
  mapping(address => Owner) _owners;
}

struct TokenRange{
  uint16 lower;
  uint16 current;
  uint16 upper;
  uint16 minted;
}

struct TokenRangeContainer {
  TokenRange _range;
}

struct Token{
  address owner; //160
  bool isBurned;
  bool isLocked;
}

struct TokenContainer {
  mapping(uint256 => Token) _tokens;
}

// solhint-disable no-inline-assembly
library ERC721BStorage {
  function getDarkEchelonStorage(bytes32 slot) internal pure returns (DarkEchelonContainer storage container) {
    assembly {
      container.slot := slot
    }
  }

  function getERC721Storage(bytes32 slot) internal pure returns (ERC721Data storage erc721) {
    assembly {
      erc721.slot := slot
    }
  }

  function getOwnerStorage(bytes32 slot) internal pure returns (OwnerContainer storage ownerContainer) {
    assembly {
      ownerContainer.slot := slot
    }
  }

  function getTokenRangeStorage(bytes32 slot) internal pure returns (TokenRangeContainer storage rangeContainer) {
    assembly {
      rangeContainer.slot := slot
    }
  }

  function getTokenStorage(bytes32 slot) internal pure returns (TokenContainer storage tokenContainer) {
    assembly {
      tokenContainer.slot := slot
    }
  }
}