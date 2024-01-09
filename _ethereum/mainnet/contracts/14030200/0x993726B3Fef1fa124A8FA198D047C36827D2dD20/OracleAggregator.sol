// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.6;

import "IERC20.sol";
import "IPriceOracle.sol";
import "SafeOwnable.sol";

interface IExternalOracle {
  function price(address _token) external view returns (uint);
}

contract OracleAggregator is IPriceOracle, SafeOwnable {

  address internal constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

  mapping (address => IExternalOracle) public oracles;

  event SetOracle(address indexed token, address indexed oracle);

  function setOracle(address _token, IExternalOracle _value) external onlyOwner {
    oracles[_token] = _value;
    emit SetOracle(_token, address(_value));
  }

  function tokenPrice(address _token) public view override returns(uint) {
    if (_token == WETH) { return 1e18; }
    return oracles[_token].price(_token);
  }

  // Not used in any code to save gas. But useful for external usage.
  function convertTokenValues(address _fromToken, address _toToken, uint _amount) external view override returns(uint) {
    uint priceFrom = tokenPrice(_fromToken) * 1e18 / 10 ** IERC20(_fromToken).decimals();
    uint priceTo   = tokenPrice(_toToken)   * 1e18 / 10 ** IERC20(_toToken).decimals();
    return _amount * priceFrom / priceTo;
  }

  function tokenSupported(address _token) external view override returns(bool) {
    if (_token == WETH) { return true; }
    return address(oracles[_token]) != address(0);
  }
}
