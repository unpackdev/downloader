// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.7.0;

import "./IUniswapV2Router01.sol";
import "./IUniswapV2Pair.sol";
import "./IUniswapV2Factory.sol";
import "./UniswapV2Library.sol";
import "./IOldERC20.sol";

contract SimpleOracle {
  address public immutable weth;
  IUniswapV2Factory public uniswapV2Factory;

  constructor(address _weth, address factory) {
    weth = _weth;
    uniswapV2Factory = IUniswapV2Factory(factory);
  }

  function getReservesForTokenPool(address _token)
    public
    view
    returns (uint256 wethReserve, uint256 tokenReserve)
  {
    IUniswapV2Pair pair = IUniswapV2Pair(
      uniswapV2Factory.getPair(_token, weth)
    );

    uint112 _wethReserve;
    uint112 _tokenReserve;
    // get token 0 from pair
    // if token 0 is provided _token
    if (pair.token0() == _token) {
      // return tokenReserve as reserve 0 and wethReserve as reserve1
      (_tokenReserve, _wethReserve, ) = pair.getReserves();
      wethReserve = uint256(_wethReserve);
      tokenReserve = uint256(_tokenReserve);
    } else {
      // else return wethReserve as reserve 0 and tokenReserve as reserve1
      (_wethReserve, _tokenReserve, ) = IUniswapV2Pair(pair).getReserves();
      wethReserve = uint256(_wethReserve);
      tokenReserve = uint256(_tokenReserve);
    }
    require(_tokenReserve != 0, "token reserves cannot be zero");
    require(_wethReserve != 0, "weth reserves cannot be zero");
  }

  function getTokenPrice(address tbnTokenAddress, address paymentTokenAddress)
    external
    view
    returns (uint256)
  {
    /** Calculation of price - get common base between reserves 
        and divide out for exchange rate
    */
    require(
      tbnTokenAddress != paymentTokenAddress,
      "Cannot get price for same token"
    );
    //   Get the reserves
    (
      uint256 tbnWETHReserves,
      uint256 tbnTokenReserves
    ) = getReservesForTokenPool(tbnTokenAddress);
    (
      uint256 paymentWETHReserves,
      uint256 paymentTokenReserves
    ) = getReservesForTokenPool(paymentTokenAddress);

    // get the decimals
    uint8 tbnTokenDecimals = IOldERC20(tbnTokenAddress).decimals();
    uint8 paymentTokenDecimals = IOldERC20(paymentTokenAddress).decimals();

    // tbnTokenPrice / paymentTokenPrice
    if (paymentTokenDecimals < tbnTokenDecimals) {
      uint8 decimalDiff = tbnTokenDecimals - paymentTokenDecimals;
      return
        (1 ether * tbnWETHReserves * paymentTokenReserves * (10**decimalDiff)) /
        (paymentWETHReserves * tbnTokenReserves);
    } else if (tbnTokenDecimals < paymentTokenDecimals) {
      uint8 decimalDiff = paymentTokenDecimals - tbnTokenDecimals;
      return
        (1 ether * tbnWETHReserves * paymentTokenReserves) /
        (paymentWETHReserves * tbnTokenReserves * (10**decimalDiff));
    } else {
      return
        (1 ether * tbnWETHReserves * paymentTokenReserves) /
        (paymentWETHReserves * tbnTokenReserves);
    }
  }
}
