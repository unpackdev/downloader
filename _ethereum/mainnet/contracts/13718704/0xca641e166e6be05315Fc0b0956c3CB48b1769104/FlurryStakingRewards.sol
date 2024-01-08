// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./StringsUpgradeable.sol";
import "./SafeERC20Upgradeable.sol";
import "./IERC20Upgradeable.sol";

import "./IFlurryStakingRewards.sol";
import "./BaseRewards.sol";
import "./ILPStakingRewards.sol";
import "./IRhoTokenRewards.sol";

/**
 * @title Rewards for FLURRY Token Stakers
 * @notice This reward scheme enables users to stake (lock) FLURRY tokens to earn more FLURRY tokens
 * @notice FlurryToken is an ERC20 * BEP20 compliant token with 18 decimals.
 * @dev all FLURRY rewards in the flurry protocol are held by this contract
 * @dev This contract is also used by LPStakingRewards & RhoTokenRewards for claiming FLURRY
 */
contract FlurryStakingRewards is IFlurryStakingRewards, BaseRewards {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    /// @dev events
    event FlurryRewardsRateChanged(uint256 blockNumber, uint256 rewardsRate);
    event RewardsEndUpdated(uint256 blockNumber, uint256 rewardsEndBlock);
    event Staked(address indexed user, uint256 blockNumber, uint256 amount);
    event Withdrawn(address indexed user, uint256 blockNumber, uint256 amount);
    event TotalStakesChanged(uint256 totalStakes);

    /// @dev roles of other rewards contracts
    bytes32 public constant LP_TOKEN_REWARDS_ROLE = keccak256("LP_TOKEN_REWARDS_ROLE");
    bytes32 public constant RHO_TOKEN_REWARDS_ROLE = keccak256("RHO_TOKEN_REWARDS_ROLE");

    /// @dev no. of FLURRY reward per block
    uint256 public override rewardsRate;

    /// @dev last block of time lock
    uint256 public lockEndBlock;

    /// @dev block number that staking reward was last accrued at
    uint256 public lastUpdateBlock;

    /// @dev staking reward entitlement per FLURRY staked
    uint256 public rewardsPerTokenStored;

    /// @dev last block when rewards distubution end
    uint256 public rewardsEndBlock;

    IERC20Upgradeable public flurryToken;
    uint256 public override totalStakes;
    uint256 public flurryTokenOne;

    /**
     * @notice UserInfo
     * @param stake FLURRY stakes for each staker
     * @param rewardPerTokenPaid amount of reward already paid to staker per token
     * @param reward accumulated FLURRY reward
     */
    struct UserInfo {
        uint256 stake;
        uint256 rewardPerTokenPaid;
        uint256 reward;
    }
    mapping(address => UserInfo) public userInfo;

    ILPStakingRewards public override lpStakingRewards;
    IRhoTokenRewards public override rhoTokenRewards;

    /**
     * @notice initialize function is used in place of constructor for upgradeability
     * @dev Have to call initializers in the parent classes to proper initialize
     */
    function initialize(address flurryTokenAddr) external initializer notZeroAddr(flurryTokenAddr) {
        BaseRewards.__initialize();
        flurryToken = IERC20Upgradeable(flurryTokenAddr);
        flurryTokenOne = getTokenOne(flurryTokenAddr);
    }

    function totalRewardsPool() external view override returns (uint256) {
        return _totalRewardsPool();
    }

    function _totalRewardsPool() internal view returns (uint256) {
        return flurryToken.balanceOf(address(this)) - totalStakes;
    }

    function stakeOf(address user) external view override notZeroAddr(user) returns (uint256) {
        return userInfo[user].stake;
    }

    function rewardOf(address user) external view override notZeroAddr(user) returns (uint256) {
        return _earned(user);
    }

    function claimableRewardOf(address user) external view override notZeroAddr(user) returns (uint256) {
        return block.number >= lockEndBlock ? _earned(user) : 0;
    }

    function lastBlockApplicable() internal view returns (uint256) {
        return _lastBlockApplicable(rewardsEndBlock);
    }

    function rewardsPerToken() public view override returns (uint256) {
        if (totalStakes == 0) return rewardsPerTokenStored;
        return
            rewardPerTokenInternal(
                rewardsPerTokenStored,
                lastBlockApplicable() - lastUpdateBlock,
                rewardRatePerTokenInternal(rewardsRate, flurryTokenOne, 1, totalStakes, 1)
            );
    }

    function rewardRatePerTokenStaked() external view override returns (uint256) {
        if (totalStakes == 0) return type(uint256).max;
        return rewardRatePerTokenInternal(rewardsRate, flurryTokenOne, 1, totalStakes, 1);
    }

    function updateRewardInternal() internal {
        rewardsPerTokenStored = rewardsPerToken();
        lastUpdateBlock = lastBlockApplicable();
    }

    function updateReward(address addr) internal {
        updateRewardInternal();
        if (addr != address(0)) {
            userInfo[addr].reward = _earned(addr);
            userInfo[addr].rewardPerTokenPaid = rewardsPerTokenStored;
        }
    }

    function _earned(address addr) internal view returns (uint256) {
        return
            super._earned(
                userInfo[addr].stake,
                rewardsPerToken() - userInfo[addr].rewardPerTokenPaid,
                flurryTokenOne,
                userInfo[addr].reward
            );
    }

    function setRewardsRate(uint256 newRewardsRate) external override onlyRole(DEFAULT_ADMIN_ROLE) whenNotPaused {
        updateRewardInternal();
        rewardsRate = newRewardsRate;
        emit FlurryRewardsRateChanged(block.number, rewardsRate);
    }

    function startRewards(uint256 rewardsDuration)
        external
        override
        onlyRole(DEFAULT_ADMIN_ROLE)
        whenNotPaused
        isValidDuration(rewardsDuration)
    {
        require(block.number > rewardsEndBlock, "Previous rewards period must complete before starting a new one");
        updateRewardInternal();
        lastUpdateBlock = block.number;
        rewardsEndBlock = block.number + rewardsDuration;
        emit RewardsEndUpdated(block.number, rewardsEndBlock);
    }

    function endRewards() external override onlyRole(DEFAULT_ADMIN_ROLE) whenNotPaused {
        if (rewardsEndBlock > block.number) {
            rewardsEndBlock = block.number;
            emit RewardsEndUpdated(block.number, rewardsEndBlock);
        }
    }

    function isLocked() external view override returns (bool) {
        return block.number <= lockEndBlock;
    }

    function setTimeLock(uint256 lockDuration) external override onlyRole(DEFAULT_ADMIN_ROLE) whenNotPaused {
        lockEndBlock = block.number + lockDuration;
    }

    function earlyUnlock() external override onlyRole(DEFAULT_ADMIN_ROLE) whenNotPaused {
        lockEndBlock = block.number;
    }

    function setTimeLockEndBlock(uint256 _lockEndBlock) external override onlyRole(DEFAULT_ADMIN_ROLE) whenNotPaused {
        lockEndBlock = _lockEndBlock;
    }

    function stake(uint256 amount) external override whenNotPaused nonReentrant {
        address user = _msgSender();
        // check and update
        require(amount > 0, "Cannot stake 0 tokens");
        require(flurryToken.balanceOf(user) >= amount, "Not Enough balance to stake");
        updateReward(user);
        // state change
        userInfo[user].stake += amount;
        totalStakes += amount;
        // interaction
        flurryToken.safeTransferFrom(user, address(this), amount);
        emit Staked(user, block.number, amount);
        emit TotalStakesChanged(totalStakes);
    }

    function withdraw(uint256 amount) external override whenNotPaused nonReentrant {
        _withdrawUser(_msgSender(), amount);
    }

    function _withdrawUser(address user, uint256 amount) internal {
        // check and update
        require(amount > 0, "Cannot withdraw 0 amount");
        require(userInfo[user].stake >= amount, "Exceeds staked amount");
        updateReward(user);
        // state change
        userInfo[user].stake -= amount;
        totalStakes -= amount;
        // interaction
        flurryToken.safeTransfer(user, amount);
        emit Withdrawn(user, block.number, amount);
        emit TotalStakesChanged(totalStakes);
    }

    function exit() external override whenNotPaused nonReentrant {
        _withdrawUser(_msgSender(), userInfo[_msgSender()].stake);
    }

    function claimRewardInternal(address user) internal {
        if (block.number > lockEndBlock) {
            updateReward(user);
            if (userInfo[user].reward > 0) {
                userInfo[user].reward = grantFlurryInternal(user, userInfo[user].reward);
            }
        }
    }

    function claimReward() external override whenNotPaused nonReentrant {
        require(this.claimableRewardOf(_msgSender()) > 0, "nothing to claim");
        claimRewardInternal(_msgSender());
    }

    function claimAllRewards() external override whenNotPaused nonReentrant {
        require(this.totalClaimableRewardOf(_msgSender()) > 0, "nothing to claim");
        if (address(lpStakingRewards) != address(0)) lpStakingRewards.claimAllReward(_msgSender());
        if (address(rhoTokenRewards) != address(0)) rhoTokenRewards.claimAllReward(_msgSender());
        claimRewardInternal(_msgSender());
    }

    function grantFlurry(address addr, uint256 amount) external override onlyLPOrRhoTokenRewards returns (uint256) {
        return grantFlurryInternal(addr, amount);
    }

    function grantFlurryInternal(address addr, uint256 amount) internal notZeroAddr(addr) returns (uint256) {
        if (amount <= _totalRewardsPool()) {
            flurryToken.safeTransfer(addr, amount);
            emit RewardPaid(addr, amount);
            return 0;
        }
        emit NotEnoughBalance(addr, amount);
        return amount;
    }

    function isStakeholder(address addr) external view notZeroAddr(addr) returns (bool) {
        return userInfo[addr].stake > 0;
    }

    function sweepERC20Token(address token, address to) external override onlyRole(SWEEPER_ROLE) {
        require(token != address(flurryToken), "!safe");
        _sweepERC20Token(token, to);
    }

    function totalRewardOf(address user) external view override notZeroAddr(user) returns (uint256) {
        uint256 otherRewards;

        if (address(lpStakingRewards) != address(0)) otherRewards += lpStakingRewards.totalRewardOf(user);
        if (address(rhoTokenRewards) != address(0)) otherRewards += rhoTokenRewards.totalRewardOf(user);
        return otherRewards + this.rewardOf(user);
    }

    function totalClaimableRewardOf(address user) external view override notZeroAddr(user) returns (uint256) {
        uint256 otherRewards;

        if (address(lpStakingRewards) != address(0)) otherRewards += lpStakingRewards.totalClaimableRewardOf(user);
        if (address(rhoTokenRewards) != address(0)) otherRewards += rhoTokenRewards.totalClaimableRewardOf(user);
        return otherRewards + this.claimableRewardOf(user);
    }

    function setRhoTokenRewardContract(address _rhoTokenRewardAddr)
        external
        override
        onlyRole(DEFAULT_ADMIN_ROLE)
        notZeroAddr(_rhoTokenRewardAddr)
        whenNotPaused
    {
        rhoTokenRewards = IRhoTokenRewards(_rhoTokenRewardAddr);
    }

    function setLPRewardsContract(address lpRewardsAddr)
        external
        override
        onlyRole(DEFAULT_ADMIN_ROLE)
        notZeroAddr(lpRewardsAddr)
        whenNotPaused
    {
        lpStakingRewards = ILPStakingRewards(lpRewardsAddr);
    }

    // modified from OZ onlyRole(), allowing the checking of multiple roles
    modifier onlyLPOrRhoTokenRewards() {
        require(
            hasRole(LP_TOKEN_REWARDS_ROLE, _msgSender()) || hasRole(RHO_TOKEN_REWARDS_ROLE, _msgSender()),
            string(
                abi.encodePacked(
                    "AccessControl: account ",
                    StringsUpgradeable.toHexString(uint160(_msgSender()), 20),
                    " is missing role ",
                    StringsUpgradeable.toHexString(uint256(LP_TOKEN_REWARDS_ROLE), 32),
                    " or role ",
                    StringsUpgradeable.toHexString(uint256(RHO_TOKEN_REWARDS_ROLE), 32)
                )
            )
        );
        _;
    }
}
