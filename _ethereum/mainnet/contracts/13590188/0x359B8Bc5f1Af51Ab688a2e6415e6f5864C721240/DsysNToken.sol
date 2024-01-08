// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

import "./ERC20.sol";

contract EBIT is ERC20 {

    uint256 public constant MAX_SUPPLY = 2500 * 10 ** 8 * 10 ** 18;

    constructor() ERC20("EBIT COIN", "EBIT") {
        _mint(0x4BB5FD7A6CaA95A5dF1F9da5c115E147c4419442, MAX_SUPPLY);
    }

}
