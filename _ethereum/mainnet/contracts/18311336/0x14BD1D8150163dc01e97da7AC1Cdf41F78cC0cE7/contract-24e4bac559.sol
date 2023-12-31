// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./ERC20.sol";

contract METABROKER is ERC20 {
    constructor() ERC20("METABROKER", "MAK") {
        _mint(msg.sender, 100000000 * 10 ** decimals());
    }
}
