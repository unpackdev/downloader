// SPDX-License-Identifier: Apache-2.0

pragma solidity =0.8.9;

import "./IMellowMultiVaultRouter.sol";

contract MellowMultiVaultRouterStorageV1 {
    mapping(uint256 => IMellowMultiVaultRouter.BatchedDeposits)
        internal _batchedDeposits;
    IERC20Minimal internal _token;
    IWETH internal _weth;

    IERC20RootVault[] internal _vaults;
    mapping(uint256 => bool) internal _isVaultCompleted;

    mapping(address => mapping(uint256 => uint256)) _managedLpTokens;

    // -------------------  AUTO-ROLLOVERS  -------------------

    // weights used on auto-rollover
    uint256[] _autoRolloverWeights;

    // list of vault indices for which auto-rollover was triggered
    uint256[] _autoRolledOverVaults;
    // given a vault index, returns true if auto-rollover was triggered
    // for that vault; returns false otherwise
    mapping(uint256 => bool) _isVaultAutoRolledOver;

    // given a vault index, returns the number of pending batched deposits
    // that resulted from its auto-rollover trigger.
    mapping(uint256 => uint256) _pendingAutoRolloverDeposits;
    // given two vault indices A and B, returns how many LP Tokens in B
    // were obtained by auto-rolling over 1 LP Token in A (in WAD)
    mapping(uint256 => mapping(uint256 => uint256))
        public _autoRolloverExchangeRatesWad;

    // maps each toVault (i.e., vault that was auto-rolled over into)
    // to a FIFO queue containing information about all auto-rollovers
    // that auto-rolled over into toVault
    mapping(uint256 => IMellowMultiVaultRouter.BatchedAutoRollovers) _batchedAutoRollovers;

    // given an user, returns true if user is registered for auto-rollover;
    // returns false otherwise
    mapping(address => bool) _isRegisteredForAutoRollover;
    // stores the list of lp tokens that were registered for auto-rollover
    // for each given user (values might be stale and must be propagated)
    mapping(address => mapping(uint256 => uint256)) _autoRolloverLpTokens;

    mapping(uint256 => uint256) _vaultMaturity;

    mapping(uint256 => bool) internal _isVaultPaused;

    // fee paid for each deposit into router
    uint256 internal _fee;

    // total fees accumulated to be transferred to batch submitters
    uint256 internal _totalFees;

    // total number of deposits to be submitted to root vaults
    uint256 internal _vaultDepositsCount;
}

contract MellowMultiVaultRouterStorage is MellowMultiVaultRouterStorageV1 {
    // Reserve some storage for use in future versions, without creating conflicts
    // with other inheritted contracts
    uint256[56] private __gap; // total storage = 100 slots, including structs
}
