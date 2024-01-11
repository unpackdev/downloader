// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

interface IBentCVXConverter {
    function convertToBentCVX(
        address inToken,
        uint256 amount,
        uint256 amountOutMin
    ) external payable;
}
