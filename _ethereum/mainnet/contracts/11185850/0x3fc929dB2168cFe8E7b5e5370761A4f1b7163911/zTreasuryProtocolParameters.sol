// SPDX-License-Identifier: MIT

pragma solidity >=0.6.8;

import "./SafeMath.sol";
import "./IERC20.sol";

import "./IZTreasuryProtocolParameters.sol";

abstract
contract zTreasuryProtocolParameters is IZTreasuryProtocolParameters {
  using SafeMath for uint256;
  
  uint256 public constant override SHARES_PRECISION = 10000;
  uint256 public constant override MAX_MAINTAINER_SHARE = 25 * SHARES_PRECISION;

  IERC20 public override zToken; // zhegic
  zGovernance public override zGov; // zgov

  address public override maintainer;

  uint256 public override maintainerShare;
  uint256 public override governanceShare;
  
  constructor(
    address _zGov,
    address _maintainer,
    address _zToken,
    uint256 _maintainerShare,
    uint256 _governanceShare
  ) public {
    _setZGov(_zGov);
    _setMaintainer(_maintainer);
    _setZToken(_zToken);
    _setShares(_maintainerShare, _governanceShare);
  }
  
  function _setZGov(address _zGov) internal {
    require(_zGov != address(0), 'zTreasuryProtocolParameters::_setZGov::no-zero-address');
    zGov = zGovernance(_zGov);
    emit ZGovSet(_zGov);
  }

  function _setMaintainer(address _maintainer) internal {
    require(_maintainer != address(0), 'zTreasuryProtocolParameters::_setMaintainer::no-zero-address');
    maintainer = _maintainer;
    emit MaintainerSet(_maintainer);
  }

  function _setZToken(address _zToken) internal {
    require(_zToken != address(0), 'zTreasuryProtocolParameters::_setZToken::no-zero-address');
    zToken = IERC20(_zToken);
    emit ZTokenSet(_zToken);
  }

  function _setShares(uint256 _maintainerShare, uint256 _governanceShare) internal {
    require(_maintainerShare.add(_governanceShare) == SHARES_PRECISION.mul(100), 'zTreasuryProtocolParameters::_setShares::not-100-percent');
    require(_maintainerShare <= MAX_MAINTAINER_SHARE, 'zTreasuryProtocolParameters::_setShares::exceeds-max-mantainer-share');
    maintainerShare = _maintainerShare;
    governanceShare = _governanceShare;
    emit SharesSet(_maintainerShare, _governanceShare);
  }
}