// SPDX-License-Identifier: MIT

pragma solidity >=0.6.8;

import "./IERC20.sol";
import "./SafeERC20.sol";

import "./IZTreasuryV2.sol";

import "./Governable.sol";
import "./Manageable.sol";
import "./CollectableDust.sol";

import "./zTreasuryV2Metadata.sol";
import "./zTreasuryV2ProtocolParameters.sol";

contract zTreasuryV2 is 
  Governable, 
  Manageable,
  CollectableDust,
  zTreasuryV2Metadata,
  zTreasuryV2ProtocolParameters, 
  IZTreasuryV2 {

  using SafeERC20 for IERC20;

  uint256 public override lastEarningsDistribution = 0;
  uint256 public override totalEarningsDistributed = 0;
  
  constructor(
    address _governor,
    address _manager,
    address _zGov,
    address _lotManager,
    address _maintainer,
    address _zToken,
    uint256 _maintainerShare,
    uint256 _governanceShare,
    uint256[] memory _initialDistributionValues
  ) public 
    zTreasuryV2ProtocolParameters(
      _zGov,
      _lotManager,
      _maintainer, 
      _zToken,
      _maintainerShare,
      _governanceShare
    )
    Governable(_governor)
    Manageable(_manager)
    CollectableDust() {
      lastEarningsDistribution = _initialDistributionValues[0];
      totalEarningsDistributed = _initialDistributionValues[1];
      _addProtocolToken(_zToken);
  }

  // Modifiers
  modifier onlyManagerOrLotManager {
    require(msg.sender == manager || msg.sender == lotManager, 'zTreasuryV2::only-manager-or-lot-manager');
    _;
  }
  
  function distributeEarnings() external override onlyManagerOrLotManager {
    uint256 _balance = zToken.balanceOf(address(this));
    
    // Send zToken to maintainer
    uint256 _maintainerEarnings = _balance.mul(maintainerShare).div(SHARES_PRECISION).div(100);
    zToken.safeTransfer(maintainer, _maintainerEarnings);

    // Send zToken to zGov
    uint256 _governanceEarnings = _balance.sub(_maintainerEarnings);
    zToken.safeApprove(address(zGov), 0);
    zToken.safeApprove(address(zGov), _governanceEarnings);

    // Notify governance reward amount to distribute
    zGov.notifyRewardAmount(_governanceEarnings);

    // Set last time distributed
    lastEarningsDistribution = block.timestamp;
    totalEarningsDistributed = totalEarningsDistributed.add(_balance);

    // Emit event
    emit EarningsDistributed(_maintainerEarnings, _governanceEarnings, totalEarningsDistributed);
  }

  // zTreasuryProtocolParameters
  function setZGov(address _zGov) external override onlyGovernor {
    _setZGov(_zGov);
  }

  function setLotManager(address _lotManager) external override onlyGovernor {
    _setLotManager(_lotManager);
  }

  function setMaintainer(address _maintainer) external override onlyGovernor {
    _setMaintainer(_maintainer);
  }

  function setZToken(address _zToken) external override onlyGovernor {
    require(address(zToken) != _zToken, 'zTreasuryV2::setZToken::same-ztoken');
    _removeProtocolToken(address(zToken));
    _addProtocolToken(address(_zToken));
    _setZToken(_zToken);
  }

  function setShares(uint256 _maintainerShare, uint256 _governanceShare) external override onlyGovernor {
    _setShares(_maintainerShare, _governanceShare);
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
