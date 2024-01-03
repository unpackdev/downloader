// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "./ERC20.sol";
import "./ERC20PresetMinterPauser.sol";

contract Moony20 is ERC20PresetMinterPauser {
    constructor() public ERC20PresetMinterPauser("Moon20", "Moony") {}
}
