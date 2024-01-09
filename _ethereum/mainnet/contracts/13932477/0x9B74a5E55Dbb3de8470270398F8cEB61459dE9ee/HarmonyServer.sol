// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./BaseServer.sol";

interface IHarmonyBridge {
  function lockToken(address ethTokenAddr, uint256 amount, address recipient) external;
}

contract HarmonyServer is BaseServer {
  address public constant bridgeAddr = 0x2dCCDB493827E15a5dC8f8b72147E6c4A5620857;
  
  event BridgedSushi(address indexed minichef, uint256 indexed amount);
  
  constructor(uint256 _pid, address _minichef) BaseServer(_pid, _minichef) {}

  function bridge() public override {
    uint256 sushiBalance = sushi.balanceOf(address(this));

    sushi.approve(bridgeAddr, sushiBalance);
    IHarmonyBridge(bridgeAddr).lockToken(address(sushi), sushiBalance, minichef);
    emit BridgedSushi(minichef, sushiBalance);
  }
}