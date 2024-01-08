// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./SafeERC20.sol";

import "./IUniswapV3Pool.sol";

import "./FullMath.sol";
import "./LiquidityAmounts.sol";
import "./Math.sol";
import "./TickMath.sol";

import "./IAloePredictions.sol";
import "./IAloePredictionsImmutables.sol";

import "./Bounds.sol";

import "./AloePoolERC20.sol";
import "./UniswapMinter.sol";

contract AloePool is AloePoolERC20, UniswapMinter {
    using SafeERC20 for IERC20;

    event Deposit(address indexed sender, uint256 shares, uint256 amount0, uint256 amount1);

    event Withdraw(address indexed sender, uint256 shares, uint256 amount0, uint256 amount1);

    event Snapshot(int24 tick, uint256 totalAmount0, uint256 totalAmount1, uint256 totalSupply);

    /// @dev The maximum number of ticks a lower||upper bound can shift down per rebalance
    int24 public constant MAX_SHIFT_DOWN = -726; // -7%

    /// @dev The maximum number of ticks a lower||upper bound can shift up per rebalance
    int24 public constant MAX_SHIFT_UP = 677; // +7%

    /// @dev The predictions market that provides this pool with next-price distribution data
    IAloePredictions public immutable PREDICTIONS;

    /// @dev The most recent predictions market epoch during which this pool was rebalanced
    uint24 public epoch;

    /// @dev The tick corresponding to the lower price bound of our mean +/- 2 stddev position
    int24 public lower2STD;

    /// @dev The tick corresponding to the upper price bound of our mean +/- 2 stddev position
    int24 public upper2STD;

    /// @dev The tick corresponding to the lower price bound of our just-in-time position
    int24 public lowerJIT;

    /// @dev The tick corresponding to the upper price bound of our just-in-time position
    int24 public upperJIT;

    /// @dev Whether the current just-in-time position was left of the active range when placed
    bool public didPlaceLeftJIT;

    /// @dev For reentrancy check
    bool private locked;

    modifier lock() {
        require(!locked, "Aloe: Locked");
        locked = true;
        _;
        locked = false;
    }

    constructor(address predictions)
        AloePoolERC20()
        UniswapMinter(IUniswapV3Pool(IAloePredictionsImmutables(predictions).UNI_POOL()))
    {
        PREDICTIONS = IAloePredictions(predictions);
        (Bounds memory bounds, bool areInverted) = IAloePredictions(predictions).current();
        (lower2STD, upper2STD) = _getNextTicks(bounds, areInverted);
    }

    /**
     * @notice Calculates the vault's total holdings of TOKEN0 and TOKEN1 - in
     * other words, how much of each token the vault would hold if it withdrew
     * all its liquidity from Uniswap.
     */
    function getReserves() public view returns (uint256 reserve0, uint256 reserve1) {
        (uint256 amount2STD0, uint256 amount2STD1) = _collectableAmountsAsOfLastPoke(lower2STD, upper2STD);
        (uint256 amountJIT0, uint256 amountJIT1) = _collectableAmountsAsOfLastPoke(lowerJIT, upperJIT);
        reserve0 = TOKEN0.balanceOf(address(this)) + amount2STD0 + amountJIT0;
        reserve1 = TOKEN1.balanceOf(address(this)) + amount2STD1 + amountJIT1;
    }

    function getNextTicks() public view returns (int24 lower, int24 upper) {
        (Bounds memory bounds, bool areInverted) = PREDICTIONS.current();
        return _getNextTicks(bounds, areInverted);
    }

    function _getNextTicks(Bounds memory bounds, bool areInverted) private pure returns (int24 lower, int24 upper) {
        uint160 sqrtPriceX96;

        if (areInverted) {
            sqrtPriceX96 = uint160(uint256(type(uint128).max) / Math.sqrt(bounds.lower << 80));
            lower = TickMath.getTickAtSqrtRatio(sqrtPriceX96);
            sqrtPriceX96 = uint160(uint256(type(uint128).max) / Math.sqrt(bounds.upper << 80));
            upper = TickMath.getTickAtSqrtRatio(sqrtPriceX96);
        } else {
            sqrtPriceX96 = uint160(Math.sqrt(bounds.lower << 80) << 32);
            lower = TickMath.getTickAtSqrtRatio(sqrtPriceX96);
            sqrtPriceX96 = uint160(Math.sqrt(bounds.upper << 80) << 32);
            upper = TickMath.getTickAtSqrtRatio(sqrtPriceX96);
        }
    }

    /**
     * @notice Deposits tokens in proportion to the vault's current holdings.
     * @dev These tokens sit in the vault and are not used for liquidity on
     * Uniswap until the next rebalance. Also note it's not necessary to check
     * if user manipulated price to deposit cheaper, as the value of range
     * orders can only by manipulated higher.
     * @dev LOCK MODIFIER IS APPLIED IN AloePoolCapped!!!
     * @param amount0Max Max amount of TOKEN0 to deposit
     * @param amount1Max Max amount of TOKEN1 to deposit
     * @param amount0Min Ensure `amount0` is greater than this
     * @param amount1Min Ensure `amount1` is greater than this
     * @return shares Number of shares minted
     * @return amount0 Amount of TOKEN0 deposited
     * @return amount1 Amount of TOKEN1 deposited
     */
    function deposit(
        uint256 amount0Max,
        uint256 amount1Max,
        uint256 amount0Min,
        uint256 amount1Min
    )
        public
        virtual
        returns (
            uint256 shares,
            uint256 amount0,
            uint256 amount1
        )
    {
        require(amount0Max != 0 || amount1Max != 0, "Aloe: 0 deposit");

        _uniswapPoke(lower2STD, upper2STD);
        _uniswapPoke(lowerJIT, upperJIT);

        (shares, amount0, amount1) = _computeLPShares(amount0Max, amount1Max);
        require(shares != 0, "Aloe: 0 shares");
        require(amount0 >= amount0Min, "Aloe: amount0 too low");
        require(amount1 >= amount1Min, "Aloe: amount1 too low");

        // Pull in tokens from sender
        if (amount0 != 0) TOKEN0.safeTransferFrom(msg.sender, address(this), amount0);
        if (amount1 != 0) TOKEN1.safeTransferFrom(msg.sender, address(this), amount1);

        // Mint shares
        _mint(msg.sender, shares);
        emit Deposit(msg.sender, shares, amount0, amount1);
    }

    /// @dev Calculates the largest possible `amount0` and `amount1` such that
    /// they're in the same proportion as total amounts, but not greater than
    /// `amount0Max` and `amount1Max` respectively.
    function _computeLPShares(uint256 amount0Max, uint256 amount1Max)
        internal
        view
        returns (
            uint256 shares,
            uint256 amount0,
            uint256 amount1
        )
    {
        uint256 totalSupply = totalSupply();
        (uint256 reserve0, uint256 reserve1) = getReserves();

        // If total supply > 0, pool can't be empty
        assert(totalSupply == 0 || reserve0 != 0 || reserve1 != 0);

        if (totalSupply == 0) {
            // For first deposit, just use the amounts desired
            amount0 = amount0Max;
            amount1 = amount1Max;
            shares = amount0 > amount1 ? amount0 : amount1; // max
        } else if (reserve0 == 0) {
            amount1 = amount1Max;
            shares = FullMath.mulDiv(amount1, totalSupply, reserve1);
        } else if (reserve1 == 0) {
            amount0 = amount0Max;
            shares = FullMath.mulDiv(amount0, totalSupply, reserve0);
        } else {
            amount0 = FullMath.mulDiv(amount1Max, reserve0, reserve1);

            if (amount0 < amount0Max) {
                amount1 = amount1Max;
                shares = FullMath.mulDiv(amount1, totalSupply, reserve1);
            } else {
                amount0 = amount0Max;
                amount1 = FullMath.mulDiv(amount0, reserve1, reserve0);
                shares = FullMath.mulDiv(amount0, totalSupply, reserve0);
            }
        }
    }

    /**
     * @notice Withdraws tokens in proportion to the vault's holdings.
     * @param shares Shares burned by sender
     * @param amount0Min Revert if resulting `amount0` is smaller than this
     * @param amount1Min Revert if resulting `amount1` is smaller than this
     * @return amount0 Amount of TOKEN0 sent to recipient
     * @return amount1 Amount of TOKEN1 sent to recipient
     */
    function withdraw(
        uint256 shares,
        uint256 amount0Min,
        uint256 amount1Min
    ) external lock returns (uint256 amount0, uint256 amount1) {
        require(shares != 0, "Aloe: 0 shares");
        uint256 totalSupply = totalSupply() + 1;

        // Calculate token amounts proportional to unused balances
        amount0 = FullMath.mulDiv(TOKEN0.balanceOf(address(this)), shares, totalSupply);
        amount1 = FullMath.mulDiv(TOKEN1.balanceOf(address(this)), shares, totalSupply);

        // Withdraw proportion of liquidity from Uniswap pool
        uint256 temp0;
        uint256 temp1;
        (temp0, temp1) = _uniswapExitFraction(shares, totalSupply, lower2STD, upper2STD);
        amount0 += temp0;
        amount1 += temp1;
        (temp0, temp1) = _uniswapExitFraction(shares, totalSupply, lowerJIT, upperJIT);
        amount0 += temp0;
        amount1 += temp1;

        // Check constraints
        require(amount0 >= amount0Min, "Aloe: amount0 too low");
        require(amount1 >= amount1Min, "Aloe: amount1 too low");

        // Transfer tokens
        if (amount0 != 0) TOKEN0.safeTransfer(msg.sender, amount0);
        if (amount1 != 0) TOKEN1.safeTransfer(msg.sender, amount1);

        // Burn shares
        _burn(msg.sender, shares);
        emit Withdraw(msg.sender, shares, amount0, amount1);
    }

    /// @dev Withdraws share of liquidity in a range from Uniswap pool. All fee earnings
    /// will be collected and left unused afterwards
    function _uniswapExitFraction(
        uint256 numerator,
        uint256 denominator,
        int24 tickLower,
        int24 tickUpper
    ) internal returns (uint256 amount0, uint256 amount1) {
        assert(numerator < denominator);

        (uint128 liquidity, , , , ) = _position(tickLower, tickUpper);
        liquidity = uint128(FullMath.mulDiv(liquidity, numerator, denominator));

        uint256 earned0;
        uint256 earned1;
        (amount0, amount1, earned0, earned1) = _uniswapExit(tickLower, tickUpper, liquidity);

        // Add share of fees
        amount0 += FullMath.mulDiv(earned0, numerator, denominator);
        amount1 += FullMath.mulDiv(earned1, numerator, denominator);
    }

    /**
     * @notice Updates vault's positions. Can only be called by the strategy.
     * @dev Two orders are placed - a base order and a limit order. The base
     * order is placed first with as much liquidity as possible. This order
     * should use up all of one token, leaving only the other one. This excess
     * amount is then placed as a single-sided bid or ask order.
     */
    function rebalance() external lock {
        uint24 _epoch = PREDICTIONS.epoch();
        require(_epoch > epoch, "Aloe: Too early");
        epoch = _epoch;

        int24 lower2STDOld = lower2STD;
        int24 upper2STDOld = upper2STD;

        // Extract target lower & upper ticks from predictions market
        (int24 lower2STDNew, int24 upper2STDNew) = getNextTicks();
        lower2STDNew = _constrainTickShift(lower2STDOld, lower2STDNew);
        upper2STDNew = _constrainTickShift(upper2STDOld, upper2STDNew);
        (lower2STDNew, upper2STDNew) = _coerceTicksToSpacing(lower2STDNew, upper2STDNew);

        // Only perform rebalance if lower||upper tick has changed
        if (lower2STDNew != lower2STDOld || upper2STDNew != upper2STDOld) {
            (uint160 sqrtPriceX96, int24 tick, , , , , ) = UNI_POOL.slot0();

            // Exit all current Uniswap positions
            {
                (uint128 liquidity2STD, , , , ) = _position(lower2STDOld, upper2STDOld);
                (uint128 liquidityJIT, , , , ) = _position(lowerJIT, upperJIT);
                _uniswapExit(lower2STDOld, upper2STDOld, liquidity2STD);
                _uniswapExit(lowerJIT, upperJIT, liquidityJIT);
            }

            // Emit snapshot to record balances and supply
            uint256 balance0 = TOKEN0.balanceOf(address(this));
            uint256 balance1 = TOKEN1.balanceOf(address(this));
            emit Snapshot(tick, balance0, balance1, totalSupply());

            // Place base order on Uniswap
            uint128 liquidity = _liquidityForAmounts(lower2STDNew, upper2STDNew, sqrtPriceX96, balance0, balance1);
            _uniswapEnter(lower2STDNew, upper2STDNew, liquidity);
            (lower2STD, upper2STD) = (lower2STDNew, upper2STDNew);

            // Place naive JIT order on Uniswap
            (int24 upperL, int24 lowerR) = _coerceTicksToSpacing(tick, tick);
            _snipe(upperL, lowerR);
        }
    }

    function snipe() external lock {
        int24 _lowerJIT = lowerJIT;
        int24 _upperJIT = upperJIT;
        (, int24 tick, , , , , ) = UNI_POOL.slot0();

        // If JIT position is active range, don't touch it
        if (_lowerJIT < tick && tick < _upperJIT) return;

        // If JIT position is adjacent to active range, don't touch it
        (int24 upperL, int24 lowerR) = _coerceTicksToSpacing(tick, tick);
        if (_upperJIT == upperL || _lowerJIT == lowerR) return;

        // Exit current JIT position
        (uint128 liquidityJIT, , , , ) = _position(_lowerJIT, _upperJIT);
        _uniswapExit(_lowerJIT, _upperJIT, liquidityJIT);

        // Enter new JIT position (earned fees get reset to 0)
        _snipe(upperL, lowerR);
    }

    function takeBounty() external lock {
        int24 _lowerJIT = lowerJIT;
        int24 _upperJIT = upperJIT;

        // Poke and check earnable fees
        UNI_POOL.burn(_lowerJIT, _upperJIT, 0);
        (, , , uint128 earnable0, uint128 earnable1) = _position(_lowerJIT, _upperJIT);

        if (didPlaceLeftJIT) {
            require(earnable1 == 0, "Aloe: Bidirectional");
            UNI_POOL.collect(msg.sender, _lowerJIT, _upperJIT, earnable0, 0);
        } else {
            require(earnable0 == 0, "Aloe: Bidirectional");
            UNI_POOL.collect(msg.sender, _lowerJIT, _upperJIT, 0, earnable1);
        }
    }

    /// @dev Allocates entire balance of _either_ TOKEN0 or TOKEN1 to as tight a position as possible,
    /// with one edge on the current active range.
    function _snipe(int24 upperL, int24 lowerR) private {
        int24 tickSpacing = TICK_SPACING;
        uint256 balance0 = TOKEN0.balanceOf(address(this));
        uint256 balance1 = TOKEN1.balanceOf(address(this));

        // TODO Won't have to compute both liquidity amounts if _all_ of one token gets used
        // in main position (as would be the case when fixing one bound and one balance)
        uint128 liquidityL = _liquidityForAmount1(upperL - tickSpacing, upperL, balance1);
        uint128 liquidityR = _liquidityForAmount0(lowerR, lowerR + tickSpacing, balance0);
        if (liquidityL > liquidityR) {
            _uniswapEnter(upperL - tickSpacing, upperL, liquidityL);
            (lowerJIT, upperJIT) = (upperL - tickSpacing, upperL);
            didPlaceLeftJIT = true;
        } else {
            _uniswapEnter(lowerR, lowerR + tickSpacing, liquidityR);
            (lowerJIT, upperJIT) = (lowerR, lowerR + tickSpacing);
            didPlaceLeftJIT = false;
        }
    }

    function _constrainTickShift(int24 tickOld, int24 tickNew) private pure returns (int24) {
        if (tickNew < tickOld + MAX_SHIFT_DOWN) {
            return tickOld + MAX_SHIFT_DOWN;
        } else if (tickNew > tickOld + MAX_SHIFT_UP) {
            return tickOld + MAX_SHIFT_UP;
        }
        return tickNew;
    }

    function _coerceTicksToSpacing(int24 tickLower, int24 tickUpper)
        private
        view
        returns (int24 tickLowerCoerced, int24 tickUpperCoerced)
    {
        tickLowerCoerced =
            tickLower -
            (tickLower < 0 ? TICK_SPACING + (tickLower % TICK_SPACING) : tickLower % TICK_SPACING);
        tickUpperCoerced =
            tickUpper +
            (tickUpper < 0 ? -tickUpper % TICK_SPACING : TICK_SPACING - (tickUpper % TICK_SPACING));
        assert(tickLowerCoerced <= tickLower);
        assert(tickUpperCoerced >= tickUpper);
    }
}
