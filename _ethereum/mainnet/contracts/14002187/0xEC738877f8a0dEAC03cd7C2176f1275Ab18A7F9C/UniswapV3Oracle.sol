// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.6;

import "IERC20.sol";
import "IUniswapV3Pool.sol";
import "IUniswapV3Factory.sol";
import "ILinkOracle.sol";
import "IPriceOracle.sol";
import "IUniswapPriceConverter.sol";

import "SafeOwnable.sol";
import "AddressLibrary.sol";

contract UniswapV3Oracle is IPriceOracle, SafeOwnable {

  using AddressLibrary for address;

  IUniswapV3Factory public constant uniFactory = IUniswapV3Factory(0x1F98431c8aD98523631AE4a59f267346ea31F984);
  address           public constant WETH       = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
  uint24            public constant POOL_FEE   = 3000;

  uint32 public twapPeriod;
  uint16 public minObservations;

  IUniswapPriceConverter public uniPriceConverter;

  event PoolAdded(address indexed token);
  event PoolRemoved(address indexed token);
  event NewTwapPeriod(uint32 value);
  event NewMinObservations(uint16 value);
  event NewUniPriceConverter(address indexed value);

  constructor(
    address _uniPriceConverter,
    uint32 _twapPeriod,
    uint16 _minObservations
  ) {

    setUniPriceConverter(_uniPriceConverter);
    setTwapPeriod(_twapPeriod);
    setMinObservations(_minObservations);
  }

  function setUniPriceConverter(address _value) public onlyOwner {
    require(_value.isContract(), 'UniswapV3Oracle: _value must be a contract');
    uniPriceConverter = IUniswapPriceConverter(_value);
    emit NewUniPriceConverter(_value);
  }

  function setTwapPeriod(uint32 _value) public onlyOwner {
    twapPeriod = _value;
    emit NewTwapPeriod(_value);
  }

  function setMinObservations(uint16 _value) public onlyOwner {
    minObservations = _value;
    emit NewMinObservations(_value);
  }

  // Returns token price in ETH
  function tokenPrice(address _token) public view override returns(uint) {
    require(tokenSupported(_token), "UniswapV3Oracle: token not supported");
    if (_token == WETH) { return 1e18; }

    return uniPriceConverter.assetToEth(
      _token,
      10 ** IERC20(_token).decimals(),
      twapPeriod
    );
  }

  // Not used in any LendingPair to save gas. But useful for external usage.
  function convertTokenValues(address _fromToken, address _toToken, uint _amount) external view override returns(uint) {
    uint priceFrom = tokenPrice(_fromToken) * 1e18 / 10 ** IERC20(_fromToken).decimals();
    uint priceTo   = tokenPrice(_toToken)   * 1e18 / 10 ** IERC20(_toToken).decimals();
    return _amount * priceFrom / priceTo;
  }

  function tokenSupported(address _token) public view override returns(bool) {
    if (_token == WETH) { return true; }
    address poolAddress = uniFactory.getPool(_token, WETH, POOL_FEE);
    if (poolAddress == address(0)) { return false; }

    (, , , , uint16 observationSlots, ,) = IUniswapV3Pool(poolAddress).slot0();
    return observationSlots >= minObservations;
  }
}
