// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "./CNFI.sol";

contract MintCNFI is ConnectToken {
  function mint(address target, uint256 amount) public {
    _mint(target, amount);
  }
}
