// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

import "./BaseStrategy.sol";
import "./IConvexBooster.sol";
import "./IConvexRewards.sol";
import "./IUniswap.sol";
import "./ICurve.sol";
import "./IWETH.sol";

import "./FixedPointMathLib.sol";

/// @title ConvexdETHFrxETHStrategy
/// @author MaxApy
/// @notice `ConvexdETHFrxETHStrategy` supplies ETH into the dETH-frxETH pool in Curve, then stakes the curve LP
/// in Convex in order to maximize yield.
contract ConvexdETHFrxETHStrategy is BaseStrategy {
    using SafeTransferLib for address;

    ////////////////////////////////////////////////////////////////
    ///                        CONSTANTS                         ///
    ////////////////////////////////////////////////////////////////

    /// @notice Ethereum mainnet's CRV Token
    IERC20 public constant crv = IERC20(0xD533a949740bb3306d119CC777fa900bA034cd52);
    /// @notice Ethereum mainnet's CVX Token
    IERC20 public constant cvx = IERC20(0x4e3FBD56CD56c3e72c1403e103b45Db9da5B9D2B);
    /// @notice Ethereum mainnet's frxETH Token
    IERC20 public constant frxETH = IERC20(0x5E8422345238F34275888049021821E8E08CAa1f);
    /// @notice Main Convex's deposit contract for LP tokens
    IConvexBooster public constant convexBooster = IConvexBooster(0xF403C135812408BFbE8713b5A23a04b3D48AAE31);
    /// @notice Router to perform CRV-WETH swaps
    IRouter public router;
    /// @notice CVX-WETH pool in Curve
    ICurve public constant cvxWethPool = ICurve(0xB576491F1E6e5E62f1d8F26062Ee822B40B0E0d4);
    /// @notice Identifier for the dETH<>frxETH Convex pool
    uint256 public constant DETH_FRXETH_CONVEX_POOL_ID = 195;

    ////////////////////////////////////////////////////////////////
    ///                         ERRORS                           ///
    ////////////////////////////////////////////////////////////////
    error ConvexPoolShutdown();
    error InvalidCoinIndex();
    error NotEnoughFundsToInvest();
    error InvalidZeroAddress();
    error CurveWithdrawAdminFeesFailed();

    ////////////////////////////////////////////////////////////////
    ///                         EVENTS                           ///
    ////////////////////////////////////////////////////////////////

    /// @notice Emitted when underlying asset is deposited into Convex
    event Invested(address indexed strategy, uint256 amountInvested);

    /// @notice Emitted when the `requestedShares` are divested from Convex
    event Divested(address indexed strategy, uint256 amountDivested);

    /// @notice Emitted when the strategy's max single trade value is updated
    event MaxSingleTradeUpdated(uint256 maxSingleTrade);

    /// @notice Emitted when the min swap for crv token is updated
    event MinSwapCrvUpdated(uint256 newMinSwapCrv);

    /// @notice Emitted when the min swap for cvx token is updated
    event MinSwapCvxUpdated(uint256 newMinSwapCvx);

    /// @notice Emitted when the router is updated
    event RouterUpdated(address newRouter);

    /// @dev `keccak256(bytes("Invested(address,uint256)"))`.
    uint256 internal constant _INVESTED_EVENT_SIGNATURE =
        0xc3f75dfc78f6efac88ad5abb5e606276b903647d97b2a62a1ef89840a658bbc3;

    /// @dev `keccak256(bytes("Divested(address,uint256)"))`.
    uint256 internal constant _DIVESTED_EVENT_SIGNATURE =
        0x2253aebe2fe8682635bbe60d9b78df72efaf785a596910a8ad66e8c6e37584fd;

    /// @dev `keccak256(bytes("MaxSingleTradeUpdated(uint256)"))`.
    uint256 internal constant _MAX_SINGLE_TRADE_UPDATED_EVENT_SIGNATURE =
        0xe8b08f84dc067e4182670384e9556796d3a831058322b7e55f9ddb3ec48d7c10;

    /// @dev `keccak256(bytes("MinSwapCrvUpdated(uint256)"))`.
    uint256 internal constant _MIN_SWAP_CRV_UPDATED_EVENT_SIGNATURE =
        0x404d194eed8bead0d0fcfd4ac84a258a6bb29cd2b997166137d0324563d0bf24;

    /// @dev `keccak256(bytes("MinSwapCvxUpdated(uint256)"))`.
    uint256 internal constant _MIN_SWAP_CVX_UPDATED_EVENT_SIGNATURE =
        0x2f0d6e0ffbe791dbba2e5087b74693bf6c57a13062b3fbd6991106624e269fc3;

    /// @dev `keccak256(bytes("RouterUpdated(address)"))`.
    uint256 internal constant _ROUTER_UPDATED_EVENT_SIGNATURE =
        0x7aed1d3e8155a07ccf395e44ea3109a0e2d6c9b29bbbe9f142d9790596f4dc80;

    ////////////////////////////////////////////////////////////////
    ///            STRATEGY GLOBAL STATE VARIABLES               ///
    ////////////////////////////////////////////////////////////////

    /*==================CONVEX-RELATED STORAGE VARIABLES==================*/
    /// @notice Main Convex's reward contract for all Convex LP pools
    IConvexRewards public convexRewardPool;
    /// @notice Convex pool's lp token address
    IERC20 public convexLpToken;
    /// @notice Main reward token for `convexRewardPool`
    IERC20 public rewardToken;

    /*==================CURVE-RELATED STORAGE VARIABLES==================*/
    /// @notice Main Curve pool for this Strategy
    ICurve public curveDEthFrxEthPool;
    /// @notice Curve's ETH-frxETH pool
    ICurve public curveEthFrxEthPool;

    /*==================STRATEGY'S STORAGE VARIABLES==================*/

    /// @notice The maximum single trade allowed in the strategy
    uint256 public maxSingleTrade;
    /// @notice miminum amount allowed to swap for CRV tokens
    uint256 public minSwapCrv;
    /// @notice miminum amount allowed to swap for CVX tokens
    uint256 public minSwapCvx;

    ////////////////////////////////////////////////////////////////
    ///                     INITIALIZATION                       ///
    ////////////////////////////////////////////////////////////////
    constructor() initializer {}

    /// @notice Initialize the Strategy
    /// @param _vault The address of the MaxApy Vault associated to the strategy
    /// @param _keepers The addresses of the keepers to be added as valid keepers to the strategy
    /// @param _strategyName the name of the strategy
    /// @param _curveDEthFrxEthPool The address of the strategy's main Curve pool, dETH-frxETH pool
    /// @param _curveEthFrxEthPool The address of Curve's ETH-frxETH pool
    /// @param _router The router address to perform swaps
    function initialize(
        IMaxApyVault _vault,
        address[] calldata _keepers,
        bytes32 _strategyName,
        address _strategist,
        ICurve _curveDEthFrxEthPool,
        ICurve _curveEthFrxEthPool,
        IRouter _router
    ) public initializer {
        __BaseStrategy_init(_vault, _keepers, _strategyName, _strategist);
 
        // Fetch convex pool data
        (, address _token,, address _crvRewards,, bool _shutdown) = convexBooster.poolInfo(DETH_FRXETH_CONVEX_POOL_ID);

        assembly {
            // Check if Convex pool is in shutdown mode
            if eq(_shutdown, 0x01) {
                // throw the `ConvexPoolShutdown` error
                mstore(0x00, 0xcff936d6)
                revert(0x1c, 0x04)
            }
        }

        convexRewardPool = IConvexRewards(_crvRewards);
        convexLpToken = IERC20(_token);
        rewardToken = IERC20(IConvexRewards(_crvRewards).rewardToken());

        // Curve init
        curveDEthFrxEthPool = _curveDEthFrxEthPool;
        curveEthFrxEthPool = _curveEthFrxEthPool;

        // Approve pools
        address(_curveDEthFrxEthPool).safeApprove(address(convexBooster), type(uint256).max);
 
        // Set router
        router = _router;
  
        address(crv).safeApprove(address(_router), type(uint256).max);
        address(cvx).safeApprove(address(cvxWethPool), type(uint256).max);
        address(frxETH).safeApprove(address(curveDEthFrxEthPool), type(uint256).max);
        address(frxETH).safeApprove(address(curveEthFrxEthPool), type(uint256).max);

        maxSingleTrade = 1_000 * 1e18;

        minSwapCrv = 1e17;
        minSwapCvx = 1e18;
    }

    ////////////////////////////////////////////////////////////////
    ///                 STRATEGY CONFIGURATION                   ///
    ////////////////////////////////////////////////////////////////

    /// @notice Sets the maximum single trade amount allowed
    /// @param _maxSingleTrade The new maximum single trade value
    function setMaxSingleTrade(uint256 _maxSingleTrade) external checkRoles(ADMIN_ROLE) {
        assembly ("memory-safe") {
            // revert if `_maxSingleTrade` is zero
            if iszero(_maxSingleTrade) {
                // throw the `InvalidZeroAmount` error
                mstore(0x00, 0xdd484e70)
                revert(0x1c, 0x04)
            }

            sstore(maxSingleTrade.slot, _maxSingleTrade) // set the max single trade value in storage

            // Emit the `MaxSingleTradeUpdated` event
            mstore(0x00, _maxSingleTrade)
            log1(0x00, 0x20, _MAX_SINGLE_TRADE_UPDATED_EVENT_SIGNATURE)
        }
    }

    /// @notice Sets the new minimum swap allowed for the CRV token
    /// @param _minSwapCrv The new minimum swap value
    function setMinSwapCrv(uint256 _minSwapCrv) external checkRoles(ADMIN_ROLE) {
        assembly ("memory-safe") {
            sstore(minSwapCrv.slot, _minSwapCrv) // set the min swap in storage

            // Emit the `MinSwapCrvUpdated` event
            mstore(0x00, _minSwapCrv)
            log1(0x00, 0x20, _MIN_SWAP_CRV_UPDATED_EVENT_SIGNATURE)
        }
    }

    /// @notice Sets the new minimum swap allowed for the CVX token
    /// @param _minSwapCvx The new minimum swap value
    function setMinSwapCvx(uint256 _minSwapCvx) external checkRoles(ADMIN_ROLE) {
        assembly ("memory-safe") {
            sstore(minSwapCvx.slot, _minSwapCvx) // set the min swap in storage

            // Emit the `MinSwapCvxUpdated` event
            mstore(0x00, _minSwapCvx)
            log1(0x00, 0x20, _MIN_SWAP_CVX_UPDATED_EVENT_SIGNATURE)
        }
    }

    /// @notice Sets the new router
    /// @dev Approval for CRV will be granted to the new router if it was not already granted
    /// @param _newRouter The new router address
    function setRouter(address _newRouter) external checkRoles(ADMIN_ROLE) {
        // Remove previous router allowance
        address(crv).safeApprove(address(router), 0);
        // Set new router allowance
        address(crv).safeApprove(_newRouter, type(uint256).max);

        assembly ("memory-safe") {
            sstore(router.slot, _newRouter) // set the new router in storage

            // Emit the `RouterUpdated` event
            mstore(0x00, _newRouter)
            log1(0x00, 0x20, _ROUTER_UPDATED_EVENT_SIGNATURE)
        }
    }

    ////////////////////////////////////////////////////////////////
    ///                    VIEW FUNCTIONS                        ///
    ////////////////////////////////////////////////////////////////

    /// @notice Provide an accurate estimate for the total amount of assets
    /// (principle + return) that this Strategy is currently managing,
    /// denominated in terms of `underlyingAsset` tokens.
    /// This total should be "realizable" e.g. the total value that could
    /// actually be obtained from this Strategy if it were to divest its
    /// entire position based on current on-chain conditions.
    /// @dev Care must be taken in using this function, since it relies on external
    /// systems, which could be manipulated by the attacker to give an inflated
    /// (or reduced) value produced by this function, based on current on-chain
    /// conditions (e.g. this function is possible to influence through
    /// flashloan attacks, oracle manipulations, or other DeFi attack
    /// mechanisms).
    /// @return The estimated total assets in this Strategy.
    function estimatedTotalAssets() public view returns (uint256) {
        return _underlyingBalance() + _lpValue(_stakedBalance(convexRewardPool));
    }

    /// @notice Provides an indication of whether this strategy is currently "active"
    /// in that it is managing an active position, or will manage a position in
    /// the future. This should correlate to `harvest()` activity, so that Harvest
    /// events can be tracked externally by indexing agents.
    /// @return True if the strategy is actively managing a position.
    function isActive() public view returns (bool) {
        return estimatedTotalAssets() != 0;
    }

    /// @notice Returns the amount of Curve LP tokens staked in Convex
    /// @return the amount of staked LP tokens
    function stakedBalance() external view returns (uint256) {
        return _stakedBalance(convexRewardPool);
    }

    ////////////////////////////////////////////////////////////////
    ///                 INTERNAL CORE FUNCTIONS                  ///
    ////////////////////////////////////////////////////////////////
    /// @notice Perform any Strategy unwinding or other calls necessary to capture the
    /// "free return" this Strategy has generated since the last time its core
    /// position(s) were adjusted. Examples include unwrapping extra rewards.
    /// This call is only used during "normal operation" of a Strategy, and
    /// should be optimized to minimize losses as much as possible.
    ///
    /// @dev This method returns any realized profits and/or realized losses
    /// incurred, and should return the total amounts of profits/losses/debt
    /// payments (in MaxApy Vault's `underlyingAsset` tokens) for the MaxApy vault's accounting (e.g.
    /// `_underlyingBalance() >= debtPayment + profit`).
    ///
    /// `debtOutstanding` will be 0 if the Strategy is not past the configured
    /// debt limit, otherwise its value will be how far past the debt limit
    /// the Strategy is. The Strategy's debt limit is configured in the MaxApy vault.
    ///
    /// NOTE: `debtPayment` should be less than or equal to `debtOutstanding`.
    ///       It is okay for it to be less than `debtOutstanding`, as that
    ///       should only be used as a guide for how much is left to pay back.
    ///       Payments should be made to minimize loss from slippage, debt,
    ///       withdrawal fees, etc.
    ///
    /// See `MaxApyVault.debtOutstanding()`.
    function _prepareReturn(uint256 debtOutstanding, uint256 minExpectedBalance)
        internal
        override
        returns (uint256 profit, uint256 loss, uint256 debtPayment)
    {
        // Cache reward pool
        IConvexRewards rewardPool = convexRewardPool;

        _unwindRewards(rewardPool);

        uint256 underlyingBalance = _underlyingBalance();

        assembly {
            // If current underlying balance after swapping does not match swap output expectations, revert
            if gt(minExpectedBalance, underlyingBalance) {
                // throw the `MinExpectedBalanceAfterSwapNotReached` error
                mstore(0x00, 0xf52187c0)
                revert(0x1c, 0x04)
            }
        }

        // not considering `_earnedRewards` to compute `totalAssets` as they have already been realized
        uint256 totalAssets = underlyingBalance + _lpValue(_stakedBalance(rewardPool));

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

            uint256 amountToWithdraw;

            assembly {
                profit := sub(totalAssets, debt)
                amountToWithdraw := add(profit, debtOutstanding)
            }

            // Check if underlying funds held in the strategy are enough to cover withdrawal.
            // If not, divest from Convex
            if (amountToWithdraw > underlyingBalance) {
                uint256 expectedAmountToWithdraw = Math.min(maxSingleTrade, amountToWithdraw - underlyingBalance);

                uint256 lpToWithdraw = _lpForAmount(expectedAmountToWithdraw);

                uint256 withdrawn = _divest(lpToWithdraw);

                assembly {
                    // Account for loss occured on withdrawal from Convex
                    if lt(withdrawn, expectedAmountToWithdraw) {
                        // if (withdrawn < expectedAmountToWithdraw)
                        loss := sub(expectedAmountToWithdraw, withdrawn) // loss = expectedAmountToWithdraw - withdrawn;
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

            // `profit` + `debtOutstanding` must be <= `underlyingBalance`. Prioritise profit first
            if (profit > underlyingBalance) {
                // Profit is prioritised. In this case, no `debtPayment` will be reported
                profit = underlyingBalance;
            } else if (amountToWithdraw > underlyingBalance) {
                // same as `profit` + `debtOutstanding` > `underlyingBalance`
                // Keep profit amount and reduce the expected debtPayment from `debtOutstanding` to the following substraction
                unchecked {
                    debtPayment = underlyingBalance - profit;
                }
            } else {
                debtPayment = debtOutstanding;
            }
        } else {
            assembly {
                /// Strategy has incurred loss
                loss := sub(debt, totalAssets)
            }
        }
    }

    /// @notice Performs any adjustments to the core position(s) of this Strategy given
    /// what change the MaxApy Vault made in the "investable capital" available to the
    /// Strategy.
    /// @dev Note that all "free capital" (capital not invested) in the Strategy after the report
    /// was made is available for reinvestment. This number could be 0, and this scenario should be handled accordingly.
    /// Also note that other implementations might use the debtOutstanding param, but not this one.
    function _adjustPosition(uint256, uint256 minOutputAfterInvestment) internal override {
        uint256 toInvest = _underlyingBalance();
        if (toInvest > 0) {
            _invest(toInvest, minOutputAfterInvestment);
        }
    }

    /// @notice Invests `amount` of underlying into the Convex pool
    /// @dev We don't perform any reward claim. All assets must have been
    /// previously converted to `underlyingAsset`.
    /// Note that because of Curve's bonus/penalty approach, we check if it is best to
    /// add liquidity with native ETH or with pegged ETH. It is then expected to always receive
    /// at least `amount` if we perform an exchange from ETH to pegged ETH.
    /// @param amount The amount of underlying to be deposited in the pool
    /// @param minOutputAfterInvestment minimum expected output after `_invest()` (designated in Curve LP tokens)
    /// @return The amount of tokens received, in terms of underlying
    function _invest(uint256 amount, uint256 minOutputAfterInvestment) internal returns (uint256) {
        // Don't do anything if amount to invest is 0
        if (amount == 0) return 0;

        uint256 underlyingBalance = _underlyingBalance();

        assembly ("memory-safe") {
            if gt(amount, underlyingBalance) {
                // throw the `NotEnoughFundsToInvest` error
                mstore(0x00, 0xb2ff68ae)
                revert(0x1c, 0x04)
            }
        }
 
        // Invested amount will be a maximum of `maxSingleTrade`
        amount = Math.min(maxSingleTrade, amount);

        // Unwrap WETH to interact with Curve
        IWETH(address(underlyingAsset)).withdraw(amount);

        // Swap ETH for frxETH
        uint256 frxEthReceivedAmount = curveEthFrxEthPool.exchange{value: amount}(0, 1, amount, 0);

        // Add liquidity to the dETH-frxETH pool in frxETH [coin1 -> frxETH]
        uint256 lpReceived = curveDEthFrxEthPool.add_liquidity([0, frxEthReceivedAmount], 0);

        assembly ("memory-safe") {
            // if (lpReceived < minOutputAfterInvestment)
            if lt(lpReceived, minOutputAfterInvestment) {
                // throw the `MinOutputAmountNotReached` error
                mstore(0x00, 0xf7c67a48)
                revert(0x1c, 0x04)
            }
        }

        // Deposit Curve LP into Convex pool with id `DETH_FRXETH_CONVEX_POOL_ID` and immediately stake convex LP tokens into the rewards contract
        convexBooster.deposit(DETH_FRXETH_CONVEX_POOL_ID, lpReceived, true);

        emit Invested(address(this), amount);

        return _lpValue(lpReceived);
    }

    /// @notice Divests amount `amount` from the Convex pool
    /// Note that divesting from the pool could potentially cause loss, so the divested amount might actually be different from
    /// the requested `amount` to divest
    /// @dev care should be taken, as the `amount` parameter is not in terms of underlying,
    /// but in terms of Curve's LP tokens
    /// Note that if minimum withdrawal amount is not reached, funds will not be divested, and this
    /// will be accounted as a loss later.
    /// @return the total amount divested, in terms of underlying asset
    function _divest(uint256 amount) internal returns (uint256) {
        // Withdraw from Convex and unwrap directly to Curve LP tokens
        convexRewardPool.withdrawAndUnwrap(amount, false);

        // Remove liquidity and obtain frxETH
        uint256 amountWithdrawn = curveDEthFrxEthPool.remove_liquidity_one_coin(
            amount,
            1,
            //frxETH
            0
        );

        // Swap frxETH for ETH
        uint256 ethReceived = curveEthFrxEthPool.exchange(1, 0, amountWithdrawn, 0);

        // Wrap ETH into WETH
        IWETH(address(underlyingAsset)).deposit{value: ethReceived}();

        return ethReceived;
    }

    /// @notice Liquidate up to `amountNeeded` of MaxApy vaul's `underlyingAsset` of this strategy's positions,
    /// irregardless of slippage. Any excess will be re-invested with `_adjustPosition()`.
    /// @dev This function should return the amount of MaxApy vault's `underlyingAsset` tokens made available by the
    /// liquidation. If there is a difference between `amountNeeded` and `liquidatedAmount`, `loss` indicates whether the
    /// difference is due to a realized loss, or if there is some other sitution at play
    /// (e.g. locked funds) where the amount made available is less than what is needed.
    /// NOTE: The invariant `liquidatedAmount + loss <= amountNeeded` should always be maintained
    /// @param amountNeeded amount of MaxApy vault's `underlyingAsset` needed to be liquidated
    /// @return liquidatedAmount the actual liquidated amount
    /// @return loss difference between the expected amount needed to reach `amountNeeded` and the actual liquidated amount
    function _liquidatePosition(uint256 amountNeeded)
        internal
        override
        returns (uint256 liquidatedAmount, uint256 loss)
    {
        uint256 underlyingBalance = _underlyingBalance();

        // If underlying balance currently held by strategy is not enough to cover
        // the requested amount, we divest from Convex
        if (underlyingBalance < amountNeeded) {
            uint256 amountToWithdraw;
            unchecked {
                amountToWithdraw = amountNeeded - underlyingBalance;
            }

            uint256 lp = _lpForAmount(amountToWithdraw);

            uint256 staked = _stakedBalance(convexRewardPool);

            assembly {
                // Adjust computed lp amount by current lp balance
                if gt(lp, staked) { lp := staked }
            }

            uint256 withdrawn = _divest(lp);

            assembly {
                if lt(withdrawn, amountToWithdraw) {
                    // if (withdrawn < amountToWithdraw)
                    loss := sub(amountToWithdraw, withdrawn) // loss = amountToWithdraw - withdrawn. Can never underflow
                }
            }
        }
        assembly {
            //  liquidatedAmount = amountNeeded - loss;
            liquidatedAmount := sub(amountNeeded, loss) // can never underflow
        }
    }

    /// @notice Liquidates everything and returns the amount that got freed.
    /// @dev This function is used during emergency exit instead of `_prepareReturn()` to
    /// liquidate all of the Strategy's positions back to the MaxApy vault.
    function _liquidateAllPositions() internal override returns (uint256 amountFreed) {
        IConvexRewards rewardPool = convexRewardPool;
        _unwindRewards(convexRewardPool);
        _divest(_stakedBalance(rewardPool));
        amountFreed = _underlyingBalance();
    }

    /// @notice Claims rewards, converting them to `underlyingAsset`.
    /// @dev MinOutputAmounts are left as 0 and properly asserted globally on `harvest()`.
    function _unwindRewards(IConvexRewards rewardPool) internal {
        // Claim CRV and CVX rewards
        rewardPool.getReward(address(this), true);

        // Exchange CRV <> WETH
        uint256 crvBalance = _crvBalance();
        if (crvBalance > minSwapCrv) {
            address[] memory path = new address[](2);
            path[0] = address(crv);
            path[1] = underlyingAsset;
            router.swapExactTokensForTokens(crvBalance, 0, path, address(this), block.timestamp);
        }

        // Exchange CVX <> WETH
        uint256 cvxBalance = _cvxBalance();
        if (cvxBalance > minSwapCvx) {
            cvxWethPool.exchange(1, 0, cvxBalance, 0, false);
        }
    }

    ////////////////////////////////////////////////////////////////
    ///                 INTERNAL VIEW FUNCTIONS                  ///
    ////////////////////////////////////////////////////////////////

    /// @notice Returns the CVX token balane of the strategy
    /// @return The amount of CVX tokens held by the current contract
    function _cvxBalance() internal view returns (uint256) {
        return cvx.balanceOf(address(this));
    }

    /// @notice Returns the CRV token balane of the strategy
    /// @return The amount of CRV tokens held by the current contract
    function _crvBalance() internal view returns (uint256) {
        return crv.balanceOf(address(this));
    }

    /// @notice Returns the amount of Curve LP tokens staked in Convex
    /// @return the amount of staked LP tokens
    function _stakedBalance(IConvexRewards rewardPool) internal view returns (uint256) {
        return rewardPool.balanceOf(address(this));
    }

    /// @notice Determines how many lp tokens depositor of `amount` of underlying would receive.
    /// @dev Some loss of precision is occured, but it is not critical as this is only an underestimation of
    /// the actual assets, and profit will be later accounted for.
    /// @return returns the estimated amount of lp tokens computed in exchange for underlying `amount`
    function _lpValue(uint256 lp) internal view returns (uint256) {
        return (lp * _lpPrice()) / 1e18;
    }

    /// @notice Determines how many lp tokens depositor of `amount` of underlying would receive.
    /// @return returns the estimated amount of lp tokens computed in exchange for underlying `amount`
    function _lpForAmount(uint256 amount) internal view returns (uint256) {
        return (amount * 1e18) / _lpPrice();
    }

    /// @notice Returns the estimated price for the strategy's Convex's LP token
    /// @return returns the estimated lp token price
    function _lpPrice() internal view returns (uint256) {
        return (
            (
                curveDEthFrxEthPool.get_virtual_price()
                    * Math.min(curveDEthFrxEthPool.get_dy(1, 0, 1 ether), curveDEthFrxEthPool.get_dy(0, 1, 1 ether))
            ) / 1e18
        );
    }

    //solhint-disable no-empty-blocks
    receive() external payable {}
}
