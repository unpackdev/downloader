// SPDX-License-Identifier: MIT

/*
Azuki Banner is profile banner NFT, generated from Azuki and Adzuki.
1. Feel free to use.<br/>
2. All copyrights of Azuki Banner and its royalty are attributed to the holder of the same NFT ID of Azuki collection.<br/>
3. Just like Azuki, Azuki Banner uses ERC721A to save gas.

Azuki: https://www.azuki.com
Adzuki: https://adzuki.art
Azuki Banner: https://banner.adzuki.art
*/

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./Strings.sol";
import "./IERC721.sol";

import "./ERC721A.sol";

contract AzukiBanner is Ownable, ERC721A, ReentrancyGuard {
  uint256 public constant MAX_MINT_AMOUNT_PER_TX = 100;
  uint256 public constant MAX_SUPPLY = 10000;
  uint256 public constant FREE_AMOUNT = 1000;
  
  address public azuki = 0xED5AF388653567Af2F388E6224dC7C4b3241C544;
  address public adzuki = 0x79985Cd00cdea2AA0002E8EF26180D0af7fe9fF3;
  uint256 public price;

  constructor() ERC721A("Azuki Banner", "AB", MAX_MINT_AMOUNT_PER_TX, MAX_SUPPLY) {
    azuki = address(this);
    price = 0.01 ether;
  }

  function _baseURI() internal pure override returns (string memory) {
      return "ipfs://QmVq8Yh32FhcNUa3agPQ1iwtgwv94qWsP68v6ZY3XgmaEd/";
  }

  function mint(uint256 amount) public payable {
      require(amount > 0 && amount <= MAX_MINT_AMOUNT_PER_TX, "Invalid mint amount!");
      require(totalSupply() + amount <= MAX_SUPPLY, "Max supply exceeded!");
      require(msg.value == price * amount, "Insufficient funds!");

      _safeMint(msg.sender, amount);
  }

  function isAzukiHolder(address account) public view returns (bool) {
    if (IERC721(azuki).balanceOf(account) > 0 || 
      IERC721(adzuki).balanceOf(account) > 0) {
        return true;
    }
    return false;
  }

  function freeMint(uint256 amount) public {
    require(totalSupply() < FREE_AMOUNT, "No free");
    require(isAzukiHolder(msg.sender), "Not azuki holder!");
    require(amount > 0 && amount <= 3, "Invalid free mint amount!");
    require(totalSupply() + amount <= MAX_SUPPLY, "Max supply exceeded!");

    _safeMint(msg.sender, amount);
  }

  function updatePrice(uint256 newPrice) public onlyOwner {
    price = newPrice;
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
