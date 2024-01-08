// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./MintableBaseToken.sol";

contract GMX is MintableBaseToken {
    constructor() public MintableBaseToken("GMX", "GMX", 0) {
    }
}
