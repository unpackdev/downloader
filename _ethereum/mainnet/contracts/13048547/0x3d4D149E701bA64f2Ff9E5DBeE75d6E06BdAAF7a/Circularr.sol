// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "./ERC20.sol";
import "./Ownable.sol";

contract Circularr is ERC20, Ownable {
    constructor() ERC20("Circularr", "$CIRP") {
        return;
    }

    function mint(address receiver, uint256 amount) external onlyOwner returns (bool success) {
        _mint(receiver, amount);
        return true;
    }

    function burn(uint256 amount) external returns (bool success) {
        _burn(msg.sender, amount);
        return true;
    }
}
