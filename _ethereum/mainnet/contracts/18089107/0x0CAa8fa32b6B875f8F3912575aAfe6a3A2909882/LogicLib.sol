//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./SafeERC20Upgradeable.sol";
import "./IERC20Upgradeable.sol";
import "./IERC20MetadataUpgradeable.sol";
import "./SafeCastUpgradeable.sol";
import "./IPool.sol";
import "./LiquidityAmounts.sol";
import "./FullMath.sol";
import "./TickMath.sol";
import "./DataTypesLib.sol";
import "./IRangeProtocolVault.sol";
import "./IPriceOracleExtended.sol";
import "./VaultErrors.sol";

/**
 * @notice LogicLib library contains the implementation logic of vault. It accepts DataTypesLib.State struct to
 * access vault state.
 */
library LogicLib {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using TickMath for int24;

    uint16 public constant MAX_PERFORMANCE_FEE_BPS = 1000;
    uint16 public constant MAX_MANAGING_FEE_BPS = 100;

    event Minted(address indexed receiver, uint256 shares, uint256 amount);
    event Burned(address indexed receiver, uint256 burnAmount, uint256 amount);
    event LiquidityAdded(
        uint256 liquidityMinted,
        int24 tickLower,
        int24 tickUpper,
        uint256 amount0In,
        uint256 amount1In
    );
    event LiquidityRemoved(
        uint256 liquidityRemoved,
        int24 tickLower,
        int24 tickUpper,
        uint256 amount0Out,
        uint256 amount1Out
    );
    event FeesEarned(uint256 feesEarned0, uint256 feesEarned1);
    event FeesUpdated(uint16 managingFee, uint16 performanceFee);
    event InThePositionStatusSet(bool inThePosition);
    event Swapped(bool zeroForOne, int256 amount0, int256 amount1);
    event TicksSet(int24 lowerTick, int24 upperTick);
    event CollateralSupplied(address token, uint256 amount);
    event CollateralWithdrawn(address token, uint256 amount);
    event GHOMinted(uint256 amount);
    event GHOBurned(uint256 amount);

    // @notice updates the tick range upon vault deployment or when the vault is out of position and totalSupply is zero.
    // It can only be called by the manager.
    // @param _lowerTick lower tick of the position.
    // @param _upperTick upper tick of the position.
    function updateTicks(DataTypesLib.State storage state, int24 _lowerTick, int24 _upperTick) external {
        if (IRangeProtocolVault(address(this)).totalSupply() != 0 || state.inThePosition)
            revert VaultErrors.NotAllowedToUpdateTicks();
        _validateTicks(_lowerTick, _upperTick, state.tickSpacing);
        state.lowerTick = _lowerTick;
        state.upperTick = _upperTick;

        emit TicksSet(_lowerTick, _upperTick);
    }

    // @notice uniswapV3 mint callback implementation.
    // @param amount0Owed amount in token0 to transfer.
    // @param amount1Owed amount in token1 to transfer.
    function uniswapV3MintCallback(
        DataTypesLib.State storage state,
        uint256 amount0Owed,
        uint256 amount1Owed
    ) external {
        if (msg.sender != address(state.pool)) revert VaultErrors.OnlyPoolAllowed();
        if (amount0Owed > 0) state.token0.safeTransfer(msg.sender, amount0Owed);
        if (amount1Owed > 0) state.token1.safeTransfer(msg.sender, amount1Owed);
    }

    // @notice uniswapV3 swap callback implementation.
    // @param amount0Delta amount0 added (+) or to be taken (-) from the vault.
    // @param amount1Delta amount1 added (+) or to be taken (-) from the vault.
    function uniswapV3SwapCallback(
        DataTypesLib.State storage state,
        int256 amount0Delta,
        int256 amount1Delta
    ) external {
        if (msg.sender != address(state.pool)) revert VaultErrors.OnlyPoolAllowed();
        if (amount0Delta > 0) state.token0.safeTransfer(msg.sender, uint256(amount0Delta));
        else if (amount1Delta > 0) state.token1.safeTransfer(msg.sender, uint256(amount1Delta));
    }

    // @notice called by the user with collateral amount to provide liquidity in collateral amount. The mint must fail
    // if the gho price is not within threshold of 0.5%.
    // @param amount the amount of collateral to provide.
    // @return shares the amount of shares minted.
    function mint(DataTypesLib.State storage state, uint256 amount) external returns (uint256 shares) {
        if (amount == 0) revert VaultErrors.InvalidCollateralAmount();
        if (!_isPriceWithinThrehold(state)) revert VaultErrors.PriceNotWithinThrehold();
        IRangeProtocolVault vault = IRangeProtocolVault(address(this));
        uint256 totalSupply = vault.totalSupply();
        if (totalSupply != 0) {
            uint256 totalAmount = getBalanceInCollateralToken(state);
            shares = FullMath.mulDivRoundingUp(amount, totalSupply, totalAmount);
        } else {
            shares = amount;
        }
        vault.mintShares(msg.sender, shares);
        if (!state.vaults[msg.sender].exists) {
            state.vaults[msg.sender].exists = true;
            state.users.push(msg.sender);
        }
        state.vaults[msg.sender].token += amount;
        IERC20Upgradeable(vault.collateralToken()).safeTransferFrom(msg.sender, address(this), amount);
        emit Minted(msg.sender, shares, amount);
    }

    // @notice called by the user with share amount to burn their vault shares redeem their share of the asset. The burn
    // must fail if the gho price is not within threshold of 0.5%.
    // @param burnAmount the amount of vault shares to burn.
    // @return shares the amount of assets in collateral token received by the user.
    function burn(DataTypesLib.State storage state, uint256 shares) external returns (uint256 amount) {
        if (shares == 0) revert VaultErrors.InvalidBurnAmount();
        if (!_isPriceWithinThrehold(state)) revert VaultErrors.PriceNotWithinThrehold();
        IRangeProtocolVault vault = IRangeProtocolVault(address(this));
        uint256 totalSupply = vault.totalSupply();
        uint256 balanceBefore = vault.balanceOf(msg.sender);
        vault.burnShares(msg.sender, shares);

        uint256 underlyingAmountInCollateralToken = getBalanceInCollateralToken(state);
        amount = FullMath.mulDiv(underlyingAmountInCollateralToken, shares, totalSupply);

        _applyManagingFee(state, amount);
        amount = _netManagingFees(state, amount);
        state.vaults[msg.sender].token = (state.vaults[msg.sender].token * (balanceBefore - shares)) / balanceBefore;

        IERC20Upgradeable(vault.collateralToken()).safeTransfer(msg.sender, amount);
        emit Burned(msg.sender, shares, amount);
    }

    // @notice called by manager to remove liquidity from the pool.
    function removeLiquidity(DataTypesLib.State storage state) external {
        (uint128 liquidity, , , , ) = state.pool.positions(getPositionID(state));
        if (liquidity != 0) {
            (uint256 amount0, uint256 amount1, uint256 fee0, uint256 fee1) = _withdraw(state, liquidity);
            emit LiquidityRemoved(liquidity, state.lowerTick, state.upperTick, amount0, amount1);

            _applyPerformanceFee(state, fee0, fee1);
            (fee0, fee1) = _netPerformanceFees(state, fee0, fee1);
            emit FeesEarned(fee0, fee1);
        }

        state.lowerTick = state.upperTick;
        state.inThePosition = false;
        emit InThePositionStatusSet(false);
    }

    // @notice called by manager to perform swap from token0 to token1 and vice-versa.
    // @param zeroForOne swap direction (true -> x to y) or (false -> y to x)
    // @param swapAmount amount to swap (+ve -> exact in, -ve exact out)
    // @param sqrtPriceLimitX96 the limit pool price can move when filling the order.
    // @param amount0 amount0 added (+) or to be taken (-) from the vault.
    // @param amount1 amount1 added (+) or to be taken (-) from the vault.
    function swap(
        DataTypesLib.State storage state,
        bool zeroForOne,
        int256 swapAmount,
        uint160 sqrtPriceLimitX96
    ) external returns (int256 amount0, int256 amount1) {
        (amount0, amount1) = state.pool.swap(address(this), zeroForOne, swapAmount, sqrtPriceLimitX96, "");
        emit Swapped(zeroForOne, amount0, amount1);
    }

    // @notice called by manager to provide liquidity to pool into a newer tick range.
    // @param newLowerTick lower tick of the position.
    // @param newUpperTick upper tick of the position.
    // @param amount0 amount in token0 to add.
    // @param amount1 amount in token1 to add.
    // @return remainingAmount0 amount in token0 left passive in the vault.
    // @return remainingAmount1 amount in token1 left passive in the vault.
    function addLiquidity(
        DataTypesLib.State storage state,
        int24 newLowerTick,
        int24 newUpperTick,
        uint256 amount0,
        uint256 amount1
    ) external returns (uint256 remainingAmount0, uint256 remainingAmount1) {
        if (state.inThePosition) revert VaultErrors.LiquidityAlreadyAdded();
        _validateTicks(newLowerTick, newUpperTick, state.tickSpacing);
        (uint160 sqrtRatioX96, , , , , , ) = state.pool.slot0();
        uint128 baseLiquidity = LiquidityAmounts.getLiquidityForAmounts(
            sqrtRatioX96,
            newLowerTick.getSqrtRatioAtTick(),
            newUpperTick.getSqrtRatioAtTick(),
            amount0,
            amount1
        );
        if (baseLiquidity > 0) {
            (uint256 amountDeposited0, uint256 amountDeposited1) = state.pool.mint(
                address(this),
                newLowerTick,
                newUpperTick,
                baseLiquidity,
                ""
            );
            emit LiquidityAdded(baseLiquidity, newLowerTick, newUpperTick, amountDeposited0, amountDeposited1);

            remainingAmount0 = amount0 - amountDeposited0;
            remainingAmount1 = amount1 - amountDeposited1;
            state.lowerTick = newLowerTick;
            state.upperTick = newUpperTick;
            emit TicksSet(newLowerTick, newUpperTick);

            state.inThePosition = true;
            emit InThePositionStatusSet(true);
        }
    }

    // @notice called by manager to transfer the unclaimed fee from pool to the vault.
    function pullFeeFromPool(DataTypesLib.State storage state) external {
        (, , uint256 fee0, uint256 fee1) = _withdraw(state, 0);
        _applyPerformanceFee(state, fee0, fee1);
        (fee0, fee1) = _netPerformanceFees(state, fee0, fee1);
        emit FeesEarned(fee0, fee1);
    }

    // @notice called by manager to collect fee from the vault.
    function collectManager(DataTypesLib.State storage state, address manager) external {
        uint256 balance0 = state.managerBalance0;
        uint256 balance1 = state.managerBalance1;
        state.managerBalance0 = 0;
        state.managerBalance1 = 0;

        if (balance0 != 0) state.token0.safeTransfer(manager, balance0);
        if (balance1 != 0) state.token1.safeTransfer(manager, balance1);
    }

    // @notice called by the manager to update the fees.
    // @param newManagingFee new managing fee percentage out of 10_000.
    // @param newPerformanceFee new performance fee percentage out of 10_000.
    function updateFees(DataTypesLib.State storage state, uint16 newManagingFee, uint16 newPerformanceFee) external {
        if (newManagingFee > MAX_MANAGING_FEE_BPS) revert VaultErrors.InvalidManagingFee();
        if (newPerformanceFee > MAX_PERFORMANCE_FEE_BPS) revert VaultErrors.InvalidPerformanceFee();

        state.managingFee = newManagingFee;
        state.performanceFee = newPerformanceFee;
        emit FeesUpdated(newManagingFee, newPerformanceFee);
    }

    // @notice supplied collateral to Aave. Called by manager only.
    // @param supplyAmount amount of collateral to supply.
    function supplyCollateral(DataTypesLib.State storage state, uint256 supplyAmount) external {
        IPool aavePool = IPool(state.poolAddressesProvider.getPool());
        IERC20Upgradeable collateralToken = IERC20Upgradeable(IRangeProtocolVault(address(this)).collateralToken());
        collateralToken.approve(address(aavePool), supplyAmount);
        aavePool.supply(address(collateralToken), supplyAmount, address(this), 0);
        emit CollateralSupplied(address(collateralToken), supplyAmount);
    }

    // @notice withdraws collateral from Aave. Called by manager only.
    // @param withdrawAmount amount of collateral to withdraw.
    function withdrawCollateral(DataTypesLib.State storage state, uint256 withdrawAmount) external {
        address collateralToken = IRangeProtocolVault(address(this)).collateralToken();
        IPool(state.poolAddressesProvider.getPool()).withdraw(collateralToken, withdrawAmount, address(this));
        emit CollateralWithdrawn(collateralToken, withdrawAmount);
    }

    // @notice borrows GHO token from Aave. Called by manager only.
    // @param mint amount of GHO to mint.
    function mintGHO(DataTypesLib.State storage state, uint256 mintAmount) external {
        uint256 interestRateMode = 2; // open debt at a variable rate
        IPool(state.poolAddressesProvider.getPool()).borrow(
            IRangeProtocolVault(address(this)).gho(),
            mintAmount,
            interestRateMode,
            0,
            address(this)
        );
        emit GHOMinted(mintAmount);
    }

    // @notice payback GHO debt to Aave. Called by manager only.
    // @param burnAmount amount of GHO debt to payback.
    function burnGHO(DataTypesLib.State storage state, uint256 burnAmount) external {
        IPool aavePool = IPool(state.poolAddressesProvider.getPool());
        IERC20Upgradeable gho = IERC20Upgradeable(IRangeProtocolVault(address(this)).gho());
        gho.approve(address(aavePool), burnAmount);
        uint256 interestRateMode = 2; // remove debt opened at a variable rate.
        aavePool.repay(address(gho), burnAmount, interestRateMode, address(this));
        emit GHOBurned(burnAmount);
    }

    /**
     * @notice returns current unclaimed fees from the pool. Calls getCurrentFees on the LogicLib.
     * @return fee0 fee in token0
     * @return fee1 fee in token1
     */
    function getCurrentFees(DataTypesLib.State storage state) external view returns (uint256 fee0, uint256 fee1) {
        (
            uint128 liquidity,
            uint256 feeGrowthInside0Last,
            uint256 feeGrowthInside1Last,
            uint128 tokensOwed0,
            uint128 tokensOwed1
        ) = state.pool.positions(getPositionID(state));
        (, int24 tick, , , , , ) = state.pool.slot0();
        fee0 = _feesEarned(state, true, feeGrowthInside0Last, tick, liquidity) + uint256(tokensOwed0);
        fee1 = _feesEarned(state, false, feeGrowthInside1Last, tick, liquidity) + uint256(tokensOwed1);
        (fee0, fee1) = _netPerformanceFees(state, fee0, fee1);
    }

    /**
     * @notice returns user vaults based on the provided index. Calls getUserVaults on LogicLib.
     * @param fromIdx the starting index to fetch users.
     * @param toIdx the ending index to fetch users.
     * @return UserVaultInfo
     */
    function getUserVaults(
        DataTypesLib.State storage state,
        uint256 fromIdx,
        uint256 toIdx
    ) external view returns (DataTypesLib.UserVaultInfo[] memory) {
        if (fromIdx == 0 && toIdx == 0) {
            toIdx = state.users.length;
        }
        DataTypesLib.UserVaultInfo[] memory usersVaultInfo = new DataTypesLib.UserVaultInfo[](toIdx - fromIdx);
        uint256 count;
        for (uint256 i = fromIdx; i < toIdx; i++) {
            DataTypesLib.UserVault memory userVault = state.vaults[state.users[i]];
            usersVaultInfo[count++] = DataTypesLib.UserVaultInfo({user: state.users[i], token: userVault.token});
        }
        return usersVaultInfo;
    }

    // @notice returns position id of the vault in pool.
    // @return positionId the id of the position in pool.
    function getPositionID(DataTypesLib.State storage state) public view returns (bytes32 positionID) {
        return keccak256(abi.encodePacked(address(this), state.lowerTick, state.upperTick));
    }

    struct LocalVars {
        uint256 amount0FromPool;
        uint256 amount1FromPool;
        uint256 amount0FromAave;
        uint256 amount1FromAave;
        int256 token0BalanceSigned;
        int256 token1BalanceSigned;
        uint256 decimals0;
        uint256 decimals1;
    }

    // @notice returns vault asset's balance in collateral token. It gets balances from the following three places.
    // Gets token0 and token1 balance from the AMM pool. Converts gho token amount to collateral token.
    // Gets collateral deposited to Aave and gho borrowed. Subtracts borrowed gho amount converted to collateral from
    // collateral amount.
    // Gets collateral and gho amounts sitting passive in the contract.
    // If the gho debt in Aave is greater than gho balance in AMM pool + gho balance passive in the contract then deficit
    // in gho is converted to collateral token and subtracted from the collateral amount to account for the gho deficit.
    // Additionally, to avoid underflow the managerBalance is only subtracted from the vault balance if it is less than the
    // vault balance.
    // @return amount the amount of vault holding converted to collateral token.
    function getBalanceInCollateralToken(DataTypesLib.State storage state) public view returns (uint256 amount) {
        (, int256 collateralPrice, , , ) = state.collateralTokenPriceFeed.latestRoundData();
        (, int256 ghoPrice, , , ) = state.ghoPriceFeed.latestRoundData();
        (uint160 sqrtRatioX96, int24 tick, , , , , ) = state.pool.slot0();

        LocalVars memory vars;
        (vars.amount0FromPool, vars.amount1FromPool) = getUnderlyingBalancesFromPool(state, sqrtRatioX96, tick);
        (vars.amount0FromAave, vars.amount1FromAave) = getUnderlyingBalancesFromAave(
            state,
            uint256(ghoPrice),
            uint256(collateralPrice)
        );
        (vars.decimals0, vars.decimals1) = (state.decimals0, state.decimals1);

        if (state.isToken0GHO) {
            vars.token0BalanceSigned = int256(
                vars.amount0FromPool + state.token0.balanceOf(address(this)) - vars.amount0FromAave
            );
            vars.token1BalanceSigned = int256(
                vars.amount1FromPool + state.token1.balanceOf(address(this)) + vars.amount1FromAave
            );

            if (vars.token0BalanceSigned < 0) {
                uint256 ghoDeficitInCollateralToken = (uint256(-vars.token0BalanceSigned) *
                    10 ** vars.decimals1 *
                    uint256(ghoPrice)) /
                    uint256(collateralPrice) /
                    10 ** vars.decimals0;
                vars.token1BalanceSigned -= int256(ghoDeficitInCollateralToken);
            }
        } else {
            vars.token0BalanceSigned = int256(
                vars.amount0FromPool + state.token0.balanceOf(address(this)) + vars.amount0FromAave
            );
            vars.token1BalanceSigned = int256(
                vars.amount1FromPool + state.token1.balanceOf(address(this)) - vars.amount1FromAave
            );

            if (vars.token1BalanceSigned < 0) {
                uint256 ghoDeficitInCollateralToken = (uint256(-vars.token1BalanceSigned) *
                    10 ** vars.decimals0 *
                    uint256(ghoPrice)) /
                    uint256(collateralPrice) /
                    10 ** vars.decimals1;
                vars.token0BalanceSigned -= int256(ghoDeficitInCollateralToken);
            }
        }

        uint256 amount0 = vars.token0BalanceSigned > int256(state.managerBalance0)
            ? uint256(vars.token0BalanceSigned) - state.managerBalance0
            : 0;
        uint256 amount1 = vars.token1BalanceSigned > int256(state.managerBalance1)
            ? uint256(vars.token1BalanceSigned) - state.managerBalance1
            : 0;

        if (state.isToken0GHO) {
            amount0 =
                (amount0 * 10 ** state.decimals1 * uint256(ghoPrice)) /
                uint256(collateralPrice) /
                10 ** state.decimals0;
        } else {
            amount1 =
                (amount1 * 10 ** state.decimals0 * uint256(ghoPrice)) /
                uint256(collateralPrice) /
                10 ** state.decimals1;
        }
        return amount0 + amount1;
    }

    // @notice returns underlying balance in collateral token based on the shares amount passed.
    // @param shares amount of vault to calculate the redeemable amount against.
    // @return amount the amount of asset in collateral token redeemable against the provided amount of collateral.
    function getUnderlyingBalanceByShare(
        DataTypesLib.State storage state,
        uint256 shares
    ) external view returns (uint256 amount) {
        uint256 _totalSupply = IRangeProtocolVault(address(this)).totalSupply();
        if (_totalSupply != 0) {
            uint256 totalUnderlyingBalanceInCollateralToken = getBalanceInCollateralToken(state);
            amount = (shares * totalUnderlyingBalanceInCollateralToken) / _totalSupply;
            amount = _netManagingFees(state, amount);
        }
    }

    // @notice returns amount0 and amount1 from the AMM pool.
    // @param amount0 the amount in token0 from AMM pool.
    // @param amount1 the amount in token1 from AMM pool.
    function getUnderlyingBalancesFromPool(
        DataTypesLib.State storage state,
        uint160 sqrtRatioX96,
        int24 tick
    ) public view returns (uint256 amount0, uint256 amount1) {
        (
            uint128 liquidity,
            uint256 feeGrowthInside0Last,
            uint256 feeGrowthInside1Last,
            uint128 tokensOwed0,
            uint128 tokensOwed1
        ) = state.pool.positions(getPositionID(state));
        if (liquidity != 0) {
            (amount0, amount1) = LiquidityAmounts.getAmountsForLiquidity(
                sqrtRatioX96,
                state.lowerTick.getSqrtRatioAtTick(),
                state.upperTick.getSqrtRatioAtTick(),
                liquidity
            );
            uint256 fee0 = _feesEarned(state, true, feeGrowthInside0Last, tick, liquidity) + uint256(tokensOwed0);
            uint256 fee1 = _feesEarned(state, false, feeGrowthInside1Last, tick, liquidity) + uint256(tokensOwed1);
            (fee0, fee1) = _netPerformanceFees(state, fee0, fee1);

            amount0 += fee0;
            amount1 += fee1;
        }
    }

    // @notice returns the supplied collateral and borrowed from Aave.
    // @param amount0 collateral supplied to Aave if token0 is collateral token else gho amount borrowed.
    // @param amount1 collateral supplied to Aave if token1 is collateral token else gho amount borrowed.
    function getUnderlyingBalancesFromAave(
        DataTypesLib.State storage state,
        uint256 ghoPrice,
        uint256 collateralTokenPrice
    ) public view returns (uint256 amount0, uint256 amount1) {
        (uint256 totalCollateralBase, uint256 totalDebtBase, , , , ) = IPool(state.poolAddressesProvider.getPool())
            .getUserAccountData(address(this));

        uint256 BASE_CURRENCY_UNIT = IPriceOracleExtended(state.poolAddressesProvider.getPriceOracle())
            .BASE_CURRENCY_UNIT();
        (amount0, amount1) = state.isToken0GHO
            ? (
                (totalDebtBase * 10 ** state.decimals0) / ghoPrice / BASE_CURRENCY_UNIT,
                (totalCollateralBase * 10 ** state.decimals1) / collateralTokenPrice / BASE_CURRENCY_UNIT
            )
            : (
                (totalCollateralBase * 10 ** state.decimals0) / collateralTokenPrice / BASE_CURRENCY_UNIT,
                (totalDebtBase * 10 ** state.decimals1) / ghoPrice / BASE_CURRENCY_UNIT
            );
    }

    // @notice transfer hook to transfer the exposure from sender to recipient.
    // @param from the sender of vault shares.
    // @param to recipient of vault shares.
    // @param amount amount of vault shares to transfer.
    function _beforeTokenTransfer(DataTypesLib.State storage state, address from, address to, uint256 amount) external {
        IRangeProtocolVault vault = IRangeProtocolVault(address(this));
        if (from == address(0x0) || to == address(0x0)) return;
        if (!state.vaults[to].exists) {
            state.vaults[to].exists = true;
            state.users.push(to);
        }
        uint256 senderBalance = vault.balanceOf(from);
        uint256 tokenAmount = state.vaults[from].token -
            (state.vaults[from].token * (senderBalance - amount)) /
            senderBalance;

        state.vaults[from].token -= tokenAmount;
        state.vaults[to].token += tokenAmount;
    }

    /**
     * @notice returns Aave position data.
     * @return totalCollateralBase total collateral supplied.
     * @return totalDebtBase total debt borrowed.
     * @return availableBorrowsBase available amount to borrow.
     * @return currentLiquidationThreshold current threshold for liquidation to trigger.
     * @return ltv Loan-to-value ratio of the position.
     * @return healthFactor current health factor of the position.
     */
    function getAavePositionData(
        DataTypesLib.State storage state
    )
        external
        view
        returns (
            uint256 totalCollateralBase,
            uint256 totalDebtBase,
            uint256 availableBorrowsBase,
            uint256 currentLiquidationThreshold,
            uint256 ltv,
            uint256 healthFactor
        )
    {
        return IPool(state.poolAddressesProvider.getPool()).getUserAccountData(address(this));
    }

    // @notice validated the lower and upper ticks.
    function _validateTicks(int24 _lowerTick, int24 _upperTick, int24 tickSpacing) private pure {
        if (_lowerTick < TickMath.MIN_TICK || _upperTick > TickMath.MAX_TICK) revert VaultErrors.TicksOutOfRange();
        if (_lowerTick >= _upperTick || _lowerTick % tickSpacing != 0 || _upperTick % tickSpacing != 0)
            revert VaultErrors.InvalidTicksSpacing();
    }

    // @notice internal function that withdraws liquidity from the AMM pool.
    // @param liquidity the amount liquidity to withdraw from the AMM pool.
    // @return burn0 amount of token0 received from burning liquidity.
    // @return burn1 amount of token1 received from burning liquidity.
    // @return fee0 amount of fee in token0 collected.
    // @return fee1 amount of fee in token1 collected.
    function _withdraw(
        DataTypesLib.State storage state,
        uint128 liquidity
    ) internal returns (uint256 burn0, uint256 burn1, uint256 fee0, uint256 fee1) {
        int24 _lowerTick = state.lowerTick;
        int24 _upperTick = state.upperTick;
        uint256 preBalance0 = state.token0.balanceOf(address(this));
        uint256 preBalance1 = state.token1.balanceOf(address(this));
        (burn0, burn1) = state.pool.burn(_lowerTick, _upperTick, liquidity);
        state.pool.collect(address(this), _lowerTick, _upperTick, type(uint128).max, type(uint128).max);
        fee0 = state.token0.balanceOf(address(this)) - preBalance0 - burn0;
        fee1 = state.token1.balanceOf(address(this)) - preBalance1 - burn1;
    }

    // @notice returns the amount of fee earned based on the feeGrowth factor.
    function _feesEarned(
        DataTypesLib.State storage state,
        bool isZero,
        uint256 feeGrowthInsideLast,
        int24 tick,
        uint128 liquidity
    ) private view returns (uint256 fee) {
        uint256 feeGrowthOutsideLower;
        uint256 feeGrowthOutsideUpper;
        uint256 feeGrowthGlobal;
        if (isZero) {
            feeGrowthGlobal = state.pool.feeGrowthGlobal0X128();
            (, , feeGrowthOutsideLower, , , , , ) = state.pool.ticks(state.lowerTick);
            (, , feeGrowthOutsideUpper, , , , , ) = state.pool.ticks(state.upperTick);
        } else {
            feeGrowthGlobal = state.pool.feeGrowthGlobal1X128();
            (, , , feeGrowthOutsideLower, , , , ) = state.pool.ticks(state.lowerTick);
            (, , , feeGrowthOutsideUpper, , , , ) = state.pool.ticks(state.upperTick);
        }

        unchecked {
            uint256 feeGrowthBelow;
            if (tick >= state.lowerTick) {
                feeGrowthBelow = feeGrowthOutsideLower;
            } else {
                feeGrowthBelow = feeGrowthGlobal - feeGrowthOutsideLower;
            }

            uint256 feeGrowthAbove;
            if (tick < state.upperTick) {
                feeGrowthAbove = feeGrowthOutsideUpper;
            } else {
                feeGrowthAbove = feeGrowthGlobal - feeGrowthOutsideUpper;
            }
            uint256 feeGrowthInside = feeGrowthGlobal - feeGrowthBelow - feeGrowthAbove;

            fee = FullMath.mulDiv(
                liquidity,
                feeGrowthInside - feeGrowthInsideLast,
                0x100000000000000000000000000000000
            );
        }
    }

    // @notice returns if the current of price of gho against collateral token from AMM does not deviate more than 0.5%
    // from gho price against collateral token from Chainlink price oracle.
    function _isPriceWithinThrehold(DataTypesLib.State storage state) private view returns (bool) {
        (uint160 sqrtRatioX96, , , , , , ) = state.pool.slot0();
        uint256 priceFromUniswap = FullMath.mulDiv(
            uint256(sqrtRatioX96) * uint256(sqrtRatioX96),
            10 ** state.decimals0,
            1 << 192
        );

        (, int256 collateralPrice, , , ) = state.collateralTokenPriceFeed.latestRoundData();
        (, int256 ghoPrice, , , ) = state.ghoPriceFeed.latestRoundData();

        uint256 priceFromOracle = state.isToken0GHO
            ? (10 ** state.decimals1 * uint256(ghoPrice)) / uint256(collateralPrice)
            : (10 ** state.decimals0 * uint256(collateralPrice)) / uint256(ghoPrice);

        uint256 priceRatio = (priceFromUniswap * 10000) / priceFromOracle;
        return priceRatio <= 10050 && priceRatio >= 9950;
    }

    // @notice applies managing fee to the amount.
    // @param amount the amount to apply the managing fee.
    function _applyManagingFee(DataTypesLib.State storage state, uint256 amount) private {
        if (state.isToken0GHO) state.managerBalance1 += (amount * state.managingFee) / 10_000;
        else state.managerBalance0 += (amount * state.managingFee) / 10_000;
    }

    // @notice applies performance fee to the fee0 and fee1.
    // @param fee0 the amount of fee0 to apply the performance fee.
    // @param fee1 the amount of fee1 to apply the performance fee.
    function _applyPerformanceFee(DataTypesLib.State storage state, uint256 fee0, uint256 fee1) private {
        uint256 _performanceFee = state.performanceFee;
        state.managerBalance0 += (fee0 * _performanceFee) / 10_000;
        state.managerBalance1 += (fee1 * _performanceFee) / 10_000;
    }

    // @notice deducts managing fee from the amount.
    // @param amount the amount to apply the managing fee.
    // @return amountAfterFee amount after deducting managing fee.
    function _netManagingFees(
        DataTypesLib.State storage state,
        uint256 amount
    ) private view returns (uint256 amountAfterFee) {
        uint256 deduct = (amount * state.managingFee) / 10_000;
        amountAfterFee = amount - deduct;
    }

    // @notice deducts performance fee from fee0 and fee1.
    // @param rawFee0 the amount of fee0 to apply the performance fee.
    // @param rawFee1 the amount of fee1 to apply the performance fee.
    // @param fee0AfterDeduction fee0 after performance fee deduction.
    // @param fee1AfterDeduction fee1 after performance fee deduction.
    function _netPerformanceFees(
        DataTypesLib.State storage state,
        uint256 rawFee0,
        uint256 rawFee1
    ) private view returns (uint256 fee0AfterDeduction, uint256 fee1AfterDeduction) {
        uint256 _performanceFee = state.performanceFee;
        uint256 deduct0 = (rawFee0 * _performanceFee) / 10_000;
        uint256 deduct1 = (rawFee1 * _performanceFee) / 10_000;
        fee0AfterDeduction = rawFee0 - deduct0;
        fee1AfterDeduction = rawFee1 - deduct1;
    }
}
