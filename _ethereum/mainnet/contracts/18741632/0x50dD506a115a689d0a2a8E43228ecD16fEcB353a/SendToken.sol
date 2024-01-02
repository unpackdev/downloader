// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.15;

import "./Executable.sol";
import "./SafeERC20.sol";
import "./Common.sol";
import "./UseStorageSlot.sol";
import "./ServiceRegistry.sol";
import "./Common.sol";
import "./UseRegistry.sol";

/**
 * @title SendToken Action contract
 * @notice Transfer token from the calling contract to the destination address
 */
contract SendToken is Executable, UseStorageSlot, UseRegistry {
  using SafeERC20 for IERC20;
  using Read for StorageSlot.TransactionStorage;

  constructor(address _registry) UseRegistry(ServiceRegistry(_registry)) {}
  
  /**
   * @param data Encoded calldata that conforms to the SendTokenData struct
   */
  function execute(bytes calldata data, uint8[] memory paramsMap) external payable override {
    SendTokenData memory send = parseInputs(data);
    send.amount = store().readUint(bytes32(send.amount), paramsMap[2]);

    if (send.asset != ETH) {
      if (send.amount == type(uint256).max) {
        send.amount = IERC20(send.asset).balanceOf(address(this));
      }
      IERC20(send.asset).safeTransfer(send.to, send.amount);
    } else {
      if (send.amount == type(uint256).max) {
        send.amount = address(this).balance;
      }
      payable(send.to).transfer(send.amount);
    }
  }

  function parseInputs(bytes memory _callData) public pure returns (SendTokenData memory params) {
    return abi.decode(_callData, (SendTokenData));
  }
}
