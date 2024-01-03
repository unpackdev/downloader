// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "./ShifterERC20Mock.sol";

contract ShifterMock {
  address public token;
  uint256 constant BIPS_DENOMINATOR = 10000;
  uint256 constant FEE = 5000;
  constructor() public {
    token = address(new ShifterERC20Mock());
  }
  function mint(bytes32 /* pHash */, uint256 amount , bytes32 /* nHash */, bytes memory /* darknode signature */) public returns (uint256) {
    ShifterERC20Mock(token).mint(msg.sender, amount / 2);
    return amount *FEE / BIPS_DENOMINATOR;
  }
  function mintFee() public pure returns (uint256) {
    return FEE;
  }
}
    
