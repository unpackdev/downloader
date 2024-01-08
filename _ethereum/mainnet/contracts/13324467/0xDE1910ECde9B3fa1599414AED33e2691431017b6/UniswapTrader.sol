// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.4;

import "./Initializable.sol";
import "./IERC20MetadataUpgradeable.sol";
import "./SafeERC20Upgradeable.sol";
import "./Controlled.sol";
import "./ModuleMapConsumer.sol";
import "./IIntegrationMap.sol";
import "./IUniswapFactory.sol";
import "./IUniswapPositionManager.sol";
import "./IUniswapSwapRouter.sol";
import "./IUniswapTrader.sol";
import "./IUniswapPool.sol";
import "./FullMath.sol";

/// @notice Integrates 0x Nodes to Uniswap v3
/// @notice tokenA/tokenB naming implies tokens are unsorted
/// @notice token0/token1 naming implies tokens are sorted
contract UniswapTrader is
  Initializable,
  ModuleMapConsumer,
  Controlled,
  IUniswapTrader
{
  using SafeERC20Upgradeable for IERC20MetadataUpgradeable;

  struct Pool {
    uint24 feeNumerator;
    uint24 slippageNumerator;
  }

  struct TokenPair {
    address token0;
    address token1;
  }

  uint24 private constant FEE_DENOMINATOR = 1_000_000;
  uint24 private constant SLIPPAGE_DENOMINATOR = 1_000_000;
  address private factoryAddress;
  address private swapRouterAddress;

  mapping(address => mapping(address => Pool[])) private pools;
  mapping(address => mapping(address => Path)) private paths;
  mapping(address => mapping(address => bool)) private isMultihopPair;

  TokenPair[] private tokenPairs;

  event UniswapPoolAdded(
    address indexed token0,
    address indexed token1,
    uint24 fee,
    uint24 slippageNumerator
  );
  event UniswapPoolSlippageNumeratorUpdated(
    address indexed token0,
    address indexed token1,
    uint256 poolIndex,
    uint24 slippageNumerator
  );
  event UniswapPairPrimaryPoolUpdated(
    address indexed token0,
    address indexed token1,
    uint256 primaryPoolIndex
  );

  /// @param controllers_ The addresses of the controlling contracts
  /// @param moduleMap_ Module Map address
  /// @param factoryAddress_ The address of the Uniswap factory contract
  /// @param swapRouterAddress_ The address of the Uniswap swap router contract
  function initialize(
    address[] memory controllers_,
    address moduleMap_,
    address factoryAddress_,
    address swapRouterAddress_
  ) public initializer {
    __Controlled_init(controllers_, moduleMap_);
    __ModuleMapConsumer_init(moduleMap_);
    factoryAddress = factoryAddress_;
    swapRouterAddress = swapRouterAddress_;
  }

  /// @param tokenA The address of tokenA ERC20 contract
  /// @param tokenB The address of tokenB ERC20 contract
  /// @param feeNumerator The Uniswap pool fee numerator
  /// @param slippageNumerator The value divided by the slippage denominator
  /// to calculate the allowable slippage
  /// positions is enabled for this pool
  function addPool(
    address tokenA,
    address tokenB,
    uint24 feeNumerator,
    uint24 slippageNumerator
  ) external override onlyManager {
    require(
      IIntegrationMap(moduleMap.getModuleAddress(Modules.IntegrationMap))
        .getIsTokenAdded(tokenA),
      "UniswapTrader::addPool: TokenA has not been added in the Integration Map"
    );
    require(
      IIntegrationMap(moduleMap.getModuleAddress(Modules.IntegrationMap))
        .getIsTokenAdded(tokenB),
      "UniswapTrader::addPool: TokenB has not been added in the Integration Map"
    );
    require(
      slippageNumerator <= SLIPPAGE_DENOMINATOR,
      "UniswapTrader::addPool: Slippage numerator cannot be greater than slippapge denominator"
    );
    require(
      IUniswapFactory(factoryAddress).getPool(tokenA, tokenB, feeNumerator) !=
        address(0),
      "UniswapTrader::addPool: Pool does not exist"
    );

    (address token0, address token1) = getTokensSorted(tokenA, tokenB);

    bool poolAdded;
    for (
      uint256 poolIndex;
      poolIndex < pools[token0][token1].length;
      poolIndex++
    ) {
      if (pools[token0][token1][poolIndex].feeNumerator == feeNumerator) {
        poolAdded = true;
      }
    }

    require(!poolAdded, "UniswapTrader::addPool: Pool has already been added");

    Pool memory newPool;
    newPool.feeNumerator = feeNumerator;
    newPool.slippageNumerator = slippageNumerator;
    pools[token0][token1].push(newPool);

    bool tokenPairAdded;
    for (uint256 pairIndex; pairIndex < tokenPairs.length; pairIndex++) {
      if (
        tokenPairs[pairIndex].token0 == token0 &&
        tokenPairs[pairIndex].token1 == token1
      ) {
        tokenPairAdded = true;
      }
    }

    if (!tokenPairAdded) {
      TokenPair memory newTokenPair;
      newTokenPair.token0 = token0;
      newTokenPair.token1 = token1;
      tokenPairs.push(newTokenPair);

      if (
        IERC20MetadataUpgradeable(token0).allowance(
          address(this),
          moduleMap.getModuleAddress(Modules.YieldManager)
        ) == 0
      ) {
        IERC20MetadataUpgradeable(token0).safeApprove(
          moduleMap.getModuleAddress(Modules.YieldManager),
          type(uint256).max
        );
      }

      if (
        IERC20MetadataUpgradeable(token1).allowance(
          address(this),
          moduleMap.getModuleAddress(Modules.YieldManager)
        ) == 0
      ) {
        IERC20MetadataUpgradeable(token1).safeApprove(
          moduleMap.getModuleAddress(Modules.YieldManager),
          type(uint256).max
        );
      }

      if (
        IERC20MetadataUpgradeable(token0).allowance(
          address(this),
          swapRouterAddress
        ) == 0
      ) {
        IERC20MetadataUpgradeable(token0).safeApprove(
          swapRouterAddress,
          type(uint256).max
        );
      }

      if (
        IERC20MetadataUpgradeable(token1).allowance(
          address(this),
          swapRouterAddress
        ) == 0
      ) {
        IERC20MetadataUpgradeable(token1).safeApprove(
          swapRouterAddress,
          type(uint256).max
        );
      }
    }

    emit UniswapPoolAdded(token0, token1, feeNumerator, slippageNumerator);
  }

  /// @param tokenA The address of tokenA of the pool
  /// @param tokenB The address of tokenB of the pool
  /// @param poolIndex The index of the pool for the specified token pair
  /// @param slippageNumerator The new slippage numerator to update the pool
  function updatePoolSlippageNumerator(
    address tokenA,
    address tokenB,
    uint256 poolIndex,
    uint24 slippageNumerator
  ) external override onlyManager {
    require(
      slippageNumerator <= SLIPPAGE_DENOMINATOR,
      "UniswapTrader:updatePoolSlippageNumerator: Slippage numerator must not be greater than slippage denominator"
    );
    (address token0, address token1) = getTokensSorted(tokenA, tokenB);
    require(
      pools[token0][token1][poolIndex].slippageNumerator != slippageNumerator,
      "UniswapTrader:updatePoolSlippageNumerator: Slippage numerator must be updated to a new number"
    );
    require(
      pools[token0][token1].length > poolIndex,
      "UniswapTrader:updatePoolSlippageNumerator: Pool does not exist"
    );

    pools[token0][token1][poolIndex].slippageNumerator = slippageNumerator;

    emit UniswapPoolSlippageNumeratorUpdated(
      token0,
      token1,
      poolIndex,
      slippageNumerator
    );
  }

  /// @notice Updates which Uniswap pool to use as the default pool
  /// @notice when swapping between token0 and token1
  /// @param tokenA The address of tokenA of the pool
  /// @param tokenB The address of tokenB of the pool
  /// @param primaryPoolIndex The index of the Uniswap pool to make the new primary pool
  function updatePairPrimaryPool(
    address tokenA,
    address tokenB,
    uint256 primaryPoolIndex
  ) external override onlyManager {
    require(
      primaryPoolIndex != 0,
      "UniswapTrader::updatePairPrimaryPool: Specified index is already the primary pool"
    );
    (address token0, address token1) = getTokensSorted(tokenA, tokenB);
    require(
      primaryPoolIndex < pools[token0][token1].length,
      "UniswapTrader::updatePairPrimaryPool: Specified pool index does not exist"
    );

    uint24 newPrimaryPoolFeeNumerator = pools[token0][token1][primaryPoolIndex]
      .feeNumerator;
    uint24 newPrimaryPoolSlippageNumerator = pools[token0][token1][
      primaryPoolIndex
    ].slippageNumerator;

    pools[token0][token1][primaryPoolIndex].feeNumerator = pools[token0][
      token1
    ][0].feeNumerator;
    pools[token0][token1][primaryPoolIndex].slippageNumerator = pools[token0][
      token1
    ][0].slippageNumerator;

    pools[token0][token1][0].feeNumerator = newPrimaryPoolFeeNumerator;
    pools[token0][token1][0]
      .slippageNumerator = newPrimaryPoolSlippageNumerator;

    emit UniswapPairPrimaryPoolUpdated(token0, token1, primaryPoolIndex);
  }

  /// @param tokenIn The address of the input token
  /// @param tokenOut The address of the output token
  /// @param recipient The address to receive the tokens
  /// @param amountIn The exact amount of the input to swap
  /// @return tradeSuccess Indicates whether the trade succeeded
  function swapExactInput(
    address tokenIn,
    address tokenOut,
    address recipient,
    uint256 amountIn
  ) external override onlyController returns (bool tradeSuccess) {
    IERC20MetadataUpgradeable tokenInErc20 = IERC20MetadataUpgradeable(tokenIn);

    if (isMultihopPair[tokenIn][tokenOut]) {
      Path memory path = getPathFor(tokenIn, tokenOut);
      IUniswapSwapRouter.ExactInputParams memory params = IUniswapSwapRouter
        .ExactInputParams({
          path: abi.encodePacked(
            path.tokenIn,
            path.firstPoolFee,
            path.tokenInTokenOut,
            path.secondPoolFee,
            path.tokenOut
          ),
          recipient: recipient,
          deadline: block.timestamp,
          amountIn: amountIn,
          amountOutMinimum: 0
        });

      // Executes the swap.
      try IUniswapSwapRouter(swapRouterAddress).exactInput(params) {
        tradeSuccess = true;
      } catch {
        tradeSuccess = false;
        tokenInErc20.safeTransfer(
          recipient,
          tokenInErc20.balanceOf(address(this))
        );
      }

      return tradeSuccess;
    }

    (address token0, address token1) = getTokensSorted(tokenIn, tokenOut);

    require(
      pools[token0][token1].length > 0,
      "UniswapTrader::swapExactInput: Pool has not been added"
    );
    require(
      tokenInErc20.balanceOf(address(this)) >= amountIn,
      "UniswapTrader::swapExactInput: Balance is less than trade amount"
    );

    uint256 amountOutMinimum = getAmountOutMinimum(tokenIn, tokenOut, amountIn);

    IUniswapSwapRouter.ExactInputSingleParams memory exactInputSingleParams;
    exactInputSingleParams.tokenIn = tokenIn;
    exactInputSingleParams.tokenOut = tokenOut;
    exactInputSingleParams.fee = pools[token0][token1][0].feeNumerator;
    exactInputSingleParams.recipient = recipient;
    exactInputSingleParams.deadline = block.timestamp;
    exactInputSingleParams.amountIn = amountIn;
    exactInputSingleParams.amountOutMinimum = amountOutMinimum;
    exactInputSingleParams.sqrtPriceLimitX96 = 0;

    try
      IUniswapSwapRouter(swapRouterAddress).exactInputSingle(
        exactInputSingleParams
      )
    {
      tradeSuccess = true;
    } catch {
      tradeSuccess = false;
      tokenInErc20.safeTransfer(
        recipient,
        tokenInErc20.balanceOf(address(this))
      );
    }
  }

  /// @param tokenIn The address of the input token
  /// @param tokenOut The address of the output token
  /// @param recipient The address to receive the tokens
  /// @param amountOut The exact amount of the output token to receive
  /// @return tradeSuccess Indicates whether the trade succeeded
  function swapExactOutput(
    address tokenIn,
    address tokenOut,
    address recipient,
    uint256 amountOut
  ) external override onlyController returns (bool tradeSuccess) {
    IERC20MetadataUpgradeable tokenInErc20 = IERC20MetadataUpgradeable(tokenIn);

    if (isMultihopPair[tokenIn][tokenOut]) {
      Path memory path = getPathFor(tokenIn, tokenOut);
      IUniswapSwapRouter.ExactOutputParams memory params = IUniswapSwapRouter
        .ExactOutputParams({
          path: abi.encodePacked(
            path.tokenIn,
            path.firstPoolFee,
            path.tokenInTokenOut,
            path.secondPoolFee,
            path.tokenOut
          ),
          recipient: recipient,
          deadline: block.timestamp,
          amountOut: amountOut,
          amountInMaximum: 0
        });

      // Executes the swap.
      try IUniswapSwapRouter(swapRouterAddress).exactOutput(params) {
        tradeSuccess = true;
      } catch {
        tradeSuccess = false;
        tokenInErc20.safeTransfer(
          recipient,
          tokenInErc20.balanceOf(address(this))
        );
      }

      return tradeSuccess;
    }
    (address token0, address token1) = getTokensSorted(tokenIn, tokenOut);
    require(
      pools[token0][token1][0].feeNumerator > 0,
      "UniswapTrader::swapExactOutput: Pool has not been added"
    );
    uint256 amountInMaximum = getAmountInMaximum(tokenIn, tokenOut, amountOut);
    require(
      tokenInErc20.balanceOf(address(this)) >= amountInMaximum,
      "UniswapTrader::swapExactOutput: Balance is less than trade amount"
    );

    IUniswapSwapRouter.ExactOutputSingleParams memory exactOutputSingleParams;
    exactOutputSingleParams.tokenIn = tokenIn;
    exactOutputSingleParams.tokenOut = tokenOut;
    exactOutputSingleParams.fee = pools[token0][token1][0].feeNumerator;
    exactOutputSingleParams.recipient = recipient;
    exactOutputSingleParams.deadline = block.timestamp;
    exactOutputSingleParams.amountOut = amountOut;
    exactOutputSingleParams.amountInMaximum = amountInMaximum;
    exactOutputSingleParams.sqrtPriceLimitX96 = 0;

    try
      IUniswapSwapRouter(swapRouterAddress).exactOutputSingle(
        exactOutputSingleParams
      )
    {
      tradeSuccess = true;
    } catch {
      tradeSuccess = false;
      tokenInErc20.safeTransfer(
        recipient,
        tokenInErc20.balanceOf(address(this))
      );
    }
  }

  /// @param tokenA The address of tokenA ERC20 contract
  /// @param tokenB The address of tokenB ERC20 contract
  /// @return pool The pool address
  function getPoolAddress(address tokenA, address tokenB)
    public
    view
    override
    returns (address pool)
  {
    uint24 feeNumerator = getPoolFeeNumerator(tokenA, tokenB, 0);
    pool = IUniswapFactory(factoryAddress).getPool(
      tokenA,
      tokenB,
      feeNumerator
    );
  }

  /// @return sqrtPriceX96 The current price of the pool as a sqrt(token1/token0) Q64.96 value
  function getSqrtPriceX96(address tokenA, address tokenB)
    public
    view
    returns (uint256)
  {
    (uint160 sqrtPriceX96, , , , , , ) = IUniswapPool(
      getPoolAddress(tokenA, tokenB)
    ).slot0();
    return uint256(sqrtPriceX96);
  }

  function getPathFor(address tokenIn, address tokenOut)
    public
    view
    override
    returns (Path memory)
  {
    require(
      isMultihopPair[tokenIn][tokenOut],
      "There is an existing Pool for this pair"
    );

    return paths[tokenIn][tokenOut];
  }

  function setPathFor(
    address tokenIn,
    address tokenOut,
    uint256 firstPoolFee,
    address tokenInTokenOut,
    uint256 secondPoolFee
  ) public override onlyManager {
    paths[tokenIn][tokenOut] = Path(
      tokenIn,
      firstPoolFee,
      tokenInTokenOut,
      secondPoolFee,
      tokenOut
    );
    isMultihopPair[tokenIn][tokenOut] = true;
  }

  /// @param tokenIn The address of the input token
  /// @param tokenOut The address of the output token
  /// @param amountIn The exact amount of the input to swap
  /// @return amountOutMinimum The minimum amount of tokenOut to receive, factoring in allowable slippage
  function getAmountOutMinimum(
    address tokenIn,
    address tokenOut,
    uint256 amountIn
  ) public view returns (uint256 amountOutMinimum) {
    uint256 estimatedAmountOut = getEstimatedTokenOut(
      tokenIn,
      tokenOut,
      amountIn
    );
    uint24 poolSlippageNumerator = getPoolSlippageNumerator(
      tokenIn,
      tokenOut,
      0
    );
    amountOutMinimum =
      (estimatedAmountOut * (SLIPPAGE_DENOMINATOR - poolSlippageNumerator)) /
      SLIPPAGE_DENOMINATOR;
  }

  /// @param tokenIn The address of the input token
  /// @param tokenOut The address of the output token
  /// @param amountOut The exact amount of token being swapped for
  /// @return amountInMaximum The maximum amount of tokenIn to spend, factoring in allowable slippage
  function getAmountInMaximum(
    address tokenIn,
    address tokenOut,
    uint256 amountOut
  ) public view override returns (uint256 amountInMaximum) {
    uint256 estimatedAmountIn = getEstimatedTokenIn(
      tokenIn,
      tokenOut,
      amountOut
    );
    uint24 poolSlippageNumerator = getPoolSlippageNumerator(
      tokenIn,
      tokenOut,
      0
    );
    amountInMaximum =
      (estimatedAmountIn * (SLIPPAGE_DENOMINATOR + poolSlippageNumerator)) /
      SLIPPAGE_DENOMINATOR;
  }

  /// @param tokenIn The address of the input token
  /// @param tokenOut The address of the output token
  /// @param amountIn The exact amount of the input to swap
  /// @return amountOut The estimated amount of tokenOut to receive
  function getEstimatedTokenOut(
    address tokenIn,
    address tokenOut,
    uint256 amountIn
  ) public view override returns (uint256 amountOut) {
    if (isMultihopPair[tokenIn][tokenOut]) {
      Path memory path = getPathFor(tokenIn, tokenOut);
      uint256 amountOutTemp = getEstimatedTokenOut(
        path.tokenIn,
        path.tokenInTokenOut,
        amountIn
      );
      return
        getEstimatedTokenOut(
          path.tokenInTokenOut,
          path.tokenOut,
          amountOutTemp
        );
    }

    uint24 feeNumerator = getPoolFeeNumerator(tokenIn, tokenOut, 0);
    uint256 sqrtPriceX96 = getSqrtPriceX96(tokenIn, tokenOut);

    // FullMath is used to allow intermediate calculation values of up to 2^512
    if (tokenIn < tokenOut) {
      amountOut =
        (FullMath.mulDiv(
          FullMath.mulDiv(amountIn, sqrtPriceX96, 2**96),
          sqrtPriceX96,
          2**96
        ) * (FEE_DENOMINATOR - feeNumerator)) /
        FEE_DENOMINATOR;
    } else {
      amountOut =
        (FullMath.mulDiv(
          FullMath.mulDiv(amountIn, 2**96, sqrtPriceX96),
          2**96,
          sqrtPriceX96
        ) * (FEE_DENOMINATOR - feeNumerator)) /
        FEE_DENOMINATOR;
    }
  }

  /// @param tokenIn The address of the input token
  /// @param tokenOut The address of the output token
  /// @param amountOut The exact amount of the output token to swap for
  /// @return amountIn The estimated amount of tokenIn to spend
  function getEstimatedTokenIn(
    address tokenIn,
    address tokenOut,
    uint256 amountOut
  ) public view returns (uint256 amountIn) {
    if (isMultihopPair[tokenIn][tokenOut]) {
      Path memory path = getPathFor(tokenIn, tokenOut);
      uint256 amountInTemp = getEstimatedTokenIn(
        path.tokenInTokenOut,
        path.tokenOut,
        amountOut
      );
      return
        getEstimatedTokenIn(path.tokenIn, path.tokenInTokenOut, amountInTemp);
    }

    uint24 feeNumerator = getPoolFeeNumerator(tokenIn, tokenOut, 0);
    uint256 sqrtPriceX96 = getSqrtPriceX96(tokenIn, tokenOut);

    // FullMath is used to allow intermediate calculation values of up to 2^512
    if (tokenIn < tokenOut) {
      amountIn =
        (FullMath.mulDiv(
          FullMath.mulDiv(amountOut, 2**96, sqrtPriceX96),
          2**96,
          sqrtPriceX96
        ) * (FEE_DENOMINATOR - feeNumerator)) /
        FEE_DENOMINATOR;
    } else {
      amountIn =
        (FullMath.mulDiv(
          FullMath.mulDiv(amountOut, sqrtPriceX96, 2**96),
          sqrtPriceX96,
          2**96
        ) * (FEE_DENOMINATOR - feeNumerator)) /
        FEE_DENOMINATOR;
    }
  }

  /// @param tokenA The address of tokenA
  /// @param tokenB The address of tokenB
  /// @param poolId The index of the pool in the pools mapping
  /// @return feeNumerator The numerator that gets divided by the fee denominator
  function getPoolFeeNumerator(
    address tokenA,
    address tokenB,
    uint256 poolId
  ) public view override returns (uint24 feeNumerator) {
    (address token0, address token1) = getTokensSorted(tokenA, tokenB);
    require(
      poolId < pools[token0][token1].length,
      "UniswapTrader::getPoolFeeNumerator: Pool ID does not exist"
    );
    feeNumerator = pools[token0][token1][poolId].feeNumerator;
  }

  /// @param tokenA The address of tokenA
  /// @param tokenB The address of tokenB
  /// @param poolId The index of the pool in the pools mapping
  /// @return slippageNumerator The numerator that gets divided by the slippage denominator
  function getPoolSlippageNumerator(
    address tokenA,
    address tokenB,
    uint256 poolId
  ) public view returns (uint24 slippageNumerator) {
    (address token0, address token1) = getTokensSorted(tokenA, tokenB);
    return pools[token0][token1][poolId].slippageNumerator;
  }

  /// @param tokenA The address of tokenA
  /// @param tokenB The address of tokenB
  /// @return token0 The address of the sorted token0
  /// @return token1 The address of the sorted token1
  function getTokensSorted(address tokenA, address tokenB)
    public
    pure
    override
    returns (address token0, address token1)
  {
    if (tokenA < tokenB) {
      token0 = tokenA;
      token1 = tokenB;
    } else {
      token0 = tokenB;
      token1 = tokenA;
    }
  }

  /// @param tokenA The address of tokenA
  /// @param tokenB The address of tokenB
  /// @param amountA The amount of tokenA
  /// @param amountB The amount of tokenB
  /// @return token0 The address of sorted token0
  /// @return token1 The address of sorted token1
  /// @return amount0 The amount of sorted token0
  /// @return amount1 The amount of sorted token1
  function getTokensAndAmountsSorted(
    address tokenA,
    address tokenB,
    uint256 amountA,
    uint256 amountB
  )
    public
    pure
    returns (
      address token0,
      address token1,
      uint256 amount0,
      uint256 amount1
    )
  {
    if (tokenA < tokenB) {
      token0 = tokenA;
      token1 = tokenB;
      amount0 = amountA;
      amount1 = amountB;
    } else {
      token0 = tokenB;
      token1 = tokenA;
      amount0 = amountB;
      amount1 = amountA;
    }
  }

  /// @return The denominator used to calculate the pool fee percentage
  function getFeeDenominator() external pure returns (uint24) {
    return FEE_DENOMINATOR;
  }

  /// @return The denominator used to calculate the allowable slippage percentage
  function getSlippageDenominator() external pure returns (uint24) {
    return SLIPPAGE_DENOMINATOR;
  }

  /// @return The number of token pairs configured
  function getTokenPairsLength() external view override returns (uint256) {
    return tokenPairs.length;
  }

  /// @param tokenA The address of tokenA
  /// @param tokenB The address of tokenB
  /// @return The quantity of pools configured for the specified token pair
  function getTokenPairPoolsLength(address tokenA, address tokenB)
    external
    view
    override
    returns (uint256)
  {
    (address token0, address token1) = getTokensSorted(tokenA, tokenB);
    return pools[token0][token1].length;
  }

  /// @param tokenPairIndex The index of the token pair
  /// @return The address of token0
  /// @return The address of token1
  function getTokenPair(uint256 tokenPairIndex)
    external
    view
    returns (address, address)
  {
    require(
      tokenPairIndex < tokenPairs.length,
      "UniswapTrader::getTokenPair: Token pair does not exist"
    );
    return (
      tokenPairs[tokenPairIndex].token0,
      tokenPairs[tokenPairIndex].token1
    );
  }

  /// @param token0 The address of token0 of the pool
  /// @param token1 The address of token1 of the pool
  /// @param poolIndex The index of the pool
  /// @return The pool fee numerator
  /// @return The pool slippage numerator
  function getPool(
    address token0,
    address token1,
    uint256 poolIndex
  ) external view returns (uint24, uint24) {
    require(
      poolIndex < pools[token0][token1].length,
      "UniswapTrader:getPool: Pool does not exist"
    );
    return (
      pools[token0][token1][poolIndex].feeNumerator,
      pools[token0][token1][poolIndex].slippageNumerator
    );
  }
}
