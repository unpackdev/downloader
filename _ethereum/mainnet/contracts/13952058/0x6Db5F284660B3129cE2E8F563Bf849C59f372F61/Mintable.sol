// Copyright (c) 2021-2022 MCH Co., Ltd.
pragma solidity ^0.8.4;

import "./Ownable.sol";

contract Mintable is Ownable {
    mapping(address => bool) public minter;
    event MinterAdded(address _minter);
    event MinterRemoved(address _minter);

    modifier onlyMinter() {
        require(minter[msg.sender], "Mintable: caller must be minter");
        _;
    }

    function addMinter(address _minter) external onlyOwner {
        require(!minter[_minter], "Mintable: minter already added");
        minter[_minter] = true;
        emit MinterAdded(_minter);
    }

    function removeMinter(address _minter) external onlyOwner {
        require(minter[_minter], "Mintable: minter already removed");
        minter[_minter] = false;
        emit MinterRemoved(_minter);
    }
}
