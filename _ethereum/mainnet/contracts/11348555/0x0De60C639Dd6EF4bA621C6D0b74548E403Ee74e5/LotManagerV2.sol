// SPDX-License-Identifier: MIT

pragma solidity >=0.6.8;

import "./SafeMath.sol";

import "./ERC20.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";

import "./ILotManagerV2.sol";
import "./IWETH9.sol";

import "./Governable.sol";
import "./Manageable.sol";
import "./CollectableDust.sol";

import "./LotManagerMetadata.sol";
import "./LotManagerV2ProtocolParameters.sol";
import "./LotManagerV2LotsHandler.sol";
import "./LotManagerV2RewardsHandler.sol";
import "./LotManagerV2Migrable.sol";
import "./LotManagerV2Unwindable.sol";

contract LotManagerV2 is
  Governable,
  Manageable,
  CollectableDust,
  LotManagerMetadata,
  LotManagerV2ProtocolParameters,
  LotManagerV2LotsHandler,
  LotManagerV2RewardsHandler,
  LotManagerV2Migrable,
  LotManagerV2Unwindable,
  ILotManagerV2 {

  constructor(
    address _governor,
    address _manager,
    uint256 _performanceFee,
    address _zTreasury,
    address _pool,
    address _weth,
    address _wbtc,
    address[2] memory _hegicStakings
  ) public
    Governable(_governor)
    Manageable(_manager)
    CollectableDust()
    LotManagerMetadata()
    LotManagerV2ProtocolParameters(
      _performanceFee,
      _zTreasury,
      _pool,
      _weth,
      _wbtc,
      _hegicStakings[0],
      _hegicStakings[1])
    LotManagerV2LotsHandler()
    LotManagerV2RewardsHandler()
    LotManagerV2Migrable()
    LotManagerV2Unwindable() {
    _addProtocolToken(_pool);
    _addProtocolToken(address(token));
    _addProtocolToken(_weth);
    _addProtocolToken(_wbtc);
    _addProtocolToken(_hegicStakings[0]);
    _addProtocolToken(_hegicStakings[1]);
  }

  // Modifiers
  modifier onlyManagerOrPool {
    require(msg.sender == address(pool) || msg.sender == manager, 'LotManagerV2::only-manager-or-pool');
    _;
  }

  modifier onlyPool {
    require(msg.sender == address(pool), 'LotManagerV2::only-pool');
    _;
  }

  // Unwind
  function unwind(uint256 _amount) external override onlyPool returns (uint256 _total) {
    return _unwind(_amount);
  }

  // Rewards handler
  function claimRewards() external override onlyManagerOrPool returns (uint256 _totalRewards) {
    return _claimRewards();
  }

  // Lot Handler
  function buyLots(uint256 _ethLots, uint256 _wbtcLots) external override onlyPool returns (bool) {
    return _buyLots(_ethLots, _wbtcLots);
  }

  function sellLots(uint256 _ethLots, uint256 _wbtcLots) external override onlyGovernor returns (bool) {
    return _sellLots(_ethLots, _wbtcLots);
  }

  function rebalanceLots(uint256 _ethLots, uint256 _wbtcLots) external override onlyManagerOrPool returns (bool) {
    return _rebalanceLots(_ethLots, _wbtcLots);
  }

  // Protocol Parameters
  function setPerformanceFee(uint256 _peformanceFee) external override onlyGovernor {
    _setPerformanceFee(_peformanceFee);
  }

  function setZTreasury(address _zTreasury) external override onlyGovernor {
    _setZTreasury(_zTreasury);
  }

  function setPool(address _pool) external override onlyGovernor {
    _removeProtocolToken(address(pool));
    _removeProtocolToken(address(token));
    _setPool(_pool);
    _addProtocolToken(_pool);
    _addProtocolToken(address(token));
  }

  function setWETH(address _weth) external override onlyGovernor {
    _removeProtocolToken(weth);
    _addProtocolToken(_weth);
    _setWETH(_weth);
  }

  function setWBTC(address _wbtc) external override onlyGovernor {
    _removeProtocolToken(wbtc);
    _addProtocolToken(_wbtc);
    _setWBTC(_wbtc);
  }

  function setHegicStaking(
    address _hegicStakingETH, 
    address _hegicStakingWBTC
  ) external override onlyGovernor {
    if (address(hegicStakingETH) != _hegicStakingETH) {
      _removeProtocolToken(address(hegicStakingETH));
      _addProtocolToken(_hegicStakingETH);
    }
    if (address(hegicStakingWBTC) != _hegicStakingWBTC) {
      _removeProtocolToken(address(hegicStakingWBTC));
      _addProtocolToken(_hegicStakingWBTC);
    }
    _setHegicStaking(
      _hegicStakingETH,
      _hegicStakingWBTC
    );
  }

  // Migrable
  function migrate(address _newLotManager) external override virtual onlyGovernor {
    _migrate(_newLotManager);
  }

  // Governable
  function setPendingGovernor(address _pendingGovernor) external override onlyGovernor {
    _setPendingGovernor(_pendingGovernor);
  }

  function acceptGovernor() external override onlyPendingGovernor {
    _acceptGovernor();
  }

  // Manageable
  function setPendingManager(address _pendingManager) external override onlyManager {
    _setPendingManager(_pendingManager);
  }

  function acceptManager() external override onlyPendingManager {
    _acceptManager();
  }

  // Collectable Dust
  function sendDust(
    address _to,
    address _token,
    uint256 _amount
  ) external override onlyGovernor {
    _sendDust(_to, _token, _amount);
  }
}
