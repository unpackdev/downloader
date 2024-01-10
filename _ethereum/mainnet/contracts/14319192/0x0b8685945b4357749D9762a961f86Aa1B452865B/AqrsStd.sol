// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Counters.sol";
import "./Strings.sol";

contract AqrsStd is ERC721, ERC721Enumerable, Ownable {
    using Counters for Counters.Counter;
    using Strings for uint256;

    event MetadataSet(uint256 tokenId, string metadata);

    string public contractMetadataAddress;

    Counters.Counter private _tokenIdCounter;

    mapping(uint256 => string) private _artsData;
    mapping(uint256 => string) private _metadata;
    mapping(uint256 => uint256) private _attributesExpirationDate;

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _contractMetadataAddress
    ) ERC721(_name, _symbol) {
        // nextTokenId is initialized to 1, since starting at 0 leads to higher gas cost for the first minter
        _tokenIdCounter.increment();
        contractMetadataAddress = _contractMetadataAddress;
    }

    function safeMint(
        address to,
        string memory artData,
        string memory metadata,
        uint256 expirationDate
    ) public onlyOwner {
        require(block.timestamp < expirationDate, "It is past expiration date");
        require(bytes(artData).length > 0, "Art data can't be empty");
        require(bytes(metadata).length > 0, "Metadata can't be empty");

        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
        _artsData[tokenId] = artData;
        _metadata[tokenId] = metadata;
        _attributesExpirationDate[tokenId] = expirationDate;
    }

    function getArtData(uint256 tokenId) public view returns (string memory) {
        require(_exists(tokenId), "adrData for nonexistent token");
        return string(abi.encodePacked("ipfs://", _artsData[tokenId]));
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "tokenURI for nonexistent token");
        return string(abi.encodePacked("ipfs://", _metadata[tokenId]));
    }

    function setMetadata(uint256 tokenId, string memory metadata) public onlyOwner {
        require(_exists(tokenId), "Setting attribute for non existing token");
        require(block.timestamp < _attributesExpirationDate[tokenId], "It is past expiration date");
        require(bytes(metadata).length > 0, "Metadata can't be empty");

        _metadata[tokenId] = metadata;
        emit MetadataSet(tokenId, metadata);
    }

    function contractURI() public view returns (string memory) {
        return string(abi.encodePacked(contractMetadataAddress, "/contract_meta.json"));
    }

    // Required to implement ERC721Enumerable
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
