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

  receive() external payable {
    require(msg.sender == weth, "IndexedUniswapRouterMinter: RECEIVED_ETHER");
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

  /**
   * @dev Swaps ether for each token in `path` using their Uniswap pairs,
   * then mints at least `minPoolAmountOut` pool tokens from `indexPool`.
   *
   * @param path Array of tokens to swap using the Uniswap router.
   * @param indexPool Address of the index pool to mint tokens from.
   * @param minPoolAmountOut Amount of pool tokens that must be received to not revert.
   */
  function swapExactETHForTokensAndMint(
    address[] calldata path,
    address indexPool,
    uint minPoolAmountOut
  ) external payable returns (uint poolAmountOut) {
    require(path[0] == weth, 'IndexedUniswapRouterMinter: INVALID_PATH');
    uint[] memory amounts = UniswapV2Library.getAmountsOut(factory, msg.value, path);

    IWETH(weth).deposit{value: amounts[0]}();
    require(
      IWETH(weth).transfer(UniswapV2Library.pairFor(factory, path[0], path[1]), amounts[0]),
      "IndexedUniswapRouterMinter: WETH_TRANSFER_FAIL"
    );
    _swap(amounts, path);

    uint amountOut =  amounts[amounts.length - 1];
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
   *
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
    uint[] memory amounts = UniswapV2Library.getAmountsOut(factory, amountIn, path);
    TransferHelper.safeTransferFrom(
      path[0], msg.sender, UniswapV2Library.pairFor(factory, path[0], path[1]), amounts[0]
    );
    _swap(amounts, path);
    uint amountOut = amounts[amounts.length - 1];

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
   *
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
    require(path[0] == weth, 'IndexedUniswapRouterMinter: INVALID_PATH');

    uint[] memory amounts = UniswapV2Library.getAmountsIn(factory, amountOut, path);
    require(amounts[0] <= msg.value, 'IndexedUniswapRouterMinter: EXCESSIVE_INPUT_AMOUNT');

    IWETH(weth).deposit{value: amounts[0]}();
    require(
      IWETH(weth).transfer(UniswapV2Library.pairFor(factory, path[0], path[1]), amounts[0]),
      "IndexedUniswapRouterMinter: WETH_TRANSFER_FAIL"
    );
    _swap(amounts, path);

    // refund dust eth, if any
    if (msg.value > amounts[0]) {
      TransferHelper.safeTransferETH(msg.sender, msg.value - amounts[0]);
    }

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
   *
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
    uint[] memory amounts = UniswapV2Library.getAmountsIn(factory, amountOut, path);
    require(amounts[0] <= amountInMax, 'IndexedUniswapRouterMinter: EXCESSIVE_INPUT_AMOUNT');
    TransferHelper.safeTransferFrom(
      path[0], msg.sender, UniswapV2Library.pairFor(factory, path[0], path[1]), amounts[0]
    );
    _swap(amounts, path);
    _mintPoolAmountOut(
      swapTokenOut,
      amountOut,
      indexPool,
      poolAmountOut
    );
  }

  function _getSwapAmountsForJoin(
    address indexPool,
    address intermediate,
    address poolToken,
    address[] memory path,
    uint256 poolRatio
  ) internal view returns (uint[] memory amounts) {
    if (intermediate == address(0)) {
      // If no intermediate token is given, set path length to 2 so the other
      // functions will not use the 3rd address.
      assembly { mstore(path, 2) }
      path[1] = poolToken;
    } else {
      // If an intermediary is given, set path length to 3 so the other
      // functions will use all addresses.
      assembly { mstore(path, 3) }
      path[1] = intermediate;
      path[2] = poolToken;
    }
    uint256 usedBalance = IIndexPool(indexPool).getUsedBalance(poolToken);
    uint256 amountToPool = bmul(poolRatio, usedBalance);
    amounts = UniswapV2Library.getAmountsIn(factory, amountToPool, path);
  }

  /**
   * @dev Swaps an input token for every underlying token in an index pool,
   * then mints `poolAmountOut` pool tokens from the pool.
   *
   * Up to one intermediary token may be provided in `intermediaries` for each
   * underlying token in the index pool.
   *
   * If a null address is provided as an intermediary, the input token will be
   * swapped directly for the output token.
   */
  function swapTokensForAllTokensAndMintExact(
    address tokenIn,
    uint256 amountInMax,
    address[] calldata intermediaries,
    address indexPool,
    uint256 poolAmountOut
  ) external returns (uint256 amountInTotal) {
    address[] memory tokens = IIndexPool(indexPool).getCurrentTokens();
    require(
      tokens.length == intermediaries.length,
      "IndexedUniswapRouterMinter: BAD_ARRAY_LENGTH"
    );
    uint256[] memory amountsToPool = new uint256[](tokens.length);

    uint256 ratio = bdiv(poolAmountOut, IERC20(indexPool).totalSupply());

    // Reserve 3 slots in memory for the addresses
    address[] memory path = new address[](3);
    path[0] = tokenIn;

    for (uint256 i = 0; i < tokens.length; i++) {
      uint[] memory amounts = _getSwapAmountsForJoin(
        indexPool,
        intermediaries[i],
        tokens[i],
        path,
        ratio
      );
      amountInMax = SafeMath.sub(amountInMax, amounts[0], "IndexedUniswapRouterMinter: EXCESSIVE_INPUT_AMOUNT");

      TransferHelper.safeTransferFrom(
        path[0], msg.sender, UniswapV2Library.pairFor(factory, path[0], path[1]), amounts[0]
      );
      _swap(amounts, path);

      uint amountToPool = amounts[amounts.length - 1];
      amountsToPool[i] = amountToPool;
      amountInTotal = SafeMath.add(amountInTotal, amounts[0]);
      TransferHelper.safeApprove(tokens[i], indexPool, amountToPool);
    }
    IIndexPool(indexPool).joinPool(poolAmountOut, amountsToPool);
    TransferHelper.safeTransfer(indexPool, msg.sender, poolAmountOut);
  }

  /**
   * @dev Swaps ether for every underlying token in an index pool,
   * then mints `poolAmountOut` pool tokens from the pool.
   *
   * Up to one intermediary token may be provided in `intermediaries` for each
   * underlying token in the index pool.
   *
   * If a null address is provided as an intermediary, the input token will be
   * swapped directly for the output token.
   */
  function swapETHForAllTokensAndMintExact(
    address indexPool,
    address[] calldata intermediaries,
    uint256 poolAmountOut
  ) external payable returns (uint amountInTotal) {
    uint256 amountInMax = msg.value;
    IWETH(weth).deposit{value: msg.value}();
    address[] memory tokens = IIndexPool(indexPool).getCurrentTokens();
    require(
      tokens.length == intermediaries.length,
      "IndexedUniswapRouterMinter: BAD_ARRAY_LENGTH"
    );
    uint256[] memory amountsToPool = new uint256[](tokens.length);

    uint256 ratio = bdiv(poolAmountOut, IERC20(indexPool).totalSupply());

    // Reserve 3 slots in memory for the addresses
    address[] memory path = new address[](3);
    path[0] = weth;

    for (uint256 i = 0; i < tokens.length; i++) {
      uint[] memory amounts = _getSwapAmountsForJoin(
        indexPool,
        intermediaries[i],
        tokens[i],
        path,
        ratio
      );
      amountInMax = SafeMath.sub(amountInMax, amounts[0], "IndexedUniswapRouterMinter: EXCESSIVE_INPUT_AMOUNT");

      require(
        IWETH(weth).transfer(UniswapV2Library.pairFor(factory, path[0], path[1]), amounts[0]),
        "IndexedUniswapRouterMinter: WETH_TRANSFER_FAIL"
      );
      _swap(amounts, path);

      uint amountToPool = amounts[amounts.length - 1];
      amountsToPool[i] = amountToPool;
      amountInTotal = SafeMath.add(amountInTotal, amounts[0]);
      TransferHelper.safeApprove(tokens[i], indexPool, amountToPool);
    }
    IIndexPool(indexPool).joinPool(poolAmountOut, amountsToPool);
    TransferHelper.safeTransfer(indexPool, msg.sender, poolAmountOut);

    if (msg.value > amountInTotal) {
      uint256 remainder = msg.value - amountInTotal;
      IWETH(weth).withdraw(remainder);
      TransferHelper.safeTransferETH(msg.sender, remainder);
    }
  }
}