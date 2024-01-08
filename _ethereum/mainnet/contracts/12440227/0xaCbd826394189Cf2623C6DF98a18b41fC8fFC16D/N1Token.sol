// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC20Burnable.sol";

contract N1Token is Ownable, ERC20Burnable {

    constructor(address wallet) Ownable() ERC20("NFTify","N1") {
        _mint(wallet, (2 * (10 ** 8)) * (10 ** 18));
        transferOwnership(wallet);
    }
}
