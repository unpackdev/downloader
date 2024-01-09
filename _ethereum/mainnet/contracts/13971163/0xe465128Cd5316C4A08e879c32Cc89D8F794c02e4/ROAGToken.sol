// contracts/ROAGToken.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";

contract ROAGToken is ERC20 {
    constructor() ERC20("The Rise Of The Aztecs - Gold", "ROAG") {
        _mint(msg.sender, 270000000 * 10 ** decimals());
    }
}