// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";

contract GreenToken is ERC20 {
    constructor() ERC20("Green Token One", "GRN1") {
        _mint(0xa82cDDA842a158c54d03A62F9d9391964748706E, 728061000000000000000000);
    }
}