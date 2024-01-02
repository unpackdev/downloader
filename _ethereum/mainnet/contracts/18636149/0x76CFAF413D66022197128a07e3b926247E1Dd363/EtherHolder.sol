// SPDX-License-Identifier: MIT
pragma solidity =0.8.20;
pragma abicoder v2;

// Imports
import "./UniswapV3Trading.sol";

/**
 * An abstract contract which enables receiving Ethers.
 */
abstract contract EtherHolder {
  // Events
  event Deposit(address indexed from, uint256 value);

  /**
   * Handles incoming Ethers by accepting those and trigerring Deposit() event.
   */
  receive() external payable {
    emit Deposit(msg.sender, msg.value);
  }
}
