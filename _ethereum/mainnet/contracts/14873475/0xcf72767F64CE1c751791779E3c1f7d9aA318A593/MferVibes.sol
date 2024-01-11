//SPDX-License-Identifier: MIT

pragma solidity ^0.8.14;

import "./ERC721A.sol";
import "./Strings.sol";
import "./Ownable.sol";
import "./PaymentSplitter.sol";

contract MferVibes is ERC721A, Ownable, PaymentSplitter {
  using Strings for uint;

  string public notRevealedURI;
  string public baseURI;  
  string public baseExtension;
  uint public price = 0.0169 ether;
  uint public maxSupply = 4200;
  uint private _reserved = 69;
  uint private _publicSupply;
  uint private _reserveSupply;
  bool public saleIsActive;
  bool public revealed;

  constructor(address[] memory _payees, uint[] memory _shares) 
  ERC721A("Mfer vibes", "M'vibes")
  PaymentSplitter(_payees, _shares) {}

  function _startTokenId() internal view virtual override returns (uint256) {
    return 1;
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }

  function mint(uint _mintAmount) public payable {
    require(saleIsActive, "Sale is not active");
    require(_mintAmount > 0, "You must mint at least 1 NFT");
    require(_publicSupply + _mintAmount <= maxSupply - _reserved, "Not enough supply");
    require(msg.value >= price * _mintAmount, "Please send the correct amount of ETH");
    _publicSupply += _mintAmount;
    _safeMint(msg.sender, _mintAmount);
  }

  function batchGift(address[] calldata _recipients, uint8[] calldata _alllowances) public onlyOwner {
    for (uint i = 0; i < _recipients.length; i++) {
        uint _mintAmount = _alllowances[i];
        require(_reserveSupply + _mintAmount <= _reserved, "Max reserve supply exceeded");
        for (uint j = 0; j < _mintAmount; ++j) {
            _safeMint(_recipients[i], _mintAmount);
        }
        _reserveSupply += _mintAmount;
    }
  }

  function tokenURI(uint tokenId) public view virtual override returns (string memory) {
    require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
    if(!revealed) {
      return notRevealedURI;
    }
    return bytes(baseURI).length > 0
        ? string(abi.encodePacked(_baseURI(), tokenId.toString(), baseExtension)): "";
  }

  function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
    notRevealedURI = _notRevealedURI;
  }

  function setBaseURI(string memory baseURI_, string memory _baseExtension) public onlyOwner {
    baseURI = baseURI_;
    baseExtension = _baseExtension;
  }

  function flipSaleState() public onlyOwner {
    saleIsActive = !saleIsActive;
  }
 
  function setPrice(uint _newPrice) public onlyOwner() {
    price = _newPrice;
  }

  function setRevealed(bool _revealed) public onlyOwner() {
      revealed = _revealed;
  }

// Payment splitter
  function etherBalanceOf(address _account) public view returns (uint256) {
        return
            ((address(this).balance + totalReleased()) * shares(_account)) /
            totalShares() -
            released(_account);
    }

    function release(address payable account) public override onlyOwner {
        super.release(account);
    }

    function withdraw() public {
        require(etherBalanceOf(msg.sender) > 0, "No funds to withdraw");
        super.release(payable(msg.sender));
    }
}