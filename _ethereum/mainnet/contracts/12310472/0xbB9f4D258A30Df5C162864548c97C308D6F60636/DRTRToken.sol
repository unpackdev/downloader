// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;
pragma abicoder v2;

import "./Ownable.sol";
import "./ERC1155.sol";


contract DRTRToken is ERC1155, Ownable {
    uint8 public constant decimals  = 0;
    string public name    = 'Dr Troller';
    string public symbol  = 'DRTR';

    string public contractURI;
    uint256 public totalCollections;
    mapping(uint256=>uint256) internal collections;         // Maps collection id to count of its elements
    mapping(uint256=>mapping(bytes32=>bytes)) internal properties;   // Maps item id to a mapping of property name hash to property value

    constructor(string memory url, string memory contractUrl) ERC1155(url) {
        contractURI = contractUrl;
    }

    function setURI(string calldata url) external onlyOwner {
        _setURI(url);        
    }

    function setContractURI(string calldata _contractURI) external onlyOwner {
        contractURI = _contractURI;        
    }

    function setNameAndSymbol(string calldata _name, string calldata _symbol) external onlyOwner {
        name = _name;
        symbol = _symbol;
    }

    function mintCollection(address beneficiary, uint256 itemsCount) external onlyOwner {
        require(itemsCount > 0, "nothing to mint");
        uint256[] memory ids = new uint256[](itemsCount);
        uint256[] memory amounts = new uint256[](itemsCount);
        uint256 collection = totalCollections++;
        collections[collection] = itemsCount;
        for(uint256 i=0; i<itemsCount; i++){
            ids[i] = uint256(getId(collection, i));
            amounts[i] = 1;
        }
        _mintBatch(beneficiary, ids, amounts, '');
    }

    function setProperty(bytes32 propertieHash, bytes32[] calldata ids, bytes[] calldata values) external onlyOwner {
        require(ids.length == values.length, "arrays length mismatch");
        for(uint256 i=0; i < ids.length; i++){
            properties[uint256(ids[i])][propertieHash] = values[i];
        }
    }

    function getProperty(bytes32 id, bytes32 propertieHash) external view returns(bytes memory){
        return properties[uint256(id)][propertieHash];
    }

    function itemsInCollection(uint256 collection) external view returns(uint256) {
        return collections[collection];
    }

    function getId(uint256 collection, uint256 num) public pure returns(bytes32) {
        return keccak256(abi.encodePacked(collection, num));
    }
}