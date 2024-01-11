// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "./ICheckouter.sol";

interface IETHCheckouter is ICheckouter {
    function fiatAnchoredAmount(uint256 amount) external view returns (uint256 anchoredAmount);

    function ethPurchase(uint256 amount, BillingType billingType) external payable;

    function withdraw(address to) external;
}