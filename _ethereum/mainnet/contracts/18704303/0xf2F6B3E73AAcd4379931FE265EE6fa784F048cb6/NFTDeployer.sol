// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;
import "./Counters.sol";
import "./MonadNFT.sol";

contract NFTDeployer {

    using Counters for Counters.Counter;

    PermissionManager public permissionManager;
    Counters.Counter private _idTracker;
    mapping(uint256 => Collection) public collections;

    event CollectionCreated(uint256 id, address collectionAddress);

    struct Collection {
        uint256 id;
        address addr;
        uint256 createdAt;
    }

    constructor(address permissionManagerAddress) {
        permissionManager = PermissionManager(permissionManagerAddress);
    }

    function createCollection(string memory name_, string memory symbol_) public onlyAdmin() returns(address){
        _idTracker.increment();
        uint256 id = _idTracker.current();
        MonadNFT nft = new MonadNFT(name_, symbol_, id, address(permissionManager));
        address collectionAddress = address(nft);
        collections[id].id = id;
        collections[id].addr = collectionAddress;
        collections[id].createdAt = block.timestamp;
        emit CollectionCreated(id, collectionAddress);
        return collectionAddress;
    }

    function currentId() public view returns(uint256){
        return _idTracker.current();
    }

    function getPermissionManagerAddress() public view returns(address){
        return address(permissionManager);
    }

    modifier onlyAdmin() {
        require(permissionManager.isAdmin(msg.sender), "Caller is not admin");
        _;
    }
}
