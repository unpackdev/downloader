// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20Burnable.sol";
import "./Ownable.sol";

contract RainbowToken is ERC20Burnable, Ownable {
    constructor(
        string memory name,
        string memory symbol,
        uint256 initialSupply,
        address tokenManager
    ) ERC20(name, symbol) {
        _mint(tokenManager, initialSupply);
    }

    /// @notice Since this token is only used to fuse multiple Polymon into one rainbow Polymon, the mint function should ensure that there are enough
    /// tokens to create the fixed quantity of rainbow Polymon, even if tokens are accidentally burned or locked.
    function mint(uint256 amount) external onlyOwner {
        _mint(msg.sender, amount);
    }
}
