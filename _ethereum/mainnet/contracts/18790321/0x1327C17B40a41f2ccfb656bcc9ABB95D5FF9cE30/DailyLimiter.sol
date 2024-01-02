pragma solidity 0.8.9;
import "./SafeMath.sol";

library DailyLimiter {
  using SafeMath for uint256;

  error DailyLimitExceeded(uint256 dailyLimit, uint256 amount);
  event DailyLimitSet(DailyLimitConfig config);
  event TokenDailyLimitConsumed(address tokenAddress, uint256 amount);

  struct DailyLimitTokenInfo {
    uint256 tokenAmount;
    uint32 refreshTime;
    uint256 defaultTokenAmount;
  }

  struct DailyLimitConfig {
    bytes32 dailyLimitId; //tokenKey/swapId
    uint32 refreshTime;
    uint256 defaultTokenAmount;
  }

  uint32 constant DefaultRefreshTime = 86400;

  function _setDailyLimit(
    DailyLimitTokenInfo storage _dailyLimitTokenInfo,
    DailyLimitConfig memory _config
  ) internal {
    require((uint256)(_config.refreshTime).mod(DefaultRefreshTime) == 0, 'Invalid refresh time.');
    require(
      block.timestamp >= _config.refreshTime &&
        (block.timestamp.sub(_config.refreshTime)) <= DefaultRefreshTime,
      'Only daily limits are supported within the contract.'
    );
    if (
      _dailyLimitTokenInfo.refreshTime != 0 &&
      (block.timestamp.sub(_dailyLimitTokenInfo.refreshTime)).div(DefaultRefreshTime) < 1
    ) {
      uint256 defaultTokenAmount = _dailyLimitTokenInfo.defaultTokenAmount;
      uint256 currentTokenAmount = _dailyLimitTokenInfo.tokenAmount;
      uint256 useAmount = defaultTokenAmount.sub(currentTokenAmount);
      _dailyLimitTokenInfo.tokenAmount = _config.defaultTokenAmount <= useAmount
        ? 0
        : _config.defaultTokenAmount.sub(useAmount);
    } else {
      _dailyLimitTokenInfo.tokenAmount = _config.defaultTokenAmount;
    }
    _dailyLimitTokenInfo.defaultTokenAmount = _config.defaultTokenAmount;
    _dailyLimitTokenInfo.refreshTime = _config.refreshTime;
    emit DailyLimitSet(_config);
  }

  function _consume(
    DailyLimitTokenInfo storage _dailyLimitTokenInfo,
    address _tokenAddress,
    uint256 _amount
  ) internal {
    (uint32 _refreshTime, uint256 _tokenAmount) = _refreshCurrentTokenAmount(
      _dailyLimitTokenInfo.refreshTime,
      _dailyLimitTokenInfo.tokenAmount,
      _dailyLimitTokenInfo.defaultTokenAmount
    );
    _dailyLimitTokenInfo.refreshTime = _refreshTime;
    if (_amount > _tokenAmount) {
      revert DailyLimitExceeded(_tokenAmount, _amount);
    }
    _tokenAmount = _tokenAmount.sub(_amount);
    _dailyLimitTokenInfo.tokenAmount = _tokenAmount;
    emit TokenDailyLimitConsumed(_tokenAddress, _amount);
  }

  function _currentDailyLimit(
    DailyLimitTokenInfo memory _dailyLimitTokenInfo
  ) internal view returns (DailyLimitTokenInfo memory) {
    (uint32 _refreshTime, uint256 _tokenAmount) = _refreshCurrentTokenAmount(
      _dailyLimitTokenInfo.refreshTime,
      _dailyLimitTokenInfo.tokenAmount,
      _dailyLimitTokenInfo.defaultTokenAmount
    );
    _dailyLimitTokenInfo.refreshTime = _refreshTime;
    _dailyLimitTokenInfo.tokenAmount = _tokenAmount;
    return _dailyLimitTokenInfo;
  }

  function _refreshCurrentTokenAmount(
    uint256 _lastRefreshTime,
    uint256 _tokenAmount,
    uint256 _defaultAmount
  ) private view returns (uint32, uint256) {
    uint256 count = (block.timestamp.sub(_lastRefreshTime)).div(DefaultRefreshTime);
    uint32 lastRefreshTime = uint32(_lastRefreshTime);
    uint256 tokenAmount = _tokenAmount;
    if (count > 0) {
      lastRefreshTime = uint32(_lastRefreshTime.add((uint256)(DefaultRefreshTime).mul(count)));
      tokenAmount = _defaultAmount;
    }
    return (lastRefreshTime, tokenAmount);
  }
}
