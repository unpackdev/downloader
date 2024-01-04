// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "./IERC20.sol";
import "./ISystemStatus.sol";
import "./ISynthetix.sol";

import "./IBPool.sol";
import "./ISwaps.sol";

/**
 * @title sTSLA on-ramp
 */
contract TSLAExchange {
  // tokens
  address private constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
  address private constant SUSD = 0x57Ab1ec28D129707052df4dF418D58a2D46d5f51;
  address private constant STSLA = 0x918dA91Ccbc32B7a6A0cc4eCd5987bbab6E31e6D;
  // synthetix
  address private constant SNX = 0x97767D7D04Fd0dB0A1a2478DCd4BA85290556B48;
  address private constant SYSTEM_STATUS = 0x1c86B3CDF2a60Ae3a574f7f71d44E2C50BDdB87E;
  // curve
  address private constant SWAPS = 0xD1602F68CC7C4c7B59D686243EA35a9C73B0c6a2;
  // balancer
  address private constant BPOOL = 0x055dB9AFF4311788264798356bbF3a733AE181c6;

  constructor () {
    IERC20(USDC).approve(SWAPS, type(uint).max);
    IERC20(SUSD).approve(BPOOL, type(uint).max);
  }

  /**
   * @notice exchange USDC for sTSLA on behalf of sender
   * @dev contract must be approved to spend USDC
   * @dev contract must be approved to exchange on Synthetix on behalf of sender
   * @param amount quantity of USDC to exchange
   * @param susdMin minimum quantity of sUSD output by Curve
   * @param stslaMin minimum quantity of sTSLA output by Balancer
   * @return susd sUSD output amount
   * @return stsla sTSLA output amount
   */
  function exchange (
    uint amount,
    uint susdMin,
    uint stslaMin
  ) external returns (uint susd, uint stsla) {
    IERC20(USDC).transferFrom(msg.sender, address(this), amount);

    (bool suspended, ) = ISystemStatus(SYSTEM_STATUS).synthExchangeSuspension(
      'sTSLA'
    );

    susd = ISwaps(SWAPS).exchange_with_best_rate(
      USDC,
      SUSD,
      amount,
      susdMin,
      suspended ? address(this) : msg.sender
    );

    if (suspended) {
      (stsla, ) = IBPool(BPOOL).swapExactAmountIn(
        SUSD,
        susd,
        STSLA,
        stslaMin,
        type(uint).max
      );

      IERC20(STSLA).transfer(msg.sender, stsla);
    } else {
      stsla = ISynthetix(SNX).exchangeOnBehalf(
        msg.sender,
        'sUSD',
        susd,
        'sTSLA'
      );
    }

    return (susd, stsla);
  }
}
