// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.18;

import "./CoreSwap.sol";

interface ICoreSwapV1 {
    event SwapHandlerUpdate(address actor, address swapHandler, bool isEnabled);
    event SwapTokenUpdate(address actor, address swapToken, bool isEnabled);
    event SwapOutputTokenUpdate(address actor, address swapOutputToken, bool isEnabled);
    event SwapHandled(
        address[] swapTokens,
        uint256[] swapAmounts,
        address outputToken,
        uint256 outputAmount,
        uint256 feeAmount
    );

    function enableSwapTokens(address[] memory swapTokens) external;

    function disableSwapTokens(address[] memory swapTokens) external;

    function enableSwapOutputTokens(address[] memory swapOutputTokens) external;

    function disableSwapOutputTokens(address[] memory swapOutputTokens) external;

    function enableSwapHandlers(address[] memory swapHandlers) external;

    function disableSwapHandlers(address[] memory swapHandlers) external;

    function swap(
        SwapPayload[] memory payloads,
        address outputToken,
        uint256 amountOutMin,
        uint256 feePct
    ) external returns (uint256 outputAmount);
}
