pragma solidity 0.8.9;
import "./SafeMath.sol";

library RateLimiter {
  using SafeMath for uint256;

  error BucketOverfilled();
  error TokenRateLimitReached(uint256 minWaitInSeconds, uint256 available, address tokenAddress);
  error MaxCapacityExceeded(uint256 capacity, uint256 amount);
  event TokensConsumed(address tokenAddress, uint256 amount);
  event ConfigChanged(TokenBucketConfig config);

  struct TokenBucket {
    uint128 currentTokenAmount;
    uint32 lastUpdatedTime;
    bool isEnabled;
    uint128 tokenCapacity;
    uint128 rate;
  }

  struct TokenBucketConfig {
    bytes32 bucketId; //tokenKey/swapId
    bool isEnabled;
    uint128 tokenCapacity;
    uint128 rate;
  }

  function _consume(
    TokenBucket storage _tokenBucket,
    address _tokenAddress,
    uint256 _amount
  ) internal {
    if (!_tokenBucket.isEnabled) {
      return;
    }
    uint256 currentTokenAmount = _tokenBucket.currentTokenAmount;
    uint256 capacity = _tokenBucket.tokenCapacity;
    uint256 timeDiff = block.timestamp.sub(_tokenBucket.lastUpdatedTime);
    if (timeDiff != 0) {
      if (currentTokenAmount > capacity) revert BucketOverfilled();
      currentTokenAmount = _calculateTokenRefill(
        capacity,
        currentTokenAmount,
        _tokenBucket.rate,
        timeDiff
      );
      _tokenBucket.lastUpdatedTime = uint32(block.timestamp);
    }
    if (capacity < _amount) {
      revert MaxCapacityExceeded(capacity, _amount);
    }
    if (currentTokenAmount < _amount) {
      uint256 rate = _tokenBucket.rate;
      uint256 minWaitInSeconds = ((_amount.sub(currentTokenAmount)).add(rate.sub(1))).div(rate);
      revert TokenRateLimitReached(minWaitInSeconds, _amount, _tokenAddress);
    }
    currentTokenAmount = currentTokenAmount.sub(_amount);

    _tokenBucket.currentTokenAmount = uint128(currentTokenAmount);
    emit TokensConsumed(_tokenAddress, _amount);
  }

  function _configTokenBucket(
    TokenBucket storage _tokenBucket,
    TokenBucketConfig memory _config
  ) internal {
    if (_tokenBucket.lastUpdatedTime != 0) {
      uint256 timeDiff = block.timestamp.sub(_tokenBucket.lastUpdatedTime);
      if (timeDiff != 0) {
        _tokenBucket.currentTokenAmount = uint128(
          _calculateTokenRefill(
            _tokenBucket.tokenCapacity,
            _tokenBucket.currentTokenAmount,
            _tokenBucket.rate,
            timeDiff
          )
        );
        _tokenBucket.lastUpdatedTime = uint32(block.timestamp);
      }
      _tokenBucket.currentTokenAmount = uint128(
        _min(_config.tokenCapacity, _tokenBucket.currentTokenAmount)
      );
    } else {
      _tokenBucket.currentTokenAmount = _config.tokenCapacity;
      _tokenBucket.lastUpdatedTime = uint32(block.timestamp);
    }
    _tokenBucket.tokenCapacity = _config.tokenCapacity;
    _tokenBucket.isEnabled = _config.isEnabled;
    _tokenBucket.rate = _config.rate;
    emit ConfigChanged(_config);
  }

  function _currentTokenBucketState(
    TokenBucket memory _tokenBucket
  ) internal view returns (TokenBucket memory) {
    _tokenBucket.currentTokenAmount = uint128(
      _calculateTokenRefill(
        _tokenBucket.tokenCapacity,
        _tokenBucket.currentTokenAmount,
        _tokenBucket.rate,
        block.timestamp.sub(_tokenBucket.lastUpdatedTime)
      )
    );
    _tokenBucket.lastUpdatedTime = uint32(block.timestamp);
    return _tokenBucket;
  }

  function _calculateTokenRefill(
    uint256 capacity,
    uint256 currentTokenAmount,
    uint256 rate,
    uint256 timeDiff
  ) private pure returns (uint256) {
    return _min(capacity, currentTokenAmount.add(timeDiff.mul(rate)));
  }

  function _min(uint256 a, uint256 b) internal pure returns (uint256) {
    return a < b ? a : b;
  }
}
