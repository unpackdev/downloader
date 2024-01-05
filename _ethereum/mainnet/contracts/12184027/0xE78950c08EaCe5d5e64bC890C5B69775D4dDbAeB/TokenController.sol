// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0 <0.7.0;

import "./SafeMathUpgradeable.sol";
import "./SafeCastUpgradeable.sol";
import "./Initializable.sol";
import "./OwnableUpgradeable.sol";

import "./ExtendedSafeCast.sol";
import "./TokenControllerInterface.sol";
import "./ControlledTokenInterface.sol";

contract TokenController is OwnableUpgradeable, TokenControllerInterface {
  using SafeMathUpgradeable for uint256;
  using SafeCastUpgradeable for uint256;
  using ExtendedSafeCast for uint256;

  event ControllerSet(TokenControllerInterface indexed controller);
  event ControlledTokenSet(ControlledTokenInterface indexed controlledToken);

  TokenControllerInterface public controller;
  ControlledTokenInterface public controlledToken;

  /// @notice Initializes a new Token Controller
  constructor () public {
    __Ownable_init();
  }

  /// @notice Set a new controller
  /// @param _controller The address of the new controller
  function setController(TokenControllerInterface _controller) external onlyOwner {
    controller = _controller;

    emit ControllerSet(_controller);
  }

  /// @notice Set a new controlled token
  /// @param _controlledToken The address of the new controlled token
  function setControlledToken(ControlledTokenInterface _controlledToken) external onlyOwner {
    controlledToken = _controlledToken;

    emit ControlledTokenSet(_controlledToken);
  }

  /// @notice Allows the controller to mint tokens for a user account
  /// @dev May be overridden to provide more granular control over minting
  /// @param _user Address of the receiver of the minted tokens
  /// @param _amount Amount of tokens to mint
  function controllerMint(address _user, uint256 _amount) external onlyController {
    controlledToken.controllerMint(_user, _amount);
  }

  /// @notice Allows the controller to burn tokens from a user account
  /// @dev May be overridden to provide more granular control over burning
  /// @param _user Address of the holder account to burn tokens from
  /// @param _amount Amount of tokens to burn
  function controllerBurn(address _user, uint256 _amount) external onlyController {
    controlledToken.controllerBurn(_user, _amount);
  }

  /// @notice Allows an operator via the controller to burn tokens on behalf of a user account
  /// @dev May be overridden to provide more granular control over operator-burning
  /// @param _operator Address of the operator performing the burn action via the controller contract
  /// @param _user Address of the holder account to burn tokens from
  /// @param _amount Amount of tokens to burn
  function controllerBurnFrom(address _operator, address _user, uint256 _amount) external onlyController {
    controlledToken.controllerBurnFrom(_operator, _user, _amount);
  }

  /// @notice Called when tokens are transferred or burned.
  /// @param from The address of the sender of the token transfer
  /// @param to The address of the receiver of the token transfer.  Will be the zero address if burning.
  /// @param amount The amount of tokens transferred
  function beforeTokenTransfer(address from, address to, uint256 amount) external override {
    if (address(controller) != address(0)) {
      controller.beforeTokenTransfer(from, to, amount);
    }
  }

  /// @dev Function modifier to ensure that the caller is the controller contract
  modifier onlyController {
    require(msg.sender == address(controller), "TokenController/only-controller");
    _;
  }
}
