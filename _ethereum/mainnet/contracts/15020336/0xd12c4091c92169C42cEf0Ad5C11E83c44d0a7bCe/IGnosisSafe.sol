// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Enum.sol";

interface IGnosisSafe {
  function execTransaction(
    address to,
    uint256 value,
    bytes calldata data,
    Enum.Operation operation,
    uint256 safeTxGas,
    uint256 baseGas,
    uint256 gasPrice,
    address gasToken,
    address payable refundReceiver,
    bytes memory signatures
  ) external payable returns (bool success);
}