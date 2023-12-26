// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.7;

// @title Router token swapping functionality
// @notice Functions for swapping tokens via WOWMAX
interface IWowmaxRouter {
    struct Swap {
        // target token address
        address to;
        // part of owned tokens to be swapped
        uint256 part;
        // contract address that performs the swap
        address addr;
        // contract DEX family
        bytes32 family;
        // additional data that is required for a specific DEX protocol
        bytes data;
    }

    struct ExchangeRoute {
        // source token address
        address from;
        // total parts of owned token
        uint256 parts;
        // array of swaps for a specified token
        Swap[] swaps;
    }

    struct ExchangeRequest {
        // source token address
        address from;
        // source token amount to swap
        uint256 amountIn;
        // target token addresses
        address[] to;
        // exchange routes
        ExchangeRoute[] exchangeRoutes;
        // slippage tolerance for each target token
        uint256[] slippage;
        // expected amount for each target token
        uint256[] amountOutExpected;
    }

    event SwapExecuted(
        address indexed account,
        address indexed from,
        uint256 amountIn,
        address[] to,
        uint256[] amountOut
    );

    // @notice Executes a token swap
    // @param request - swap request
    // @return amountsOut - array of amounts that were received for each target token
    // @dev if from token is address(0) and amountIn is 0,
    // then chain native token is used as a source token, and value is used as amountIn
    function swap(ExchangeRequest calldata request) external payable returns (uint256[] memory amountsOut);
}
