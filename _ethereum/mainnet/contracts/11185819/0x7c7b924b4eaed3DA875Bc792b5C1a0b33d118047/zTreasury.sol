// SPDX-License-Identifier: MIT

pragma solidity >=0.6.8;

import "./IERC20.sol";
import "./SafeERC20.sol";

import "./IZTreasury.sol";

import "./Governable.sol";
import "./CollectableDust.sol";

import "./zTreasuryProtocolParameters.sol";

contract zTreasury is 
  Governable, 
  CollectableDust,
  zTreasuryProtocolParameters, 
  IZTreasury {

  using SafeERC20 for IERC20;

  uint256 public override lastEarningsDistribution = 0;
  uint256 public override totalEarningsDistributed = 0;
  
  constructor(
    address _governor,
    address _zGov,
    address _maintainer,
    address _zToken,
    uint256 _maintainerShare,
    uint256 _governanceShare
  ) public 
    zTreasuryProtocolParameters(
      _zGov, 
      _maintainer, 
      _zToken,
      _maintainerShare,
      _governanceShare
    )
    CollectableDust()
    Governable(_governor) { // governor = timelock
    
    _addProtocolToken(_zToken);
  }
  
  function distributeEarnings() external override {

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

  function setMaintainer(address _maintainer) external override onlyGovernor {
    _setMaintainer(_maintainer);
  }

  function setZToken(address _zToken) external override onlyGovernor {
    require(address(zToken) != _zToken, 'zTreasury::setZToken::same-ztoken');
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

  // Collectable Dust
  function sendDust(
    address _to,
    address _token,
    uint256 _amount
  ) external override onlyGovernor {
    _sendDust(_to, _token, _amount);
  }
}