// SPDX-License-Identifier: MIT
pragma solidity =0.8.19;

import "./IERC20.sol";
import "./Ownable.sol";
import "./SafeMath.sol";

import "./AggregatorV3Interface.sol";

import "./IUniswapV2Router02.sol";
import "./IReserveOracle.sol";
import "./IRSRV.sol";

contract ReserveOracle is IReserveOracle, Ownable {
  using SafeMath for uint;

  IRSRV public token;
  address public reserve;
  address public WETH;
  address public uniswapV2Pair;
  uint public previousAthMarketCap;
  uint public timestampReset;
  uint public activeMultiplier = 10000;
  uint public baseMultiplier = 10000;
  uint public boostMultiplier = 10;
  uint public percentageForHalt = 4000;
  uint public percentageForReset = 2000;
  uint public startTime;
  uint public lastUpdateTime;
  uint public startThreshold = 1 weeks;
  uint public resetDelay = 1 days;
  uint public resetCooldown = 12 hours;

  uint private _lastMarketCap;
  uint private _lastPercentage = 10000;

  AggregatorV3Interface internal dataFeed;

  constructor(
    address _dataFeed
  ) {
    // GOERLI ETH/USD PRICE FEED: 0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e
    // MAINNET ETH/USD PRICE FEED: 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419
    dataFeed = AggregatorV3Interface(_dataFeed);
  }

  function getEthPrice() public view returns (uint) {
    (
      /* uint80 roundID */,
      int answer,
      /*uint startedAt*/,
      /*uint timeStamp*/,
      /*uint80 answeredInRound*/
    ) = dataFeed.latestRoundData();

    return uint(answer);
  }

  function getPriceData() 
    external 
    view 
  returns (
    uint price, 
    uint circulatingSupply, 
    uint marketCap, 
    uint lastMarketCap, 
    uint lastMultiplier, 
    uint lastPercentage
  ) {
    price = getCurrentPrice();
    circulatingSupply = getCirculatingSupply();
    marketCap = getCurrentMarketCap();
    lastMarketCap = _lastMarketCap;
    lastMultiplier = activeMultiplier;
    lastPercentage = _lastPercentage;
  }

  function getCurrentPrice() public view returns (uint) {
    return _getPriceInEth() * getEthPrice() / 1e8;
  }

  function getCurrentMarketCap() public view returns (uint) {
    return _getMarketCapinEth() * getEthPrice() / 1e8;
  }

  function getCirculatingSupply() public view returns (uint) {
    return IERC20(address(token)).totalSupply() -
      IERC20(address(token)).balanceOf(address(0xdead));
  }

  function getPercentageFromAth() external view returns (uint percentage) {
    if (previousAthMarketCap == 0) return 0;

    uint marketCap = getCurrentMarketCap();
    percentage = marketCap.mul(1e4).div(previousAthMarketCap);
  }

  function _getPriceInEth() internal view returns (uint) {
    uint wethBalance = IERC20(WETH).balanceOf(uniswapV2Pair);
    uint tokenBalance = IERC20(address(token)).balanceOf(uniswapV2Pair);
    return wethBalance.mul(1e18).div(tokenBalance);
  }

  function _getMarketCapinEth() internal view returns (uint) {
    return _getPriceInEth().mul(getCirculatingSupply()).div(1e18);
  }

  /** RESERVED FUNCTIONS **/

  function setCurrentMultiplier() external returns (uint) {
    require (_msgSender() == owner() || _msgSender() == address(reserve), "Not authorized");

    if (startTime == 0) startTime = block.timestamp;

    if (activeMultiplier == 1 && lastUpdateTime.add(resetCooldown) < block.timestamp) {
      return activeMultiplier;
    }

    lastUpdateTime = block.timestamp;

    uint marketCap = getCurrentMarketCap();
    _lastMarketCap = marketCap;
    if (previousAthMarketCap == 0) {
      previousAthMarketCap = marketCap;
      return activeMultiplier;
    } else {
      uint multiplier;
      if (marketCap >= previousAthMarketCap) {
        previousAthMarketCap = marketCap;
        multiplier = baseMultiplier;
        _lastPercentage = 10000;
        timestampReset = 0;
      } else {
        uint percentage = marketCap.mul(1e4).div(previousAthMarketCap);
        _lastPercentage = percentage;
        if (percentage >= percentageForHalt) {
          multiplier = baseMultiplier.add(uint(1e4).sub(percentage).mul(boostMultiplier));
          timestampReset = 0;
        } else if (percentage >= percentageForReset) {
          multiplier = 0;
          timestampReset = 0;
        } else {
          if (startTime.add(startThreshold) < block.timestamp) {
            if (timestampReset == 0) {
              timestampReset = block.timestamp;
              multiplier = 0;
            } else {
              if (timestampReset.add(resetDelay) < block.timestamp) {
                previousAthMarketCap = marketCap;
                multiplier = 1;
                startTime = block.timestamp;
                timestampReset = 0;
              } else {
                multiplier = 0;
              }
            }
          } else {
            multiplier = 0;
            timestampReset = 0;
          }
        }
      }

      activeMultiplier = multiplier;
      return activeMultiplier;
    }
  }

  function setToken(address _token) external onlyOwner {
    token = IRSRV(_token);
    uniswapV2Pair = token.uniswapV2Pair();

    IUniswapV2Router02 router = IUniswapV2Router02(token.uniswapV2Router());
    WETH = router.WETH();
  }

  function setReserve(address _reserve) external onlyOwner {
    require (_reserve != address(0), "Invalid reserve address");
    reserve = _reserve;
  }

  function setBaseMultiplier(uint _multiplier) external onlyOwner {
    baseMultiplier = _multiplier;
  }

  function setBoostMultiplier(uint _multiplier) external onlyOwner {
    boostMultiplier = _multiplier;
  }

  function setStartThreshold(uint _threshold) external onlyOwner {
    startThreshold = _threshold;
  }

  function setResetDelay(uint _resetDelay) external onlyOwner {
    resetDelay = _resetDelay;
  }

  function setResetCooldown(uint _resetCooldown) external onlyOwner {
    resetCooldown = _resetCooldown;
  }

  function setPercentages(uint _percentageForHalt, uint _percentageForReset) external onlyOwner {
    percentageForHalt = _percentageForHalt;
    percentageForReset = _percentageForReset;
  }
}