// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./ERC20.sol";

contract Lena is ERC20 {
    constructor() ERC20("Lena", "Lena") {
        _mint(0x4e091acbF7076C3bCff637a1E53f92dBDD0DC3e0, 100_000_000e18);
    }
}
