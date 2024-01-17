// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity ^0.8.17;


interface ISettings {
    struct LocalSettings {
        address router;
        uint256 systemFee;
        address feeCollectorLocal;
        bool isWhitelist;
    }

    struct SourceSettings {
        address gateway;
        bool useGatewayFallback;
        address router;
        address vault;
        uint256 sourceVaultDecimals;
        uint256 targetVaultDecimals;
        uint256 systemFee;
        address feeCollector;
        bool isWhitelist;
        uint256 swapAmountMin;
        uint256 swapAmountMax;
    }

    struct TargetSettings {
        address router;
        address vault;
    }

    struct FallbackSettings {
        uint256 sourceVaultDecimals;
        uint256 targetVaultDecimals;
    }

    struct VariableTokenClaimSettings {
        address vault;
        uint256 fallbackFee;
        address feeCollectorForVariableToken;
    }

    struct MessageFeeEstimateSettings {
        address gateway;
    }

    struct LocalAmountCalculationSettings {
        uint256 systemFee;
        bool isWhitelist;
    }

    struct VaultAmountCalculationSettings {
        uint256 fromDecimals;
        uint256 toDecimals;
        uint256 systemFee;
        bool isWhitelist;
    }
}
