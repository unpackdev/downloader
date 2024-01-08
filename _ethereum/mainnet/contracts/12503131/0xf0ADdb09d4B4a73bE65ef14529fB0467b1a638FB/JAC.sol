// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC20.sol";

contract JAC is Ownable, ERC20 {

    constructor(address wallet) Ownable() ERC20("Japan All Culture+","JAC+") {
        _mint(wallet, (2 * (10 ** 9)) * (10 ** 18));
         transferOwnership(wallet);
    }
}
