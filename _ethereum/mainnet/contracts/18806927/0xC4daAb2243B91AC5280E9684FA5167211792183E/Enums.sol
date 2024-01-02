// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

/// enums
enum FeeCurrency {
    Null,
    // L1
    Native,
    // different asset
    Token
}

enum FeeType {
    Null,
    // absolute/onetime
    Default,
    // buy/sell depending on target
    From,
    // buy/sell depending on target
    To
}

enum FeeSyncAction {
    Null,
    // adding a fee
    Add,
    // updating a fee
    Update,
    // removing a fee
    Delete
}

enum FeeDeployState {
    Null,
    // a fee is recently added, updated or removed
    Queued,
    // a fee config is deployed
    Pending,
    // a fee gets receives information about being deployed
    Deployed
}
