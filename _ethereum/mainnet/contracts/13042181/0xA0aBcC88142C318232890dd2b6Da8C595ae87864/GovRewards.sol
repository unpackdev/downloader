// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.7.6;

import "./SafeMath.sol";
import "./IERC20.sol";
import "./IReign.sol";
import "./LibRewardsDistribution.sol";

contract GovRewards {
    // lib
    using SafeMath for uint256;
    using SafeMath for uint128;

    // state variables

    address private _rewardsVault;
    // contracts
    IERC20 private _reignToken;
    IReign private _reign;

    mapping(uint128 => uint256) private _sizeAtEpoch;
    mapping(uint128 => uint256) private _epochInitTime;
    mapping(address => uint128) private lastEpochIdHarvested;

    uint256 public epochDuration; // init from reignDiamond contract
    uint256 public epochStart; // init from reignDiamond contract
    uint128 public lastInitializedEpoch;

    // events
    event MassHarvest(
        address indexed user,
        uint256 epochsHarvested,
        uint256 totalValue
    );
    event Harvest(
        address indexed user,
        uint128 indexed epochId,
        uint256 amount
    );
    event InitEpoch(address indexed caller, uint128 indexed epochId);

    // constructor
    constructor(
        address reignTokenAddress,
        address reign,
        address rewardsVault
    ) {
        _reignToken = IERC20(reignTokenAddress);
        _reign = IReign(reign);
        _rewardsVault = rewardsVault;
    }

    //before this the epoch start date is 0
    function initialize() public {
        require(epochStart == 0, "Can only be initialized once");
        epochDuration = _reign.getEpochDuration();
        epochStart = _reign.getEpoch1Start();
    }

    // public method to harvest all the unharvested epochs until current epoch - 1
    function massHarvest() external returns (uint256) {
        uint256 totalDistributedValue;
        uint256 epochId = _getEpochId().sub(1); // fails in epoch 0

        for (
            uint128 i = lastEpochIdHarvested[msg.sender] + 1;
            i <= epochId;
            i++
        ) {
            // i = epochId
            // compute distributed Value and do one single transfer at the end
            uint256 userRewards = _harvest(i);
            totalDistributedValue = totalDistributedValue.add(userRewards);
        }

        emit MassHarvest(
            msg.sender,
            epochId - lastEpochIdHarvested[msg.sender],
            totalDistributedValue
        );

        _reignToken.transferFrom(
            _rewardsVault,
            msg.sender,
            totalDistributedValue
        );

        return totalDistributedValue;
    }

    //gets the rewards for a single epoch
    function harvest(uint128 epochId) external returns (uint256) {
        // checks for requested epoch
        require(_getEpochId() > epochId, "This epoch is in the future");
        require(
            lastEpochIdHarvested[msg.sender].add(1) == epochId,
            "Harvest in order"
        );
        // get amount to transfer and transfer it
        uint256 userReward = _harvest(epochId);
        if (userReward > 0) {
            _reignToken.transferFrom(_rewardsVault, msg.sender, userReward);
        }

        emit Harvest(msg.sender, epochId, userReward);
        return userReward;
    }

    /*
     * internal methods
     */

    function _harvest(uint128 epochId) internal returns (uint256) {
        // try to initialize an epoch
        if (lastInitializedEpoch < epochId) {
            _initEpoch(epochId);
        }
        // Set user state for last harvested
        lastEpochIdHarvested[msg.sender] = epochId;

        // exit if there is no stake on the epoch
        if (_sizeAtEpoch[epochId] == 0) {
            return 0;
        }

        // compute and return user total reward.
        // For optimization reasons the transfer have been moved to an upper layer
        // (i.e. massHarvest needs to do a single transfer)
        uint256 epochRewards = getRewardsForEpoch();
        uint256 boostMultiplier = getBoost(msg.sender, epochId);
        uint256 userEpochRewards = epochRewards
            .mul(_getUserBalancePerEpoch(msg.sender, epochId))
            .mul(boostMultiplier)
            .div(_sizeAtEpoch[epochId])
            .div(1 * 10**18); // apply boost multiplier

        return userEpochRewards;
    }

    function _initEpoch(uint128 epochId) internal {
        require(
            lastInitializedEpoch.add(1) == epochId,
            "Epoch can be init only in order"
        );
        lastInitializedEpoch = epochId;
        _epochInitTime[epochId] = block.timestamp;
        // call the staking smart contract to init the epoch
        _sizeAtEpoch[epochId] = _getPoolSizeAtTs(block.timestamp);

        emit InitEpoch(msg.sender, epochId);
    }

    /*
     *   VIEWS
     */

    //returns the current epoch
    function getCurrentEpoch() external view returns (uint256) {
        return _getEpochId();
    }

    // gets the total amount of rewards accrued to a pool during an epoch
    function getRewardsForEpoch() public view returns (uint256) {
        return LibRewardsDistribution.rewardsPerEpochStaking(epochStart);
    }

    // calls to the staking smart contract to retrieve user balance for an epoch
    function getEpochStake(address userAddress, uint128 epochId)
        external
        view
        returns (uint256)
    {
        return _getUserBalancePerEpoch(userAddress, epochId);
    }

    function userLastEpochIdHarvested() external view returns (uint256) {
        return lastEpochIdHarvested[msg.sender];
    }

    // calls to the staking smart contract to retrieve the epoch total poolLP size
    function getPoolSizeAtTs(uint256 timestamp)
        external
        view
        returns (uint256)
    {
        return _getPoolSizeAtTs(timestamp);
    }

    // calls to the staking smart contract to retrieve the epoch total poolLP size
    function getPoolSize(uint128 epochId) external view returns (uint256) {
        return _sizeAtEpoch[epochId];
    }

    // checks if the user has voted that epoch and returns accordingly
    function getBoost(address user, uint128 epoch)
        public
        view
        returns (uint256)
    {
        return _reign.stakingBoostAtEpoch(user, epoch);
    }

    // get how many rewards the user gets for an epoch
    function getUserRewardsForEpoch(uint128 epochId)
        public
        view
        returns (uint256)
    {
        // exit if there is no stake on the epoch
        if (_sizeAtEpoch[epochId] == 0) {
            return 0;
        }

        uint256 epochRewards = getRewardsForEpoch();
        uint256 boostMultiplier = getBoost(msg.sender, epochId);
        uint256 userEpochRewards = epochRewards
            .mul(_getUserBalancePerEpoch(msg.sender, epochId))
            .mul(boostMultiplier)
            .div(_sizeAtEpoch[epochId])
            .div(1 * 10**18); // apply boost multiplier

        return userEpochRewards;
    }

    function _getPoolSizeAtTs(uint256 timestamp)
        internal
        view
        returns (uint256)
    {
        // retrieve unilp token balance
        return _reign.reignStakedAtTs(timestamp);
    }

    function _getUserBalancePerEpoch(address userAddress, uint128 epochId)
        internal
        view
        returns (uint256)
    {
        // retrieve unilp token balance per user per epoch
        return _reign.getEpochUserBalance(userAddress, epochId);
    }

    // compute epoch id from blocktimestamp and
    function _getEpochId() internal view returns (uint128 epochId) {
        if (block.timestamp < epochStart) {
            return 0;
        }
        epochId = uint128(
            block.timestamp.sub(epochStart).div(epochDuration).add(1)
        );
    }
}
