// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.6;

import "./Ownable.sol";
import "./IERC20.sol";

contract Treasury is Ownable {
  // solhint-disable-next-line no-empty-blocks
  receive() external payable {}

  /**
   * @notice Transfer token to recipient.
   * @param token Target token.
   * @param recipient Recipient.
   * @param amount Transfer amount.
   */
  function transfer(
    IERC20 token,
    address recipient,
    uint256 amount
  ) external onlyOwner {
    require(amount > 0, "Treasury::transfer: negative or zero amount");
    require(recipient != address(0), "Treasury::transfer: invalid recipient");
    token.transfer(recipient, amount);
  }

  /**
   * @notice Transfer ETH to recipient.
   * @param recipient Recipient.
   * @param amount Transfer amount.
   */
  function transferETH(address payable recipient, uint256 amount) external onlyOwner {
    require(amount > 0, "Treasury::transferETH: negative or zero amount");
    require(recipient != address(0), "Treasury::transferETH: invalid recipient");
    recipient.transfer(amount);
  }

  /**
   * @notice Approve token to recipient.
   * @param token Target token.
   * @param recipient Recipient.
   * @param amount Approve amount.
   */
  function approve(
    IERC20 token,
    address recipient,
    uint256 amount
  ) external onlyOwner {
    uint256 allowance = token.allowance(address(this), recipient);
    if (allowance > 0) {
      token.approve(recipient, 0);
    }
    token.approve(recipient, amount);
  }
}
