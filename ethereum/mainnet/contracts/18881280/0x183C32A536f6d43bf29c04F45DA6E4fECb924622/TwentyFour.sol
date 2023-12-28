// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./Ownable.sol";

contract TwentyFour is Ownable, ERC20 {
  
    constructor(uint256 _totalSupply) ERC20("TwentyFour", "2400") {
        _mint(msg.sender, _totalSupply);
    }

    function burn(uint256 value) external {
        _burn(msg.sender, value);
    }
}
