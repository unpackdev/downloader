// SPDX-License-Identifier: MIT






pragma solidity ^0.8.17;

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./Ownable.sol";

contract GETSBF is ERC20, ERC20Burnable, Ownable {
    constructor() ERC20("GET Sam Bankman-Fried", "GETSBF") {

          _mint(msg.sender, 110000000 * 10 ** decimals());
    }

    function burn( uint256 amount ) public override {
        _burn(msg.sender, amount);

    }
}