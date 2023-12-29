//SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

contract Ownable {

    address _owner;

    constructor() {
        _owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == _owner);
        _;
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        _owner = newOwner;
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

}