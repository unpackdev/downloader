pragma solidity ^0.7.4;

import "./ERC20Burnable.sol";
import "./ERC20.sol";

contract ERC20Mock is ERC20, ERC20Burnable {
    constructor(address initialAccount, uint256 initialBalance) ERC20("MockToken", "MCT") {
        _mint(initialAccount, initialBalance);
    }
}
