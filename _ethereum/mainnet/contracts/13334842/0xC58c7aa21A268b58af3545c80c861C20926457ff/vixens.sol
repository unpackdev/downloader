// SPDX-License-Identifier: None
pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./SafeMath.sol";
import "./ERC721Enumerable.sol";
import "./EnumerableSet.sol";

interface IBanana {
    function ownerOf(uint256 tokenId) external view returns (address owner);
}

contract VixensOfIoN is Ownable, ERC721Enumerable {
  using SafeMath for uint256;
  using EnumerableSet for EnumerableSet.UintSet;

  IBanana public bananaContract;

  uint256 public constant mintPrice = 0.035 ether;
  uint256 public constant txLimit = 20;

  uint256 public totalSupplyLimit = 10000;
  uint256 public publicMintSupplyLimit = 5973;
  bool public saleActive = false;

  string public baseUri;

  mapping(uint256 => bool) public bananaMinted;
  EnumerableSet.UintSet private mintedBananas;
  uint256 private publicMintCounter = 0;
  
  constructor(
    address bananaContractAddress
  ) ERC721("Vixens of IoN", "VIXEN") {
    bananaContract = IBanana(bananaContractAddress);
  }

  function _baseURI() internal view override returns (string memory) {
    return baseUri;
  }

  function setBaseURI(string calldata newBaseUri) external onlyOwner {
    baseUri = newBaseUri;
  }
  
  function toggleSaleActive() external onlyOwner {
    saleActive = !saleActive;
  }

  function mintPublic(uint numberOfTokens) external payable {
    require(saleActive, "SALE_INACTIVE");
    require(numberOfTokens <= txLimit, "EXCESS_TOKENS");
    require(msg.value == mintPrice.mul(numberOfTokens), "WRONG_PAYMENT");
    require(publicMintCounter + numberOfTokens <= publicMintSupplyLimit, "INSUFFICIENT_TOKENS");

    publicMintCounter += numberOfTokens;
    mint(msg.sender, numberOfTokens);
  }

  function mintBanana(uint256[] memory tokenIds) external payable {
    require(tokenIds.length > 0, "INPUT_EMPTY");
    require(msg.value == mintPrice.mul(tokenIds.length), "WRONG_PAYMENT");

    for(uint i = 0; i < tokenIds.length; i++) {
      require(bananaContract.ownerOf(tokenIds[i]) == msg.sender, "NOT_OWN_BANANA");
      // require(!bananaMinted[tokenIds[i]], "BANANA_USED");
      require(mintedBananas.add(tokenIds[i]), "BANANA_USED");
      // bananaMinted[tokenIds[i]] = true;
    }

    mint(msg.sender, tokenIds.length);
  }

  function mint(address to, uint numberOfTokens) private {
    require(totalSupply().add(numberOfTokens) <= totalSupplyLimit, "INSUFFICIENT_TOKENS");

    uint256 newId = totalSupply();
    for(uint i = 0; i < numberOfTokens; i++) {
      newId += 1;
      _safeMint(to, newId);
    }
  }

  function mintGoldBananas() external onlyOwner {
    mintedBananas.add(10001);
    mintedBananas.add(10002);
    mintedBananas.add(10003);
    mintedBananas.add(10004);
    mint(bananaContract.ownerOf(10001), 1);
    mint(bananaContract.ownerOf(10002), 1);
    mint(bananaContract.ownerOf(10003), 1);
    mint(bananaContract.ownerOf(10004), 1);
  }

  function airdropTo(address to, uint256 numberOfTokens) external onlyOwner {
    require(publicMintCounter + numberOfTokens <= publicMintSupplyLimit, "INSUFFICIENT_TOKENS");
    publicMintCounter += numberOfTokens;

    mint(to, numberOfTokens);
  }

  function withdraw() external onlyOwner {
    require(address(this).balance > 0, "NO_BALANCE");
    
    (bool success, ) = msg.sender.call{value: address(this).balance}("");
    require(success, "FAILED");
  }

  function tokensOwnedBy(address wallet) external view returns(uint256[] memory) {
    uint tokenCount = balanceOf(wallet);

    uint256[] memory ownedTokenIds = new uint256[](tokenCount);
    for(uint i = 0; i < tokenCount; i++){
      ownedTokenIds[i] = tokenOfOwnerByIndex(wallet, i);
    }

    return ownedTokenIds;
  }

  function getMintedBananas() external view returns(uint256[] memory) {
    return mintedBananas.values();
  }

  function isBananaMinted(uint256 tokenId) external view returns(bool) {
    return mintedBananas.contains(tokenId);
  }
}