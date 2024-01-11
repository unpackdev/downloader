// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./ITornStaking.sol";
import "./ITornGovernance.sol";
import "./AbstractConnector.sol";
import "./UniswapV3OracleHelper.sol";

contract TornPowerIndexConnector is AbstractConnector {
  event Stake(address indexed sender, uint256 amount, uint256 rewardReceived);
  event Redeem(address indexed sender, uint256 amount, uint256 rewardReceived);

  uint256 public constant RATIO_CONSTANT = 10000000 ether;
  address public immutable GOVERNANCE;
  address public immutable STAKING;
  IERC20 public immutable UNDERLYING;
  WrappedPiErc20Interface public immutable PI_TOKEN;

  constructor(
    address _staking,
    address _underlying,
    address _piToken,
    address _governance
  )
    public
    // 1e18 for 100% / (6 hours * 60 * 60) seconds ~= 46e12 degradation per 1 second
    AbstractConnector(46e12)
  {
    STAKING = _staking;
    UNDERLYING = IERC20(_underlying);
    PI_TOKEN = WrappedPiErc20Interface(_piToken);
    GOVERNANCE = _governance;
  }

  // solhint-disable-next-line
  function claimRewards(PowerIndexRouterInterface.StakeStatus _status, DistributeData memory _distributeData)
    external
    override
    returns (bytes memory stakeData)
  {
    uint256 tokenBefore = UNDERLYING.balanceOf(address(PI_TOKEN));
    _claimImpl();
    uint256 receivedReward = UNDERLYING.balanceOf(address(PI_TOKEN)).sub(tokenBefore);
    if (receivedReward > 0) {
      uint256 rewardsToReinvest;
      (rewardsToReinvest, stakeData) = _distributeReward(_distributeData, PI_TOKEN, UNDERLYING, receivedReward);
      _approveToStaking(rewardsToReinvest);
      _stakeImpl(rewardsToReinvest);
      return stakeData;
    }
    // Otherwise the rewards are distributed each time deposit/withdraw methods are called,
    // so no additional actions required.
    return new bytes(0);
  }

  function stake(uint256 _amount, DistributeData memory) public override returns (bytes memory result, bool claimed) {
    _stakeImpl(_amount);
    emit Stake(msg.sender, GOVERNANCE, address(UNDERLYING), _amount);
  }

  function redeem(uint256 _amount, DistributeData memory)
    external
    override
    returns (bytes memory result, bool claimed)
  {
    _redeemImpl(_amount);
    emit Redeem(msg.sender, GOVERNANCE, address(UNDERLYING), _amount);
  }

  function beforePoke(
    bytes memory _pokeData,
    DistributeData memory _distributeData,
    bool _willClaimReward
  ) external override {}

  function afterPoke(
    PowerIndexRouterInterface.StakeStatus, /*reserveStatus*/
    bool /*_rewardClaimDone*/
  ) external override returns (bytes memory) {
    return new bytes(0);
  }

  function initRouter(bytes calldata) external override {
    _approveToStaking(uint256(-1));
  }

  /*** VIEWERS ***/

  function getPendingRewards() external view returns (uint256) {
    return ITornStaking(STAKING).checkReward(address(PI_TOKEN));
  }

  /**
   * @notice Calculate pending rewards of TornStaking
   * @param _accRewardPerTorn TornStaking variable, getting by accumulatedRewardPerTorn()
   * @param _accRewardRateOnLastUpdate TornStaking variable, getting by accumulatedRewardRateOnLastUpdate()
   * @param _lockedBalance Staked amount in TornGovernance
   */
  function pendingReward(
    uint256 _accRewardPerTorn,
    uint256 _accRewardRateOnLastUpdate,
    uint256 _lockedBalance
  ) public view returns (uint256) {
    return
      _lockedBalance.mul(_accRewardPerTorn.sub(_accRewardRateOnLastUpdate)).div(RATIO_CONSTANT).add(
        ITornStaking(STAKING).accumulatedRewards(address(PI_TOKEN))
      );
  }

  /**
   * @notice Calculate forecast rewards from TornStaking
   * @param _accRewardPerTorn TornStaking variable, getting by accumulatedRewardPerTorn()
   * @param _accRewardRateOnLastUpdate TornStaking variable, getting by accumulatedRewardRateOnLastUpdate()
   * @param _reinvestDuration Duration in seconds to forecast future rewards
   * @param _lastRewardsUpdate Last stake/unstake/claim action timestamp
   * @param _lockedBalance Staked amount in TornGovernance
   */
  function forecastReward(
    uint256 _accRewardPerTorn,
    uint256 _accRewardRateOnLastUpdate,
    uint256 _reinvestDuration,
    uint256 _lastRewardsUpdate,
    uint256 _lockedBalance
  ) public view returns (uint256) {
    return
      _reinvestDuration
        .mul(_accRewardPerTorn.sub(_accRewardRateOnLastUpdate))
        .div(block.timestamp.sub(_lastRewardsUpdate))
        .mul(_lockedBalance)
        .div(RATIO_CONSTANT);
  }

  /**
   * @notice Calculate pending rewards from TornStaking and forecast
   * @param _lastClaimRewardsAt Last claim action timestamp
   * @param _lastChangeStakeAt Last stake/unstake action timestamp
   * @param _reinvestDuration Duration to forecast future rewards, based on last stake/unstake period of rewards
   */
  function getPendingAndForecastReward(
    uint256 _lastClaimRewardsAt,
    uint256 _lastChangeStakeAt,
    uint256 _reinvestDuration
  )
    public
    view
    returns (
      uint256 pending,
      uint256 forecast,
      uint256 forecastByPending
    )
  {
    uint256 lastUpdate = _lastClaimRewardsAt > _lastChangeStakeAt ? _lastClaimRewardsAt : _lastChangeStakeAt;
    uint256 lockedBalance = getUnderlyingStaked();
    uint256 accRewardPerTorn = ITornStaking(STAKING).accumulatedRewardPerTorn();
    uint256 accRewardOnLastUpdate = ITornStaking(STAKING).accumulatedRewardRateOnLastUpdate(address(PI_TOKEN));
    pending = pendingReward(accRewardPerTorn, accRewardOnLastUpdate, lockedBalance);

    return (
      pending,
      forecastReward(accRewardPerTorn, accRewardOnLastUpdate, _reinvestDuration, lastUpdate, lockedBalance),
      forecastReward(accRewardPerTorn, accRewardOnLastUpdate, _reinvestDuration, lastUpdate, pending)
    );
  }

  /**
   * @notice Checking: is pending rewards in TORN enough to cover transaction cost to reinvest
   * @param _claimParams Claim parameters, that stored in PowerIndexRouter
   * @param _lastClaimRewardsAt Last claim action timestamp
   * @param _lastChangeStakeAt Last stake/unstake action timestamp
   */
  function isClaimAvailable(
    bytes calldata _claimParams,
    uint256 _lastClaimRewardsAt,
    uint256 _lastChangeStakeAt
  ) external view virtual override returns (bool) {
    (uint256 paybackDuration, uint256 gasToReinvest) = unpackClaimParams(_claimParams);
    (, , uint256 forecastByPending) = getPendingAndForecastReward(
      _lastClaimRewardsAt,
      _lastChangeStakeAt,
      paybackDuration
    );
    return forecastByPending >= getTornUsedToReinvest(gasToReinvest, tx.gasprice);
  }

  /**
   * @notice Get reinvest transaction cost in TORN
   * @param _gasUsed Gas used for reinvest transaction
   * @param _gasPrice Gas price
   */
  function getTornUsedToReinvest(uint256 _gasUsed, uint256 _gasPrice) public view returns (uint256) {
    return calcTornOutByWethIn(_gasUsed.mul(_gasPrice));
  }

  /**
   * @notice Get Uniswap V3 TORN price ratio
   */
  function getTornPriceRatio() public view virtual returns (uint256) {
    uint32 uniswapTimePeriod = 5400;
    uint24 uniswapTornSwappingFee = 10000;
    uint24 uniswapWethSwappingFee = 0;

    return
      UniswapV3OracleHelper.getPriceRatioOfTokens(
        [address(UNDERLYING), UniswapV3OracleHelper.WETH],
        [uniswapTornSwappingFee, uniswapWethSwappingFee],
        uniswapTimePeriod
      );
  }

  /**
   * @notice Convert TORN amount to WETH amount with built in ratio
   * @param _tornAmountIn TORN amount to convert
   */
  function calcWethOutByTornIn(uint256 _tornAmountIn) external view returns (uint256) {
    return _tornAmountIn.mul(getTornPriceRatio()).div(UniswapV3OracleHelper.RATIO_DIVIDER);
  }

  /**
   * @notice Convert WETH amount to TORN amount with built in ratio
   * @param _wethAmount WETH amount to convert
   */
  function calcTornOutByWethIn(uint256 _wethAmount) public view returns (uint256) {
    return _wethAmount.mul(UniswapV3OracleHelper.RATIO_DIVIDER).div(getTornPriceRatio());
  }

  /**
   * @notice Pack claim params to bytes.
   */
  function packClaimParams(uint256 paybackDuration, uint256 gasToReinvest) external pure returns (bytes memory) {
    return abi.encode(paybackDuration, gasToReinvest);
  }

  /**
   * @notice Unpack claim params from bytes to variables.
   */
  function unpackClaimParams(bytes memory _claimParams)
    public
    pure
    returns (uint256 paybackDuration, uint256 gasToReinvest)
  {
    if (_claimParams.length == 0 || keccak256(_claimParams) == keccak256("")) {
      return (0, 0);
    }
    (paybackDuration, gasToReinvest) = abi.decode(_claimParams, (uint256, uint256));
  }

  /*** OVERRIDES ***/

  function getUnderlyingStaked() public view override returns (uint256) {
    if (STAKING == address(0)) {
      return 0;
    }
    return ITornGovernance(GOVERNANCE).lockedBalance(address(PI_TOKEN));
  }

  function _approveToStaking(uint256 _amount) internal {
    PI_TOKEN.approveUnderlying(GOVERNANCE, _amount);
  }

  function _claimImpl() internal {
    _callExternal(PI_TOKEN, STAKING, ITornStaking.getReward.selector, new bytes(0));
  }

  function _stakeImpl(uint256 _amount) internal {
    _callExternal(PI_TOKEN, GOVERNANCE, ITornGovernance.lockWithApproval.selector, abi.encode(_amount));
  }

  function _redeemImpl(uint256 _amount) internal {
    _callExternal(PI_TOKEN, GOVERNANCE, ITornGovernance.unlock.selector, abi.encode(_amount));
  }
}
