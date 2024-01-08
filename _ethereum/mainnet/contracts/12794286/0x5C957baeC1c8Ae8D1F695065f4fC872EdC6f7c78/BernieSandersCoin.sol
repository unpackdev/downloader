// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";

contract BernieSandersCoin is ERC20 {
    constructor() ERC20("BernieSandersCoin", "BSC") {
        _mint(msg.sender, 1000000 * 10 ** decimals());
    }
}