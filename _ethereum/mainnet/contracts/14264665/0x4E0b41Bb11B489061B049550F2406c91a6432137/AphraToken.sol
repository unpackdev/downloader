// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "./ERC20.sol";

contract AphraToken is ERC20("Aphra Finance DAO", "APHRA", 18) {


    error NotMinter();
    event MinterChanged(address newMinter, address minter);

    address public minter;
    constructor(
    ) {
        minter = msg.sender;
        _mint(msg.sender, 0);
    }

    function setMinter(address newMinter_) external {
        if (msg.sender != minter) revert NotMinter();
        minter = newMinter_;
        emit MinterChanged(newMinter_, minter);
    }

    function mint(address account, uint amount) external returns (bool) {
        if (msg.sender != minter) revert NotMinter();
        _mint(account, amount);
        return true;
    }
}
