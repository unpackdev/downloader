// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./IPowerPoke.sol";
import "./SafeERC20.sol";
import "./WrappedPiErc20Interface.sol";
import "./IPoolRestrictions.sol";
import "./PowerIndexRouterInterface.sol";
import "./IRouterConnector.sol";
import "./PowerIndexNaiveRouter.sol";

/**
 * @notice PowerIndexRouter executes connectors with delegatecall to stake and redeem ERC20 tokens in
 * protocol-specified staking contracts. After calling, it saves stakeData and pokeData as connectors storage.
 * Available ERC20 token balance from piERC20 is distributed between connectors by its shares and calculated
 * as the difference between total balance and share of necessary balance(reserveRatio) for keeping in piERC20
 * for withdrawals.
 */
contract PowerIndexRouter is PowerIndexRouterInterface, PowerIndexNaiveRouter {
  using SafeERC20 for IERC20;

  uint256 internal constant COMPENSATION_PLAN_1_ID = 1;
  uint256 public constant HUNDRED_PCT = 1 ether;

  event SetReserveConfig(uint256 ratio, uint256 ratioLowerBound, uint256 ratioUpperBound, uint256 claimRewardsInterval);
  event SetPerformanceFee(uint256 performanceFee);
  event SetConnector(
    IRouterConnector indexed connector,
    uint256 share,
    bool callBeforeAfterPoke,
    uint256 indexed connectorIndex,
    bool indexed isNewConnector
  );
  event SetConnectorClaimParams(address connector, bytes claimParams);
  event SetConnectorStakeParams(address connector, bytes stakeParams);

  struct BasicConfig {
    address poolRestrictions;
    address powerPoke;
    uint256 reserveRatio;
    uint256 reserveRatioLowerBound;
    uint256 reserveRatioUpperBound;
    uint256 claimRewardsInterval;
    address performanceFeeReceiver;
    uint256 performanceFee;
  }

  WrappedPiErc20Interface public immutable piToken;
  IERC20 public immutable underlying;
  address public immutable performanceFeeReceiver;

  IPoolRestrictions public poolRestrictions;
  IPowerPoke public powerPoke;
  uint256 public reserveRatio;
  uint256 public claimRewardsInterval;
  uint256 public lastRebalancedByPokerAt;
  uint256 public reserveRatioLowerBound;
  uint256 public reserveRatioUpperBound;
  // 1 ether == 100%
  uint256 public performanceFee;
  Connector[] public connectors;

  struct RebalanceConfig {
    bool shouldPushFunds;
    StakeStatus status;
    uint256 diff;
    bool shouldClaim;
    bool forceRebalance;
    uint256 connectorIndex;
  }

  struct Connector {
    IRouterConnector connector;
    uint256 share;
    bool callBeforeAfterPoke;
    uint256 lastClaimRewardsAt;
    uint256 lastChangeStakeAt;
    bytes stakeData;
    bytes pokeData;
    bytes stakeParams;
    bytes claimParams;
  }

  struct ConnectorInput {
    bool newConnector;
    uint256 connectorIndex;
    IRouterConnector connector;
    uint256 share;
    bool callBeforeAfterPoke;
  }

  struct PokeFromState {
    uint256 minInterval;
    uint256 maxInterval;
    uint256 piTokenUnderlyingBalance;
    uint256 addToExpectedAmount;
    bool atLeastOneForceRebalance;
    bool skipCanPokeCheck;
  }

  modifier onlyEOA() {
    require(tx.origin == msg.sender, "ONLY_EOA");
    _;
  }

  modifier onlyReporter(uint256 _reporterId, bytes calldata _rewardOpts) {
    uint256 gasStart = gasleft();
    powerPoke.authorizeReporter(_reporterId, msg.sender);
    _;
    _reward(_reporterId, gasStart, COMPENSATION_PLAN_1_ID, _rewardOpts);
  }

  modifier onlyNonReporter(uint256 _reporterId, bytes calldata _rewardOpts) {
    uint256 gasStart = gasleft();
    powerPoke.authorizeNonReporter(_reporterId, msg.sender);
    _;
    _reward(_reporterId, gasStart, COMPENSATION_PLAN_1_ID, _rewardOpts);
  }

  constructor(address _piToken, BasicConfig memory _basicConfig) public PowerIndexNaiveRouter() Ownable() {
    require(_piToken != address(0), "INVALID_PI_TOKEN");
    require(_basicConfig.reserveRatioUpperBound <= HUNDRED_PCT, "UPPER_RR_GREATER_THAN_100_PCT");
    require(_basicConfig.reserveRatio >= _basicConfig.reserveRatioLowerBound, "RR_LTE_LOWER_RR");
    require(_basicConfig.reserveRatio <= _basicConfig.reserveRatioUpperBound, "RR_GTE_UPPER_RR");
    require(_basicConfig.performanceFee < HUNDRED_PCT, "PVP_FEE_GTE_HUNDRED_PCT");
    require(_basicConfig.performanceFeeReceiver != address(0), "INVALID_PVP_ADDR");
    require(_basicConfig.poolRestrictions != address(0), "INVALID_POOL_RESTRICTIONS_ADDR");

    piToken = WrappedPiErc20Interface(_piToken);
    (, bytes memory underlyingRes) = _piToken.call(abi.encodeWithSignature("underlying()"));
    underlying = IERC20(abi.decode(underlyingRes, (address)));
    poolRestrictions = IPoolRestrictions(_basicConfig.poolRestrictions);
    powerPoke = IPowerPoke(_basicConfig.powerPoke);
    reserveRatio = _basicConfig.reserveRatio;
    reserveRatioLowerBound = _basicConfig.reserveRatioLowerBound;
    reserveRatioUpperBound = _basicConfig.reserveRatioUpperBound;
    claimRewardsInterval = _basicConfig.claimRewardsInterval;
    performanceFeeReceiver = _basicConfig.performanceFeeReceiver;
    performanceFee = _basicConfig.performanceFee;
  }

  receive() external payable {}

  /*** OWNER METHODS ***/

  /**
   * @notice Set reserve ratio config
   * @param _reserveRatio Share of necessary token balance that piERC20 must hold after poke execution.
   * @param _reserveRatioLowerBound Lower bound of ERC20 token balance to force rebalance.
   * @param _reserveRatioUpperBound Upper bound of ERC20 token balance to force rebalance.
   * @param _claimRewardsInterval Time interval to claim rewards in connectors contracts.
   */
  function setReserveConfig(
    uint256 _reserveRatio,
    uint256 _reserveRatioLowerBound,
    uint256 _reserveRatioUpperBound,
    uint256 _claimRewardsInterval
  ) external virtual override onlyOwner {
    require(_reserveRatioUpperBound <= HUNDRED_PCT, "UPPER_RR_GREATER_THAN_100_PCT");
    require(_reserveRatio >= _reserveRatioLowerBound, "RR_LT_LOWER_RR");
    require(_reserveRatio <= _reserveRatioUpperBound, "RR_GT_UPPER_RR");

    reserveRatio = _reserveRatio;
    reserveRatioLowerBound = _reserveRatioLowerBound;
    reserveRatioUpperBound = _reserveRatioUpperBound;
    claimRewardsInterval = _claimRewardsInterval;
    emit SetReserveConfig(_reserveRatio, _reserveRatioLowerBound, _reserveRatioUpperBound, _claimRewardsInterval);
  }

  /**
   * @notice Set performance fee.
   * @param _performanceFee Share of rewards for distributing to performanceFeeReceiver(Protocol treasury).
   */
  function setPerformanceFee(uint256 _performanceFee) external onlyOwner {
    require(_performanceFee < HUNDRED_PCT, "PERFORMANCE_FEE_OVER_THE_LIMIT");
    performanceFee = _performanceFee;
    emit SetPerformanceFee(_performanceFee);
  }

  /**
   * @notice Set piERC20 ETH fee for deposit and withdrawal functions.
   * @param _ethFee Fee amount in ETH.
   */
  function setPiTokenEthFee(uint256 _ethFee) external onlyOwner {
    require(_ethFee <= 0.1 ether, "ETH_FEE_OVER_THE_LIMIT");
    piToken.setEthFee(_ethFee);
  }

  /**
   * @notice Set connectors configs. Items should have `newConnector` variable to create connectors and `connectorIndex`
   * to update existing connectors.
   * @param _connectorList Array of connector items.
   */
  function setConnectorList(ConnectorInput[] memory _connectorList) external onlyOwner {
    require(_connectorList.length != 0, "CONNECTORS_LENGTH_CANT_BE_NULL");

    for (uint256 i = 0; i < _connectorList.length; i++) {
      ConnectorInput memory c = _connectorList[i];

      if (c.newConnector) {
        connectors.push(
          Connector(
            c.connector,
            c.share,
            c.callBeforeAfterPoke,
            0,
            0,
            new bytes(0),
            new bytes(0),
            new bytes(0),
            new bytes(0)
          )
        );
        c.connectorIndex = connectors.length - 1;
      } else {
        connectors[c.connectorIndex].connector = c.connector;
        connectors[c.connectorIndex].share = c.share;
        connectors[c.connectorIndex].callBeforeAfterPoke = c.callBeforeAfterPoke;
      }

      emit SetConnector(c.connector, c.share, c.callBeforeAfterPoke, c.connectorIndex, c.newConnector);
    }
    _checkConnectorsTotalShare();
  }

  /**
   * @notice Set connectors claim params to pass it to connector.
   * @param _connectorIndex Index of connector
   * @param _claimParams Claim params
   */
  function setClaimParams(uint256 _connectorIndex, bytes memory _claimParams) external onlyOwner {
    connectors[_connectorIndex].claimParams = _claimParams;
    emit SetConnectorClaimParams(address(connectors[_connectorIndex].connector), _claimParams);
  }

  /**
   * @notice Set connector stake params to pass it to connector.
   * @param _connectorIndex Index of connector
   * @param _stakeParams Claim params
   */
  function setStakeParams(uint256 _connectorIndex, bytes memory _stakeParams) external onlyOwner {
    connectors[_connectorIndex].stakeParams = _stakeParams;
    emit SetConnectorStakeParams(address(connectors[_connectorIndex].connector), _stakeParams);
  }

  /**
   * @notice Set piERC20 noFee config for account address.
   * @param _for Account address.
   * @param _noFee Value for account.
   */
  function setPiTokenNoFee(address _for, bool _noFee) external onlyOwner {
    piToken.setNoFee(_for, _noFee);
  }

  /**
   * @notice Call piERC20 `withdrawEthFee`.
   * @param _receiver Receiver address.
   */
  function withdrawEthFee(address payable _receiver) external onlyOwner {
    piToken.withdrawEthFee(_receiver);
  }

  /**
   * @notice Transfer ERC20 balances and rights to a new router address.
   * @param _piToken piERC20 address.
   * @param _newRouter New router contract address.
   * @param _tokens ERC20 to transfer.
   */
  function migrateToNewRouter(
    address _piToken,
    address payable _newRouter,
    address[] memory _tokens
  ) public override onlyOwner {
    super.migrateToNewRouter(_piToken, _newRouter, _tokens);

    _newRouter.transfer(address(this).balance);

    uint256 len = _tokens.length;
    for (uint256 i = 0; i < len; i++) {
      IERC20 t = IERC20(_tokens[i]);
      t.safeTransfer(_newRouter, t.balanceOf(address(this)));
    }
  }

  /**
   * @notice Call initRouter function of the connector contract.
   * @param _connectorIndex Connector index in connectors array.
   * @param _data To pass as an argument.
   */
  function initRouterByConnector(uint256 _connectorIndex, bytes memory _data) public onlyOwner {
    (bool success, bytes memory result) = address(connectors[_connectorIndex].connector).delegatecall(
      abi.encodeWithSignature("initRouter(bytes)", _data)
    );
    require(success, string(result));
  }

  function piTokenCallback(address, uint256 _withdrawAmount) external payable virtual override {
    PokeFromState memory state = PokeFromState(0, 0, 0, _withdrawAmount, false, true);
    _rebalance(state, false, false);
  }

  /**
   * @notice Call poke by Reporter.
   * @param _reporterId Reporter ID.
   * @param _claimAndDistributeRewards Claim rewards only if interval reached.
   * @param _rewardOpts To whom and how to reward Reporter.
   */
  function pokeFromReporter(
    uint256 _reporterId,
    bool _claimAndDistributeRewards,
    bytes calldata _rewardOpts
  ) external onlyReporter(_reporterId, _rewardOpts) onlyEOA {
    _pokeFrom(_claimAndDistributeRewards, false);
  }

  /**
   * @notice Call poke by Slasher.
   * @param _reporterId Slasher ID.
   * @param _claimAndDistributeRewards Claim rewards only if interval reached.
   * @param _rewardOpts To whom and how reward Slasher.
   */
  function pokeFromSlasher(
    uint256 _reporterId,
    bool _claimAndDistributeRewards,
    bytes calldata _rewardOpts
  ) external onlyNonReporter(_reporterId, _rewardOpts) onlyEOA {
    _pokeFrom(_claimAndDistributeRewards, true);
  }

  /**
   * @notice Executes rebalance(beforePoke, rebalancePoke, claimRewards, afterPoke) for connector contract by config.
   * @param _conf Connector rebalance config.
   */
  function _rebalancePokeByConf(RebalanceConfig memory _conf) internal {
    Connector storage c = connectors[_conf.connectorIndex];

    if (c.callBeforeAfterPoke) {
      _beforePoke(c, _conf.shouldClaim);
    }

    if (_conf.status != StakeStatus.EQUILIBRIUM) {
      _rebalancePoke(c, _conf.status, _conf.diff);
    }

    // check claim interval again due to possibility of claiming by stake or redeem function(maybe already claimed)
    if (_conf.shouldClaim && claimRewardsIntervalReached(c.lastClaimRewardsAt)) {
      _claimRewards(c, _conf.status);
      c.lastClaimRewardsAt = block.timestamp;
    } else {
      require(_conf.status != StakeStatus.EQUILIBRIUM, "NOTHING_TO_DO");
    }

    if (c.callBeforeAfterPoke) {
      _afterPoke(c, _conf.status, _conf.shouldClaim);
    }
  }

  function claimRewardsIntervalReached(uint256 _lastClaimRewardsAt) public view returns (bool) {
    return _lastClaimRewardsAt + claimRewardsInterval < block.timestamp;
  }

  /**
   * @notice Rebalance every connector according to its share in an array.
   * @param _claimAndDistributeRewards Need to claim and distribute rewards.
   * @param _isSlasher Calling by Slasher.
   */
  function _pokeFrom(bool _claimAndDistributeRewards, bool _isSlasher) internal {
    PokeFromState memory state = PokeFromState(0, 0, 0, 0, false, false);
    (state.minInterval, state.maxInterval) = _getMinMaxReportInterval();

    _rebalance(state, _claimAndDistributeRewards, _isSlasher);

    require(
      _canPoke(_isSlasher, state.atLeastOneForceRebalance, state.minInterval, state.maxInterval),
      "INTERVAL_NOT_REACHED_OR_NOT_FORCE"
    );

    lastRebalancedByPokerAt = block.timestamp;
  }

  function _rebalance(
    PokeFromState memory s,
    bool _claimAndDistributeRewards,
    bool _isSlasher
  ) internal {
    if (connectors.length == 1 && reserveRatio == 0 && !_claimAndDistributeRewards) {
      if (s.addToExpectedAmount > 0) {
        _rebalancePoke(connectors[0], StakeStatus.EXCESS, s.addToExpectedAmount);
      } else {
        _rebalancePoke(connectors[0], StakeStatus.SHORTAGE, piToken.getUnderlyingBalance());
      }
      return;
    }

    s.piTokenUnderlyingBalance = piToken.getUnderlyingBalance();
    (uint256[] memory stakedBalanceList, uint256 totalStakedBalance) = _getUnderlyingStakedList();

    RebalanceConfig[] memory configs = new RebalanceConfig[](connectors.length);

    // First cycle: connectors with EXCESS balance status on staking
    for (uint256 i = 0; i < connectors.length; i++) {
      if (connectors[i].share == 0) {
        continue;
      }

      (StakeStatus status, uint256 diff, bool shouldClaim, bool forceRebalance) = getStakeAndClaimStatus(
        s.piTokenUnderlyingBalance,
        totalStakedBalance,
        stakedBalanceList[i],
        s.addToExpectedAmount,
        _claimAndDistributeRewards,
        connectors[i]
      );
      if (forceRebalance) {
        s.atLeastOneForceRebalance = true;
      }

      if (status == StakeStatus.EXCESS) {
        // Calling rebalance immediately if interval conditions reached
        if (s.skipCanPokeCheck || _canPoke(_isSlasher, forceRebalance, s.minInterval, s.maxInterval)) {
          _rebalancePokeByConf(RebalanceConfig(false, status, diff, shouldClaim, forceRebalance, i));
        }
      } else {
        // Push config for second cycle
        configs[i] = RebalanceConfig(true, status, diff, shouldClaim, forceRebalance, i);
      }
    }

    // Second cycle: connectors with EQUILIBRIUM and SHORTAGE balance status on staking
    for (uint256 i = 0; i < connectors.length; i++) {
      if (!configs[i].shouldPushFunds) {
        continue;
      }
      // Calling rebalance if interval conditions reached
      if (s.skipCanPokeCheck || _canPoke(_isSlasher, configs[i].forceRebalance, s.minInterval, s.maxInterval)) {
        _rebalancePokeByConf(configs[i]);
      }
    }
  }

  /**
   * @notice Checking: if time interval reached or have `forceRebalance`.
   */
  function _canPoke(
    bool _isSlasher,
    bool _forceRebalance,
    uint256 _minInterval,
    uint256 _maxInterval
  ) internal view returns (bool) {
    if (_forceRebalance) {
      return true;
    }
    return
      _isSlasher
        ? (lastRebalancedByPokerAt + _maxInterval < block.timestamp)
        : (lastRebalancedByPokerAt + _minInterval < block.timestamp);
  }

  /**
   * @notice Call redeem in the connector with delegatecall, save result stakeData if not null.
   */
  function _redeem(Connector storage _c, uint256 _diff) internal {
    _callStakeRedeem("redeem(uint256,(bytes,bytes,uint256,address))", _c, _diff);
  }

  /**
   * @notice Call stake in the connector with delegatecall, save result `stakeData` if not null.
   */
  function _stake(Connector storage _c, uint256 _diff) internal {
    _callStakeRedeem("stake(uint256,(bytes,bytes,uint256,address))", _c, _diff);
  }

  function _callStakeRedeem(
    string memory _method,
    Connector storage _c,
    uint256 _diff
  ) internal {
    (bool success, bytes memory result) = address(_c.connector).delegatecall(
      abi.encodeWithSignature(_method, _diff, _getDistributeData(_c))
    );
    require(success, string(result));
    bool claimed;
    (result, claimed) = abi.decode(result, (bytes, bool));
    if (result.length > 0) {
      _c.stakeData = result;
    }
    if (claimed) {
      _c.lastClaimRewardsAt = block.timestamp;
    }
    _c.lastChangeStakeAt = block.timestamp;
  }

  /**
   * @notice Call `beforePoke` in the connector with delegatecall, do not save `pokeData`.
   */
  function _beforePoke(Connector storage c, bool _willClaimReward) internal {
    (bool success, ) = address(c.connector).delegatecall(
      abi.encodeWithSignature(
        "beforePoke(bytes,(bytes,uint256,address),bool)",
        c.pokeData,
        _getDistributeData(c),
        _willClaimReward
      )
    );
    require(success, "_beforePoke call error");
  }

  /**
   * @notice Call `afterPoke` in the connector with delegatecall, save result `pokeData` if not null.
   */
  function _afterPoke(
    Connector storage _c,
    StakeStatus _stakeStatus,
    bool _rewardClaimDone
  ) internal {
    (bool success, bytes memory result) = address(_c.connector).delegatecall(
      abi.encodeWithSignature("afterPoke(uint8,bool)", uint8(_stakeStatus), _rewardClaimDone)
    );
    require(success, string(result));
    result = abi.decode(result, (bytes));
    if (result.length > 0) {
      _c.pokeData = result;
    }
  }

  /**
   * @notice Rebalance connector: stake if StakeStatus.SHORTAGE and redeem if StakeStatus.EXCESS.
   */
  function _rebalancePoke(
    Connector storage _c,
    StakeStatus _stakeStatus,
    uint256 _diff
  ) internal {
    if (_stakeStatus == StakeStatus.EXCESS) {
      _redeem(_c, _diff);
    } else if (_stakeStatus == StakeStatus.SHORTAGE) {
      _stake(_c, _diff);
    }
  }

  function redeem(uint256 _connectorIndex, uint256 _diff) external onlyOwner {
    _redeem(connectors[_connectorIndex], _diff);
  }

  function stake(uint256 _connectorIndex, uint256 _diff) external onlyOwner {
    _stake(connectors[_connectorIndex], _diff);
  }

  /**
   * @notice Explicitly collects the assigned rewards. If a reward token is the same as the underlying, it should
   * allocate it at piERC20. Otherwise, it should transfer to the router contract for further action.
   * @dev It's not the only way to claim rewards. Sometimes rewards are distributed implicitly while interacting
   * with a protocol. E.g., MasterChef distributes rewards on each `deposit()/withdraw()` action, and there is
   * no use in calling `_claimRewards()` immediately after calling one of these methods.
   */
  function _claimRewards(Connector storage c, StakeStatus _stakeStatus) internal {
    (bool success, bytes memory result) = address(c.connector).delegatecall(
      abi.encodeWithSelector(IRouterConnector.claimRewards.selector, _stakeStatus, _getDistributeData(c))
    );
    require(success, string(result));
    result = abi.decode(result, (bytes));
    if (result.length > 0) {
      c.stakeData = result;
    }
  }

  function _reward(
    uint256 _reporterId,
    uint256 _gasStart,
    uint256 _compensationPlan,
    bytes calldata _rewardOpts
  ) internal {
    powerPoke.reward(_reporterId, _gasStart.sub(gasleft()), _compensationPlan, _rewardOpts);
  }

  /*
   * @dev Getting status and diff of actual staked balance and target reserve balance.
   */
  function getStakeStatusForBalance(uint256 _stakedBalance, uint256 _share)
    external
    view
    returns (
      StakeStatus status,
      uint256 diff,
      bool forceRebalance
    )
  {
    return getStakeStatus(piToken.getUnderlyingBalance(), getUnderlyingStaked(), _stakedBalance, 0, _share);
  }

  function getStakeAndClaimStatus(
    uint256 _leftOnPiTokenBalance,
    uint256 _totalStakedBalance,
    uint256 _stakedBalance,
    uint256 _addToExpectedAmount,
    bool _claimAndDistributeRewards,
    Connector memory _c
  )
    public
    view
    returns (
      StakeStatus status,
      uint256 diff,
      bool shouldClaim,
      bool forceRebalance
    )
  {
    (status, diff, forceRebalance) = getStakeStatus(
      _leftOnPiTokenBalance,
      _totalStakedBalance,
      _stakedBalance,
      _addToExpectedAmount,
      _c.share
    );
    shouldClaim = _claimAndDistributeRewards && claimRewardsIntervalReached(_c.lastClaimRewardsAt);

    if (shouldClaim && _c.claimParams.length != 0) {
      shouldClaim = _c.connector.isClaimAvailable(_c.claimParams, _c.lastClaimRewardsAt, _c.lastChangeStakeAt);
      if (shouldClaim && !forceRebalance) {
        forceRebalance = true;
      }
    }
  }

  /*
   * @dev Getting status and diff of current staked balance and target stake balance.
   */
  function getStakeStatus(
    uint256 _leftOnPiTokenBalance,
    uint256 _totalStakedBalance,
    uint256 _stakedBalance,
    uint256 _addToExpectedAmount,
    uint256 _share
  )
    public
    view
    returns (
      StakeStatus status,
      uint256 diff,
      bool forceRebalance
    )
  {
    uint256 expectedStakeAmount;
    (status, diff, expectedStakeAmount) = getStakeStatusPure(
      reserveRatio,
      _leftOnPiTokenBalance,
      _totalStakedBalance,
      _stakedBalance,
      _share,
      _addToExpectedAmount
    );

    if (status == StakeStatus.EQUILIBRIUM) {
      return (status, diff, forceRebalance);
    }

    uint256 denominator = _leftOnPiTokenBalance.add(_totalStakedBalance);

    if (status == StakeStatus.EXCESS) {
      uint256 numerator = _leftOnPiTokenBalance.add(diff).mul(HUNDRED_PCT);
      uint256 currentRatio = numerator.div(denominator);
      forceRebalance = reserveRatioLowerBound >= currentRatio;
    } else if (status == StakeStatus.SHORTAGE) {
      if (diff > _leftOnPiTokenBalance) {
        return (status, diff, true);
      }
      uint256 numerator = _leftOnPiTokenBalance.sub(diff).mul(HUNDRED_PCT);
      uint256 currentRatio = numerator.div(denominator);
      forceRebalance = reserveRatioUpperBound <= currentRatio;
    }
  }

  function getUnderlyingStaked() public view virtual returns (uint256) {
    uint256 underlyingStaked = 0;
    for (uint256 i = 0; i < connectors.length; i++) {
      require(address(connectors[i].connector) != address(0), "CONNECTOR_IS_NULL");
      underlyingStaked += connectors[i].connector.getUnderlyingStaked();
    }
    return underlyingStaked;
  }

  function _getUnderlyingStakedList() internal view virtual returns (uint256[] memory list, uint256 total) {
    uint256[] memory underlyingStakedList = new uint256[](connectors.length);
    total = 0;
    for (uint256 i = 0; i < connectors.length; i++) {
      require(address(connectors[i].connector) != address(0), "CONNECTOR_IS_NULL");
      underlyingStakedList[i] = connectors[i].connector.getUnderlyingStaked();
      total += underlyingStakedList[i];
    }
    return (underlyingStakedList, total);
  }

  function getUnderlyingReserve() public view returns (uint256) {
    return underlying.balanceOf(address(piToken));
  }

  function calculateLockedProfit() public view returns (uint256) {
    uint256 lockedProfit = 0;
    for (uint256 i = 0; i < connectors.length; i++) {
      require(address(connectors[i].connector) != address(0), "CONNECTOR_IS_NULL");
      lockedProfit += connectors[i].connector.calculateLockedProfit(connectors[i].stakeData);
    }
    return lockedProfit;
  }

  function getUnderlyingAvailable() public view returns (uint256) {
    // _getUnderlyingReserve + getUnderlyingStaked - _calculateLockedProfit
    return getUnderlyingReserve().add(getUnderlyingStaked()).sub(calculateLockedProfit());
  }

  function getUnderlyingTotal() external view returns (uint256) {
    // _getUnderlyingReserve + getUnderlyingStaked
    return getUnderlyingReserve().add(getUnderlyingStaked());
  }

  function getPiEquivalentForUnderlying(uint256 _underlyingAmount, uint256 _piTotalSupply)
    external
    view
    virtual
    override
    returns (uint256)
  {
    return getPiEquivalentForUnderlyingPure(_underlyingAmount, getUnderlyingAvailable(), _piTotalSupply);
  }

  function getPiEquivalentForUnderlyingPure(
    uint256 _underlyingAmount,
    uint256 _totalUnderlyingWrapped,
    uint256 _piTotalSupply
  ) public pure virtual override returns (uint256) {
    if (_piTotalSupply == 0) {
      return _underlyingAmount;
    }
    // return _piTotalSupply * _underlyingAmount / _totalUnderlyingWrapped;
    return _piTotalSupply.mul(_underlyingAmount).div(_totalUnderlyingWrapped);
  }

  function getUnderlyingEquivalentForPi(uint256 _piAmount, uint256 _piTotalSupply)
    external
    view
    virtual
    override
    returns (uint256)
  {
    return getUnderlyingEquivalentForPiPure(_piAmount, getUnderlyingAvailable(), _piTotalSupply);
  }

  function getUnderlyingEquivalentForPiPure(
    uint256 _piAmount,
    uint256 _totalUnderlyingWrapped,
    uint256 _piTotalSupply
  ) public pure virtual override returns (uint256) {
    if (_piTotalSupply == 0) {
      return _piAmount;
    }
    // _piAmount * _totalUnderlyingWrapped / _piTotalSupply;
    return _totalUnderlyingWrapped.mul(_piAmount).div(_piTotalSupply);
  }

  /**
   * @notice Calculates the desired stake status.
   * @param _reserveRatioPct The reserve ratio in %, 1 ether == 100 ether.
   * @param _leftOnPiToken The underlying ERC20 tokens balance on the piERC20 contract.
   * @param _totalStakedBalance The underlying ERC20 tokens balance staked on the all connected staking contracts.
   * @param _stakedBalance The underlying ERC20 tokens balance staked on the connector staking contract.
   * @param _share Share of the connector contract.
   * @return status The stake status:
   * * SHORTAGE: There is not enough underlying ERC20 balance on the staking contract to satisfy the reserve ratio.
   *             Therefore, the connector contract should send the diff amount to the staking contract.
   * * EXCESS: There is some extra underlying ERC20 balance on the staking contract.
   *           Therefore, the connector contract should redeem the diff amount from the staking contract.
   * * EQUILIBRIUM: The reserve ratio hasn't changed, the diff amount is 0, and no need for additional
   *                stake/redeem actions.
   * @return diff The difference between `expectedStakeAmount` and `_stakedBalance`.
   * @return expectedStakeAmount The calculated expected underlying ERC20 staked balance.
   */
  function getStakeStatusPure(
    uint256 _reserveRatioPct,
    uint256 _leftOnPiToken,
    uint256 _totalStakedBalance,
    uint256 _stakedBalance,
    uint256 _share,
    uint256 _addToExpectedStakeAmount
  )
    public
    view
    returns (
      StakeStatus status,
      uint256 diff,
      uint256 expectedStakeAmount
    )
  {
    require(_reserveRatioPct <= HUNDRED_PCT, "RR_GREATER_THAN_100_PCT");
    expectedStakeAmount = getExpectedStakeAmount(_reserveRatioPct, _leftOnPiToken, _totalStakedBalance, _share);
    expectedStakeAmount = expectedStakeAmount.add(_addToExpectedStakeAmount.mul(_share).div(1 ether));

    if (expectedStakeAmount > _stakedBalance) {
      status = StakeStatus.SHORTAGE;
      diff = expectedStakeAmount.sub(_stakedBalance);
    } else if (expectedStakeAmount < _stakedBalance) {
      status = StakeStatus.EXCESS;
      diff = _stakedBalance.sub(expectedStakeAmount);
    } else {
      status = StakeStatus.EQUILIBRIUM;
      diff = 0;
    }
  }

  /**
   * @notice Calculates an expected underlying ERC20 staked balance.
   * @param _reserveRatioPct % of a reserve ratio, 1 ether == 100%.
   * @param _leftOnPiToken The underlying ERC20 tokens balance on the piERC20 contract.
   * @param _stakedBalance The underlying ERC20 tokens balance staked on the staking contract.
   * @param _share % of a total connectors share, 1 ether == 100%.
   * @return expectedStakeAmount The expected stake amount:
   *
   *                           / (100% - %reserveRatio) * (_leftOnPiToken + _stakedBalance) * %share \
   *    expectedStakeAmount = | ----------------------------------------------------------------------|
   *                           \                                    100%                             /
   */
  function getExpectedStakeAmount(
    uint256 _reserveRatioPct,
    uint256 _leftOnPiToken,
    uint256 _stakedBalance,
    uint256 _share
  ) public pure returns (uint256) {
    return
      uint256(1 ether).sub(_reserveRatioPct).mul(_stakedBalance.add(_leftOnPiToken).mul(_share).div(HUNDRED_PCT)).div(
        HUNDRED_PCT
      );
  }

  function _getMinMaxReportInterval() internal view returns (uint256 min, uint256 max) {
    return powerPoke.getMinMaxReportIntervals(address(this));
  }

  function _getDistributeData(Connector storage c) internal view returns (IRouterConnector.DistributeData memory) {
    return IRouterConnector.DistributeData(c.stakeData, c.stakeParams, performanceFee, performanceFeeReceiver);
  }

  function _checkConnectorsTotalShare() internal view {
    uint256 totalShare = 0;
    for (uint256 i = 0; i < connectors.length; i++) {
      require(address(connectors[i].connector) != address(0), "CONNECTOR_IS_NULL");
      totalShare = totalShare.add(connectors[i].share);
    }
    require(totalShare == HUNDRED_PCT, "TOTAL_SHARE_IS_NOT_HUNDRED_PCT");
  }
}
