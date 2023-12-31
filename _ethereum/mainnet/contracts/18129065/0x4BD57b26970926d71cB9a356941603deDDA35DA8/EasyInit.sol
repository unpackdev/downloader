// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./Admins.sol";
import "./EasyLibrary.sol";

abstract contract EasyInit is Admins {
    string public name;
    string public symbol;
    uint256 public collectionEndID;

    constructor(address _newOwner) Admins(_newOwner){}

    /**
    @dev Returns the total number of tokens within the collection.
    */
    function totalSupply() public view virtual returns(uint256) {
        return collectionEndID;
    }

    /**
    @dev Allows admin to update the collectionEndID which is used to determine the end of the initial collection of NFTs.
    @param _newcollectionEndID The new collectionEndID to set.
    */
    function updateCollectionEndID(uint _newcollectionEndID) external virtual onlyAdmins {
        collectionEndID = _newcollectionEndID;
    }
}
