// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./ERC20PresetMinterPauser.sol";

contract Royal is ERC20PresetMinterPauser {
    constructor() ERC20PresetMinterPauser("ROYAL", "ROYAL") {}
}
