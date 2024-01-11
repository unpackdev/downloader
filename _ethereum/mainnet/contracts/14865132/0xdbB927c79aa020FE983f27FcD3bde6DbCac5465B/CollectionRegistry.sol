pragma solidity 0.8.12;

import "./Ownable.sol";
import "./ICollectionRegistry.sol";

contract CollectionRegistry is ICollectionRegistry, Ownable {
    mapping(address => bool) whitelistedCollections;

    mapping(address => bool) public authorized;

    event CollectionRegistered(address indexed collection);
    event CollectionUnregistered(address indexed collection);
    event Authorized(address indexed account);
    event Unauthorized(address indexed account);

    error CollectionRegistry_Not_Authorized();

    modifier onlyAuthorized() {
        if (!authorized[msg.sender] && owner() != msg.sender)
            revert CollectionRegistry_Not_Authorized();

        _;
    }

    function addAuthorized(address account) external onlyOwner {
        authorized[account] = true;
        emit Authorized(account);
    }

    function removeAuthorized(address account) external onlyOwner {
        authorized[account] = false;
        emit Unauthorized(account);
    }

    function isJumyCollection(address collection) external view returns (bool) {
        return whitelistedCollections[collection];
    }

    function registerCollection(address collection) external onlyAuthorized {
        whitelistedCollections[collection] = true;
        emit CollectionRegistered(collection);
    }

    function unRegisterCollection(address collection) external onlyAuthorized {
        whitelistedCollections[collection] = false;
        emit CollectionUnregistered(collection);
    }
}
