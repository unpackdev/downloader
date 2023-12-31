//SPDX-License-Identifier: MIT
pragma solidity ^0.6.8;
pragma experimental ABIEncoderV2;

import "./ERC20.sol";
import "./SafeMath.sol";

import "./PriceOracle.sol";
import "./CTokenInterface.sol";

contract CTokenPriceOracle is PriceOracle {
  using SafeMath for uint256;

  constructor() public {}

  /// @dev Get the exchange rate of one cToken to one underlying token in wads
  function getPrice(address cTokenAddress) external view override returns (uint256) {
    CTokenInterface cToken = CTokenInterface(cTokenAddress);
    return cToken.exchangeRateStored();
  }
}
