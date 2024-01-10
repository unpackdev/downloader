// SPDX-License-Identifier: MIT

/*
Adzuki is entirely copy-pasting images from Azuki:
1. Half of the mint fee is immediately given to the holder of the same NFT ID of Azuki collection.
2. All copyrights of Adzuki and its royalty are attributed to the holder of the same NFT ID of Azuki collection.
3. Top 1000 is free, so the mint fee for those holders will be distributed after the mint is completed.
4. Just like Azuki, Adzuki uses ERC721A to save gas.

Azuki: https://www.azuki.com
Adzuki: https://adzuki.art
*/

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./Strings.sol";
import "./IERC721.sol";

import "./ERC721A.sol";

contract Adzuki is Ownable, ERC721A, ReentrancyGuard {
  uint256 public constant MAX_MINT_AMOUNT_PER_TX = 100;
  uint256 public constant MAX_SUPPLY = 10000;
  uint256 public constant PRICE = 0.05 ether;
  uint256 public constant AZUKI_FEE = PRICE / 2; // 0.025 ether
  uint256 public constant FREE_AMOUNT = 1000;
  
  address public azuki = 0xED5AF388653567Af2F388E6224dC7C4b3241C544;

  constructor() ERC721A("Adzuki", "ADZUKI", MAX_MINT_AMOUNT_PER_TX, MAX_SUPPLY) {}

  function _baseURI() internal pure override returns (string memory) {
      return "ipfs://QmV4kdAUCVUMjWCZhnfUVhTSyqNDAQKdYN1tnt3AAT5kUy/";
  }

  function mint(uint256 amount) public payable {
      require(amount > 0 && amount <= MAX_MINT_AMOUNT_PER_TX, "Invalid mint amount!");
      require(totalSupply() + amount <= MAX_SUPPLY, "Max supply exceeded!");
      require(msg.value == PRICE * amount, "Insufficient funds!");

      uint256 tokenId = totalSupply();
      for (uint256 i = 0; i < amount; i++) {
        address azukiOwner = IERC721(azuki).ownerOf(tokenId);
        azukiOwner.call{value: AZUKI_FEE}(""); // ignore, Not all is success
        tokenId++;
      }

      _safeMint(msg.sender, amount);
  }

  function freeMint(uint256 amount) public {
      require(totalSupply() < FREE_AMOUNT, "No free");
      require(amount > 0 && amount <= MAX_MINT_AMOUNT_PER_TX, "Invalid mint amount!");
      require(totalSupply() + amount <= MAX_SUPPLY, "Max supply exceeded!");

      _safeMint(msg.sender, amount);
  }

  function withdraw() public onlyOwner nonReentrant {
    uint256 balance = address(this).balance;
    Address.sendValue(payable(owner()), balance);
  }

  function getOwnershipData(uint256 tokenId)
    external
    view
    returns (TokenOwnership memory)
  {
    return ownershipOf(tokenId);
  }

  function royaltyInfo(uint256 tokenId, uint256 salePrice)
      external
      view
      virtual
      override
      returns (address, uint256)
    {
      // 5% to azuki owner
      address azukiOwner = IERC721(azuki).ownerOf(tokenId);
      uint256 royaltyAmount = (salePrice * 5) / 100;

      return (azukiOwner, royaltyAmount);
    }
}
