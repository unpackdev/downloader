// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./ERC20.sol";
import "./Ownable.sol";

contract SimpleToken is ERC20, Ownable {

    constructor() ERC20("Simpletoken", "SIM") {
        _mint(msg.sender, 1000000 * 10 ** decimals());
    }
}

