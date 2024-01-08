// SPDX-License-Identifier: Apache-2.0

pragma solidity >=0.8.0;

interface ILiquidityMining {

    event Stake(address indexed account, uint amount, uint8 indexed rangeStartIndex, uint8 indexed rangeEndIndex);
    event UnstakeRange(address indexed account, uint unstakedAmount, uint8 indexed rangeStartIndex, uint8 indexed rangeEndIndex);
    event Unstake(address indexed account, uint amount, uint rewardInPHTR, uint exitFeeInPHTR);
    event SetEmission(address indexed account, address indexed emission);

    struct Tier {
        /// % booster for tier qualification
        uint16 boosterInBP;
        /// % of totalSupply, required to qualify for this tier
        uint16 thresholdInBP;
    }

    struct VestingRange {
        uint8 startIndex;
        uint8 endIndex;
    }

    struct AccountDetails {
        uint128 vestedBoostedStake; // 128
        uint128 totalStake; // 128 + 128 = 256
        address referrer; // 160
        uint16 tierBoosterInBP; // 160 + 16 = 176
        uint16 referralBoosterInBP; // 160 + 16 + 16 = 192
        uint lastAccumulatedPHTRInTotalBoostedStakeInQ;
        uint rewardInPHTR;
    }

    struct StakeWithPermitParams {
        address referrer;
        uint amount;
        uint8 minTierIndex; 
        VestingRange vestingRange;
        uint deadline;
        bool approveMax;
        uint8 v; 
        bytes32 r; 
        bytes32 s;
    }

    function MIN_VESTING_TIME_IN_SECONDS() external view returns (uint64);
    function PHTR() external view returns (address);
    function LP() external view returns (address);
    function emission() external view returns (address);
    function minTierReferrerBooster() external view returns (uint16);
    function totalBoostedStake() external view returns (uint);
    function tierBoosterInBP(uint _amount, uint8 _minTierIndex) external view returns (uint16);
    function programDetails() 
        external 
        view 
        returns (
            uint _totalBoostedStake,
            uint _accumulatedPHTRInTotalSharesInQ,
            Tier[] memory _tiers,
            uint[] memory _vestingDatesInSeconds, 
            uint[] memory _vestingTimeBoostersInBP
        );
     function accountDetails(address _account) 
        external 
        view 
        returns (
            uint _boostedStake,
            uint _totalReward,
            AccountDetails memory _accountDetails
        );

    function vestingOptionStake(address _account, VestingRange calldata _vestingRange) external view returns (uint);

    function stake(
        address _referrer, 
        uint _amount, 
        uint8 _minTierIndex, 
        VestingRange calldata _vestingRange
    ) external;

    function stakeWithPermit(StakeWithPermitParams calldata _params) external;

    function unstake(VestingRange[] calldata _vestingRanges, uint _amount) external;
}