//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.9;

import "./ERC20PresetMinterPauser.sol";

contract AKIR is ERC20PresetMinterPauser {
    constructor() ERC20PresetMinterPauser("Akiverse Rewards", "AKIR") {}
}
