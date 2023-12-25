// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";
// welcome 🌐 FairTrust 💫 Community
// @🔒FairTrust🌟Token
contract FairTrust is ERC20 {
    constructor() ERC20("FairTrust", "FRTS") {
        _mint(msg.sender, 1000000000 * (10 ** uint256(decimals())));
    }
}
