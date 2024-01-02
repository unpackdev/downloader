// SPDX-License-Identifier: ISC
pragma solidity ^0.8.0;

import "./IERC20.sol";

interface IAdapter {
    struct Route {
        uint256 index; 
        address targetExchange;
        bytes payload;
    }

    function swap(
        address fromToken,
        address toToken,
        uint256 fromAmount,
        Route calldata route
    ) external payable;

    function quote(
        address fromToken,
        address toToken,
        uint256 fromAmount,
        Route calldata route
    ) external returns(uint256);
}
