// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./Ownable.sol";

contract ERC20Token is ERC20, Ownable {
    address minter;

    constructor(string memory _name, string memory _symbol)
        ERC20(_name, _symbol) Ownable()
    {}

    modifier onlyMinter() {
        require(minter == msg.sender, "Only Minter Can Mint");
        _;
    }

    function setMinter(address newMinter) public onlyOwner {
        minter = newMinter;
    }

    function mint(address to, uint256 value) public onlyMinter returns (bool) {
        _mint(to, value);
        return true;
    }
}
