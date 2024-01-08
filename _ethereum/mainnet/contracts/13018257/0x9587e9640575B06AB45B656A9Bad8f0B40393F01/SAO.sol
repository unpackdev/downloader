//SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.6;

import "./ERC20.sol";

contract SAO is ERC20("Sator", "SAO") {
    constructor (address _issuer, uint256 _amount) {
        ERC20._mint(_issuer, _amount);
    }
}