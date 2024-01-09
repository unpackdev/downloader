//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.4;

import "./ERC20PresetMinterPauser.sol";
import "./TokenTimelock.sol";

contract DiamondDAO is ERC20PresetMinterPauser {
    constructor() ERC20PresetMinterPauser("DiamondDAO", "DMND") {

    }
}

