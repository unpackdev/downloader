// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./ERC20.sol";

contract XifraToken is ERC20 {
    constructor() ERC20("Xifra", "XFA") {
        _mint(msg.sender, 500000000 * 10**18);
    }

    function burn(uint256 _amount) external {
        _burn(msg.sender, _amount);
    }
}