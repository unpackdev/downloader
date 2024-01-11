// SPDX-License-Identifier: No license

pragma solidity ^0.8.0;

import "./ERC20AbstractToken.sol";

contract TRex is ERC20AbstractToken {
  constructor(
    string memory _name,
    string memory _symbol,
    uint256 _initialBalance
  ) ERC20AbstractToken(
    _name,
    _symbol,
    _initialBalance
  ) {}
}
