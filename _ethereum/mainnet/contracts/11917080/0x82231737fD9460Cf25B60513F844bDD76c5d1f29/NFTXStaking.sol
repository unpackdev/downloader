// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


import "./IERC20.sol";
import "./BootERC20.sol";
import "./Context.sol";

contract NFTXStaking {

    /// @dev Emitted when NFTX is staked
    event NFTXStaked (address indexed user, uint256 amount);

    /// @dev Emitted when NFTX is unstaked
    event NFTXUnstaked (address indexed user, uint256 amount);


    IERC20 public immutable NFTX;
    BootERC20 public immutable BOOT;

    /// @dev The block number at which the staking ends, no staking after this timestamp.
    uint256 public immutable STAKING_END_TIME_BLOCK_NUMBER;

    uint256 private constant DECIMAL_MULTIPLIER = 10**18;

    /// @dev The amount of BOOT minted per block
    uint256 private _interestRatePerBlock = DECIMAL_MULTIPLIER * 100;

    struct UserStakeInfo {
        uint256 amount;
        uint256 rewardDebt;
        uint256 bootEarned;
    }

    mapping (address => UserStakeInfo) private _userStakes;

    /// @dev Reward mechanism management variables
    uint256 private _accAmountPerShare;
    uint256 private _totalProductivity;
    uint256 private _lastRewardBlock;
    uint256 private _totalStakedAmount;


    /// @notice The constructor - does the token initialization and calculates the STAKING_END_TIME_BLOCK_NUMBER
    /// @param NFTX_TOKEN The address of the NFTX token
    /// @param BOOT_TOKEN The address of the BOOT token
    /// @param mintingBlocks The amount of blocks that the minting is allowed for
    constructor(address NFTX_TOKEN, address BOOT_TOKEN, uint256 mintingBlocks) {
        BOOT = BootERC20(BOOT_TOKEN);
        NFTX = IERC20(NFTX_TOKEN);

        STAKING_END_TIME_BLOCK_NUMBER = block.number + mintingBlocks;
    }

    // ========== MODIFIERS ==========

    /// @dev Throws if called after the STAKING_END_TIME_BLOCK_NUMBER
    modifier onlyIfNotStakingEnded() {
        require(block.number <= STAKING_END_TIME_BLOCK_NUMBER, "NFTXStaking: Staking ended");
        _;
    }


    // ========== STAKING AND REWARDS ==========

    /// @dev Stake the requested NFTX amount to the contract
    /// @param _amount The amount to stake
    /// @return _success Whether the staking was successful
    function stakeNFTX(uint256 _amount) public onlyIfNotStakingEnded returns (bool _success){

        require(_amount > 0, 'NFTXStaking: NFTX staking amount must be greater than 0.');
        require(NFTX.balanceOf(msg.sender) >= _amount, "NFTXStaking: Not enough NFTX balance.");

        // take the user's amount
        NFTX.transferFrom(msg.sender, address(this), _amount);

        UserStakeInfo storage userStakeInfo = _userStakes[msg.sender];
        // update contract state
        update();
        if (userStakeInfo.amount > 0) {
            // send the user rewards up until this point
            _rewardUser(msg.sender);
        }

        _totalProductivity = _totalProductivity + _amount;
        userStakeInfo.amount = userStakeInfo.amount + _amount;
        userStakeInfo.rewardDebt = _getRewardDebt(msg.sender);

        _totalStakedAmount = _totalStakedAmount + _amount;
        emit NFTXStaked(msg.sender, _amount);
        return true;
    }

    /// @dev Unstake the requested NFTX amount from the contract
    /// @param _amount The amount to unstake
    /// @return _success Whether the unstaking was successful
    function unstakeNFTX(uint256 _amount) public returns (bool _success) {
        require(_amount > 0, 'NFTXStaking: NFTX unstake amount must be greater than 0.');

        UserStakeInfo storage userStakeInfo = _userStakes[msg.sender];
        require(userStakeInfo.amount >= _amount, "NFTXStaking: Requested NFTX amount greater than the available amount.");

        update();


        // send the user's pending amount
        _rewardUser(msg.sender);

        userStakeInfo.amount = userStakeInfo.amount - _amount;
        userStakeInfo.rewardDebt = _getRewardDebt(msg.sender);
        _totalProductivity = _totalProductivity - _amount;

        NFTX.transfer(msg.sender, _amount);

        _totalStakedAmount = _totalStakedAmount - _amount;
        emit NFTXUnstaked(msg.sender, _amount);
        return true;
    }


    /// @dev Update the internal state of the contract, used for updating the variables for the rewards mechanism
    function update() internal
    {
        if (block.number <= _lastRewardBlock) {
            return;
        }

        if (_totalProductivity == 0) {
            // there is nothing to be rewarded
            _lastRewardBlock = block.number;
            return;
        }

        uint256 rewards = 0;
        uint256 latestBlockNumber = block.number;

        if(latestBlockNumber > STAKING_END_TIME_BLOCK_NUMBER) {
            latestBlockNumber = STAKING_END_TIME_BLOCK_NUMBER;
        }

        uint256 blocksSinceLastReward = latestBlockNumber - _lastRewardBlock;


        rewards = blocksSinceLastReward * _interestRatePerBlock;
        _accAmountPerShare = _getAccAmountPerShare(rewards);

        // mint rewards to contract, to distribute later
        BOOT.mint(address(this), rewards);
        _lastRewardBlock = latestBlockNumber;
    }


    // ========== HELPER FUNCTIONS ==========


    /// @dev Calculates and sends the pending rewards to user
    /// @param _user The address of the user
    function _rewardUser(address _user) internal {
        uint256 pendingAmount = _getPendingAmount(_user);
        BOOT.transfer(_user, pendingAmount);
        _userStakes[_user].bootEarned += pendingAmount;
    }

    /// @dev Calculate the pending rewards amount for user
    /// @param _user The user's address
    /// @return _pendingAmount The user's pending amount
    function _getPendingAmount(address _user) internal view returns (uint256 _pendingAmount) {
        return (_userStakes[_user].amount * _accAmountPerShare) / DECIMAL_MULTIPLIER - _userStakes[_user].rewardDebt;
    }

    /// @dev Calculate the reward debt for user
    /// @param _user The user's address
    /// @return _rewardDebt The user's reward debt
    function _getRewardDebt(address _user) internal view returns (uint256 _rewardDebt) {
        return (_userStakes[_user].amount * _accAmountPerShare) / DECIMAL_MULTIPLIER;
    }

    /// @dev Calculate the accumulative amount per share based on the unclaimed rewards
    /// @param _rewards The unclaimed rewards
    /// @return accAmountPerShare The accumulative amount per share
    function _getAccAmountPerShare(uint256 _rewards) internal view returns (uint256 accAmountPerShare) {
        return _accAmountPerShare + ((_rewards * DECIMAL_MULTIPLIER) / _totalProductivity);
    }


    // ========== VIEW FUNCTIONS / METADATA ==========

    /// @dev Calculates the user's unclaimed rewards (the  rewards from NFTX staking, which are not claimed yet).
    /// @param _user The address of the user
    /// @return _unclaimedRewards The user's uncalimed rewards.
    function getUnclaimedRewards(address _user) external view returns (uint256 _unclaimedRewards) {
        UserStakeInfo storage userStakeInfo = _userStakes[_user];
        uint256 accAmountPerShare = _accAmountPerShare;

        if (block.number > _lastRewardBlock && _totalProductivity != 0) {

            uint256 blocksSinceLastReward = block.number - _lastRewardBlock;

            if(block.number > STAKING_END_TIME_BLOCK_NUMBER) {
                blocksSinceLastReward = STAKING_END_TIME_BLOCK_NUMBER - _lastRewardBlock;
            }

            uint256 reward = blocksSinceLastReward * _interestRatePerBlock;
            accAmountPerShare = _getAccAmountPerShare(reward);
        }

        return (userStakeInfo.amount * accAmountPerShare) / DECIMAL_MULTIPLIER - userStakeInfo.rewardDebt;

    }

    /// @dev Return the accumulative amount per share
    /// @return accAmountPerShare Accumulative amount per share
    function accumulativeAmountPerShare() external view returns (uint256 accAmountPerShare) {
        return _accAmountPerShare;
    }

    /// @dev Return the total productivity
    /// @return _totalProd Total productivity
    function totalProductivity() external view returns (uint256 _totalProd) {
        return _totalProductivity;
    }

    /// @dev Return the block of the last reward
    /// @return _lastRewardBlck The last reward block
    function lastRewardBlock() external view returns (uint256 _lastRewardBlck) {
        return _lastRewardBlock;
    }

    /// @dev Return the user's staked amount
    /// @param _user The address of the user
    /// @return stakedAmount The user's current staked amount
    function getStakedAmount(address _user) external view returns (uint256 stakedAmount) {
        return _userStakes[_user].amount;
    }

    /// @dev Return the user's total earned BOOT amount
    /// @param _user The address of the user
    /// @return bootEarned The user's total earned BOOT amount
    function getBootEarned(address _user) external view returns (uint256 bootEarned) {
        return _userStakes[_user].bootEarned;
    }

    /// @dev Returns the amount of BOOT tokens minted per block
    /// @return bootMined The amount of BOOT tokens minted per block
    function getBootMintedPerBlock() external view returns (uint256 bootMined) {
        return _interestRatePerBlock;
    }

    /// @dev Returns the blocks left until the staking ends
    /// @return numberOfBlocksLeft Number of blocks until the staking ends
    function getNumberOfBlocksLeft() external view returns (uint256 numberOfBlocksLeft) {
        return STAKING_END_TIME_BLOCK_NUMBER - block.number;
    }

    /// @dev Returns the total staked amount
    /// @return totalStakedAmount The total staked amount
    function getTotalStakedAmount() external view returns (uint256 totalStakedAmount) {
        return _totalStakedAmount;
    }



}