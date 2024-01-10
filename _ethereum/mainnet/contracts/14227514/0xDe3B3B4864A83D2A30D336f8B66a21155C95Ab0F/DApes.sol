//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC1155Upgradeable.sol";
import "./ERC1155PausableUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./UUPSUpgradeable.sol";

import "./ECDSA.sol";
import "./Counters.sol";
import "./BitMaps.sol";

contract DApes is ERC1155PausableUpgradeable, UUPSUpgradeable, OwnableUpgradeable {
    using Counters for Counters.Counter;
    using BitMaps for BitMaps.BitMap;

    struct Collection {
        uint256 startID;
        Counters.Counter nextID;
        uint256 endID;
    }
    
    event CollectionMinted(uint256 collection, uint256 nonce, uint256 tokenID, address to);

    address public gatekeeper;

    Counters.Counter private _supply;
    BitMaps.BitMap private _usedNonces;

    Collection[] public collections;

    function initialize(address aGatekeeper, string memory uri) public initializer {
        __ERC1155Pausable_init();
        __ERC1155_init_unchained(uri);
        __UUPSUpgradeable_init();
        __Ownable_init_unchained();

        gatekeeper = aGatekeeper;
        _supply = Counters.Counter(0);
    }

    function setGatekeeper(address aGatekeeper) public onlyOwner {
        gatekeeper = aGatekeeper;
    }

    function addCollection(uint256 startID, uint256 endID) public onlyOwner {
        require(startID < endID, "Start should preceede end");
        require(collections.length == 0 || collections[collections.length - 1].endID <= startID, "Collections shouldn't overlap");
        collections.push(Collection({ nextID: Counters.Counter(startID), endID: endID, startID: startID }));
    }

    function amendTopCollection(uint256 newEndID) public onlyOwner {
        require(collections.length > 0, "No collection to amend");
        Collection storage top = collections[collections.length - 1];
        require(top.nextID.current() <= newEndID, "End cuts existing supply");

        top.endID = newEndID;
    }

    function keyHash(uint256 collection, uint256 nonce, address addr) public pure returns (bytes32) {
        return ECDSA.toEthSignedMessageHash(abi.encodePacked(collection, nonce, addr));
    }

    function isKeyUsed(uint256 nonce) public view returns(bool) {
        return _usedNonces.get(nonce);
    }

    function mint(uint256 collectionID, uint256 nonce, bytes memory signature) public {
        bytes32 kh = keyHash(collectionID, nonce, msg.sender);
       
        require(ECDSA.recover(kh, signature) == gatekeeper, "Invalid access key");
        require(!isKeyUsed(nonce), "Key already used");
       
        Collection storage collection = collections[collectionID];
        uint256 newID = collection.nextID.current();
       
        require(newID < collection.endID, "Minted out");
        
        _usedNonces.set(nonce);
        _supply.increment();
        collection.nextID.increment();

        emit CollectionMinted(collectionID, nonce, newID, msg.sender);
        _mint(msg.sender, newID, 1, "");
    }

    function totalSupply() public view returns (uint256) {
        return _supply.current();
    }

    function setURI(string calldata newURI) public onlyOwner {
        _setURI(newURI);
    }

    function name() external pure returns (string memory) {
        return "DApes";
    }

    function symbol() external pure returns (string memory) {
        return "DAPES";
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}
}