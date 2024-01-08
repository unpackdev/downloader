// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./SafeMath.sol";
import "./Math.sol";
import "./IStrategy.sol";
import "./TransferHelper.sol";
import "./OhStrategy.sol";
import "./OhCurve3PoolHelper.sol";
import "./OhCurve3PoolStrategyStorage.sol";

/// @title Oh! Finance Curve 3Pool Strategy
/// @notice Standard Curve 3Pool LP + Gauge Single Underlying Strategy
/// @notice 3Pool Underlying, in order: (DAI, USDC, USDT)
contract OhCurve3PoolStrategy is OhStrategy, OhCurve3PoolStrategyStorage, OhCurve3PoolHelper, IStrategy {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    /// @notice Initialize the Curve 3Pool Strategy Logic
    constructor() initializer {
        assert(registry() == address(0));
        assert(bank() == address(0));
        assert(underlying() == address(0));
        assert(reward() == address(0));
    }

    /// @notice Initialize the Curve 3Pool Strategy Proxy
    /// @param registry_ Address of the Registry
    /// @param bank_ Address of the Bank
    /// @param underlying_ Underlying (DAI, USDC, USDT)
    /// @param derivative_ 3CRV LP Token
    /// @param reward_ CRV Gov Token
    /// @param pool_ Address of the Curve 3Pool
    /// @param gauge_ Curve Gauge, Staking Contract
    /// @param mintr_ Curve Mintr, Rewards Contract
    /// @param index_ Underlying 3Pool Index
    function initializeCurve3PoolStrategy(
        address registry_,
        address bank_,
        address underlying_,
        address derivative_,
        address reward_,
        address pool_,
        address gauge_,
        address mintr_,
        uint256 index_
    ) public initializer {
        initializeStrategy(registry_, bank_, underlying_, derivative_, reward_);
        initializeCurve3PoolStorage(pool_, gauge_, mintr_, index_);
    }

    // calculate the total underlying balance
    function investedBalance() public view override returns (uint256) {
        return calcWithdraw(pool(), stakedBalance(), int128(index()));
    }

    // amount of 3CRV staked in the Gauge
    function stakedBalance() public view returns (uint256) {
        return staked(gauge());
    }

    /// @notice Execute the Curve 3Pool Strategy
    /// @dev Compound CRV Yield, Add Liquidity, Stake into Gauge
    function invest() external override onlyBank {
        _compound();
        _deposit();
    }

    /// @notice Withdraw an amount of underlying from Curve 3Pool Strategy
    /// @param amount Amount of Underlying tokens to withdraw
    /// @dev Unstake from Gauge, Remove Liquidity
    function withdraw(uint256 amount) external override onlyBank returns (uint256) {
        uint256 withdrawn = _withdraw(msg.sender, amount);
        return withdrawn;
    }

    /// @notice Withdraw all underlying from Curve 3Pool Strategy
    /// @dev Unstake from Gauge, Remove Liquidity
    function withdrawAll() external override onlyBank {
        uint256 invested = investedBalance();
        _withdraw(msg.sender, invested);
    }

    /// @dev Compound rewards into underlying through liquidation
    /// @dev Claim Rewards from Mintr, sell CRV for USDC
    function _compound() internal {
        // claim available CRV rewards
        claim(mintr(), gauge());
        uint256 rewardAmount = rewardBalance();
        if (rewardAmount > 0) {
            liquidate(reward(), underlying(), rewardAmount);
        }
    }

    // deposit underlying into 3Pool to get 3CRV and stake into Gauge
    function _deposit() internal {
        uint256 amount = underlyingBalance();
        if (amount > 0) {
            // add liquidity to 3Pool to receive 3CRV
            addLiquidity(pool(), underlying(), index(), amount, 1);
            // stake all received in the 3CRV gauge
            stake(gauge(), derivative(), derivativeBalance());
        }
    }

    // withdraw underlying tokens from the protocol
    // TODO: Double check withdrawGauge math, TransferHelper
    function _withdraw(address recipient, uint256 amount) internal returns (uint256) {
        if (amount == 0) {
            return 0;
        }

        uint256 invested = investedBalance();
        uint256 staked = stakedBalance();

        // calculate % of supply ownership
        uint256 supplyShare = amount.mul(1e18).div(invested);

        // find amount to unstake in 3CRV
        uint256 unstakeAmount = Math.min(staked, supplyShare.mul(staked).div(1e18));

        // find amount to redeem in underlying
        uint256 redeemAmount = Math.min(invested, supplyShare.mul(invested).div(1e18));

        // unstake from Gauge & remove liquidity from Pool
        unstake(gauge(), unstakeAmount);
        removeLiquidity(pool(), index(), redeemAmount, unstakeAmount);

        // withdraw to bank
        uint256 withdrawn = TransferHelper.safeTokenTransfer(recipient, underlying(), amount);
        return withdrawn;
    }
}
