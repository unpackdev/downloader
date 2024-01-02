// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./Address.sol";
import "./SafeERC20.sol";
import "./EnumerableMap.sol";
import "./EnumerableSet.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Pair.sol";
import "./IUniswapV2Router02.sol";

/**
 * @title AIXRevenueSharing
 * @dev A contract to stake AIX tokens and receive ETH as rewards.
 */
contract AIXRevenueSharing is Ownable, ReentrancyGuard {
    using EnumerableMap for EnumerableMap.UintToUintMap;
    using EnumerableSet for EnumerableSet.UintSet;
    using Address for address payable;
    using SafeERC20 for IERC20;

    IERC20 public immutable aix;

    uint256 public totalStaked;
    uint256 public totalBoostedStaked;
    uint256 public totalPaidRewards;
    uint256 public totalAssignedRewards;

    uint256 public currentETHPerDay;
    uint256 public accumulatedRewardPerBoostedToken;
    uint256 public lastAccumulatedRewardPerTokenUpdateTimestamp;

    bool public earlyWithdrawalAllowed;
    bool public stakePaused;

    event EarlyWithdrawalAllowedSet(bool earlyWithdrawalAllowed);
    event StakePausedSet(bool stakePaused);

    function setEarlyWithdrawalAllowed(bool _earlyWithdrawalAllowed) external onlyOwner {
        earlyWithdrawalAllowed = _earlyWithdrawalAllowed;
        emit EarlyWithdrawalAllowedSet(_earlyWithdrawalAllowed);
    }

    function setStakePaused(bool _stakePaused) external onlyOwner {
        stakePaused = _stakePaused;
        emit StakePausedSet(_stakePaused);
    }

    uint256 public lastStakeId = 0;

    // mainnet 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
    // goerli 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
    IUniswapV2Router02 public immutable uniswapRouter;

    address public controller;
    event ControllerSet(address controller);
    function setController(address _controller) external onlyOwner {
        controller = _controller;
        emit ControllerSet(_controller);
    }
    uint256 public maxETHPerDay;
    event MaxETHPerDaySet(uint256 maxETHPerDay);
    function setMaxETHPerDay(uint256 _maxETHPerDay) external onlyOwner {
        maxETHPerDay = _maxETHPerDay;
        emit MaxETHPerDaySet(_maxETHPerDay);
    }

    // mainnet 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2
    // goerli 0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6
    address public immutable weth;

    struct Stake {
        address user;
        uint256 stakedAmount;
        uint256 boostedStakedAmount;
        uint256 period;
        uint256 unstakeTimestamp;
        uint256 lastRewardPerToken;
        uint256 totalPaidRewards;  // for statistics
    }

    mapping(address => EnumerableSet.UintSet) private _userStakes;
    mapping(uint256 => Stake) public stakes;

    EnumerableMap.UintToUintMap private _stakePeriodBoosts;

    event EmergencyWithdrawn(
        address indexed user,
        uint256 indexed stakeId,
        uint256 amount
    );
    event TransferETH(address indexed to, uint256 value);
    event Staked(
        address indexed user,
        uint256 indexed stakeId,
        uint256 stakedAmount,
        uint256 boostedAmount,
        uint256 unstakeTimestamp,
        uint256 lastRewardPerToken
    );
    event Withdrawn(
        address indexed user,
        uint256 indexed stakeId,
        uint256 amount,
        uint256 newStakedAmount,
        uint256 newBoostedStakedAmount,
        uint256 newUnstakeTimestamp,
        bool isRemoved
    );
    event RewardPaid(
        address indexed user,
        uint256 indexed stakeId,
        uint256 reward,
        uint256 lastRewardPerToken,
        uint256 stakeTotalPaidRewards,
        uint256 totalPaidRewards
    );
    event CurrentETHPerDaySet(uint256 currentETHPerDay);
    event EthReceived(uint256 amount);
    event EthToOwner(uint256 amount);

    struct StakePeriodBoost {
        uint256 period;
        uint256 boost;
    }

    event StakePeriodBoostsSet(uint256 period, uint256 boost);
    event StakePeriodBoostsRemoved(uint256 period);
    event TotalStakedChanged(uint256 totalStaked, uint256 totalBoostedStaked);

    /**
     * @dev Initializes the contract with the AIX token address.
     * @param _aix The AIX token contract address.
     */
    constructor(
        IERC20 _aix,
        IUniswapV2Router02 _uniswapRouter,
        address _weth,
        uint256 _maxETHPerDay
    ) {
        aix = _aix;
        uniswapRouter = _uniswapRouter;
        weth = _weth;
        maxETHPerDay = _maxETHPerDay;
    }

    function setStakePeriodBoosts(StakePeriodBoost[] memory _newStakePeriodBoosts) external onlyOwner {
        for (uint256 i = 0; i < _newStakePeriodBoosts.length; ++i) {
            StakePeriodBoost memory _stakePeriodBoost = _newStakePeriodBoosts[i];
            if (_stakePeriodBoost.boost > 0) {
                _stakePeriodBoosts.set(_stakePeriodBoost.period, _stakePeriodBoost.boost);
                emit StakePeriodBoostsSet(_stakePeriodBoost.period, _stakePeriodBoost.boost);
            } else {
                _stakePeriodBoosts.remove(_stakePeriodBoost.period);
                emit StakePeriodBoostsRemoved(_stakePeriodBoost.period);
            }
        }
    }

    event AccumulatedRewardPerBoostedTokenUpdated(
        uint256 accumulatedRewardPerBoostedToken,
        uint256 lastAccumulatedRewardPerTokenUpdateTimestamp
    );

    function _updateAccumulatedRewardPerToken() internal {
        if (totalBoostedStaked > 0) {
            uint256 assignedRewards = currentETHPerDay *
                (block.timestamp - lastAccumulatedRewardPerTokenUpdateTimestamp) / 1 days;
            totalAssignedRewards += assignedRewards;
            accumulatedRewardPerBoostedToken += 1e18 * assignedRewards / totalBoostedStaked;
        }
        lastAccumulatedRewardPerTokenUpdateTimestamp = block.timestamp;
        emit AccumulatedRewardPerBoostedTokenUpdated(
            accumulatedRewardPerBoostedToken,
            lastAccumulatedRewardPerTokenUpdateTimestamp
        );
    }

    function setCurrentETHPerDay(uint256 _currentETHPerDay) external {
        require(msg.sender == controller || msg.sender == owner(), "AIXRevenueSharing: Access denied");
        require(_currentETHPerDay <= maxETHPerDay, "AIXRevenueSharing: too high");
        _updateAccumulatedRewardPerToken();
        currentETHPerDay = _currentETHPerDay;
        emit CurrentETHPerDaySet(_currentETHPerDay);
    }

    function _payUserReward(address account, uint256 stakeId) internal returns(uint256) {
        Stake storage _stake = stakes[stakeId];
        uint256 reward = _stake.boostedStakedAmount *
            (accumulatedRewardPerBoostedToken - _stake.lastRewardPerToken) / 1e18;
        _stake.lastRewardPerToken = accumulatedRewardPerBoostedToken;
        _stake.totalPaidRewards += reward;
        totalPaidRewards += reward;
        emit RewardPaid(
            account,
            stakeId,
            reward,
            _stake.lastRewardPerToken,
            _stake.totalPaidRewards,
            totalPaidRewards
        );
        return reward;
    }

    /**
     * @dev Public function to stake AIX tokens.
     * @param amount The amount of AIX tokens to stake.
     */
    function stake(uint256 amount, uint256 period) external nonReentrant {
        require(!stakePaused, "AIXRevenueSharing: Staking is paused");
        require(amount >= 1e18, "AIXRevenueSharing: Cannot stake too small");
        uint256 stakeId = ++lastStakeId;

        uint256 boost = getStakePeriodBoost(period);

        _updateAccumulatedRewardPerToken();
        totalStaked += amount;
        uint256 boostedAmount = amount * boost / 10000;
        totalBoostedStaked += boostedAmount;

        stakes[stakeId] = Stake({
            user: msg.sender,
            stakedAmount: amount,
            boostedStakedAmount: boostedAmount,
            period: period,
            unstakeTimestamp: block.timestamp + period,
            lastRewardPerToken: accumulatedRewardPerBoostedToken,
            totalPaidRewards: 0
        });
        _userStakes[msg.sender].add(stakeId);
        aix.safeTransferFrom(msg.sender, address(this), amount);

        emit Staked({
            user: msg.sender,
            stakeId: stakeId,
            stakedAmount: amount,
            boostedAmount: boostedAmount,
            unstakeTimestamp: block.timestamp + period,
            lastRewardPerToken: accumulatedRewardPerBoostedToken
        });
        emit TotalStakedChanged(totalStaked, totalBoostedStaked);
    }

    event EarlyUnstake(address indexed user, uint256 indexed stakeId);

    /**
     * @notice Unstake and relock the rest.
     * @param amount The amount of AIX tokens to withdraw.
     */
    function unstake(
        uint256 stakeId,
        uint256 amount
    ) external nonReentrant {
        require(amount > 0, "AIXRevenueSharing: Cannot withdraw 0");
        Stake storage _stake = stakes[stakeId];
        require(_stake.stakedAmount >= amount, "AIXRevenueSharing: Withdraw amount exceeds balance");

        require(_userStakes[msg.sender].contains(stakeId), "AIXRevenueSharing: Stake does not belong to user");

        _updateAccumulatedRewardPerToken();

        uint256 reward = 0;
        if (_stake.unstakeTimestamp < block.timestamp) {
            reward = _payUserReward(msg.sender, stakeId);
        } else {
            require(earlyWithdrawalAllowed, "AIXRevenueSharing: too early");
            emit EarlyUnstake(msg.sender, stakeId);
            _stake.lastRewardPerToken = accumulatedRewardPerBoostedToken;  // rewards are not paid
        }

        totalStaked -= amount;
        _stake.stakedAmount -= amount;

        totalBoostedStaked -= _stake.boostedStakedAmount;
        if (_stake.stakedAmount == 0) {
            _userStakes[msg.sender].remove(stakeId);
            _stake.boostedStakedAmount = 0;
        } else {  // relock the rest
            _stake.boostedStakedAmount = _stake.stakedAmount * getStakePeriodBoost(_stake.period) / 10000;
            totalBoostedStaked += _stake.boostedStakedAmount;
            _stake.unstakeTimestamp = block.timestamp + _stake.period;
        }

        aix.safeTransfer(msg.sender, amount);
        safeTransferETH(msg.sender, reward);
        emit Withdrawn(
            msg.sender,
            stakeId,
            amount,
            _stake.stakedAmount,
            _stake.boostedStakedAmount,
            _stake.unstakeTimestamp,
            _stake.stakedAmount == 0
        );
        emit TotalStakedChanged(totalStaked, totalBoostedStaked);
    }

    // @notice WARNING! Understand what you are doing before calling this function.
    function emergencyWithdraw(uint256 stakeId) external nonReentrant {
        Stake storage _stake = stakes[stakeId];

        require(earlyWithdrawalAllowed || _stake.unstakeTimestamp < block.timestamp,
            "AIXRevenueSharing: too early");
        require(_userStakes[msg.sender].contains(stakeId), "AIXRevenueSharing: Stake does not belong to user");

        _updateAccumulatedRewardPerToken();
        uint256 amount = _stake.stakedAmount;
        totalStaked -= _stake.stakedAmount;
        totalBoostedStaked -= _stake.boostedStakedAmount;
        _stake.stakedAmount = 0;
        _stake.boostedStakedAmount = 0;
        _userStakes[msg.sender].remove(stakeId);

        aix.safeTransfer(msg.sender, amount);
        emit EmergencyWithdrawn(msg.sender, stakeId, amount);
        emit TotalStakedChanged(totalStaked, totalBoostedStaked);
    }

    event UnstakeTimestampUpdated(address indexed user, uint256 indexed stakeId, uint256 unstakeTimestamp);

    function claimRewards(uint256 stakeId) external nonReentrant {
        require(_userStakes[msg.sender].contains(stakeId), "AIXRevenueSharing: Stake does not belong to user");
        _updateAccumulatedRewardPerToken();
        uint256 reward = _payUserReward(msg.sender, stakeId);
        stakes[stakeId].unstakeTimestamp = block.timestamp + stakes[stakeId].period;
        emit UnstakeTimestampUpdated(msg.sender, stakeId, stakes[stakeId].unstakeTimestamp);
        safeTransferETH(msg.sender, reward);
    }

    function restakeRewards(
        uint256 stakeId,
        uint256 minAmountOut  // set to 0 to disable, in case of front-running we will use it
    ) external nonReentrant {
        require(!stakePaused, "AIXRevenueSharing: Staking is paused");
        require(_userStakes[msg.sender].contains(stakeId), "AIXRevenueSharing: Stake does not belong to user");
        _updateAccumulatedRewardPerToken();
        Stake storage _stake = stakes[stakeId];
        uint256 reward = _stake.boostedStakedAmount *
            (accumulatedRewardPerBoostedToken - _stake.lastRewardPerToken) / 1e18;
        require(reward > 0, "No rewards to restake");
        _stake.lastRewardPerToken = accumulatedRewardPerBoostedToken;
        totalPaidRewards += reward;
        _stake.totalPaidRewards += reward;

        uint256 aixAmount = _convertEthToAix(reward, minAmountOut);

        _stake.stakedAmount += aixAmount;
        totalBoostedStaked -= _stake.boostedStakedAmount;
        _stake.boostedStakedAmount = _stake.stakedAmount * getStakePeriodBoost(_stake.period) / 10000;
        totalBoostedStaked += _stake.boostedStakedAmount;
        totalStaked += aixAmount;
        _stake.unstakeTimestamp = block.timestamp + _stake.period;
        emit Restaked(
            msg.sender,
            stakeId,
            aixAmount,
            reward,
            _stake.stakedAmount,
            _stake.boostedStakedAmount,
            _stake.unstakeTimestamp
        );
        emit TotalStakedChanged(totalStaked, totalBoostedStaked);
    }

    event Restaked(
        address indexed user,
        uint256 indexed stakeId,
        uint256 amount,
        uint256 reward,
        uint256 stakedAmount,
        uint256 boostedStakedAmount,
        uint256 unstakeTimestamp
    );

    function _convertEthToAix(uint256 ethAmount, uint256 minAmountOut) internal returns (uint256) {
        address[] memory path = new address[](2);
        path[0] = weth;
        path[1] = address(aix);
        uint256[] memory amounts = uniswapRouter.swapExactETHForTokens{value: ethAmount}(
            minAmountOut,
            path,
            address(this),
            block.timestamp
        );
        return amounts[1];
    }

    function safeTransferETH(address to, uint256 value) internal {
        if (value > 0) {
            (bool success, ) = to.call{value: value}("");
            require(success, "ETH transfer failed");
        }
        emit TransferETH(to, value);
    }

    function recoverEth(uint256 amount) external onlyOwner {
        safeTransferETH(owner(), amount);
        emit EthToOwner(amount);
    }

    receive() external payable {
        emit EthReceived(msg.value);
    }

    // ---- view functions ----

    struct StakeInfo {
        address user;
        uint256 stakeId;
        uint256 stakedAmount;
        uint256 boostedStakedAmount;
        uint256 period;
        uint256 unstakeTimestamp;
        uint256 lastRewardPerToken;
        uint256 totalPaidRewards;  // for statistics
        uint256 apr;
        uint256 availableReward;
        uint256 poolShare;  // 100% = 1e18
    }

    function getAPRForPeriod(uint256 period) public view returns (uint256) {
        uint256 boost = getStakePeriodBoost(period);
        return calculateAPRForBoost(boost);
    }

    function getAvailableStakeReward(uint256 stakeId) public view returns (uint256) {
        Stake storage _stake = stakes[stakeId];
        require(totalBoostedStaked != 0, "Invalid contract state");
        uint256 _accumulatedRewardPerBoostedToken = accumulatedRewardPerBoostedToken +
            1e18 * currentETHPerDay *
            (block.timestamp - lastAccumulatedRewardPerTokenUpdateTimestamp) / 1 days / totalBoostedStaked;
        uint256 reward = _stake.boostedStakedAmount *
            (_accumulatedRewardPerBoostedToken - _stake.lastRewardPerToken) / 1e18;
        return reward;
    }

    function getAllStakesAvailableRewards(address account) public view returns (uint256) {
        uint256 result = 0;
        for (uint256 i = 0; i < _userStakes[account].length(); ++i) {
            result += getAvailableStakeReward(_userStakes[account].at(i));
        }
        return result;
    }

    /**
     * @dev Returns the boost factor for a given staking period.
     * @param period The staking period in seconds.
     * @return The boost factor for this staking period.
     */
    function getStakePeriodBoost(uint256 period) public view returns (uint256) {
        require(_stakePeriodBoosts.contains(period), "Staking period does not exist");
        return _stakePeriodBoosts.get(period);
    }

    /**
     * @dev Returns all staking periods with their boost factors.
     */
    function getAllStakesPeriod() public view returns (StakePeriodBoost[] memory) {
        StakePeriodBoost[] memory result = new StakePeriodBoost[](_stakePeriodBoosts.length());
        for (uint256 i = 0; i < _stakePeriodBoosts.length(); ++i) {
            (uint256 period, uint256 boost) = _stakePeriodBoosts.at(i);
            result[i].period = period;
            result[i].boost = boost;
        }
        return result;
    }

    struct StakePeriodBoostAPR {
        uint256 period;
        uint256 boost;
        uint256 apr;
    }

    function getAllStakesPeriodBoostAPR() public view returns (StakePeriodBoostAPR[] memory) {
        StakePeriodBoostAPR[] memory result = new StakePeriodBoostAPR[](_stakePeriodBoosts.length());
        for (uint256 i = 0; i < _stakePeriodBoosts.length(); ++i) {
            (uint256 period, uint256 boost) = _stakePeriodBoosts.at(i);
            result[i].period = period;
            result[i].boost = boost;
            result[i].apr = calculateAPRForBoost(boost);
        }
        return result;
    }

    /**
     * @notice Returns the APR for a given boost factor.
     * @param _boost The boost factor in 1/10000 units.
     * @return The APR for this boost factor (in 1/10000 units).
     */
    function calculateAPRForBoost(
        uint256 _boost
    ) public view returns (uint256) {
        address[] memory path = new address[](2);
        path[0] = weth;
        path[1] = address(aix);
        uint256 smallOne = 1e12;  // to avoid slippage
        uint256[] memory amounts = uniswapRouter.getAmountsOut(smallOne, path);
        uint256 ethInAixPrice = amounts[1];
        if (totalBoostedStaked == 0) {
            return type(uint256).max;
        }
        return _boost * currentETHPerDay * 365 * ethInAixPrice / smallOne / totalBoostedStaked;
    }

    function getUserStakeIds(address account) public view returns (uint256[] memory) {
        uint256[] memory result = new uint256[](_userStakes[account].length());
        for (uint256 i = 0; i < _userStakes[account].length(); ++i) {
            result[i] = _userStakes[account].at(i);
        }
        return result;
    }

    function getStake(uint256 stakeId) public view returns (StakeInfo memory) {
        Stake memory _stake = stakes[stakeId];
        require(_stake.user != address(0), "Stake does not exist");
        return StakeInfo({
            user: _stake.user,
            stakeId: stakeId,
            stakedAmount: _stake.stakedAmount,
            boostedStakedAmount: _stake.boostedStakedAmount,
            period: _stake.period,
            unstakeTimestamp: _stake.unstakeTimestamp,
            lastRewardPerToken: _stake.lastRewardPerToken,
            totalPaidRewards: _stake.totalPaidRewards,
            apr: calculateAPRForBoost(getStakePeriodBoost(_stake.period)),
            availableReward: getAvailableStakeReward(stakeId),
            poolShare: _stake.boostedStakedAmount * 1e18 / totalBoostedStaked
        });
    }

    function getUserStakes(address account) external view returns (StakeInfo[] memory) {
        uint256[] memory stakeIds = getUserStakeIds(account);
        StakeInfo[] memory result = new StakeInfo[](stakeIds.length);
        for (uint256 i = 0; i < stakeIds.length; ++i) {
            result[i] = getStake(stakeIds[i]);
        }
        return result;
    }
}
