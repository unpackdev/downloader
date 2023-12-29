// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./SafeERC20.sol";

interface IPresale {

    function TOKEN() external view returns (IERC20);
    function VESTING_TIME_WL() external view returns (uint);
    function VESTING_TIME() external view returns (uint);
    function ROOT() external view returns (bytes32);
    function totalOut() external view returns (uint);
    function totalTokens() external view returns (uint);
    function state() external view returns (uint);
    function START_CLAIM_TIME() external view returns (uint);
    function MIN_AMOUNT_IN() external view returns (uint);
    function MAX_AMOUNT_IN() external view returns (uint);
    function MAX_TOTAL_OUT() external view returns (uint);
    function MAX_SALE() external view returns (uint);
    function actualSale() external view returns (uint);
    function price() external view returns (uint);
    function users(address) external view returns (uint, uint, uint, uint);
}
