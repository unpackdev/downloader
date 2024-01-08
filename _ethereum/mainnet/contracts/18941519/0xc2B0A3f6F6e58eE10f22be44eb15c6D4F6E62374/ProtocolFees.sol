// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
pragma abicoder v2;

import "./Ownable.sol";
import "./IProtocolFees.sol";

contract ProtocolFees is IProtocolFees, Ownable {
  uint256 public constant override DEN = 10000;

  uint256 public override yieldAdmin;
  uint256 public override yieldBurn;

  function setYieldAdmin(uint256 _yieldAdmin) external onlyOwner {
    require(_yieldAdmin <= (DEN * 20) / 100, 'lte20%');
    yieldAdmin = _yieldAdmin;
    emit SetYieldAdmin(_yieldAdmin);
  }

  function setYieldBurn(uint256 _yieldBurn) external onlyOwner {
    require(_yieldBurn <= (DEN * 20) / 100, 'lte20%');
    yieldBurn = _yieldBurn;
    emit SetYieldBurn(_yieldBurn);
  }
}
