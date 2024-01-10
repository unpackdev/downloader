// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.7 <0.9.0;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./DCAHubCompanionParameters.sol";

/// @dev All public functions are payable, so that they can be multicalled together with other payable functions when msg.value > 0
abstract contract DCAHubCompanionWTokenPositionHandler is DCAHubCompanionParameters, IDCAHubCompanionWTokenPositionHandler {
  using SafeERC20 for IERC20;

  constructor() {
    approveWTokenForHub();
  }

  /// @inheritdoc IDCAHubCompanionWTokenPositionHandler
  function depositUsingProtocolToken(
    address _from,
    address _to,
    uint256 _amount,
    uint32 _amountOfSwaps,
    uint32 _swapInterval,
    address _owner,
    IDCAPermissionManager.PermissionSet[] calldata _permissions,
    bytes calldata _miscellaneous
  ) external payable returns (uint256 _positionId) {
    if (_from != PROTOCOL_TOKEN || _to == PROTOCOL_TOKEN) revert InvalidTokens();

    _wrap(_amount);
    _positionId = _miscellaneous.length > 0
      ? hub.deposit(address(wToken), _to, _amount, _amountOfSwaps, _swapInterval, _owner, _permissions, _miscellaneous)
      : hub.deposit(address(wToken), _to, _amount, _amountOfSwaps, _swapInterval, _owner, _permissions);
  }

  /// @inheritdoc IDCAHubCompanionWTokenPositionHandler
  function withdrawSwappedUsingProtocolToken(uint256 _positionId, address payable _recipient)
    external
    payable
    checkPermission(_positionId, IDCAPermissionManager.Permission.WITHDRAW)
    returns (uint256 _swapped)
  {
    _swapped = hub.withdrawSwapped(_positionId, address(this));
    _unwrapAndSend(_swapped, _recipient);
  }

  /// @inheritdoc IDCAHubCompanionWTokenPositionHandler
  function withdrawSwappedManyUsingProtocolToken(uint256[] calldata _positionIds, address payable _recipient)
    external
    payable
    returns (uint256 _swapped)
  {
    for (uint256 i; i < _positionIds.length; i++) {
      _checkPermissionOrFail(_positionIds[i], IDCAPermissionManager.Permission.WITHDRAW);
    }
    IDCAHub.PositionSet[] memory _positionSets = new IDCAHub.PositionSet[](1);
    _positionSets[0].token = address(wToken);
    _positionSets[0].positionIds = _positionIds;
    uint256[] memory _withdrawn = hub.withdrawSwappedMany(_positionSets, address(this));
    _swapped = _withdrawn[0];
    _unwrapAndSend(_swapped, _recipient);
  }

  /// @inheritdoc IDCAHubCompanionWTokenPositionHandler
  function increasePositionUsingProtocolToken(
    uint256 _positionId,
    uint256 _amount,
    uint32 _newSwaps
  ) external payable checkPermission(_positionId, IDCAPermissionManager.Permission.INCREASE) {
    _wrap(_amount);
    hub.increasePosition(_positionId, _amount, _newSwaps);
  }

  /// @inheritdoc IDCAHubCompanionWTokenPositionHandler
  function reducePositionUsingProtocolToken(
    uint256 _positionId,
    uint256 _amount,
    uint32 _newSwaps,
    address payable _recipient
  ) external payable checkPermission(_positionId, IDCAPermissionManager.Permission.REDUCE) {
    hub.reducePosition(_positionId, _amount, _newSwaps, address(this));
    _unwrapAndSend(_amount, _recipient);
  }

  /// @inheritdoc IDCAHubCompanionWTokenPositionHandler
  function terminateUsingProtocolTokenAsFrom(
    uint256 _positionId,
    address payable _recipientUnswapped,
    address _recipientSwapped
  ) external payable checkPermission(_positionId, IDCAPermissionManager.Permission.TERMINATE) returns (uint256 _unswapped, uint256 _swapped) {
    (_unswapped, _swapped) = hub.terminate(_positionId, address(this), _recipientSwapped);
    _unwrapAndSend(_unswapped, _recipientUnswapped);
  }

  /// @inheritdoc IDCAHubCompanionWTokenPositionHandler
  function terminateUsingProtocolTokenAsTo(
    uint256 _positionId,
    address _recipientUnswapped,
    address payable _recipientSwapped
  ) external payable checkPermission(_positionId, IDCAPermissionManager.Permission.TERMINATE) returns (uint256 _unswapped, uint256 _swapped) {
    (_unswapped, _swapped) = hub.terminate(_positionId, _recipientUnswapped, address(this));
    _unwrapAndSend(_swapped, _recipientSwapped);
  }

  /// @inheritdoc IDCAHubCompanionWTokenPositionHandler
  function approveWTokenForHub() public {
    wToken.approve(address(hub), type(uint256).max);
  }

  receive() external payable {}

  function _unwrapAndSend(uint256 _amount, address payable _recipient) internal {
    if (_amount > 0) {
      // Unwrap wToken
      wToken.withdraw(_amount);

      // Send protocol token to recipient
      _recipient.transfer(_amount);
    }
  }

  function _wrap(uint256 _amount) internal {
    if (_amount > 0) {
      // Convert to wToken
      wToken.deposit{value: _amount}();
    }
  }
}
