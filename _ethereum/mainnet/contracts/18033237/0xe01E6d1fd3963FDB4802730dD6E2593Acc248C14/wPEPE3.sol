// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";

contract WrappedPepe3 is ERC20 {
    constructor() ERC20("wPEPE3", "Wrapped Pepe 3.0") {
        uint256 tokenSupply = 10000000000 * (10**decimals());
        _mint(msg.sender, tokenSupply);
    }
}
