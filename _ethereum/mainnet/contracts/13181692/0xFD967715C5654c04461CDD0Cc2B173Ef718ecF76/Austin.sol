//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./ERC20.sol";

/**
 * @title Austin
 * @dev Simple ERC20 Token where all tokens are pre-assigned to creator
 */
contract Austin is ERC20 {

    /**
     * @dev Constructor that gives msg.sender all of existing tokens.
     */
    constructor() ERC20("Austin", "AUSTIN") {
        _mint(msg.sender, 10000000 * (10 ** uint256(decimals())));
    }
}
