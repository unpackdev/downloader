// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

/**
 * @title ITransferRules interface
 * @dev The interface for any on-chain SRC20 transfer rule
 * Transfer Rules are expected to have the same interface
 * This interface is used by the SRC20 token
 */
interface ITransferRules {
  function setSRC(address src20) external returns (bool);

  function doTransfer(
    address from,
    address to,
    uint256 value
  ) external returns (bool);
}
