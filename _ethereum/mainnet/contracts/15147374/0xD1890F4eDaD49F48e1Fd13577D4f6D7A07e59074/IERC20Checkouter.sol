// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "./ICheckouter.sol";

interface IERC20Checkouter is ICheckouter {
    
    function addTokenCheckouter(address token, TokenInfo memory tokenInfo) external;

    function removeTokenCheckouter(address token) external ;

    function tokenFiatAnchoredAmount(address token, uint256 amount) external view returns (uint256 anchoredAmount);

    function tokenPurchase(address token, address from, uint256 amount, BillingType billingType) external;

    function withdrawToken(address token, address to) external;
}