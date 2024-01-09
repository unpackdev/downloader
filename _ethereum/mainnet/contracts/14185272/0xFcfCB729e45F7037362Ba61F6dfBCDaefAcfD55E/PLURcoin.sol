/**
 *Submitted for verification at Etherscan.io on 2022-02-13
*/
// contracts/PLURcoin.sol
// SPDX-License-Identifier: MIT


pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./ownable.sol";

contract PLURcoin is ERC20, Ownable {
    constructor() ERC20("PLURcoin", "PLUR") {
        _mint(msg.sender, 100000000000 * 10 ** 18);
    
    }

    function burn(uint256 amount) external {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _burn(msg.sender, amount);
        
    }
}