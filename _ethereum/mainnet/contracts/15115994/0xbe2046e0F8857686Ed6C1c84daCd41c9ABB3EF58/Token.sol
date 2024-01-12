// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC20.sol";

contract DevToken is ERC20 {
    constructor(uint256 _totalSupply) ERC20("Develompent Token", "DVMT") {
        _mint(_msgSender(), _totalSupply);
    }
}
