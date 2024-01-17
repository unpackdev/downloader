// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./LibDiamond.sol";

struct AppStorage {
  // Token name
  string name;

  // Token symbol
  string symbol;

  // Base URI
  string baseURI;

  // URI of contract metadata
  string contractURI;

  // Mapping from token ID to owner address
  mapping(uint256 => address) owners;

  // Mapping owner address to token count
  mapping(address => uint256) balances;

  // Mapping from token ID to approved address
  mapping(uint256 => address) tokenApprovals;

  // Mapping from owner to operator approvals
  mapping(address => mapping(address => bool)) operatorApprovals;

  address payable fees;

  uint256 maxAvailable24x24Id;
  uint256 maxAvailable16x16Id;
  uint256 maxAvailable8x8Id;
  uint256 maxAvailable5x5Id;
  uint256 maxAvailable3x3Id;
  uint256 maxAvailable2x2Id;
  uint256 maxAvailable1x1Id;

  // Minting price for each size of land
  uint256[7] mintingPrices;
}

contract Modifiers {
  AppStorage internal s;

  modifier onlyOwner {
    LibDiamond.enforceIsContractOwner();
    _;
  }
}
