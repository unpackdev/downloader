// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

error Unauthorized();

error InvalidArrayLength();

error InvalidMerkleProof();

error ZeroAddress();

error ZeroAmount();

error ZeroPrice();

error ContractAddressExpected(address contract_);

error InsufficientCAFE();

error InsufficientBalance();

error UnknownTrack();

error TokenLocked();

error TokenNotOwn();

error UnknownToken();

error TrackExpired();

error TokenNotLocked();

error NoTokensGiven();

error TokenOutOfRange();

error AmountExceedsLocked();

error StakingVolumeExceeded();

error StakingTrackNotAssigned();

error StakingLockViolation(uint256 tokenId);

error NotInStakingPeriod();

error TrackPaused(uint256 trackId);

error ContractPaused();

error VSExistsForAccount(address account);

error VSInvalidCliff();

error VSInvalidAllocation();

error VSMissing(address account);

error VSCliffNotReached();

error VSInvalidPeriodSpec();

error VSCliffNERelease();

error NothingVested();

error OnceOnly();

error MintingExceedsSupply(uint256 supply);

error InvalidStage();

error DuplicateClaim();

error DuplicateTokenSelection();
error CantCreateZeroTokens();
error TokenCollectionMismatch();
error CollectionNotFound();
error InvalidETHAmount();
error TokenMaxSupplyReached();
error InOpenSale();
error NotInOpenSale();
error InvalidEditionsSpec();
error ZeroEditionsSpecified();

error InvalidTrackTiming();
error InvalidTrackStart();