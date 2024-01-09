// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "./SafeERC20.sol";

import "./OwnableUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";

contract TokenfyLPStaking is OwnableUpgradeable, PausableUpgradeable, ReentrancyGuardUpgradeable {
    using SafeERC20 for IERC20;

    struct UserInfo {
        uint256 amount;
        uint256 rewardDebt;
    }

    // Tokens
    IERC20 public tokenfyToken;
    IERC20 public lpToken;

    // Reward calculation settings
    uint256 public startBlock;
    uint256 public accTokenPerShare;
    uint256 public endBlock;
    uint256 public lastRewardBlock;
    uint256 public rewardPerBlock;
    uint256 public constant PRECISION = 10**12;

    // Stakeholder balances
    mapping(address => UserInfo) public userInfo;

    event Stake(address indexed user, uint256 amount, uint256 claimedRewards);
    event Claim(address indexed user, uint256 claimedRewards);
    event Unstake(address indexed user, uint256 amount, uint256 claimedRewards);

    event AdminRewardWithdraw(uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 amount);
    event RewardsChange(uint256 rewardPerBlock, uint256 endBlock);

    function initialize() public initializer {
        __Ownable_init();
        __ReentrancyGuard_init();
        __Pausable_init_unchained();
    }

    /**
     * @dev stakes LP tokens. If stakeholder has pending rewards, sends reward tokens
     */
    function stake(uint256 amount) external nonReentrant {
        require(amount > 0, "TokenfyLPStaking: invalid amount");

        updatePool();

        uint256 claimableRewards;

        if (userInfo[msg.sender].amount > 0) {
            claimableRewards =
                ((userInfo[msg.sender].amount * accTokenPerShare) / PRECISION) -
                userInfo[msg.sender].rewardDebt;

            if (claimableRewards > 0) {
                tokenfyToken.safeTransfer(msg.sender, claimableRewards);
            }
        }

        lpToken.safeTransferFrom(msg.sender, address(this), amount);

        userInfo[msg.sender].amount += amount;
        userInfo[msg.sender].rewardDebt = (userInfo[msg.sender].amount * accTokenPerShare) / PRECISION;

        emit Stake(msg.sender, amount, claimableRewards);
    }

    /**
     * @dev claims pending rewards
     */
    function claim() external nonReentrant {
        updatePool();

        uint256 claimableRewards = ((userInfo[msg.sender].amount * accTokenPerShare) / PRECISION) -
            userInfo[msg.sender].rewardDebt;

        require(claimableRewards > 0, "TokenfyLPStaking: no rewards");

        userInfo[msg.sender].rewardDebt = (userInfo[msg.sender].amount * accTokenPerShare) / PRECISION;
        tokenfyToken.safeTransfer(msg.sender, claimableRewards);

        emit Claim(msg.sender, claimableRewards);
    }

    /**
     * @dev withdraws all LP tokens without rewards
     */
    function emergencyWithdraw() external nonReentrant whenPaused {
        uint256 userBalance = userInfo[msg.sender].amount;

        require(userBalance != 0, "TokenfyLPStaking: balance is 0");

        userInfo[msg.sender].amount = 0;
        userInfo[msg.sender].rewardDebt = 0;

        lpToken.safeTransfer(msg.sender, userBalance);

        emit EmergencyWithdraw(msg.sender, userBalance);
    }

    /**
     * @dev unstakes staked LP tokens. If stakeholder has pending rewards, sends reward tokens
     */
    function unstake(uint256 amount) external nonReentrant {
        require(
            (userInfo[msg.sender].amount >= amount) && (amount > 0),
            "TokenfyLPStaking: invalid amount"
        );

        updatePool();

        uint256 claimableRewards = ((userInfo[msg.sender].amount * accTokenPerShare) / PRECISION) -
            userInfo[msg.sender].rewardDebt;

        userInfo[msg.sender].amount -= amount;
        userInfo[msg.sender].rewardDebt = (userInfo[msg.sender].amount * accTokenPerShare) / PRECISION;

        lpToken.safeTransfer(msg.sender, amount);

        if (claimableRewards > 0) {
            tokenfyToken.safeTransfer(msg.sender, claimableRewards);
        }

        emit Unstake(msg.sender, amount, claimableRewards);
    }

    /**
     * @dev withdraws rewards from the contract
     */
    function adminRewardWithdraw(uint256 amount) external onlyOwner {
        tokenfyToken.safeTransfer(msg.sender, amount);

        emit AdminRewardWithdraw(amount);
    }

    /**
     * @dev pauses the contract
     */
    function pause() external onlyOwner whenNotPaused {
        _pause();
    }

    /**
     * @dev unpauses the contract
     */
    function unpause() external onlyOwner whenPaused {
        _unpause();
    }

    /**
     * @dev sets up initial rewards distribution
     */
    function setupRewards(
        address _lpToken,
        address _tokenfyToken,
        uint256 _rewardPerBlock,
        uint256 _startBlock,
        uint256 _endBlock
    ) external onlyOwner {
        lpToken = IERC20(_lpToken);
        tokenfyToken = IERC20(_tokenfyToken);

        rewardPerBlock = _rewardPerBlock;
        startBlock = _startBlock;
        endBlock = _endBlock;

        lastRewardBlock = _startBlock;
    }

    /**
     * @dev updates reward distribution
     */
    function updateRewardPerBlockAndEndBlock(uint256 newRewardPerBlock, uint256 newEndBlock) external onlyOwner {
        if (block.number >= startBlock) {
            updatePool();
        }
        require(newEndBlock > block.number, "TokenfyLPStaking: New endBlock must be after current block");
        require(newEndBlock > startBlock, "TokenfyLPStaking: New endBlock must be after start block");

        endBlock = newEndBlock;
        rewardPerBlock = newRewardPerBlock;

        emit RewardsChange(newRewardPerBlock, newEndBlock);
    }

    /**
     * @dev calculates current staked LP balance
     */
    function totalLP() external view returns (uint256) {
        return lpToken.balanceOf(address(this));
    }

    /**
     * @dev calculates current tokenfy balance
     */
    function totalTokenfy() external view returns (uint256) {
        return tokenfyToken.balanceOf(address(this));
    }

    /**
     * @dev calculates staking rewards
     */
    function stakingRewards(address user) external view returns (uint256) {
        uint256 lpTokenSupply = lpToken.balanceOf(address(this));

        if ((block.number > lastRewardBlock) && (lpTokenSupply != 0)) {
            uint256 multiplier = calculateBlockMultiplier(lastRewardBlock, block.number);
            uint256 tokenReward = multiplier * rewardPerBlock;
            uint256 adjustedTokenPerShare = accTokenPerShare + (tokenReward * PRECISION) / lpTokenSupply;

            return (userInfo[user].amount * adjustedTokenPerShare) / PRECISION - userInfo[user].rewardDebt;
        } else {
            return (userInfo[user].amount * accTokenPerShare) / PRECISION - userInfo[user].rewardDebt;
        }
    }

    /**
     * @dev updates pool reward state
     */
    function updatePool() internal {
        if (block.number <= lastRewardBlock) {
            return;
        }

        uint256 lpTokenSupply = lpToken.balanceOf(address(this));

        if (lpTokenSupply == 0) {
            lastRewardBlock = block.number;
            return;
        }

        uint256 multiplier = calculateBlockMultiplier(lastRewardBlock, block.number);
        uint256 tokenReward = multiplier * rewardPerBlock;

        if (tokenReward > 0) {
            accTokenPerShare = accTokenPerShare + ((tokenReward * PRECISION) / lpTokenSupply);
        }

        if (lastRewardBlock <= endBlock) {
            lastRewardBlock = block.number;
        }
    }

    /**
     * @dev calculates block rewards multiplier
     */
    function calculateBlockMultiplier(uint256 from, uint256 to) internal view returns (uint256) {
        if (to <= endBlock) {
            return to - from;
        } else if (from >= endBlock) {
            return 0;
        } else {
            return endBlock - from;
        }
    }
}