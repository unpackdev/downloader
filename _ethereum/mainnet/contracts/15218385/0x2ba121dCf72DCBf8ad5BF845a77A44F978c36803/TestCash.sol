// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.15;

import "./Initializable.sol";
import "./ERC20PresetMinterPauserUpgradeable.sol";

contract TestCash is Initializable, ERC20PresetMinterPauserUpgradeable {

    constructor() {
        initialize("TestCash", "TC");
    }
}