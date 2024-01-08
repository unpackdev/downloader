// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";

contract SING is ERC20  {
    constructor() ERC20("SingIdea", "SING") {
        _mint(msg.sender, 500000000 * (10 ** uint256(decimals())));
    }
}
