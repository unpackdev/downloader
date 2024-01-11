// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./IERC20.sol";

// INoone 
interface INoone is IERC20 {

    struct Fees {
        uint256 impact;
        uint256 buyFee;
        uint256 sellFee;
        uint256 transferFee;
    }

    function currentFees() external view returns (Fees memory);

    struct LiquidityETHParams {
        address pair;
        uint256 amountTokenOrLP;
        uint256 amountTokenMin;
        uint256 amountETHMin;
        address to;
        uint256 deadline;
    }

    event LiquidityAddedETH(
        address pair,
        uint256 amountToken,
        uint256 amountETH,
        uint256 liquidity
    );

    function addLiquidityETH(LiquidityETHParams calldata params)
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function taxedPair(address pair) external view returns (bool);
} 