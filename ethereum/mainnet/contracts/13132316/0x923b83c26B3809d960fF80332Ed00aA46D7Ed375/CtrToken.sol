// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

import "./Ownable.sol";
import "./ERC20Burnable.sol";

contract CtrToken is Ownable, ERC20Burnable {
    constructor(address wallet, uint256 totalSupply) Ownable() ERC20("Creator Chain","CTR") {
        _mint(wallet, totalSupply);
        transferOwnership(wallet);
    }
}
