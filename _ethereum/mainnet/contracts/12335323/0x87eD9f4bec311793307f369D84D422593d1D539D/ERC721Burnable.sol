// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Operatable.sol";

abstract contract ERC721Burnable is ERC721, Operatable {
    using Address for address;
    using Roles for Roles.Role;
    Roles.Role private burners;

    modifier onlyBurner() {
        require(isBurner(msg.sender), "Must be burner");
        _;
    }

    event BurnerAdded(address indexed account);
    event BurnerRemoved(address indexed account);

    constructor () {}

    function isBurner(address account) public view returns (bool) {
        return burners.has(account);
    }

    function addBurner(address account) public onlyOperator() {
        require(account.isContract(), "Burner must be contract");
        burners.add(account);
        emit BurnerAdded(account);
    }

    function removeBurner(address account) public onlyOperator() {
        burners.remove(account);
        emit BurnerRemoved(account);
    }

    function burn(uint256 tokenId) virtual public onlyBurner {
        require(_isApprovedOrOwner(msg.sender, tokenId), "ERC721Burnable: caller is not owner nor approved");
        _burn(tokenId);
    }
}
