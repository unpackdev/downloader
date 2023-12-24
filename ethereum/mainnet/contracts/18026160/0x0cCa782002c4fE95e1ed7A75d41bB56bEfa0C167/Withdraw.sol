// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.15;

import "./Executable.sol";
import "./UseStore.sol";
import "./OperationStorage.sol";
import "./Spark.sol";
import "./Spark.sol";
import "./IPool.sol";

/**
 * @title Withdraw | Spark Action contract
 * @notice Withdraw collateral from Spark's lending pool
 */
contract SparkWithdraw is Executable, UseStore {
  using Write for OperationStorage;

  constructor(address _registry) UseStore(_registry) {}

  /**
   * @param data Encoded calldata that conforms to the WithdrawData struct
   */
  function execute(bytes calldata data, uint8[] memory) external payable override {
    WithdrawData memory withdraw = parseInputs(data);

    uint256 amountWithdrawn = IPool(registry.getRegisteredService(SPARK_LENDING_POOL)).withdraw(
      withdraw.asset,
      withdraw.amount,
      withdraw.to
    );

    store().write(bytes32(amountWithdrawn));
  }

  function parseInputs(bytes memory _callData) public pure returns (WithdrawData memory params) {
    return abi.decode(_callData, (WithdrawData));
  }
}
