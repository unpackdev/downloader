// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

interface ITokenController {
  /**
   * @dev Reverts when the caller is not a bridge.
   */
  error CallerIsNotABridge();

  /**
   * @dev Reverts when the address is zero.
   */
  error ZeroAddressError();

  /**
   * @dev Release tokens to the recipient.
   * @param recipient Address of the recipient.
   * @param amount Amount of tokens to release.
   */
  function releaseTokens(address recipient, uint256 amount) external;

  /**
   * @dev Reserve tokens from the sender.
   * @param sender Address of the sender.
   * @param amount Amount of tokens to reserve.
   */
  function reserveTokens(address sender, uint256 amount) external;

  /**
   * @dev Set the bridge contract address.
   * @param _bridgeContract Address of the bridge contract.
   */
  function setBridgeContract(address _bridgeContract) external;
}
