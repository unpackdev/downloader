// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "./IERC20.sol";

struct SwapDescription {
    IERC20 fromToken;
    IERC20 toToken;
    address receiver;
    uint256 amount;
    uint256 minReturnAmount;
}

struct ToChainDescription {
    uint32 toChainId;
    IERC20 toChainToken;
    uint256 expectedToChainTokenAmount;
    uint32 slippage;
}

// interface for xy.finance swap
interface ISwap {
    function swap(
        address aggregatorAdaptor,
        SwapDescription memory swapDesc,
        bytes memory aggregatorData,
        ToChainDescription calldata toChainDesc
    ) external payable;

    function getTokenBalance(IERC20 _token, address _account) external returns (uint256);
}