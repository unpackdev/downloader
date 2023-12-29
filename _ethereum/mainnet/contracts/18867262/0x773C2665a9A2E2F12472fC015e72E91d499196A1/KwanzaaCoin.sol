// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./ERC20.sol";
import "./LiquidityAmounts.sol";
import "./TickMath.sol";

interface IUniswapV3Factory {
    function createPool(address tokenA, address tokenB, uint24 fee) external returns (address pool);
}

interface IUniswapV3Pool {
    function mint(address recipient, int24 tickLower, int24 tickUpper, uint128 amount, bytes calldata data)
        external
        returns (uint256 amount0, uint256 amount1);

    function initialize(uint160 sqrtPriceX96) external;
}

contract KwanzaaCoin is ERC20 {
    bool isInitialized;
    address immutable kwanzaaKing;

    // 2023 Kwanzaa
    uint256 public constant KWANZAA_START_TS = 1703548800;
    uint256 public constant KWANZAA_END_TS = 1704153599;
    uint256 public constant MAX_MERRY_KWANZAA_AMOUNT = 69_69_69 * 1e18;
    mapping(address => bool) public hasBeenWishedMerryKwanzaa;

    // Uniswap V3 initial pool params
    address constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    int24 constant MIN_TICK = -887272;
    int24 constant MAX_TICK = -MIN_TICK;
    uint160 constant MIN_SQRT_PRICE = 4295128739;
    uint160 constant MAX_SQRT_PRICE = 1461446703485210103287273052203988822378723970342;
    uint160 constant SQRT_KWANZAA_PER_ETH = 20_000; // == 400m KWANZAA per eth
    uint24 constant FEE = 500;
    int24 constant TICK_SPACING = 10;
    uint256 constant SUPPLY_TO_MINT = 1_000_000_000 * 1e18;
    address initialPool;

    /// @dev Constructoooooor
    constructor() {
        kwanzaaKing = msg.sender;
    }

    /// @dev Create a V3 pool, initialize it, and add some single sided liquidity.
    function initialize() public {
        require(!isInitialized, "already initialized");

        address pool =
            IUniswapV3Factory(0x1F98431c8aD98523631AE4a59f267346ea31F984).createPool(address(this), WETH, FEE);
        initialPool = pool;

        int24 tickLower;
        int24 tickUpper;
        uint256 amount0Desired;
        uint256 amount1Desired;
        uint160 initialPrice;
        uint160 minOrMaxPrice;
        if (address(this) < WETH) {
            // KWANZAA is token0, so price is WETH / KWANZAA.
            initialPrice = (2 << 96) / SQRT_KWANZAA_PER_ETH;
            tickLower = (TickMath.getTickAtSqrtRatio(initialPrice) / TICK_SPACING) * TICK_SPACING;
            tickUpper = (MAX_TICK / TICK_SPACING) * TICK_SPACING; // max v3 tick
            minOrMaxPrice = MAX_SQRT_PRICE;

            amount0Desired = SUPPLY_TO_MINT;
            amount1Desired = 0;
        } else {
            // KWANZAA is token1, so price is KWANZAA/WETH.
            initialPrice = SQRT_KWANZAA_PER_ETH * (2 << 96);
            tickUpper = (TickMath.getTickAtSqrtRatio(initialPrice) / TICK_SPACING) * TICK_SPACING;
            tickLower = (MIN_TICK / TICK_SPACING) * TICK_SPACING; // max v3 tick
            minOrMaxPrice = MIN_SQRT_PRICE;

            amount0Desired = 0;
            amount1Desired = SUPPLY_TO_MINT;
        }

        IUniswapV3Pool(pool).initialize(initialPrice);

        uint128 liquidityToMint = LiquidityAmounts.getLiquidityForAmounts(
            initialPrice, initialPrice, minOrMaxPrice, amount0Desired, amount1Desired
        );

        IUniswapV3Pool(pool).mint(kwanzaaKing, tickLower, tickUpper, liquidityToMint, "");

        isInitialized = true;
    }

    /// @dev Used for the initial liquidity mint.  This will only be used once.
    function uniswapV3MintCallback(uint256, uint256, bytes calldata) external {
        require(!isInitialized, "has already been initialized");
        require(msg.sender != address(0), "invalid sender");
        require(msg.sender == initialPool, "invalid sender");
        _mint(msg.sender, SUPPLY_TO_MINT);
    }

    /// @dev If Kwanzaa, merry Kwanzaa :)
    function merryKwanzaa() public {
        require(isKwanzaa(), "Not Kwanzaa :(");
        require(!hasBeenWishedMerryKwanzaa[msg.sender], "you have already been wished Merry Kwanzaa");
        hasBeenWishedMerryKwanzaa[msg.sender] = true;
        uint256 amount = ((uint256(blockhash(block.number - 1)) % MAX_MERRY_KWANZAA_AMOUNT) / 100000) * 100000 + 42069;
        _mint(msg.sender, amount);
    }

    /// @dev Is it Kwanzaa?
    function isKwanzaa() public view returns (bool) {
        return (block.timestamp >= KWANZAA_START_TS) && (block.timestamp <= KWANZAA_END_TS);
    }

    /// @dev congratulate me a Merry Kwanzaa pls
    function congratulateMe() public pure returns (string memory) {
        return "https://www.youtube.com/watch?v=S22_DuaoHCU";
    }

    /// @dev Returns the name of the token. Kwanzaa Coin!
    function name() public view virtual override returns (string memory) {
        return "Kwanzaa Coin";
    }

    /// @dev Returns the symbol of the token. KWANZA!
    function symbol() public view virtual override returns (string memory) {
        return "KWANZAA";
    }
}
