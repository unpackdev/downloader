// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.7 <0.9.0;

import "./IDCAHubCompanion.sol";
import "./Governable.sol";

abstract contract DCAHubCompanionParameters is Governable, IDCAHubCompanionParameters {
  /// @inheritdoc IDCAHubCompanionParameters
  IDCAHub public immutable hub;
  /// @inheritdoc IDCAHubCompanionParameters
  IDCAPermissionManager public immutable permissionManager;
  /// @inheritdoc IDCAHubCompanionParameters
  IWrappedProtocolToken public immutable wToken;
  /// @inheritdoc IDCAHubCompanionParameters
  address public constant PROTOCOL_TOKEN = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
  /// @inheritdoc IDCAHubCompanionParameters
  mapping(address => bool) public tokenHasApprovalIssue;

  constructor(
    IDCAHub _hub,
    IDCAPermissionManager _permissionManager,
    IWrappedProtocolToken _wToken,
    address _governor
  ) Governable(_governor) {
    if (address(_hub) == address(0) || address(_permissionManager) == address(0) || address(_wToken) == address(0))
      revert IDCAHubCompanion.ZeroAddress();
    hub = _hub;
    wToken = _wToken;
    permissionManager = _permissionManager;
  }

  /// @inheritdoc IDCAHubCompanionParameters
  function setTokensWithApprovalIssues(address[] calldata _addresses, bool[] calldata _hasIssue) external onlyGovernor {
    if (_addresses.length != _hasIssue.length) revert InvalidTokenApprovalParams();
    for (uint256 i; i < _addresses.length; i++) {
      tokenHasApprovalIssue[_addresses[i]] = _hasIssue[i];
    }
    emit TokenWithApprovalIssuesSet(_addresses, _hasIssue);
  }

  function _checkPermissionOrFail(uint256 _positionId, IDCAPermissionManager.Permission _permission) internal view {
    if (!permissionManager.hasPermission(_positionId, msg.sender, _permission)) revert IDCAHubCompanion.UnauthorizedCaller();
  }

  function _approveHub(address _from, uint256 _amount) internal {
    // If the token we are going to approve doesn't have the approval issue we see in USDT, we will approve 1 extra.
    // We are doing that so that the allowance isn't fully spent, and the next approve is cheaper.
    IERC20(_from).approve(address(hub), tokenHasApprovalIssue[_from] ? _amount : _amount + 1);
  }

  modifier checkPermission(uint256 _positionId, IDCAPermissionManager.Permission _permission) {
    _checkPermissionOrFail(_positionId, _permission);
    _;
  }
}
