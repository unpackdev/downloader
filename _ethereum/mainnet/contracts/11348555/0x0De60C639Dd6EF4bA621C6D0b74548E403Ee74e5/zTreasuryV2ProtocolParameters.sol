// SPDX-License-Identifier: MIT

pragma solidity >=0.6.8;

import "./SafeMath.sol";
import "./IERC20.sol";

import "./ILotManagerMetadata.sol";
import "./IZTreasuryV2ProtocolParameters.sol";

abstract
contract zTreasuryV2ProtocolParameters is IZTreasuryV2ProtocolParameters {
  using SafeMath for uint256;
  
  uint256 public constant override SHARES_PRECISION = 10000;
  uint256 public constant override MAX_MAINTAINER_SHARE = 25 * SHARES_PRECISION;

  IERC20 public override zToken; // zhegic
  zGovernance public override zGov; // zgov

  address public override lotManager;
  address public override maintainer;

  uint256 public override maintainerShare;
  uint256 public override governanceShare;
  
  constructor(
    address _zGov,
    address _lotManager,
    address _maintainer,
    address _zToken,
    uint256 _maintainerShare,
    uint256 _governanceShare
  ) public {
    _setZGov(_zGov);
    _setLotManager(_lotManager);
    _setMaintainer(_maintainer);
    _setZToken(_zToken);
    _setShares(_maintainerShare, _governanceShare);
  }
  
  function _setZGov(address _zGov) internal {
    require(_zGov != address(0), 'zTreasuryV2ProtocolParameters::_setZGov::no-zero-address');
    zGov = zGovernance(_zGov);
    emit ZGovSet(_zGov);
  }

  function _setLotManager(address _lotManager) internal {
    require(_lotManager != address(0), 'zTreasuryV2ProtocolParameters::_setLotManager::no-zero-address');
    require(ILotManagerMetadata(_lotManager).isLotManager(), 'zTreasuryV2ProtocolParameters::_setLotManager::not-lot-manager');
    lotManager = _lotManager;
    emit LotManagerSet(_lotManager);
  }

  function _setMaintainer(address _maintainer) internal {
    require(_maintainer != address(0), 'zTreasuryV2ProtocolParameters::_setMaintainer::no-zero-address');
    maintainer = _maintainer;
    emit MaintainerSet(_maintainer);
  }

  function _setZToken(address _zToken) internal {
    require(_zToken != address(0), 'zTreasuryV2ProtocolParameters::_setZToken::no-zero-address');
    zToken = IERC20(_zToken);
    emit ZTokenSet(_zToken);
  }

  function _setShares(uint256 _maintainerShare, uint256 _governanceShare) internal {
    require(_maintainerShare.add(_governanceShare) == SHARES_PRECISION.mul(100), 'zTreasuryV2ProtocolParameters::_setShares::not-100-percent');
    require(_maintainerShare <= MAX_MAINTAINER_SHARE, 'zTreasuryV2ProtocolParameters::_setShares::exceeds-max-mantainer-share');
    maintainerShare = _maintainerShare;
    governanceShare = _governanceShare;
    emit SharesSet(_maintainerShare, _governanceShare);
  }
}