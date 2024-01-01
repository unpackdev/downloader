// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "./Ownable.sol";
import "./ITokenController.sol";

abstract contract TokenController is ITokenController, Ownable {
  address public bridgeContract;

  constructor() Ownable() {}

  /**
   * @dev Reverts when the bridge contract address is not defined.
   */
  modifier checkBridge() {
    if (_msgSender() != bridgeContract) {
      revert CallerIsNotABridge();
    }
     _;
  }

  function setBridgeContract(address _bridgeContract) external override onlyOwner {
    if (_bridgeContract == address(0)) {
      revert ZeroAddressError();
    }
    bridgeContract = _bridgeContract;
  }
}
