// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.7.6;

import "./PermissionOperators.sol";
import "./Utils.sol";
import "./IERC20Ext.sol";
import "./ReentrancyGuard.sol";
import "./SafeMath.sol";
import "./SafeERC20.sol";
import "./EnumerableSet.sol";
import "./ILiquidationCallback.sol";
import "./ILiquidationStrategyBase.sol";
import "./IPool.sol";

contract LiquidationStrategyBase is ILiquidationStrategyBase, PermissionOperators,
  Utils, ReentrancyGuard {

  using SafeERC20 for IERC20Ext;
  using SafeMath for uint256;
  using EnumerableSet for EnumerableSet.AddressSet;

  // after repeatedPeriod since startTime, there will be duration (in seconds)
  // for liquidators to liquidate tokens in the treasury pool
  // for example: from deployed time, every 2 weeks liquidation is enabled for 4 days
  struct LiquidationSchedule {
    uint128 startTime;
    uint64 repeatedPeriod;
    uint64 duration;
  }

  // list of tokens that can be liquidate to
  EnumerableSet.AddressSet private _whitelistedLiquidators;
  EnumerableSet.AddressSet private _whitelistedPriceOracles;

  LiquidationSchedule private _liquidationSchedule;
  IPool private _treasuryPool;
  address payable private _rewardPool;

  bool public paused = false;
  event Pause(address caller, bool isPaused);

  event TreasuryPoolSet(address indexed treasuryPool);
  event RewardPoolSet(address indexed rewardPool);
  event LiquidationScheduleUpdated(uint128 startTime, uint64 repeatedPeriod, uint64 duration);
  event WhitelistedLiquidatorUpdated(address indexed liquidator, bool indexed isAdd);
  event WhitelistedPriceOracleUpdated(address indexed oracle, bool indexed isAdd);

  constructor(
    address admin,
    address treasuryPoolAddress,
    address payable rewardPoolAddress,
    uint128 startTime,
    uint64 repeatedPeriod,
    uint64 duration,
    address[] memory whitelistedLiquidators,
    address[] memory whitelistedOracles
  ) PermissionAdmin(admin) {
    _setTreasuryPool(treasuryPoolAddress);
    _setRewardPool(rewardPoolAddress);
    _setLiquidationSchedule(startTime, repeatedPeriod, duration);
    _updateWhitelistedLiquidators(whitelistedLiquidators, true);
    _updateWhitelistedPriceOracles(whitelistedOracles, true);
  }

  receive() external payable {}

  /**
   * @dev Update liquidation schedule
   *  to disable the liquidation: set repeatedPeriod to 0
   *  to always enable the liquidation: set duration >= repeatedPeriod
   * @param startTime: start time of the first liquidation schedule
   * @param repeatedPeriod period in seconds that the schedule will be repeated
   * @param duration duration of each schedule
   */
  function updateLiquidationSchedule(
    uint128 startTime,
    uint64 repeatedPeriod,
    uint64 duration
  )
    external onlyAdmin
  {
    _setLiquidationSchedule(startTime, repeatedPeriod, duration);
  }

  function updateTreasuryPool(address pool) external override onlyAdmin {
    _setTreasuryPool(pool);
  }

  function updateRewardPool(address payable pool) external override onlyAdmin {
    _setRewardPool(pool);
  }

  function updateWhitelistedLiquidators(address[] calldata liquidators, bool isAdd)
    external override onlyAdmin
  {
    _updateWhitelistedLiquidators(liquidators, isAdd);
  }

  function updateWhitelistedOracles(address[] calldata oracles, bool isAdd)
    external override onlyAdmin
  {
    _updateWhitelistedPriceOracles(oracles, isAdd);
  }

  /**
   * @dev Allow operator to pause the liquidation in case of emergency
   *  It's faster and more flexible than waiting for a proposal
   */
  function setPause(bool isPause) external onlyOperator {
    paused = isPause;
    emit Pause(msg.sender, isPause);
  }

  /** @dev Liquidate list of tokens to a single dest token,
  *   source token must not be a whitelisted token, dest must be a whitelisted token
  *   in case whitelisted liquidator is enabled, sender must be whitelisted
  *   funds need to be transferred back to the LiquidationStrategy before transferring to RewardPool
  * @param oracle the whitelisted oracle that will be used to get conversion data
  * @param sources list of source tokens to liquidate
  * @param amounts list of amounts corresponding to each source token
  * @param recipient receiver of source tokens
  * @param dest dest token to liquidate to
  * @param oracleHint hint for getting data from oracle
  * @param txData data to callback to recipient
  */
  function liquidate(
    ILiquidationPriceOracleBase oracle,
    IERC20Ext[] calldata sources,
    uint256[] calldata amounts,
    address payable recipient,
    IERC20Ext dest,
    bytes calldata oracleHint,
    bytes calldata txData
  )
    external virtual override nonReentrant
    returns (uint256 destAmount)
  {
    require(!paused, 'liquidate: only when not paused');
    require(isWhitelistedLiquidator(msg.sender), 'liquidate: only whitelisted liquidator');
    require(isWhitelistedOracle(address(oracle)), 'liquidate: only whitelisted oracle');
    require(isLiquidationEnabled(), 'liquidate: only when liquidation enabled');

    // request return data from oracle
    uint256 minReturn = oracle.getExpectedReturn(
      msg.sender, sources, amounts, dest, oracleHint
    );
    require(minReturn > 0, 'liquidate: minReturn == 0');

    uint256 destBalance = getBalance(dest, address(this));

    // request funds from treasury pool to recipient
    _treasuryPool.withdrawFunds(sources, amounts, recipient);
    // callback to recipient to transfer dest amount to reward
    // internal function to prevent stack too deep
    _liquidationCallback(sources, amounts, recipient, dest, minReturn, txData);

    destAmount = getBalance(dest, address(this)).sub(destBalance);
    require(destAmount >= minReturn, 'liquidate: low return amount');
    _transferToken(dest, rewardPool(), destAmount);
  }

  // Whitelisted liquidators
  function getWhitelistedLiquidatorsLength() external override view returns (uint256) {
    return _whitelistedLiquidators.length();
  }

  function getWhitelistedLiquidatorAt(uint256 index) external override view returns (address) {
    return _whitelistedLiquidators.at(index);
  }

  function getAllWhitelistedLiquidators()
    external view override returns (address[] memory liquidators)
  {
    uint256 length = _whitelistedLiquidators.length();
    liquidators = new address[](length);
    for(uint256 i = 0; i < length; i++) {
      liquidators[i] = _whitelistedLiquidators.at(i);
    }
  }

  // Whitelisted Price Orcales
  function getWhitelistedPriceOraclesLength() external override view returns (uint256) {
    return _whitelistedPriceOracles.length();
  }

  function getWhitelistedPriceOracleAt(uint256 index) external override view returns (address) {
    return _whitelistedPriceOracles.at(index);
  }

  function getAllWhitelistedPriceOracles()
    external view override returns (address[] memory oracles)
  {
    uint256 length = _whitelistedPriceOracles.length();
    oracles = new address[](length);
    for(uint256 i = 0; i < length; i++) {
      oracles[i] = _whitelistedPriceOracles.at(i);
    }
  }

  function getLiquidationSchedule()
    external override view
    returns(
      uint128 startTime,
      uint64 repeatedPeriod,
      uint64 duration
    )
  {
    (startTime, repeatedPeriod, duration) = (
      _liquidationSchedule.startTime,
      _liquidationSchedule.repeatedPeriod,
      _liquidationSchedule.duration
    );
  }

  function treasuryPool() public override view returns (address) {
    return address(_treasuryPool);
  }

  function rewardPool() public override view returns (address payable) {
    return _rewardPool;
  }

  function isWhitelistedLiquidator(address liquidator)
    public view override returns (bool)
  {
    return _whitelistedLiquidators.contains(liquidator);
  }

  function isWhitelistedOracle(address oracle)
    public view override returns (bool)
  {
    return _whitelistedPriceOracles.contains(oracle);
  }

  function isLiquidationEnabled() public view override returns (bool) {
    LiquidationSchedule memory schedule = _liquidationSchedule;
    if (schedule.duration == 0) return false;
    if (block.timestamp < uint256(schedule.startTime)) return false;
    uint256 timeInPeriod = (block.timestamp - uint256(schedule.startTime)) % uint256(schedule.repeatedPeriod);
    return timeInPeriod < schedule.duration;
  }

  function _setTreasuryPool(address _pool) internal {
    require(_pool != address(0), 'invalid treasury pool');
    _treasuryPool = IPool(_pool);
    emit TreasuryPoolSet(_pool);
  }

  function _setRewardPool(address payable _pool) internal {
    require(_pool != address(0), 'invalid reward pool');
    _rewardPool = _pool;
    emit RewardPoolSet(_pool);
  }

  function _updateWhitelistedLiquidators(address[] memory _liquidators, bool _isAdd) internal {
    for(uint256 i = 0; i < _liquidators.length; i++) {
      if (_isAdd) {
        _whitelistedLiquidators.add(_liquidators[i]);
      } else {
        _whitelistedLiquidators.remove(_liquidators[i]);
      }
      emit WhitelistedLiquidatorUpdated(_liquidators[i], _isAdd);
    }
  }

  function _updateWhitelistedPriceOracles(address[] memory _oracles, bool _isAdd) internal {
    for(uint256 i = 0; i < _oracles.length; i++) {
      if (_isAdd) {
        _whitelistedPriceOracles.add(_oracles[i]);
      } else {
        _whitelistedPriceOracles.remove(_oracles[i]);
      }
      emit WhitelistedPriceOracleUpdated(_oracles[i], _isAdd);
    }
  }

  function _setLiquidationSchedule(
    uint128 _startTime,
    uint64 _repeatedPeriod,
    uint64 _duration
  ) internal {
    require(_repeatedPeriod > 0, 'repeated period is 0');
    _liquidationSchedule = LiquidationSchedule({
        startTime: _startTime,
        repeatedPeriod: _repeatedPeriod,
        duration: _duration
    });
    emit LiquidationScheduleUpdated(_startTime, _repeatedPeriod, _duration);
  }

  function _transferToken(IERC20Ext token, address payable recipient, uint256 amount) internal {
    if (token == ETH_TOKEN_ADDRESS) {
      (bool success, ) = recipient.call { value: amount }('');
      require(success, 'transfer eth failed');
    } else {
      token.safeTransfer(recipient, amount);
    }
  }

  function _liquidationCallback(
    IERC20Ext[] memory sources,
    uint256[] memory amounts,
    address payable recipient,
    IERC20Ext dest,
    uint256 minReturn,
    bytes calldata txData
  ) internal {
    ILiquidationCallback(recipient).liquidationCallback(
      msg.sender, sources, amounts, address(this), dest, minReturn, txData
    );
  }
}
