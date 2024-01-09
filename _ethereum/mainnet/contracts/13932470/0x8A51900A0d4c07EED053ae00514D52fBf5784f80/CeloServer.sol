// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./BaseServer.sol";

interface ICeloBridge {
  function send(address _token, uint256 _amount, uint32 _destination, bytes32 _recipient) external;
}

contract CeloServer is BaseServer {
  address public constant bridgeAddr = 0x6a39909e805A3eaDd2b61fFf61147796ca6aBB47;
  
  event BridgedSushi(address indexed minichef, uint256 indexed amount);

  constructor(uint256 _pid, address _minichef) BaseServer(_pid, _minichef) {}

  function bridge() public override {
    uint256 sushiBalance = sushi.balanceOf(address(this));

    sushi.approve(bridgeAddr, sushiBalance);
    ICeloBridge(bridgeAddr).send(address(sushi), sushiBalance, 1667591279, bytes32(uint256(uint160(minichef))));
    emit BridgedSushi(minichef, sushiBalance);
  }
}