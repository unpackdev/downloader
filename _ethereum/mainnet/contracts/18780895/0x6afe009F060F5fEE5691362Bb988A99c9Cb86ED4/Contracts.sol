// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

library Contracts {
    bytes32 internal constant BEACON_PROXY_CONTROLLER = "BeaconProxyController";
    bytes32 internal constant CURRENCY_CONTROLLER = "CurrencyController";
    bytes32 internal constant GENESIS_VALUE_VAULT = "GenesisValueVault";
    bytes32 internal constant LENDING_MARKET_CONTROLLER = "LendingMarketController";
    bytes32 internal constant RESERVE_FUND = "ReserveFund";
    bytes32 internal constant TOKEN_VAULT = "TokenVault";
}

library BeaconContracts {
    bytes32 internal constant FUTURE_VALUE_VAULT = "FutureValueVault";
    bytes32 internal constant LENDING_MARKET = "LendingMarket";
}
