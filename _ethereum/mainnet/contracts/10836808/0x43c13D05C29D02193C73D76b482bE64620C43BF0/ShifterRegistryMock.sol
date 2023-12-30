// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "./ShifterMock.sol";

contract ShifterRegistryMock {
  mapping (address => address) public getGatewayByToken;
  address public token;
  address public shifter;
  constructor() public {
    shifter = address(new ShifterMock());
    token = ShifterMock(shifter).token();
    getGatewayByToken[token] = shifter;
  }
}
