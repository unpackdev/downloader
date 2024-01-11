// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC173.sol";

/**
 * @dev Implementation of the ERC173
 */
contract Package_ERC173 is ERC173 {
    address private _owner;

    modifier ownership() {
        require(owner() == msg.sender, "ERC173: caller is not the owner");
        _;
    }

    constructor(address owner_) {
        _transferOwnership(owner_);
    }


    function owner() public view override returns (address) {
        return _owner;
    }

    function transferOwnership(address _newOwner) public override ownership {
        _transferOwnership(_newOwner);
    }

    function _transferOwnership(address _newOwner) internal {
        address previousOwner = _owner;
        _owner = _newOwner;
    
        emit OwnershipTransferred(previousOwner, _newOwner);
    }
}
