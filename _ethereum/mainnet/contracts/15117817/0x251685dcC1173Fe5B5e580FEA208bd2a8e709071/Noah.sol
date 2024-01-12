//SPDX-License-Identifier: UNLICENSED

// Solidity files have to start with this pragma.
// It will be used by the Solidity compiler to validate its version.
pragma solidity ^0.8.9;

// We import this library to be able to use console.log
import "./console.sol";

import "./ERC20.sol";
import "./Ownable.sol";

contract Noah is ERC20, Ownable {
    constructor() ERC20("Noah", "NOAH") {}

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }
}
