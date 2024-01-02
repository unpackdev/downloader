// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./Ownable.sol";

contract XAUG is ERC20, Ownable {
    constructor() ERC20("XAUG", "XAUg") {
        _mint(msg.sender, 2 * (10**18)); // Total Supply: 2 with 18 decimals
    }

    function mint(address account, uint256 amount) external onlyOwner {
        _mint(account, amount);
    }

    function burn(uint256 amount) external {
            _burn(msg.sender, amount);
    }
}
