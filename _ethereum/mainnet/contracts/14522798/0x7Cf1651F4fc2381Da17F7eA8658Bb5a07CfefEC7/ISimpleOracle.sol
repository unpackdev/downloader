// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.3;

contract ISimpleOracle {
  function getReservesForTokenPool(address _token)
    public
    view
    virtual
    returns (uint256 wethReserve, uint256 tokenReserve)
  {}

  function getTokenPrice(address tbnTokenAddress, address paymentTokenAddress)
    public
    view
    virtual
    returns (uint256)
  {}
}
