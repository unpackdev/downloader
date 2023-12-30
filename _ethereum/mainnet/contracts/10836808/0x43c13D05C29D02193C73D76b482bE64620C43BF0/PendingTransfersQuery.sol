pragma experimental ABIEncoderV2;
// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "./ERC20AdapterLib.sol";

contract PendingTransfersQuery {
  function execute(bytes memory) public view returns (ERC20AdapterLib.EscrowRecord[] memory) {
    return ERC20AdapterLib.getIsolatePointer().payments;
  }
}
