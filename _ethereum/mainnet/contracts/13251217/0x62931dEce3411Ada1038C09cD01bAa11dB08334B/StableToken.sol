//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.4;

import "./ERC20.sol";
import "./Ownable.sol";

contract StableToken is ERC20, Ownable {

    constructor() ERC20("mockSTABLE", "mockSTABLE") {}

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

    function _transferOwnership(address newOwner) public onlyOwner {
        transferOwnership(newOwner);
    }
}