// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";

contract Shibaverse is ERC721, ERC721Enumerable, Ownable {
  uint256 public constant MAX_SUPPLY = 3333;
  uint256 public constant MAX_MINT_PER_TX = 3;
  uint256 public constant PRICE = 0.069 ether;

  bool public whitelistSaleOpen = false;
  bool public publicSaleOpen = false;
  mapping(address => uint256) private _whitelist;

  string private _baseTokenURI = '';

  constructor() ERC721("Shibaverse", "SV") {}

  function _baseURI() internal view override returns (string memory) {
    return _baseTokenURI;
  }

  function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable) {
    super._beforeTokenTransfer(from, to, tokenId);
  }

  function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool) {
    return super.supportsInterface(interfaceId);
  }

  function setBaseURI(string calldata newBaseURI) external onlyOwner {
    _baseTokenURI = newBaseURI;
  }

  function setWhitelistSaleOpen(bool newWhitelistSaleOpen) external onlyOwner {
    whitelistSaleOpen = newWhitelistSaleOpen;
  }

  function setPublicSaleOpen(bool newPublicSaleOpen) external onlyOwner {
    publicSaleOpen = newPublicSaleOpen;
  }

  function updateWhitelist(address[] calldata addresses, uint256[] calldata allowedMints) external onlyOwner {
    require(addresses.length == allowedMints.length, "Mismatching array lengths");
    for (uint256 i = 0; i < addresses.length; i++) {
      _whitelist[addresses[i]] = allowedMints[i];
    }
  }

  function getWhitelistedMints(address whitelistedAddress) external view returns (uint256) {
    return _whitelist[whitelistedAddress];
  }

  function mintWhitelist(uint256 numberOfMints) external payable {
    uint256 supply = totalSupply();

    require(whitelistSaleOpen, "Whitelist sale isn't open");
    require(_whitelist[msg.sender] >= numberOfMints, "You don't have enough mints allowed on the whitelist");
    require(msg.value >= numberOfMints * PRICE, "Insufficient ETH paid");
    require(supply + numberOfMints <= MAX_SUPPLY, "Exceeds max supply");

    _whitelist[msg.sender] -= numberOfMints;

    for (uint256 i = 0; i < numberOfMints; i++) {
      _safeMint(msg.sender, supply + i);
    }
  }

  function mintPublic(uint256 numberOfMints) external payable {
    uint256 supply = totalSupply();

    require(publicSaleOpen, "Public sale isn't open");
    require(msg.value >= numberOfMints * PRICE, "Insufficient ETH paid");
    require(numberOfMints <= MAX_MINT_PER_TX, "Exceeds max mint per tx");
    require(supply + numberOfMints <= MAX_SUPPLY, "Exceeds max supply");

    for (uint256 i = 0; i < numberOfMints; i++) {
      _safeMint(msg.sender, supply + i);
    }
  }

  function withdraw() external onlyOwner {
    (bool success, ) = msg.sender.call{value: address(this).balance}("");
    require(success, "Transfer failed");
  }
}
