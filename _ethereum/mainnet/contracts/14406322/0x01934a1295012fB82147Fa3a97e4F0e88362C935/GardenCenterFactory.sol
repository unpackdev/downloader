// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

import "./IERC721.sol";

interface GardenCenter{

    function construct(address _collection, address _sender, bool _isCollectionOwner) external;
}

interface Ownable{

    function owner() external view returns (address);
}

contract GardenCenterFactory {
    
    address public blueprint;
    address public owner;
    address[] public centers;
    mapping(address => address) public centersMap;
    mapping(address => uint256) public centersIndex;
    mapping(address => uint256) public graceTimeEnd;
    mapping(address => address) public altOwner;
    mapping(address => bool) public admins;

    event GardenCenterCreated(address indexed user, address indexed collection, address indexed center);
    event GardenCenterDeleted(address indexed collection, address indexed center);
    event AdminSet(address indexed admin, bool state);

    constructor(address _blueprint)  {

        blueprint = _blueprint;
        owner = msg.sender;
        centers.push(address(0));
    }

    function newCenter(address collection) external {
	    
        require(collection != address(0), "newCenter: null address not allowed.");
        require(IERC721(0x13fD344E39C30187D627e68075d6E9201163DF33).balanceOf(msg.sender) != 0, "newCenter: not an RG unicorn holder.");
        require(centersMap[collection] == address(0), "newCenter: center exists already.");

        uint256 _graceTimeEnd = graceTimeEnd[collection];

        require(_graceTimeEnd != 0, "newCenter: graceTimeEnd not set yet by admin.");

        bool isOwner = false;

        address _owner = altOwner[collection];

        if(_owner == address(0)){

            try Ownable(collection).owner() returns(address __owner)
            {
                
                _owner = __owner;
                
            } catch {}

        }

        if(_graceTimeEnd > block.timestamp && _owner != msg.sender){

            revert("Owner may still create a new garden center.");
        }

        if(_owner == msg.sender){

            isOwner = true;
        }

	    address center = createClone(blueprint);
	    
	    GardenCenter(center).construct(collection, msg.sender, isOwner);

	    centers.push(center);
        centersIndex[collection] = centers.length - 1;
        centersMap[collection] = center;
	    
	    emit GardenCenterCreated(msg.sender, collection, center);
	}

    function getCentersLength() external view returns(uint256){

        return centers.length;
    }

    function setGraceTimeEnd(address _collection, uint256 _endTime) external{

        require(owner == msg.sender || admins[msg.sender], "setGraceTimeEnd: not an admin.");

        graceTimeEnd[_collection] = _endTime;
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

    function clearCenter(address _collection) external{

        require(owner == msg.sender, "clear: not the owner.");

        emit GardenCenterDeleted( _collection, centersMap[_collection] );

        centersMap[_collection] = address(0);
        centers[centersIndex[_collection]] = address(0);
        centersIndex[_collection] = 0;
        graceTimeEnd[_collection] = 0;
        altOwner[_collection] = address(0);
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