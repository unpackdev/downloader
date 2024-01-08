// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC20.sol";

contract RabBIT is Ownable, ERC20 {

    constructor(address wallet) Ownable() ERC20("RabBIT","RIT") {
        _mint(wallet, (1 * (10 ** 9)) * (10 ** 18));
         transferOwnership(wallet);
    }
}
