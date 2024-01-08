// SPDX-License-Identifier: MIT
pragma solidity >=0.5.11 <0.9.0;

import "./ERC1155Tradable.sol";

contract JevelsERC1155 is ERC1155Tradable {
  string private _contractURI = "https://jevels.com/contract-uri";

  constructor(address[] memory _proxyRegistries)
  ERC1155Tradable(
    "Jevels",
    "JVL",
      _proxyRegistries
  ) {}

  function contractURI() public view returns (string memory) {
    return _contractURI;
  }

  function setContractURI(string calldata contractURI_) public returns (bool) {
    _contractURI = contractURI_;
    return true;
  }
}
