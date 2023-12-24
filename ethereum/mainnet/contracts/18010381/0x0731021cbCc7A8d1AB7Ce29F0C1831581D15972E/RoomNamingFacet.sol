// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

import "./PseudoRandomLib.sol";
import "./RoomNamingStorage.sol";
import "./OwnableInternal.sol";
import "./ERC721BaseInternal.sol";
import "./ConstantsLib.sol";
import "./Counters.sol";

contract RoomNamingFacet is OwnableInternal, ERC721BaseInternal {
    using Counters for Counters.Counter;

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/
    event RoomNameSet(address user, uint256 roomId, string newName);

    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Thrown if the room ID is invalid
     */
    error InvalidRoomId(uint8);
    /**
     * @notice Thrown if the room ID is invalid
     */
    error RoomNameTooLong(string);
    /**
     * @notice Thrown if the caller is not allowed to set the given room name
     */
    error NotAllowedToSetRoomName(address, uint8);
    /**
     * @notice Thrown if the provided token ID does not exist
     */
    error TokenDoesNotExist(uint256);
    /**
     * @notice Thrown if the message sender does not own the provided token ID
     */
    error NotTokenOwner(address, uint256);
    /**
     * @notice Thrown when trying to set base room name to empty string
     */
    error CannotSetBlankRoomName(uint8);

    function getSpecialTicketsCount() external view returns (uint256) {
        RoomNamingStorage.Layout storage l = RoomNamingStorage.layout();
        return l.specialTicketsCount.current();
    }

    /*//////////////////////////////////////////////////////////////
                        ROOM NAMING FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    // Returns which room this token has access to name, 0 if none
    function getRoomNamingRights(uint256 tokenId) public view returns (uint256) {
        RoomNamingStorage.Layout storage l = RoomNamingStorage.layout();
        if (!_exists(tokenId)) {
            revert TokenDoesNotExist(tokenId);
        }
        return l.tokenIdToRoomRights[tokenId];
    }

    // Set room name only if sender has a token that permits it
    function setRoomName(uint256 tokenId, uint8 roomId, string memory name) public {
        RoomNamingStorage.Layout storage l = RoomNamingStorage.layout();

        // validate the msg sender is the owner of the token
        if (_ownerOf(tokenId) != msg.sender) {
            revert NotTokenOwner(msg.sender, tokenId);
        }

        // validate the room id is valid
        validateRoomId(roomId);

        // validate the token has the right to set the room name
        if (l.tokenIdToRoomRights[tokenId] != roomId) {
            revert NotAllowedToSetRoomName(msg.sender, roomId);
        }

        // validate the name is not too long
        if (bytes(name).length > ConstantsLib.MAX_ROOM_NAME_LENGTH) {
            revert RoomNameTooLong(name);
        }

        if (bytes(name).length == 0) {
            revert CannotSetBlankRoomName(roomId);
        }

        l.customRoomNames[roomId] = name;

        emit RoomNameSet(msg.sender, roomId, name);
    }

    function getBaseRoomName(uint8 roomId) public view returns (string memory) {
        validateRoomId(roomId);
        RoomNamingStorage.Layout storage l = RoomNamingStorage.layout();
        if (bytes(l.baseRoomNames[roomId]).length == 0) {
            if (roomId == 1) {
                return "Toy Store";
            } else if (roomId == 2) {
                return "Library";
            } else if (roomId == 3) {
                return "Theater";
            } else if (roomId == 4) {
                return "Kitchen";
            } else if (roomId == 5) {
                return "Gym";
            } else if (roomId == 6) {
                return "Arcade";
            } else if (roomId == 7) {
                return "Bar";
            } else if (roomId == 8) {
                return "Garden";
            } else if (roomId == 9) {
                return "Pool";
            } else if (roomId == 10) {
                return "Laboratory";
            }
        }
        return l.baseRoomNames[roomId];
    }

    // the owner can override the base room name suffix
    function setBaseRoomName(uint8 roomId, string memory name) external onlyOwner {
        validateRoomId(roomId);
        if (bytes(name).length == 0) {
            revert CannotSetBlankRoomName(roomId);
        }

        if (bytes(name).length > ConstantsLib.MAX_ROOM_NAME_LENGTH) {
            revert RoomNameTooLong(name);
        }

        RoomNamingStorage.Layout storage l = RoomNamingStorage.layout();
        l.baseRoomNames[roomId] = name;
    }

    function getRoomName(uint8 roomId) external view returns (string memory) {
        RoomNamingStorage.Layout storage l = RoomNamingStorage.layout();

        validateRoomId(roomId);

        // if blank, return the base room name
        if (keccak256(abi.encodePacked((l.customRoomNames[roomId]))) == keccak256(abi.encodePacked(("")))) {
            return getBaseRoomName(roomId);
        }

        // otherwise return the custom room name followed by the base room name
        return string(abi.encodePacked(l.customRoomNames[roomId], " ", getBaseRoomName(roomId)));
    }

    function validateRoomId(uint8 roomId) internal pure {
        if (roomId < ConstantsLib.MIN_ROOM_ID || roomId > ConstantsLib.SPECIAL_TICKETS_COUNT) {
            revert InvalidRoomId(roomId);
        }
    }
}
