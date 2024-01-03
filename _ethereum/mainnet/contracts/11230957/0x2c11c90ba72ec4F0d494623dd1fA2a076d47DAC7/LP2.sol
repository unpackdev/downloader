// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "./ERC20.sol";
import "./ERC20PresetMinterPauser.sol";

contract LP2 is ERC20PresetMinterPauser {
    // Cap at 1 million

    constructor() public ERC20PresetMinterPauser("Test20", "test20") {}
}
