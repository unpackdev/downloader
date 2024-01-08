//SPDX-License-Identifier: Unlicense
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "./console.sol";
import "./Types.sol";
import "./IERC20.sol";
import "./SafeMath.sol";
import "./IDexRouter.sol";
import "./BaseAccess.sol";

// @dev The ZrxRouter is used by settlement to execute orders through 0x
contract ZrxRouter is BaseAccess, IDexRouter {
    using SafeMath for uint256;
    using SafeMath for uint112;
    using SafeMath for uint;

    function initialize() public initializer {
      BaseAccess.initAccess();
    }

  // @dev Executes a call to 0x to make fill the order
  // @param order - contains the order details from the Smart Order Router
  // @param orderCallData - abi encoded swapTarget address and data from 0x API
  function fill(Types.Order calldata order, bytes calldata orderCallData) 
    external override returns (bool success, string memory failReason) {

      //call data contains the target address and data to pass to it to execute
      (address swapTarget, address allowanceTarget, bytes memory data) = abi.decode(orderCallData, (address,address,bytes));
      
      console.log("Going to swap target", swapTarget);
      console.log("Approving allowance for", allowanceTarget);

      //Settlement transferred token input amount so we can swap
      uint256 balanceBefore = order.output.token.balanceOf(address(this));
    
      console.log("Balance of input token b4", balanceBefore);

      //for protocols that require zero-first approvals
      require(order.input.token.approve(allowanceTarget, 0));

      //make sure 0x target has approval to spend this contract's tokens
      require(order.input.token.approve(allowanceTarget, order.input.amount));

      //execute the swap
      console.log("Swapping...");
      (bool _success,) = swapTarget.call{gas: gasleft()}(data);
      
      if(!_success) {
        console.log("Failed to swap");
        return (false, "SWAP_CALL_FAILED");
      }

      //make sure we received tokens
      uint256 balanceAfter = order.output.token.balanceOf(address(this));
      uint256 diff = balanceAfter.sub(balanceBefore);
      console.log("Balance received", diff);

      require(diff >= order.output.amount, "Insufficient output amount");
      if(!order.output.token.transfer(order.trader, diff)) {
        console.log("Could not transfer tokens to trader");
        return (false, "Failed to transfer funds to trader");
      }
      return (true,"");
  }

  // Payable fallback to allow this contract to receive protocol fee refunds.
  receive() external payable {}

}
