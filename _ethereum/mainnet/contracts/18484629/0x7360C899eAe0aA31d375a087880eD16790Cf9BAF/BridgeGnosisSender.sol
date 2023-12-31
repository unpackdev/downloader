// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./SafeERC20.sol";
import "./OwnableUpgradeable.sol";

import "./IBridgeGnosis.sol";
import "./ILayerZeroEndpoint.sol";

contract BridgeGnosisSender is OwnableUpgradeable {
  using SafeERC20 for IERC20;

  enum ActionType {
    DEPOSIT, 
    WITHDRAW
  }

  address public immutable token;
  address public immutable bridge;
  address public immutable layerZeroEndpoint;
  uint16 public immutable layerZeroSrcChainId;
  uint16 public immutable layerZeroDstChainId;
  address public receiver;
  uint public nonce;

  event Execute(bytes indexed messageId, address indexed user, ActionType indexed actionType, uint amount, address vault);

  constructor(
    address _token,
    address _bridge,
    address _layerZeroEndpoint,
    uint16 _layerZeroSrcChainId,
    uint16 _layerZeroDstChainId,
    address _receiver
  ) {
    token = _token;
    bridge = _bridge;
    layerZeroEndpoint = _layerZeroEndpoint;
    layerZeroSrcChainId = _layerZeroSrcChainId;
    layerZeroDstChainId = _layerZeroDstChainId;
    receiver = _receiver;
  }
  
  function execute(address _vault, uint _amount, ActionType _actionType) external payable {
    require(_amount > 0, "Amount cannot be 0");

    bytes memory messageId = abi.encode(layerZeroSrcChainId, address(this), nonce);
    (uint nativeFee,) = ILayerZeroEndpoint(layerZeroEndpoint).estimateFees(
      layerZeroDstChainId, 
      address(this),
      abi.encode(messageId, msg.sender, _actionType, _amount, _vault),
      false,
      bytes("")
    );
    
    require(msg.value >= nativeFee, "Fees are not sufficient");
    
    if(_actionType == ActionType.DEPOSIT) {
      // Transfer tokens from user to receiver
      IERC20(token).safeTransferFrom(msg.sender, address(this), _amount);

      // Transfer tokens to bridge
      IERC20(token).approve(bridge, _amount);
      IBridgeGnosis(bridge).relayTokens(receiver, _amount);
    }

    ILayerZeroEndpoint(layerZeroEndpoint).send { value: nativeFee }(
      layerZeroDstChainId,
      abi.encodePacked(receiver, address(this)),
      abi.encode(messageId, msg.sender, _actionType, _amount, _vault),
      payable(msg.sender),
      address(0x0),
      bytes("")
    );

    unchecked { ++nonce; }

    emit Execute(messageId, msg.sender, _actionType, _amount, _vault);
  }

  function setReceiver(address _newReceiver) external onlyOwner {
    receiver = _newReceiver;
  }

  receive() external payable {}
}