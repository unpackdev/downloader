// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "./ShifterERC20Mock.sol";

contract ShifterMock {
  address public token;
  constructor() public {
    token = address(new ShifterERC20Mock());
  }
  function mint(bytes32 /* pHash */, uint256 amount , bytes32 /* nHash */, bytes memory /* darknode signature */) public returns (uint256) {
    ShifterERC20Mock(token).mint(msg.sender, amount);
    return amount;
  }
  function mintFee() public pure returns (uint16) {
    return 0;
  }
}
    
