// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.7.6;

import "./SafeMath.sol";
import "./SafeERC20.sol";
import "./IStaking.sol";
import "./LibRewardsDistribution.sol";

contract LPRewards {
    // lib
    using SafeMath for uint256;
    using SafeMath for uint128;
    using SafeERC20 for IERC20;

    // constants
    uint256 public constant NR_OF_EPOCHS = 100;

    // state variables

    uint256 public epochDuration; // init from staking contract
    uint256 public epochStart; // init from staking contract
    uint128 public lastInitializedEpoch;

    uint256 public totalAmountPerEpoch;

    uint256[] private _sizeAtEpoch = new uint256[](NR_OF_EPOCHS + 1);

    address private _depositLP;
    address private _rewardsVault;

    mapping(address => uint128) private _lastEpochIdHarvested;

    // contracts
    IERC20 private _reignToken;
    IStaking private _staking;

    // events
    event MassHarvest(
        address indexed user,
        uint256 sizeAtEpochHarvested,
        uint256 totalValue
    );

    event Harvest(
        address indexed user,
        uint128 indexed epochId,
        uint256 amount
    );

    event InitEpoch(address indexed caller, uint128 indexed epochId);

    constructor(
        address reignTokenAddress,
        address depositLP,
        address stakeContract,
        address rewardsVault,
        uint256 totalDistribution
    ) {
        _reignToken = IERC20(reignTokenAddress);
        _depositLP = depositLP;
        _staking = IStaking(stakeContract);
        _rewardsVault = rewardsVault;
        totalAmountPerEpoch = LibRewardsDistribution.rewardsPerEpochLPRewards(
            totalDistribution,
            NR_OF_EPOCHS
        );
    }

    function initialize() public {
        require(epochStart == 0, "Can only be initialized once");
        epochDuration = _staking.epochDuration();
        epochStart = _staking.epoch1Start() + epochDuration;
    }

    // public methods
    // public method to harvest all the unharvested epochs until current epoch - 1
    function massHarvest() external returns (uint256) {
        uint256 totalDistributedValue;
        uint256 epochId = getCurrentEpoch().sub(1); // fails in epoch 0
        // force max number of epochs
        if (epochId > NR_OF_EPOCHS) {
            epochId = NR_OF_EPOCHS;
        }

        for (
            uint128 i = _lastEpochIdHarvested[msg.sender] + 1;
            i <= epochId;
            i++
        ) {
            // i = epochId
            // compute distributed Value and do one single transfer at the end
            totalDistributedValue += _harvest(i);
        }

        emit MassHarvest(
            msg.sender,
            epochId - _lastEpochIdHarvested[msg.sender],
            totalDistributedValue
        );

        if (totalDistributedValue > 0) {
            _reignToken.safeTransferFrom(
                _rewardsVault,
                msg.sender,
                totalDistributedValue
            );
        }

        return totalDistributedValue;
    }

    function harvest(uint128 epochId) external returns (uint256) {
        // checks for requested epoch
        require(getCurrentEpoch() > epochId, "This epoch is in the future");
        require(
            epochId <= NR_OF_EPOCHS,
            "Maximum number of sizeAtEpoch is 100"
        );
        require(
            _lastEpochIdHarvested[msg.sender].add(1) == epochId,
            "Can only harvest in order"
        );
        // init epoch if necessary and get rewards amount
        uint256 userReward = _harvest(epochId);
        if (userReward > 0) {
            _reignToken.safeTransferFrom(_rewardsVault, msg.sender, userReward);
        }
        emit Harvest(msg.sender, epochId, userReward);
        return userReward;
    }

    // internal methods
    function _initEpoch(uint128 epochId) internal {
        //epochs can only be harvested in order, therfore they can also only be initialised in order
        // i.e it's impossible that we init epoch 5 after 3 as to harvest 5 user needs to first harvets 4
        lastInitializedEpoch = epochId;
        // call the staking smart contract to init the epoch
        _sizeAtEpoch[epochId] = _getPoolSize(epochId);

        emit InitEpoch(msg.sender, epochId);
    }

    function _harvest(uint128 epochId) internal returns (uint256) {
        // initialize the epoch
        if (lastInitializedEpoch < epochId) {
            _initEpoch(epochId);
        }
        // Set user state for last harvested
        _lastEpochIdHarvested[msg.sender] = epochId;

        // exit if there is no stake on the epoch
        if (_sizeAtEpoch[epochId] == 0) {
            return 0;
        }
        // compute and return user total reward.
        // For optimization reasons the transfer have been moved to an upper layer (i.e. massHarvest needs to do a single transfer)
        return
            totalAmountPerEpoch
                .mul(_getUserBalancePerEpoch(msg.sender, epochId))
                .div(_sizeAtEpoch[epochId]);
    }

    /**
        VIEWS
     */

    // compute epoch id from blocktimestamp and date
    function getCurrentEpoch() public view returns (uint128 epochId) {
        if (block.timestamp < epochStart) {
            return 0;
        }
        epochId = uint128(
            block.timestamp.sub(epochStart).div(epochDuration).add(1)
        );
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

        return
            totalAmountPerEpoch
                .mul(_getUserBalancePerEpoch(msg.sender, epochId))
                .div(_sizeAtEpoch[epochId]);
    }

    //returns deposit token
    function depositLP() public view returns (address) {
        return _depositLP;
    }

    // calls to the staking smart contract to retrieve the epoch's total pool size
    function getPoolSize(uint128 epochId) external view returns (uint256) {
        return _getPoolSize(epochId);
    }

    // calls to the staking smart contract to retrieve user balance for an epoch
    function getEpochStake(address userAddress, uint128 epochId)
        external
        view
        returns (uint256)
    {
        return _getUserBalancePerEpoch(userAddress, epochId);
    }

    // returns when epoch in which user last harvested
    function userLastEpochIdHarvested() external view returns (uint256) {
        return _lastEpochIdHarvested[msg.sender];
    }

    // retrieve pool size at epoch
    function _getPoolSize(uint128 epochId) internal view returns (uint256) {
        return _staking.getEpochPoolSize(_depositLP, _stakingEpochId(epochId));
    }

    // retrieve token balance per user per epoch
    function _getUserBalancePerEpoch(address userAddress, uint128 epochId)
        internal
        view
        returns (uint256)
    {
        return
            _staking.getEpochUserBalance(
                userAddress,
                _depositLP,
                _stakingEpochId(epochId)
            );
    }

    // get the staking epoch which is 1 epoch more
    function _stakingEpochId(uint128 epochId) internal pure returns (uint128) {
        return epochId + 1;
    }
}
