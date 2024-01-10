// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721EnumerableLite.sol";
import "./Strings.sol";
import "./Ownable.sol";
import "./PaymentSplitter.sol";

contract Sixzeros is ERC721EnumerableLite, Ownable, PaymentSplitter {
  using Strings for uint256;

  uint256 public PRICE = 0.05 ether;
  uint256 public MAX_SUPPLY = 1000000;

  string public _baseTokenURI =
    "ipfs://QmdEFAjgo3mcxGcukQ7kvCp79eW2YTi7y6NBhV5HHKH5RX?";

  bool public paused = false;

  address dev = 0x776d2A6c0f8960CF1e8da9917Bc504e6E99D4dfE;
  address art = 0x767cE8f13d8fA9CC5CFf2243CFa44274E8366805;

  address[] addressList = [dev, art];
  uint256[] shareList = [25, 975];

  constructor()
    ERC721B("Six Zeros", "000000")
    PaymentSplitter(addressList, shareList)
  {}

  function mint(uint256 _count) external payable {
    require(!paused, "Sale is currently paused.");

    uint256 supply = totalSupply();
    require(supply + _count <= MAX_SUPPLY, "Exceeds max supply.");
    require(msg.value >= PRICE * _count, "Ether sent is not correct.");

    for (uint256 i = 0; i < _count; ++i) {
      _mint(msg.sender, supply + i);
    }
  }

  function mintTo(uint256[] calldata quantity, address[] calldata recipient)
    external
    onlyOwner
  {
    require(
      quantity.length == recipient.length,
      "Must provide equal quantities and recipients"
    );

    uint256 totalQuantity;
    uint256 supply = totalSupply();
    for (uint256 i; i < quantity.length; ++i) {
      totalQuantity += quantity[i];
    }
    require(supply + totalQuantity < MAX_SUPPLY, "Mint/order exceeds supply");

    for (uint256 i; i < recipient.length; ++i) {
      for (uint256 j; j < quantity[i]; ++j) {
        _mint(recipient[i], supply++);
      }
    }
  }

  function pause(bool _updatePaused) public onlyOwner {
    require(paused != _updatePaused, "New value matches old");
    paused = _updatePaused;
  }

  function setBaseURI(string calldata _newBaseURI) external onlyOwner {
    _baseTokenURI = _newBaseURI;
  }

  function tokenURI(uint256 tokenId)
    external
    view
    override
    returns (string memory)
  {
    require(
      _exists(tokenId),
      "ERC721Metadata: URI query for nonexistent token"
    );

    string memory baseURI = _baseTokenURI;
    return
      bytes(baseURI).length > 0
        ? string(abi.encodePacked(baseURI, tokenId.toString()))
        : "";
  }
}
