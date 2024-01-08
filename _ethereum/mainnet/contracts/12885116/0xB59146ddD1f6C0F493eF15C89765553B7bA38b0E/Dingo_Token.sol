// SPDX-License-Identifier: GPL-3.0



pragma solidity ^0.6.8;

import "./ERC20.sol";
import "./Ownable.sol";

contract Dingo is ERC20, Ownable {
    constructor() ERC20("Dingo", "Dingo") public {
      
    }

    function mint(address to, uint256 amount) public onlyOwner  {
        _mint(to, amount);
    }

    function burn(uint256 _value) public {
        _burn(msg.sender, _value);
    }
}