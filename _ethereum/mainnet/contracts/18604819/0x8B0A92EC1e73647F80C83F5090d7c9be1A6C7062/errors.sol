//SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import "./utils.sol";

// Multisig
    error StakingController_WrongArgumentsCount();
    error StakingController_WrongInputAddress();
    error StakingController_WrongInputUint();

// Lootbox
    error Lootbox_WrongInputAddress();
    error Lootbox_WrongInputUint();
    error Lootbox_WrongArgumentsCount();
    error Lootbox_WrongCurrency();
    error Lootbox_NoSupply(RarityLootbox);

// NFT
    error NFT_WrongTokenId(uint256 _id);
    error NFT_WrongTypeId(uint256 _id);
    error NFT_WrongArgumentsCount();
    error NFT_WrongInputAddress();
    error NFT_WrongInputUint();
    error NFT_WrongStakingAddress();
    error NFT_NoSupply(string _distribution, uint8 _typeId);
    error NFT_WrongCurrency();
    error NFT_WrongPaymentAmount();
    error NFT_NoAccessToCall();
    error NFT_NoVestingAmount();
    error NFT_NoVestingEnabled();

// Quests
    error Quests_InvalidReward();
    error Quests_RewardNotAvailable();
    error Quests_NotEnoughUniqueNFT(uint32 _id);
    error Quests_NotEnoughTotalNFT(uint32 _id);
    error Quests_NotEnoughSpendXBTC(uint256 _spend);
    error Quests_NotEnoughLootboxesOpened(uint32 _opened);
    error Quests_NotEnoughRewardsAccumulated(uint8 _rewards);