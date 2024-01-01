// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./FijaStrategy.sol";
import "./CurveConvexStrategyProtocol.sol";
import "./errors.sol";
import "./ICurve.sol";
import "./ICurveConvexPeriphery.sol";
import "./CurveConvexBase.sol";
import "./CurveConvexPeriphery.sol";

///
/// @title Curve Convex Strategy
/// @author Fija
/// @notice Main contract used for asset management
/// @dev Responsibe for adding or removing the liquidity from the pool,
/// executing swaps, harvesting and rebalancing assets
///
contract CurveConvexStrategy is CurveConvexBase {
    ICurveConvexPeriphery internal immutable PERIPHERY;

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
    {
        PERIPHERY = ICurveConvexPeriphery(data_.linkAddr);
    }

    ///
    /// NOTE: uses periphery contract to query total assets it has under management
    /// @inheritdoc IERC4626
    ///
    function totalAssets() public view virtual override returns (uint256) {
        return PERIPHERY.totalAssets();
    }

    ///
    /// @dev calculates amount of tokens receiver will get based on asset deposit.
    /// @param assets amount of assets caller wants to deposit
    /// @param receiver address of the owner of deposit once deposit completes, this address will receive tokens.
    /// @return amount of tokens receiver will receive
    /// NOTE: Executes deposits to curve pools and stakes LP tokens to Convex pools
    /// Caller and receiver must be whitelisted
    /// Cannot deposit in emergency mode
    /// Emits IERC4626.Deposit
    ///
    function deposit(
        uint256 assets,
        address receiver
    )
        public
        payable
        virtual
        override
        emergencyModeRestriction
        returns (uint256)
    {
        uint256 tokens = super.deposit(assets, receiver);

        // find lowest negative difference between target and current exposure
        (int256[8] memory poolExpDiff, ) = PERIPHERY.exposureDiff(
            totalAssets()
        );
        address depositCcy = DEPOSIT_CCY;
        uint256 remainingToDeposit;

        if (depositCcy == ETH) {
            remainingToDeposit = address(this).balance;
        } else {
            remainingToDeposit = IERC20(depositCcy).balanceOf(address(this));
        }

        while (remainingToDeposit > 0) {
            uint8 minIndex = 0;
            int256 minDiff = 0;

            for (uint8 i = 0; i < POOL_NUM; i++) {
                if (poolExpDiff[i] < minDiff) {
                    minDiff = poolExpDiff[i];
                    minIndex = i;
                }
            }
            if (minDiff < 0) {
                uint256 assetsToDeposit = 0;
                if (int256(remainingToDeposit) + minDiff <= 0) {
                    // deposit all assets to pool
                    assetsToDeposit = remainingToDeposit;
                    remainingToDeposit = 0;
                } else {
                    // deposit difference
                    assetsToDeposit = uint256(minDiff * -1);
                    remainingToDeposit -= assetsToDeposit;

                    // reduce deposited exposure
                    poolExpDiff[minIndex] = 0;
                }
                address pool = _curvePools[minIndex];

                uint256 minAmount = PERIPHERY.calcTokenAmount(
                    pool,
                    assetsToDeposit,
                    true
                );
                minAmount =
                    (minAmount * (BASIS_POINTS_DIVISOR - SLIPPAGE_SWAP)) /
                    BASIS_POINTS_DIVISOR;

                address depositCtr = _poolDepositCtr[pool];
                if (depositCcy != ETH) {
                    SafeERC20.forceApprove(
                        IERC20(depositCcy),
                        depositCtr != address(0) ? depositCtr : pool,
                        assetsToDeposit
                    );
                }
                address lpToken = _poolLpToken[pool];

                // deposit to curve pools to get LP tokens
                _addLiquidity(pool, assetsToDeposit, minAmount);

                SafeERC20.forceApprove(
                    IERC20(lpToken),
                    address(Convex_IBooster),
                    IERC20(lpToken).balanceOf(address(this))
                );
                // stake all LPtokens to convex
                Convex_IBooster.depositAll(_poolConvexPoolId[pool], true);
            } else {
                // no positive discrepancy, so end logic
                remainingToDeposit = 0;
            }
        }
        return tokens;
    }

    ///
    /// @dev Burns tokens from owner and sends exact number of assets to receiver
    /// @param assets amount of assets caller wants to withdraw
    /// @param receiver address of the asset receiver
    /// @param owner address of the owner of tokens
    /// @return amount of tokens burnt based on exact assets requested
    /// NOTE: unstakes LP tokens from Convex pools and removes liquidity from Curve pools
    /// Caller, receiver and owner must be whitelisted
    /// Emits IERC4626.Withdraw
    ///
    function withdraw(
        uint256 assets,
        address receiver,
        address owner
    ) external virtual override(IERC4626) returns (uint256) {
        _withdraw(assets);
        return super.withdraw(assets, receiver, owner);
    }

    ///
    /// @dev Burns exact number of tokens from owner and sends assets to receiver.
    /// @param tokens amount of tokens caller wants to redeem
    /// @param receiver address of the asset receiver
    /// @param owner address of the owner of tokens
    /// @return amount of assets receiver will receive based on exact burnt tokens
    /// NOTE: unstakes LP tokens from Convex pools and removes liquidity from Curve pools
    /// Caller, receiver and owner must be whitelisted
    /// Emits IERC4626.Withdraw
    ///
    function redeem(
        uint256 tokens,
        address receiver,
        address owner
    ) external virtual override returns (uint256) {
        uint256 assets = previewRedeem(tokens);
        _withdraw(assets);
        return super.redeem(tokens, receiver, owner);
    }

    ///
    /// NOTE: harvest is scheduled
    /// @inheritdoc IFijaStrategy
    ///
    function needHarvest() external view virtual override returns (bool) {
        if (block.timestamp >= _lastHarvestTime + HARVEST_TIME) {
            return true;
        }
        return false;
    }

    ///
    /// NOTE: Only governance access
    /// Restricted in emergency mode
    /// emits IFijaStrategy.Harvest
    /// @inheritdoc IFijaStrategy
    ///
    function harvest()
        public
        virtual
        override
        onlyGovernance
        emergencyModeRestriction
    {
        // get rewards from each pool
        for (uint8 i = 0; i < POOL_NUM; i++) {
            IRewardStaking(_poolRewardContract[_curvePools[i]]).getReward(
                address(this),
                false
            );
        }
        // convert CRV and CVX rewards to deposit currency
        uint256 crvAmount = IERC20(CRV).balanceOf(address(this));
        uint256 cvxAmount = IERC20(CVX).balanceOf(address(this));
        (
            uint256[2] memory output,
            uint256[] memory crvIntermed,
            uint256[] memory cvxIntermed
        ) = PERIPHERY.crvCvxToDepositCcy([crvAmount, cvxAmount]);

        if (output[0] != 0) {
            uint8 poolNum = uint8(_crvRewardRoute.length);
            // calculate CRV to deposit currency amount
            for (uint8 i = 0; i < poolNum; i++) {
                crvAmount = _exchange(
                    _crvRewardRoute[i].addr,
                    _crvRewardRoute[i].from,
                    _crvRewardRoute[i].to,
                    crvAmount,
                    crvIntermed[i]
                );
            }
        } else {
            crvAmount = 0;
        }
        if (output[1] != 0) {
            uint8 poolNum = uint8(_cvxRewardRoute.length);
            // calculate CVX to deposit currency amount
            for (uint8 i = 0; i < poolNum; i++) {
                cvxAmount = _exchange(
                    _cvxRewardRoute[i].addr,
                    _cvxRewardRoute[i].from,
                    _cvxRewardRoute[i].to,
                    cvxAmount,
                    cvxIntermed[i]
                );
            }
        } else {
            cvxAmount = 0;
        }

        _lastHarvestTime = block.timestamp;
        uint256 totalRewards = crvAmount + cvxAmount;

        uint256 share = 0;
        address depositCcy = DEPOSIT_CCY;

        if (totalRewards > 0) {
            share = (totalRewards * 2500) / BASIS_POINTS_DIVISOR;

            if (depositCcy == ETH) {
                (bool success, ) = payable(governance()).call{value: share}("");
                if (!success) {
                    revert TransferFailed();
                }
            } else {
                SafeERC20.safeTransfer(IERC20(depositCcy), governance(), share);
            }
        }
        emit Harvest(block.timestamp, totalRewards, share, depositCcy, "");
    }

    ///
    /// NOTE uses periphery contract to query needEmergencyMode()
    /// @inheritdoc IFijaStrategy
    ///
    function needEmergencyMode() public view virtual override returns (bool) {
        return PERIPHERY.needEmergencyMode();
    }

    ///
    /// NOTE: Only governance access
    /// emits IFijaStrategy.EmergencyMode
    /// @inheritdoc IFijaStrategy
    ///
    function setEmergencyMode(
        bool turnOn
    ) external virtual override onlyGovernance {
        emit EmergencyMode(block.timestamp, turnOn);

        address depositCcy = DEPOSIT_CCY;
        if (turnOn) {
            _isEmergencyMode = true;

            for (uint8 i = 0; i < POOL_NUM; i++) {
                address pool = _curvePools[i];
                address rewardContract = _poolRewardContract[pool];

                uint256 balanceLpToken = IERC20(rewardContract).balanceOf(
                    address(this)
                );
                IRewardStaking(rewardContract).withdrawAndUnwrap(
                    balanceLpToken,
                    false
                );
                // convert LP tokens to deposit currency
                int128 depositIndex = _poolDepositCcyIndex[pool];

                uint256 minOutCoin = PERIPHERY.calcWithdrawOneCoin(
                    pool,
                    balanceLpToken,
                    depositIndex
                );
                // liquidate token
                if (minOutCoin != 0) {
                    minOutCoin =
                        (minOutCoin *
                            (BASIS_POINTS_DIVISOR - SLIPPAGE_EMERGENCY)) /
                        BASIS_POINTS_DIVISOR;

                    address depositCtr = _poolDepositCtr[pool];
                    if (depositCtr != address(0)) {
                        SafeERC20.forceApprove(
                            IERC20(_poolLpToken[pool]),
                            depositCtr,
                            balanceLpToken
                        );
                    }
                    _removeLiquidityOneCoin(
                        pool,
                        balanceLpToken,
                        depositIndex,
                        minOutCoin
                    );
                }
            }
            // if emergency pool is disabled no swaps
            if (EME_POOL_DISABLED) {
                return;
            }
            // convert all deposit currency to emergency currency
            uint256 amountToExchange;
            if (depositCcy == ETH) {
                amountToExchange = address(this).balance;
            } else {
                amountToExchange = IERC20(depositCcy).balanceOf(address(this));
            }

            uint256 minOut = PERIPHERY.getExchangeAmount(
                _emergencyPool,
                depositCcy,
                EMERGENCY_CCY,
                amountToExchange
            );

            if (minOut != 0) {
                minOut =
                    (minOut * (BASIS_POINTS_DIVISOR - SLIPPAGE_EMERGENCY)) /
                    BASIS_POINTS_DIVISOR;

                _exchange(
                    _emergencyPool,
                    depositCcy,
                    EMERGENCY_CCY,
                    amountToExchange,
                    minOut
                );
            }
        } else {
            _isEmergencyMode = false;
            // if emergency pool is disabled no swaps just rebalance
            if (EME_POOL_DISABLED) {
                rebalance();
                return;
            }

            // convert emergency currency to deposit currency
            uint256 amountToExchange = IERC20(EMERGENCY_CCY).balanceOf(
                address(this)
            );

            uint256 minOut = PERIPHERY.getExchangeAmount(
                _emergencyPool,
                EMERGENCY_CCY,
                depositCcy,
                amountToExchange
            );
            if (minOut != 0) {
                minOut =
                    (minOut * (BASIS_POINTS_DIVISOR - SLIPPAGE_SWAP)) /
                    BASIS_POINTS_DIVISOR;

                _exchange(
                    _emergencyPool,
                    EMERGENCY_CCY,
                    depositCcy,
                    amountToExchange,
                    minOut
                );
            }
            rebalance();
        }
    }

    ///
    /// NOTE: rebalance is perfomed based on timespan and total asset thresholds
    /// @inheritdoc IFijaStrategy
    ///
    function needRebalance() external view virtual override returns (bool) {
        uint256 totalAsset = totalAssets();
        if (
            _lastRebalanceTime + REBALANCE_TIME_UPPER < block.timestamp &&
            REBALANCE_THR1 <= totalAsset &&
            REBALANCE_THR2 > totalAsset
        ) {
            return true;
        }
        if (
            _lastRebalanceTime + REBALANCE_TIME_LOWER < block.timestamp &&
            REBALANCE_THR2 <= totalAsset
        ) {
            return true;
        }
        return false;
    }

    ///
    /// NOTE: Only governance access
    /// Restricted in emergency mode
    /// emits IFijaStrategy.Rebalance
    /// @inheritdoc IFijaStrategy
    ///
    function rebalance()
        public
        virtual
        override
        onlyGovernance
        emergencyModeRestriction
    {
        _lastRebalanceTime = block.timestamp;
        (
            int256[8] memory poolExpDiff,
            uint256[] memory poolAllocationsBps
        ) = PERIPHERY.exposureDiff(totalAssets());

        // first settle the positives, reduction of exposure
        uint8 poolNum = POOL_NUM;
        for (uint8 i = 0; i < poolNum; i++) {
            address pool = _curvePools[i];
            if (poolExpDiff[i] > 0) {
                // increase lpTokens to withdraw in order to ensure to get atleasst poolExpDiff[i]
                uint256 lpTokensToWithdraw = PERIPHERY.calcTokenAmount(
                    pool,
                    (uint256(poolExpDiff[i]) *
                        (BASIS_POINTS_DIVISOR + SLIPPAGE_SWAP)) /
                        BASIS_POINTS_DIVISOR,
                    false
                );
                // get lp tokens from convex
                IRewardStaking(_poolRewardContract[pool]).withdrawAndUnwrap(
                    lpTokensToWithdraw,
                    false
                );
                // special approve for deposit zaps
                address depositCtr = _poolDepositCtr[pool];
                if (depositCtr != address(0)) {
                    SafeERC20.forceApprove(
                        IERC20(_poolLpToken[pool]),
                        depositCtr,
                        lpTokensToWithdraw
                    );
                }
                // liquidate lp tokens on curve
                _removeLiquidityOneCoin(
                    pool,
                    lpTokensToWithdraw,
                    _poolDepositCcyIndex[pool],
                    uint256(poolExpDiff[i]) //minOut
                );
            }
        }
        // second settle the negatives, increase of exposure
        string memory str = "";
        for (uint8 i = 0; i < poolNum; i++) {
            address pool = _curvePools[i];
            str = string(
                abi.encodePacked(
                    str,
                    "|Pool:",
                    Strings.toHexString(uint256(uint160(pool)), 20),
                    "|AllocationBps:",
                    Strings.toString(poolAllocationsBps[i])
                )
            );
            if (poolExpDiff[i] < 0) {
                uint256 assetsToDeposit = uint256(poolExpDiff[i] * -1);
                address depositCcy = DEPOSIT_CCY;
                if (depositCcy != ETH) {
                    address depositCtr = _poolDepositCtr[pool];
                    SafeERC20.forceApprove(
                        IERC20(depositCcy),
                        depositCtr != address(0) ? depositCtr : pool,
                        assetsToDeposit
                    );
                }
                uint256 minOut = PERIPHERY.calcTokenAmount(
                    pool,
                    assetsToDeposit,
                    true
                );
                minOut =
                    (minOut * (BASIS_POINTS_DIVISOR - SLIPPAGE_SWAP)) /
                    BASIS_POINTS_DIVISOR;

                address lpToken = _poolLpToken[pool];

                _addLiquidity(pool, assetsToDeposit, minOut);

                SafeERC20.forceApprove(
                    IERC20(lpToken),
                    address(Convex_IBooster),
                    IERC20(lpToken).balanceOf(address(this))
                );
                // stake LPtokens to convex
                Convex_IBooster.depositAll(_poolConvexPoolId[pool], true);
            }
        }
        emit Rebalance(block.timestamp, str);
    }

    ///
    /// NOTE: uses periphery contract to query status()
    /// @inheritdoc IFijaStrategy
    ///
    function status() external view virtual override returns (string memory) {
        return PERIPHERY.status();
    }

    ///
    /// @dev Helper for withdraw and redeem methods, contains main logic for
    /// balanced assets withdrawals from liquidity pools when
    /// @param assets amount of assets caller wants to withdraw
    ///
    function _withdraw(uint256 assets) private {
        uint256 currentBalance;
        address depositCcy = DEPOSIT_CCY;

        if (depositCcy == ETH) {
            currentBalance = address(this).balance;
        } else {
            currentBalance = IERC20(depositCcy).balanceOf(address(this));
        }

        // check if we have any
        if (assets > currentBalance) {
            uint256 remainingToWithdraw = assets - currentBalance;
            if (!_isEmergencyMode) {
                (int256[8] memory poolExpDiff, ) = PERIPHERY.exposureDiff(
                    totalAssets() - assets
                );

                while (remainingToWithdraw > 0) {
                    uint8 maxIndex = 0;
                    int256 maxDiff = 0;
                    // find biggest positive difference between target and current exposure
                    for (uint8 i = 0; i < POOL_NUM; i++) {
                        if (poolExpDiff[i] > maxDiff) {
                            maxDiff = poolExpDiff[i];
                            maxIndex = i;
                        }
                    }
                    if (maxDiff > 0) {
                        uint256 assetsToWithdraw = 0;
                        if (int256(remainingToWithdraw) - maxDiff <= 0) {
                            // withdraw all assets from the pool
                            assetsToWithdraw = remainingToWithdraw;
                            remainingToWithdraw = 0;
                        } else {
                            // withdraw difference
                            assetsToWithdraw = uint256(maxDiff);
                            remainingToWithdraw -= assetsToWithdraw;

                            // reduce deposited exposure
                            poolExpDiff[maxIndex] = 0;
                        }
                        address pool = _curvePools[maxIndex];

                        uint256 lpTokensToWithdraw = ICurveConvexPeriphery(
                            PERIPHERY
                        ).calcTokenAmount(pool, assetsToWithdraw, false);

                        // include slippage to get enough assets out
                        lpTokensToWithdraw =
                            (lpTokensToWithdraw *
                                (BASIS_POINTS_DIVISOR + SLIPPAGE_SWAP)) /
                            BASIS_POINTS_DIVISOR;

                        // check if we are burning more then we have
                        address rewardContract = _poolRewardContract[pool];
                        uint256 lpTokenBalance = IERC20(rewardContract)
                            .balanceOf(address(this));

                        if (lpTokensToWithdraw > lpTokenBalance) {
                            lpTokensToWithdraw = lpTokenBalance;
                            assetsToWithdraw =
                                (assetsToWithdraw *
                                    (BASIS_POINTS_DIVISOR - SLIPPAGE_SWAP)) /
                                BASIS_POINTS_DIVISOR;
                        }
                        // get lp tokens from convex
                        IRewardStaking(rewardContract).withdrawAndUnwrap(
                            lpTokensToWithdraw,
                            false
                        );
                        // special approval for deposit zaps
                        address depositCtr = _poolDepositCtr[pool];
                        if (depositCtr != address(0)) {
                            SafeERC20.forceApprove(
                                IERC20(_poolLpToken[pool]),
                                depositCtr,
                                lpTokensToWithdraw
                            );
                        }
                        // liquidate lp tokens on curve to get deposit currency out
                        _removeLiquidityOneCoin(
                            pool,
                            lpTokensToWithdraw,
                            _poolDepositCcyIndex[pool],
                            assetsToWithdraw //minOut
                        );
                    } else {
                        remainingToWithdraw = 0;
                    }
                }
            } else {
                // in emergency mode, convert emergency to deposit and withdraw
                address emergencyCcy = EMERGENCY_CCY;
                uint256 amount = PERIPHERY.getExchangeAmount(
                    _emergencyPool,
                    depositCcy,
                    emergencyCcy,
                    remainingToWithdraw
                );
                if (amount == 0) {
                    revert FijaInsufficientAmountToWithdraw();
                }

                uint256 emergencyCCyAmount = (amount *
                    (BASIS_POINTS_DIVISOR + SLIPPAGE_EMERGENCY)) /
                    BASIS_POINTS_DIVISOR;

                // check if we have enough of emergencyCcy
                uint256 emergencyCcyBalance = IERC20(emergencyCcy).balanceOf(
                    address(this)
                );
                if (emergencyCCyAmount > emergencyCcyBalance) {
                    emergencyCCyAmount = emergencyCcyBalance;
                    remainingToWithdraw =
                        (remainingToWithdraw *
                            (BASIS_POINTS_DIVISOR - SLIPPAGE_SWAP)) /
                        BASIS_POINTS_DIVISOR;
                }

                _exchange(
                    _emergencyPool,
                    emergencyCcy,
                    depositCcy,
                    emergencyCCyAmount,
                    remainingToWithdraw
                );
            }
        }
    }

    ///
    /// @dev Helper for providing liquidity to Curve pools
    /// Used to brige difference in pool interfaces
    /// @param pool address to which liquidity is provided
    /// @param depositAmount amount in deposit tokens to provide to liquidity pools
    /// @param minMintAmount minimum amount of LP token expected to receive
    /// NOTE: some pool require use of special deposit contracts for operations
    ///
    function _addLiquidity(
        address pool,
        uint256 depositAmount,
        uint256 minMintAmount
    ) private {
        uint8 id = _poolCategory[pool][0];
        int128 depositCcyIndex = _poolDepositCcyIndex[pool];

        uint256[4] memory amounts = _buildInputAmount(
            depositAmount,
            depositCcyIndex
        );
        address depositCcy = DEPOSIT_CCY;

        address origPool;
        address depositCtr = _poolDepositCtr[pool];
        if (depositCtr != address(0)) {
            origPool = pool;
            pool = depositCtr;
        }
        if (id == 0) {
            uint256 ethValue = 0;
            if (depositCcy == ETH) {
                ethValue = depositAmount;
            }
            uint256[3] memory inputs = [amounts[0], amounts[1], amounts[2]];

            ICurve(pool).add_liquidity{value: ethValue}(inputs, minMintAmount);
        } else if (id == 1) {
            uint256[3] memory inputs = [amounts[0], amounts[1], amounts[2]];

            uint256 ethValue = 0;
            if (depositCcy == ETH) {
                ethValue = depositAmount;
            }
            ICurve(pool).add_liquidity{value: ethValue}(
                inputs,
                minMintAmount,
                true
            );
        } else if (id == 2) {
            uint256[2] memory inputs = [amounts[0], amounts[1]];

            uint256 ethValue = 0;
            if (depositCcy == ETH) {
                ethValue = depositAmount;
            }
            ICurve(pool).add_liquidity{value: ethValue}(inputs, minMintAmount);
        } else if (id == 3) {
            ICurve(pool).add_liquidity(amounts, minMintAmount);
        } else if (id == 4) {
            uint256[2] memory inputs = [amounts[0], amounts[1]];

            uint256 ethValue = 0;
            if (depositCcy == ETH) {
                ethValue = depositAmount;
            }

            ICurve(pool).add_liquidity{value: ethValue}(
                inputs,
                minMintAmount,
                true
            );
        } else if (id == 5) {
            ICurve(pool).add_liquidity(origPool, amounts, minMintAmount);
        } else if (id == 6) {
            uint256[3] memory inputs = [amounts[0], amounts[1], amounts[2]];
            ICurve(pool).add_liquidity(origPool, inputs, minMintAmount);
        } else {
            revert FijaInvalidPoolCategory();
        }
    }

    ///
    /// @dev Helper for calculating amount of deposit tokens to receive when burning LP tokens
    /// Used to brige difference in pool interfaces
    /// @param pool address of Curve liquidity pool which holds LP tokens
    /// @param burnAmount amount of LP tokens to burn
    /// @param i index indicating token position in the pool, this indicates type of token received in return
    /// @param minReceived minimum amount of deposit tokens expected to receive
    /// NOTE: some pool require use of special deposit contracts for operations
    ///
    function _removeLiquidityOneCoin(
        address pool,
        uint256 burnAmount,
        int128 i,
        uint256 minReceived
    ) private {
        uint8 id = _poolCategory[pool][1];
        address depositCtr = _poolDepositCtr[pool];

        address origPool;
        if (depositCtr != address(0)) {
            origPool = pool;
            pool = depositCtr;
        }
        if (id == 0) {
            ICurve(pool).remove_liquidity_one_coin(burnAmount, i, minReceived);
        } else if (id == 1) {
            ICurve(pool).remove_liquidity_one_coin(
                burnAmount,
                i,
                minReceived,
                true
            );
        } else if (id == 2) {
            ICurve(pool).remove_liquidity_one_coin(
                burnAmount,
                uint256(int256(i)),
                minReceived,
                true
            );
        } else if (id == 3) {
            ICurve(pool).remove_liquidity_one_coin(
                burnAmount,
                uint256(int256(i)),
                minReceived
            );
        } else if (id == 4) {
            ICurve(pool).remove_liquidity_one_coin(
                origPool,
                burnAmount,
                i,
                minReceived
            );
        } else {
            revert FijaInvalidPoolCategory();
        }
    }

    ///
    /// @dev Helper for executing swap between two tokens
    /// Used to brige difference in pool interfaces
    /// @param pool address of Curve liquidity pool
    /// @param from token address exchanging "from"
    /// @param to token address exchanging "to"
    /// @param input amount of "from" tokens to exchange
    /// @param minOut minimum amount of "to" tokens expected to receive
    /// NOTE: some pool require use of special deposit contracts for operations
    ///
    function _exchange(
        address pool,
        address from,
        address to,
        uint256 input,
        uint256 minOut
    ) private returns (uint256) {
        address poolDeposit = _poolDepositCtr[pool];
        uint8 id = _poolExchangeCategory[pool][1];

        uint256 i = _rewardPoolCoinIndex[pool][from];
        uint256 j = _rewardPoolCoinIndex[pool][to];
        if (id == 0) {
            IExchangeRegistry ex = IExchangeRegistry(
                Curve_IAddressProvider.get_address(CURVE_EXCHANGE_ID)
            );

            uint256 ethValue = 0;
            if (from == ETH) {
                ethValue = input;
            } else {
                SafeERC20.forceApprove(IERC20(from), address(ex), input);
            }
            return
                ex.exchange{value: ethValue}(
                    pool,
                    from,
                    to,
                    input,
                    minOut,
                    address(this)
                );
        } else if (id == 1) {
            address depo = pool;
            if (poolDeposit != address(0)) {
                depo = poolDeposit;
            }
            uint256 ethValue = 0;
            if (from == ETH) {
                ethValue = input;
            } else {
                SafeERC20.forceApprove(IERC20(from), depo, input);
            }

            return
                ICurve(depo).exchange{value: ethValue}(
                    i,
                    j,
                    input,
                    minOut,
                    true
                );
        } else if (id == 2) {
            uint256 ethValue = 0;
            if (from == ETH) {
                ethValue = input;
            } else {
                SafeERC20.forceApprove(IERC20(from), pool, input);
            }
            return
                ICurve(pool).exchange_underlying{value: ethValue}(
                    int128(uint128(i)),
                    int128(uint128(j)),
                    input,
                    minOut
                );
        } else if (id == 3) {
            // deposit zap
            address depo = pool;
            if (poolDeposit != address(0)) {
                depo = poolDeposit;
            }

            uint256 ethValue = 0;
            if (from == ETH) {
                ethValue = input;
            } else {
                SafeERC20.forceApprove(IERC20(from), depo, input);
            }

            return
                ICurve(depo).exchange_underlying{value: ethValue}(
                    i,
                    j,
                    input,
                    minOut
                );
        } else if (id == 4) {
            // deposit zap
            uint256 ethValue = 0;
            if (from == ETH) {
                ethValue = input;
            } else {
                SafeERC20.forceApprove(IERC20(from), poolDeposit, input);
            }
            return
                ICurve(poolDeposit).exchange{value: ethValue}(
                    pool,
                    i,
                    j,
                    input,
                    minOut
                );
        } else if (id == 5) {
            address depo = pool;
            if (poolDeposit != address(0)) {
                depo = poolDeposit;
            }
            uint256 ethValue = 0;
            if (from == ETH) {
                ethValue = input;
            } else {
                SafeERC20.forceApprove(IERC20(from), depo, input);
            }
            return
                ICurve(depo).exchange{value: ethValue}(
                    int128(uint128(i)),
                    int128(uint128(j)),
                    input,
                    minOut
                );
        } else if (id == 6) {
            // deposit zap
            address depo = pool;
            if (poolDeposit != address(0)) {
                depo = poolDeposit;
            }

            uint256 ethValue = 0;
            if (from == ETH) {
                ethValue = input;
            } else {
                SafeERC20.forceApprove(IERC20(from), depo, input);
            }

            return ICurve(depo).exchange{value: ethValue}(i, j, input, minOut);
        } else {
            revert FijaInvalidPoolCategory();
        }
    }

    receive() external payable override {}
}
