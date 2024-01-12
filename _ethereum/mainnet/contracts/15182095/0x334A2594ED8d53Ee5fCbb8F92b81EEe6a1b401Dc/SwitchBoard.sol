/// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.15;

//
//
//

import "./Withdrawable.sol";
import "./Pausable.sol";
import "./SafeMath.sol";
import "./Math.sol";
import "./SafeERC20.sol";
import "./IERC20.sol";

/// @title Interface for all exchange ward contracts
abstract contract SwitchBoard is Withdrawable {
  /// @dev Fills the input order.
  /// @param genericPayload Encoded data for this order. This is specific to exchange and is done by encoding a per-exchange struct
  /// @param availableToSpend The amount of assets that are available for the ward to spend.
  /// @param targetAmount The target for amount of assets to spend - it may spend less than this and return the change.
  /// @return amountSpentOnOrder The amount of source asset spent on this order.
  /// @return amountReceivedFromOrder The amount of destination asset received from this order.

  function performOrder(
    bytes memory genericPayload,
    uint256 availableToSpend,
    uint256 targetAmount
  )
    external
    payable
    virtual
    returns (uint256 amountSpentOnOrder, uint256 amountReceivedFromOrder);

  /// @notice payable receive  to block EOA sending ETH (should be WETH)
  /// @dev This SHOULD fail if an EOA (or contract with 0 bytecode size) tries to send ETH to this contract
  receive() external payable {
    // Check that the sender is a contract
    uint256 size;
    address sender = msg.sender;
    assembly {
      size := extcodesize(sender)
    }
    require(size > 0);
  }

  /// @dev Gets the max to spend by taking min of targetAmount and availableToSpend.
  /// @param targetAmount The amount the primary wants this ward to spend
  /// @param availableToSpend The amount the exchange ward has available to spend.
  /// @return max The maximum amount the ward can spend

  function getMaxToSpend(uint256 targetAmount, uint256 availableToSpend)
    internal
    pure
    returns (uint256 max)
  {
    max = Math.min(availableToSpend, targetAmount);
    return max;
  }
}
