// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0 <0.7.0;

import "./SafeMathUpgradeable.sol";
import "./SafeCastUpgradeable.sol";
import "./Initializable.sol";
import "./OwnableUpgradeable.sol";

import "./ExtendedSafeCast.sol";
import "./ExpandedTokenControllerInterface.sol";

contract RestrictedSendReceive is OwnableUpgradeable, ExpandedTokenControllerInterface {
  using SafeMathUpgradeable for uint256;
  using SafeCastUpgradeable for uint256;
  using ExtendedSafeCast for uint256;

  event ControllerSet(ExpandedTokenControllerInterface indexed controller);
  event SenderApproved(address indexed sender);
  event SenderRemoved(address indexed sender);
  event RecipientApproved(address indexed recipient);
  event RecipientRemoved(address indexed recipient);

  ExpandedTokenControllerInterface public controller;

  mapping(address => bool) internal approvedSenders;
  mapping(address => bool) internal approvedRecipients;

  /// @notice Initializes a new Token Controller
  constructor (ExpandedTokenControllerInterface _controller) public {
    __Ownable_init();
    controller = _controller;
  }

  /// @notice Set a new controller
  /// @param _controller The address of the new controller
  function setController(ExpandedTokenControllerInterface _controller) external onlyOwner {
    controller = _controller;

    emit ControllerSet(_controller);
  }

  /// @notice Approve a new sender
  /// @param _sender The address of the sender
  function approveSender(address _sender) external onlyOwner {
    approvedSenders[_sender] = true;

    emit SenderApproved(_sender);
  }

  /// @notice Remove a sender
  /// @param _sender The address of the sender
  function removeSender(address _sender) external onlyOwner {
    approvedSenders[_sender] = false;

    emit SenderRemoved(_sender);
  }

  /// @notice Approve a new recipient
  /// @param _recipient The address of the recipient
  function approveRecipient(address _recipient) external onlyOwner {
    approvedRecipients[_recipient] = true;

    emit RecipientApproved(_recipient);
  }

  /// @notice Remove a recipient
  /// @param _recipient The address of the recipient
  function removeRecipient(address _recipient) external onlyOwner {
    approvedRecipients[_recipient] = false;

    emit RecipientRemoved(_recipient);
  }

  /// @notice Allows the controller to mint tokens for a user account
  /// @dev May be overridden to provide more granular control over minting
  /// @param _user Address of the receiver of the minted tokens
  /// @param _amount Amount of tokens to mint
  function controllerMint(address _user, uint256 _amount) external override onlyOwner {
    controller.controllerMint(_user, _amount);
  }

  /// @notice Allows the controller to burn tokens from a user account
  /// @dev May be overridden to provide more granular control over burning
  /// @param _user Address of the holder account to burn tokens from
  /// @param _amount Amount of tokens to burn
  function controllerBurn(address _user, uint256 _amount) external override onlyOwner {
    controller.controllerBurn(_user, _amount);
  }

  /// @notice Allows an operator via the controller to burn tokens on behalf of a user account
  /// @dev May be overridden to provide more granular control over operator-burning
  /// @param _operator Address of the operator performing the burn action via the controller contract
  /// @param _user Address of the holder account to burn tokens from
  /// @param _amount Amount of tokens to burn
  function controllerBurnFrom(address _operator, address _user, uint256 _amount) external override onlyOwner {
    controller.controllerBurnFrom(_operator, _user, _amount);
  }

  /// @notice Called when tokens are transferred or burned.
  /// @param from The address of the sender of the token transfer
  /// @param to The address of the receiver of the token transfer.  Will be the zero address if burning.
  /// @param amount The amount of tokens transferred
  function beforeTokenTransfer(address from, address to, uint256 amount) external override {
    require(_isApprovedSender(from) || _isApprovedRecipient(to), "RestrictedSendReceive/unapproved");
  }

  /// @notice Find out if an address is an approved sender or not
  /// @notice _sender The address of the sender
  function _isApprovedSender(address _sender) internal view returns (bool) {
      return approvedSenders[_sender];
  }

  /// @notice Find out if an address is an approved sender or not
  /// @notice _sender The address of the sender
  function isApprovedSender(address _sender) external view returns (bool) {
      _isApprovedSender(_sender);
  }

  /// @notice Find out if an address is an approved recipient or not
  /// @notice _recipient The address of the recipient
  function _isApprovedRecipient(address _recipient) internal view returns (bool) {
      return approvedRecipients[_recipient];
  }

  /// @notice Find out if an address is an approved recipient or not
  /// @notice _recipient The address of the recipient
  function isApprovedRecipient(address recipient) external view returns (bool) {
      _isApprovedRecipient(recipient);
  }
}
