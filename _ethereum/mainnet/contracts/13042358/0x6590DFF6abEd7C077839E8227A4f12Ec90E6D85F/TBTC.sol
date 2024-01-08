// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "./ERC20WithPermit.sol";
import "./MisfundRecovery.sol";

contract TBTC is ERC20WithPermit, MisfundRecovery {
    constructor() ERC20WithPermit("tBTC v2", "tBTC") {}
}
