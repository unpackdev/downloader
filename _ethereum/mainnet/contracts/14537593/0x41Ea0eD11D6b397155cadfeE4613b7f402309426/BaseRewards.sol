//SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

/**
 * @title BaseRewards Abstract Contract
 * @notice Abstract Contract to be inherited by LPStakingReward, StakingReward and RhoTokenReward.
 * Implements the core logic as internal functions.
 * *** Note: avoid using `super` keyword to avoid confusion because the derived contracts use multiple inheritance ***
 */

import "./MathUpgradeable.sol";
import "./SafeERC20Upgradeable.sol";
import "./IERC20Upgradeable.sol";
import "./IERC20MetadataUpgradeable.sol";
import "./AccessControlEnumerableUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";

abstract contract BaseRewards is AccessControlEnumerableUpgradeable, PausableUpgradeable, ReentrancyGuardUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    // events
    event RewardPaid(address indexed user, uint256 reward);
    event NotEnoughBalance(address indexed user, uint256 withdrawalAmount);

    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant SWEEPER_ROLE = keccak256("SWEEPER_ROLE");

    function __initialize() internal {
        AccessControlEnumerableUpgradeable.__AccessControlEnumerable_init();
        ReentrancyGuardUpgradeable.__ReentrancyGuard_init();
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    function getTokenOne(address token) internal view returns (uint256) {
        return 10**IERC20MetadataUpgradeable(token).decimals();
    }

    /**
     * @notice Calculate accrued but unclaimed reward for a user
     * @param _tokenBalance balance of the rhoToken, OR staking ammount of LP/FLURRY
     * @param _netRewardPerToken accumulated reward minus the reward already paid to user, on a per token basis
     * @param _tokenOne decimal of the token
     * @param accumulatedReward accumulated reward of the user
     * @return claimable reward of the user
     */
    function _earned(
        uint256 _tokenBalance,
        uint256 _netRewardPerToken,
        uint256 _tokenOne,
        uint256 accumulatedReward
    ) internal pure returns (uint256) {
        return ((_tokenBalance * _netRewardPerToken) / _tokenOne) + accumulatedReward;
    }

    /**
     * @notice Rewards are accrued up to this block (put aside in rewardsPerTokenPaid)
     * @return min(The current block # or last rewards accrual block #)
     */
    function _lastBlockApplicable(uint256 _rewardsEndBlock) internal view returns (uint256) {
        return MathUpgradeable.min(block.number, _rewardsEndBlock);
    }

    function rewardRatePerTokenInternal(
        uint256 rewardRate,
        uint256 tokenOne,
        uint256 allocPoint,
        uint256 totalToken,
        uint256 totalAllocPoint
    ) internal pure returns (uint256) {
        return (rewardRate * tokenOne * allocPoint) / (totalToken * totalAllocPoint);
    }

    function rewardPerTokenInternal(
        uint256 accruedRewardsPerToken,
        uint256 blockDelta,
        uint256 rewardRatePerToken
    ) internal pure returns (uint256) {
        return accruedRewardsPerToken + blockDelta * rewardRatePerToken;
    }

    /**
     * admin functions to withdraw random token transfer to this contract
     */
    function _sweepERC20Token(address token, address to) internal notZeroTokenAddr(token) {
        IERC20Upgradeable tokenToSweep = IERC20Upgradeable(token);
        tokenToSweep.safeTransfer(to, tokenToSweep.balanceOf(address(this)));
    }

    /** Pausable */
    function pause() external onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() external onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    modifier notZeroAddr(address addr) {
        require(addr != address(0), "address is zero");
        _;
    }

    modifier notZeroTokenAddr(address addr) {
        require(addr != address(0), "token address is zero");
        _;
    }

    modifier isValidDuration(uint256 rewardDuration) {
        require(rewardDuration > 0, "Reward duration cannot be zero");
        _;
    }
}
