// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC721A.sol";

contract WomenTribePride is ERC721A, Ownable {
  uint256 constant _maxSupply = 2022;
  uint256 public cost = 0.02 ether;
  bool public isSaleActive;

  constructor() ERC721A("WomenTribePride", "WTP") {}

  function allTokensOfOwner(address user) public view returns (uint256[] memory) {
    uint256[] memory allTokens = new uint256[](balanceOf(user));
    for (uint16 i = 0; i < allTokens.length; i++) {
      allTokens[i] = tokenOfOwnerByIndex(user, i);
    }
    return allTokens;
  }

  function toggleSaleStatus() public onlyOwner {
    isSaleActive = !isSaleActive;
  }

  function withdraw() public onlyOwner {
    payable(msg.sender).transfer(address(this).balance);
  }

  function setCost(uint256 _cost) public onlyOwner {
    cost = _cost;
  }

  function mint(uint256 amount) public payable {
    require(isSaleActive, "Sale is not active");
    require(currentIndex < _maxSupply, "Sold out");
    require(amount > 0, "Amount must be greater than 0");
    require(msg.value >= amount * cost, "Not enough ETH");

    _mint(msg.sender, amount, '', false);
  }

  function mintAsOwner(address to, uint8 amount) public onlyOwner {
    require(currentIndex + amount < _maxSupply, "Sold out");
    _mint(to, amount, '', false);
  }

  function airdrop(address[] calldata _addresses, uint16[] calldata amounts) public onlyOwner {
    require(_addresses.length == amounts.length, "Addresses and amounts must have the same length");
    require(currentIndex + _addresses.length < _maxSupply, "Sold out");
    require(_addresses.length > 0, "Addresses must have at least one element");

    for (uint256 i = 0; i < _addresses.length; i++) {
      _mint(_addresses[i], amounts[i], '', false);
    }
  }

  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    require(_exists(tokenId), 'ERC721Metadata: URI query for nonexistent token');
    return "ipfs://QmUe2dtUiGQfE8EKxgwFBXA7TDEY4UEU4Vciyfz4h6c3Zr";
  }
}