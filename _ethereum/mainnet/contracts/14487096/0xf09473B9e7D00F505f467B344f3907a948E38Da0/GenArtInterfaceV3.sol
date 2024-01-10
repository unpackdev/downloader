// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./GenArtAccess.sol";
import "./IGenArtMembership.sol";
import "./IGenArtERC721V2.sol";
import "./IGenArtInterfaceV3.sol";

/**
 * Interface to the GEN.ART Membership and Governance Token Contracts
 */

contract GenArtInterfaceV3 is GenArtAccess, IGenArtInterfaceV3 {
    IGenArtMembership private _genArtMembership;

    constructor(address genArtMembershipAddress_) {
        _genArtMembership = IGenArtMembership(genArtMembershipAddress_);
    }

    function isGoldToken(uint256 _membershipId)
        public
        view
        override
        returns (bool)
    {
        return _genArtMembership.isGoldToken(_membershipId);
    }

    function getMembershipsOf(address account)
        public
        view
        override
        returns (uint256[] memory)
    {
        return _genArtMembership.getTokensByOwner(account);
    }

    function ownerOfMembership(uint256 _membershipId)
        public
        view
        override
        returns (address)
    {
        return _genArtMembership.ownerOf(_membershipId);
    }

    /**
     *@dev Get available mints for an account
     */
    function getAvailableMintsForAccount(address collection, address account)
        public
        view
        override
        returns (uint256)
    {
        uint256[] memory memberships = getMembershipsOf(account);
        uint256 availableMints;
        for (uint256 i; i < memberships.length; i++) {
            availableMints += IGenArtERC721V2(collection)
                .getAvailableMintsForMembership(memberships[i]);
        }
        return availableMints;
    }
}
