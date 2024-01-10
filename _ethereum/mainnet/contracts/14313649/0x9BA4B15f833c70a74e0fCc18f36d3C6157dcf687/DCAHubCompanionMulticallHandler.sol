// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.7 <0.9.0;

import "./SafeERC20.sol";
import "./Multicall.sol";
import "./DCAHubCompanionParameters.sol";

/// @dev All public functions are payable, so that they can be multicalled together with other payable functions when msg.value > 0
abstract contract DCAHubCompanionMulticallHandler is Multicall, DCAHubCompanionParameters, IDCAHubCompanionMulticallHandler {
  using SafeERC20 for IERC20Metadata;

  /// @inheritdoc IDCAHubCompanionMulticallHandler
  function permissionPermitProxy(
    IDCAPermissionManager.PermissionSet[] calldata _permissions,
    uint256 _tokenId,
    uint256 _deadline,
    uint8 _v,
    bytes32 _r,
    bytes32 _s
  ) external payable {
    permissionManager.permissionPermit(_permissions, _tokenId, _deadline, _v, _r, _s);
  }

  /// @inheritdoc IDCAHubCompanionMulticallHandler
  function depositProxy(
    address _from,
    address _to,
    uint256 _amount,
    uint32 _amountOfSwaps,
    uint32 _swapInterval,
    address _owner,
    IDCAPermissionManager.PermissionSet[] calldata _permissions,
    bytes calldata _miscellaneous,
    bool _transferFromCaller
  ) external payable returns (uint256 _positionId) {
    _transferFromAndApprove(_from, _amount, _transferFromCaller);
    _positionId = _miscellaneous.length > 0
      ? hub.deposit(_from, _to, _amount, _amountOfSwaps, _swapInterval, _owner, _permissions, _miscellaneous)
      : hub.deposit(_from, _to, _amount, _amountOfSwaps, _swapInterval, _owner, _permissions);
  }

  /// @inheritdoc IDCAHubCompanionMulticallHandler
  function withdrawSwappedProxy(uint256 _positionId, address _recipient)
    external
    payable
    checkPermission(_positionId, IDCAPermissionManager.Permission.WITHDRAW)
    returns (uint256 _swapped)
  {
    _swapped = hub.withdrawSwapped(_positionId, _recipient);
  }

  /// @inheritdoc IDCAHubCompanionMulticallHandler
  function withdrawSwappedManyProxy(IDCAHub.PositionSet[] calldata _positions, address _recipient)
    external
    payable
    returns (uint256[] memory _withdrawn)
  {
    for (uint256 i; i < _positions.length; i++) {
      for (uint256 j; j < _positions[i].positionIds.length; j++) {
        _checkPermissionOrFail(_positions[i].positionIds[j], IDCAPermissionManager.Permission.WITHDRAW);
      }
    }
    _withdrawn = hub.withdrawSwappedMany(_positions, _recipient);
  }

  /// @inheritdoc IDCAHubCompanionMulticallHandler
  function increasePositionProxy(
    uint256 _positionId,
    uint256 _amount,
    uint32 _newSwaps,
    bool _transferFromCaller
  ) external payable checkPermission(_positionId, IDCAPermissionManager.Permission.INCREASE) {
    IERC20Metadata _from = hub.userPosition(_positionId).from;
    _transferFromAndApprove(address(_from), _amount, _transferFromCaller);
    hub.increasePosition(_positionId, _amount, _newSwaps);
  }

  /// @inheritdoc IDCAHubCompanionMulticallHandler
  function reducePositionProxy(
    uint256 _positionId,
    uint256 _amount,
    uint32 _newSwaps,
    address _recipient
  ) external payable checkPermission(_positionId, IDCAPermissionManager.Permission.REDUCE) {
    hub.reducePosition(_positionId, _amount, _newSwaps, _recipient);
  }

  /// @inheritdoc IDCAHubCompanionMulticallHandler
  function terminateProxy(
    uint256 _positionId,
    address _recipientUnswapped,
    address _recipientSwapped
  ) external payable checkPermission(_positionId, IDCAPermissionManager.Permission.TERMINATE) returns (uint256 _unswapped, uint256 _swapped) {
    (_unswapped, _swapped) = hub.terminate(_positionId, _recipientUnswapped, _recipientSwapped);
  }

  function _transferFromAndApprove(
    address _from,
    uint256 _amount,
    bool _transferFromCaller
  ) internal {
    if (_transferFromCaller) {
      IERC20Metadata(_from).safeTransferFrom(msg.sender, address(this), _amount);
    }
    _approveHub(address(_from), _amount);
  }
}
