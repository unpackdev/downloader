// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

error NotDaoOwner();

error NotCanvasOwner();

error NotRole(bytes32 role, address account);

error NotCaller(address caller);

error RoyaltyFeeRatioOutOfRange();

error UnauthorizedToExchangeRoyaltyTokenToETH();

error Blacklisted();

error NotInWhitelist();

error InvalidETHRatio();

error ExceedMaxMintableRound();

error ExceedDaoMintableRound();

error NewMintableRoundsFewerThanRewardIssuedRounds();

error InvalidRound();

error ExceedMinterMaxMintAmount();

error NftExceedMaxAmount();

error ZeroFloorPriceCannotUseLinearPriceVariation();

error D4APaused();

error Paused(bytes32 id);

error UriAlreadyExist(string uri);

error UriNotExist(string uri);

error DaoIndexTooLarge();

error DaoIndexAlreadyExist();

error InvalidSignature();

error DaoNotExist();

error CanvasNotExist();

error PriceTooLow();

error NotEnoughEther();

error D4AProjectAlreadyExist(bytes32 daoId);

error D4ACanvasAlreadyExist(bytes32 canvasId);

error StartRoundAlreadyPassed();

error DaoNotStarted();

error NotOperationRole();

error UnableToUnlock();

error BasicDaoLocked();

error NotCanvasIdOfSpecialTokenUri();

error NotBasicDaoNftFlatPrice();

error SupplyOutOfRange();

error ExceedDailyMintCap();