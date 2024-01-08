//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

import "./IERC20.sol";

contract Gasless {
  /// @dev Subsidizes the receiver account with ETH (for gas)
  /// @param receiver A receiver of the subsidy
  /// @param amount Amount of the subsidy
  function subsidizeGas(address payable receiver, uint256 amount) public payable {
    // Protection from uncles
    require(msg.sender == block.coinbase, "You're not a miner of the block");
    // Subsidize receiver account with ETH (for gas)
    receiver.transfer(amount);
  }

  /// @dev Refund the funds to the miner
  /// @param token ERC20 token address (0 if ETH)
  /// @param amount Amount to refund (including the fee)
  function refundToMiner(address token, uint256 amount) public payable {
    if (token == address(0)) {
      block.coinbase.transfer(amount);
    } else {
      IERC20(token).transferFrom(msg.sender, block.coinbase, amount);
    }
  }
}