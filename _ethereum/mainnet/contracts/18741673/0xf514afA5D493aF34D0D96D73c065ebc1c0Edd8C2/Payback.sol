// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.15;

import "./Executable.sol";
import "./UseStorageSlot.sol";
import "./ServiceRegistry.sol";
import "./IVariableDebtToken.sol";
import "./IWETHGateway.sol";
import "./Aave.sol";
import "./ILendingPool.sol";
import "./IPoolV3.sol";
import "./Aave.sol";
import "./UseRegistry.sol";


/**
 * @title Payback | AAVE V3 Action contract
 * @notice Pays back a specified amount to AAVE's lending pool
 */
contract AaveV3Payback is Executable, UseStorageSlot, UseRegistry {
  using Write for StorageSlot.TransactionStorage;
  using Read for StorageSlot.TransactionStorage;


  constructor(address _registry) UseRegistry(ServiceRegistry(_registry)) {}

  /**
   * @dev Look at UseStore.sol to get additional info on paramsMapping.
   * @dev The paybackAll flag - when passed - will signal the user wants to repay the full debt balance for a given asset
   * @param data Encoded calldata that conforms to the PaybackData struct
   * @param paramsMap Maps operation storage values by index (index offset by +1) to execute calldata params
   */
  function execute(bytes calldata data, uint8[] memory paramsMap) external payable override {
    PaybackData memory payback = parseInputs(data);

    payback.amount = store().readUint(bytes32(payback.amount), paramsMap[1]);

    if (payback.onBehalf == address(0)) {
      payback.onBehalf = address(this);
    }

    IPoolV3(getRegisteredService(AAVE_POOL)).repay(
      payback.asset,
      payback.paybackAll ? type(uint256).max : payback.amount,
      2,
      payback.onBehalf
    );

    store().write(bytes32(payback.amount));
  }

  function parseInputs(bytes memory _callData) public pure returns (PaybackData memory params) {
    return abi.decode(_callData, (PaybackData));
  }
}
