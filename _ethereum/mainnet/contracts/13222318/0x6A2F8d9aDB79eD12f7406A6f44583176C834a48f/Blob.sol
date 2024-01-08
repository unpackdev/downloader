//SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";

//Custom utils for Blob
import "./BlobGenerator.sol";

contract Blob is ERC721Enumerable, Ownable, BlobGenerator {
  // price per blob 0.08
  uint256 public constant NFT_PRICE = 80000000000000000;
  // discount price per. discount when minting >= 8;
  uint256 public constant NFT_DISCOUNT_PRICE = 50000000000000000;
  uint256 public constant NFT_DISCOUNT_THRESHOLD = 8;

  // max supply
  uint256 public constant MAX_SUPPLY = 8108;

  constructor(string memory name, string memory symbol)
    ERC721(name, symbol)
    BlobGenerator()
  {
    //owner gets first 10
    for (uint256 i = 0; i < 10; i++) {
      _safeMint(_msgSender(), totalSupply());
    }
  }

  //smart minting: "try" to mint up to a number requested then return change
  function mint(uint256 numberToMint) public payable {
    require(totalSupply() < MAX_SUPPLY, "Blobs are sold out!!");
    require(numberToMint > 0, "At least 1 should be minted");

    uint256 _msgValue = msg.value;
    uint256 _unitPrice = NFT_PRICE;

    //check if discount applies
    if (numberToMint >= NFT_DISCOUNT_THRESHOLD) {
      _unitPrice = NFT_DISCOUNT_PRICE;
    }

    require(_msgValue >= numberToMint * _unitPrice, "Requires more funding");

    uint256 numberMinted = 0;
    do {
      _safeMint(_msgSender(), totalSupply());
      numberMinted++;
    } while (numberMinted < numberToMint && totalSupply() < MAX_SUPPLY);

    uint256 payment = numberMinted * _unitPrice;
    uint256 remainder = _msgValue - payment;
    if (remainder > 0) {
      //return any change
      payable(_msgSender()).transfer(remainder);
    }
  }

  function withdraw() public onlyOwner {
    uint256 balance = address(this).balance;
    payable(_msgSender()).transfer(balance);
  }

  function tokenURI(uint256 tokenId)
    public
    view
    override
    returns (string memory)
  {
    require(
      _exists(tokenId),
      "ERC721Metadata: URI query for nonexistent token"
    );
    return generateTokenURI(tokenId);
  }
}
