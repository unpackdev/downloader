//SPDX-License-Identifier: Unlicense
pragma solidity ^0.6.8;
pragma experimental ABIEncoderV2;

import "./Types.sol";
import "./ISwapAction.sol";
import "./console.sol";

contract TestSwapper is ISwapAction {

    // @dev perform a swap according to the order details. Returns a bool indicating
    // success and a string fail reason.
    function swap(Types.Order calldata order) external override returns (bool, string memory) {
        if(order.orderType == Types.OrderType.EXACT_OUT) {
            return(false, "Simulating script failure");
        }
        console.log("Attempting to execute action");
        order.output.token.transfer(order.trader, order.output.amount);
        return (true, "");
    }
}