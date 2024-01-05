// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.8.0;

import "./ERC20.sol";

contract WrapGovernanceToken is ERC20 {
  constructor (address _destination) public ERC20("Wrap Governance Token", "WRAP") {
    _setupDecimals(8);
    _mint(_destination, 100_000_000 * (10 ** uint256(decimals())));
  }
}
