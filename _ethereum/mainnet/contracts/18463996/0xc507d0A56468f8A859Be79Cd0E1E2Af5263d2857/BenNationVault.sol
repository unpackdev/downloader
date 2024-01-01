// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "./SafeERC20.sol";
import "./Ownable.sol";

/**
 * @title BenNationVault
 * @author Ben Coin Collective
 * @notice This vault holds reward tokens for Ben Nation pools using the same reward token as staked (e.g. Earn BEN by staking BEN).
 * @dev The owner of this contract is the corresponding Ben Nation pool contract.
 */
contract BenNationVault is Ownable {
  using SafeERC20 for IERC20;

  /**
   * @notice Safely transfer reward tokens to a user
   * @param _token The reward token to send
   * @param _to The recipient's address
   * @param _amount The amount of reward tokens to send
   * @dev Only callable by the owner
   */
  function safeTransfer(IERC20 _token, address _to, uint _amount) external onlyOwner {
    _token.safeTransfer(_to, _amount);
  }
}
