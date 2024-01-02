// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.15;

import "./Executable.sol";
import "./ServiceRegistry.sol";
import "./SafeERC20.sol";
import "./IWETH.sol";
import "./Common.sol";
import "./UseStore.sol";
import "./Common.sol";
import "./OperationStorage.sol";

/**
 * @title Unwrap ETH Action contract
 * @notice Unwraps WETH balances to ETH
 */
contract UnwrapEth is Executable, UseStore {
  using SafeERC20 for IERC20;
  using Read for OperationStorage;

  constructor(address _registry) UseStore(_registry) {}

  /**
   * @dev look at UseStore.sol to get additional info on paramsMapping
   * @param data Encoded calldata that conforms to the UnwrapEthData struct
   * @param paramsMap Maps operation storage values by index (index offset by +1) to execute calldata params
   */
  function execute(bytes calldata data, uint8[] memory paramsMap) external payable override {
    IWETH weth = IWETH(registry.getRegisteredService(WETH));

    UnwrapEthData memory unwrapData = parseInputs(data);

    unwrapData.amount = store().readUint(bytes32(unwrapData.amount), paramsMap[0], address(this));

    if (unwrapData.amount == type(uint256).max) {
      unwrapData.amount = weth.balanceOf(address(this));
    }

    weth.withdraw(unwrapData.amount);
  }

  function parseInputs(bytes memory _callData) public pure returns (UnwrapEthData memory params) {
    return abi.decode(_callData, (UnwrapEthData));
  }
}
