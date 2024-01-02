// Copyright 2021-2022, Offchain Labs, Inc.
// For license information, see https://github.com/OffchainLabs/nitro-contracts/blob/main/LICENSE
// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "./GlobalState.sol";
import "./Machine.sol";
import "./ISequencerInbox.sol";
import "./IBridge.sol";
import "./IOutbox.sol";
import "./IInboxBase.sol";
import "./IRollupEventInbox.sol";
import "./IRollupLogic.sol";
import "./IChallengeManager.sol";

struct Config {
    uint64 confirmPeriodBlocks;
    uint64 extraChallengeTimeBlocks;
    address stakeToken;
    uint256 baseStake;
    bytes32 wasmModuleRoot;
    address owner;
    address loserStakeEscrow;
    uint256 chainId;
    string chainConfig;
    uint64 genesisBlockNum;
    ISequencerInbox.MaxTimeVariation sequencerInboxMaxTimeVariation;
}

struct ContractDependencies {
    IBridge bridge;
    ISequencerInbox sequencerInbox;
    IInboxBase inbox;
    IOutbox outbox;
    IRollupEventInbox rollupEventInbox;
    IChallengeManager challengeManager;
    address rollupAdminLogic;
    IRollupUser rollupUserLogic;
    // misc contracts that are useful when interacting with the rollup
    address validatorUtils;
    address validatorWalletCreator;
}
