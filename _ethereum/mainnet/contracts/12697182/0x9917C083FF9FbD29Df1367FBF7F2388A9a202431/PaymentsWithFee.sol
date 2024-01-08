// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import "./IERC20Extended.sol";
import "./IPaymentsWithFee.sol";
import "./IWETH.sol";
import "./TransferHelper.sol";
import "./Payments.sol";

abstract contract PaymentsWithFee is Payments, IPaymentsWithFee {
    /// @inheritdoc IPaymentsWithFee
    function unwrapWETHWithFee(
        uint256 amountMinimum,
        address recipient,
        uint256 feeBips,
        address feeRecipient
    ) public payable override {
        require(feeBips > 0 && feeBips <= 100);

        uint256 balanceWETH = IWETH(WETH).balanceOf(address(this));
        require(balanceWETH >= amountMinimum, 'Insufficient WETH');

        if (balanceWETH > 0) {
            IWETH(WETH).withdraw(balanceWETH);
            uint256 feeAmount = (balanceWETH * feeBips) / 10_000;
            if (feeAmount > 0) TransferHelper.safeTransferETH(feeRecipient, feeAmount);
            TransferHelper.safeTransferETH(recipient, balanceWETH - feeAmount);
        }
    }

    /// @inheritdoc IPaymentsWithFee
    function sweepTokenWithFee(
        address token,
        uint256 amountMinimum,
        address recipient,
        uint256 feeBips,
        address feeRecipient
    ) public payable override {
        require(feeBips > 0 && feeBips <= 100);

        uint256 balanceToken = IERC20Extended(token).balanceOf(address(this));
        require(balanceToken >= amountMinimum, 'Insufficient token');

        if (balanceToken > 0) {
            uint256 feeAmount = (balanceToken * feeBips) / 10_000;
            if (feeAmount > 0) TransferHelper.safeTransfer(token, feeRecipient, feeAmount);
            TransferHelper.safeTransfer(token, recipient, balanceToken - feeAmount);
        }
    }
}
