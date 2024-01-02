// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "./Enums.sol";

/// General Fee Config

struct FeeConfig {
    // relative: 10000 = 1% or 100 = 0.01%
    // absolute: 10000 = 1 or 1 = 0.0001
    uint256 fee;
    // Assets are always going to the fee distributor on the home chain. This config is necessary to define which receiver gets this asset.
    // It's purpose can be overwritten by the FeeDistributor. So it will serve as a fallback.
    address receiver;
    // defines the type. It does not have a purpose yet but may have in the future
    // see {Enums->FeeType}
    FeeType ftype;
    // type of how the fees should be handles
    // see {Enums->FeeCurrency}
    FeeCurrency currency;
    // // Deploy state of a fee config
    // // see {Enums->FeeDeployState}
    // FeeDeployState deployState;
}

/// Fee Management

struct AddFeeConfigParams {
    // fee id which can be defined elsewhere but needs to be a bytes32
    bytes32 id;
    // see {struct FeeConfig->fee}
    uint256 fee;
    // see {struct FeeConfig->receiver}
    address receiver;
    // see {struct FeeConfig->ftype}
    FeeType ftype;
    // see {struct FeeConfig->currency}
    FeeCurrency currency;
}

struct UpdateFeeConfigParams {
    // see {struct AddFeeConfigParams->id}
    bytes32 id;
    // see {struct FeeConfig->fee}
    uint256 fee;
    // see {struct FeeConfig->fee}
    address receiver;
}

struct RemoveFeeConfigParams {
    // see {struct AddFeeConfigParams->id}
    bytes32 id;
}

/// Chain Management

struct AddChainParams {
    // chain id
    uint256 chainId;
    // address of the participant, most likely the diamon address of the target chain
    address target;
}
struct RemoveChainParams {
    // chain id
    uint256 chainId;
}

/// Fee & Chain Management

struct AssignFeeConfigToChainParams {
    // fee config id
    bytes32 id;
    // chain id to assign the fee config id to
    uint256 chainId;
}
struct UnassignFeeConfigFromChainParams {
    // fee config id
    bytes32 id;
    // chain id to unassign the fee config id from
    uint256 chainId;
}
struct UnassignFeeConfigFromAllChainsParams {
    // fee config id
    bytes32 id;
}

/// Syncing

struct FeeSyncQueue {
    // fee config id
    bytes32 id;
    // chain id
    uint256 chainId;
    // action to execute on the target chain
    FeeSyncAction action;
}

struct FeeConfigDeployState {
    bytes32 id;
    FeeDeployState state;
}

/// Data Transfer Objects

struct FeeConfigSyncDTO {
    // fee config id
    bytes32 id;
    // fee value
    uint256 fee;
    // address to make conditional charged based on a specific token
    // a contract can decide by itself whether to it or not
    // if defined and used, this fee should be restricted and charged onto a specific token
    address target;
    // desired action to execute on the target chain
    FeeSyncAction action;
}
struct FeeConfigSyncHomeFees {
    // fee config id
    bytes32 id;
    // amount of the collected fees of this if
    uint256 amount;
}
struct FeeConfigSyncHomeDTO {
    // total amount of collected fees
    uint256 totalFees;
    // address of the bounty receiver on the home chain
    address bountyReceiver;
    // containing fee information that will moved to the home chain
    FeeConfigSyncHomeFees[] fees;
}

struct CelerRelayerData {
    // bytes32 hash which defined the action that should be taken
    bytes32 what;
    // address of the contract which what is being executed to
    address target;
    // encoded message of the desired scope
    bytes message;
}

/// Fee Store

struct FeeStoreConfig {
    // fee config id
    bytes32 id;
    // fee
    uint256 fee;
    // address of the contract which what is being executed to
    address target;
    // flag for being markes as deleted
    bool deleted;
}

/// Fee Distributor

struct AddReceiverParams {
    // public name for the receiver
    // can be "Staking", "Liquidity Backing" or whatever
    string name;
    // potion of share in points. Points will be summarized in the distribution to calculate the relative share
    uint64 points;
    // address of the contract/account that receives the share
    address account;
    // swap path in case a share receiver expects another token then the intermediate token of the bridge
    address[] swapPath;
}
