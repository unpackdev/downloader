// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./ILendingPoolV2.sol";
import "./ILendingPoolAddressesProviderV2.sol";
import "./IAaveIncentivesController.sol";
import "./IAaveProtocolDataProviderV2.sol";
import "./IStakedToken.sol";

/// @title Oh! Finance AaveV2 Helper
/// @notice Helper functions to interact with the AaveV2
/// @dev https://docs.aave.com/portal/
abstract contract OhAaveV2Helper {
    using SafeERC20 for IERC20;

    /// @notice Get the AaveV2 aToken for a given underlying
    /// @param dataProvider The AaveV2 Data Provider
    /// @param underlying The underlying token to check
    /// @return The address of the associated aToken
    function aToken(address dataProvider, address underlying) internal view returns (address) {
        (address aTokenAddress, , ) = IAaveProtocolDataProviderV2(dataProvider).getReserveTokensAddresses(underlying);
        return aTokenAddress;
    }

    /// @notice Get the AaveV2 Lending Pool
    /// @param addressProvider The AaveV2 Address Provider
    /// @return The address of the AaveV2 Lending Pool
    function lendingPool(address addressProvider) internal view returns (address) {
        return ILendingPoolAddressesProviderV2(addressProvider).getLendingPool();
    }

    /// @notice Get the cooldown timestamp start for this contract
    /// @param stakedToken The address of stkAAVE
    /// @return The timestamp the cooldown started on
    function stakersCooldown(address stakedToken) internal view returns (uint256) {
        uint256 stakerCooldown = IStakedToken(stakedToken).stakersCooldowns(address(this));
        return stakerCooldown;
    }

    /// @notice Get the cooldown window in seconds for unstaking stkAAVE to AAVE before cooldown expires
    /// @dev 864000 - 10 days
    /// @param stakedToken The address of stkAAVE
    /// @return The cooldown seconds to wait before unstaking
    function cooldownWindow(address stakedToken) internal view returns (uint256) {
        uint256 window = IStakedToken(stakedToken).COOLDOWN_SECONDS();
        return window;
    }

    /// @notice Get the unstake window in seconds for unstaking stkAAVE to AAVE after cooldown passes
    /// @dev 172800 - 2 days
    /// @param stakedToken The address of stkAAVE
    /// @return The unstake window seconds we have to unwrap stkAAVE to AAVE
    function unstakingWindow(address stakedToken) internal view returns (uint256) {
        uint256 window = IStakedToken(stakedToken).UNSTAKE_WINDOW();
        return window;
    }

    /// @notice Initiate a claim cooldown to swap stkAAVE to AAVE
    /// @param stakedToken The address of stkAAVE
    function cooldown(address stakedToken) internal {
        IStakedToken(stakedToken).cooldown();
    }

    /// @notice Redeem an amount of stkAAVE for AAVE
    /// @param stakedToken The address of stkAAVE
    /// @param amount The amount of stkAAVE to redeem
    function redeem(address stakedToken, uint256 amount) internal {
        IStakedToken(stakedToken).redeem(address(this), amount);
    }

    /// @notice Claim stkAAVE from the AaveV2 Incentive Controller
    /// @dev Claim all available rewards, return if none available
    /// @param incentivesController The AaveV2 Incentive Controller
    /// @param token The aToken to claim rewards for
    function claimRewards(address incentivesController, address token) internal {
        address[] memory tokens = new address[](1);
        tokens[0] = token;

        uint256 rewards = IAaveIncentivesController(incentivesController).getRewardsBalance(tokens, address(this));

        if (rewards > 0) {
            IAaveIncentivesController(incentivesController).claimRewards(tokens, rewards, address(this));
        }
    }

    /// @notice Lend underlying to Aave V2 Lending Pool, receive aTokens
    /// @param pool The AaveV2 Lending Pool
    /// @param underlying The underlying ERC20 to lend
    /// @param amount The amount of underlying to lend
    function lend(
        address pool,
        address underlying,
        uint256 amount
    ) internal {
        IERC20(underlying).safeIncreaseAllowance(pool, amount);
        ILendingPoolV2(pool).deposit(
            underlying,
            amount,
            address(this),
            0 // referral code
        );
    }

    /// @notice Reclaim underlying by sending aTokens to Aave V2 Lending Pool
    /// @param pool The AaveV2 Lending Pool
    /// @param token The aToken to redeem for underlying
    /// @param amount The amount of aTokens to send
    function reclaim(
        address pool,
        address token,
        uint256 amount
    ) internal returns (uint256) {
        uint256 balance = IERC20(token).balanceOf(address(this));
        IERC20(token).safeIncreaseAllowance(pool, amount);
        uint256 withdrawn = ILendingPoolV2(pool).withdraw(token, amount, address(this));
        require(withdrawn == amount || withdrawn == balance, "AaveV2: Withdraw failed");
        return withdrawn;
    }
}
