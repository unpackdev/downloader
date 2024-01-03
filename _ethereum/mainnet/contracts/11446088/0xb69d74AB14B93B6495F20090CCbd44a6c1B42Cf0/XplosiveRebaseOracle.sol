// SPDX-License-Identifier: UNLICENSED
/**
 *
 * ██╗  ██╗███████╗████████╗██╗  ██╗
 * ╚██╗██╔╝██╔════╝╚══██╔══╝██║  ██║
 *  ╚███╔╝ █████╗     ██║   ███████║
 *  ██╔██╗ ██╔══╝     ██║   ██╔══██║
 * ██╔╝ ██╗███████╗   ██║   ██║  ██║
 * ╚═╝  ╚═╝╚══════╝   ╚═╝   ╚═╝  ╚═╝
 *
 *    An Ethereum pegged
 * base-down, burn-up currency.
 *       Rebase-Oracle
 *
 *  https://xEth.finance
 *
 *
**/


/// SWC-103:  Floating Pragma
pragma solidity 0.6.12;

import "./Ownable.sol";
import "./XplosiveSafeMath.sol";
import "./XplosiveEthereumInterface.sol";
import "./UniswapPairInterface.sol";
import "./XplosiveGovenorable.sol";

contract XplosiveRebaseOracle is Ownable, XplosiveGovenorable
{
  using XplosiveSafeMath for uint256;

  /// @notice an event emitted when deviationThreshold is changed
  event NewDeviationThreshold(uint256 oldDeviationThreshold, uint256 newDeviationThreshold);

  event TargetToleranceChanged(uint256 _newTolerance);

  /// @notice Spreads out getting to the target price
  uint256 public rebaseLag;

  /// @notice Peg target
  uint256 public targetRate;

  uint256 private targetTolerance = 0.2 ether;

  // If the current exchange rate is within this fractional distance from the target, no supply
  // update is performed. Fixed point number--same format as the rate.
  // (ie) abs(rate - targetRate) / targetRate < deviationThreshold, then no supply change.
  uint256 public deviationThreshold;

  /// @notice More than this much time must pass between rebase operations.
  uint256 public minRebaseTimeIntervalSec;

  /// @notice Block timestamp of last rebase operation
  uint256 public lastRebaseTimestampSec;

  /// @notice The rebase window begins this many seconds into the minRebaseTimeInterval period.
  // For example if minRebaseTimeInterval is 24hrs, it represents the time of day in seconds.
  uint256 public rebaseWindowOffsetSec;

  /// @notice The length of the time window where a rebase operation is allowed to execute, in seconds.
  uint256 public rebaseWindowLengthSec;

  /// @notice The number of rebase cycles since inception
  uint256 public epoch;

  /// @notice delays rebasing activation to facilitate liquidity
  uint256 public constant rebaseDelay = 0;

  address public xETHAddress;

  address public uniswap_xeth_eth_pair;

  mapping(address => bool) public whitelistFrom;

  constructor(address _XplosiveTokenAddress, address _XplosiveUniswapPairAddress)
  public
  Ownable()
  XplosiveGovenorable()
  {
      minRebaseTimeIntervalSec = 1 days;
      rebaseWindowOffsetSec = 0; // 00:00 UTC rebases
      // Default Target Rate Set For 1 ETH
      targetRate = 10**18;
      // daily rebase, with targeting reaching peg
      rebaseLag = 1;
      // 5%
      // deviationThreshold = 5 * 10**15;
      // 20%
      deviationThreshold = 0.2 ether;
      // 24 hours
      rebaseWindowLengthSec = 24 hours;
      uniswap_xeth_eth_pair = _XplosiveUniswapPairAddress;
      xETHAddress = _XplosiveTokenAddress;
  }

  function setWhitelistedRebaserAddress(address _addr, bool _whitelisted)
  external
  onlyGovenor
  {
      whitelistFrom[_addr] = _whitelisted;
  }


  function _isWhitelisted(address _from)
  internal
  view
  returns (bool)
  {
      return whitelistFrom[_from];
  }

  /**
  * @notice Initiates a new rebase operation, provided the minimum time period has elapsed.
  *
  * @dev The supply adjustment equals (_totalSupply * DeviationFromTargetRate) / rebaseLag
  *      Where DeviationFromTargetRate is (MarketOracleRate - targetRate) / targetRate
  *      and targetRate is 1e18
  */
  function rebase()
  public
  {
    // EOA only
    require(msg.sender == tx.origin);
    require(_isWhitelisted(msg.sender));
    // ensure rebasing at correct time
    _inRebaseWindow();

    require(lastRebaseTimestampSec.add(minRebaseTimeIntervalSec) < now);

    // Snap the rebase time to the start of this window.
    lastRebaseTimestampSec = now;

    epoch = epoch.add(1);

    // get price from uniswap v2;
    // uint256 exchangeRate = getPrice();
    (uint xethReserve, uint ethReserve, ) = UniswapPairInterface(uniswap_xeth_eth_pair).getReserves();
    uint uniPrice = ethReserve.mul(10e18).div(xethReserve);

    // calculates % change to supply
    // (uint256 offPegPerc, bool positive) = computeOffPegPerc(exchangeRate);
    (uint256 offPegPerc, bool positive) = computeOffPegPerc(uniPrice);

    uint256 indexDelta;
    if(!positive)
    {
      indexDelta = uniPrice;
    }
    else
    {
      indexDelta = offPegPerc;
    }

    // Apply the Dampening factor.
    indexDelta = indexDelta.div(rebaseLag);

    XplosiveEthereumInterface xETH = XplosiveEthereumInterface(xETHAddress);

    if (positive)
    {
      require(xETH.xETHScalingFactor().mul(uint256(10**18).add(indexDelta)).div(10**18) < xETH.maxScalingFactor(), "new scaling factor will be too big");
    }

    // rebase
    xETH.rebase(epoch, indexDelta, positive);
    assert(xETH.xETHScalingFactor() <= xETH.maxScalingFactor());
  }

  /**
  * @dev Use Circuit Breakers (Prevents some un godly amount of XETHG to be minted)
  * 1.xETHG Price Marker
  * 2.Set Rebase 20% treashold
  * 3.Calculate Uni Pair Price
  * 4.Target Price + Circuit Breaker
  * 5.Accepted xETHprice Price For Rebase
  * 6.Is Uniswap Price Over Circuit Breaker?
  * 7.Yes, Use Rebase xETHCircuit Breaker Price
  * 8.No, Use Uniswap Price
  */
  // function getPrice()
  // public
  // view
  // onlyGovenor
  // returns (uint256)
  // {
  //   (uint xethReserve, uint ethReserve, ) = UniswapPairInterface(uniswap_xeth_eth_pair).getReserves();
  //   // uint xEthPrice;
  //   // uint ETHER = 1 ether;
  //   // uint ETHER_80 = 0.8 ether;
  //   // uint BASE_20 = ETHER.sub(ETHER_80);
  //   // uint BASE_20 = 0.2 ether;

  //   // uint uniPrice = ethReserve.mul(ETHER).div(xethReserve);
  //   uint uniPrice = ethReserve.mul(10e18).div(xethReserve);
  //   // uint circuitBreaker = (targetRate.mul(BASE_20)).div(10e18);
  //   uint newTargetRate = targetRate.mul(targetTolerance).div(10e18);
  //   // uint xEthCircuitBreakerPrice = targetRate.add(circuitBreaker);
  //   uint expectedTargetRate = targetRate.add(newTargetRate);
  //   if (uniPrice > expectedTargetRate)
  //   {
  //     // return xEthPrice = xEthCircuitBreakerPrice;
  //     return expectedTargetRate;
  //   }
  //   else
  //   {
  //     // return xEthPrice = uniPrice;
  //     return uniPrice;
  //   }

  // }

  function setDeviationThreshold(uint256 deviationThreshold_)
  external
    onlyGovenor

  {
    require(deviationThreshold > 0);
    uint256 oldDeviationThreshold = deviationThreshold;
    deviationThreshold = deviationThreshold_;
    emit NewDeviationThreshold(oldDeviationThreshold, deviationThreshold_);
  }

  /**
  * @notice Sets the rebase lag parameter.
  It is used to dampen the applied supply adjustment by 1 / rebaseLag
  If the rebase lag R, equals 1, the smallest value for R, then the full supply
  correction is applied on each rebase cycle.
  If it is greater than 1, then a correction of 1/R of is applied on each rebase.
  * @param rebaseLag_ The new rebase lag parameter.
  */
  function setRebaseLag(uint256 rebaseLag_)
  external
  onlyGovenor
  {
    require(rebaseLag_ > 0);
    rebaseLag = rebaseLag_;
  }

  /**
  * @notice Sets the targetRate parameter.
  * @param targetRate_ The new target rate parameter.
  */
  function setTargetRate(uint256 targetRate_)
  external
  onlyGovenor
  {
    require(targetRate_ > 0);
    targetRate = targetRate_;
  }

  /**
  * @notice Sets the parameters which control the timing and frequency of
  *         rebase operations.
  *         a) the minimum time period that must elapse between rebase cycles.
  *         b) the rebase window offset parameter.
  *         c) the rebase window length parameter.
  * @param minRebaseTimeIntervalSec_ More than this much time must pass between rebase
  *        operations, in seconds.
  * @param rebaseWindowOffsetSec_ The number of seconds from the beginning of
  the rebase interval, where the rebase window begins.
  * @param rebaseWindowLengthSec_ The length of the rebase window in seconds.
  */
  function setRebaseTimingParameters(uint256 minRebaseTimeIntervalSec_, uint256 rebaseWindowOffsetSec_, uint256 rebaseWindowLengthSec_)
  external
  onlyGovenor
  {
    require(minRebaseTimeIntervalSec_ > 0);
    require(rebaseWindowOffsetSec_ < minRebaseTimeIntervalSec_);

    minRebaseTimeIntervalSec = minRebaseTimeIntervalSec_;
    rebaseWindowOffsetSec = rebaseWindowOffsetSec_;
    rebaseWindowLengthSec = rebaseWindowLengthSec_;
  }

  /**
  * @return If the latest block timestamp is within the rebase time window it, returns true.
  *         Otherwise, returns false.
  */
  function inRebaseWindow()
  public
  view
  returns (bool)
  {
    // rebasing is delayed until there is a liquid market
    _inRebaseWindow();
    return true;
  }

  function _inRebaseWindow()
  internal
  view
  {
    require(now.mod(minRebaseTimeIntervalSec) >= rebaseWindowOffsetSec, "too early");
    require(now.mod(minRebaseTimeIntervalSec) < (rebaseWindowOffsetSec.add(rebaseWindowLengthSec)), "too late");
  }

  // function testComputeOddPegPercent(uint256 _rate)
  // external
  // view
  // onlyOwner
  // returns (uint256, bool)
  // {
  //   (uint256 difference, bool overtarget) = computeOffPegPerc(_rate);
  //   return (difference, overtarget);
  // }

  /**
  * @return Computes in % how far off market is from peg
  */
  function computeOffPegPerc(uint256 rate)
  private
  view
  returns (uint256, bool)
  {
    if (withinDeviationThreshold(rate))
    {
      return (0, false);
    }

    // indexDelta =  (rate - targetRate) / targetRate
    if (rate > targetRate)
    {
      uint256 t = rate.sub(targetRate).mul(10**18).div(targetRate);
      if(t > deviationThreshold)
      {
        return (deviationThreshold, true);
      }

      return (t, true);
    }

    // return (targetRate.sub(rate).mul(10**18).div(targetRate), false);
    return (0, false);
  }

  // function testWithinDeviationThreshold(uint256 _rate)
  // external
  // view
  // onlyOwner
  // returns (bool)
  // {
  //   bool b = withinDeviationThreshold(_rate);
  //   return b;
  // }

  /**
  * @param rate The current exchange rate, an 18 decimal fixed point number.
  * @return If the rate is within the deviation threshold from the target rate, returns true.
  *         Otherwise, returns false.
  */
  function withinDeviationThreshold(uint256 rate)
  private
  view
  returns (bool)
  {
    uint256 absoluteDeviationThreshold = targetRate.mul(deviationThreshold).div(10 ** 18);
    return (rate >= targetRate && rate.sub(targetRate) < absoluteDeviationThreshold) || (rate < targetRate && targetRate.sub(rate) < absoluteDeviationThreshold);
  }

  // function getTargetTolerance()
  // public
  // view
  // returns (uint256)
  // {
  //   return targetTolerance;
  // }

  // function setTargetTolerance(uint256 _newTolerance)
  // external
  // onlyGovenor
  // {
  //   targetTolerance = _newTolerance;
  //   emit TargetToleranceChanged(targetTolerance);
  // }
}
