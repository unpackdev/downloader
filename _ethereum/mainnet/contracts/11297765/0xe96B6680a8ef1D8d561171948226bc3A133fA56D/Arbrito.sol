//SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.7.5;

import "./IBalancer.sol";
import "./IUniswap.sol";
import "./IERC20.sol";

contract Arbrito is IUniswapPairCallee {
  enum Borrow { Token0, Token1 }

  function perform(
    Borrow borrow,
    uint256 amount,
    address uniswapPair,
    address balancerPool,
    address uniswapToken0,
    address uniswapToken1,
    uint256 uniswapReserve0,
    uint256 uniswapReserve1,
    uint256 blockNumber
  ) external {
    require(block.number == blockNumber, "Delayed execution");

    (uint256 reserve0, uint256 reserve1, ) = IUniswapPair(uniswapPair).getReserves();
    require(reserve0 == uniswapReserve0, "Reserve0 mismatch");
    require(reserve1 == uniswapReserve1, "Reserve1 mismatch");

    bytes memory payload =
      abi.encode(
        balancerPool,
        msg.sender,
        uniswapToken0,
        uniswapToken1,
        uniswapReserve0,
        uniswapReserve1
      );

    if (borrow == Borrow.Token0) {
      IUniswapPair(uniswapPair).swap(amount, 0, address(this), payload);
    } else {
      IUniswapPair(uniswapPair).swap(0, amount, address(this), payload);
    }
  }

  function uniswapV2Call(
    address, // sender
    uint256 amount0,
    uint256 amount1,
    bytes calldata data
  ) external override {
    (
      address balancerPoolAddress,
      address ownerAddress,
      address token0,
      address token1,
      uint256 reserve0,
      uint256 reserve1
    ) = abi.decode(data, (address, address, address, address, uint256, uint256));

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

    IERC20(tokenTrade).approve(balancerPoolAddress, amountTrade);

    (uint256 balancerAmountOut, ) =
      IBalancerPool(balancerPoolAddress).swapExactAmountIn(
        tokenTrade,
        amountTrade,
        tokenPayback,
        amountPayback,
        uint256(-1)
      );

    require(IERC20(tokenPayback).transfer(msg.sender, amountPayback), "Payback failed");

    require(
      IERC20(tokenPayback).transfer(ownerAddress, balancerAmountOut - amountPayback),
      "Sender transfer failed"
    );
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
}
