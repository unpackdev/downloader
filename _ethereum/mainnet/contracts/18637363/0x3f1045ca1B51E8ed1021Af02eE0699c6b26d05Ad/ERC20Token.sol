// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "./Ownable.sol";
import "./ERC20.sol";

contract ERC20Token is ERC20, Ownable {
    constructor(
        string memory _name,
        string memory _symbol,
        address _receiver,
        uint256 _amount
    ) ERC20(_name, _symbol) Ownable(msg.sender) {
        _mint(_receiver, _amount);
    }
}