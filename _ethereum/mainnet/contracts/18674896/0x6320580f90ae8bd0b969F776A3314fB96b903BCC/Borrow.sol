// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.15;

import "./Executable.sol";
import "./UseStore.sol";
import "./OperationStorage.sol";
import "./IVariableDebtToken.sol";
import "./IWETHGateway.sol";
import "./ILendingPool.sol";
import "./Aave.sol";
import "./Aave.sol";
import "./IERC20.sol";

/**
 * @title Borrow | AAVE Action contract
 * @notice Borrows ETH from AAVE's lending pool
 */
contract AaveBorrow is Executable, UseStore {
  using Write for OperationStorage;

  constructor(address _registry) UseStore(_registry) {}

  /**
   * @param data Encoded calldata that conforms to the BorrowData struct
   */
  function execute(bytes calldata data, uint8[] memory) external payable override {
    BorrowData memory borrow = parseInputs(data);

    ILendingPool(registry.getRegisteredService(AAVE_LENDING_POOL)).borrow(
      borrow.asset,
      borrow.amount,
      2,
      0,
      address(this)
    );

    store().write(bytes32(borrow.amount));
  }

  function parseInputs(bytes memory _callData) public pure returns (BorrowData memory params) {
    return abi.decode(_callData, (BorrowData));
  }
}
