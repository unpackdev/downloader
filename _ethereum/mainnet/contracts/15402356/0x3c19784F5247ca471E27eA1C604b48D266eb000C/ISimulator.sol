// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "./IAggregator.sol";


interface ISimulator {

    struct TradeDetails {
        uint256 marketId;
        uint256 value;
        bytes tradeData;
    }

    function batchBuyWithETHSimulate(TradeDetails[] calldata tradeDetails) external payable;

    function batchBuyWithERC20sSimulate(
        IAggregator.ERC20Pair[] calldata erc20Pairs,
        TradeDetails[] calldata tradeDetails,
        address[] calldata dustTokens
    ) external payable;
}
