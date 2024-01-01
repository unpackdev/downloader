// SPDX-License-Identifier: LZBL-1.1
// Copyright 2023 LayerZero Labs Ltd.
// You may obtain a copy of the License at
// https://github.com/LayerZero-Labs/license/blob/main/LICENSE-LZBL-1.1

pragma solidity ^0.8.0;

// lp contract for converting other stable coins to STBT
interface IToSTBTLp {
    function getSupportedTokens() external view returns (address[] memory tokens);

    function swapToSTBT(
        address _fromToken,
        uint _fromTokenAmount,
        uint _minStbtOut
    ) external returns (uint requestedOut, uint rewardOut);

    function getSwapToSTBTAmountOut(
        address _fromToken,
        uint _fromTokenAmount
    ) external view returns (uint requestedOut, uint rewardOut);
}
