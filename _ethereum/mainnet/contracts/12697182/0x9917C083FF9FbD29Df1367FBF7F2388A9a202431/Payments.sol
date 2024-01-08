// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import "./IERC20Extended.sol";
import "./IPayments.sol";
import "./IWETH.sol";
import "./TransferHelper.sol";
import "./ArchRouterImmutableState.sol";

abstract contract Payments is IPayments, ArchRouterImmutableState {
    receive() external payable {
        require(msg.sender == WETH, 'Not WETH');
    }

    /// @inheritdoc IPayments
    function unwrapWETH(uint256 amountMinimum, address recipient) external payable override {
        uint256 balanceWETH = withdrawWETH(amountMinimum);
        TransferHelper.safeTransferETH(recipient, balanceWETH);
    }

    /// @inheritdoc IPayments
    function unwrapWETHAndTip(uint256 tipAmount, uint256 amountMinimum, address recipient) external payable override {
        uint256 balanceWETH = withdrawWETH(amountMinimum);
        tip(tipAmount);
        if(balanceWETH > tipAmount) {
            TransferHelper.safeTransferETH(recipient, balanceWETH - tipAmount);
        }
    }

    /// @inheritdoc IPayments
    function tip(uint256 tipAmount) public payable override {
        TransferHelper.safeTransferETH(block.coinbase, tipAmount);
    }

    /// @inheritdoc IPayments
    function sweepToken(
        address token,
        uint256 amountMinimum,
        address recipient
    ) external payable override {
        uint256 balanceToken = IERC20Extended(token).balanceOf(address(this));
        require(balanceToken >= amountMinimum, 'Insufficient token');

        if (balanceToken > 0) {
            TransferHelper.safeTransfer(token, recipient, balanceToken);
        }
    }

    /// @inheritdoc IPayments
    function refundETH() external payable override {
        if (address(this).balance > 0) TransferHelper.safeTransferETH(msg.sender, address(this).balance);
    }

    /// @param amountMinimum Min amount of WETH to withdraw
    function withdrawWETH(uint256 amountMinimum) public returns(uint256 balanceWETH){
        balanceWETH = IWETH(WETH).balanceOf(address(this));
        require(balanceWETH >= amountMinimum && balanceWETH > 0, 'Insufficient WETH');
        IWETH(WETH).withdraw(balanceWETH);
    }

    /// @param token The token to pay
    /// @param payer The entity that must pay
    /// @param recipient The entity that will receive payment
    /// @param value The amount to pay
    function pay(
        address token,
        address payer,
        address recipient,
        uint256 value
    ) internal {
        if (token == WETH && address(this).balance >= value) {
            // pay with WETH
            IWETH(WETH).deposit{value: value}(); // wrap only what is needed to pay
            IWETH(WETH).transfer(recipient, value);
        } else if (payer == address(this)) {
            // pay with tokens already in the contract (for the exact input multihop case)
            TransferHelper.safeTransfer(token, recipient, value);
        } else {
            // pull payment
            TransferHelper.safeTransferFrom(token, payer, recipient, value);
        }
    }
}
