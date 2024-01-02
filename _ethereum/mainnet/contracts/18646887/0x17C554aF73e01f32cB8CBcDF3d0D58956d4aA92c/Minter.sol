// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./Ownable.sol";

abstract contract Minter is Ownable {
    mapping(address => bool) private _minters;

    event MinterAdded(address indexed account);
    event MinterRemoved(address indexed account);

    constructor() Ownable() {}

    modifier onlyMinter() {
        require(_minters[msg.sender], "Minter: caller is not a minter");
        _;
    }

    function isMinter(address account) public view returns (bool) {
        return _minters[account];
    }

    function addMinter(address account) public virtual onlyOwner {
        require(account != address(0), "Minter: cannot add zero address as minter");
        require(!_minters[account], "Minter: account is already a minter");
        _minters[account] = true;
        emit MinterAdded(account);
    }

    function removeMinter(address account) public virtual onlyOwner {
        require(account != address(0), "Minter: cannot remove zero address as minter");
        require(_minters[account], "Minter: account is not a minter");
        _minters[account] = false;
        emit MinterRemoved(account);
    }
}
