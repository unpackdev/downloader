/*
https://powerpool.finance/
          wrrrw r wrr
         ppwr rrr wppr0       prwwwrp                                 prwwwrp                   wr0
        rr 0rrrwrrprpwp0      pp   pr  prrrr0 pp   0r  prrrr0  0rwrrr pp   pr  prrrr0  prrrr0    r0
        rrp pr   wr00rrp      prwww0  pp   wr pp w00r prwwwpr  0rw    prwww0  pp   wr pp   wr    r0
        r0rprprwrrrp pr0      pp      wr   pr pp rwwr wr       0r     pp      wr   pr wr   pr    r0
         prwr wrr0wpwr        00        www0   0w0ww    www0   0w     00        www0    www0   0www0
          wrr ww0rrrr
*/
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
  event RewardUser(
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

  /// @notice The event emitted when a reporter is missing pending tokens to update price for
  event NothingToReward(uint256 indexed userId, uint256 ethPrice);

  /// @notice The event emitted when the stored price is updated
  event PriceUpdated(string symbol, uint256 price);

  /// @notice The event emitted when the owner updates the cvpAPY value
  event SetCvpApy(uint256 cvpAPY);

  /// @notice The event emitted when the owner updates min/max report intervals
  event SetReportIntervals(uint256 minReportInterval, uint256 maxReportInterval);

  /// @notice The event emitted when the owner updates the totalReportsPerYear value
  event SetTotalReportsPerYear(uint256 totalReportsPerYear);

  /// @notice The event emitted when the owner updates the powerOracleStaking address
  event SetPowerOracleStaking(address powerOracleStaking);

  /// @notice The event emitted when the owner updates the gasExpensesPerAssetReport value
  event SetGasExpensesPerAssetReport(uint256 gasExpensesPerAssetReport);

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
  uint256 public cvpAPY;

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
    uint256 cvpAPY_,
    uint256 totalReportsPerYear_,
    uint256 gasExpensesPerAssetReport_,
    uint256 gasPriceLimit_,
    uint256 minReportInterval_,
    uint256 maxReportInterval_
  ) external initializer {
    _transferOwnership(owner_);
    powerOracleStaking = IPowerOracleStaking(powerOracleStaking_);
    cvpAPY = cvpAPY_;
    totalReportsPerYear = totalReportsPerYear_;
    gasExpensesPerAssetReport = gasExpensesPerAssetReport_;
    gasPriceLimit = gasPriceLimit_;
    minReportInterval = minReportInterval_;
    maxReportInterval = maxReportInterval_;
  }

  /*** Current Poke Interface ***/

  function _updateEthPrice() internal returns (uint256) {
    uint256 ethPrice = fetchEthPrice();
    _savePrice("ETH", ethPrice);
    return ethPrice;
  }

  function _updateCvpPrice(uint256 ethPrice_) internal returns (uint256) {
    uint256 cvpPrice = fetchCvpPrice(ethPrice_);
    _savePrice("CVP", cvpPrice);
    return cvpPrice;
  }

  function _fetchAndSavePrice(string memory symbol_, uint256 ethPrice_) internal returns (ReportInterval) {
    TokenConfig memory config = getTokenConfigBySymbol(symbol_);
    require(config.priceSource == PriceSource.REPORTER, "only reporter prices get posted");

    uint256 price;
    if (keccak256(abi.encodePacked(symbol_)) == ethHash) {
      price = ethPrice_;
    } else {
      price = fetchAnchorPrice(symbol_, config, ethPrice_);
    }

    return _savePrice(symbol_, price);
  }

  function _savePrice(string memory symbol_, uint256 price_) internal returns (ReportInterval) {
    bytes32 symbolHash = keccak256(abi.encodePacked(symbol_));

    uint256 delta = block.timestamp - prices[symbolHash].timestamp;
    prices[keccak256(abi.encodePacked(symbol_))] = Price(block.timestamp.toUint128(), price_.toUint128());

    if (delta < minReportInterval) {
      return ReportInterval.LESS_THAN_MIN;
    }

    if (delta < maxReportInterval) {
      return ReportInterval.OK;
    }

    return ReportInterval.GREATER_THAN_MAX;
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
    uint256 amount = calculateReward(count_, powerOracleStaking.getDepositOf(userId_), ethPrice_, cvpPrice_);

    if (amount > 0) {
      rewards[userId_] = rewards[userId_].add(amount);
      emit RewardUser(userId_, count_, userDeposit, ethPrice_, cvpPrice_, amount);
    } else {
      emit RewardIgnored(userId_, count_, userDeposit, ethPrice_, cvpPrice_, amount);
    }
  }

  function _min(uint256 a, uint256 b) internal pure returns (uint256) {
    return a < b ? a : b;
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

    uint256 ethPrice = _updateEthPrice();
    uint256 cvpPrice = _updateCvpPrice(ethPrice);
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

    uint256 ethPrice = _updateEthPrice();
    uint256 overdueCount = 0;

    for (uint256 i = 0; i < len; i++) {
      if (_fetchAndSavePrice(symbols_[i], ethPrice) == ReportInterval.GREATER_THAN_MAX) {
        overdueCount++;
      }
    }

    emit PokeFromSlasher(slasherId_, len, overdueCount);
    if (overdueCount > 0) {
      powerOracleStaking.slash(slasherId_, overdueCount);
    }
  }

  /**
   * @notice Arbitrary user pokes symbols without being rewarded
   * @param symbols_ Asset symbols to poke
   */
  function poke(string[] memory symbols_) external override whenNotPaused {
    uint256 len = symbols_.length;
    require(len > 0, "PowerOracle::poke: Missing token symbols");

    uint256 ethPrice = _updateEthPrice();

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
   * @param cvpAPY_ The planned yield in % (1 ether == 1%)
   */
  function setCvpAPY(uint256 cvpAPY_) external override onlyOwner {
    cvpAPY = cvpAPY_;
    emit SetCvpApy(cvpAPY_);
  }

  /**
   * @notice Set the total number of reports for all pairs per year
   * @param totalReportsPerYear_ The total number of reports
   */
  function setTotalReportsPerYear(uint256 totalReportsPerYear_) external override onlyOwner {
    totalReportsPerYear = totalReportsPerYear_;
    emit SetTotalReportsPerYear(totalReportsPerYear_);
  }

  /**
   * @notice Set the current estimated gas expenses for reporting a single asset
   * @param gasExpensesPerAssetReport_ The gas amount
   */
  function setGasExpensesPerAssetReport(uint256 gasExpensesPerAssetReport_) external override onlyOwner {
    gasExpensesPerAssetReport = gasExpensesPerAssetReport_;
    emit SetGasExpensesPerAssetReport(gasExpensesPerAssetReport_);
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

  function calculateReward(
    uint256 count_,
    uint256 deposit_,
    uint256 ethPrice_,
    uint256 cvpPrice_
  ) public view returns (uint256) {
    if (count_ == 0) {
      return 0;
    }

    // return count_ * (calculateFixedReward(deposit_) + calculateGasCompensation(ethPrice_, cvpPrice_));
    return count_.mul(calculateFixedReward(deposit_).add(calculateGasCompensation(ethPrice_, cvpPrice_)));
  }

  function calculateFixedReward(uint256 deposit_) public view returns (uint256) {
    // return cvpAPY * deposit_ / totalReportsPerYear / HUNDRED_PCT;
    return cvpAPY.mul(deposit_) / totalReportsPerYear / HUNDRED_PCT;
  }

  function calculateGasCompensation(uint256 ethPrice_, uint256 cvpPrice_) public view returns (uint256) {
    require(ethPrice_ > 0, "PowerOracle::calculateGasCompensation: ETH price is 0");
    require(cvpPrice_ > 0, "PowerOracle::calculateGasCompensation: CVP price is 0");

    // return _min(tx.gasprice, gasPriceLimit) * gasExpensesPerAssetReport * ethPrice_ / cvpPrice_;
    return _min(tx.gasprice, gasPriceLimit).mul(gasExpensesPerAssetReport).mul(ethPrice_) / cvpPrice_;
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
}
