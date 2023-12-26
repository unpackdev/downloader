// SPDX-License-Identifier: LGPL-3.0
pragma solidity 0.8.17;

import "./HopeOneRole.sol";
import "./AutomationCompatibleInterface.sol";
import "./IHOPEPriceFeed.sol";
import "./IHopeAggregator.sol";

contract HopeAutomation is HopeOneRole, AutomationCompatibleInterface {
  uint256 internal constant THRESHOLD_FACTOR = 1e4;

  address public priceFeed;
  address public aggregator;

  uint256 public heartbeat;
  uint256 public deviationThreshold;

  uint256 public lastPrice;
  uint256 public lastTimestamp;

  event HeartbeatUpdated(uint256 newHeartbeat);
  event DeviationThresholdUpdated(uint256 newDeviationThreshold);
  event HOPEPriceFeedUpdated(address newPriceFeed);
  event AggregatorUpdated(address newAggregator);
  event PriceUpdated(uint256 price, uint256 timestamp);

  constructor(address _priceFeed, address _aggregator, uint256 _heartbeat, uint256 _deviationThreshold) {
    _setHOPEPriceFeed(_priceFeed);
    _setAggregator(_aggregator);
    _setHeartbeat(_heartbeat);
    _setDeviationThreshold(_deviationThreshold);
  }

  function setHeartbeat(uint256 _heartbeat) external onlyRole(OPERATOR_ROLE) {
    _setHeartbeat(_heartbeat);
  }

  function setDeviationThreshold(uint256 _deviationThreshold) external onlyRole(OPERATOR_ROLE) {
    _setDeviationThreshold(_deviationThreshold);
  }

  function setHOPEPriceFeed(address _priceFeed) external onlyRole(OPERATOR_ROLE) {
    _setHOPEPriceFeed(_priceFeed);
  }

  function setAggregator(address _aggregator) external onlyRole(OPERATOR_ROLE) {
    _setAggregator(_aggregator);
  }

  function _setHeartbeat(uint256 _heartbeat) internal {
    heartbeat = _heartbeat;
    emit HeartbeatUpdated(_heartbeat);
  }

  function _setDeviationThreshold(uint256 _deviationThreshold) internal {
    deviationThreshold = _deviationThreshold;
    emit DeviationThresholdUpdated(_deviationThreshold);
  }

  function _setHOPEPriceFeed(address _priceFeed) internal {
    priceFeed = _priceFeed;
    emit HOPEPriceFeedUpdated(_priceFeed);
  }

  function _setAggregator(address _aggregator) internal {
    aggregator = _aggregator;
    emit AggregatorUpdated(_aggregator);
  }

  function checkUpkeep(
    bytes calldata /*checkData*/
  ) external view override returns (bool upkeepNeeded, bytes memory /*performData*/) {
    (, upkeepNeeded) = _checkUpKeep();
  }

  function performUpkeep(bytes memory /*performData*/) external override {
    (uint256 price, bool upkeepNeeded) = _checkUpKeep();
    require(upkeepNeeded, 'HopeAutomation: upkeep not needed');
    lastPrice = price;
    lastTimestamp = block.timestamp;
    IHopeAggregator(aggregator).transmit(price);

    emit PriceUpdated(price, block.timestamp);
  }

  function _checkUpKeep() internal view returns (uint256 price, bool upkeepNeeded) {
    price = _getPrice();
    upkeepNeeded = price > 0;
    bool thresholdMet;
    unchecked {
      upkeepNeeded = upkeepNeeded && block.timestamp - lastTimestamp >= heartbeat;
      if (price >= lastPrice) {
        thresholdMet = price - lastPrice >= (deviationThreshold * lastPrice) / THRESHOLD_FACTOR;
      } else {
        thresholdMet = lastPrice - price >= (deviationThreshold * lastPrice) / THRESHOLD_FACTOR;
      }
      upkeepNeeded = upkeepNeeded || thresholdMet;
    }
  }

  function _getPrice() internal view returns (uint256 price) {
    price = IHOPEPriceFeed(priceFeed).latestAnswer();
  }
}
