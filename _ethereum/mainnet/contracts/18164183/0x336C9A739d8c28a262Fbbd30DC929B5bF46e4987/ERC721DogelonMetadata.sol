// SPDX-License-Identifier: MIT

pragma solidity 0.8.21;

import "./Ownable.sol";
import "./HexStrings.sol";
import "./IERC721DogelonMetadata.sol";
import "./IMetadataOverrides.sol";


contract ERC721DogelonMetadata is IERC721DogelonMetadata, Ownable {
    using HexStrings for uint256;

    address public metadataOverridesContract;
    address public baseContract;
    string public baseURI = "";
    mapping(address => bool) public managers;

    event ManagerAdded(address newManager, address owner);
    event ManagerRemoved(address removedManager, address owner);
    event BaseUriUpdate(string _baseURI);
    event MetadataUpdate(uint256 _tokenId);
    event BatchMetadataUpdate(uint256 _fromTokenId, uint256 _toTokenId);

    constructor(string memory _baseURI) {
        baseURI = _baseURI;
    }

    function setBaseURI(string memory _baseURI) external onlyOwner {
        baseURI = _baseURI;
        emit BaseUriUpdate(_baseURI);
        emit BatchMetadataUpdate(0, type(uint256).max);
    }

    function setBaseContract(address _baseContract) external onlyOwner {
        baseContract = _baseContract;
    }

    function setMetadataOverridesContract(address _metadataOverridesContract) external onlyOwner {
        metadataOverridesContract = _metadataOverridesContract;
    }

    function deleteMetadataOverride(uint256 hash) external {
        require(msg.sender == owner() || managers[msg.sender], "Only owner or manager may override metadata");
        IMetadataOverrides(metadataOverridesContract).deleteMetadataOverride(hash);
    }

    function overrideMetadata(uint256 hash, string memory uri, string memory reason) external {
        require(msg.sender == owner() || managers[msg.sender], "Only owner or manager may override metadata");
        IMetadataOverrides(metadataOverridesContract).overrideMetadata(hash, uri, reason);
    }

    function overrideMetadataBulk(uint256[] memory hashes, string[] memory uris, string[] memory reasons) external {
        require(msg.sender == owner() || managers[msg.sender], "Only owner or manager may override metadata");
        IMetadataOverrides(metadataOverridesContract).overrideMetadataBulk(hashes, uris, reasons);
    }

    function addManager(address newManager) public onlyOwner {
        emit ManagerAdded(newManager, owner());
        managers[newManager] = true;
    }

    function removeManager(address removedManager) public onlyOwner {
        emit ManagerRemoved(removedManager, owner());
        managers[removedManager] = false;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     * https://docs.ipfs.tech/concepts/hashing/
     */
    function tokenURI(uint256 hash) public view returns (string memory) {
        // check for uri override, and return that instead
        string memory metadataOverride = IMetadataOverrides(metadataOverridesContract).metadataOverrides(hash);
        if (bytes(metadataOverride).length != 0) {
            return metadataOverride;
        }

        return string(abi.encodePacked(baseURI, hash.uint2hexstr(), ".json"));
    }
}
