// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC165Storage.sol";

abstract contract OnApprove is ERC165Storage {
  constructor() {
    _registerInterface(OnApprove(this).onApprove.selector);
  }

  function onApprove(address owner, address spender, uint256 amount, bytes calldata data) external virtual returns (bool);
}

