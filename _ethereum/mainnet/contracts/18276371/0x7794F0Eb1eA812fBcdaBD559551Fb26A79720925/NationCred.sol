//SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

import "./INationCred.sol";
import "./IERC721.sol";

/**
 * @notice Stores the passport IDs of active Nation3 citizens.
 */
contract NationCred is INationCred {
    address public owner;
    IERC721 public passport;
    uint16[] private passportIDs;

    constructor(address passportAddress) {
        owner = address(msg.sender);
        passport = IERC721(passportAddress);
    }

    function setOwner(address owner_) public {
        require(msg.sender == owner, "You are not the owner");
        owner = owner_;
    }

    function setActiveCitizens(uint16[] calldata passportIDs_) public {
        require(msg.sender == owner, "You are not the owner");
        passportIDs = passportIDs_;
    }

    function isActiveID(uint16 passportID) public view returns (bool) {
        for (uint16 i = 0; i < passportIDs.length; i++) {
            if (passportIDs[i] == passportID) {
                return true;
            }
        }
        return false;
    }

    function isActiveAddress(address citizen) public view returns (bool) {
        for (uint16 i = 0; i < passportIDs.length; i++) {
            uint256 passportID = passportIDs[i];
            address passportOwner = passport.ownerOf(passportID);
            if (passportOwner == citizen) {
                return true;
            }
        }
        return false;
    }
}
