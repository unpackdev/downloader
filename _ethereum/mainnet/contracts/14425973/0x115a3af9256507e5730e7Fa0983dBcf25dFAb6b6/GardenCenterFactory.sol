// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "./IERC721.sol";

interface GardenCenterOwnershipToken{

    function mint(address to, address collection, address center) external;
}

interface GardenCenter{

    function construct(address _collection, address _sender) external;
}

interface Ownable{

    function owner() external view returns(address);
}

contract GardenCenterFactory {
    
    uint256 public cooldownPeriod;
    address public blueprint;
    address public owner;
    address public ownershipToken;
    address[] public centers;
    mapping(address => address) public centersMap;
    mapping(address => uint256) public centersIndex;
    mapping(address => address) public altOwner;
    mapping(address => uint256) public accountLastTimestamp;
    mapping(uint256 => uint256) public tokenIdLastTimestamp;
    mapping(address => bool) public admins;

    event GardenCenterCreated(address indexed user, address indexed collection, address indexed center);
    event AdminSet(address indexed admin, bool state);

    constructor(address _blueprint)  {

        blueprint = _blueprint;
        owner = msg.sender;
        centers.push(address(0));
        ownershipToken = 0xdD96c5C111294eC1C1883f171CCaF7F48b5EE4a8;
        cooldownPeriod = 86400;
    }

    function newCenter(address collection, uint256 unicornTokenId) external {
	    
        uint256 _cooldownPeriod = cooldownPeriod;
        address _sender = msg.sender;

        require(collection != address(0), "newCenter: null address not allowed.");
        require(IERC721(0x13fD344E39C30187D627e68075d6E9201163DF33).ownerOf(unicornTokenId) == _sender, "newCenter: not owning the given tokenId.");
        require(block.timestamp - accountLastTimestamp[_sender] >= _cooldownPeriod, "newCenter: cooldown period for account not yet expired");
        require(block.timestamp - tokenIdLastTimestamp[unicornTokenId] >= _cooldownPeriod, "newCenter: cooldown period for tokendID not yet expired");
        require(centersMap[collection] == address(0), "newCenter: center exists already.");

	    address center = createClone(blueprint);
        uint256 ts = block.timestamp;

	    centers.push(center);
        centersIndex[collection] = centers.length - 1;
        centersMap[collection] = center;
        accountLastTimestamp[_sender] = ts;
        tokenIdLastTimestamp[unicornTokenId] = ts;

        GardenCenter(center).construct(collection, _sender);
        GardenCenterOwnershipToken(ownershipToken).mint(_sender, collection, center);
	    
	    emit GardenCenterCreated(_sender, collection, center);
	}

    function collectionOwner(address _owner, address collection) external view returns(bool){

        return Ownable(collection).owner() == _owner;
    }

    function getCentersLength() external view returns(uint256){

        return centers.length;
    }

    function setCooldownPeriod(uint256 _cooldownPeriod) external{

        require(owner == msg.sender || admins[msg.sender], "setCooldownPeriod: not an admin.");

        cooldownPeriod = _cooldownPeriod;
    }

    function setAltOwner(address _collection, address _altOwner) external{

        require(owner == msg.sender || admins[msg.sender], "setAltOwner: not an admin.");

        altOwner[_collection] = _altOwner;
    }

    function setAdmin(address _admin, bool _is) external{

        require(owner == msg.sender, "setAdmin: not the owner.");

        admins[_admin] = _is;

        emit AdminSet(_admin, _is);
    }

    function setBlueprint(address _blueprint) external{

        require(owner == msg.sender, "setBlueprint: not the owner.");

        blueprint = _blueprint;
    }

    function transferOwnership(address _newOwner) external{

        require(owner == msg.sender, "transferOwnership: not the owner.");

        owner = _newOwner;
    }

    function createClone(address target) internal returns (address result) {
        bytes20 targetBytes = bytes20(target);
        assembly {
            let clone := mload(0x40)
            mstore(clone, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(clone, 0x14), targetBytes)
            mstore(add(clone, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            result := create(0, clone, 0x37)
        }
    }
}