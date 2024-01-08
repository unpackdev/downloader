// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;

import "./Math.sol";
import "./SafeMath.sol";
import "./SafeERC20.sol";
import "./SafeERC20Upgradeable.sol";
import "./ReentrancyGuard.sol";
import "./OwnableUpgradeable.sol";

import "./IUniswapV2Pair.sol";
import "./IRewarder.sol";

import "./IContractsRegistry.sol";
import "./IBMIStaking.sol";
import "./ILiquidityMining.sol";
import "./ILiquidityMiningStaking.sol";

import "./AbstractDependant.sol";
import "./AbstractSlasher.sol";

import "./Globals.sol";

abstract contract AbstractLiquidityMiningStaking is
    ILiquidityMiningStaking,
    IRewarder,
    OwnableUpgradeable,
    ReentrancyGuard,
    AbstractDependant,
    AbstractSlasher
{
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    address public sushiswapMasterChefV2Address;
    IERC20 public rewardsToken;
    address public stakingToken;
    IBMIStaking public bmiStaking;
    ILiquidityMining public liquidityMining;

    uint256 public rewardPerBlock;
    uint256 public firstBlockWithReward;
    uint256 public lastBlockWithReward;
    uint256 public lastUpdateBlock;
    uint256 public rewardPerTokenStored;
    uint256 public rewardTokensLocked;

    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) internal _rewards;

    uint256 public totalStaked;
    mapping(address => uint256) public staked;

    address public nftStakingAddress;
    mapping(address => uint256) public stakerRewardMultiplier;

    event RewardsSet(
        uint256 rewardPerBlock,
        uint256 firstBlockWithReward,
        uint256 lastBlockWithReward
    );
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, address indexed recipient, uint256 reward);
    event RewardRestaked(address indexed user, uint256 reward);
    event RewardTokensRecovered(uint256 amount);

    modifier onlyNFTStaking() {
        require(_msgSender() == nftStakingAddress, "LMS: Not a NFT staking contract");
        _;
    }

    modifier onlyMCV2() {
        require(_msgSender() == sushiswapMasterChefV2Address, "LMS: Not a MCV2 contract");
        _;
    }

    modifier updateReward(address account) {
        _updateReward(account);
        _;
    }

    function __LiquidityMiningStaking_init() internal initializer {
        __Ownable_init();
    }

    function blocksWithRewardsPassed() public view override returns (uint256) {
        uint256 from = Math.max(lastUpdateBlock, firstBlockWithReward);
        uint256 to = Math.min(block.number, lastBlockWithReward);

        return from >= to ? 0 : to.sub(from);
    }

    function rewardPerToken() public view override returns (uint256) {
        uint256 totalPoolStaked = totalStaked;

        if (totalPoolStaked == 0) {
            return rewardPerTokenStored;
        }

        uint256 accumulatedReward =
            blocksWithRewardsPassed().mul(rewardPerBlock).mul(DECIMALS18).div(totalPoolStaked);

        return rewardPerTokenStored.add(accumulatedReward);
    }

    function earned(address _account) public view override returns (uint256) {
        uint256 rewardsDifference = rewardPerToken().sub(userRewardPerTokenPaid[_account]);
        uint256 _staked = staked[_account];
        uint256 newlyAccumulated =
            _staked
                .add(_staked.mul(stakerRewardMultiplier[_account]).div(PERCENTAGE_100))
                .mul(rewardsDifference)
                .div(DECIMALS18);

        return _rewards[_account].add(newlyAccumulated);
    }

    function setRewardMultiplier(address _account, uint256 _rewardMultiplier)
        external
        override
        onlyNFTStaking
        updateReward(_account)
    {
        uint256 _accountStaked = staked[_account];
        uint256 _oldMultiplier = stakerRewardMultiplier[_account];
        uint256 totalPoolStaked = totalStaked;

        stakerRewardMultiplier[_account] = _rewardMultiplier;

        totalPoolStaked = totalPoolStaked.sub(
            _accountStaked.mul(_oldMultiplier).div(PERCENTAGE_100)
        );

        totalPoolStaked = totalPoolStaked.add(
            _accountStaked.mul(_rewardMultiplier).div(PERCENTAGE_100)
        );

        totalStaked = totalPoolStaked;
    }

    /// @dev returns percentage multiplied by 10**25
    function getSlashingPercentage() external view override returns (uint256) {
        return getSlashingPercentage(liquidityMining.startLiquidityMiningTime());
    }

    function earnedSlashed(address _account) external view override returns (uint256) {
        return _applySlashing(earned(_account), liquidityMining.startLiquidityMiningTime());
    }

    /// @notice djusts the staking of a specific user by staking,  withdrawing or _getReward (harvesting, WandHarvest) on the sushiswap protocol
    /// @dev function required by the sushiswap integration, and only accessible to the masterchef v2 contract of sushi,
    /// sushi will handel all of staking , witdrwa our lp token and get reward (sushi token) of a user , and we tract all the state on top of that,
    /// alongside with  distribute our reward token
    /// @param pid uint256 The index of the sushiswap pool
    /// @param user address  user’s address
    /// @param recipient address Receiver of the LP tokens and SUSHI rewards (may the same user or another user who will get the benefits)
    /// @param sushiAmount uint256 the pending $SUSHI amount by sushi
    /// @param newLpAmount uint256 new lp token amount of the user
    function onSushiReward(
        uint256 pid,
        address user,
        address recipient,
        uint256 sushiAmount,
        uint256 newLpAmount
    ) external override onlyMCV2 nonReentrant updateReward(user) {
        uint256 _userStaked = staked[user];
        uint256 _amountDiff;

        staked[user] = newLpAmount;
        // deposit from sushi swap farm
        if (newLpAmount > _userStaked) {
            _amountDiff = newLpAmount.sub(_userStaked);

            totalStaked = totalStaked.add(
                _amountDiff.add(_amountDiff.mul(stakerRewardMultiplier[user]).div(PERCENTAGE_100))
            );

            emit Staked(user, _amountDiff);
        }
        // withdraw from sushi swap farm
        else if (newLpAmount < _userStaked) {
            _amountDiff = _userStaked.sub(newLpAmount);

            totalStaked = totalStaked.sub(
                _amountDiff.add(_amountDiff.mul(stakerRewardMultiplier[user]).div(PERCENTAGE_100))
            );

            // withdrawAndHarvest from sushi swap farm
            if (sushiAmount > 0) _getReward(user, recipient);

            emit Withdrawn(user, _amountDiff);
        } else {
            //harvest from sushi swap farm
            _getReward(user, recipient);
        }
    }

    function _getReward(address user, address recipient) internal {
        uint256 reward = _rewards[user];

        if (reward > 0) {
            delete _rewards[user];

            uint256 bmiStakingProfit =
                _getSlashed(reward, liquidityMining.startLiquidityMiningTime());
            uint256 profit = reward.sub(bmiStakingProfit);

            // transfer slashed bmi to the bmiStaking and add them to the pool
            rewardsToken.safeTransfer(address(bmiStaking), bmiStakingProfit);
            bmiStaking.addToPool(bmiStakingProfit);

            // transfer bmi profit to the user
            rewardsToken.safeTransfer(recipient, profit);

            rewardTokensLocked = rewardTokensLocked.sub(reward);

            emit RewardPaid(user, recipient, profit);
        }
    }

    /// @notice returns APY% with 10**5 precision
    function getAPY() external view override returns (uint256) {
        uint256 totalSupply = IUniswapV2Pair(stakingToken).totalSupply();
        (uint256 reserveBMI, , ) = IUniswapV2Pair(stakingToken).getReserves();

        if (totalSupply == 0 || reserveBMI == 0) {
            return 0;
        }

        return
            rewardPerBlock.mul(BLOCKS_PER_YEAR).mul(PERCENTAGE_100).div(
                totalStaked.add(APY_TOKENS).mul(reserveBMI.mul(2).mul(10**20).div(totalSupply))
            );
    }

    function setRewards(
        uint256 _rewardPerBlock,
        uint256 _startingBlock,
        uint256 _blocksAmount
    ) external onlyOwner updateReward(address(0)) {
        uint256 unlockedTokens = _getFutureRewardTokens();

        rewardPerBlock = _rewardPerBlock;
        firstBlockWithReward = _startingBlock;
        lastBlockWithReward = _startingBlock.add(_blocksAmount).sub(1);

        uint256 lockedTokens = _getFutureRewardTokens();
        rewardTokensLocked = rewardTokensLocked.sub(unlockedTokens).add(lockedTokens);

        require(
            rewardTokensLocked <= rewardsToken.balanceOf(address(this)),
            "LMS: Not enough tokens for the rewards"
        );

        emit RewardsSet(_rewardPerBlock, _startingBlock, lastBlockWithReward);
    }

    function recoverNonLockedRewardTokens() external onlyOwner {
        uint256 nonLockedTokens = rewardsToken.balanceOf(address(this)).sub(rewardTokensLocked);

        rewardsToken.safeTransfer(owner(), nonLockedTokens);

        emit RewardTokensRecovered(nonLockedTokens);
    }

    function _updateReward(address account) internal {
        uint256 currentRewardPerToken = rewardPerToken();

        rewardPerTokenStored = currentRewardPerToken;
        lastUpdateBlock = block.number;

        if (account != address(0)) {
            _rewards[account] = earned(account);
            userRewardPerTokenPaid[account] = currentRewardPerToken;
        }
    }

    function _getFutureRewardTokens() internal view returns (uint256) {
        uint256 blocksLeft = _calculateBlocksLeft(firstBlockWithReward, lastBlockWithReward);

        return blocksLeft.mul(rewardPerBlock);
    }

    function _calculateBlocksLeft(uint256 _from, uint256 _to) internal view returns (uint256) {
        if (block.number >= _to) return 0;

        if (block.number < _from) return _to.sub(_from).add(1);

        return _to.sub(block.number);
    }
}
