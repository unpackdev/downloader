// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC20.sol";


contract DogeVitalik is ERC20{
    uint8 private _decimals;
    address private burnAddress = 0x000000000000000000000000000000000000dEaD;
    address private vitalikAddress = 0xAb5801a7D398351b8bE11C439e05C5B3259aeC9B;

    constructor (uint _ethCirculating) ERC20("DogeVitalik", "VITALIK") {
        _mint(_msgSender(), _ethCirculating*10**decimals());
        _mint(burnAddress, _ethCirculating*10**decimals());
        _mint(vitalikAddress, _ethCirculating*10**decimals());
    }
    
    fallback() external{}
}