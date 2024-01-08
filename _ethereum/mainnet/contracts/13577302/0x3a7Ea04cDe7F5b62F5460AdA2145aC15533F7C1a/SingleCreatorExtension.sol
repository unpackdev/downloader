// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "./ERC165Checker.sol";
import "./IERC721CreatorCore.sol";

import "./LegacyInterfaces.sol";

abstract contract SingleCreatorBase {
    address internal _creator;
}

/**
 * @dev Extension that only uses a single creator contract instance
 */
abstract contract ERC721SingleCreatorExtension is SingleCreatorBase {

    constructor(address creator) {
        require(ERC165Checker.supportsInterface(creator, type(IERC721CreatorCore).interfaceId) ||
                ERC165Checker.supportsInterface(creator, LegacyInterfaces.IERC721CreatorCore_v1), 
                "Redeem: Minting reward contract must implement IERC721CreatorCore");
        _creator = creator;
    }

    function creatorContract() public view returns(address) {
        return _creator;
    }

}