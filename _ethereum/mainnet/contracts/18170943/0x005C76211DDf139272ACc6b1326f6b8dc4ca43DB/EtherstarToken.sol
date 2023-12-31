// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC20.sol";

contract EtherstarToken is ERC20 {
    constructor() ERC20("Etherstar Token", "ETST") {
        _mint(msg.sender, 10_000_000 * 10 ** decimals());
    }
}
