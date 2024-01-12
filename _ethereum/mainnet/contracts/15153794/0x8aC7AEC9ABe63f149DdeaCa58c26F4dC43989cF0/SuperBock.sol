// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC1155.sol";
import "./Ownable.sol";

contract SuperBock is ERC1155, Ownable {

  // storage

  mapping(address => bool) public minters;
  string internal _uri;

  // events

  event MinterAdded(address indexed minter);
  event MinterRemoved(address indexed minter);

  // modifiers

  modifier onlyMinter {
    require(minters[msg.sender], "Not a minter");
    _;
  }

  // functions

  constructor (string memory newURI) {
    _transferOwnership(msg.sender);
    _uri = newURI;
  }

  function uri(uint256) public view override returns (string memory) {
    return _uri;
  }

  function setURI(string memory newURI) public onlyOwner {
    _uri = newURI;
  }

  function addMinter(address minter) public onlyOwner {
    minters[minter] = true;
    emit MinterAdded(minter);
  }

  function removeMinter(address minter) public onlyOwner {
    minters[minter] = false;
    emit MinterRemoved(minter);
  }

  function mint(address to, uint256 id, uint256 amount, bytes memory data) public onlyMinter {
    _mint(to, id, amount, data);
  }

  function batchMint(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) public onlyMinter {
    _batchMint(to, ids, amounts, data);
  }

}
