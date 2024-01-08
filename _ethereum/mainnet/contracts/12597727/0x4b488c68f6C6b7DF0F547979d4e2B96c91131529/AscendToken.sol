// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

import "./ERC20PresetMinterPauser.sol";

contract AscendToken is ERC20PresetMinterPauser {
    uint256 supply = 399999999 * 10**18;
    constructor(string memory name, string memory symbol) ERC20PresetMinterPauser(name, symbol) {
        _mint(_msgSender(), supply);
    }
}