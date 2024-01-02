// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

library ConfiguratorInputTypes {
    struct InitReserveInput {
        address yTokenImpl;
        address variableDebtTokenImpl;
        uint8 underlyingAssetDecimals;
        address interestRateStrategyAddress;
        address underlyingAsset;
        address treasury;
        address incentivesController;
        string yTokenName;
        string yTokenSymbol;
        string variableDebtTokenName;
        string variableDebtTokenSymbol;
        bytes params;
    }

    struct InitERC1155ReserveInput {
        address nTokenImpl;
        address underlyingAsset;
        address treasury;
        address configurationProvider;
        bytes params;
    }

    struct UpdateYTokenInput {
        address asset;
        address treasury;
        address incentivesController;
        string name;
        string symbol;
        address implementation;
        bytes params;
    }

    struct UpdateNTokenInput {
        address asset;
        address treasury;
        address implementation;
        bytes params;
    }

    struct UpdateDebtTokenInput {
        address asset;
        address incentivesController;
        string name;
        string symbol;
        address implementation;
        bytes params;
    }
}
