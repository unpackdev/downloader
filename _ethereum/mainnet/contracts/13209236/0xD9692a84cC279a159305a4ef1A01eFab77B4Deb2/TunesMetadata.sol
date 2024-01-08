//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.2;

import "./Ownable.sol";
import "./IERC721Enumerable.sol";
import "./IERC721Metadata.sol";

contract TunesMetadata is Ownable {
    IERC721Enumerable public tunes;

    struct OfficialMetadata {
        string key;
        address devAddress;
    }

    mapping(string => OfficialMetadata) public officialMetadata;
    string[] public officialMetadataAliases;
    
    mapping(address => mapping(string => mapping(uint => string))) public directMetadata;
    
    mapping(address => mapping(string => address)) public inheritedMetadata;

    constructor(address _tunesAddress) {
       tunes = IERC721Enumerable(_tunesAddress);
    }

    function ownerOf(uint tokenId) public view returns (address owner) {
        require (tokenId <= tunes.totalSupply(), 'Invalid tokenID');
        return tunes.ownerOf(tokenId);
    }

    function setOfficialMetadata(address _devAddress, string memory _key, string memory _metadataKeyAlias) public onlyOwner {
        OfficialMetadata storage officialMetadataInstance = officialMetadata[_metadataKeyAlias];
        
        // Only update the keys if this was never set
        if (bytes(officialMetadataInstance.key).length == 0) {
            officialMetadataAliases.push(_metadataKeyAlias);
        }

        officialMetadataInstance.devAddress = _devAddress;
        officialMetadataInstance.key = _key;
    }
    
    function getOfficialMetadata(string memory _metadataKeyAlias, uint _tokenID) public view returns (string memory) {
        OfficialMetadata memory officialMetadataInstance = officialMetadata[_metadataKeyAlias];
        require(bytes(officialMetadataInstance.key).length > 0, "This is not an official alias.");

        return getMetadata(officialMetadataInstance.devAddress, officialMetadataInstance.key, _tokenID);
    }
    
    function getOfficialMetadataAliases() public view returns (string[] memory) {
        return officialMetadataAliases;
    }
    
    // First, check to see if there's a contract linked. Any inherited metadata always takes priority of metadata that is directly set.
    
    function getMetadata(address _devAddress, string memory _key, uint _tokenID) public view returns (string memory) {
        require (_tokenID <= tunes.totalSupply(), 'Invalid tokenID');
        address derivativeContractAddress = inheritedMetadata[_devAddress][_key];
        
        if (derivativeContractAddress != address(0)) {
            IERC721Metadata derivativeContract = IERC721Metadata(inheritedMetadata[_devAddress][_key]);
            return derivativeContract.tokenURI(_tokenID);
        }
        
        return directMetadata[_devAddress][_key][_tokenID];
    }
    
    // Direct Metadata - used to to directly set string values for a Tune.

    function setDirectMetadata(string memory _key, uint _tokenID, string memory _data) public {
        directMetadata[msg.sender][_key][_tokenID] = _data;
    }
    
    // Inherited Metadata - used to set metadata for a Tune using the tokenURI of a deployed derivativeContract

    function setInheritedMetadata(string memory _key, address _address) public {
        require (inheritedMetadata[msg.sender][_key] == address(0), "You cannot replace this address.");
        inheritedMetadata[msg.sender][_key] = _address;
    }
}