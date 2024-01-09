// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

//              _____
//     ___..--""      `.
//_..-'               ,'
//                  ,'
//   (|\          ,'
//      ________,'
//   ,.`/`./\/`/
//  /-'
//   `',^/\/\
//_________,'
//

// SSS

import "./ERC20.sol";

contract H20Token is ERC20 {
  constructor(string memory name, string memory symbol, uint256 supply) ERC20(name, symbol) {
    _mint(msg.sender, supply);
  }
}
