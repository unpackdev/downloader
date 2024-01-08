// SPDX-License-Identifier: MIT
// eyJuYW1lIjoiME4xIC0gTWV0YWRhdGEiLCJkZXNjcmlwdGlvbiI6IlRoaXMgc2hvdWxkIE5PVCBiZSByZXZlYWxlZCBiZWZvcmUgYWxsIGFyZSBzb2xkLiBJbWFnZXMgY29udGFpbmVkIGJlbG93IiwiaW1hZ2VzIjoiMHg1MTZENTU0ODYxMzQ0QTc3NEI1MDY3NjY0ODcxNDM1ODMxNTQ3ODMyNTc2OTRBNTg2NDYzNEM2MzY1NTM3NDZGNTEzNjY1Nzg1NTU4Mzg1NDRBNkE0NjYxNjE1MSJ9
pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./Strings.sol";

contract BabyHodla is ERC721Enumerable, Ownable {
  using Strings for uint256;

  uint256 public constant HODLA_GIFT = 199;
  uint256 public constant HODLA_PUBLIC = 9_800;
  uint256 public constant HODLA_MAX = HODLA_GIFT + HODLA_PUBLIC;
  uint256 public constant PURCHASE_LIMIT = 25;
  uint256 public PRICE = 0.049 ether;

  bool public isActive = false;
  string public proof;

  /// @dev We will use these to be able to calculate remaining correctly.
  uint256 public totalGiftSupply;
  uint256 public totalPublicSupply;

  string private _contractURI = '';
  string private _tokenBaseURI = '';
  string private _tokenRevealedBaseURI = '';

  constructor() ERC721('BabyHodla', 'HODL') {}

  function purchase(uint256 numberOfTokens) external payable {
    require(isActive, 'Contract is not active');
    require(totalSupply() < HODLA_MAX, 'All tokens have been minted');
    require(numberOfTokens <= PURCHASE_LIMIT, 'Would exceed PURCHASE_LIMIT');
    /**
    * @dev The last person to purchase might pay too much.
    * This way however they can't get sniped.
    * If this happens, we'll refund the Eth for the unavailable tokens.
    */
    require(totalPublicSupply < HODLA_PUBLIC, 'Purchase would exceed HODLA_PUBLIC');
    require(PRICE * numberOfTokens <= msg.value, 'ETH amount is not sufficient');

    for (uint256 i = 0; i < numberOfTokens; i++) {
      /**
      * @dev Since they can get here while exceeding the HODLA_MAX,
      * we have to make sure to not mint any additional tokens.
      */
      if (totalPublicSupply < HODLA_PUBLIC) {
        /**
        * @dev Public token numbering starts after HODLA_GIFT.
        * And we don't want our tokens to start at 0 but at 1.
        */
        uint256 tokenId = HODLA_GIFT + totalPublicSupply + 1;

        totalPublicSupply += 1;
        _safeMint(msg.sender, tokenId);
      }
    }
  }

  function gift(address[] calldata to) external onlyOwner {
    require(totalSupply() < HODLA_MAX, 'All tokens have been minted');
    require(totalGiftSupply + to.length <= HODLA_GIFT, 'Not enough tokens left to gift');

    for(uint256 i = 0; i < to.length; i++) {
      /// @dev We don't want our tokens to start at 0 but at 1.
      uint256 tokenId = totalGiftSupply + 1;

      totalGiftSupply += 1;
      _safeMint(to[i], tokenId);
    }
  }

  function setIsActive(bool _isActive) external onlyOwner {
    isActive = _isActive;
  }
  
  function setPrice(uint256 newPrice) external onlyOwner {
    PRICE = newPrice;
  }

  function setProof(string calldata proofString) external onlyOwner {
    proof = proofString;
  }

  function withdraw() external onlyOwner {
    uint256 balance = address(this).balance;

    payable(msg.sender).transfer(balance);
  }

  function setContractURI(string calldata URI) external onlyOwner {
    _contractURI = URI;
  }

  function setBaseURI(string calldata URI) external onlyOwner {
    _tokenBaseURI = URI;
  }

  function setRevealedBaseURI(string calldata revealedBaseURI) external onlyOwner {
    _tokenRevealedBaseURI = revealedBaseURI;
  }

  function contractURI() public view returns (string memory) {
    return _contractURI;
  }

  function tokenURI(uint256 tokenId) public view override(ERC721) returns (string memory) {
    require(_exists(tokenId), 'Token does not exist');

    /// @dev Convert string to bytes so we can check if it's empty or not.
    string memory revealedBaseURI = _tokenRevealedBaseURI;
    return bytes(revealedBaseURI).length > 0 ?
      string(abi.encodePacked(revealedBaseURI, tokenId.toString())) :
      _tokenBaseURI;
  }
}