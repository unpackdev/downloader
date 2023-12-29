// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Diamond.sol";
import "./ERC20MetadataStorage.sol";

contract MagicProxy is Diamond {
    constructor() {
        ERC20MetadataStorage.Layout storage l = ERC20MetadataStorage.layout();
        l.name = 'MAGIC';
        l.symbol = 'MAGIC';
    }
}
