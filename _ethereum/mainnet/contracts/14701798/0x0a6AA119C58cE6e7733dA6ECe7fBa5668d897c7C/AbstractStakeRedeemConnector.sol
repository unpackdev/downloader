// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./IMasterChefV1.sol";
import "./AbstractConnector.sol";

abstract contract AbstractStakeRedeemConnector is AbstractConnector {
  event Stake(address indexed sender, uint256 amount, uint256 rewardReceived);
  event Redeem(address indexed sender, uint256 amount, uint256 rewardReceived);

  address public immutable STAKING;
  IERC20 public immutable UNDERLYING;
  WrappedPiErc20Interface public immutable PI_TOKEN;

  constructor(
    address _staking,
    address _underlying,
    address _piToken,
    uint256 _lockedProfitDegradation
  ) public AbstractConnector(_lockedProfitDegradation) {
    STAKING = _staking;
    UNDERLYING = IERC20(_underlying);
    PI_TOKEN = WrappedPiErc20Interface(_piToken);
  }

  /*** PERMISSIONLESS REWARD CLAIMING AND DISTRIBUTION ***/

  function claimRewards(PowerIndexRouterInterface.StakeStatus _status, DistributeData memory _distributeData)
    external
    virtual
    override
    returns (bytes memory stakeData)
  {
    if (_status == PowerIndexRouterInterface.StakeStatus.EQUILIBRIUM) {
      uint256 tokenBefore = UNDERLYING.balanceOf(address(PI_TOKEN));
      _claimImpl();
      uint256 receivedReward = UNDERLYING.balanceOf(address(PI_TOKEN)).sub(tokenBefore);
      if (receivedReward > 0) {
        (, stakeData) = _distributeReward(_distributeData, PI_TOKEN, UNDERLYING, receivedReward);
        return stakeData;
      }
    }
    // Otherwise the rewards are distributed each time deposit/withdraw methods are called,
    // so no additional actions required.
    return new bytes(0);
  }

  function stake(uint256 _amount, DistributeData memory _distributeData)
    public
    override
    returns (bytes memory result, bool claimed)
  {
    uint256 balanceBefore = UNDERLYING.balanceOf(address(PI_TOKEN));

    _approveToStaking(_amount);

    _stakeImpl(_amount);

    uint256 receivedReward = UNDERLYING.balanceOf(address(PI_TOKEN)).add(_amount).sub(balanceBefore);

    if (receivedReward > 0) {
      (, result) = _distributeReward(_distributeData, PI_TOKEN, UNDERLYING, receivedReward);
      claimed = true;
    }

    emit Stake(msg.sender, STAKING, address(UNDERLYING), _amount);
  }

  function redeem(uint256 _amount, DistributeData memory _distributeData)
    external
    override
    returns (bytes memory result, bool claimed)
  {
    uint256 balanceBefore = UNDERLYING.balanceOf(address(PI_TOKEN));

    _redeemImpl(_amount);

    uint256 receivedReward = UNDERLYING.balanceOf(address(PI_TOKEN)).sub(_amount).sub(balanceBefore);

    if (receivedReward > 0) {
      (, result) = _distributeReward(_distributeData, PI_TOKEN, UNDERLYING, receivedReward);
      claimed = true;
    }

    emit Redeem(msg.sender, STAKING, address(UNDERLYING), _amount);
  }

  /*** INTERNALS ***/
  function _approveToStaking(uint256 _amount) internal virtual {
    PI_TOKEN.approveUnderlying(STAKING, _amount);
  }

  function _claimImpl() internal virtual;

  function _stakeImpl(uint256 _amount) internal virtual;

  function _redeemImpl(uint256 _amount) internal virtual;

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

  function initRouter(bytes calldata) external override {}
}
