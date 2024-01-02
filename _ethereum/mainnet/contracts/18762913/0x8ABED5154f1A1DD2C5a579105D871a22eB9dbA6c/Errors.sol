// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

library Errors {
    error InvalidAmount();
    error AmountNotAvailableInEpoch(uint16 epoch);
    error InvalidEpoch();
    error InvalidRegistration();
    error SentinelNotReleasable(address sentinel);
    error NothingToClaim();
    error LendPeriodTooBig();
    error InvalidDuration();
    error UnfinishedStakingPeriod();
    error NothingAtStake();
    error MaxTotalSupplyExceeded();
    error NotPartecipatedInGovernanceAtEpoch(uint16 epoch);
    error GuardianAlreadyRegistered(address guardian);
    error InvalidNumberOfEpochs(uint16 numberOfEpochs);
    error NotResumable();
    error InvalidSignatureNonce(uint256 signatureNonce, uint256 expectedSignatureNonce);
    error ActorAlreadySlashed(uint256 lastSlashTimestamp, uint256 slashTimestamp);
    error ActorAlreadyResumed(uint256 lastResumeTimestamp, uint256 slashTimestamp);
}
