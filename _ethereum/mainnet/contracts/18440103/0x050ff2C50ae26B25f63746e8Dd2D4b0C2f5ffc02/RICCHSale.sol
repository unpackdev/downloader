// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "./Ownable.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./Address.sol";
import "./AggregatorV3Interface.sol";

contract RICCHSaleBase is Ownable {
  using Address for address payable;
  using SafeERC20 for IERC20;

  uint constant public USD_UNIT = 1e6;
  uint constant public PRICE = 0.004 * 1e6;
  uint constant public DISCOUNT_30_PRICE = (PRICE * (100 - 30)) / 100;
  uint constant public DISCOUNT_20_PRICE = (PRICE * (100 - 20)) / 100;
  uint constant public DISCOUNT_10_PRICE = (PRICE * (100 - 10)) / 100;
  uint constant public DISCOUNT_5_PRICE = (PRICE * (100 - 5)) / 100;

  uint constant public SALE_START = 1698451200; // 28 Oct 2023, 00:00:00
  uint constant public DISCOUNT_30_END = 1699487999; // 08 Nov 2023, 23:59:59
  uint constant public DISCOUNT_20_END = 1702079999; // 08 Dec 2023, 23:59:59
  uint constant public DISCOUNT_10_END = 1704758399; // 08 Jan 2024, 23:59:59
  uint constant public DISCOUNT_5_END = 1706659199; // 30 Jan 2024, 23:59:59

  IERC20 immutable public USDT;
  IERC20 immutable public USDC;
  IERC20 immutable public RICCH;
  uint constant public RICCH_UNIT = 1e18;
  uint constant public ETH_UNIT = 1 ether;

  AggregatorV3Interface immutable public USD_ETH_FEED;

  event Purchase(address buyer, address paidWith, uint ricchAmount, uint price);

  constructor(IERC20 _ricch, IERC20 _usdt, IERC20 _usdc, AggregatorV3Interface _usdEthFeed, address _owner) {
    _transferOwnership(_owner);
    USDT = _usdt;
    USDC = _usdc;
    USD_ETH_FEED = _usdEthFeed;
    RICCH = _ricch;
  }

  function buyWithToken(IERC20 _payWith, uint _ricchAmount) external {
    bool allowedToken = _payWith == USDT || _payWith == USDC;
    require(allowedToken, 'Token is not allowed');
    require(_ricchAmount > 0, 'Amount should be positive');
    address bank = owner();
    uint priceUSDperRICCH = getCurrentPrice();
    _payWith.safeTransferFrom(msg.sender, bank, divCeil(_ricchAmount * priceUSDperRICCH, RICCH_UNIT));
    RICCH.safeTransferFrom(bank, msg.sender, _ricchAmount);
    emit Purchase(msg.sender, address(_payWith), _ricchAmount, priceUSDperRICCH);
  }

  function buyWithETH() external payable {
    address payable bank = payable(owner());
    uint priceETHperRICCH = divCeil(ETH_UNIT * getCurrentPrice(), getUSDETHPrice());
    uint ricchAmount = msg.value * RICCH_UNIT / priceETHperRICCH;
    require(ricchAmount > 0, 'Amount should be positive');
    RICCH.safeTransferFrom(bank, msg.sender, ricchAmount);
    bank.sendValue(msg.value);
    emit Purchase(msg.sender, address(0), ricchAmount, priceETHperRICCH);
  }

  function getCurrentPrice() public view returns(uint) {
    return getPrice(getTime());
  }

  function getPrice(uint _timestamp) public pure returns(uint) {
    if (_timestamp <= DISCOUNT_30_END) {
      return DISCOUNT_30_PRICE;
    }
    if (_timestamp <= DISCOUNT_20_END) {
      return DISCOUNT_20_PRICE;
    }
    if (_timestamp <= DISCOUNT_10_END) {
      return DISCOUNT_10_PRICE;
    }
    if (_timestamp <= DISCOUNT_5_END) {
      return DISCOUNT_5_PRICE;
    }
    return PRICE;
  }

  function getUSDETHPrice() public view returns(uint) {
    int256 usd8UnitsPerETH;
    (, usd8UnitsPerETH, , , ) = USD_ETH_FEED.latestRoundData();
    require(usd8UnitsPerETH > 0, 'Invalid ETH price');
    uint usdUnitsPerETH = uint(usd8UnitsPerETH / 100);
    require(usdUnitsPerETH > 0, 'usdUnitsPerETH == 0');
    return usdUnitsPerETH;
  }

  function divCeil(uint _a, uint _b) internal pure returns(uint) {
    if (_a % _b == 0) {
      return _a / _b;
    }
    return (_a / _b) + 1;
  }

  function getTime() internal virtual view returns(uint) {
    return block.timestamp;
  }
}

contract RICCHSale is RICCHSaleBase {
  constructor(IERC20 _ricch, address _owner)
  RICCHSaleBase(
    _ricch,
    IERC20(0xdAC17F958D2ee523a2206206994597C13D831ec7),
    IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48),
    AggregatorV3Interface(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419),
    _owner
  ) {}
}

contract RICCHSaleSepolia is RICCHSaleBase {
  uint private testTime;

  constructor(IERC20 _ricch, IERC20 _usdt, IERC20 _usdc, address _owner)
  RICCHSaleBase(
    _ricch,
    _usdt,
    _usdc,
    AggregatorV3Interface(0x694AA1769357215DE4FAC081bf1f309aDC325306),
    _owner
  ) {}

  function setTime(uint _time) external {
    testTime = _time;
  }

  function getTime() internal override view returns(uint) {
    if (testTime == 0) {
      return block.timestamp;
    }
    return testTime;
  }
}
