// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./Ownable.sol";

contract FomoToken is ERC20, Ownable {
    constructor(address holder) ERC20("Fomoverse Token", "FOMO") {
        // Initial total supply: 696,969,696,969 (696b)
        _mint(holder, 696969696969 * 10 ** uint(decimals()));

        transferOwnership(holder);
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }
}
