// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

// ====================================================================
// ========================= MarketMaker.sol ==========================
// ====================================================================

/**
 * @title MarketMaker
 * @dev Implementation:
Borrow SWEEP, exchange USDC and place it into a Uniswap V3 AMM as single-sided liquidity
Remove any LP positions that are converted to SWEEP, and repay it
*/

import "./LiquidityHelper.sol";
import "./Stabilizer.sol";

contract MarketMaker is Stabilizer {
    // Uniswap V3 Position Manager
    INonfungiblePositionManager public constant nonfungiblePositionManager =
        INonfungiblePositionManager(0xC36442b4a4522E871399CD717aBDD847Ab11FE88);
    LiquidityHelper private immutable liquidityHelper;

    // Details about position
    struct Position {
        uint128 liquidity;
        int24 tickLower;
        int24 tickUpper;
        uint24 fee;
        uint256 token0Amount;
        uint256 token1Amount;
    }

    uint256[] public positionIds;
    uint256[] private removeIds;

    // Map tokenId to Position
    mapping(uint256 => Position) public positions;

    address public token0;
    address public token1;
    bool private immutable flag; // The sort status of tokens

    // Spread Variables
    uint256 public topSpread;
    uint256 public bottomSpread;
    uint256 public tickSpread;

    // Constants
    uint24 private constant PRECISION = 1e6;

    // Events
    event Minted(uint256 tokenId, uint128 liquidity);
    event Burned(uint256 tokenId);

    constructor(
        string memory _name,
        address _sweep,
        address _usdx,
        address _liquidityHelper,
        address _oracleUsdx,
        address _borrower,
        uint256 _topSpread,
        uint256 _bottomSpread,
        uint256 _tickSpread
    ) Stabilizer(_name, _sweep, _usdx, _oracleUsdx, _borrower) {
        flag = _usdx < _sweep;
        (token0, token1) = flag ? (_usdx, _sweep) : (_sweep, _usdx);
        liquidityHelper = LiquidityHelper(_liquidityHelper);
        minEquityRatio = 0;
        topSpread = _topSpread;
        bottomSpread = _bottomSpread;
        tickSpread = _tickSpread;
    }

    /* ========== Simple Marketmaker Actions ========== */

    /**
     * @notice Execute operation to peg to target price of SWEEP.
     */
    function execute(uint256 sweepAmount) external nonReentrant {
        uint256 targetPrice = sweep.targetPrice();
        uint256 arbPriceUpper = ((PRECISION + topSpread) * targetPrice) /
            PRECISION;
        uint256 arbPriceLower = ((PRECISION - bottomSpread) * targetPrice) /
            PRECISION;

        uint24 poolFee = amm().poolFee();

        if (sweep.ammPrice() > arbPriceUpper) {
            uint256 usdxAmount = sellSweepToAMM(sweepAmount);
            uint256 minPrice = ((PRECISION - tickSpread) * targetPrice) /
                PRECISION;
            uint256 maxPrice = targetPrice;

            addSingleLiquidity(minPrice, maxPrice, usdxAmount, poolFee);
        }

        if (sweep.ammPrice() < arbPriceLower && sweepAmount == 0) {
            removeOutOfPositions(poolFee);
        }
    }

    /**
     * @notice Sell Sweep.
     * @param sweepAmount to sell.
     */
    function sellSweepToAMM(
        uint256 sweepAmount
    ) internal returns (uint256 usdxAmount) {
        uint256 sweepLimit = sweep.minters(address(this)).maxAmount;
        uint256 sweepAvailable = sweepLimit - sweepBorrowed;
        if (sweepAmount > sweepAvailable) sweepAmount = sweepAvailable;

        // calculate usdx minimum amount for swap
        uint256 minAmountUSD = sweep.convertToUSD(sweepAmount);
        uint256 minAmountUSDx = _oracleUsdToUsdx(minAmountUSD);
        _borrow(sweepAmount);

        usdxAmount = _sell(sweepAmount, minAmountUSDx);
    }

    /**
     * @notice Buy Sweep.
     * @param sweepAmount to buy.
     */
    function buySweep(uint256 sweepAmount) external nonReentrant {
        uint256 sweepLimit = sweep.minters(address(this)).maxAmount;
        uint256 sweepAvailable = sweepLimit - sweepBorrowed;
        if (sweepAvailable < sweepAmount) revert NotEnoughBalance();
        // calculate amount to pay
        uint24 poolFee = amm().poolFee();
        uint256 targetPrice = sweep.targetPrice();
        uint256 spread = (sweep.arbSpread() * targetPrice) / PRECISION;
        uint256 price = targetPrice + spread;
        uint256 usdxAmount = (sweepAmount * price) / (10 ** sweep.decimals());

        TransferHelper.safeTransferFrom(
            address(usdx),
            msg.sender,
            address(this),
            usdxAmount
        );
        addSingleLiquidity(targetPrice, price, usdxAmount, poolFee);
        _borrow(sweepAmount);

        TransferHelper.safeTransfer(address(sweep), msg.sender, sweepAmount);
    }

    /**
     * @notice Update topSpread.
     * @param newTopSpread new topSpread.
     */
    function setTopSpread(
        uint256 newTopSpread
    ) external onlyBorrower onlySettingsEnabled {
        topSpread = newTopSpread;
    }

    /**
     * @notice Update bottomSpread.
     * @param newBottomSpread new bottomSpread.
     */
    function setBottomSpread(
        uint256 newBottomSpread
    ) external onlyBorrower onlySettingsEnabled {
        bottomSpread = newBottomSpread;
    }

    /**
     * @notice Update tickSpread.
     * @param newTickSpread new tickSpread.
     */
    function setTickSpread(
        uint256 newTickSpread
    ) external onlyBorrower onlySettingsEnabled {
        tickSpread = newTickSpread;
    }

    /* ============ AMM Marketmaker Actions =========== */

    /**
     * @notice Add single-sided liquidity
     * @param minPrice minimum price
     * @param maxPrice maximum price
     * @param usdxAmount usdx amount to mint
     * @param poolFee pool fee
     */
    function addSingleLiquidity(
        uint256 minPrice,
        uint256 maxPrice,
        uint256 usdxAmount,
        uint24 poolFee
    ) internal {
        uint256 sweepAmount;
        uint256 usdxBalance = usdx.balanceOf(address(this));
        if (usdxAmount > usdxBalance) usdxAmount = usdxBalance;

        // Check market maker has enough balance to mint
        if (usdxAmount == 0) revert NotEnoughBalance();

        TransferHelper.safeApprove(
            address(usdx),
            address(nonfungiblePositionManager),
            usdxAmount
        );

        (int24 minTick, int24 maxTick) = getTicks(minPrice, maxPrice, poolFee);

        (uint256 amount0Mint, uint256 amount1Mint) = flag
            ? (usdxAmount, sweepAmount)
            : (sweepAmount, usdxAmount);

        (
            uint256 tokenId,
            uint128 amountLiquidity,
            uint256 amount0,
            uint256 amount1
        ) = nonfungiblePositionManager.mint(
                INonfungiblePositionManager.MintParams({
                    token0: token0,
                    token1: token1,
                    fee: poolFee,
                    tickLower: minTick,
                    tickUpper: maxTick,
                    amount0Desired: amount0Mint,
                    amount1Desired: amount1Mint,
                    amount0Min: amount0Mint,
                    amount1Min: amount1Mint,
                    recipient: address(this),
                    deadline: block.timestamp
                })
            );

        Position memory pos = Position(
            amountLiquidity,
            minTick,
            maxTick,
            poolFee,
            amount0,
            amount1
        );

        positionIds.push(tokenId);
        positions[tokenId] = pos;

        emit Minted(tokenId, amountLiquidity);
    }

    /**
     * @notice Remove out-of-range poisitions
     */
    function removeOutOfPositions(uint24 poolFee) internal {
        uint256 len = positionIds.length;
        int24 tickCurrent = liquidityHelper.getCurrentTick(
            token0,
            token1,
            poolFee
        );

        for (uint256 i = 0; i < len; ) {
            uint256 tokenId = positionIds[i];
            Position memory position = positions[tokenId];

            // check to see if current tick is out of i-th position's range.
            // it means all usdc were sold out and only sweep are left.
            // At this time, we need to check tick direction.
            if (
                (!flag && tickCurrent < position.tickLower) ||
                (flag && tickCurrent > position.tickUpper)
            ) {
                removeLiquidity(tokenId, position.liquidity);
                removeIds.push(i);
            }
            unchecked {
                ++i;
            }
        }

        // Remove position ids
        for (uint256 i = removeIds.length; i > 0; ) {
            uint256 _index = removeIds[i - 1];
            positionIds[_index] = positionIds[positionIds.length - 1];
            positionIds.pop();

            unchecked {
                --i;
            }
        }
        delete removeIds;
    }

    /**
     * @notice Remove liquidity
     * @param tokenId Token Id
     * @param liquidity.
     */
    function removeLiquidity(uint256 tokenId, uint128 liquidity) internal {
        (uint256 dAmount0, uint256 dAmount1) = nonfungiblePositionManager
            .decreaseLiquidity(
                INonfungiblePositionManager.DecreaseLiquidityParams({
                    tokenId: tokenId,
                    liquidity: liquidity,
                    amount0Min: 0,
                    amount1Min: 0,
                    deadline: block.timestamp
                })
            );

        (uint256 cAmount0, uint256 cAmount1) = nonfungiblePositionManager
            .collect(
                INonfungiblePositionManager.CollectParams({
                    tokenId: tokenId,
                    recipient: address(this),
                    amount0Max: type(uint128).max,
                    amount1Max: type(uint128).max
                })
            );

        // repay amount
        uint256 sweepAmount;

        if (token0 == address(sweep)) {
            sweepAmount = cAmount0 + dAmount0;
        } else {
            sweepAmount = cAmount1 + dAmount1;
        }

        _repay(sweepAmount);

        nonfungiblePositionManager.burn(tokenId);

        delete positions[tokenId];

        emit Burned(tokenId);
    }

    /**
     * @notice Get the ticks from price range
     * @return minTick The minimum tick
     * @return maxTick The maximum tick
     */
    function getTicks(
        uint256 minPrice,
        uint256 maxPrice,
        uint24 poolFee
    ) internal view returns (int24 minTick, int24 maxTick) {
        int24 tickSpacing = liquidityHelper.getTickSpacing(
            token0,
            token1,
            poolFee
        );
        uint8 decimals = sweep.decimals();

        minTick = liquidityHelper.getTickFromPrice(
            minPrice,
            decimals,
            tickSpacing,
            flag
        );

        maxTick = liquidityHelper.getTickFromPrice(
            maxPrice,
            decimals,
            tickSpacing,
            flag
        );

        (minTick, maxTick) = minTick < maxTick
            ? (minTick, maxTick)
            : (maxTick, minTick);
    }

    /**
     * @notice Counts positions
     */
    function numPositions() external view returns (uint256) {
        return positionIds.length;
    }
}
