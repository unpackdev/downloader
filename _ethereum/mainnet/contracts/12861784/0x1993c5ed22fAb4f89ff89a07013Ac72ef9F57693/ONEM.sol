// SPDX-License-Identifier: MIT
// File: token/ONEM.sol 

pragma solidity ^0.8.6;

import "./ERC20.sol";

contract OneM is ERC20 {
    constructor() ERC20('One Moment', 'ONEM') {
         _mint(msg.sender, 10000000000 * 10 ** 18);
             }
      
    function burn(uint amount) external {
        _burn(msg.sender, amount);
    }
}