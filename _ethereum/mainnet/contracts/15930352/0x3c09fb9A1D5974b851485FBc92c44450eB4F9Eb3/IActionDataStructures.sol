// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity ^0.8.17;


interface IActionDataStructures {
    struct LocalAction {
        address fromTokenAddress;
        address toTokenAddress;
        SwapInfo swapInfo;
        address recipient;
    }

    struct Action {
        uint256 gatewayType;
        uint256 vaultType;
        address sourceTokenAddress;
        SwapInfo sourceSwapInfo;
        uint256 targetChainId;
        address targetTokenAddress;
        SwapInfo[] targetSwapInfoOptions;
        address targetRecipient;
    }

    struct SwapInfo {
        uint256 fromAmount;
        uint256 routerType;
        bytes routerData;
    }

    struct TargetMessage {
        uint256 actionId;
        address sourceSender;
        uint256 vaultType;
        address targetTokenAddress;
        SwapInfo targetSwapInfo;
        address targetRecipient;
    }
}
