// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;
pragma experimental ABIEncoderV2;

import "./TransferHelper.sol";

import "./IERC20.sol";
import "./IWETH.sol";

import "./IIndexPool.sol";

import "./UniswapV2Library.sol";
import "./BMath.sol";


contract IndexedUniswapRouterMinter is BMath {
  address public immutable factory;
  address public immutable weth;

  constructor(address factory_, address weth_) public {
    factory = factory_;
    weth = weth_;
  }

  function _swapInGivenOut(address input, address output, uint amountOut) internal returns (uint amountIn) {
    (address token0, address token1) = UniswapV2Library.sortTokens(input, output);
    address pair = UniswapV2Library.calculatePair(factory, token0, token1);

    (uint reserves0, uint reserves1,) = IUniswapV2Pair(pair).getReserves();
    if (input == token0) {
      amountIn = UniswapV2Library.getAmountIn(amountOut, reserves0, reserves1);
      TransferHelper.safeTransferFrom(input, msg.sender, pair, amountIn);
      IUniswapV2Pair(pair).swap(0, amountOut, address(this), new bytes(0));
    } else {
      amountIn = UniswapV2Library.getAmountIn(amountOut, reserves1, reserves0);
      TransferHelper.safeTransferFrom(input, msg.sender, pair, amountIn);
      IUniswapV2Pair(pair).swap(amountOut, 0, address(this), new bytes(0));
    }
  }

  // requires the initial amount to have already been sent to the first pair
  function _swap(uint[] memory amounts, address[] memory path) internal {
    for (uint i; i < path.length - 1; i++) {
      (address input, address output) = (path[i], path[i + 1]);
      (address token0, address token1) = UniswapV2Library.sortTokens(input, output);
      uint amountOut = amounts[i + 1];
      (uint amount0Out, uint amount1Out) = input == token0 ? (uint(0), amountOut) : (amountOut, uint(0));
      address to = i < path.length - 2 ? UniswapV2Library.pairFor(factory, output, path[i + 2]) : address(this);
      IUniswapV2Pair(UniswapV2Library.calculatePair(factory, token0, token1)).swap(
        amount0Out, amount1Out, to, new bytes(0)
      );
    }
  }

  function _mintTokenAmountIn(
    address tokenIn,
    uint amountIn,
    address indexPool,
    uint minPoolAmountOut
  ) internal returns (uint poolAmountOut) {
    TransferHelper.safeApprove(tokenIn, indexPool, amountIn);
    poolAmountOut = IIndexPool(indexPool).joinswapExternAmountIn(
      tokenIn,
      amountIn,
      minPoolAmountOut
    );
    TransferHelper.safeTransfer(indexPool, msg.sender, poolAmountOut);
  }

  function _mintPoolAmountOut(
    address tokenIn,
    uint amountIn,
    address indexPool,
    uint poolAmountOut
  ) internal {
    TransferHelper.safeApprove(tokenIn, indexPool, amountIn);
    IIndexPool(indexPool).joinswapPoolAmountOut(
      tokenIn,
      poolAmountOut,
      amountIn
    );
    TransferHelper.safeTransfer(indexPool, msg.sender, poolAmountOut);
  }

  function _swapExactETHForTokens(
    address[] memory path
  )
    internal
    returns (uint amountOut)
  {
    require(path[0] == weth, 'IndexedUniswapRouterMinter: INVALID_PATH');
    uint[] memory amounts = UniswapV2Library.getAmountsOut(factory, msg.value, path);
    IWETH(weth).deposit{value: amounts[0]}();
    assert(IWETH(weth).transfer(UniswapV2Library.pairFor(factory, path[0], path[1]), amounts[0]));
    _swap(amounts, path);
    return amounts[amounts.length - 1];
  }

  function _swapExactTokensForTokens(
    uint amountIn,
    address[] memory path
  ) internal returns (uint amountOut) {
    uint[] memory amounts = UniswapV2Library.getAmountsOut(factory, amountIn, path);
    TransferHelper.safeTransferFrom(
      path[0], msg.sender, UniswapV2Library.pairFor(factory, path[0], path[1]), amounts[0]
    );
    _swap(amounts, path);
    return amounts[amounts.length - 1];
  }

  function _tokenInGivenPoolOut(
    address indexPool,
    address tokenIn,
    uint256 poolAmountOut
  ) internal view returns (uint256 amountIn) {
    IIndexPool.Record memory record = IIndexPool(indexPool).getTokenRecord(tokenIn);
    if (!record.ready) {
      uint256 minimumBalance = IIndexPool(indexPool).getMinimumBalance(tokenIn);
      uint256 realToMinRatio = bdiv(
        bsub(minimumBalance, record.balance),
        minimumBalance
      );
      uint256 weightPremium = bmul(MIN_WEIGHT / 10, realToMinRatio);
      record.balance = minimumBalance;
      record.denorm = uint96(badd(MIN_WEIGHT, weightPremium));
    }
    uint256 totalSupply = IERC20(indexPool).totalSupply();
    uint256 totalWeight = IIndexPool(indexPool).getTotalDenormalizedWeight();
    uint256 swapFee = IIndexPool(indexPool).getSwapFee();
    return calcSingleInGivenPoolOut(
      record.balance,
      record.denorm,
      totalSupply,
      totalWeight,
      poolAmountOut,
      swapFee
    );
  }


  function _swapTokensForExactTokens(
    uint amountOut,
    uint amountInMax,
    address[] memory path
  ) internal returns (uint amountIn) {
    uint[] memory amounts = UniswapV2Library.getAmountsIn(factory, amountOut, path);
    require(amounts[0] <= amountInMax, 'IndexedUniswapRouterMinter: EXCESSIVE_INPUT_AMOUNT');
    TransferHelper.safeTransferFrom(
      path[0], msg.sender, UniswapV2Library.pairFor(factory, path[0], path[1]), amounts[0]
    );
    _swap(amounts, path);
    return amounts[0];
  }

  function _swapEthForExactTokens(
    uint amountOut,
    address[] memory path
  ) internal {
    require(path[0] == weth, 'IndexedUniswapRouterMinter: INVALID_PATH');
    uint[] memory amounts = UniswapV2Library.getAmountsIn(factory, amountOut, path);
    require(amounts[0] <= msg.value, 'IndexedUniswapRouterMinter: EXCESSIVE_INPUT_AMOUNT');
    IWETH(weth).deposit{value: amounts[0]}();
    assert(IWETH(weth).transfer(UniswapV2Library.pairFor(factory, path[0], path[1]), amounts[0]));
    _swap(amounts, path);
    // refund dust eth, if any
    if (msg.value > amounts[0]) {
      TransferHelper.safeTransferETH(msg.sender, msg.value - amounts[0]);
    }
  }

  /**
   * @dev Swaps ether for each token in `path` using their Uniswap pairs,
   * then mints at least `minPoolAmountOut` pool tokens from `indexPool`.
   * @param path Array of tokens to swap using the Uniswap router.
   * @param indexPool Address of the index pool to mint tokens from.
   * @param minPoolAmountOut Amount of pool tokens that must be received to not revert.
   */
  function swapExactETHForTokensAndMint(
    address[] calldata path,
    address indexPool,
    uint minPoolAmountOut
  ) external payable returns (uint poolAmountOut) {
    uint amountOut = _swapExactETHForTokens(path);
    return _mintTokenAmountIn(
      path[path.length - 1],
      amountOut,
      indexPool,
      minPoolAmountOut
    );
  }

  /**
   * @dev Swaps a token for each other token in `path` using their Uniswap pairs,
   * then mints at least `minPoolAmountOut` pool tokens from `indexPool`.
   * @param amountIn Amount of the first token in `path` to swap.
   * @param path Array of tokens to swap using the Uniswap router.
   * @param indexPool Address of the index pool to mint tokens from.
   * @param minPoolAmountOut Amount of pool tokens that must be received to not revert.
   */
  function swapExactTokensForTokensAndMint(
    uint amountIn,
    address[] calldata path,
    address indexPool,
    uint minPoolAmountOut
  ) external returns (uint poolAmountOut) {
    uint amountOut = _swapExactTokensForTokens(amountIn, path);
    return _mintTokenAmountIn(
      path[path.length - 1],
      amountOut,
      indexPool,
      minPoolAmountOut
    );
  }

  /**
   * @dev Swaps ether for each token in `path` through Uniswap,
   * then mints `poolAmountOut` pool tokens from `indexPool`.
   * @param path Array of tokens to swap using the Uniswap router.
   * @param indexPool Address of the index pool to mint tokens from.
   * @param poolAmountOut Amount of pool tokens that must be received to not revert.
   */
  function swapETHForTokensAndMintExact(
    address[] calldata path,
    address indexPool,
    uint poolAmountOut
  ) external payable {
    address swapTokenOut = path[path.length - 1];
    uint amountOut = _tokenInGivenPoolOut(indexPool, swapTokenOut, poolAmountOut);
    _swapEthForExactTokens(amountOut, path);
    return _mintPoolAmountOut(
      swapTokenOut,
      amountOut,
      indexPool,
      poolAmountOut
    );
  }

  /**
   * @dev Swaps a token for each other token in `path` through Uniswap,
   * then mints at least `poolAmountOut` pool tokens from `indexPool`.
   * @param amountInMax Maximum amount of the first token in `path` to give.
   * @param path Array of tokens to swap using the Uniswap router.
   * @param indexPool Address of the index pool to mint tokens from.
   * @param poolAmountOut Amount of pool tokens that must be received to not revert.
   */
  function swapTokensForTokensAndMintExact(
    uint amountInMax,
    address[] calldata path,
    address indexPool,
    uint poolAmountOut
  ) external {
    address swapTokenOut = path[path.length - 1];
    uint amountOut = _tokenInGivenPoolOut(indexPool, swapTokenOut, poolAmountOut);
    _swapTokensForExactTokens(amountOut, amountInMax, path);
    _mintPoolAmountOut(
      swapTokenOut,
      amountOut,
      indexPool,
      poolAmountOut
    );
  }

  /**
   * @dev Swaps an input token with its pair for every underlying token in `indexPool`,
   * then mints `poolAmountOut` pool tokens from `indexPool`.
   */
  function swapTokensForAllTokensAndMintExact(
    address tokenIn,
    uint256 amountInMax,
    address indexPool,
    uint256 poolAmountOut
  ) public returns (uint256 amountInTotal) {
    uint256 totalSupply = IERC20(indexPool).totalSupply();
    uint256 ratio = bdiv(poolAmountOut, totalSupply);

    address[] memory tokens = IIndexPool(indexPool).getCurrentTokens();
    uint256[] memory amountsToPool = new uint256[](tokens.length);

    amountInTotal = 0;

    for (uint256 i = 0; i < tokens.length; i++) {
      address token = tokens[i];
      uint256 usedBalance = IIndexPool(indexPool).getUsedBalance(token);
      uint256 amountToPool = bmul(ratio, usedBalance);
      amountsToPool[i] = amountToPool;
      uint amountToPair = _swapInGivenOut(tokenIn, token, amountToPool);
      amountInTotal += amountToPair;
      TransferHelper.safeApprove(token, indexPool, amountToPool);
    }
    require(amountInTotal <= amountInMax, "IndexedUniswapRouterMinter: EXCESSIVE_INPUT_AMOUNT");
    IIndexPool(indexPool).joinPool(poolAmountOut, amountsToPool);
    TransferHelper.safeTransfer(indexPool, msg.sender, poolAmountOut);
  }

  function swapETHForAllTokensAndMintExact(
    address indexPool,
    uint256 poolAmountOut
  ) external payable returns (uint256 amountInTotal) {
    IWETH(weth).deposit{value: msg.value}();
    amountInTotal = swapTokensForAllTokensAndMintExact(
      weth,
      msg.value,
      indexPool,
      poolAmountOut
    );

    if (msg.value > amountInTotal) {
      uint256 remainder = msg.value - amountInTotal;
      IWETH(weth).withdraw(remainder);
      TransferHelper.safeTransferETH(msg.sender, remainder);
    }
  }
}