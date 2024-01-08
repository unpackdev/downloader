// contracts/GameItems.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


import "./ReentrancyGuard.sol";
import "./strings.sol";
import "./KeyInterface.sol";

interface ISalmon {
  function burn(address from, uint256 amount) external;
  function balanceOf(address account) external view returns (uint256);
}

contract Buckets is KeyInterface, ReentrancyGuard {
    using Strings for uint256;


    mapping(uint256 => uint256 ) bucketCost;
    mapping(uint256 => bool) saleLive;
    uint256[] bucketIDs;
    ISalmon public salmon;


    constructor(address _salmon) ERC1155("https://api.beargame.io/api/buckets/") {
        salmon = ISalmon(_salmon);
        m_Name = 'Salmon Buckets';
        m_Symbol = 'BUCKET';
        bucketCost[0] = 1000000 ether;
        bucketCost[1] = 500000 ether;
        bucketCost[2] = 100000 ether;

        saleLive[0] = true;
        saleLive[1] = true;
        saleLive[2] = true;

        bucketIDs = [0, 1, 2];

    }

    function mintBucket(uint256 _amount, uint256 _type) external payable nonReentrant() {
        address msgsender = _msgSender();
        require(msg.value == 0, "You must pay using SALMON");
        require(tx.origin == msgsender, "Only EOA");
        require(_type < bucketIDs.length, "Bucket ID Doesnt Exist");
        require(saleLive[_type],"Sale for this type is not active");

        uint256 totalCost = _amount * bucketCost[_type];

        require(salmon.balanceOf(msgsender) >= totalCost, "Not enough $SALMON");

        salmon.burn(msgsender, totalCost);
        _mint(msgsender, _type, _amount, "");

    }

    function setSaleStatus(uint256 _id, bool _status) external onlyOwner {

        saleLive[_id] = _status;
    }

    function getSaleStatus(uint256 _id) public view returns (bool _status) {
        _status = saleLive[_id];

    }

    function addBucketTypes(uint256 _type, uint256 _cost) external onlyOwner {
        bucketCost[_type] = _cost * 10 ** 18; 
        bucketIDs.push(_type);
    }
        
    function setSalmonAddress(address _salmon) external onlyOwner {
       salmon = ISalmon(_salmon);
    }
    
    function setURI(string memory newuri) external onlyOwner {
        _setURI(newuri);
    }

    function uri(uint256 _id) public view override returns (string memory) {
        require(totalSupply(_id) > 0, "URI: nonexistent token");
        return string(abi.encodePacked(super.uri(_id),_id.toString()));
    } 

    function nTypes() public view  returns (uint256) {
        return bucketIDs.length;
    }

    function getCost(uint256 _id) public view returns (uint256 cost) {
        cost = bucketCost[_id];
    }


    
}