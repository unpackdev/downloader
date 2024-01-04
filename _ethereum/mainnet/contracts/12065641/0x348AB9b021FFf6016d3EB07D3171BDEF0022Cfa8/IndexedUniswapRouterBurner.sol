// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;
pragma experimental ABIEncoderV2;

import "./TransferHelper.sol";

import "./IERC20.sol";
import "./IWETH.sol";

import "./IIndexPool.sol";

import "./UniswapV2Library.sol";
import "./BMath.sol";


contract IndexedUniswapRouterBurner is BMath {
  address public immutable factory;
  address public immutable weth;

  constructor(address factory_, address weth_) public {
    factory = factory_;
    weth = weth_;
  }

  receive() external payable {
    require(msg.sender == weth, "IndexedUniswapRouterBurner: RECEIVED_ETHER");
  }

  // requires the initial amount to have already been sent to the first pair
  function _swap(uint[] memory amounts, address[] memory path, address recipient) internal {
    for (uint i; i < path.length - 1; i++) {
      (address input, address output) = (path[i], path[i + 1]);
      (address token0, address token1) = UniswapV2Library.sortTokens(input, output);
      uint amountOut = amounts[i + 1];
      (uint amount0Out, uint amount1Out) = input == token0 ? (uint(0), amountOut) : (amountOut, uint(0));
      address to = i < path.length - 2 ? UniswapV2Library.pairFor(factory, output, path[i + 2]) : recipient;
      IUniswapV2Pair(UniswapV2Library.calculatePair(factory, token0, token1)).swap(
        amount0Out, amount1Out, to, new bytes(0)
      );
    }
  }

  /**
   * @dev Redeems `poolAmountIn` pool tokens for the first token in `path`
   * and swaps it to at least `minAmountOut` of the last token in `path`.
   *
   * @param indexPool Address of the index pool to burn tokens from.
   * @param poolAmountIn Amount of pool tokens to burn.
   * @param path Array of tokens to swap using the Uniswap router.
   * @param minAmountOut Amount of last token in `path` that must be received to not revert.
   * @return amountOut Amount of output tokens received.
   */
  function burnExactAndSwapForTokens(
    address indexPool,
    uint poolAmountIn,
    address[] calldata path,
    uint minAmountOut
  ) external returns (uint amountOut) {
    amountOut = _burnExactAndSwap(
      indexPool,
      poolAmountIn,
      path,
      minAmountOut,
      msg.sender
    );
  }

  /**
   * @dev Redeems `poolAmountIn` pool tokens for the first token in `path`
   * and swaps it to at least `minAmountOut` ether.
   *
   * @param indexPool Address of the index pool to burn tokens from.
   * @param poolAmountIn Amount of pool tokens to burn.
   * @param path Array of tokens to swap using the Uniswap router.
   * @param minAmountOut Amount of ether that must be received to not revert.
   * @return amountOut Amount of ether received.
   */
  function burnExactAndSwapForETH(
    address indexPool,
    uint poolAmountIn,
    address[] calldata path,
    uint minAmountOut
  ) external returns (uint amountOut) {
    require(path[path.length - 1] == weth, 'IndexedUniswapRouterBurner: INVALID_PATH');
    amountOut = _burnExactAndSwap(
      indexPool,
      poolAmountIn,
      path,
      minAmountOut,
      address(this)
    );
    IWETH(weth).withdraw(amountOut);
    TransferHelper.safeTransferETH(msg.sender, amountOut);
  }

  function _burnExactAndSwap(
    address indexPool,
    uint poolAmountIn,
    address[] memory path,
    uint minAmountOut,
    address recipient
  ) internal returns (uint amountOut) {
    // Transfer the pool tokens to the router.
    TransferHelper.safeTransferFrom(
      indexPool,
      msg.sender,
      address(this),
      poolAmountIn
    );
    // Burn the pool tokens for the first token in `path`.
    uint redeemedAmountOut = IIndexPool(indexPool).exitswapPoolAmountIn(
      path[0],
      poolAmountIn,
      0
    );
    // Calculate the swap amounts for the redeemed amount of the first token in `path`.
    uint[] memory amounts = UniswapV2Library.getAmountsOut(factory, redeemedAmountOut, path);
    amountOut = amounts[amounts.length - 1];
    require(
      amountOut >= minAmountOut,
      "IndexedUniswapRouterBurner: INSUFFICIENT_OUTPUT_AMOUNT"
    );
    // Transfer the redeemed tokens to the first Uniswap pair.
    TransferHelper.safeTransfer(
      path[0],
      UniswapV2Library.pairFor(factory, path[0], path[1]),
      amounts[0]
    );
    // Execute the routed swaps and send the output tokens to `recipient`.
    _swap(amounts, path, recipient);
  }

  /**
   * @dev Redeems up to `poolAmountInMax` pool tokens for the first token in `path`
   * and swaps it to exactly `tokenAmountOut` of the last token in `path`.
   *
   * @param indexPool Address of the index pool to burn tokens from.
   * @param poolAmountInMax Maximum amount of pool tokens to burn.
   * @param path Array of tokens to swap using the Uniswap router.
   * @param tokenAmountOut Amount of last token in `path` to receive.
   * @return poolAmountIn Amount of pool tokens burned.
   */
  function burnAndSwapForExactTokens(
    address indexPool,
    uint poolAmountInMax,
    address[] calldata path,
    uint tokenAmountOut
  ) external returns (uint poolAmountIn) {
    poolAmountIn = _burnAndSwapForExact(
      indexPool,
      poolAmountInMax,
      path,
      tokenAmountOut,
      msg.sender
    );
  }

  /**
   * @dev Redeems up to `poolAmountInMax` pool tokens for the first token in `path`
   * and swaps it to exactly `ethAmountOut` ether.
   *
   * @param indexPool Address of the index pool to burn tokens from.
   * @param poolAmountInMax Maximum amount of pool tokens to burn.
   * @param path Array of tokens to swap using the Uniswap router.
   * @param ethAmountOut Amount of eth to receive.
   * @return poolAmountIn Amount of pool tokens burned.
   */
  function burnAndSwapForExactETH(
    address indexPool,
    uint poolAmountInMax,
    address[] calldata path,
    uint ethAmountOut
  ) external returns (uint poolAmountIn) {
    require(path[path.length - 1] == weth, 'IndexedUniswapRouterBurner: INVALID_PATH');
    poolAmountIn = _burnAndSwapForExact(
      indexPool,
      poolAmountInMax,
      path,
      ethAmountOut,
      address(this)
    );
    IWETH(weth).withdraw(ethAmountOut);
    TransferHelper.safeTransferETH(msg.sender, ethAmountOut);
  }

  function _burnAndSwapForExact(
    address indexPool,
    uint poolAmountInMax,
    address[] memory path,
    uint tokenAmountOut,
    address recipient
  ) internal returns (uint poolAmountIn) {
    // Transfer the maximum pool tokens to the router.
    TransferHelper.safeTransferFrom(
      indexPool,
      msg.sender,
      address(this),
      poolAmountInMax
    );
    // Calculate the swap amounts for `tokenAmountOut` of the last token in `path`.
    uint[] memory amounts = UniswapV2Library.getAmountsIn(factory, tokenAmountOut, path);
    // Burn the pool tokens for the exact amount of the first token in `path`.
    poolAmountIn = IIndexPool(indexPool).exitswapExternAmountOut(
      path[0],
      amounts[0],
      poolAmountInMax
    );
    // Transfer the redeemed tokens to the first Uniswap pair.
    TransferHelper.safeTransfer(
      path[0],
      UniswapV2Library.pairFor(factory, path[0], path[1]),
      amounts[0]
    );
    // Execute the routed swaps and send the output tokens to `recipient`.
    _swap(amounts, path, recipient);
    // Return any unburned pool tokens to the caller.
    TransferHelper.safeTransfer(
      indexPool,
      msg.sender,
      SafeMath.sub(poolAmountInMax, poolAmountIn)
    );
  }

  /**
   * @dev Burns `poolAmountOut` for all the underlying tokens in a pool, then
   * swaps each of them on Uniswap for at least `minAmountOut` of `tokenOut`.
   *
   * Up to one intermediary token may be provided in `intermediaries` for each
   * underlying token in the index pool.
   *
   * If a null address is provided as an intermediary, the input token will be
   * swapped directly for the output token.
   */
  function burnForAllTokensAndSwapForTokens(
    address indexPool,
    uint256[] calldata minAmountsOut,
    address[] calldata intermediaries,
    uint256 poolAmountIn,
    address tokenOut,
    uint256 minAmountOut
  ) external returns (uint256 amountOutTotal) {
    amountOutTotal = _burnForAllTokensAndSwap(
      indexPool,
      tokenOut,
      minAmountsOut,
      intermediaries,
      poolAmountIn,
      minAmountOut,
      msg.sender
    );
  }

  /**
   * @dev Burns `poolAmountOut` for all the underlying tokens in a pool, then
   * swaps each of them on Uniswap for at least `minAmountOut` ether.
   *
   * Up to one intermediary token may be provided in `intermediaries` for each
   * underlying token in the index pool.
   *
   * If a null address is provided as an intermediary, the input token will be
   * swapped directly for the output token.
   */
  function burnForAllTokensAndSwapForETH(
    address indexPool,
    uint256[] calldata minAmountsOut,
    address[] calldata intermediaries,
    uint256 poolAmountIn,
    uint256 minAmountOut
  ) external returns (uint amountOutTotal) {
    amountOutTotal = _burnForAllTokensAndSwap(
      indexPool,
      weth,
      minAmountsOut,
      intermediaries,
      poolAmountIn,
      minAmountOut,
      address(this)
    );
    IWETH(weth).withdraw(amountOutTotal);
    TransferHelper.safeTransferETH(msg.sender, amountOutTotal);
  }

  function _burnForAllTokensAndSwap(
    address indexPool,
    address tokenOut,
    uint256[] calldata minAmountsOut,
    address[] calldata intermediaries,
    uint256 poolAmountIn,
    uint256 minAmountOut,
    address recipient
  ) internal returns (uint amountOutTotal) {
    // Transfer the pool tokens from the caller.
    TransferHelper.safeTransferFrom(indexPool, msg.sender, address(this), poolAmountIn);
    address[] memory tokens = IIndexPool(indexPool).getCurrentTokens();
    require(
      intermediaries.length == tokens.length && minAmountsOut.length == tokens.length,
      "IndexedUniswapRouterBurner: BAD_ARRAY_LENGTH"
    );
    IIndexPool(indexPool).exitPool(poolAmountIn, minAmountsOut);
    // Reserve 3 slots in memory for the addresses
    address[] memory path = new address[](3);

    for (uint256 i = 0; i < tokens.length; i++) {
      uint[] memory amounts = _getSwapAmountsForExit(
        tokens[i],
        intermediaries[i],
        tokenOut,
        path
      );
      TransferHelper.safeTransfer(
        tokens[i],
        UniswapV2Library.pairFor(factory, tokens[i], path[1]),
        amounts[0]
      );
      _swap(amounts, path, recipient);

      uint amountOut = amounts[amounts.length - 1];
      amountOutTotal = SafeMath.add(amountOutTotal, amountOut);
    }
    require(amountOutTotal >= minAmountOut, "IndexedUniswapRouterBurner: INSUFFICIENT_OUTPUT_AMOUNT");
  }

  function _getSwapAmountsForExit(
    address tokenIn,
    address intermediate,
    address tokenOut,
    address[] memory path
  ) internal view returns (uint[] memory amounts) {
    if (intermediate == address(0)) {
      // If no intermediate token is given, set path length to 2 so the other
      // functions will not use the 3rd address.
      assembly { mstore(path, 2) }
      path[1] = tokenOut;
    } else {
      // If an intermediary is given, set path length to 3 so the other
      // functions will use all addresses.
      assembly { mstore(path, 3) }
      path[1] = intermediate;
      path[2] = tokenOut;
    }
    uint balance = IERC20(tokenIn).balanceOf(address(this));
    amounts = UniswapV2Library.getAmountsOut(factory, balance, path);
  }
}