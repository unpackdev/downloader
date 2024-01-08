// SPDX-License-Identifier: MIT
pragma solidity >=0.6.6;

import "./IBFactory.sol";
import "./IERC20.sol";
import "./BMath.sol";

/// @author Oiler Network
/// @title Balancer BPools Router
/// @notice Allows to route swaps and set approvals only once on behalf of the router
/// @notice Manages providing liquidity when a given pair does not exist
contract BRouter is BMath {
    uint256 constant MAX_UINT = 2**256 - 1;

    /// @dev Address of bFactory
    address public immutable factory;

    /// @dev Maps pairs to pools
    mapping(address => mapping(address => address)) public getPool;

    /// @dev Stores address of every created pool
    address[] public allPools;

    /// @dev Stores pool initial liquidity providers
    mapping(address => address) public initialLiquidityProviders;

    /// @dev Ensures tx is included in block no after deadline.
    modifier ensure(uint256 deadline) {
        require(deadline >= block.timestamp, "DEADLINE EXPIRED");
        _;
    }

    constructor(address _factory) public {
        factory = _factory;
    }

    // **** ADD LIQUIDITY ****
    /// @dev Adds liquidity to an existing pool or creates a new one if it's not existing
    function addLiquidity(
        address tokenA, // Option
        address tokenB, // Collateral
        uint256 amountA, // Amount of Options to add to liquidity
        uint256 amountB // Amount of Collateral to add to liquidity
    ) external returns (uint256 poolTokens) {
        address poolAddress = getPool[tokenA][tokenB];
        IBPool pool;
        require(IERC20(tokenA).transferFrom(msg.sender, address(this), amountA), "Token A transfer failed");
        require(IERC20(tokenB).transferFrom(msg.sender, address(this), amountB), "Token B transfer failed");

        // Create the pool if it doesn't exist yet
        // currently anyone can create a pool
        if (poolAddress == address(0)) {
            pool = IBFactory(factory).newBPool();
            initialLiquidityProviders[address(pool)] = msg.sender;
            IERC20(tokenA).approve(address(pool), MAX_UINT);
            IERC20(tokenB).approve(address(pool), MAX_UINT);
            pool.bind(tokenA, amountA, BONE);
            pool.bind(tokenB, amountB, BONE);
            pool.setSwapFee(0.05 * 1e18); // 5% fee
            pool.finalize();
            addPool(tokenA, tokenB, address(pool)); // Add pool to the pool registry
        } else {
            // Add liquidity to existing pool by join()
            pool = IBPool(poolAddress);
            uint256 poolTokensA = pool.getBalance(tokenA);
            uint256 poolTokensB = pool.getBalance(tokenB);
            uint256 ratioTokenA = bdiv(amountA, poolTokensA);
            uint256 ratioTokenB = bdiv(amountB, poolTokensB);
            uint256 poolAmountOut = bmul(pool.totalSupply(), min(ratioTokenA, ratioTokenB));
            poolAmountOut = bmul(poolAmountOut, 0.99999999 * 1e18);
            uint256[] memory maxAmountsIn = new uint256[](2);
            maxAmountsIn[0] = amountA;
            maxAmountsIn[1] = amountB;
            pool.joinPool(poolAmountOut, maxAmountsIn);
        }
        // Transfer pool liquidity tokens to msg.sender
        uint256 collected = pool.balanceOf(address(this));
        require(pool.transfer(msg.sender, collected), "ERR_ERC20_FAILED");

        uint256 stuckAmountA = IERC20(tokenA).balanceOf(address(this));
        uint256 stuckAmountB = IERC20(tokenB).balanceOf(address(this));

        require(IERC20(tokenA).transfer(msg.sender, stuckAmountA), "ERR_ERC20_FAILED");
        require(IERC20(tokenB).transfer(msg.sender, stuckAmountB), "ERR_ERC20_FAILED");

        return collected;
    }

    // **** REMOVE LIQUIDITY ****
    /// @dev Removes liquidity
    function removeLiquidity(
        address tokenA, // Option
        address tokenB, // Collateral
        uint256 poolAmountIn // Amount of pool share tokens to give up
    ) external returns (uint256[] memory amounts) {
        IBPool pool = IBPool(getPool[tokenA][tokenB]);
        pool.transferFrom(msg.sender, address(this), poolAmountIn);
        pool.approve(address(pool), poolAmountIn);

        if (bsub(pool.totalSupply(), poolAmountIn) == 0) {
            require(msg.sender == initialLiquidityProviders[address(pool)]);
        }

        uint256[] memory minAmountsOut = new uint256[](2);
        minAmountsOut[0] = 0;
        minAmountsOut[1] = 0;
        pool.exitPool(poolAmountIn, minAmountsOut);

        // Transfer pool tokens back to msg.sender
        amounts = new uint256[](2);
        amounts[0] = IERC20(tokenA).balanceOf(address(this));
        amounts[1] = IERC20(tokenB).balanceOf(address(this));
        require(IERC20(tokenA).transfer(msg.sender, amounts[0]), "ERR_ERC20_FAILED");
        require(IERC20(tokenB).transfer(msg.sender, amounts[1]), "ERR_ERC20_FAILED");
    }

    /// @dev Swaps tokens
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256 tokenAmountOut, uint256 spotPriceAfter) {
        return _swapExactTokensForTokens(amountIn, amountOutMin, path, to, deadline, MAX_UINT);
    }

    /// @dev Swaps tokens and ensures price did not exceed maxPrice
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline,
        uint256 maxPrice
    ) external returns (uint256 tokenAmountOut, uint256 spotPriceAfter) {
        return _swapExactTokensForTokens(amountIn, amountOutMin, path, to, deadline, maxPrice);
    }

    /// @dev Gets the token amounts held bPool specified by it's address
    function getReserves(address poolAddress) external view returns (uint256[] memory reserves) {
        IBPool pool = IBPool(poolAddress);
        address[] memory tokens = pool.getCurrentTokens();
        reserves = new uint256[](2);
        reserves[0] = pool.getBalance(tokens[0]);
        reserves[1] = pool.getBalance(tokens[1]);
        return reserves;
    }

    /// @dev Gets the token amounts held bPool specified by it's tokens
    function getReserves(address tokenA, address tokenB) external view returns (uint256[] memory reserves) {
        IBPool pool = getPoolByTokens(tokenA, tokenB);
        reserves = new uint256[](2);
        reserves[0] = pool.getBalance(tokenA);
        reserves[1] = pool.getBalance(tokenB);
        return reserves;
    }

    /// @dev Gets token price in bPool sans fee
    function getSpotPriceSansFee(address tokenA, address tokenB) external view returns (uint256 quote) {
        IBPool pool = getPoolByTokens(tokenA, tokenB);
        return pool.getSpotPriceSansFee(tokenA, tokenB);
    }

    /// @dev Gets token price in bPool with fee
    function getSpotPriceWithFee(address tokenA, address tokenB) external view returns (uint256 amountOut) {
        IBPool pool = getPoolByTokens(tokenA, tokenB);
        return pool.getSpotPrice(tokenA, tokenB);
    }

    /// @dev Return the bPool tokens held by a specific address together with their total supply
    function getPoolShare(
        address tokenA,
        address tokenB,
        address owner
    ) external view returns (uint256 tokens, uint256 poolTokens) {
        IBPool pool = getPoolByTokens(tokenA, tokenB);
        tokens = pool.balanceOf(owner);
        poolTokens = pool.totalSupply();
    }

    /// @dev Calculates the approximate amount out of tokens after swapping them.
    function getAmountOut(
        uint256 amountIn,
        address tokenIn,
        address tokenOut
    ) external view returns (uint256 amountOut) {
        IBPool pool = getPoolByTokens(tokenIn, tokenOut);
        return
            calcOutGivenIn(
                pool.getBalance(tokenIn),
                pool.getDenormalizedWeight(tokenIn),
                pool.getBalance(tokenOut),
                pool.getDenormalizedWeight(tokenOut),
                amountIn,
                pool.getSwapFee()
            );
    }

    /// @dev Calculates the approximate amount in of tokens after swapping them.
    function getAmountIn(
        uint256 amountOut,
        address tokenIn,
        address tokenOut
    ) external view returns (uint256 amountIn) {
        IBPool pool = getPoolByTokens(tokenIn, tokenOut);
        return
            calcInGivenOut(
                pool.getBalance(tokenIn),
                pool.getDenormalizedWeight(tokenIn),
                pool.getBalance(tokenOut),
                pool.getDenormalizedWeight(tokenOut),
                amountOut,
                pool.getSwapFee()
            );
    }

    /// @dev Returns fee amount of specific token pair pool.
    function getSwapFee(address tokenA, address tokenB) external view returns (uint256 fee) {
        IBPool pool = getPoolByTokens(tokenA, tokenB);
        return pool.getSwapFee();
    }

    function getSwapFee(address poolAddress) external view returns (uint256 fee) {
        return IBPool(poolAddress).getSwapFee();
    }

    /// @dev Queries mapped pairs and reverts if pair does not exist
    function getPoolByTokens(address tokenA, address tokenB) public view returns (IBPool pool) {
        address poolAddress = getPool[tokenA][tokenB];
        require(poolAddress != address(0), "Pool doesn't exist");
        return IBPool(poolAddress);
    }

    /// @dev return the number of existing pools
    function getAllPoolsLength() public view returns (uint256) {
        return allPools.length;
    }

    /// @dev Returns the smallest of two numbers.
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    // Add pool to Registry
    function addPool(
        address tokenA,
        address tokenB,
        address poolAddress
    ) internal {
        getPool[tokenA][tokenB] = poolAddress;
        getPool[tokenB][tokenA] = poolAddress; // populate mapping in the reverse direction
        allPools.push(poolAddress);
    }

    function _swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline,
        uint256 maxPrice
    ) internal ensure(deadline) returns (uint256 tokenAmountOut, uint256 spotPriceAfter) {
        IBPool pool = getPoolByTokens(path[0], path[1]);
        IERC20(path[0]).transferFrom(msg.sender, address(this), amountIn);

        (tokenAmountOut, spotPriceAfter) = pool.swapExactAmountIn(path[0], amountIn, path[1], amountOutMin, maxPrice);

        uint256 amount = IERC20(path[1]).balanceOf(address(this)); // Think if we should use tokenAmountOut
        require(IERC20(path[1]).transfer(to, amount), "ERR_ERC20_FAILED");
    }
}
