//SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import "./ERC165.sol";

abstract contract OnApprove2 is ERC165 {
  constructor() {
    bytes4 OnApproveSelector= bytes4(keccak256("onApprove(address,address,uint256,bytes)"));

    _registerInterface(OnApproveSelector);
    // _registerInterface(OnApprove(this).onApprove.selector);
  }

  // function onApprove(address owner, address spender, uint256 amount, bytes calldata data) external returns (bool);
}