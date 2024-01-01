// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./CurveConvexStrategyProtocol.sol";
import "./errors.sol";
import "./ICurveConvexPeriphery.sol";
import "./CurveConvexBase.sol";
import "./IFijaStrategy.sol";

///
/// @title Curve Convex Periphery
/// @author Fija
/// @notice View methods to support main strategy contract operations
/// @dev To offload size and heavy view methods for off-chain usage
///
contract CurveConvexPeriphery is CurveConvexBase, ICurveConvexPeriphery {
    ///
    /// @dev reference to main strategy contract
    ///
    address internal STRATEGY;

    constructor(
        address depositCurrency_,
        address governance_,
        string memory tokenName_,
        string memory tokenSymbol_,
        uint256 maxTicketSize_,
        uint256 maxVaultValue_,
        ConstructorData memory data_
    )
        CurveConvexBase(
            depositCurrency_,
            governance_,
            tokenName_,
            tokenSymbol_,
            maxTicketSize_,
            maxVaultValue_,
            data_
        )
    {}

    ///
    /// @dev link to base strategy contract
    /// @param strategy address to associate periphery contract with main strategy contract
    ///
    function setStrategy(address strategy) public onlyOwner {
        STRATEGY = strategy;
    }

    ///
    /// NOTE: uses pool categories and deposit zap addresses to identify the interface and invoke methods on proper contracts
    /// @inheritdoc ICurveConvexPeriphery
    ///
    function calcTokenAmount(
        address pool,
        uint256 depositAmount,
        bool isDeposit
    ) external view override returns (uint256) {
        uint8 id = _poolCategory[pool][2];
        uint256[4] memory amounts = _buildInputAmount(
            depositAmount,
            _poolDepositCcyIndex[pool]
        );
        if (id == 0) {
            uint256[3] memory inputs = [amounts[0], amounts[1], amounts[2]];

            return ICurve(pool).calc_token_amount(inputs, isDeposit);
        } else if (id == 1) {
            uint256[2] memory inputs = [amounts[0], amounts[1]];

            return ICurve(pool).calc_token_amount(inputs, isDeposit);
        } else if (id == 2) {
            if (_poolDepositCtr[pool] != address(0)) {
                pool = _poolDepositCtr[pool];
            }
            return ICurve(pool).calc_token_amount(amounts, isDeposit);
        } else if (id == 3) {
            uint256[2] memory inputs = [amounts[0], amounts[1]];

            return ICurve(pool).calc_token_amount(inputs);
        } else if (id == 4) {
            return
                ICurve(_poolDepositCtr[pool]).calc_token_amount(
                    pool,
                    amounts,
                    isDeposit
                );
        } else if (id == 5) {
            uint256[3] memory inputs = [amounts[0], amounts[1], amounts[2]];
            return
                ICurve(_poolDepositCtr[pool]).calc_token_amount(
                    pool,
                    inputs,
                    isDeposit
                );
        } else {
            revert FijaInvalidPoolCategory();
        }
    }

    ///
    /// NOTE: uses pool categories and deposit zap addresses to identify the interface and invoke methods on proper contracts
    /// @inheritdoc ICurveConvexPeriphery
    ///
    function calcWithdrawOneCoin(
        address pool,
        uint256 burnAmount,
        int128 i
    ) public view returns (uint256) {
        uint8 id = _poolCategory[pool][3];
        if (id == 0) {
            if (_poolDepositCtr[pool] != address(0)) {
                pool = _poolDepositCtr[pool];
            }
            try ICurve(pool).calc_withdraw_one_coin(burnAmount, i) returns (
                uint256 amount
            ) {
                return amount;
            } catch {
                return 0;
            }
        } else if (id == 1) {
            try
                ICurve(pool).calc_withdraw_one_coin(burnAmount, i, true)
            returns (uint256 amount) {
                return amount;
            } catch {
                return 0;
            }
        } else if (id == 2) {
            try
                ICurve(pool).calc_withdraw_one_coin(
                    burnAmount,
                    uint256(int256(i))
                )
            returns (uint256 amount) {
                return amount;
            } catch {
                return 0;
            }
        } else if (id == 3) {
            try
                ICurve(_poolDepositCtr[pool]).calc_withdraw_one_coin(
                    pool,
                    burnAmount,
                    i
                )
            returns (uint256 amount) {
                return amount;
            } catch {
                return 0;
            }
        } else {
            revert FijaInvalidPoolCategory();
        }
    }

    ///
    /// NOTE: uses pool categories and deposit zap addresses to identify the interface and invoke methods on proper contracts
    /// @inheritdoc ICurveConvexPeriphery
    ///
    function getExchangeAmount(
        address pool,
        address from,
        address to,
        uint256 input
    ) public view override returns (uint256) {
        uint8 id = _poolExchangeCategory[pool][0];
        if (id == 0) {
            IExchangeRegistry ex = IExchangeRegistry(
                Curve_IAddressProvider.get_address(CURVE_EXCHANGE_ID)
            );
            try ex.get_exchange_amount(pool, from, to, input) returns (
                uint256 amount
            ) {
                return amount;
            } catch {
                return 0;
            }
        } else if (id == 1) {
            address depo = pool;
            if (_poolDepositCtr[pool] != address(0)) {
                depo = _poolDepositCtr[pool];
            }
            try
                ICurve(depo).get_dy(
                    _rewardPoolCoinIndex[pool][from],
                    _rewardPoolCoinIndex[pool][to],
                    input
                )
            returns (uint256 amount) {
                return amount;
            } catch {
                return 0;
            }
        } else if (id == 2) {
            address depo = pool;
            if (_poolDepositCtr[pool] != address(0)) {
                depo = _poolDepositCtr[pool];
            }
            try
                ICurve(depo).get_dy_underlying(
                    int128(uint128(_rewardPoolCoinIndex[pool][from])),
                    int128(uint128(_rewardPoolCoinIndex[pool][to])),
                    input
                )
            returns (uint256 amount) {
                return amount;
            } catch {
                return 0;
            }
        } else if (id == 3) {
            // deposit zap
            try
                ICurve(_poolDepositCtr[pool]).get_dy_underlying(
                    _rewardPoolCoinIndex[pool][from],
                    _rewardPoolCoinIndex[pool][to],
                    input
                )
            returns (uint256 amount) {
                return amount;
            } catch {
                return 0;
            }
        } else if (id == 4) {
            // deposit zap
            try
                ICurve(_poolDepositCtr[pool]).get_dy(
                    pool,
                    _rewardPoolCoinIndex[pool][from],
                    _rewardPoolCoinIndex[pool][to],
                    input
                )
            returns (uint256 amount) {
                return amount;
            } catch {
                return 0;
            }
        } else if (id == 5) {
            // deposit zap
            try
                ICurve(_poolDepositCtr[pool]).get_dy_underlying(
                    pool,
                    _rewardPoolCoinIndex[pool][from],
                    _rewardPoolCoinIndex[pool][to],
                    input
                )
            returns (uint256 amount) {
                return amount;
            } catch {
                return 0;
            }
        } else if (id == 6) {
            try
                ICurve(pool).get_dy(
                    int128(uint128(_rewardPoolCoinIndex[pool][from])),
                    int128(uint128(_rewardPoolCoinIndex[pool][to])),
                    input
                )
            returns (uint256 amount) {
                return amount;
            } catch {
                return 0;
            }
        } else {
            revert FijaInvalidPoolCategory();
        }
    }

    ///
    /// @inheritdoc ICurveConvexPeriphery
    ///
    function exposureDiff(
        uint256 targetExposure
    ) external view override returns (int256[8] memory, uint256[] memory) {
        (uint256[2] memory crvCvxInDepositCCy, , ) = crvCvxToDepositCcy(
            [PRECISION_18, PRECISION_18]
        );
        uint256[] memory numerators = new uint256[](POOL_NUM);
        uint256 denominator = 0;

        for (uint8 i = 0; i < POOL_NUM; i++) {
            address pool = _curvePools[i];
            numerators[i] =
                _poolYield(crvCvxInDepositCCy[0], crvCvxInDepositCCy[1], pool) *
                _poolRating[pool];

            denominator += numerators[i];
        }
        int256[8] memory poolExDiff;
        uint256[] memory poolAllocationsLogBps = new uint256[](POOL_NUM);

        for (uint8 i = 0; i < POOL_NUM; i++) {
            address pool = _curvePools[i];

            uint256 currentPoolExp = calcWithdrawOneCoin(
                pool,
                IERC20(_poolRewardContract[pool]).balanceOf(STRATEGY),
                _poolDepositCcyIndex[pool]
            );
            uint256 poolAllocation = (numerators[i] * PRECISION_30) /
                denominator;

            poolAllocationsLogBps[i] =
                (numerators[i] * BASIS_POINTS_DIVISOR) /
                denominator;

            uint256 targetPoolExposure = (targetExposure * poolAllocation) /
                PRECISION_30;

            poolExDiff[i] = int256(currentPoolExp) - int256(targetPoolExposure);
        }
        return (poolExDiff, poolAllocationsLogBps);
    }

    ///
    /// NOTE: exchange hop results are used as part of harvest when exchanging CRV/CVX to deposit tokens, xwthrough reward routes
    /// @inheritdoc ICurveConvexPeriphery
    ///
    function crvCvxToDepositCcy(
        uint256[2] memory inputs
    )
        public
        view
        returns (uint256[2] memory, uint256[] memory, uint256[] memory)
    {
        uint8 poolNum = uint8(_crvRewardRoute.length);
        bool isEmergencyMode = IFijaStrategy(STRATEGY).emergencyMode();

        uint256[] memory crvIntermed = new uint256[](poolNum);

        // calculate CRV to deposit currency amount
        for (uint8 i = 0; i < poolNum; i++) {
            uint256 amount = getExchangeAmount(
                _crvRewardRoute[i].addr,
                _crvRewardRoute[i].from,
                _crvRewardRoute[i].to,
                inputs[0]
            );
            uint256 slippage = SLIPPAGE_SWAP;
            if (isEmergencyMode) {
                slippage = SLIPPAGE_EMERGENCY;
            }
            inputs[0] =
                (amount * (BASIS_POINTS_DIVISOR - slippage)) /
                BASIS_POINTS_DIVISOR;
            if (inputs[0] == 0) {
                break;
            }

            crvIntermed[i] = inputs[0];
        }
        poolNum = uint8(_cvxRewardRoute.length);

        uint256[] memory cvxIntermed = new uint256[](poolNum);
        // save intermed exchange values to use for swaps

        // calculate CVX to deposit currency amount
        for (uint8 i = 0; i < poolNum; i++) {
            uint256 amount = getExchangeAmount(
                _cvxRewardRoute[i].addr,
                _cvxRewardRoute[i].from,
                _cvxRewardRoute[i].to,
                inputs[1]
            );
            uint256 slippage = SLIPPAGE_SWAP;
            if (isEmergencyMode) {
                slippage = SLIPPAGE_EMERGENCY;
            }
            inputs[1] =
                (amount * (BASIS_POINTS_DIVISOR - slippage)) /
                BASIS_POINTS_DIVISOR;
            if (inputs[1] == 0) {
                break;
            }
            cvxIntermed[i] = inputs[1];
        }
        // amount in depositCCy
        return ([inputs[0], inputs[1]], crvIntermed, cvxIntermed);
    }

    ///
    /// @inheritdoc ICurveConvexPeriphery
    ///
    function needEmergencyMode()
        external
        view
        override(FijaStrategy, ICurveConvexPeriphery)
        returns (bool)
    {
        uint256 depositDec = decimals();

        for (uint8 i = 0; i < POOL_NUM; i++) {
            address pool = _curvePools[i];

            uint256 lpTokenInDepositCCy = calcWithdrawOneCoin(
                pool,
                PRECISION_18,
                _poolDepositCcyIndex[pool]
            );

            // check de-peg
            if (DE_PEG_CHECK) {
                address[8] memory coins = _underlyingCoins(pool);
                for (uint8 j = 0; j < coins.length; j++) {
                    if (coins[j] == address(0)) {
                        break;
                    }
                    if (coins[j] != DEPOSIT_CCY) {
                        int128 coinIndex = _findCoinIndex(coins, coins[j]);
                        uint256 nonDepositDec = ERC20(coins[j]).decimals();

                        uint256 value = calcWithdrawOneCoin(
                            pool,
                            PRECISION_18,
                            coinIndex
                        );
                        value =
                            (((value * 10 ** depositDec) /
                                (10 ** nonDepositDec)) * 10000) /
                            lpTokenInDepositCCy;
                        // 4 decimals precision
                        if (
                            value < (10000 - DEPEG_DEVIATION) ||
                            value > (10000 + DEPEG_DEVIATION)
                        ) {
                            return true;
                        }
                    }
                }
            }
            // check low liquidity
            uint256 currentPoolExposure = (lpTokenInDepositCCy *
                IERC20(_poolRewardContract[pool]).balanceOf(STRATEGY)) /
                PRECISION_18;

            uint256 tvlPoolPerc = (((lpTokenInDepositCCy *
                IERC20(_poolLpToken[pool]).totalSupply()) / PRECISION_18) *
                LIQUIDITY_THR_BPS) / BASIS_POINTS_DIVISOR;

            if (currentPoolExposure > tvlPoolPerc) {
                return true;
            }
        }
        return false;
    }

    ///
    /// @inheritdoc ICurveConvexPeriphery
    ///
    function totalAssets()
        external
        view
        override(IERC4626, ICurveConvexPeriphery)
        returns (uint256)
    {
        uint256 emergencyCcyValue = 0;

        if (IFijaStrategy(STRATEGY).emergencyMode()) {
            // calculate value in emergencyCCy
            emergencyCcyValue = getExchangeAmount(
                _emergencyPool,
                EMERGENCY_CCY,
                DEPOSIT_CCY,
                IERC20(EMERGENCY_CCY).balanceOf(STRATEGY)
            );
        }
        uint256 depositCcyValue;

        if (DEPOSIT_CCY == ETH) {
            depositCcyValue = STRATEGY.balance;
        } else {
            depositCcyValue = IERC20(DEPOSIT_CCY).balanceOf(STRATEGY);
        }
        // calculate value of lp tokens
        uint256 valueOfLpTokens = 0;
        for (uint8 i = 0; i < POOL_NUM; i++) {
            address pool = _curvePools[i];

            valueOfLpTokens += calcWithdrawOneCoin(
                pool,
                IERC20(_poolRewardContract[pool]).balanceOf(STRATEGY),
                _poolDepositCcyIndex[pool]
            );
        }
        return valueOfLpTokens + emergencyCcyValue + depositCcyValue;
    }

    ///
    /// NOTE: total assets, pools, Lp tokens amount / pool, assets deployed / pool
    /// unclaimed rewards, amount in deposit token on strategy, amount in emergency token on strategy
    /// @inheritdoc ICurveConvexPeriphery
    ///
    function status()
        external
        view
        virtual
        override(FijaStrategy, ICurveConvexPeriphery)
        returns (string memory)
    {
        string memory str1 = string(
            abi.encodePacked("totalAssets:", Strings.toString(totalAssets()))
        );

        string memory str2 = "";

        uint256 crvEarned = 0;
        for (uint8 i = 0; i < POOL_NUM; i++) {
            address pool = _curvePools[i];

            uint256 amountInLpTokens = IERC20(_poolRewardContract[pool])
                .balanceOf(STRATEGY);

            uint256 poolValue = calcWithdrawOneCoin(
                pool,
                amountInLpTokens,
                _poolDepositCcyIndex[pool]
            );
            str2 = string(
                abi.encodePacked(
                    str2,
                    "|Pool:",
                    Strings.toHexString(uint256(uint160(pool)), 20),
                    "|LpTokens:",
                    Strings.toString(amountInLpTokens),
                    "|Value:",
                    Strings.toString(poolValue)
                )
            );

            (, , , address rewardContract, , ) = Convex_IBooster.poolInfo(
                _poolConvexPoolId[pool]
            );
            crvEarned += IRewardStaking(rewardContract).earned(STRATEGY);
        }

        uint256 depositCCyValue;
        uint256 emergencyCCyValue = 0;

        if (!EME_POOL_DISABLED) {
            emergencyCCyValue = IERC20(EMERGENCY_CCY).balanceOf(STRATEGY);
        }
        if (DEPOSIT_CCY == ETH) {
            depositCCyValue = STRATEGY.balance;
        } else {
            depositCCyValue = IERC20(DEPOSIT_CCY).balanceOf(STRATEGY);
        }
        return
            string(
                abi.encodePacked(
                    str1,
                    "|UnclaimedRewards:",
                    Strings.toString(
                        crvEarned + Convex_ICvxMining.ConvertCrvToCvx(crvEarned)
                    ),
                    "|DepositCcyAmount:",
                    Strings.toString(depositCCyValue),
                    "|EmergencyCcyAmount:",
                    EME_POOL_DISABLED
                        ? "N/A"
                        : Strings.toString(emergencyCCyValue),
                    str2
                )
            );
    }

    ///
    /// @dev Helper method to calculatee pool yield
    /// @param crvInDepositCCy exchange rate CRV/deposit token
    /// @param cvxInDepositCcy exchange rate CVX/deposit token
    /// @param pool address of pool
    /// @return APR of the pool in bps (14 decimals precision)
    /// NOTE: APR is sum of CRV reward apr and CVX reward apr
    ///
    function _poolYield(
        uint256 crvInDepositCCy,
        uint256 cvxInDepositCcy,
        address pool
    ) private view returns (uint256) {
        uint256 lpTokenPriceInDepositCcy = calcWithdrawOneCoin(
            pool,
            PRECISION_18,
            _poolDepositCcyIndex[pool]
        );

        (, uint256[] memory rates) = Convex_IApr.rewardRates(
            _poolConvexPoolId[pool]
        );
        uint256 crvApr = Convex_IApr.apr(
            rates[0],
            crvInDepositCCy,
            lpTokenPriceInDepositCcy
        );
        uint256 cvxApr = Convex_IApr.apr(
            rates[1],
            cvxInDepositCcy,
            lpTokenPriceInDepositCcy
        );

        return crvApr + cvxApr;
    }
}
