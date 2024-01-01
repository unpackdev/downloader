// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.15;

import "./CLLPadlock.sol";
import "./CLLKey.sol";
import "./AccessControl.sol";

contract CLLFactory is AccessControl{

    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");

    CLLPadlock  public padlocks;
    CLLKey      public keys;

    // Padlock and keys relationships
    mapping(uint256 => uint256) public keyToPadlockRelations;

    // Location
    mapping(uint256 => uint256) public padlock2location;
    mapping(uint256 => bytes32) public padlock2location_extra_data;
    mapping(uint256 => uint256) public location2padlock;
    mapping(uint256 => uint256) public location2price_wei;

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(MANAGER_ROLE, msg.sender);
        padlocks = new CLLPadlock();
        keys =  new CLLKey();
    }

    function setPadlockLocation( address allegedKeyOwner
                                ,uint256 padlock
                                ,uint256 key
                                ,uint256 location
                                ,bytes32 location_extra_data) external onlyRole(MANAGER_ROLE) {

      require(isKeyForPadlock(key, padlock), "Incorrect key");
      require(allegedKeyOwner == keys.ownerOf(key), "Cannot move padlock");
      require(location2padlock[location] != padlock, "Moving to same location is no use");
      require(location2padlock[location] == 0, "Another padlock is already there");

      uint256 currentLocation = padlock2location[padlock];
      location2padlock[currentLocation] = 0;
      location2padlock[location] = padlock;
      padlock2location[padlock] = location;
      padlock2location_extra_data[padlock] = location_extra_data;

    }

    function mintPadlockAndKeysTo(address to
                                 ,uint256 padlockTokenId
                                 ,uint256 numberOfKeys) external onlyRole(MANAGER_ROLE){
        require(numberOfKeys <= 16, "Too much keys"); 
        uint256 keyBaseTokenId = 256 + padlockTokenId;

        padlocks.safeMint(to, padlockTokenId);

        for(uint8 n = 0; n < numberOfKeys; n++){
            uint256 keyTokenId = keyBaseTokenId + n;
            keys.safeMint(to, keyTokenId);
            keyToPadlockRelations[keyTokenId] = padlockTokenId;
        }
    }

    function engravePadlock( address allegedPadlockOwner 
                            ,uint256 padlockTokenId
                            ,bytes32 text_1
                            ,bytes32 text_2
                            ,bytes32 text_3) external onlyRole(MANAGER_ROLE){

      require(allegedPadlockOwner == padlocks.ownerOf(padlockTokenId), "Not owner");

      padlocks.engravePadlock(padlockTokenId, text_1, text_2, text_3);
    }

    function isKeyForPadlock(uint256 keyId, uint256 padlockId) public view returns (bool) {
        require(padlocks.exists(padlockId), "Non existent padlock");
        require(keys.exists(keyId), "Non existent key");
        return keyToPadlockRelations[keyId] == padlockId;
    }
    
    function padlockTokenURI(uint256 tokenId) external view returns (string memory) {
      return padlocks.tokenURI(tokenId);
    }
    
    function keyTokenURI(uint256 tokenId) external view returns (string memory) {
      return keys.tokenURI(tokenId);
    }

    function padlocksSetBaseURI(string calldata newBaseTokenURI) external onlyRole(DEFAULT_ADMIN_ROLE) {
      padlocks.setBaseURI(newBaseTokenURI);
    }

    function keysSetBaseURI(string calldata newBaseTokenURI) external onlyRole(DEFAULT_ADMIN_ROLE) {
      keys.setBaseURI(newBaseTokenURI);
    }
}

