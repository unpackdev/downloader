// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.7.6;

import "./SafeMath.sol";
import "./SafeERC20.sol";
import "./ISovWrapper.sol";
import "./IBasketBalancer.sol";
import "./IReign.sol";
import "./LibRewardsDistribution.sol";

contract WrappingRewards {
    // lib
    using SafeMath for uint256;
    using SafeMath for uint128;
    using SafeERC20 for IERC20;

    // state variables

    uint256 public constant NO_VOTE_PENALTY = 3 * 10**16; // -3%
    uint256 private constant BASE_MULTIPLIER = 10**18;

    // addresses
    address public treasury;
    address public rewardsVault;
    address public basketBalancer;

    // contracts
    IERC20 public reignToken;
    ISovWrapper public wrapper;

    uint128 public lastInitializedEpoch;
    uint256 public epochDuration; // init from staking contract
    uint256 public epochStart; // init from staking contract

    mapping(uint128 => uint256) private _sizeAtEpoch;
    mapping(address => uint128) private _lastEpochIdHarvested;

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
        address _reignTokenAddress,
        address _basketBalancer,
        address _wrappingContract,
        address _rewardsVault,
        address _treasury
    ) {
        reignToken = IERC20(_reignTokenAddress);
        wrapper = ISovWrapper(_wrappingContract);
        rewardsVault = _rewardsVault;
        basketBalancer = _basketBalancer;
        epochDuration = wrapper.epochDuration();
        epochStart = wrapper.epoch1Start() + epochDuration;
        treasury = _treasury;
    }

    // public method to harvest all the unharvested epochs until current epoch - 1
    function massHarvest() external returns (uint256) {
        uint256 totalDistributedValue;
        uint256 epochId = _getEpochId().sub(1); // fails in epoch 0

        for (
            uint128 i = _lastEpochIdHarvested[msg.sender] + 1;
            i <= epochId;
            i++
        ) {
            // i = epochId
            // compute distributed Value and do one single transfer at the end
            totalDistributedValue += _harvest(i);
        }

        if (totalDistributedValue > 0) {
            reignToken.safeTransferFrom(
                rewardsVault,
                msg.sender,
                totalDistributedValue
            );
        }

        emit MassHarvest(
            msg.sender,
            epochId - _lastEpochIdHarvested[msg.sender],
            totalDistributedValue
        );

        return totalDistributedValue;
    }

    //gets the rewards for a single epoch
    function harvest(uint128 epochId) external returns (uint256) {
        // checks for requested epoch
        require(_getEpochId() > epochId, "This epoch is in the future");
        require(
            _lastEpochIdHarvested[msg.sender].add(1) == epochId,
            "Can only harvest in order"
        );

        uint256 userReward = _harvest(epochId);
        if (userReward > 0) {
            reignToken.safeTransferFrom(rewardsVault, msg.sender, userReward);
        }

        emit Harvest(msg.sender, epochId, userReward);
        return userReward;
    }

    // transfer the entire fees collected in this contract to DAO treasury
    function collectFeesToDAO() public {
        uint256 balance = IERC20(reignToken).balanceOf(address(this));
        IERC20(reignToken).safeTransfer(treasury, balance);
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
        uint256 epochRewards = LibRewardsDistribution
            .wrappingRewardsPerEpochTotal(epochStart); //this accounts for2 year halving already
        return epochRewards;
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
        return _lastEpochIdHarvested[msg.sender];
    }

    // calls to the staking smart contract to retrieve the epoch total poolLP size
    function getPoolSize(uint128 epochId) external view returns (uint256) {
        return _getPoolSize(epochId);
    }

    // checks if the user has voted that epoch and returns accordingly
    function isBoosted(address user, uint128 epoch) public view returns (bool) {
        IBasketBalancer basketBalancer = IBasketBalancer(basketBalancer);
        address _reign = basketBalancer.reignDiamond();
        // if user or users delegate has voted
        if (
            basketBalancer.hasVotedInEpoch(
                user,
                epoch + 1 // basketBalancer epoch is 1 higher then this
            ) ||
            basketBalancer.hasVotedInEpoch(
                IReign(_reign).userDelegatedTo(user),
                epoch + 1 // basketBalancer epoch is 1 higher then this
            )
        ) {
            return true;
        } else {
            return false; // apply -3%
        }
    }

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
        bool boost = isBoosted(msg.sender, epochId);

        // get users share of rewards
        uint256 userEpochRewards = epochRewards
            .mul(_getUserBalancePerEpoch(msg.sender, epochId))
            .div(_sizeAtEpoch[epochId]);

        //if user is not boosted pull penalty into this contract and reduce user rewards
        if (!boost) {
            uint256 penalty = userEpochRewards.mul(NO_VOTE_PENALTY).div(
                BASE_MULTIPLIER
            ); // decrease by 3%

            userEpochRewards = userEpochRewards.sub(penalty);
        }

        return userEpochRewards;
    }

    /**
        INTERNAL
     */

    function _harvest(uint128 epochId) internal returns (uint256) {
        // try to initialize an epoch
        if (lastInitializedEpoch < epochId) {
            _initEpoch(epochId);
        }
        // Set user state for last harvested
        _lastEpochIdHarvested[msg.sender] = epochId;

        // exit if there is no stake on the epoch
        if (_sizeAtEpoch[epochId] == 0) {
            return 0;
        }

        uint256 epochRewards = getRewardsForEpoch();
        bool boost = isBoosted(msg.sender, epochId);

        // get users share of rewards
        uint256 userEpochRewards = epochRewards
            .mul(_getUserBalancePerEpoch(msg.sender, epochId))
            .div(_sizeAtEpoch[epochId]);

        //if user is not boosted pull penalty into this contract and reduce user rewards
        if (!boost) {
            uint256 penalty = userEpochRewards.mul(NO_VOTE_PENALTY).div(
                BASE_MULTIPLIER
            ); // decrease by 3%

            userEpochRewards = userEpochRewards.sub(penalty);

            reignToken.safeTransferFrom(rewardsVault, address(this), penalty);
        }

        return userEpochRewards;
    }

    function _initEpoch(uint128 epochId) internal {
        //epochs can only be harvested in order, therfore they can also only be initialised in order
        // i.e it's impossible that we init epoch 5 after 3 as to harvest 5 user needs to first harvets 4
        _sizeAtEpoch[epochId] = _getPoolSize(epochId);
        lastInitializedEpoch = epochId;
        // call the staking smart contract to init the epoch

        emit InitEpoch(msg.sender, epochId);
    }

    function _getPoolSize(uint128 epochId) internal view returns (uint256) {
        // retrieve unilp token balance
        return wrapper.getEpochPoolSize(_wrapperEpochId(epochId));
    }

    function _getUserBalancePerEpoch(address userAddress, uint128 epochId)
        internal
        view
        returns (uint256)
    {
        // retrieve unilp token balance per user per epoch
        return
            wrapper.getEpochUserBalance(userAddress, _wrapperEpochId(epochId));
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

    // get the staking epoch which is 1 epoch more
    function _wrapperEpochId(uint128 epochId) internal pure returns (uint128) {
        return epochId + 1;
    }
}
