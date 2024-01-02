// SPDX-License-Identifier: UNLICENSED

pragma solidity =0.8.19;

import "./ERC20Burnable.sol";

contract PlaceholderToken is ERC20Burnable {
    constructor(address receiver, uint256 totalSupply) ERC20("KEI Placeholder Token", "KPT") {
        _mint(receiver, totalSupply);
    }

    function decimals() public pure override returns (uint8) {
        return 8;
    }
}
