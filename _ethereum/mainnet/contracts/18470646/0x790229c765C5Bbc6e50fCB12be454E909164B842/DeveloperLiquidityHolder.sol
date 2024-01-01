// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./Bloodline.sol";
import "./TickMath.sol";
import "./LiquidityAmounts.sol";
import "./IUniswapV3Pool.sol";
import "./IERC20.sol";

/// LiquidityOwner initialization is one time action.
error LiquidityOwnerAlreadyInitialized();
/// Attempt to access liquidity owner functionality from unauthorized address.
error OnlyLiquidityOwner();
/// Attempt to access developer functionality from unauthorized address.
error OnlyDeveloper();
/// Impossible to build positions with 0/negative tick spacing.
error UnacceptableRange();
/// Attempt to call uniswap v3 mint callback.
error CallbackCanBeCalledOnlyByPool();
/// Logic error: uniswap v3 pool asks for WETH instead of BDL.
error WrongSideOfPrice();

/**
 * @title DeveloperLiquidityHolder - Holds all developer liquidity positions,
 *                         produced by providing only BLOOD liquidity into ranges
 *                         of BDL/ETH uniswap v3 pool. Beneficiary of 3% minted
 *                         BLOOD as developer fee.
 */
contract DeveloperLiquidityHolder {
    /*//////////////////////////////////////////////////////////////
                               EVENTS
    //////////////////////////////////////////////////////////////*/
    event BloodOnlyLiquidityProvided(
        int24 indexed tickLower, int24 indexed tickUpper, uint256 indexed amountBDL
    );

    event LiquidityNotProvided(
        int24 indexed tickLower, int24 indexed tickUpper, uint256 indexed amountBDL
    );

    /*//////////////////////////////////////////////////////////////
                              CONSTANTS
    //////////////////////////////////////////////////////////////*/
    /// @notice The uniswap v3 pool tick spacing
    int24 constant TICK_SPACING = 200;
    /// @dev True, if BDL is token0 in a uniswap v3 pool.
    bool immutable BDL_TOKEN_ZERO;

    /*//////////////////////////////////////////////////////////////
                  DEVELOPER LIQUIDITY HOLDER STORAGE
    //////////////////////////////////////////////////////////////*/

    address private developer;
    /// @notice Contract, which triggers providing liquidity and provides tick.
    address public liquidityOwner;
    /// @notice ERC20, which is an underlying pool token.
    Bloodline public bloodline;
    /// @notice WETH9, which is an underlying pool token.
    address public weth;
    /// @notice Uniswap v3 pool with 1% fee, WETH and BLOOD as underlying tokens.
    IUniswapV3Pool public pool;
    /// @notice Number of ticks to build a price range for a position, initial 28 tick - 75% difference
    int24 public ticksNumber = 28;

    modifier onlyDeveloper() {
        if (msg.sender != developer) {
            revert OnlyDeveloper();
        }
        _;
    }

    modifier onlyLiquidityOwner() {
        if (msg.sender != liquidityOwner) {
            revert OnlyLiquidityOwner();
        }
        _;
    }

    /*//////////////////////////////////////////////////////////////
                            CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Constructor sets storage and immutable values.
     * @param _developer address, which receives developer fee.
     * @param _bloodline ERC20 bloodline token address.
     * @param _weth WETH9 (ERC20 Wrapped Ether) contract address.
     */
    constructor(address _developer, address _bloodline, address _weth) {
        developer = _developer;
        bloodline = Bloodline(_bloodline);
        weth = _weth;
        // immutables
        BDL_TOKEN_ZERO = _bloodline < _weth;
        // get the pool
        pool = IUniswapV3Pool(Bloodline(_bloodline).uniV3Pool());
    }

    /**
     * @notice Method initialize liquidityOwner.
     * @param _liquidityOwner address of LiquidityOwner contract.
     */
    function setLiquidityOwner(address _liquidityOwner) external {
        if (liquidityOwner != address(0)) {
            revert LiquidityOwnerAlreadyInitialized();
        }
        liquidityOwner = _liquidityOwner;
    }

    /*//////////////////////////////////////////////////////////////
                          LIQUIDITY OWNER BLOCK
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Method is called by LiquidityOwner, when cycle is completed.
     *         Provides only BDL liquidity to a pool.
     * @param tickFromLO tick from LiquidityOwner, should be border tick or pool tick.
     * @return True.
     */
    function provideBDLLiquidity(int24 tickFromLO)
        external
        onlyLiquidityOwner
        returns (bool)
    {
        (int24 tickLower, int24 tickUpper) = calculateTicksForRange(tickFromLO);
        uint256 amountBDL = bloodline.balanceOf(address(this));
        _provideBDLLiquidity(tickLower, tickUpper, amountBDL);
        return true;
    }

    /*//////////////////////////////////////////////////////////////
                            EXTERNAL
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Method transfers BDL to developer on request.
     * @return bloodlineAmount BDL amount, being transferred to developer.
     */
    function withdrawBDL() external onlyDeveloper returns (uint256 bloodlineAmount) {
        bloodlineAmount = bloodline.balanceOf(address(this));
        bloodline.transfer(developer, bloodlineAmount);
    }

    /**
     * @notice Method adjust price range of next positions.
     * @param _ticksNumber Number of ticks to build a price range for a position.
     */
    function setTicksNumber(int24 _ticksNumber) external onlyDeveloper {
        if (_ticksNumber <= int24(0)) {
            revert UnacceptableRange();
        }
        ticksNumber = _ticksNumber;
    }

    /**
     * @notice Method liquidates uniswap V3 position. Transfers underlying assets
     *         to developer.
     * @param tickLower The lower tick of the position.
     * @param tickUpper The upper tick of the position.
     * @return wethAmount of the position, transferred to developer.
     * @return bloodlineAmount of the position, transferred to developer.
     */
    function liquidatePosition(
        int24 tickLower,
        int24 tickUpper
    )
        external
        onlyDeveloper
        returns (uint128 wethAmount, uint128 bloodlineAmount)
    {
        bytes32 posKey = keccak256(abi.encodePacked(address(this), tickLower, tickUpper));
        (uint128 liquidity,,,,) = pool.positions(posKey);

        pool.burn(tickLower, tickUpper, liquidity);
        // the amounts collected are returned
        (uint128 amount0, uint128 amount1) = pool.collect(
            address(this), tickLower, tickUpper, type(uint128).max, type(uint128).max
        );

        // transfer WETH and BDL to developer
        (wethAmount, bloodlineAmount) =
            BDL_TOKEN_ZERO ? (amount1, amount0) : (amount0, amount1);
        IERC20(weth).transfer(developer, wethAmount);
        bloodline.transfer(developer, bloodlineAmount);
    }

    /*//////////////////////////////////////////////////////////////
                          PUBLIC FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @dev Calculates ticks for position.
    function calculateTicksForRange(int24 tickFromLO)
        public
        view
        returns (int24 tickLower, int24 tickUpper)
    {
        int24 priceRange = ticksNumber * TICK_SPACING;
        if (BDL_TOKEN_ZERO) {
            // tick negative
            // this tickFromLO is used as tickLower for BDL position
            // tickUpper of BDL position will equal tickForBDL + RANGE
            tickLower = tickFromLO;
            tickUpper = tickFromLO + priceRange;
        } else {
            // tick positive
            // this tickFromLO is used as tickUpper for BDL position
            // tickLower of BDL position will equal tickForBDL - RANGE
            tickUpper = tickFromLO;
            tickLower = tickFromLO - priceRange;
        }
        if (tickLower > tickUpper) (tickLower, tickUpper) = (tickUpper, tickLower);
    }

    /*//////////////////////////////////////////////////////////////
                          INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @dev Provides liquidity.
    function _provideBDLLiquidity(
        int24 tickLower,
        int24 tickUpper,
        uint256 bdlAmountToProvide
    )
        internal
    {
        uint160 sqrtRatioAX96 = TickMath.getSqrtRatioAtTick(tickLower);
        uint160 sqrtRatioBX96 = TickMath.getSqrtRatioAtTick(tickUpper);
        uint128 liquidity = BDL_TOKEN_ZERO
            ? LiquidityAmounts.getLiquidityForAmount0(
                sqrtRatioAX96, sqrtRatioBX96, bdlAmountToProvide
            )
            : LiquidityAmounts.getLiquidityForAmount1(
                sqrtRatioAX96, sqrtRatioBX96, bdlAmountToProvide
            );

        try pool.mint(address(this), tickLower, tickUpper, liquidity, "") {
            emit BloodOnlyLiquidityProvided(tickLower, tickUpper, bdlAmountToProvide);
        } catch {
            emit LiquidityNotProvided(tickLower, tickUpper, bdlAmountToProvide);
        }
    }

    /*//////////////////////////////////////////////////////////////
                            CALLBACKS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Called by uniswap v3 pool, when minting liquidity. Pays BDL to a pool.
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
        if ((BDL_TOKEN_ZERO && amount1Owed != 0) || (!BDL_TOKEN_ZERO && amount0Owed != 0)) {
            revert WrongSideOfPrice();
        }
        bloodline.transfer(msg.sender, BDL_TOKEN_ZERO ? amount0Owed : amount1Owed);
    }
}
