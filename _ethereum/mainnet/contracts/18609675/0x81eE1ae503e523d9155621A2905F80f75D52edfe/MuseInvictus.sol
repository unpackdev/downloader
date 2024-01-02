// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./IERC2981.sol";

contract MuseInvictus is ERC721A, Ownable, IERC2981 {
  uint256 public MAX_SUPPLY = 1170;
  bool public isActive = false;
  uint256 public tier1Price = 0.054 ether;
  uint256 public tier2Price = 0.054 ether;
  uint256 public tier3Price = 0.108 ether;
  uint256 public tier4Price = 0.162 ether;
  string public _baseTokenURI;
  address private _royaltyRecipient;
  uint256 private _royaltyPercentage = 10;

  constructor(string memory baseURI, address recipient) ERC721A("Muse Invictus", "Muse") Ownable() IERC2981() {
    setBaseURI(baseURI);
    _royaltyRecipient = recipient;
  }

  modifier saleIsOpen {
    require(totalSupply() < MAX_SUPPLY, "Sale has ended.");
    _;
  }

  modifier onlyAuthorized() {
    require(owner() == msg.sender, "Unauthorized");
    _;
  }

  function setTier1Price(uint256 _price) public onlyAuthorized {
    tier1Price = _price;
  }

  function setTier2Price(uint256 _price) public onlyAuthorized {
    tier2Price = _price;
  }

  function setTier3Price(uint256 _price) public onlyAuthorized {
    tier3Price = _price;
  }

  function setTier4Price(uint256 _price) public onlyAuthorized {
    tier4Price = _price;
  }

  function toggleSale() public onlyAuthorized {
    isActive = !isActive;
  }

  function setBaseURI(string memory baseURI) public onlyAuthorized {
    _baseTokenURI = baseURI;
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return _baseTokenURI;
  }

  function getCurrentPrice() public view returns (uint256) {
    uint256 mintIndex = totalSupply();

    if (mintIndex <= 167) {
      return tier1Price;
    } else if (mintIndex <= 531) {
      return tier2Price;
    } else if (mintIndex <= 805) {
      return tier3Price;
    }

    return tier4Price;
  }

  function batchAirdrop(uint256 _count, address[] calldata addresses) external onlyAuthorized {
    uint256 supply = totalSupply();
    require(supply < MAX_SUPPLY, "Total supply spent.");

    for (uint256 i = 0; i < addresses.length; i++) {
      require(addresses[i] != address(0), "Can't add a null address");
      _safeMint(addresses[i], _count);
    }
  }

  function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
    require(_exists(_tokenId), "Token Id Non-existent");
    return bytes(_baseURI()).length > 0 ? string(abi.encodePacked(_baseURI(), Strings.toString(_tokenId), ".json")) : "";
  }

  function _startTokenId() internal view virtual override returns (uint256) {
    return 1;
  }

  function setRoyaltyInfo(address recipient, uint256 percentage) public onlyAuthorized {
    require(percentage <= 100, "Royalty percentage is too high");
    _royaltyRecipient = recipient;
    _royaltyPercentage = percentage;
  }

  function royaltyInfo(uint256 tokenId, uint256 salePrice) external view override returns (address, uint256) {
    require(_exists(tokenId), "Token Id Non-existent");
    uint256 royaltyAmount = (salePrice * _royaltyPercentage) / 100;
    return (_royaltyRecipient, royaltyAmount);
  }

  function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721A, IERC165) returns (bool) {
    return super.supportsInterface(interfaceId);
  }

  function mint(uint256 _count) public payable saleIsOpen {
    uint256 mintIndex = totalSupply();

    if (msg.sender != owner()) {
      require(isActive, "Sale is not active currently");
      require(mintIndex + _count <= MAX_SUPPLY, "Total supply exceeded");

      uint256 totalCost = 0;
      for (uint256 i = 0; i < _count; i++) {
        if (mintIndex + i < 167) {
          totalCost += tier1Price;
        } else if (mintIndex + i < 531) {
          totalCost += tier2Price;
        } else if (mintIndex + i < 805) {
          totalCost += tier3Price;
        } else {
          totalCost += tier4Price;
        }
      }
      require(msg.value >= totalCost, "Insufficient ETH amount sent");

      payable(owner()).transfer(totalCost * _count);
    }

    _safeMint(msg.sender, _count);
  }
}