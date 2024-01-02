pragma solidity 0.8.9;

import "./RateLimiter.sol";
import "./DailyLimiter.sol";

interface ILimiter {
  function consumeDailyLimit(bytes32 dailyLimitId, address tokenAddress, uint256 amount) external;

  function consumeTokenBucket(bytes32 bucketId, address tokenAddress, uint256 amount) external;

}
