// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.15;

import "./Executable.sol";
import "./UseStorageSlot.sol";
import "./ServiceRegistry.sol";
import "./IVariableDebtToken.sol";
import "./IWETHGateway.sol";
import "./ILendingPool.sol";
import "./Aave.sol";
import "./Aave.sol";
import "./IPoolV3.sol";
import "./UseRegistry.sol";

/**
 * @title Borrow | AAVE V3 Action contract
 * @notice Borrows token from AAVE's lending pool
 */
contract AaveV3Borrow is Executable, UseStorageSlot, UseRegistry {
  using Read for StorageSlot.TransactionStorage;
  using Write for StorageSlot.TransactionStorage;

  constructor(address _registry) UseRegistry(ServiceRegistry(_registry)) {}
  
  /**
   * @param data Encoded calldata that conforms to the BorrowData struct
   */
  function execute(bytes calldata data, uint8[] memory paramsMap) external payable override {
    BorrowData memory borrow = parseInputs(data);

    uint256 mappedBorrowAmount = store().readUint(
      bytes32(borrow.amount),
      paramsMap[1]
    );

    IPoolV3(getRegisteredService(AAVE_POOL)).borrow(
      borrow.asset,
      mappedBorrowAmount,
      2,
      0,
      address(this)
    );

    store().write(bytes32(mappedBorrowAmount));
  }

  function parseInputs(bytes memory _callData) public pure returns (BorrowData memory params) {
    return abi.decode(_callData, (BorrowData));
  }
}
