//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721.sol";
import "./Ownable.sol";

contract KissMas is ERC721, Ownable {

  uint96 private supply;
  address public minter;

  string public baseURI;

  constructor(
    string memory _name,
    string memory _symbol,
    string memory _URI
  ) ERC721(_name, _symbol) {
    baseURI = _URI;
    minter = msg.sender;
  }

  /* view functions */

  function totalSupply() external view returns (uint) {
    return supply;
  }

  function _baseURI() internal view override returns (string memory) {
    return baseURI;
  }

  /* mutating functions */

  function setBaseURI(string memory URI) external onlyOwner {
    baseURI = URI;
  }

  function changeMinter(address newMinter) external onlyOwner {
    minter = newMinter;
  }

  function mint(
    address[] calldata destinations,
    uint[] calldata amounts,
    uint expectedSupply
  ) external {

    uint currentSupply = supply;
    address currentMinter = minter;

    require(msg.sender == currentMinter, "!minter");

    for (uint i = 0; i < amounts.length; i++) {

      uint amount = amounts[i];
      address destination = destinations[i];

      for (uint j = 0; j < amount; j++) {
        _safeMint(destination, ++currentSupply);
      }
    }

    require(currentSupply == expectedSupply, "!supply");
    supply = uint96(currentSupply);
  }

}
