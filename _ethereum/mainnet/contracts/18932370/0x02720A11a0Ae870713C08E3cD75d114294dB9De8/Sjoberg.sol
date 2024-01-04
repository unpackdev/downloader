// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./Ownable.sol";

contract SjobergToken is Ownable, ERC20 {
  
    constructor(uint256 _totalSupply) ERC20("Johanna Sjoberg", "Sjoberg") {
        _mint(msg.sender, _totalSupply * 10 ** 18);
    }

    function burn(uint256 value) external {
        _burn(msg.sender, value);
    }
}
