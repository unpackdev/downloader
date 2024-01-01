// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

import "./BaseStrategy.sol";
import "./IYVault.sol";

import "./FixedPointMathLib.sol";

/// @title GenericYVaultStrategy
/// @author Adapted from https://github.com/Grandthrax/yearn-steth-acc/blob/master/contracts/Strategy.sol
/// @notice `YearnStrategy` supplies an underlying token into a generic Yearn Vault,
/// earning the Yearn Vault's yield

contract YearnStrategy is BaseStrategy {
    using SafeTransferLib for address;

    ////////////////////////////////////////////////////////////////
    ///                        CONSTANTS                         ///
    ////////////////////////////////////////////////////////////////
    uint256 internal constant DEGRADATION_COEFFICIENT = 10 ** 18;

    ////////////////////////////////////////////////////////////////
    ///                         ERRORS                           ///
    ////////////////////////////////////////////////////////////////
    error NotEnoughFundsToInvest();

    ////////////////////////////////////////////////////////////////
    ///                         EVENTS                           ///
    ////////////////////////////////////////////////////////////////

    /// @notice Emitted when underlying asset is deposited into the Yearn Vault
    event Invested(address indexed strategy, uint256 amountInvested);

    /// @notice Emitted when the `requestedShares` are divested from the Yearn Vault
    event Divested(address indexed strategy, uint256 requestedShares, uint256 amountDivested);

    /// @notice Emitted when the strategy's max single trade value is updated
    event MaxSingleTradeUpdated(uint256 maxSingleTrade);

    /// @notice Emitted when the strategy's min single trade value is updated
    event MinSingleTradeUpdated(uint256 minSingleTrade);

    // @dev `keccak256(bytes("Invested(uint256,uint256)"))`.
    uint256 internal constant _INVESTED_EVENT_SIGNATURE =
        0xc3f75dfc78f6efac88ad5abb5e606276b903647d97b2a62a1ef89840a658bbc3;

    // @dev `keccak256(bytes("Divested(uint256,uint256,uint256)"))`.
    uint256 internal constant _DIVESTED_EVENT_SIGNATURE =
        0xf44b6ecb6421462dee6400bd4e3bb57864c0f428d0f7e7d49771f9fd7c30d4fa;

    // @dev `keccak256(bytes("MaxSingleTradeUpdated(uint256)"))`.
    uint256 internal constant _MAX_SINGLE_TRADE_UPDATED_EVENT_SIGNATURE =
        0xe8b08f84dc067e4182670384e9556796d3a831058322b7e55f9ddb3ec48d7c10;

    // @dev `keccak256(bytes("MinSingleTradeUpdated(uint256)"))`.
    uint256 internal constant _MIN_SINGLE_TRADE_UPDATED_EVENT_SIGNATURE =
        0x70bc59027d7d0bba6fbf38b995e26c84f6c1805fc3ead71ec1d7ebeb7d76399b;

    ////////////////////////////////////////////////////////////////
    ///            STRATEGY GLOBAL STATE VARIABLES               ///
    ////////////////////////////////////////////////////////////////

    /// @notice The Yearn Vault the strategy interacts with
    IYVault public yVault;
    /// @notice Maximum trade size within the strategy
    uint256 public maxSingleTrade;
    /// @notice Minimun trade size within the strategy
    uint256 public minSingleTrade;

    ////////////////////////////////////////////////////////////////
    ///                     INITIALIZATION                       ///
    ////////////////////////////////////////////////////////////////
    constructor() initializer {}

    /// @notice Initialize the Strategy
    /// @param _vault The address of the MaxApy Vault associated to the strategy
    /// @param _keepers The addresses of the keepers to be added as valid keepers to the strategy
    /// @param _strategyName the name of the strategy
    /// @param _yVault The Yearn Finance vault this strategy will interact with
    function initialize(
        IMaxApyVault _vault,
        address[] calldata _keepers,
        bytes32 _strategyName,
        address _strategist,
        IYVault _yVault
    ) public initializer {
        __BaseStrategy_init(_vault, _keepers, _strategyName, _strategist);
        yVault = _yVault;

        /// Approve Yearn Vault to transfer underlying
        underlyingAsset.safeApprove(address(_yVault), type(uint256).max);

        maxSingleTrade = 1_000 * 1e18;
        minSingleTrade = 1e16;
    }

    ////////////////////////////////////////////////////////////////
    ///                 STRATEGY CONFIGURATION                   ///
    ////////////////////////////////////////////////////////////////

    /// @notice Sets the maximum single trade amount allowed
    /// @param _maxSingleTrade The new maximum single trade value
    function setMaxSingleTrade(uint256 _maxSingleTrade) external checkRoles(ADMIN_ROLE) {
        assembly {
            // if _maxSingleTrade == 0 revert()
            if iszero(_maxSingleTrade) {
                // Throw the `InvalidZeroAmount` error
                mstore(0x00, 0xdd484e70)
                revert(0x1c, 0x04)
            }
            sstore(maxSingleTrade.slot, _maxSingleTrade)
            // Emit the `MaxSingleTradeUpdated` event
            mstore(0x00, _maxSingleTrade)
            log1(0x00, 0x20, _MAX_SINGLE_TRADE_UPDATED_EVENT_SIGNATURE)
        }
    }

    /// @notice Sets the minimum single trade amount allowed
    /// @param _minSingleTrade The new minimum single trade value
    function setMinSingleTrade(uint256 _minSingleTrade) external checkRoles(ADMIN_ROLE) {
        assembly {
            // if _minSingleTrade == 0 revert()
            if iszero(_minSingleTrade) {
                // Throw the `InvalidZeroAmount` error
                mstore(0x00, 0xdd484e70)
                revert(0x1c, 0x04)
            }
            sstore(minSingleTrade.slot, _minSingleTrade)
            // Emit the `MinSingleTradeUpdated` event
            mstore(0x00, _minSingleTrade)
            log1(0x00, 0x20, _MIN_SINGLE_TRADE_UPDATED_EVENT_SIGNATURE)
        }
    }

    ////////////////////////////////////////////////////////////////
    ///                    VIEW FUNCTIONS                        ///
    ////////////////////////////////////////////////////////////////

    /// @notice Provide an accurate estimate for the total amount of assets
    /// (principle + return) that this Strategy is currently managing,
    /// denominated in terms of `underlyingAsset` tokens.
    /// This total should be "realizable" e.g. the total value that could
    /// *actually* be obtained from this Strategy if it were to divest its
    /// entire position based on current on-chain conditions.
    /// @dev Care must be taken in using this function, since it relies on external
    /// systems, which could be manipulated by the attacker to give an inflated
    /// (or reduced) value produced by this function, based on current on-chain
    /// conditions (e.g. this function is possible to influence through
    /// flashloan attacks, oracle manipulations, or other DeFi attack
    /// mechanisms).
    /// @return The estimated total assets in this Strategy.
    function estimatedTotalAssets() public view returns (uint256) {
        return _underlyingBalance() + _shareValue(_shareBalance());
    }

    /**
     *  @notice Provides an indication of whether this strategy is currently "active"
     *  in that it is managing an active position, or will manage a position in
     *  the future. This should correlate to `harvest()` activity, so that Harvest
     *  events can be tracked externally by indexing agents.
     *  @return True if the strategy is actively managing a position.
     */
    function isActive() public view returns (bool) {
        return estimatedTotalAssets() != 0;
    }

    ////////////////////////////////////////////////////////////////
    ///                 INTERNAL CORE FUNCTIONS                  ///
    ////////////////////////////////////////////////////////////////
    /// @notice Perform any Strategy unwinding or other calls necessary to capture the
    /// "free return" this Strategy has generated since the last time its core
    /// position(s) were adjusted. Examples include unwrapping extra rewards.
    /// This call is only used during "normal operation" of a Strategy, and
    /// should be optimized to minimize losses as much as possible.
    /// @dev This method returns any realized profits and/or realized losses
    /// incurred, and should return the total amounts of profits/losses/debt
    /// payments (in MaxApy Vault's `underlyingAsset` tokens) for the MaxApy Vault's accounting (e.g.
    /// `underlyingAsset.balanceOf(this) >= debtPayment + profit`).
    ///
    /// `debtOutstanding` will be 0 if the Strategy is not past the configured
    /// debt limit, otherwise its value will be how far past the debt limit
    /// the Strategy is. The Strategy's debt limit is configured in the MaxApy Vault.
    ///
    /// NOTE: `debtPayment` should be less than or equal to `debtOutstanding`.
    ///       It is okay for it to be less than `debtOutstanding`, as that
    ///       should only be used as a guide for how much is left to pay back.
    ///       Payments should be made to minimize loss from slippage, debt,
    ///       withdrawal fees, etc.
    /// See `MaxApyVault.debtOutstanding()`.
    function _prepareReturn(uint256 debtOutstanding, uint256)
        internal
        override
        returns (uint256 profit, uint256 loss, uint256 debtPayment)
    {
        // Fetch initial strategy state
        uint256 underlyingBalance = _underlyingBalance();
        uint256 shares = _shareBalance();
        uint256 totalAssets = underlyingBalance + _shareValue(shares);

        uint256 debt;
        assembly {
            // debt = vault.strategies(address(this)).strategyTotalDebt;
            mstore(0x00, 0xbdb9f8b3)
            mstore(0x20, address())
            if iszero(call(gas(), sload(vault.slot), 0, 0x1c, 0x24, 0x00, 0x20)) { revert(0x00, 0x04) }
            debt := mload(0x00)
        }

        if (totalAssets >= debt) {
            // Strategy has obtained profit or holds more funds than it should
            // considering the current debt

            profit = totalAssets - debt;

            uint256 amountToWithdraw = profit + debtOutstanding;

            // Check if underlying funds held in the strategy are enough to cover withdrawal.
            // If not, divest from yearn
            if (amountToWithdraw > underlyingBalance) {
                uint256 expectedAmountToWithdraw = Math.min(maxSingleTrade, amountToWithdraw - underlyingBalance);

                uint256 sharesToWithdraw = _sharesForAmount(expectedAmountToWithdraw);

                uint256 withdrawn = _divest(sharesToWithdraw);

                // Account for loss occured on withdrawal from yearn
                if (withdrawn < expectedAmountToWithdraw) {
                    unchecked {
                        loss = expectedAmountToWithdraw - withdrawn;
                    }
                }
                // Overwrite underlyingBalance with the proper amount after withdrawing
                underlyingBalance = _underlyingBalance();
            }

            assembly {
                // Net off profit and loss
                switch lt(profit, loss)
                // if (profit < loss)
                case true {
                    loss := sub(loss, profit)
                    profit := 0
                }
                case false {
                    profit := sub(profit, loss)
                    loss := 0
                }
            }
            /*          // Net off profit and loss
            if (profit >= loss) {
                // Profit gets reduced by the loss amount incurred
                profit -= loss;
                loss = 0;
            } else {
                // Loss gets reduced by the profit amount obtained
                loss -= profit;
                profit = 0;
            } */

            // `profit` + `debtOutstanding` must be <= `underlyingBalance`. Prioritise profit first
            if (profit > underlyingBalance) {
                // Profit is prioritised. In this case, no `debtPayment` will be reported
                profit = underlyingBalance;
            } else if (amountToWithdraw > underlyingBalance) {
                // same as `profit` + `debtOutstanding` > `underlyingBalance`
                // Extract debt payment from divested amount
                unchecked {
                    debtPayment = underlyingBalance - profit;
                }
            } else {
                debtPayment = debtOutstanding;
            }
        } else {
            assembly {
                loss := sub(debt, totalAssets)
            }
        }
    }

    /// @notice Performs any adjustments to the core position(s) of this Strategy given
    /// what change the MaxApy Vault made in the "investable capital" available to the
    /// Strategy.
    /// @dev Note that all "free capital" (capital not invested) in the Strategy after the report
    /// was made is available for reinvestment. This number could be 0, and this scenario should be handled accordingly.
    function _adjustPosition(uint256, uint256 minOutputAfterInvestment) internal override {
        uint256 toInvest = _underlyingBalance();
        if (toInvest > minSingleTrade) {
            toInvest = Math.min(maxSingleTrade, toInvest);
            _invest(toInvest, minOutputAfterInvestment);
        }
    }

    /// @notice Invests `amount` of underlying, depositing it in the Yearn Vault
    /// @param amount The amount of underlying to be deposited in the vault
    /// @param minOutputAfterInvestment minimum expected output after `_invest()` (designated in Yearn receipt tokens)
    /// @return depositedAmount The amount of shares received, in terms of underlying
    function _invest(uint256 amount, uint256 minOutputAfterInvestment) internal returns (uint256 depositedAmount) {
        // Don't do anything if amount to invest is 0
        if (amount == 0) return 0;

        uint256 underlyingBalance = _underlyingBalance();
        if (amount > underlyingBalance) revert NotEnoughFundsToInvest();

        // Invested amount will be a maximum of `maxSingleTrade`
        amount = Math.min(maxSingleTrade, amount);

        uint256 shares = yVault.deposit(amount);
        
        assembly ("memory-safe") {
            // if (shares < minOutputAfterInvestment)
            if lt(shares, minOutputAfterInvestment) {
                // throw the `MinOutputAmountNotReached` error
                mstore(0x00, 0xf7c67a48)
                revert(0x1c, 0x04)
            }
        }

        depositedAmount = _shareValue(shares);

        assembly {
            // Emit the `Invested` event
            mstore(0x00, amount)
            log2(0x00, 0x20, _INVESTED_EVENT_SIGNATURE, address())
        }
    }

    /// @notice Divests amount `shares` from Yearn Vault
    /// Note that divesting from Yearn could potentially cause loss (set to 0.01% as default in
    /// the Vault implementation), so the divested amount might actually be different from
    /// the requested `shares` to divest
    /// @dev care should be taken, as the `shares` parameter is *not* in terms of underlying,
    /// but in terms of yvault shares
    /// @return withdrawn the total amount divested, in terms of underlying asset
    function _divest(uint256 shares) internal returns (uint256 withdrawn) {
        // return uint256 withdrawn = yVault.withdraw(shares);
        assembly {
            // store selector and parameters in memory
            mstore(0x00, 0x2e1a7d4d)
            mstore(0x20, shares)
            // call yVault.withdraw(shares)
            if iszero(call(gas(), sload(yVault.slot), 0, 0x1c, 0x24, 0x00, 0x20)) { revert(0x00, 0x04) }
            withdrawn := mload(0x00)

            // Emit the `Divested` event
            mstore(0x00, shares)
            mstore(0x20, withdrawn)
            log2(0x00, 0x40, _DIVESTED_EVENT_SIGNATURE, address())
        }
    }

    /// @notice Liquidate up to `amountNeeded` of MaxApy Vault's `underlyingAsset` of this strategy's positions,
    /// irregardless of slippage. Any excess will be re-invested with `_adjustPosition()`.
    /// @dev This function should return the amount of MaxApy Vault's `underlyingAsset` tokens made available by the
    /// liquidation. If there is a difference between `amountNeeded` and `liquidatedAmount`, `loss` indicates whether the
    /// difference is due to a realized loss, or if there is some other sitution at play
    /// (e.g. locked funds) where the amount made available is less than what is needed.
    /// NOTE: The invariant `liquidatedAmount + loss <= amountNeeded` should always be maintained
    /// @param amountNeeded amount of MaxApy Vault's `underlyingAsset` needed to be liquidated
    /// @return liquidatedAmount the actual liquidated amount
    /// @return loss difference between the expected amount needed to reach `amountNeeded` and the actual liquidated amount

    function _liquidatePosition(uint256 amountNeeded)
        internal
        override
        returns (uint256 liquidatedAmount, uint256 loss)
    {
        uint256 underlyingBalance = _underlyingBalance();
        // If underlying balance currently held by strategy is not enough to cover
        // the requested amount, we divest from the Yearn Vault
        if (underlyingBalance < amountNeeded) {
            uint256 amountToWithdraw;
            unchecked {
                amountToWithdraw = amountNeeded - underlyingBalance;
            }
            uint256 shares = _sharesForAmount(amountToWithdraw);
            uint256 withdrawn = _divest(shares);
            assembly {
                // if withdrawn < amountToWithdraw
                if lt(withdrawn, amountToWithdraw) { loss := sub(amountToWithdraw, withdrawn) }
            }
        }
        // liquidatedAmount = amountNeeded - loss;
        assembly {
            liquidatedAmount := sub(amountNeeded, loss)
        }
    }

    /// @notice Liquidates everything and returns the amount that got freed.
    /// @dev This function is used during emergency exit instead of `_prepareReturn()` to
    /// liquidate all of the Strategy's positions back to the MaxApy Vault.
    function _liquidateAllPositions() internal override returns (uint256 amountFreed) {
        _divest(_shareBalance());
        amountFreed = _underlyingBalance();
    }

    ////////////////////////////////////////////////////////////////
    ///                 INTERNAL VIEW FUNCTIONS                  ///
    ////////////////////////////////////////////////////////////////

    /// @notice Determines the current value of `shares`.
    /// @dev if sqrt(yVault.totalAssets()) >>> 1e39, this could potentially revert
    /// @return returns the estimated amount of underlying computed from shares `shares`
    function _shareValue(uint256 shares) internal view returns (uint256) {
        uint256 vaultTotalSupply;
        assembly {
            // get yVault.totalSupply()
            mstore(0x00, 0x18160ddd)
            if iszero(staticcall(gas(), sload(yVault.slot), 0x1c, 0x04, 0x00, 0x20)) { revert(0x00, 0x04) }
            vaultTotalSupply := mload(0x00)
        }
        if (vaultTotalSupply == 0) return shares;

        return Math.mulDiv(shares, _freeFunds(), vaultTotalSupply);
    }

    /// @notice Determines how many shares depositor of `amount` of underlying would receive.
    /// @return shares returns the estimated amount of shares computed in exchange for underlying `amount`
    function _sharesForAmount(uint256 amount) internal view returns (uint256 shares) {
        uint256 freeFunds = _freeFunds();
        assembly {
            // if freeFunds != 0 return amount
            if gt(freeFunds, 0) {
                // get yVault.totalSupply()
                mstore(0x00, 0x18160ddd)
                if iszero(staticcall(gas(), sload(yVault.slot), 0x1c, 0x04, 0x00, 0x20)) { revert(0x00, 0x04) }
                let totalSupply := mload(0x00)

                // Overflow check equivalent to require(totalSupply == 0 || amount <= type(uint256).max / totalSupply)
                if iszero(iszero(mul(totalSupply, gt(amount, div(not(0), totalSupply))))) { revert(0, 0) }

                shares := div(mul(amount, totalSupply), freeFunds)
            }
        }
    }

    /// @notice Calculates the yearn vault free funds considering the locked profit
    /// @return returns the computed yearn vault free funds
    function _freeFunds() internal view returns (uint256) {
        return yVault.totalAssets() - _calculateLockedProfit();
    }

    /// @notice Calculates the yearn vault locked profit i.e. how much profit is locked and cant be withdrawn
    /// @return lockedProfit returns the computed locked profit value
    function _calculateLockedProfit() internal view returns (uint256 lockedProfit) {
        assembly {
            let _yVault := sload(yVault.slot)

            // get yVault.lastReport()
            mstore(0x00, 0xc3535b52)
            if iszero(staticcall(gas(), _yVault, 0x1c, 0x04, 0x00, 0x20)) { revert(0x00, 0x04) }
            let lastReport := mload(0x00)
            // get yVault.lockedProfitDegradation()
            mstore(0x00, 0x42232716)
            if iszero(staticcall(gas(), _yVault, 0x1c, 0x04, 0x00, 0x20)) { revert(0x00, 0x04) }
            let lockedProfitDegradation := mload(0x00)

            // Check overflow
            if gt(lastReport, timestamp()) { revert(0, 0) }

            //temporal value to save gas
            let lockedFundsRatio := sub(timestamp(), lastReport)

            // Overflow check equivalent to require(lockedProfitDegradation == 0 || lockedFundsRatio <= type(uint256).max / lockedProfitDegradation)
            if iszero(iszero(mul(lockedProfitDegradation, gt(lockedFundsRatio, div(not(0), lockedProfitDegradation)))))
            {
                revert(0, 0)
            }

            lockedFundsRatio := mul(lockedFundsRatio, lockedProfitDegradation)

            //if (lockedFundsRatio < DEGRADATION_COEFFICIENT)
            if lt(lockedFundsRatio, DEGRADATION_COEFFICIENT) {
                // get yVault.lockedProfit()
                mstore(0x00, 0x44b81396)
                if iszero(staticcall(gas(), _yVault, 0x1c, 0x04, 0x00, 0x20)) { revert(0x00, 0x04) }
                lockedProfit := mload(0x00)

                // Overflow check equivalent to require(lockedProfit == 0 || lockedFundsRatio <= type(uint256).max / lockedProfit)
                if iszero(iszero(mul(lockedProfit, gt(lockedFundsRatio, div(not(0), lockedProfit))))) { revert(0, 0) }

                //return lockedProfit - ((lockedFundsRatio * lockedProfit) / DEGRADATION_COEFFICIENT);
                lockedProfit := sub(lockedProfit, div(mul(lockedFundsRatio, lockedProfit), DEGRADATION_COEFFICIENT))
            }
        }
    }

    /// @notice Returns the current strategy's amount of yearn vault shares
    /// @return _balance balance the strategy's balance of yearn vault shares
    function _shareBalance() internal view returns (uint256 _balance) {
        assembly {
            // return yVault.balanceOf(address(this));
            mstore(0x00, 0x70a08231)
            mstore(0x20, address())
            if iszero(staticcall(gas(), sload(yVault.slot), 0x1c, 0x24, 0x00, 0x20)) { revert(0x00, 0x04) }
            _balance := mload(0x00)
        }
    }
}
