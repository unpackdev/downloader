// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.7.6;

import "./IERC20.sol";

interface ICHIDepositCallBack {
    function CHIDepositCallback(
        IERC20 token0,
        uint256 amount0,
        IERC20 token1,
        uint256 amount1,
        address recipient
    ) external;
}
