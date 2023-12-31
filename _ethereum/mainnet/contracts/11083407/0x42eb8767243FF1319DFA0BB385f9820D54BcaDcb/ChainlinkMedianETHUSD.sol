pragma solidity ^0.6.7;

interface AggregatorInterface {
  event AnswerUpdated(int256 indexed current, uint256 indexed roundId, uint256 timestamp);
  event NewRound(uint256 indexed roundId, address indexed startedBy, uint256 startedAt);

  function latestAnswer() external returns (int256);
  function latestTimestamp() external returns (uint256);
  function latestRound() external returns (uint256);
  function getAnswer(uint256 roundId) external returns (int256);
  function getTimestamp(uint256 roundId) external returns (uint256);

  // post-Historic

  function decimals() external returns (uint8);
  function getRoundData(uint256 _roundId)
    external
    returns (
      uint256 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint256 answeredInRound
    );
  function latestRoundData()
    external
    returns (
      uint256 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint256 answeredInRound
    );
}

abstract contract StabilityFeeTreasuryLike {
    function getAllowance(address) virtual external view returns (uint, uint);
    function systemCoin() virtual external view returns (address);
    function pullFunds(address, address, uint) virtual external;
}

contract ChainlinkPriceFeedMedianizer {
    // --- Auth ---
    mapping (address => uint) public authorizedAccounts;
    /**
     * @notice Add auth to an account
     * @param account Account to add auth to
     */
    function addAuthorization(address account) external isAuthorized {
        authorizedAccounts[account] = 1;
        emit AddAuthorization(account);
    }
    /**
     * @notice Remove auth from an account
     * @param account Account to remove auth from
     */
    function removeAuthorization(address account) external isAuthorized {
        authorizedAccounts[account] = 0;
        emit RemoveAuthorization(account);
    }
    /**
    * @notice Checks whether msg.sender can call an authed function
    **/
    modifier isAuthorized {
        require(authorizedAccounts[msg.sender] == 1, "ChainlinkPriceFeedMedianizer/account-not-authorized");
        _;
    }

    AggregatorInterface public chainlinkAggregator;

    // Delay between updates after which the reward starts to increase
    uint256 public periodSize;
    // Starting reward for the feeReceiver
    uint256 public baseUpdateCallerReward;          // [wad]
    // Max possible reward for the feeReceiver
    uint256 public maxUpdateCallerReward;           // [wad]
    // Max delay taken into consideration when calculating the adjusted reward
    uint256 public maxRewardIncreaseDelay;
    // Rate applied to baseUpdateCallerReward every extra second passed beyond periodSize seconds since the last update call
    uint256 public perSecondCallerRewardIncrease;   // [ray]
    // Latest median price
    uint256 private medianPrice;                    // [wad]
    // Timestamp of the Chainlink aggregator
    uint256 public linkAggregatorTimestamp;
    // Last timestamp when the median was updated
    uint256 public  lastUpdateTime;                 // [unix timestamp]
    // Multiplier for the Chainlink price feed in order to scaled it to 18 decimals. Default to 10 for USD price feeds
    uint8   public  multiplier = 10;

    // You want to change these every deployment
    uint256 public staleThreshold = 3;
    bytes32 public symbol         = "ethusd";

    // SF treasury contract
    StabilityFeeTreasuryLike public treasury;

    // --- Events ---
    event ModifyParameters(bytes32 parameter, address addr);
    event ModifyParameters(bytes32 parameter, uint256 data);
    event UpdateResult(uint256 medianPrice, uint256 lastUpdateTime);
    event RewardCaller(address feeReceiver, uint256 amount);
    event FailRewardCaller(bytes revertReason, address finalFeeReceiver, uint256 reward);
    event AddAuthorization(address account);
    event RemoveAuthorization(address account);

    constructor(
      address aggregator,
      address treasury_,
      uint256 periodSize_,
      uint256 baseUpdateCallerReward_,
      uint256 maxUpdateCallerReward_,
      uint256 perSecondCallerRewardIncrease_
    ) public {
        require(aggregator != address(0), "ChainlinkPriceFeedMedianizer/null-aggregator");
        require(multiplier >= 1, "ChainlinkPriceFeedMedianizer/null-multiplier");
        require(maxUpdateCallerReward_ > baseUpdateCallerReward_, "ChainlinkPriceFeedMedianizer/invalid-max-reward");
        require(perSecondCallerRewardIncrease_ >= RAY, "ChainlinkPriceFeedMedianizer/invalid-reward-increase");
        require(periodSize_ > 0, "ChainlinkPriceFeedMedianizer/null-period-size");
        authorizedAccounts[msg.sender] = 1;
        treasury                       = StabilityFeeTreasuryLike(treasury_);
        baseUpdateCallerReward         = baseUpdateCallerReward_;
        maxUpdateCallerReward          = maxUpdateCallerReward_;
        perSecondCallerRewardIncrease  = perSecondCallerRewardIncrease_;
        periodSize                     = periodSize_;
        chainlinkAggregator            = AggregatorInterface(aggregator);
        maxRewardIncreaseDelay         = uint(-1);
        emit AddAuthorization(msg.sender);
        emit ModifyParameters(bytes32("treasury"), treasury_);
        emit ModifyParameters(bytes32("maxRewardIncreaseDelay"), uint(-1));
        emit ModifyParameters(bytes32("periodSize"), periodSize);
        emit ModifyParameters(bytes32("aggregator"), aggregator);
        emit ModifyParameters(bytes32("baseUpdateCallerReward"), baseUpdateCallerReward);
        emit ModifyParameters(bytes32("maxUpdateCallerReward"), maxUpdateCallerReward);
        emit ModifyParameters(bytes32("perSecondCallerRewardIncrease"), perSecondCallerRewardIncrease);
    }

    // --- General Utils ---
    function either(bool x, bool y) internal pure returns (bool z) {
        assembly{ z := or(x, y)}
    }
    function both(bool x, bool y) internal pure returns (bool z) {
        assembly{ z := and(x, y)}
    }

    // --- Math ---
    uint256 internal constant WAD = 10 ** 18;
    uint256 internal constant RAY = 10 ** 27;
    function minimum(uint x, uint y) internal pure returns (uint z) {
        z = (x <= y) ? x : y;
    }
    function subtract(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x);
    }
    function multiply(uint x, int y) internal pure returns (int z) {
        z = int(x) * y;
        require(int(x) >= 0);
        require(y == 0 || z / y == int(x));
    }
    function multiply(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x);
    }
    function wmultiply(uint x, uint y) internal pure returns (uint z) {
        z = multiply(x, y) / WAD;
    }
    function rmultiply(uint x, uint y) internal pure returns (uint z) {
        z = multiply(x, y) / RAY;
    }
    function rpower(uint x, uint n, uint base) internal pure returns (uint z) {
        assembly {
            switch x case 0 {switch n case 0 {z := base} default {z := 0}}
            default {
                switch mod(n, 2) case 0 { z := base } default { z := x }
                let half := div(base, 2)  // for rounding.
                for { n := div(n, 2) } n { n := div(n,2) } {
                    let xx := mul(x, x)
                    if iszero(eq(div(xx, x), x)) { revert(0,0) }
                    let xxRound := add(xx, half)
                    if lt(xxRound, xx) { revert(0,0) }
                    x := div(xxRound, base)
                    if mod(n,2) {
                        let zx := mul(z, x)
                        if and(iszero(iszero(x)), iszero(eq(div(zx, x), z))) { revert(0,0) }
                        let zxRound := add(zx, half)
                        if lt(zxRound, zx) { revert(0,0) }
                        z := div(zxRound, base)
                    }
                }
            }
        }
    }

    // --- Administration ---
    function modifyParameters(bytes32 parameter, uint256 data) external isAuthorized {
        if (parameter == "baseUpdateCallerReward") baseUpdateCallerReward = data;
        else if (parameter == "maxUpdateCallerReward") {
          require(data > baseUpdateCallerReward, "ChainlinkPriceFeedMedianizer/invalid-max-reward");
          maxUpdateCallerReward = data;
        }
        else if (parameter == "perSecondCallerRewardIncrease") {
          require(data >= RAY, "ChainlinkPriceFeedMedianizer/invalid-reward-increase");
          perSecondCallerRewardIncrease = data;
        }
        else if (parameter == "maxRewardIncreaseDelay") {
          require(data > 0, "ChainlinkPriceFeedMedianizer/invalid-max-increase-delay");
          maxRewardIncreaseDelay = data;
        }
        else if (parameter == "periodSize") {
          require(data > 0, "ChainlinkPriceFeedMedianizer/null-period-size");
          periodSize = data;
        }
        else if (parameter == "staleThreshold") {
          require(data > 1, "ChainlinkPriceFeedMedianizer/invalid-stale-threshold");
          staleThreshold = data;
        }
        else revert("ChainlinkPriceFeedMedianizer/modify-unrecognized-param");
        emit ModifyParameters(parameter, data);
    }
    function modifyParameters(bytes32 parameter, address addr) external isAuthorized {
        if (parameter == "aggregator") chainlinkAggregator = AggregatorInterface(addr);
        else if (parameter == "treasury") {
          require(StabilityFeeTreasuryLike(addr).systemCoin() != address(0), "ChainlinkPriceFeedMedianizer/treasury-coin-not-set");
      	  treasury = StabilityFeeTreasuryLike(addr);
        }
        else revert("ChainlinkPriceFeedMedianizer/modify-unrecognized-param");
        emit ModifyParameters(parameter, addr);
    }

    function read() external view returns (uint256) {
        require(both(medianPrice > 0, subtract(now, linkAggregatorTimestamp) <= multiply(periodSize, staleThreshold)), "ChainlinkPriceFeedMedianizer/invalid-price-feed");
        return medianPrice;
    }

    function getResultWithValidity() external view returns (uint256,bool) {
        return (medianPrice, both(medianPrice > 0, subtract(now, linkAggregatorTimestamp) <= multiply(periodSize, staleThreshold)));
    }

    // --- Treasury Utils ---
    function treasuryAllowance() public view returns (uint256) {
        (uint total, uint perBlock) = treasury.getAllowance(address(this));
        return minimum(total, perBlock);
    }
    function getCallerReward() public view returns (uint256) {
        if (lastUpdateTime == 0) return baseUpdateCallerReward;
        uint256 timeElapsed = subtract(now, lastUpdateTime);
        if (timeElapsed < periodSize) {
            return 0;
        }
        uint256 baseReward   = baseUpdateCallerReward;
        uint256 adjustedTime = subtract(timeElapsed, periodSize);
        if (adjustedTime > 0) {
            adjustedTime = (adjustedTime > maxRewardIncreaseDelay) ? maxRewardIncreaseDelay : adjustedTime;
            baseReward = rmultiply(rpower(perSecondCallerRewardIncrease, adjustedTime, RAY), baseReward);
        }
        uint256 maxReward = minimum(maxUpdateCallerReward, treasuryAllowance() / RAY);
        if (baseReward > maxReward) {
            baseReward = maxReward;
        }
        return baseReward;
    }
    function rewardCaller(address proposedFeeReceiver, uint256 reward) internal {
        if (address(treasury) == proposedFeeReceiver) return;
        if (either(address(treasury) == address(0), reward == 0)) return;
        address finalFeeReceiver = (proposedFeeReceiver == address(0)) ? msg.sender : proposedFeeReceiver;
        try treasury.pullFunds(finalFeeReceiver, treasury.systemCoin(), reward) {
            emit RewardCaller(finalFeeReceiver, reward);
        }
        catch(bytes memory revertReason) {
            emit FailRewardCaller(revertReason, finalFeeReceiver, reward);
        }
    }

    // --- Median Updates ---
    function updateResult(address feeReceiver) external {
        int256 aggregatorPrice = chainlinkAggregator.latestAnswer();
        uint256 aggregatorTimestamp = chainlinkAggregator.latestTimestamp();
        require(aggregatorPrice > 0, "ChainlinkPriceFeedMedianizer/invalid-price-feed");
        require(aggregatorTimestamp > 0 && aggregatorTimestamp > linkAggregatorTimestamp, "ChainlinkPriceFeedMedianizer/invalid-timestamp");
        uint256 callerReward    = getCallerReward();
        medianPrice             = multiply(uint(aggregatorPrice), 10 ** uint(multiplier));
        linkAggregatorTimestamp = aggregatorTimestamp;
        lastUpdateTime          = now;
        emit UpdateResult(medianPrice, lastUpdateTime);
        rewardCaller(feeReceiver, callerReward);
    }
}

contract ChainlinkMedianETHUSD is ChainlinkPriceFeedMedianizer {
  constructor(
    address aggregator,
    uint256 periodSize,
    uint256 baseUpdateCallerReward,
    uint256 maxUpdateCallerReward,
    uint256 perSecondCallerRewardIncrease
  ) ChainlinkPriceFeedMedianizer(aggregator, address(0), periodSize, baseUpdateCallerReward, maxUpdateCallerReward, perSecondCallerRewardIncrease) public {
        symbol = "ETHUSD";
        multiplier = 10;
        staleThreshold = 6;
    }
}