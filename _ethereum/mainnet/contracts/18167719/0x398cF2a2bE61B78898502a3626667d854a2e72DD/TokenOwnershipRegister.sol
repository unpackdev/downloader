// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;


import "./Ownable.sol";

contract TokenOwnershipRegister is Ownable {
    mapping(address => bool) deployedCollections;
    mapping(address => mapping(address => uint256)) public userToCollectionToBalance;
    mapping(address => mapping(address => uint256[])) public userToCollectionToTokens;
    address factoryAddress;

    modifier onlyFactory() {
        require(msg.sender == factoryAddress, "Factory only");
        _;
    }

    modifier onlyRegisteredCollections(address sender) {
        require(deployedCollections[sender], "Registered collections only");
        _;
    }

    function setFactoryAddress(address _factoryAddress) external onlyOwner {
        factoryAddress = _factoryAddress;
    }


    function registerCollection(address _newCollection) external onlyFactory {
        deployedCollections[_newCollection] = true;
    }

    function recordMint(address _collection, address _owner, uint _tokenId) external onlyRegisteredCollections(_collection) {
        userToCollectionToBalance[_owner][_collection]+= 1;
        userToCollectionToTokens[_owner][_collection].push(_tokenId);
    }

    function recordTransfer(address _collection, address _from, address _to, uint _tokenId) external onlyRegisteredCollections(_collection) {
        uint[] storage tokens = userToCollectionToTokens[_from][_collection];
        uint balance = userToCollectionToBalance[_from][_collection];
        for(uint i = 0; i < balance; i++) {
            if(tokens[i] == _tokenId) {
                uint lastIndex = balance - 1;
                uint lastIndexValue = tokens[lastIndex];
                tokens[i] = lastIndexValue;
                // tokens.pop();
                delete tokens[lastIndex];
            }
        }
        userToCollectionToTokens[_to][_collection].push(_tokenId);
        userToCollectionToBalance[_from][_collection]-= 1;
        userToCollectionToBalance[_to][_collection]+= 1;

    }
}