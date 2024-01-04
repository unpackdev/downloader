// SPDX-License-Identifier: MIT

pragma solidity ^0.7.4;

import "./IUniswapV2Router02.sol";
import "./IGovernable.sol";

interface IDPexRouter is IUniswapV2Router02, IGovernable {
    function feeAggregator() external returns (address);

    function setfeeAggregator(address aggregator) external;
    function swapAggregatorToken(
        uint amountIn,
        address[] calldata path,
        address to
    ) external returns (uint256);
}