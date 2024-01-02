// SPDX-License-Identifier: UNLICENSE
pragma solidity ^0.8.0;

import "./ERC20.sol";

contract Covas is ERC20 {

    address public miner;
    address public receiver;

    constructor(address vault, string memory name, string memory symbol) ERC20(name, symbol) {
        receiver = vault;
        miner = msg.sender;
        _mint(receiver, 1e27);
    }

    function mint(uint256 amount) external {
        require(msg.sender == miner, "Covas: only miner can mint");
        _mint(receiver, amount);
    }
}