// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./ERC20Burnable.sol";
import "./Ownable.sol";

contract TokenV1 is ERC20Burnable, Ownable {
    constructor() ERC20("scoot", "SCOOT") {}

    function mint(address account_, uint256 amount_) public onlyOwner {
        _mint(account_, amount_);
    }
}
