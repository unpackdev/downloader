// SPDX-License-Identifier: MIT

import "./ERC20.sol";
import "./Ownable.sol";
pragma solidity ^0.8.0;

contract Sandeep is ERC20, Ownable {
    constructor() ERC20("Sandeep", "DEEP") {
        _mint(msg.sender, 1000000000 * 10 ** decimals());
    }

    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
    }
}
