pragma solidity 0.8.2;

import "./AnyswapV5ERC20.sol";

// SPDX-License-Identifier: ISC

contract NeuronToken is AnyswapV5ERC20 {
    constructor(address _governance) AnyswapV5ERC20("NeuronToken", "NEUR", 18, address(0x0), _governance) {
        // governance will become admin who can add and revoke roles
    }
}
