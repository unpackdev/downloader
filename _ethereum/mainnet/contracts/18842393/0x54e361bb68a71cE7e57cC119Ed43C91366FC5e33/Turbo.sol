//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./ERC20.sol";

contract Turbo is ERC20{

    constructor(
        string memory _name,
        string memory _symbol,
        address receiver,
        uint256 volume
    ) ERC20(_name, _symbol){
        _mint(receiver, volume);
    }
}