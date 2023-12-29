// SPDX-License-Identifier: MIT
pragma solidity =0.8.21;

import "./ConveyorRouterV1.sol";

interface IConveyorRouterV1 {
    function swapExactTokenForToken(
        ConveyorRouterV1.TokenToTokenSwapData calldata swapData,
        ConveyorRouterV1.SwapAggregatorMulticall calldata genericMulticall
    ) external payable;

    function swapExactEthForToken(
        ConveyorRouterV1.EthToTokenSwapData calldata swapData,
        ConveyorRouterV1.SwapAggregatorMulticall calldata swapAggregatorMulticall
    ) external payable;

    function swapExactTokenForEth(
        ConveyorRouterV1.TokenToEthSwapData calldata swapData,
        ConveyorRouterV1.SwapAggregatorMulticall calldata swapAggregatorMulticall
    ) external payable;

    function initializeAffiliate(address affiliateAddress) external;
    function initializeReferrer() external payable;

    function upgradeMulticall(bytes memory bytecode, bytes32 salt) external payable returns (address);

    function quoteSwapExactTokenForToken(
        ConveyorRouterV1.TokenToTokenSwapData calldata swapData,
        ConveyorRouterV1.SwapAggregatorMulticall calldata swapAggregatorMulticall
    ) external payable returns (uint256 gasConsumed);

    function quoteSwapExactTokenForEth(
        ConveyorRouterV1.TokenToEthSwapData calldata swapData,
        ConveyorRouterV1.SwapAggregatorMulticall calldata swapAggregatorMulticall
    ) external payable returns (uint256 gasConsumed);

    function quoteSwapExactEthForToken(
        ConveyorRouterV1.EthToTokenSwapData calldata swapData,
        ConveyorRouterV1.SwapAggregatorMulticall calldata swapAggregatorMulticall
    ) external payable returns (uint256 gasConsumed);

    function withdraw() external;

    function CONVEYOR_MULTICALL() external view returns (address);
    function affiliates(uint16) external view returns (address);
    function referrers(uint16) external view returns (address);
}
