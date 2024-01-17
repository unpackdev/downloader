// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./ERC20PresetMinterPauser.sol";

contract MMM is ERC20PresetMinterPauser {
    constructor() ERC20PresetMinterPauser("MMM", "MMM") {}
}