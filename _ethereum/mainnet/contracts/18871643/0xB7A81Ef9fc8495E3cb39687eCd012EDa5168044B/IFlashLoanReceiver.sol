// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.21;

/**
 * @title IFlashLoanReceiver interface
 * @notice Interface for the IFlashLoanReceiver.
 * @author Sturdy
 * @dev implement this interface to develop a flashloan-compatible flashLoanReceiver contract
 **/
interface IFlashLoanReceiver {
  function executeOperation(
    address[] calldata assets,
    uint256[] calldata amounts,
    uint256[] calldata premiums,
    address initiator,
    bytes calldata params
  ) external returns (bool);
}
