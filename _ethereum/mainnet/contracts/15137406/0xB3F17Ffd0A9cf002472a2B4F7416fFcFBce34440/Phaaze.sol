// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "./ERC1155.sol";

contract Phaaze is ERC1155 {
  string public name = "Phaaze";

  constructor(address artist_, uint256 amountToMint, string memory baseURI) ERC1155(baseURI) {
    for (uint i = 1; i < 9; i++) {
      _mint(artist_, i, amountToMint, "");
    }
  }
}
