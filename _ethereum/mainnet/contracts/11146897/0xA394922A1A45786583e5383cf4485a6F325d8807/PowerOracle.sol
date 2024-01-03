// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "./Initializable.sol";
import "./IERC20.sol";
import "./SafeMath.sol";
import "./SafeCast.sol";
import "./IPowerOracle.sol";
import "./IPowerOracleStaking.sol";
import "./IPowerOracleStaking.sol";
import "./UniswapTWAPProvider.sol";
import "./Pausable.sol";
import "./Ownable.sol";

contract PowerOracle is IPowerOracle, Ownable, Initializable, Pausable, UniswapTWAPProvider {
  using SafeMath for uint256;
  using SafeCast for uint256;

  uint256 public constant HUNDRED_PCT = 100 ether;

  struct Price {
    uint128 timestamp;
    uint128 value;
  }

  /// @notice The event emitted when a reporter calls a poke operation
  event PokeFromReporter(uint256 indexed reporterId, uint256 tokenCount, uint256 rewardCount);

  /// @notice The event emitted when a slasher executes poke and slashes the current reporter
  event PokeFromSlasher(uint256 indexed slasherId, uint256 tokenCount, uint256 overdueCount);

  /// @notice The event emitted when an arbitrary user calls poke operation
  event Poke(address indexed poker, uint256 tokenCount);

  /// @notice The event emitted when a reporter receives their reward for the report
  event RewardUserReport(
    uint256 indexed userId,
    uint256 count,
    uint256 deposit,
    uint256 ethPrice,
    uint256 cvpPrice,
    uint256 calculatedReward
  );

  /// @notice The event emitted when a reporter is not eligible for a reward or rewards are disabled
  event RewardIgnored(
    uint256 indexed userId,
    uint256 count,
    uint256 deposit,
    uint256 ethPrice,
    uint256 cvpPrice,
    uint256 calculatedReward
  );

  /// @notice The event emitted when a slasher receives their reward for the update
  event RewardUserSlasherUpdate(
    uint256 indexed slasherId,
    uint256 deposit,
    uint256 ethPrice,
    uint256 cvpPrice,
    uint256 calculatedReward
  );

  /// @notice The event emitted when a slasher receives their reward for the update
  event RewardUserSlasherUpdateIgnored(
    uint256 indexed slasherId,
    uint256 deposit,
    uint256 ethPrice,
    uint256 cvpPrice,
    uint256 calculatedReward
  );

  event UpdateSlasher(uint256 indexed slasherId, uint256 prevSlasherTimestamp, uint256 newSlasherTimestamp);

  /// @notice The event emitted when a reporter is missing pending tokens to update price for
  event NothingToReward(uint256 indexed userId, uint256 ethPrice);

  /// @notice The event emitted when the stored price is updated
  event PriceUpdated(string symbol, uint256 price);

  /// @notice The event emitted when the owner updates the cvpReportAPY value
  event SetCvpApy(uint256 cvpReportAPY, uint256 cvpSlasherUpdateAPY);

  /// @notice The event emitted when the owner updates min/max report intervals
  event SetReportIntervals(uint256 minReportInterval, uint256 maxReportInterval);

  /// @notice The event emitted when the owner updates the totalReportsPerYear value
  event SetTotalReportsPerYear(uint256 totalReportsPerYear, uint256 totalSlasherUpdatePerYear);

  /// @notice The event emitted when the owner updates the powerOracleStaking address
  event SetPowerOracleStaking(address powerOracleStaking);

  /// @notice The event emitted when the owner updates the gasExpensesPerAssetReport value
  event SetGasExpenses(uint256 gasExpensesPerAssetReport, uint256 gasExpensesForSlasherStatusUpdate);

  /// @notice The event emitted when the owner updates the gasPriceLimit value
  event SetGasPriceLimit(uint256 gasPriceLimit);

  /// @notice CVP token address
  IERC20 public immutable cvpToken;

  /// @notice CVP reservoir which should pre-approve some amount of tokens to this contract in order to let pay rewards
  address public immutable reservoir;

  /// @notice The linked PowerOracleStaking contract address
  IPowerOracleStaking public powerOracleStaking;

  /// @notice Min report interval in seconds
  uint256 public minReportInterval;

  /// @notice Max report interval in seconds
  uint256 public maxReportInterval;

  /// @notice The planned yield from a deposit in CVP tokens
  uint256 public cvpReportAPY;

  /// @notice The total number of reports for all pairs per year
  uint256 public totalReportsPerYear;

  /// @notice The current estimated gas expenses for reporting a single asset
  uint256 public gasExpensesPerAssetReport;

  /// @notice The maximum gas price to be used with gas compensation formula
  uint256 public gasPriceLimit;

  /// @notice The accrued reward by a user ID
  mapping(uint256 => uint256) public rewards;

  /// @notice Official prices and timestamps by symbol hash
  mapping(bytes32 => Price) public prices;

  /// @notice Last slasher update time by a user ID
  mapping(uint256 => uint256) public lastSlasherUpdates;

  /// @notice The current estimated gas expenses for updating a slasher status
  uint256 public gasExpensesForSlasherStatusUpdate;

  /// @notice The planned yield from a deposit in CVP tokens
  uint256 public cvpSlasherUpdateAPY;

  /// @notice The total number of slashers update per year
  uint256 public totalSlasherUpdatesPerYear;

  constructor(
    address cvpToken_,
    address reservoir_,
    uint256 anchorPeriod_,
    TokenConfig[] memory configs
  ) public UniswapTWAPProvider(anchorPeriod_, configs) UniswapConfig(configs) {
    cvpToken = IERC20(cvpToken_);
    reservoir = reservoir_;
  }

  function initialize(
    address owner_,
    address powerOracleStaking_,
    uint256 cvpReportAPY_,
    uint256 cvpSlasherUpdateAPY_,
    uint256 totalReportsPerYear_,
    uint256 totalSlasherUpdatesPerYear_,
    uint256 gasExpensesPerAssetReport_,
    uint256 gasExpensesForSlasherStatusUpdate_,
    uint256 gasPriceLimit_,
    uint256 minReportInterval_,
    uint256 maxReportInterval_
  ) external initializer {
    _transferOwnership(owner_);
    powerOracleStaking = IPowerOracleStaking(powerOracleStaking_);
    cvpReportAPY = cvpReportAPY_;
    cvpSlasherUpdateAPY = cvpSlasherUpdateAPY_;
    totalReportsPerYear = totalReportsPerYear_;
    totalSlasherUpdatesPerYear = totalSlasherUpdatesPerYear_;
    gasExpensesPerAssetReport = gasExpensesPerAssetReport_;
    gasExpensesForSlasherStatusUpdate = gasExpensesForSlasherStatusUpdate_;
    gasPriceLimit = gasPriceLimit_;
    minReportInterval = minReportInterval_;
    maxReportInterval = maxReportInterval_;
  }

  /*** Current Poke Interface ***/

  function _fetchEthPrice() internal returns (uint256) {
    bytes32 symbolHash = keccak256(abi.encodePacked("ETH"));
    if (getIntervalStatus(symbolHash) == ReportInterval.LESS_THAN_MIN) {
      return uint256(prices[symbolHash].value);
    }
    uint256 ethPrice = fetchEthPrice();
    _savePrice(symbolHash, ethPrice);
    return ethPrice;
  }

  function _fetchCvpPrice(uint256 ethPrice_) internal returns (uint256) {
    bytes32 symbolHash = keccak256(abi.encodePacked("CVP"));
    if (getIntervalStatus(symbolHash) == ReportInterval.LESS_THAN_MIN) {
      return uint256(prices[symbolHash].value);
    }
    uint256 cvpPrice = fetchCvpPrice(ethPrice_);
    _savePrice(symbolHash, cvpPrice);
    return cvpPrice;
  }

  function _fetchAndSavePrice(string memory symbol_, uint256 ethPrice_) internal returns (ReportInterval) {
    TokenConfig memory config = getTokenConfigBySymbol(symbol_);
    require(config.priceSource == PriceSource.REPORTER, "only reporter prices get posted");
    bytes32 symbolHash = keccak256(abi.encodePacked(symbol_));

    ReportInterval intervalStatus = getIntervalStatus(symbolHash);
    if (intervalStatus == ReportInterval.LESS_THAN_MIN) {
      return intervalStatus;
    }

    uint256 price;
    if (symbolHash == ethHash) {
      price = ethPrice_;
    } else {
      price = fetchAnchorPrice(symbol_, config, ethPrice_);
    }

    _savePrice(symbolHash, price);

    return intervalStatus;
  }

  function _savePrice(bytes32 _symbolHash, uint256 price_) internal {
    prices[_symbolHash] = Price(block.timestamp.toUint128(), price_.toUint128());
  }

  function priceInternal(TokenConfig memory config_) internal view returns (uint256) {
    if (config_.priceSource == PriceSource.REPORTER) return prices[config_.symbolHash].value;
    if (config_.priceSource == PriceSource.FIXED_USD) return config_.fixedPrice;
    if (config_.priceSource == PriceSource.FIXED_ETH) {
      uint256 usdPerEth = prices[ethHash].value;
      require(usdPerEth > 0, "ETH price not set, cannot convert to dollars");
      return mul(usdPerEth, config_.fixedPrice) / ethBaseUnit;
    }
    revert("UniswapTWAPProvider::priceInternal: Unsupported case");
  }

  function _rewardUser(
    uint256 userId_,
    uint256 count_,
    uint256 ethPrice_,
    uint256 cvpPrice_
  ) internal {
    if (count_ == 0) {
      emit NothingToReward(userId_, ethPrice_);
      return;
    }

    uint256 userDeposit = powerOracleStaking.getDepositOf(userId_);
    uint256 amount = calculateReportReward(count_, userDeposit, ethPrice_, cvpPrice_);

    if (amount > 0) {
      rewards[userId_] = rewards[userId_].add(amount);
      emit RewardUserReport(userId_, count_, userDeposit, ethPrice_, cvpPrice_, amount);
    } else {
      emit RewardIgnored(userId_, count_, userDeposit, ethPrice_, cvpPrice_, amount);
    }
  }

  function _rewardSlasherUpdate(
    uint256 userId_,
    uint256 ethPrice_,
    uint256 cvpPrice_
  ) internal {
    uint256 userDeposit = powerOracleStaking.getDepositOf(userId_);
    uint256 amount = calculateSlasherUpdateReward(userDeposit, ethPrice_, cvpPrice_);

    if (amount > 0) {
      rewards[userId_] = rewards[userId_].add(amount);
      emit RewardUserSlasherUpdate(userId_, userDeposit, ethPrice_, cvpPrice_, amount);
    } else {
      emit RewardUserSlasherUpdateIgnored(userId_, userDeposit, ethPrice_, cvpPrice_, amount);
    }
  }

  function _updateSlasherAndReward(
    uint256 _slasherId,
    uint256 _ethPrice,
    uint256 _cvpPrice
  ) internal {
    _updateSlasherTimestamp(_slasherId, true);
    _rewardSlasherUpdate(_slasherId, _ethPrice, _cvpPrice);
  }

  function _updateSlasherTimestamp(uint256 _slasherId, bool _rewardPaid) internal {
    uint256 prevSlasherUpdate = lastSlasherUpdates[_slasherId];
    uint256 delta = block.timestamp.sub(prevSlasherUpdate);
    if (_rewardPaid) {
      require(delta >= maxReportInterval, "PowerOracle::_updateSlasherAndReward: bellow maxReportInterval");
    } else {
      require(delta >= maxReportInterval.sub(minReportInterval), "PowerOracle::_updateSlasherAndReward: bellow delta interval diffs");
    }
    lastSlasherUpdates[_slasherId] = block.timestamp;
    emit UpdateSlasher(_slasherId, prevSlasherUpdate, lastSlasherUpdates[_slasherId]);
  }

  /*** Pokers ***/

  /**
   * @notice A reporter pokes symbols with incentive to be rewarded
   * @param reporterId_ The valid reporter's user ID
   * @param symbols_ Asset symbols to poke
   */
  function pokeFromReporter(uint256 reporterId_, string[] memory symbols_) external override whenNotPaused {
    uint256 len = symbols_.length;
    require(len > 0, "PowerOracle::pokeFromReporter: Missing token symbols");

    powerOracleStaking.authorizeReporter(reporterId_, msg.sender);

    uint256 ethPrice = _fetchEthPrice();
    uint256 cvpPrice = _fetchCvpPrice(ethPrice);
    uint256 rewardCount = 0;

    for (uint256 i = 0; i < len; i++) {
      if (_fetchAndSavePrice(symbols_[i], ethPrice) != ReportInterval.LESS_THAN_MIN) {
        rewardCount++;
      }
    }

    emit PokeFromReporter(reporterId_, len, rewardCount);
    _rewardUser(reporterId_, rewardCount, ethPrice, cvpPrice);
  }

  /**
   * @notice A slasher pokes symbols with incentive to be rewarded
   * @param slasherId_ The slasher's user ID
   * @param symbols_ Asset symbols to poke
   */
  function pokeFromSlasher(uint256 slasherId_, string[] memory symbols_) external override whenNotPaused {
    uint256 len = symbols_.length;
    require(len > 0, "PowerOracle::pokeFromSlasher: Missing token symbols");

    powerOracleStaking.authorizeSlasher(slasherId_, msg.sender);

    uint256 ethPrice = _fetchEthPrice();
    uint256 cvpPrice = _fetchCvpPrice(ethPrice);
    uint256 overdueCount = 0;

    for (uint256 i = 0; i < len; i++) {
      if (_fetchAndSavePrice(symbols_[i], ethPrice) == ReportInterval.GREATER_THAN_MAX) {
        overdueCount++;
      }
    }

    emit PokeFromSlasher(slasherId_, len, overdueCount);

    if (overdueCount > 0) {
      powerOracleStaking.slash(slasherId_, overdueCount);
      _rewardUser(slasherId_, overdueCount, ethPrice, cvpPrice);
      _updateSlasherTimestamp(slasherId_, false);
    } else {
      _updateSlasherAndReward(slasherId_, ethPrice, cvpPrice);
    }
  }

  function slasherUpdate(uint256 slasherId_) external override whenNotPaused {
    powerOracleStaking.authorizeSlasher(slasherId_, msg.sender);

    uint256 ethPrice = _fetchEthPrice();
    _updateSlasherAndReward(slasherId_, ethPrice, _fetchCvpPrice(ethPrice));
  }

  /**
   * @notice Arbitrary user pokes symbols without being rewarded
   * @param symbols_ Asset symbols to poke
   */
  function poke(string[] memory symbols_) external override whenNotPaused {
    uint256 len = symbols_.length;
    require(len > 0, "PowerOracle::poke: Missing token symbols");

    uint256 ethPrice = _fetchEthPrice();

    for (uint256 i = 0; i < len; i++) {
      _fetchAndSavePrice(symbols_[i], ethPrice);
    }

    emit Poke(msg.sender, len);
  }

  /**
   * @notice Withdraw the available rewards
   * @param userId_ The user ID to withdraw the reward for
   * @param to_ The address to transfer the reward to
   */
  function withdrawRewards(uint256 userId_, address to_) external override {
    powerOracleStaking.requireValidAdminKey(userId_, msg.sender);
    require(to_ != address(0), "PowerOracle::withdrawRewards: Can't withdraw to 0 address");
    uint256 rewardAmount = rewards[userId_];
    require(rewardAmount > 0, "PowerOracle::withdrawRewards: Nothing to withdraw");
    rewards[userId_] = 0;

    cvpToken.transferFrom(reservoir, to_, rewardAmount);
  }

  /*** Owner Interface ***/

  /**
   * @notice Set the planned yield from a deposit in CVP tokens
   * @param cvpReportAPY_ The planned yield in % (1 ether == 1%)
   * @param cvpSlasherUpdateAPY_ The planned yield in % (1 ether == 1%)
   */
  function setCvpAPY(uint256 cvpReportAPY_, uint256 cvpSlasherUpdateAPY_) external override onlyOwner {
    cvpReportAPY = cvpReportAPY_;
    cvpSlasherUpdateAPY = cvpSlasherUpdateAPY_;
    emit SetCvpApy(cvpReportAPY_, cvpSlasherUpdateAPY_);
  }

  /**
   * @notice Set the total number of reports for all pairs per year
   * @param totalReportsPerYear_ The total number of reports
   * @param totalSlasherUpdatesPerYear_ The total number of slasher updates
   */
  function setTotalPerYear(uint256 totalReportsPerYear_, uint256 totalSlasherUpdatesPerYear_)
    external
    override
    onlyOwner
  {
    totalReportsPerYear = totalReportsPerYear_;
    totalSlasherUpdatesPerYear = totalSlasherUpdatesPerYear_;
    emit SetTotalReportsPerYear(totalReportsPerYear_, totalSlasherUpdatesPerYear_);
  }

  /**
   * @notice Set the current estimated gas expenses
   * @param gasExpensesPerAssetReport_ The gas amount for reporting a single asset
   * @param gasExpensesForSlasherStatusUpdate_ The gas amount for updating slasher status
   */
  function setGasExpenses(uint256 gasExpensesPerAssetReport_, uint256 gasExpensesForSlasherStatusUpdate_)
    external
    override
    onlyOwner
  {
    gasExpensesPerAssetReport = gasExpensesPerAssetReport_;
    gasExpensesForSlasherStatusUpdate = gasExpensesForSlasherStatusUpdate_;
    emit SetGasExpenses(gasExpensesPerAssetReport_, gasExpensesForSlasherStatusUpdate_);
  }

  /**
   * @notice Set the current estimated gas expenses for reporting a single asset
   * @param gasPriceLimit_ The gas amount
   */
  function setGasPriceLimit(uint256 gasPriceLimit_) external override onlyOwner {
    gasPriceLimit = gasPriceLimit_;
    emit SetGasPriceLimit(gasPriceLimit_);
  }

  /**
   * @notice The owner sets the current report min/max in seconds
   * @param minReportInterval_ The minimum report interval for the reporter
   * @param maxReportInterval_ The maximum report interval for the reporter
   */
  function setReportIntervals(uint256 minReportInterval_, uint256 maxReportInterval_) external override onlyOwner {
    minReportInterval = minReportInterval_;
    maxReportInterval = maxReportInterval_;
    emit SetReportIntervals(minReportInterval_, maxReportInterval_);
  }

  /**
   * @notice The owner sets a new powerOracleStaking contract
   * @param powerOracleStaking_ The poserOracleStaking contract address
   */
  function setPowerOracleStaking(address powerOracleStaking_) external override onlyOwner {
    powerOracleStaking = IPowerOracleStaking(powerOracleStaking_);
    emit SetPowerOracleStaking(powerOracleStaking_);
  }

  /**
   * @notice The owner pauses poke*-operations
   */
  function pause() external override onlyOwner {
    _pause();
  }

  /**
   * @notice The owner unpauses poke*-operations
   */
  function unpause() external override onlyOwner {
    _unpause();
  }

  /*** Viewers ***/

  function calculateReportReward(
    uint256 count_,
    uint256 deposit_,
    uint256 ethPrice_,
    uint256 cvpPrice_
  ) public view returns (uint256) {
    if (count_ == 0) {
      return 0;
    }

    return
      count_.mul(
        calculateReporterFixedReward(deposit_).add(
          calculateGasCompensation(ethPrice_, cvpPrice_, gasExpensesPerAssetReport)
        )
      );
  }

  function calculateReporterFixedReward(uint256 deposit_) public view returns (uint256) {
    require(cvpReportAPY > 0, "PowerOracle: cvpReportAPY is 0");
    require(totalReportsPerYear > 0, "PowerOracle: totalReportsPerYear is 0");
    // return cvpReportAPY * deposit_ / totalReportsPerYear / HUNDRED_PCT;
    return cvpReportAPY.mul(deposit_) / totalReportsPerYear / HUNDRED_PCT;
  }

  function calculateGasCompensation(
    uint256 ethPrice_,
    uint256 cvpPrice_,
    uint256 gasExpenses_
  ) public view returns (uint256) {
    require(ethPrice_ > 0, "PowerOracle::calculateGasCompensation: ETH price is 0");
    require(cvpPrice_ > 0, "PowerOracle::calculateGasCompensation: CVP price is 0");
    require(gasExpenses_ > 0, "PowerOracle::calculateGasCompensation: Gas expenses is 0");

    // return _min(tx.gasprice, gasPriceLimit) * gasExpensesPerAssetReport * ethPrice_ / cvpPrice_;
    return _min(tx.gasprice, gasPriceLimit).mul(gasExpenses_).mul(ethPrice_) / cvpPrice_;
  }

  function calculateSlasherUpdateReward(
    uint256 deposit_,
    uint256 ethPrice_,
    uint256 cvpPrice_
  ) public view returns (uint256) {
    return
      calculateSlasherFixedReward(deposit_).add(
        calculateGasCompensation(ethPrice_, cvpPrice_, gasExpensesForSlasherStatusUpdate)
      );
  }

  function calculateSlasherFixedReward(uint256 deposit_) public view returns (uint256) {
    require(cvpSlasherUpdateAPY > 0, "PowerOracle: cvpSlasherUpdateAPY is 0");
    require(totalSlasherUpdatesPerYear > 0, "PowerOracle: totalSlasherUpdatesPerYear is 0");
    return cvpSlasherUpdateAPY.mul(deposit_) / totalSlasherUpdatesPerYear / HUNDRED_PCT;
  }

  function getIntervalStatus(bytes32 _symbolHash) public view returns (ReportInterval) {
    uint256 delta = block.timestamp.sub(prices[_symbolHash].timestamp);

    if (delta < minReportInterval) {
      return ReportInterval.LESS_THAN_MIN;
    }

    if (delta < maxReportInterval) {
      return ReportInterval.OK;
    }

    return ReportInterval.GREATER_THAN_MAX;
  }

  /**
   * @notice Get the underlying price of a token
   * @param token_ The token address for price retrieval
   * @return Price denominated in USD, with 6 decimals, for the given asset address
   */
  function getPriceByAsset(address token_) external view override returns (uint256) {
    TokenConfig memory config = getTokenConfigByUnderlying(token_);
    return priceInternal(config);
  }

  /**
   * @notice Get the official price for a symbol, like "COMP"
   * @param symbol_ The symbol for price retrieval
   * @return Price denominated in USD, with 6 decimals
   */
  function getPriceBySymbol(string calldata symbol_) external view override returns (uint256) {
    TokenConfig memory config = getTokenConfigBySymbol(symbol_);
    return priceInternal(config);
  }

  /**
   * @notice Get price by a token symbol hash,
   *    like "0xd6aca1be9729c13d677335161321649cccae6a591554772516700f986f942eaa" for USDC
   * @param symbolHash_ The symbol hash for price retrieval
   * @return Price denominated in USD, with 6 decimals, for the given asset address
   */
  function getPriceBySymbolHash(bytes32 symbolHash_) external view override returns (uint256) {
    TokenConfig memory config = getTokenConfigBySymbolHash(symbolHash_);
    return priceInternal(config);
  }

  /**
   * @notice Get the underlying price of a cToken
   * @dev Implements the PriceOracle interface for Compound v2.
   * @param cToken_ The cToken address for price retrieval
   * @return Price denominated in USD, with 18 decimals, for the given cToken address
   */
  function getUnderlyingPrice(address cToken_) external view override returns (uint256) {
    TokenConfig memory config = getTokenConfigByCToken(cToken_);
    // Comptroller needs prices in the format: ${raw price} * 1e(36 - baseUnit)
    // Since the prices in this view have 6 decimals, we must scale them by 1e(36 - 6 - baseUnit)
    return mul(1e30, priceInternal(config)) / config.baseUnit;
  }

  /**
   * @notice Get the price by underlying address
   * @dev Implements the old PriceOracle interface for Compound v2.
   * @param token_ The underlying address for price retrieval
   * @return Price denominated in USD, with 18 decimals, for the given underlying address
   */
  function assetPrices(address token_) external view override returns (uint256) {
    TokenConfig memory config = getTokenConfigByUnderlying(token_);
    // Return price in the same format as getUnderlyingPrice, but by token address
    return mul(1e30, priceInternal(config)) / config.baseUnit;
  }

  function _min(uint256 a, uint256 b) internal pure returns (uint256) {
    return a < b ? a : b;
  }
}
