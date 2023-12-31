// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC20.sol";

contract HormigaToken is ERC20 {
    constructor() ERC20("Hormiga Token Coin", "HTC") {
        // Total supply: 7 million
        uint256 totalSupply = 7 * (10**6) * (10**6); // 7 million tokens with 6 decimals
        _mint(msg.sender, totalSupply);
    }

    function decimals() public view virtual override returns (uint8) {
        return 6;
    }
}
