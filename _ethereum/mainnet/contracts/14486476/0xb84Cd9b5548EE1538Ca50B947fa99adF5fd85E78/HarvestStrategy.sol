// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.11;

import "./ClaimFullSingleRewardStrategy.sol";

import "./IHarvestVault.sol";
import "./IHarvestPool.sol";

/**
 * @notice Harvest strategy implementation
 */
contract HarvestStrategy is ClaimFullSingleRewardStrategy {
    using SafeERC20 for IERC20;

    /* ========== STATE VARIABLES ========== */

    /// @notice Harvest vault contract
    IHarvestVault public immutable vault;
    /// @notice Harvest pool contract
    IHarvestPool public immutable pool;

    /* ========== CONSTRUCTOR ========== */

    /**
     * @notice Set initial values
     * @param _farm Farm contract
     * @param _vault Vault contract
     * @param _pool Pool contract
     * @param _underlying Underlying asset
     */
    constructor(
        IERC20 _farm,
        IHarvestVault _vault,
        IHarvestPool _pool,
        IERC20 _underlying
    )
        BaseStrategy(_underlying, 1, 0, 0, 0, false, false) 
        ClaimFullSingleRewardStrategy(_farm) 
    {
        require(address(_vault) != address(0), "HarvestStrategy::constructor: Vault address cannot be 0");
        require(address(_pool) != address(0), "HarvestStrategy::constructor: Pool address cannot be 0");
        vault = _vault;
        pool = _pool;
    }

    /* ========== VIEWS ========== */

    /**
     * @notice Get strategy balance
     * @return Strategy balance
     */
    function getStrategyBalance() public view override returns(uint128) {
        uint256 fTokenBalance = pool.balanceOf(address(this));
        return SafeCast.toUint128(_getfTokenValue(fTokenBalance));
    }

    /* ========== OVERRIDDEN FUNCTIONS ========== */

    /**
     * @dev Claim strategy reward
     * @return Reward amount
     */
    function _claimStrategyReward() internal override returns(uint128) {
        // claim
        uint256 rewardBefore = rewardToken.balanceOf(address(this));
        pool.getReward();
        uint256 rewardAmount = rewardToken.balanceOf(address(this)) - rewardBefore;

        // add already claimed rewards
        rewardAmount += strategies[self].pendingRewards[address(rewardToken)];

        return SafeCast.toUint128(rewardAmount);
    }

    /**
     * @dev Deposit
     * @param amount Amount to deposit
     * @return Deposited amount
     */
    function _deposit(uint128 amount, uint256[] memory) internal override returns(uint128) {

        // deposit underlying
        underlying.safeApprove(address(vault), amount);
        uint256 fTokenBefore = vault.balanceOf(address(this));
        vault.deposit(amount);
        uint256 fTokenNew = vault.balanceOf(address(this)) - fTokenBefore;
        _resetAllowance(underlying, address(vault));

        // stake fTokens
        vault.approve(address(pool), fTokenNew);
        pool.stake(fTokenNew);

        return SafeCast.toUint128(_getfTokenValue(fTokenNew));
    }

    /**
     * @dev Withdraw
     * @param shares Shares to withdraw
     * @return Withdrawn amount
     */
    function _withdraw(uint128 shares, uint256[] memory) internal override returns(uint128) {
        uint256 fTokensTotal = pool.balanceOf(address(this));

        uint256 fWithdrawAmount = (fTokensTotal * shares) / strategies[self].totalShares;

        // withdraw staked fTokens from pool
        pool.withdraw(fWithdrawAmount);

        // withdraw fTokens from vault
        uint256 undelyingBefore = underlying.balanceOf(address(this));
        vault.withdraw(fWithdrawAmount);
        uint256 undelyingWithdrawn = underlying.balanceOf(address(this)) - undelyingBefore;

        return SafeCast.toUint128(undelyingWithdrawn);
    }

    /**
     * @dev Emergency withdraw
     */
    function _emergencyWithdraw(address, uint256[] calldata) internal override {
        pool.exit();
        vault.withdraw(vault.balanceOf(address(this)));
    }

    /* ========== PRIVATE FUNCTIONS ========== */

    /**
     * @dev Return value of fTokens in the underlying asset
     * @param fTokenAmount Amount of fTokens
     * @return value in the underlying asset
     */
    function _getfTokenValue(uint256 fTokenAmount) private view returns(uint256) {
        if (fTokenAmount == 0)
            return 0;

        uint256 vaultTotal = vault.underlyingBalanceWithInvestment();
        return (vaultTotal * fTokenAmount) / vault.totalSupply();
    }
}