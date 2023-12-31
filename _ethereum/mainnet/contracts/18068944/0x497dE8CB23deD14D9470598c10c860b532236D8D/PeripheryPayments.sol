// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "./IERC20Upgradeable.sol";
import "./TransferHelper.sol";
import "./IWETH9.sol";
import "./PeripheryState.sol";
import "./Weth9Unwrapper.sol";

abstract contract PeripheryPayments is PeripheryState {
    receive() external payable {
        require(msg.sender == WETH9, "Not WETH9");
    }

    function wrapETH(uint256 value) external payable {
        IWETH9(WETH9).deposit{value: value}();
    }

    function pull(address token, uint256 value) external payable {
        TransferHelper.safeTransferFrom(token, msg.sender, address(this), value);
    }

    // internal methods
    /// @param token The token to pay
    /// @param payer The entity that must pay
    /// @param recipient The entity that will receive payment
    /// @param value The amount to pay
    function pay(address token, address payer, address recipient, uint256 value) internal {
        if (token == WETH9 && address(this).balance >= value) {
            //require(address(this).balance >= value, "Insufficient native token value");
            // pay with WETH9
            IWETH9(WETH9).deposit{value: value}(); // wrap only what is needed to pay
            IWETH9(WETH9).transfer(recipient, value);
        } else if (payer == address(this)) {
            // pay with tokens already in the contract (for the exact input multihop case)
            TransferHelper.safeTransfer(token, recipient, value);
        } else {
            // pull payment
            TransferHelper.safeTransferFrom(token, payer, recipient, value);
        }
    }
}
