// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
pragma abicoder v2;

import "./Ownable.sol";
import "./IProtocolFees.sol";
import "./IProtocolFeeRouter.sol";

contract ProtocolFeeRouter is IProtocolFeeRouter, Ownable {
  IProtocolFees public override protocolFees;

  constructor(IProtocolFees _fees) {
    protocolFees = _fees;
  }

  function setProtocolFees(IProtocolFees _protocolFees) external onlyOwner {
    protocolFees = _protocolFees;
  }
}
