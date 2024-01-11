// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Address.sol";
import "./Counters.sol";
import "./BaseAccessControl.sol";
import "./DragonInfo.sol";

contract DragonToken is ERC721, BaseAccessControl {

    using Address for address;
    using Counters for Counters.Counter;

    string public constant NONEXISTENT_TOKEN_ERROR = "DragonToken: nonexistent token";
    string public constant NOT_ENOUGH_PRIVILEGES_ERROR = "DragonToken: not enough privileges to call the method";
    string public constant DRAGON_EXISTS_ERROR = "DragonToken: a dragon with such ID already exists";
    string public constant BAD_CID_ERROR = "DragonToken: bad CID";
    string public constant CID_SET_ERROR = "DragonToken: CID is already set";
    
    Counters.Counter private _dragonIds;

    // Mapping token id to dragon details
    mapping(uint => uint) private _info;
    // Mapping token id to cid
    mapping(uint => string) private _cids;

    string private _defaultMetadataCid;
    address private _dragonCreator;
    address private _dragonReplicator;

    constructor(uint dragonSeed, string memory defaultCid, address accessControl) 
    ERC721("CryptoDragons", "CD")
    BaseAccessControl(accessControl) {  
        _dragonIds = Counters.Counter({ _value: dragonSeed });
        _defaultMetadataCid = defaultCid;
    }

    function approveAndCall(address spender, uint256 tokenId, bytes calldata extraData) external returns (bool success) {
        require(_exists(tokenId), NONEXISTENT_TOKEN_ERROR);
        _approve(spender, tokenId);
        (bool _success, ) = 
            spender.call(
                abi.encodeWithSignature("receiveApproval(address,uint256,address,bytes)", 
                _msgSender(), 
                tokenId, 
                address(this), 
                extraData) 
            );
        if(!_success) { 
            revert("DragonToken: spender internal error"); 
        }
        return true;
    }

    function tokenURI(uint tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), NONEXISTENT_TOKEN_ERROR);
        string memory cid = _cids[tokenId];
        return string(abi.encodePacked("ipfs://", (bytes(cid).length > 0) ? cid : defaultMetadataCid()));
    }

    function dragonCreatorAddress() public view returns(address) {
        return _dragonCreator;
    }

    function setDragonCreatorAddress(address newAddress) external onlyRole(COO_ROLE) {
        address previousAddress = _dragonCreator;
        _dragonCreator = newAddress;
        emit AddressChanged("dragonCreator", previousAddress, newAddress);
    }

    function dragonReplicatorAddress() public view returns(address) {
        return _dragonReplicator;
    }

    function setDragonReplicatorAddress(address newAddress) external onlyRole(COO_ROLE) {
        address previousAddress = _dragonReplicator;
        _dragonReplicator = newAddress;
        emit AddressChanged("dragonReplicator", previousAddress, newAddress);
    }

    function hasMetadataCid(uint tokenId) public view returns(bool) {
        require(_exists(tokenId), NONEXISTENT_TOKEN_ERROR);
        return bytes(_cids[tokenId]).length > 0;
    }

    function setMetadataCid(uint tokenId, string calldata cid) external onlyRole(COO_ROLE) {
        require(_exists(tokenId), NONEXISTENT_TOKEN_ERROR);
        require(bytes(cid).length >= 46, BAD_CID_ERROR);
        require(!hasMetadataCid(tokenId), CID_SET_ERROR);
        _cids[tokenId] = cid;
    }

    function defaultMetadataCid() public view returns (string memory){
        return _defaultMetadataCid;
    }

    function setDefaultMetadataCid(string calldata newDefaultCid) external onlyRole(COO_ROLE) {
        _defaultMetadataCid = newDefaultCid;
    }

    function dragonInfo(uint dragonId) public view returns (DragonInfo.Details memory) {
        require(_exists(dragonId), NONEXISTENT_TOKEN_ERROR);
        return DragonInfo.getDetails(_info[dragonId]);
    }

    function strengthOf(uint dragonId) external view returns (uint) {
        DragonInfo.Details memory details = dragonInfo(dragonId);
        return details.strength > 0 ? details.strength : DragonInfo.calcStrength(details.genes);
    }

    function isSiblings(uint dragon1Id, uint dragon2Id) external view returns (bool) {
        DragonInfo.Details memory info1 = dragonInfo(dragon1Id);
        DragonInfo.Details memory info2 = dragonInfo(dragon2Id);
        return 
            (info1.generation > 1 && info2.generation > 1) && //the 1st generation of dragons doesn't have siblings
            (info1.parent1Id == info2.parent1Id || info1.parent1Id == info2.parent2Id || 
            info1.parent2Id == info2.parent1Id || info1.parent2Id == info2.parent2Id);
    }

    function isParent(uint dragon1Id, uint dragon2Id) external view returns (bool) {
        DragonInfo.Details memory info = dragonInfo(dragon1Id);
        return info.parent1Id == dragon2Id || info.parent2Id == dragon2Id;
    }

    function mint(address to, DragonInfo.Details calldata info) external returns (uint) {
        require(_msgSender() == dragonCreatorAddress(), NOT_ENOUGH_PRIVILEGES_ERROR);
        
        _dragonIds.increment();
        uint newDragonId = uint(_dragonIds.current());
        
        _info[newDragonId] = DragonInfo.getValue(info);
        _mint(to, newDragonId);

        return newDragonId;
    }

    function mintReplica(address to, uint dragonId, uint value, string memory cid) external returns (uint) {
        require(_msgSender() == dragonReplicatorAddress(), NOT_ENOUGH_PRIVILEGES_ERROR);
        require(_info[dragonId] == 0, DRAGON_EXISTS_ERROR);
        
        _info[dragonId] = value;
        _cids[dragonId] = cid;
        
        _mint(to, dragonId);

        return dragonId;
    }

    function setStrength(uint dragonId) external returns (uint) {
        DragonInfo.Details memory details = dragonInfo(dragonId);
        if (details.strength == 0) {
            details.strength = DragonInfo.calcStrength(details.genes);
            _info[dragonId] = DragonInfo.getValue(details);
        }
        return details.strength;
    }
}