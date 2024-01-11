// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;


import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./Ownable.sol";

/// @custom:security-contact tech@noox.world
contract PreNoox is ERC20, ERC20Burnable, Ownable {

    mapping(address => bool) private _whitelist;

    constructor() ERC20("preNOOX", "PRENOOX") {}

    function mint(address to, uint256 amount) public onlyOwner {
        require(isWhitelisted(to), "mint: address not whitelisted");
        _mint(to, amount);
    }

    function addWhitelist(address _address) public onlyOwner {
        _whitelist[_address] = true;
    }

    function removeWhitelist(address _address) public onlyOwner {
        _whitelist[_address] = false;
    }

    function isWhitelisted(address _address) public view returns (bool) {
        return _whitelist[_address];
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal override {
        super._beforeTokenTransfer(from, to, amount);
        require(
            (isWhitelisted(from)) || (from == address(0) && isWhitelisted(to)), 
            "transfer: not allowed"
        );
    }
}