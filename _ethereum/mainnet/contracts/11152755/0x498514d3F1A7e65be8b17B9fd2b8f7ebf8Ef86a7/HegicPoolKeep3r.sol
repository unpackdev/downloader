// SPDX-License-Identifier: MIT

pragma solidity >=0.6.8;

import "./SafeMath.sol";

import "./IHegicPoolV2.sol";
import "./IHegicPoolKeep3r.sol";

import "./Governable.sol";
import "./CollectableDust.sol";

import "./Keep3rAbstract.sol";

contract HegicPoolKeep3r is Governable, CollectableDust, Keep3r, IHegicPoolKeep3r {
  using SafeMath for uint256;

  IHegicPoolV2 public HegicPool;

  constructor(
    address _keep3r,
    address _hegicPool
  ) public Governable(msg.sender) CollectableDust() Keep3r(_keep3r) {
    setHegicPool(_hegicPool);
    acceptManager();
  }

  // Setters
  function setHegicPool(address _hegicPool) public override onlyGovernor {
    require(IHegicPoolV2(_hegicPool).isHegicPool(), 'pool-keeper::set-hegic-pool:not-hegic-pool');
    HegicPool = IHegicPoolV2(_hegicPool);
    emit HegicPoolSet(_hegicPool);
  }

  function setKeep3r(address _keep3r) public override onlyGovernor {
    _setKeep3r(_keep3r);
    emit Keep3rSet(_keep3r);
  }

  // Keep3r actions
  function claimRewards() external override paysKeeper {
    uint256 _rewards = HegicPool.claimRewards();
    emit RewardsClaimedByKeeper(_rewards);
  }

  // Governor keeper bypass
  function forceClaimRewards() external override onlyGovernor {
    uint256 _rewards = HegicPool.claimRewards();
    emit ForcedClaimedRewards(_rewards);
  }

  // HegicPool Manager
  function buyLots(uint256 _eth, uint256 _wbtc) external override onlyGovernor {
    HegicPool.buyLots(_eth, _wbtc);
    emit LotsBought(_eth, _wbtc);
  }

  function setPendingManager(address _pendingManager) external override onlyGovernor {
    HegicPool.setPendingManager(_pendingManager);
    emit PendingManagerSet(_pendingManager);
  }

  function acceptManager() public override onlyGovernor {
    HegicPool.acceptManager();
    emit AcceptManager();
  }

  // Governable
  function setPendingGovernor(address _pendingGovernor) external override onlyGovernor {
    _setPendingGovernor(_pendingGovernor);
  }

  function acceptGovernor() external override onlyPendingGovernor {
    _acceptGovernor();
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