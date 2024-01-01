// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./SafeERC20.sol";
import "./Ownable.sol";

import "./IBridgeGnosis.sol";
import "./ILayerZeroEndpoint.sol";

contract BridgeGnosisSender is Ownable {
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
  address public keeper;

  uint public gasClaim;
  uint public nonce;

  event Execute(uint indexed messageId, address indexed user, ActionType indexed actionType, uint amount, address vault);

  constructor(
    address _token,
    address _bridge,
    address _layerZeroEndpoint,
    uint16 _layerZeroSrcChainId,
    uint16 _layerZeroDstChainId,
    address _receiver,
    address _keeper,
    uint _gasClaim
  ) {
    token = _token;
    bridge = _bridge;
    layerZeroEndpoint = _layerZeroEndpoint;
    layerZeroSrcChainId = _layerZeroSrcChainId;
    layerZeroDstChainId = _layerZeroDstChainId;
    receiver = _receiver;
    keeper = _keeper;
    gasClaim = _gasClaim;
  }
  
  function execute(address _vault, uint _amount, ActionType _actionType) external payable {
    require(_amount > 0, "Amount cannot be 0");

    (uint nativeFee,) = ILayerZeroEndpoint(layerZeroEndpoint).estimateFees(
      layerZeroDstChainId, 
      address(this),
      abi.encode(nonce, msg.sender, _actionType, _amount, _vault),
      false,
      bytes("")
    );
    
    if(_actionType == ActionType.DEPOSIT) {
      require(msg.value >= nativeFee, "Funds should cover fee");

      // Transfer tokens from user to receiver
      IERC20(token).safeTransferFrom(msg.sender, address(this), _amount);

      // Transfer tokens to bridge
      IERC20(token).approve(bridge, _amount);
      IBridgeGnosis(bridge).relayTokens(receiver, _amount);
    } else if(_actionType == ActionType.WITHDRAW) {
      // User must cover the cost to claim
      uint valueForClaim = gasClaim * tx.gasprice;
      require(msg.value >= valueForClaim + nativeFee, "Funds should cover fee and claim");

      // Send value to Keeper
      payable(keeper).transfer(valueForClaim);

      // Send excess back to user
      payable(msg.sender).transfer(msg.value - valueForClaim - nativeFee);
    }

    ILayerZeroEndpoint(layerZeroEndpoint).send { value: nativeFee }(
      layerZeroDstChainId,
      abi.encodePacked(receiver, address(this)),
      abi.encode(nonce, msg.sender, _actionType, _amount, _vault),
      payable(msg.sender),
      address(0x0),
      bytes("")
    );


    emit Execute(nonce, msg.sender, _actionType, _amount, _vault);
    
    unchecked { ++nonce; }
  }

  function setReceiver(address _newReceiver) external onlyOwner {
    receiver = _newReceiver;
  }

  function setKeeper(address _newKeeper) external onlyOwner {
    keeper = _newKeeper;
  }

  function setGasClaim(uint _newGasClaim) external onlyOwner {
    gasClaim = _newGasClaim;
  }

  receive() external payable {}
}