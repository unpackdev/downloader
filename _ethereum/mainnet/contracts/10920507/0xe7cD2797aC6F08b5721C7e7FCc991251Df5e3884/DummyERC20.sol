// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "./ERC20.sol";
import "./Ownable.sol";

// Only used for testing Dubiex
contract DummyVanillaERC20 is ERC20, Ownable {
    string public constant NAME = "Dummy";
    string public constant SYMBOL = "DUMMY";

    constructor() public ERC20(NAME, SYMBOL) Ownable() {}

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }
}
