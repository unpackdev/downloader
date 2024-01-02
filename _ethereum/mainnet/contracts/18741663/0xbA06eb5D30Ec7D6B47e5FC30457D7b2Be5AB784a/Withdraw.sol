// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.15;

import "./Executable.sol";
import "./UseStorageSlot.sol";
import "./ServiceRegistry.sol";
import "./ILendingPool.sol";
import "./Aave.sol";
import "./Aave.sol";
import "./IPoolV3.sol";
import "./UseRegistry.sol";

/**
 * @title Withdraw | AAVE V3 Action contract
 * @notice Withdraw collateral from AAVE's lending pool
 */
contract AaveV3Withdraw is Executable, UseStorageSlot, UseRegistry {
  using Write for StorageSlot.TransactionStorage;

  constructor(address _registry) UseRegistry(ServiceRegistry(_registry)) {}

  /**
   * @param data Encoded calldata that conforms to the WithdrawData struct
   */
  function execute(bytes calldata data, uint8[] memory) external payable override {
    WithdrawData memory withdraw = parseInputs(data);

    uint256 amountWithdrawn = IPoolV3(getRegisteredService(AAVE_POOL)).withdraw(
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
