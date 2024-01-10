// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.10;

import "./ERC20PresetMinterPauser.sol";

contract BRIX is ERC20PresetMinterPauser {
    constructor() ERC20PresetMinterPauser("BRIX Token", "BRIX") { }
}