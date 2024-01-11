// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC721A.sol";

contract Outback is Ownable, ERC721A {
  using Strings for uint256;
  
  // Contract Constants
  uint128 public constant maxSupply = 8151;
  
  // Timestamps
  uint128 public immutable saleStartTime;

  // Contract Vars
  uint128 public teamClaimed;
  string public baseURI;

  mapping(address => uint8) public addressClaimed;

  constructor(uint128 _saleStartTime) ERC721A("Outback", "OBSH") {
    saleStartTime = _saleStartTime;
  }

  function mint(uint8 _amount) external  {
    require(addressClaimed[_msgSender()] + _amount <= 2, "Exceeds wallet mint amount.");
    require(totalSupply() + _amount <= maxSupply, "Quantity requested exceeds max supply.");
    require(tx.origin == msg.sender, "The caller is another contract.");
    require(block.timestamp >= saleStartTime, "Sale has not started yet.");

    _mint(msg.sender, _amount);
    addressClaimed[_msgSender()] += _amount;
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }

  function teamClaim(uint128 _amount) external  onlyOwner{
    require(teamClaimed + _amount <= 70, "Team has already claimed.");
    _mint(msg.sender, _amount);
    teamClaimed += _amount;
  }

  function setBaseURI(string calldata _newBaseURI) external onlyOwner {
    baseURI = _newBaseURI;
  }

  function _startTokenId() internal view virtual override returns (uint256) {
    return 1;
  }

  function tokenURI(uint256 _tokenId)
    public
    view
    virtual
    override
    returns (string memory)
  {
    require(
      _exists(_tokenId),
      "ERC721Metadata: URI query for nonexistent token"
    );
    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), ".json"))
        : "";
  }
}