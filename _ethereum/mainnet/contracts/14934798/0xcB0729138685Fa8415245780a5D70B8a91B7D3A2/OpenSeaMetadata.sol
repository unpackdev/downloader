// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./Ownable.sol";

abstract contract OpenSeaMetadata is Ownable {

  string public _baseContarctURI;

  function contractURI() public view returns (string memory) {
      return _baseContarctURI;
  }
  function setContractURI(string memory _newContractURI) public onlyOwner {
      _baseContarctURI = _newContractURI;
  }
}