// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.18;

import "./ERC20.sol";
import "./Ownable.sol";

contract DecubateTest is ERC20("Decubate Test", "DCBT"), Ownable {
    constructor() {
        _mint(msg.sender, 1e18);
    }

    function mint(address user, uint256 amount) external onlyOwner {
        _mint(user, amount);
    }
}
