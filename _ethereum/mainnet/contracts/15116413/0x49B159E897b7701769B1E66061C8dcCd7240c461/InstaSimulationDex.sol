//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.6;

import "./SafeERC20.sol";
import "./IERC20.sol";

contract InstaSimulationDex {
    using SafeERC20 for IERC20;

    address internal constant nativeToken =
        0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    receive() external payable {}

    function swap(
        address sellToken,
        address buyToken,
        uint256 sellAmount,
        uint256 buyAmount
    ) external payable {
        if (sellToken != nativeToken)
            IERC20(sellToken).safeTransferFrom(
                msg.sender,
                address(this),
                sellAmount
            );

        if (buyToken != nativeToken)
            IERC20(buyToken).safeTransfer(msg.sender, buyAmount);
        else {
            bool success;
            (success, ) = address(msg.sender).call{value: buyAmount}("");
            require(success, "ETH transfer failed");
        }
    }
}
