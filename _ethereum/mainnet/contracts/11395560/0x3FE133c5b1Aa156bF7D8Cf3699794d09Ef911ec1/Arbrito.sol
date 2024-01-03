//SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.7.5;

import "./IBalancer.sol";
import "./IUniswap.sol";
import "./IERC20.sol";
import "./IWeth.sol";

contract Arbrito is IUniswapPairCallee {
  enum Borrow { Token0, Token1 }

  address[] public tokens;
  mapping(address => uint256) public balances;

  address immutable WETH_ADDRESS;
  address immutable UNISWAP_ROUTER_ADDRESS;
  address payable immutable OWNER;

  constructor(address wethAddress, address uniswapRouterAddress) {
    UNISWAP_ROUTER_ADDRESS = uniswapRouterAddress;
    WETH_ADDRESS = wethAddress;
    OWNER = msg.sender;
  }

  receive() external payable {}

  function perform(
    Borrow borrow,
    uint256 amount,
    address uniswapPair,
    address balancerPool,
    address uniswapToken0,
    address uniswapToken1,
    uint256 uniswapReserve0,
    uint256 uniswapReserve1,
    uint256 balancerBalance0,
    uint256 balancerBalance1
  ) external {
    (uint256 reserve0, uint256 reserve1, ) = IUniswapPair(uniswapPair).getReserves();

    require(
      borrow == Borrow.Token0
        ? (reserve0 >= uniswapReserve0 && reserve1 <= uniswapReserve1)
        : (reserve0 <= uniswapReserve0 && reserve1 >= uniswapReserve1),
      "Uniswap reserves mismatch"
    );

    {
      uint256 balance0 = IBalancerPool(balancerPool).getBalance(uniswapToken0);
      uint256 balance1 = IBalancerPool(balancerPool).getBalance(uniswapToken1);

      require(
        borrow == Borrow.Token0
          ? balance0 <= balancerBalance0 && balance1 >= balancerBalance1
          : balance0 >= balancerBalance0 && balance1 <= balancerBalance1,
        "Balancer balances mismatch"
      );
    }

    bytes memory payload =
      abi.encode(balancerPool, uniswapToken0, uniswapToken1, reserve0, reserve1);

    if (borrow == Borrow.Token0) {
      IUniswapPair(uniswapPair).swap(amount, 0, address(this), payload);
    } else {
      IUniswapPair(uniswapPair).swap(0, amount, address(this), payload);
    }
  }

  function uniswapV2Call(
    address sender,
    uint256 amount0,
    uint256 amount1,
    bytes calldata data
  ) external override {
    (
      address balancerPoolAddress,
      address token0,
      address token1,
      uint256 reserve0,
      uint256 reserve1
    ) = abi.decode(data, (address, address, address, uint256, uint256));

    uint256 amountTrade;
    uint256 amountPayback;

    address tokenPayback;
    address tokenTrade;

    if (amount0 != 0) {
      amountTrade = amount0;
      (tokenTrade, tokenPayback) = (token0, token1);
      amountPayback = calculateUniswapPayback(amountTrade, reserve1, reserve0);
    } else {
      amountTrade = amount1;
      (tokenPayback, tokenTrade) = (token0, token1);
      amountPayback = calculateUniswapPayback(amountTrade, reserve0, reserve1);
    }

    allow(sender, balancerPoolAddress, tokenTrade, amountTrade);

    (uint256 balancerAmountOut, ) =
      IBalancerPool(balancerPoolAddress).swapExactAmountIn(
        tokenTrade,
        amountTrade,
        tokenPayback,
        amountPayback,
        uint256(-1)
      );

    require(IERC20(tokenPayback).transfer(msg.sender, amountPayback), "Payback failed");

    if (balances[tokenPayback] == 0) {
      tokens.push(tokenPayback);
    }

    balances[tokenPayback] += balancerAmountOut - amountPayback;
  }

  function allow(
    address owner,
    address spender,
    address token,
    uint256 amount
  ) internal {
    if (IERC20(token).allowance(owner, spender) < amount) {
      IERC20(token).approve(spender, uint256(-1));
    }
  }

  function calculateUniswapPayback(
    uint256 amountOut,
    uint256 reserveIn,
    uint256 reserveOut
  ) internal pure returns (uint256) {
    uint256 numerator = reserveIn * amountOut * 1000;
    uint256 denominator = (reserveOut - amountOut) * 997;
    return numerator / denominator + 1;
  }

  function withdraw() external {
    address[] memory path = new address[](2);
    address me = address(this);
    path[1] = WETH_ADDRESS;

    uint256 weth = 0;
    for (uint256 i = 0; i < tokens.length; i++) {
      address token = tokens[i];

      if (token == WETH_ADDRESS) {
        weth += balances[token];
      } else {
        path[0] = token;

        allow(me, UNISWAP_ROUTER_ADDRESS, token, balances[token]);

        weth += IUniswapRouter(UNISWAP_ROUTER_ADDRESS).swapExactTokensForTokens(
          balances[token],
          0,
          path,
          me,
          block.timestamp
        )[1];
      }

      delete balances[token];
    }

    delete tokens;

    IWeth(WETH_ADDRESS).withdraw(weth);
    OWNER.transfer(weth);
  }
}
