// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./ERC20.sol";
import "./Ownable.sol";

contract TestERC20_SIMPLE is Ownable, ERC20 {
    // test for verification of contract
    constructor(
        string memory name,
        string memory symbol
    )ERC20(name, symbol){}

    function mint(uint amount) external onlyOwner {
        _mint(msg.sender, amount);
    }
}
