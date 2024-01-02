// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.15;

import "./Executable.sol";
import "./ServiceRegistry.sol";
import "./SafeERC20.sol";
import "./IWETH.sol";
import "./Common.sol";
import "./Swap.sol";
import "./Common.sol";
import "./UseStorageSlot.sol";
import "./ServiceRegistry.sol";
import "./UseRegistry.sol";

/**
 * @title SwapAction Action contract
 * @notice Call the deployed Swap contract which handles swap execution
 */
contract SwapAction is Executable, UseStorageSlot, UseRegistry {
  using SafeERC20 for IERC20;
  using Write for StorageSlot.TransactionStorage;

  constructor(address _registry) UseRegistry(ServiceRegistry(_registry)) {}

  /**
   * @dev The swap contract is pre-configured to use a specific exchange (EG 1inch)
   * @param data Encoded calldata that conforms to the SwapData struct
   */
  function execute(bytes calldata data, uint8[] memory) external payable override {
    address swapAddress = getRegisteredService(SWAP);

    SwapData memory swap = parseInputs(data);

    IERC20(swap.fromAsset).safeApprove(swapAddress, swap.amount);

    uint256 received = Swap(swapAddress).swapTokens(swap);

    store().write(bytes32(received));
  }

  function parseInputs(bytes memory _callData) public pure returns (SwapData memory params) {
    return abi.decode(_callData, (SwapData));
  }
}
