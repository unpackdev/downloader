// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "./ERC721A.sol";

// This contract tracks land claims to locations.
// Lands are tokens on the given contract.
// Locations are strings.
// Locations must be unique.
contract LandClaim {
    ERC721A public thisToken;

    // Existing mappings
    mapping(uint256 => string) private _claims;
    mapping(string => uint256) private _locations;
    mapping(string => bool) private _locationsClaimed;

    constructor(address _thisTokenAddress) {
        thisToken = ERC721A(_thisTokenAddress);
    }

    function claim(uint256 tokenId, string memory location) public {
        require(bytes(location).length != 0, "Location must not be empty");
        require(thisToken.ownerOf(tokenId) == msg.sender || thisToken.isApprovedForAll(thisToken.ownerOf(tokenId), msg.sender), "Caller must own the token or be approved");
        require(bytes(_claims[tokenId]).length == 0, "TokenId is already claimed");
        require(!_locationsClaimed[location], "Location is already claimed");

        _locations[location] = tokenId;
        _claims[tokenId] = location;
        _locationsClaimed[location] = true;
    }

    function unclaimTokenId(uint256 tokenId) public {
        require(thisToken.ownerOf(tokenId) == msg.sender || thisToken.isApprovedForAll(thisToken.ownerOf(tokenId), msg.sender), "Caller must own the token or be approved");
        require(bytes(_claims[tokenId]).length != 0, "TokenId is not claimed");

        // Get the location associated with tokenId
        string memory location = _claims[tokenId];

        // Delete mappings
        delete _claims[tokenId];
        delete _locations[location];
        delete _locationsClaimed[location];
    }

    function unclaimLocation(string memory location) public {
        require(bytes(location).length != 0, "Location must not be empty");
        require(_locationsClaimed[location], "Location is not claimed");

        uint256 tokenId = _locations[location];
        
        require(thisToken.ownerOf(tokenId) == msg.sender || thisToken.isApprovedForAll(thisToken.ownerOf(tokenId), msg.sender), "Caller must own the token or be approved");

        delete _locations[location];
        delete _locationsClaimed[location];
        delete _claims[tokenId];
    }

    function getTokenIdLocation(uint256 tokenId) public view returns (string memory location) {
        return _claims[tokenId];
    }

    function getLocationTokenId(string memory location) public view returns (bool, uint256) {
        return (
            _locationsClaimed[location],
            _locations[location]
        );
    }
}
