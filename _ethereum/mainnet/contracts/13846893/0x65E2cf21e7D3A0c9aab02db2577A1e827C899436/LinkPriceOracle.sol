// SPDX-License-Identifier: UNLICENSED

// Copyright (c) WildCredit - All rights reserved
// https://twitter.com/WildCredit

import "IERC20.sol";
import "ILinkOracle.sol";
import "IPriceOracle.sol";
import "SafeOwnable.sol";

pragma solidity 0.8.6;

contract LinkPriceOracle is IPriceOracle, SafeOwnable {

  uint public MIN_ORACLE_FRESHNESS = 3 hours;

  mapping(address => ILinkOracle) public linkOracles;
  mapping(address => uint) private tokenPrices;

  event AddLinkOracle(address indexed token, address oracle);
  event RemoveLinkOracle(address indexed token);
  event PriceUpdate(address indexed token, uint amount);

  function addLinkOracle(address _token, ILinkOracle _linkOracle) external onlyOwner {
    require(_linkOracle.decimals() == 8, "LinkPriceOracle: non-usd pairs not allowed");
    linkOracles[_token] = _linkOracle;

    emit AddLinkOracle(_token, address(_linkOracle));
  }

  function removeLinkOracle(address _token) external onlyOwner {
    linkOracles[_token] = ILinkOracle(address(0));
    emit RemoveLinkOracle(_token);
  }

  function setTokenPrice(address _token, uint _value) external onlyOwner {
    tokenPrices[_token] = _value;
    emit PriceUpdate(_token, _value);
  }

  // _token price in USD with 18 decimals
  function tokenPrice(address _token) public view override returns(uint) {

    if (tokenPrices[_token] != 0) {
      return tokenPrices[_token];

    } else if (address(linkOracles[_token]) != address(0)) {

      (, int answer, , uint updatedAt, ) = linkOracles[_token].latestRoundData();
      uint result = uint(answer);
      uint timeElapsed = block.timestamp - updatedAt;
      require(result > 1, "LinkPriceOracle: invalid oracle value");
      require(timeElapsed <= MIN_ORACLE_FRESHNESS, "LinkPriceOracle: oracle is stale");

      return result * 1e10;

    } else {
      revert("LinkPriceOracle: token not supported");
    }
  }

  function convertTokenValues(address _fromToken, address _toToken, uint _amount) external view override returns(uint) {
    uint priceFrom = tokenPrice(_fromToken) * 1e18 / 10 ** IERC20(_fromToken).decimals();
    uint priceTo   = tokenPrice(_toToken)   * 1e18 / 10 ** IERC20(_toToken).decimals();
    return _amount * priceFrom / priceTo;
  }

  function tokenSupported(address _token) external view override returns(bool) {
    return (
      address(linkOracles[_token]) != address(0) ||
      tokenPrices[_token] != 0
    );
  }
}
