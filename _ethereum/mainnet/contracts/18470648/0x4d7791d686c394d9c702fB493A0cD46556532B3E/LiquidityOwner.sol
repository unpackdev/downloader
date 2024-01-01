// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./Bloodline.sol";
import "./ABDKMath64x64.sol";
import "./TickMath.sol";
import "./LiquidityAmounts.sol";
import "./IUniswapV3Pool.sol";
import "./IMemeAltar.sol";
import "./IDeveloperLiquidityHolder.sol";
import "./IERC20.sol";

/// Attempt to access meme altar functionality from unauthorized address.
error OnlyMemeAltar();
/// Attempt to provide non-existing unprovided liquidity.
error NothingToProvide();
/// Current pool price disallows provide liquidity in passed range. Move price up first.
error CurrentPriceDisallowsToProvide();
/// Rage quit is impossible, project is still alive.
error ProjectAlive();
/// Attempt to call uniswap v3 mint callback.
error CallbackCanBeCalledOnlyByPool();
/// Logic error: uniswap v3 pool asks for BDL instead of WETH.
error WrongSideOfPrice();

/**
 * @title LiquidityOwner - Holds all WETH received from selling sacrificed memes.
 *                         Transfers WETH, which is developer fee. Transfers extra
 *                         received amounts to uniswap pools. Provides only WETH
 *                         liquidity on each cycle completed in two positions,
 *                         depending on a cycle price.
 */
contract LiquidityOwner {
    // stores provided and unprovided ETH amounts, related to a uniswap position
    struct Position {
        uint112 providedETH;
        uint112 unprovidedETH;
    }

    /*//////////////////////////////////////////////////////////////
                               EVENTS
    //////////////////////////////////////////////////////////////*/
    event LiquidityProvided(
        int24 indexed tickLower, int24 indexed tickUpper, uint256 indexed amountWETH
    );

    event LiquidityShouldBeProvidedLater(
        int24 indexed tickLower, int24 indexed tickUpper, uint256 indexed amountWETH
    );

    /*//////////////////////////////////////////////////////////////
                              CONSTANTS
    //////////////////////////////////////////////////////////////*/
    /// @notice The uniswap v3 pool tick spacing
    int24 constant TICK_SPACING = 200;
    /// @notice Price range for a first position 1 tick - 2% difference
    int24 constant PRICE_RANGE_1 = 1;
    /// @notice Price range for a second position 11 ticks - 25% difference
    int24 constant PRICE_RANGE_2 = 11;
    /// @notice Maximum BDL/ETH price due to a BDL limitations of 128bits.
    uint256 constant MAX_PRICE = 10_000_000_000_000;
    /// @notice Minimum BDL/ETH price.
    uint256 constant MIN_PRICE = 1;
    /// @dev True, if WETH is token0 in a uniswap v3 pool.
    bool immutable ETH_TOKEN_ZERO;

    /*//////////////////////////////////////////////////////////////
                        LIQUIDITY OWNER STORAGE
    //////////////////////////////////////////////////////////////*/

    address private developer;
    /// @notice Contract, which triggers cycle completed event.
    address public memeAltar;
    /// @notice ERC20, which is an underlying pool token.
    Bloodline public bloodline;
    /// @notice WETH9, which is an underlying pool token.
    address public weth;
    /// @notice Uniswap v3 pool with 1% fee, WETH and BLOOD as underlying tokens.
    IUniswapV3Pool public pool;
    /// @notice Contract holds BDL belongs to developer and provides BDL liquidity.
    address public devLiquidityHolder;
    /// @notice Stores the uniswap v3 positions.
    /// @dev range -> provided/unprovided ETH
    mapping(int48 => Position) public _positions;
    /// @notice Total amount of collected ETH from all cycles.
    uint112 public collectedEthTotal;
    /// @notice Stores Bloodline total supply after previous cycle was completed.
    uint128 public previousBDLTotalSupply;
    /// @notice Stores cycle ticks, around which WETH liquidity is provided.
    int24[] public cycleTicks;
    /// @notice The closest tick to BDL side of pool liquidity.
    int24 public borderTick;

    modifier onlyMemeAltar() {
        if (msg.sender != memeAltar) {
            revert OnlyMemeAltar();
        }
        _;
    }

    /*//////////////////////////////////////////////////////////////
                            CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Constructor sets storage values, sets contract itself in MemeAltar.
     * @param _developer address, which receives developer fee.
     * @param _bloodline ERC20 bloodline token address.
     * @param _weth WETH9 (ERC20 Wrapped Ether) contract address.
     * @param _memeAltar MemeAltar contract address.
     */
    constructor(
        address _developer,
        address _bloodline,
        address _weth,
        address _memeAltar,
        address _devLiquidityHolder
    ) {
        developer = _developer;
        memeAltar = _memeAltar;
        bloodline = Bloodline(_bloodline);
        weth = _weth;
        devLiquidityHolder = _devLiquidityHolder;
        ETH_TOKEN_ZERO = _weth < _bloodline;
        // set initial border tick at max BDL/ETH price
        borderTick = calculateTickCycle(MAX_PRICE);
        IMemeAltar(_memeAltar).setLiquidityOwner(address(this));
        IDeveloperLiquidityHolder(_devLiquidityHolder).setLiquidityOwner(address(this));
        // get the pool
        pool = IUniswapV3Pool(Bloodline(_bloodline).uniV3Pool());
    }

    /*//////////////////////////////////////////////////////////////
                          MEME ALTAR BLOCK
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Method is called by MemeAltar, when cycle is completed. Calculates and returns issuance price.
     *         Provides only WETH liquidity to a pool, if there is collected ETH in cycle and pool price allows.
     * @param collectedEthInCycle pure amount of WETH collected in a completed cycle.
     * @return issuancePrice BLOOD/ETH ratio used as a base to calculate BLOOD rewards by MemeAltar.
     */
    function provideLiquidity(uint112 collectedEthInCycle)
        external
        onlyMemeAltar
        returns (uint256 issuancePrice)
    {
        // store new amount collected
        collectedEthTotal += collectedEthInCycle;

        uint256 bdlTotalSupply = bloodline.totalSupply();
        // calculate issuance price
        issuancePrice = bdlTotalSupply / collectedEthTotal;
        if (issuancePrice == 0) issuancePrice = MIN_PRICE;
        if (issuancePrice > MAX_PRICE) issuancePrice = MAX_PRICE;

        // calculate liquidity price
        uint256 newlyMintedBDLAmount = bdlTotalSupply > previousBDLTotalSupply
            ? bdlTotalSupply - previousBDLTotalSupply
            : 0;
        previousBDLTotalSupply = uint128(bdlTotalSupply);

        if (collectedEthInCycle > 0) {
            uint256 cyclePrice = newlyMintedBDLAmount / collectedEthInCycle;
            if (cyclePrice == 0 || cyclePrice > MAX_PRICE) cyclePrice = issuancePrice;
            int24 cycleTick = calculateTickCycle(cyclePrice);
            cycleTicks.push(cycleTick);

            uint112 halfETH = collectedEthInCycle / 2;
            (, int24 tick,,,,,) = pool.slot0();
            // range 1
            (int24 tickLower, int24 tickUpper) = calculateTicksForRange1(cycleTick);
            _provideLiquidity(tickLower, tickUpper, tick, collectedEthInCycle - halfETH);
            // range 2
            (tickLower, tickUpper) = calculateTicksForRange2(cycleTick);
            _provideLiquidity(tickLower, tickUpper, tick, halfETH);
            // Developer BDL liquidity
            int24 tickForBDL = tick;
            // set border tick, pick border or pool tick for start of bdl range
            if (ETH_TOKEN_ZERO) {
                // positive tick
                if (tickLower < borderTick) borderTick = tickLower;
                if (borderTick < tickForBDL) tickForBDL = borderTick;
            } else {
                // negative tick
                if (tickUpper > borderTick) borderTick = tickUpper;
                if (borderTick > tickForBDL) tickForBDL = borderTick;
            }
            require(
                IDeveloperLiquidityHolder(devLiquidityHolder).provideBDLLiquidity(tickForBDL)
            );
        }
    }

    /**
     * @notice Method is called inside sacrifice tx to pay developer fee in WETH.
     *         Each WETH received by selling meme contains 3% developer fee.
     * @param developerFee 3% of received WETH amount in a current sacrifice.
     */
    function payDeveloperFee(uint256 developerFee) external onlyMemeAltar {
        IERC20(weth).transfer(developer, developerFee);
    }

    /**
     * @notice Method is called inside sacrificeMemeAndBuyBLOOD tx to pay WETH
     *         to a pool after receiving BLOOD from it. Or in extremly rare case to buy meme tokens back.
     * @param uniswapPool address of uniswap pool, which should receive WETH.
     * @param extraAmount amount of WETH temporary received by LiquidityOwner.
     */
    function payWETHToUniswapPool(
        address uniswapPool,
        uint256 extraAmount
    )
        external
        onlyMemeAltar
    {
        IERC20(weth).transfer(uniswapPool, extraAmount);
    }

    /*//////////////////////////////////////////////////////////////
                            EXTERNAL
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Method allows to provide WETH, which belongs to a specific range,
     *         but was unable to be provided before due to a pool price.
     * @param tickLower The lower tick of the position in which to add liquidity.
     * @param tickUpper The upper tick of the position in which to add liquidity.
     */
    function provideUnprovidedLiquidity(int24 tickLower, int24 tickUpper) external {
        int48 range = _concatenateTicks(tickLower, tickUpper);
        Position storage position = _positions[range];
        if (position.unprovidedETH == 0) {
            revert NothingToProvide();
        }

        (, int24 tick,,,,,) = pool.slot0();
        bool canBeProvided = _liquidityCanBeProvided(tick, tickLower, tickUpper);
        if (!canBeProvided) revert CurrentPriceDisallowsToProvide();

        uint112 amountToProvide = position.unprovidedETH;
        position.unprovidedETH = 0;

        _provideLiquidity(tickLower, tickUpper, tick, amountToProvide);
    }

    /**
     * @notice Method performes a health check of the project state.
     *         Liquidates position, if health check fails.
     * @param tickLower The lower tick of the position.
     * @param tickUpper The upper tick of the position.
     * @return wethAmount of the position leftovers, transfered to developer.
     * @return bloodlineAmount of the position being burned.
     */
    function rageQuit(
        int24 tickLower,
        int24 tickUpper
    )
        external
        returns (uint128 wethAmount, uint128 bloodlineAmount)
    {
        bool projectDead =
            bloodline.balanceOf(address(pool)) >= bloodline.totalSupply() * 99 / 100;
        if (!projectDead) {
            revert ProjectAlive();
        }
        bytes32 posKey = keccak256(abi.encodePacked(address(this), tickLower, tickUpper));
        (uint128 liquidity,,,,) = pool.positions(posKey);
        pool.burn(tickLower, tickUpper, liquidity);
        // the amounts collected are returned
        (uint128 amount0, uint128 amount1) = pool.collect(
            address(this), tickLower, tickUpper, type(uint128).max, type(uint128).max
        );
        // transfer WETH leftovers to developer and burn bloodline
        (wethAmount, bloodlineAmount) =
            ETH_TOKEN_ZERO ? (amount0, amount1) : (amount1, amount0);
        IERC20(weth).transfer(developer, wethAmount);
        bloodline.burn(bloodlineAmount);
    }

    /**
     * @notice Method collects uniswap V3 position fees. Transfers WETH part to
     *         developer and burns Bloodline part.
     * @param tickLower The lower tick of the position.
     * @param tickUpper The upper tick of the position.
     * @return wethAmount of the fee, being transfered to developer.
     * @return bloodlineAmount of the fee, being burned.
     */
    function collectPositionFees(
        int24 tickLower,
        int24 tickUpper
    )
        public
        returns (uint128 wethAmount, uint128 bloodlineAmount)
    {
        // burn 0 to update fees collected
        pool.burn(tickLower, tickUpper, 0);

        // the amounts collected are returned
        (uint128 amount0, uint128 amount1) = pool.collect(
            address(this), tickLower, tickUpper, type(uint128).max, type(uint128).max
        );
        // transfer WETH fee to developer and burn bloodline fee
        (wethAmount, bloodlineAmount) =
            ETH_TOKEN_ZERO ? (amount0, amount1) : (amount1, amount0);
        IERC20(weth).transfer(developer, wethAmount);
        bloodline.burn(bloodlineAmount);
    }

    /*//////////////////////////////////////////////////////////////
                          PUBLIC FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @dev Calculates ticks from cycle price for position of range 1.
    function calculateTicksForRange1(int24 tickCycle)
        public
        pure
        returns (int24 tickLower, int24 tickUpper)
    {
        // range 1
        tickLower = tickCycle;
        int24 priceRange = PRICE_RANGE_1 * TICK_SPACING;
        if (tickLower < 0) priceRange = -priceRange;
        tickUpper = tickLower + priceRange;
        if (tickLower > tickUpper) (tickLower, tickUpper) = (tickUpper, tickLower);
    }

    /// @dev Calculates ticks from cycle price for position of range 2.
    function calculateTicksForRange2(int24 tickCycle)
        public
        pure
        returns (int24 tickLower, int24 tickUpper)
    {
        // range 2
        int24 priceRange = PRICE_RANGE_2 * TICK_SPACING;
        tickLower = tickCycle - priceRange;
        tickUpper = tickCycle + priceRange;
        if (tickLower > tickUpper) (tickLower, tickUpper) = (tickUpper, tickLower);
    }

    /// @dev Performs a check, if liquidity can be provided within a passed range, depends on a pool tick.
    function _liquidityCanBeProvided(
        int24 tick,
        int24 tickLower,
        int24 tickUpper
    )
        public
        view
        returns (bool)
    {
        if (ETH_TOKEN_ZERO && tickLower >= tick) return true;
        if (!ETH_TOKEN_ZERO && tickUpper <= tick) return true;
        return false;
    }

    /// @dev Concatenates ticks into a range.
    function _concatenateTicks(int24 tickLower, int24 tickUpper) public pure returns (int48) {
        return (int48(tickLower) << 24) | (int48(tickUpper) & int48(0x000000ffffff));
    }

    /*//////////////////////////////////////////////////////////////
                          INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @dev Calculates cycle tick from cycle price.
    function calculateTickCycle(uint256 cyclePrice) internal view returns (int24 cycleTick_) {
        cycleTick_ = TickMath.getTickAtSqrtRatio(
            uint160(int160(ABDKMath64x64.sqrt(int128(int256(cyclePrice << 64))) << 32))
        );
        cycleTick_ = cycleTick_ / TICK_SPACING * TICK_SPACING;
        cycleTick_ = ETH_TOKEN_ZERO ? cycleTick_ : -cycleTick_;
    }

    /// @dev Provides liquidity, if pool price allows, otherwise stores an amount to be able to provide later.
    function _provideLiquidity(
        int24 tickLower,
        int24 tickUpper,
        int24 tick,
        uint112 ethAmountToProvide
    )
        internal
    {
        int48 range = _concatenateTicks(tickLower, tickUpper);
        Position storage position = _positions[range];

        if (position.providedETH > 0) {
            collectPositionFees(tickLower, tickUpper);
        }

        bool canBeProvided = _liquidityCanBeProvided(tick, tickLower, tickUpper);

        if (!canBeProvided) {
            position.unprovidedETH += ethAmountToProvide;
            emit LiquidityShouldBeProvidedLater(tickLower, tickUpper, ethAmountToProvide);
            return;
        }

        uint160 sqrtRatioAX96 = TickMath.getSqrtRatioAtTick(tickLower);
        uint160 sqrtRatioBX96 = TickMath.getSqrtRatioAtTick(tickUpper);
        uint128 liquidity = ETH_TOKEN_ZERO
            ? LiquidityAmounts.getLiquidityForAmount0(
                sqrtRatioAX96, sqrtRatioBX96, ethAmountToProvide
            )
            : LiquidityAmounts.getLiquidityForAmount1(
                sqrtRatioAX96, sqrtRatioBX96, ethAmountToProvide
            );

        pool.mint(address(this), tickLower, tickUpper, liquidity, "");

        // store provided ETH
        position.providedETH += ethAmountToProvide;

        emit LiquidityProvided(tickLower, tickUpper, ethAmountToProvide);
    }

    /*//////////////////////////////////////////////////////////////
                            CALLBACKS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Called by uniswap v3 pool, when minting liquidity. Pays WETH to a pool.
     * @param amount0Owed The amount of token0 due to the pool for the minted liquidity
     * @param amount1Owed The amount of token1 due to the pool for the minted liquidity
     */
    function uniswapV3MintCallback(
        uint256 amount0Owed,
        uint256 amount1Owed,
        bytes calldata
    )
        external
    {
        if (msg.sender != address(pool)) {
            revert CallbackCanBeCalledOnlyByPool();
        }
        if ((ETH_TOKEN_ZERO && amount1Owed != 0) || (!ETH_TOKEN_ZERO && amount0Owed != 0)) {
            revert WrongSideOfPrice();
        }
        IERC20(weth).transfer(msg.sender, ETH_TOKEN_ZERO ? amount0Owed : amount1Owed);
    }
}
