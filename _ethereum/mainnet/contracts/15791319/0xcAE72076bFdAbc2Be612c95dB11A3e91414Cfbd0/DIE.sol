// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

import "./ERC20PresetMinterPauser.sol";

contract DIE is ERC20PresetMinterPauser {
    constructor() ERC20PresetMinterPauser("Die in chinese", "DIE") {
    }
}
