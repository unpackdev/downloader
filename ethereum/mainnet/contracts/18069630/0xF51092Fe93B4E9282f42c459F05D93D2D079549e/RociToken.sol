// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC20.sol";

contract RociToken is ERC20 {
    /**
     * @dev Constructor.
     */
    constructor() ERC20("RociFi", "ROCI") {
        _mint(msg.sender, 1000000000 ether);
    }
}
