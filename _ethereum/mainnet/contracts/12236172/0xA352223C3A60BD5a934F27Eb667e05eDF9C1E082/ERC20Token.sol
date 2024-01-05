// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;

import "./ERC20.sol";

// Name: MasterBrews
// Symbol: BREW
// Decimals: 18
// Initial Supply: 1,000,000,000
// Total Supply: 1,000,000,000
// Transfer Type: Unstoppable
// Mintable: False

contract ERC20Token is ERC20 {

  constructor() public ERC20("MasterBrews", "BREW") {
    _mint(0x52195c65EaA6E10f077a74791c68519e354DBf77, 1000000000 * 1 ether);
  }
  
}
