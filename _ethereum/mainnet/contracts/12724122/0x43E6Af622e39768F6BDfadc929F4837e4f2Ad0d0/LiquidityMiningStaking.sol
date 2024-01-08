// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;

import "./Math.sol";
import "./SafeMath.sol";
import "./SafeERC20.sol";
import "./SafeERC20Upgradeable.sol";
import "./ReentrancyGuard.sol";
import "./OwnableUpgradeable.sol";

import "./IUniswapV2Pair.sol";

import "./IContractsRegistry.sol";
import "./IBMIStaking.sol";
import "./ILiquidityMining.sol";
import "./ILiquidityMiningStaking.sol";

import "./AbstractDependant.sol";
import "./AbstractSlasher.sol";

import "./Globals.sol";

contract LiquidityMiningStaking is
    ILiquidityMiningStaking,
    OwnableUpgradeable,
    ReentrancyGuard,
    AbstractDependant,
    AbstractSlasher
{
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    address public legacyLiquidityMiningStakingAddress;
    IERC20 public rewardsToken;
    address public stakingToken;
    IBMIStaking public bmiStaking;

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

    /***************** PROXY ALERT *****************/
    /******* DO NOT MODIFY THE STORAGE ABOVE *******/

    ILiquidityMining public liquidityMining;

    event RewardsSet(
        uint256 rewardPerBlock,
        uint256 firstBlockWithReward,
        uint256 lastBlockWithReward
    );
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);
    event RewardRestaked(address indexed user, uint256 reward);
    event RewardTokensRecovered(uint256 amount);

    modifier onlyStaking() {
        require(
            _msgSender() == legacyLiquidityMiningStakingAddress,
            "LMS: Not a staking contract"
        );
        _;
    }

    modifier updateReward(address account) {
        _updateReward(account);
        _;
    }

    function __LiquidityMiningStaking_init() external initializer {
        __Ownable_init();
    }

    function setDependencies(IContractsRegistry _contractsRegistry)
        external
        override
        onlyInjectorOrZero
    {
        legacyLiquidityMiningStakingAddress = _contractsRegistry
            .getLegacyLiquidityMiningStakingContract();
        rewardsToken = IERC20(_contractsRegistry.getBMIContract());
        bmiStaking = IBMIStaking(_contractsRegistry.getBMIStakingContract());
        stakingToken = _contractsRegistry.getUniswapBMIToETHPairContract();
        liquidityMining = ILiquidityMining(_contractsRegistry.getLiquidityMiningContract());
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
            blocksWithRewardsPassed().mul(rewardPerBlock).mul(DECIMALS).div(totalPoolStaked);

        return rewardPerTokenStored.add(accumulatedReward);
    }

    function earned(address _account) public view override returns (uint256) {
        uint256 rewardsDifference = rewardPerToken().sub(userRewardPerTokenPaid[_account]);
        uint256 newlyAccumulated = staked[_account].mul(rewardsDifference).div(DECIMALS);

        return _rewards[_account].add(newlyAccumulated);
    }

    /// @dev returns percentage multiplied by 10**25
    function getSlashingPercentage() external view override returns (uint256) {
        return getSlashingPercentage(liquidityMining.startLiquidityMiningTime());
    }

    function earnedSlashed(address _account) external view override returns (uint256) {
        return _applySlashing(earned(_account), liquidityMining.startLiquidityMiningTime());
    }

    function stakeFor(address _user, uint256 _amount) external override onlyStaking {
        require(_amount > 0, "LMS: Amount should be greater than 0");

        _stake(_user, _amount);
    }

    function stake(uint256 _amount) external override nonReentrant updateReward(_msgSender()) {
        require(_amount > 0, "LMS: Amount should be greater than 0");

        IERC20(stakingToken).safeTransferFrom(_msgSender(), address(this), _amount);
        _stake(_msgSender(), _amount);
    }

    function withdraw(uint256 _amount) public override nonReentrant updateReward(_msgSender()) {
        require(_amount > 0, "LMS: Amount should be greater than 0");

        uint256 userStaked = staked[_msgSender()];

        require(userStaked >= _amount, "LMS: Insufficient staked amount");

        totalStaked = totalStaked.sub(_amount);
        staked[_msgSender()] = userStaked.sub(_amount);
        IERC20(stakingToken).safeTransfer(_msgSender(), _amount);

        emit Withdrawn(_msgSender(), _amount);
    }

    function getReward() public override nonReentrant updateReward(_msgSender()) {
        uint256 reward = _rewards[_msgSender()];

        if (reward > 0) {
            delete _rewards[_msgSender()];

            uint256 bmiStakingProfit =
                _getSlashed(reward, liquidityMining.startLiquidityMiningTime());
            uint256 profit = reward.sub(bmiStakingProfit);

            // transfer slashed bmi to the bmiStaking and add them to the pool
            rewardsToken.safeTransfer(address(bmiStaking), bmiStakingProfit);
            bmiStaking.addToPool(bmiStakingProfit);

            // transfer bmi profit to the user
            rewardsToken.safeTransfer(_msgSender(), profit);

            rewardTokensLocked = rewardTokensLocked.sub(reward);

            emit RewardPaid(_msgSender(), profit);
        }
    }

    function restake() external override nonReentrant updateReward(_msgSender()) {
        uint256 reward = _rewards[_msgSender()];

        if (reward > 0) {
            delete _rewards[_msgSender()];

            rewardsToken.transfer(address(bmiStaking), reward);
            bmiStaking.stakeFor(_msgSender(), reward);

            rewardTokensLocked = rewardTokensLocked.sub(reward);

            emit RewardRestaked(_msgSender(), reward);
        }
    }

    function exit() external override {
        withdraw(staked[_msgSender()]);
        getReward();
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

    function _stake(address _user, uint256 _amount) internal {
        totalStaked = totalStaked.add(_amount);
        staked[_user] = staked[_user].add(_amount);

        emit Staked(_user, _amount);
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
