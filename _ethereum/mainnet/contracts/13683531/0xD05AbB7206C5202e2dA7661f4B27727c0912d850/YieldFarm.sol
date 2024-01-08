// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.10;

import "./IERC20.sol";
import "./IERC20Metadata.sol";
import "./SafeERC20.sol";
import "./IStaking.sol";

contract YieldFarm {
    using SafeERC20 for IERC20;

    struct TokenDetails {
        address addr;
        uint8 decimals;
    }

    TokenDetails[] public poolTokens;
    uint8 maxDecimals;

    IERC20 public rewardToken;

    address public communityVault;
    IStaking public staking;

    uint256 public totalDistributedAmount;
    uint256 public numberOfEpochs;
    uint128 public epochsDelayedFromStakingContract;

    uint256 public _totalAmountPerEpoch;
    uint128 public lastInitializedEpoch;

    uint256[] public epochPoolSizeCache;
    mapping(address => uint128) public lastEpochIdHarvested;

    uint256 public epochDuration; // init from staking contract
    uint256 public epochStart; // init from staking contract

    // events
    event MassHarvest(address indexed user, uint256 epochsHarvested, uint256 totalValue);
    event Harvest(address indexed user, uint128 indexed epochId, uint256 amount);

    // constructor
    constructor(
        address[] memory poolTokenAddresses,
        address rewardTokenAddress,
        address stakingAddress,
        address communityVaultAddress,
        uint256 distributedAmount,
        uint256 noOfEpochs,
        uint128 epochsDelayed
    ) {
        for (uint256 i = 0; i < poolTokenAddresses.length; i++) {
            address addr = poolTokenAddresses[i];
            require(addr != address(0), "invalid pool token address");

            uint8 decimals = IERC20Metadata(addr).decimals();
            poolTokens.push(TokenDetails(addr, decimals));

            if (maxDecimals < decimals) {
                maxDecimals = decimals;
            }
        }

        rewardToken = IERC20(rewardTokenAddress);

        staking = IStaking(stakingAddress);
        communityVault = communityVaultAddress;

        totalDistributedAmount = distributedAmount;
        numberOfEpochs = noOfEpochs;
        epochPoolSizeCache = new uint256[](numberOfEpochs + 1);
        epochsDelayedFromStakingContract = epochsDelayed;

        epochDuration = staking.epochDuration();
        epochStart = staking.epoch1Start() + epochDuration * epochsDelayedFromStakingContract;

        _totalAmountPerEpoch = totalDistributedAmount / numberOfEpochs;
    }

    // public methods
    // public method to harvest all the unharvested epochs until current epoch - 1
    function massHarvest() external returns (uint256){
        uint256 totalUserReward;
        uint256 epochId = _getEpochId() - 1; // fails in epoch 0

        // force max number of epochs
        if (epochId > numberOfEpochs) {
            epochId = numberOfEpochs;
        }

        uint128 userLastEpochHarvested = lastEpochIdHarvested[msg.sender];

        for (uint128 i = userLastEpochHarvested + 1; i <= epochId; i++) {
            // i = epochId
            // compute distributed Value and do one single transfer at the end
            totalUserReward += _harvest(i);
        }

        emit MassHarvest(msg.sender, epochId - userLastEpochHarvested, totalUserReward);

        if (totalUserReward > 0) {
            rewardToken.safeTransferFrom(communityVault, msg.sender, totalUserReward);
        }

        return totalUserReward;
    }

    function harvest(uint128 epochId) external returns (uint256){
        // checks for requested epoch
        require(_getEpochId() > epochId, "This epoch is in the future");
        require(epochId <= numberOfEpochs, "Maximum number of epochs is 25");
        require(lastEpochIdHarvested[msg.sender] + 1 == epochId, "Harvest in order");

        uint256 userReward = _harvest(epochId);
        if (userReward > 0) {
            rewardToken.safeTransferFrom(communityVault, msg.sender, userReward);
        }

        emit Harvest(msg.sender, epochId, userReward);

        return userReward;
    }

    // views
    // calls to the staking smart contract to retrieve the epoch total pool size
    function getPoolSize(uint128 epochId) external view returns (uint256) {
        return _getPoolSize(epochId);
    }

    function getPoolSizeByToken(address token, uint128 epochId) external view returns (uint256) {
        uint128 stakingEpochId = _stakingEpochId(epochId);

        return staking.getEpochPoolSize(token, stakingEpochId);
    }

    function getCurrentEpoch() external view returns (uint256) {
        return _getEpochId();
    }

    // calls to the staking smart contract to retrieve user balance for an epoch
    function getEpochStake(address userAddress, uint128 epochId) external view returns (uint256) {
        return _getUserBalancePerEpoch(userAddress, epochId);
    }

    function getEpochStakeByToken(address userAddress, address token, uint128 epochId) external view returns (uint256) {
        uint128 stakingEpochId = _stakingEpochId(epochId);

        return staking.getEpochUserBalance(userAddress, token, stakingEpochId);
    }

    function userLastEpochIdHarvested() external view returns (uint256){
        return lastEpochIdHarvested[msg.sender];
    }

    function getPoolTokens() external view returns (address[] memory tokens) {
        tokens = new address[](poolTokens.length);

        for (uint256 i = 0; i < poolTokens.length; i++) {
            tokens[i] = poolTokens[i].addr;
        }
    }

    // internal methods

    function _initEpoch(uint128 epochId) internal {
        require(lastInitializedEpoch + 1 == epochId, "Epoch can be init only in order");

        lastInitializedEpoch = epochId;
        // call the staking smart contract to init the epoch
        epochPoolSizeCache[epochId] = _getPoolSize(epochId);
    }

    function _harvest(uint128 epochId) internal returns (uint256) {
        // try to initialize an epoch. if it can't it fails
        // if it fails either user either a BarnBridge account will init not init epochs
        if (lastInitializedEpoch < epochId) {
            _initEpoch(epochId);
        }
        // Set user last harvested epoch
        lastEpochIdHarvested[msg.sender] = epochId;
        // compute and return user total reward. For optimization reasons the transfer have been moved to an upper layer (i.e. massHarvest needs to do a single transfer)

        // exit if there is no stake on the epoch
        if (epochPoolSizeCache[epochId] == 0) {
            return 0;
        }

        return _totalAmountPerEpoch * _getUserBalancePerEpoch(msg.sender, epochId) / epochPoolSizeCache[epochId];
    }

    function _getPoolSize(uint128 epochId) internal view returns (uint256) {
        uint128 stakingEpochId = _stakingEpochId(epochId);

        uint256 totalPoolSize;

        for (uint256 i = 0; i < poolTokens.length; i++) {
            totalPoolSize = totalPoolSize + staking.getEpochPoolSize(poolTokens[i].addr, stakingEpochId) * 10 ** (maxDecimals - poolTokens[i].decimals);
        }

        return totalPoolSize;
    }


    function _getUserBalancePerEpoch(address userAddress, uint128 epochId) internal view returns (uint256){
        uint128 stakingEpochId = _stakingEpochId(epochId);

        uint256 totalUserBalance;

        for (uint256 i = 0; i < poolTokens.length; i++) {
            totalUserBalance = totalUserBalance + staking.getEpochUserBalance(userAddress, poolTokens[i].addr, stakingEpochId) * 10 ** (maxDecimals - poolTokens[i].decimals);
        }

        return totalUserBalance;
    }

    // compute epoch id from block.timestamp and epochStart date
    function _getEpochId() internal view returns (uint128) {
        if (block.timestamp < epochStart) {
            return 0;
        }

        return uint128(
            (block.timestamp - epochStart) / epochDuration + 1
        );
    }

    // get the staking epoch
    function _stakingEpochId(uint128 epochId) internal view returns (uint128) {
        return epochId + epochsDelayedFromStakingContract;
    }
}
