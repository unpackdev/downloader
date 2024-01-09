// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./BaseServer.sol";

interface IPolygonBridge {
  function depositFor(address user, address token, bytes calldata depositData) external;
}

contract PolygonServer is BaseServer {
  address public constant bridgeAddr = 0xA0c68C638235ee32657e8f720a23ceC1bFc77C77;
  address public constant polygonErcBridge = 0x40ec5B33f54e0E8A33A975908C5BA1c14e5BbbDf;

  event BridgedSushi(address indexed minichef, uint256 indexed amount);

  constructor(uint256 _pid, address _minichef) BaseServer(_pid, _minichef) {}

  function bridge() public override {
    uint256 sushiBalance = sushi.balanceOf(address(this));

    sushi.approve(address(polygonErcBridge), sushiBalance);
    IPolygonBridge(bridgeAddr).depositFor(minichef, address(sushi), toBytes(sushiBalance));
    
    emit BridgedSushi(minichef, sushiBalance);
  }

  function toBytes(uint256 x) internal pure returns (bytes memory b) {
    b = new bytes(32);
    assembly { mstore(add(b, 32), x) }
}
}