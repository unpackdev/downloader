// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./Ownable.sol";

/**
  An ode to my boy Alex, who fucking hates Crypto, here sir, 
  is a special shitstain token for ya mate!
*/
contract ShiTstain is ERC20, Ownable {
    constructor() ERC20("ShiTstain", "SHITST") {
        _mint(msg.sender, 9000000000000 * 10 ** decimals());
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }
}