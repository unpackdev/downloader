// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

/**
 * @title ITokenRecipient
 *
 * @notice Recipient Cart Token and stake
 *
 */

interface ITokenRecipient {
  function tokensReceived(
      address from,
      uint amount,
      bytes calldata exData
  ) external returns (bool);
}