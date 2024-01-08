// SPDX-License-Identifier: MIT

// ______  __  __   ______       _____    __  __   _____    ______
// /\__  _\/\ \_\ \ /\  ___\     /\  __-. /\ \/\ \ /\  __-. /\  ___\
// \/_/\ \/\ \  __ \\ \  __\     \ \ \/\ \\ \ \_\ \\ \ \/\ \\ \  __\
//   \ \_\ \ \_\ \_\\ \_____\    \ \____- \ \_____\\ \____- \ \_____\
//    \/_/  \/_/\/_/ \/_____/     \/____/  \/_____/ \/____/  \/_____/
//

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "./Ownable.sol";
import "./ITheDudesFactoryV2.sol";

contract TheDudesFactoryGenesisCollection is Ownable {

  uint public immutable maxItems = 50;
  uint256 public totalSupply;
  address public factoryAddress;
  uint256 public collectionId;

  mapping(uint256 => string) public tokenURIs;
  mapping(uint256 => bool) public lockedTokens;

  constructor (address factoryAddress_, uint256 collectionId_) {
    factoryAddress = factoryAddress_;
    collectionId = collectionId_;
  }

  function mint(address account, string calldata tokenURI_) public onlyOwner {
    require(totalSupply < maxItems, "All minted already.");
    uint256 tokenId = totalSupply;
    tokenURIs[tokenId] = tokenURI_;
    totalSupply++;
    ITheDudesFactoryV2(factoryAddress).mint(collectionId, account, tokenId);
  }

  function updateTokenURI(uint256 tokenId, string calldata tokenURI_) public onlyOwner {
    require(!lockedTokens[tokenId], "Token is locked.");
    tokenURIs[tokenId] = tokenURI_;
  }

  function lockTokenURI(uint256 tokenId) public onlyOwner {
    lockedTokens[tokenId] = true;
  }

  function tokenURI(uint256 tokenId) public view virtual returns (string memory) {
    return tokenURIs[tokenId];
  }
}
