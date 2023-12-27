// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract Ownable {
    address private mainOwner;
    mapping(address => bool) private owners;

    event SetMainOwner(address indexed previousOwner, address indexed newOwner);
    event AddedOwner(address indexed newOwner);
    event RemovedOwner(address indexed removedOwner);

    constructor() {
        owners[msg.sender] = true;
        setMainOwner(msg.sender);
    }

    function owner() public view returns (address) {
        return mainOwner;
    }

    modifier onlyOwner() {
        require(owners[msg.sender]);
        _;
    }

    function isOwner(address _address) public view returns (bool) {
        return owners[_address];
    }

    function setMainOwner(address _newOwner) public onlyOwner {
        require(_newOwner != address(0), "setMainOwner: new owner is the zero address");

        require(isOwner(_newOwner) == true, "setMainOwner: new owner is not owner");

        emit SetMainOwner(mainOwner, _newOwner);
    }

    function addOwner(address _newOwner) public onlyOwner {
        require(_newOwner != address(0), "addOwner: new owner is the zero address");
        require(isOwner(_newOwner) == false, "addOwner: new owner is already the owner");

        owners[_newOwner] = true;

        emit AddedOwner(_newOwner);
    }

    function removeOwner(address _toRemove) public onlyOwner {
        require(_toRemove != address(0), "removeOwner: remove owner is the zero address");
        require(_toRemove != msg.sender, "removeOwner: remove owner is msg.sender");
        require(isOwner(_toRemove) == true, "removeOwner: remove owner is not owner");
        require(_toRemove != mainOwner, "removeOwner: Main Owner cannot be removed");

        delete owners[_toRemove];

        emit RemovedOwner(_toRemove);
    }
}
