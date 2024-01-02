pragma solidity 0.8.9;

import "./RateLimiter.sol";
import "./DailyLimiter.sol";
import "./BridgeInLibrary.sol";
import "./Proxy.sol";
import "./SafeMath.sol";
import "./BridgeOutInterface.sol";

contract LimiterImplementation is ProxyStorage {
  using DailyLimiter for DailyLimiter.DailyLimitTokenInfo;
  using RateLimiter for RateLimiter.TokenBucket;
  using SafeMath for uint256;

  // key: tokenKey / swapId
  mapping(bytes32 => RateLimiter.TokenBucket) private tokenBucket;
  mapping(bytes32 => DailyLimiter.DailyLimitTokenInfo) private dailyLimit;
  address public admin;
  address public bridgeIn;
  address public bridgeOut;

  modifier onlyAdmin() {
    require(msg.sender == admin, 'no permission');
    _;
  }
  modifier onlyBridge() {
    require(msg.sender == bridgeIn || msg.sender == bridgeOut, 'no permission');
    _;
  }

  function changeAdmin(address _admin) external onlyAdmin{
    require(_admin != address(0), "invalid input");
    admin = _admin;
  }

  function initialize(address _bridgeIn, address _bridgeOut, address _admin) external onlyOwner {
    require(bridgeIn == address(0), 'already initialized');
    bridgeIn = _bridgeIn;
    bridgeOut = _bridgeOut;
    admin = _admin;
  }

  function consumeDailyLimit(
    bytes32 dailyLimitId,
    address tokenAddress,
    uint256 amount
  ) external onlyBridge {
    dailyLimit[dailyLimitId]._consume(tokenAddress, amount);
  }

  function consumeTokenBucket(
    bytes32 bucketId,
    address tokenAddress,
    uint256 amount
  ) external onlyBridge {
    tokenBucket[bucketId]._consume(tokenAddress, amount);
  }

  function setDailyLimit(
    DailyLimiter.DailyLimitConfig[] memory dailyLimitConfigs
  ) external onlyAdmin {
    for (uint i = 0; i < dailyLimitConfigs.length; i++) {
      DailyLimiter.DailyLimitConfig memory dailyLimitConfig = dailyLimitConfigs[i];
      dailyLimit[dailyLimitConfig.dailyLimitId]._setDailyLimit(dailyLimitConfig);
    }
  }

  function getReceiptDailyLimit(
    address token,
    string memory targetChainId
  ) public view returns (DailyLimiter.DailyLimitTokenInfo memory) {
    bytes32 dailyLimitId = BridgeInLibrary._generateTokenKey(token, targetChainId);
    return dailyLimit[dailyLimitId]._currentDailyLimit();
  }

  function getSwapDailyLimit(
    bytes32 swapId
  ) public view returns (DailyLimiter.DailyLimitTokenInfo memory) {
        return dailyLimit[swapId]._currentDailyLimit();
  }

  function setTokenBucketConfig(RateLimiter.TokenBucketConfig[] memory configs) external onlyAdmin {
    for (uint i = 0; i < configs.length; i++) {
      RateLimiter.TokenBucketConfig memory config = configs[i];
      tokenBucket[config.bucketId]._configTokenBucket(configs[i]);
    }
  }

  function getCurrentReceiptTokenBucketState(
    address token,
    string memory targetChainId
  ) public view returns (RateLimiter.TokenBucket memory) {
    bytes32 bucketId = BridgeInLibrary._generateTokenKey(token, targetChainId);
    return tokenBucket[bucketId]._currentTokenBucketState();
  }

  function getCurrentReceiptTokenBucketStates(
    address[] memory tokens,
    string[] memory targetChainIds
  ) public view returns (RateLimiter.TokenBucket[] memory _tokenBuckets) {
    _tokenBuckets = new RateLimiter.TokenBucket[](tokens.length);
    for (uint i = 0; i < tokens.length; i++) {
      bytes32 bucketId = BridgeInLibrary._generateTokenKey(tokens[i], targetChainIds[i]);
      _tokenBuckets[i] = tokenBucket[bucketId]._currentTokenBucketState();
    }
    return _tokenBuckets;
  }

  function getCurrentSwapTokenBucketState(
    address token,
    string memory fromChainId
  ) public view returns (RateLimiter.TokenBucket memory) {
    bytes32 swapId = IBridgeOut(bridgeOut).getSwapId(token, fromChainId);
    return tokenBucket[swapId]._currentTokenBucketState();
  }

    function getCurrentSwapTokenBucketStates(
    address[] memory tokens,
    string[] memory fromChainIds
  ) public view returns (RateLimiter.TokenBucket[] memory _tokenBuckets) {
    _tokenBuckets = new RateLimiter.TokenBucket[](tokens.length);
    for (uint i = 0; i < tokens.length; i++) {
      bytes32 swapId = IBridgeOut(bridgeOut).getSwapId(tokens[i], fromChainIds[i]);
      _tokenBuckets[i] = tokenBucket[swapId]._currentTokenBucketState();
    }
    return _tokenBuckets;
  }

  function getReceiptBucketMinWaitSeconds(
    uint256 amount,
    address token,
    string memory targetChainId
  ) public view returns (uint256) {
    bytes32 bucketId = BridgeInLibrary._generateTokenKey(token, targetChainId);
    return getMinWaitSeconds(bucketId,amount);
  }

  function getSwapBucketMinWaitSeconds(
    uint256 amount,
    address token,
    string memory fromChainId
  ) public view returns (uint256) {
    bytes32 swapId = IBridgeOut(bridgeOut).getSwapId(token, fromChainId);
    return getMinWaitSeconds(swapId,amount);
  }

  function getMinWaitSeconds(bytes32 bucketId,uint256 amount) private view returns (uint256) {
     RateLimiter.TokenBucket memory bucket = tokenBucket[bucketId]._currentTokenBucketState();
    if (amount > bucket.currentTokenAmount) {
      return
        ((amount.sub(bucket.currentTokenAmount)).add(((uint256)(bucket.rate).sub(1)))).div(
          bucket.rate
        );
    } else {
      return 0;
    }
  }
}
