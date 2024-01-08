// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC1155Supply.sol";
import "./Ownable.sol";

contract DivineObjects is  ERC1155Supply, Ownable {

    mapping(uint256 => string) internal _tokenMetadata;
    mapping(uint256 => uint256) internal _maxSupply;
    
    modifier tokenExists(uint256 tokenId) {
        require(bytes(_tokenMetadata[tokenId]).length != 0, "Token doesn't exist.");
        _;
    }
    
    constructor() ERC1155("") {}

    function mint(address wallet, uint256 tokenId) public tokenExists(tokenId) onlyOwner {
        require(totalSupply(tokenId) +1 <= _maxSupply[tokenId], "Max supply already claimed.");
        _mint(wallet, tokenId, 1, "");
    }
    
    function mintMultiple(address[] memory addresses, uint256 tokenId)  public tokenExists(tokenId) onlyOwner {
        require(totalSupply(tokenId) + addresses.length <= _maxSupply[tokenId], "Max supply already claimed.");
        for (uint256 i = 0; i < addresses.length; i++) {
            _mint(addresses[i], tokenId, 1, "");
        }
    }

    function addNewToken(uint256 tokenId, string calldata ipfsHash, uint256 maxSupply) public onlyOwner {
        require(bytes(_tokenMetadata[tokenId]).length == 0, "Token already exists.");
        require(maxSupply > 0, "Max supply must be more than 0");
        _tokenMetadata[tokenId] = ipfsHash;
        _maxSupply[tokenId] = maxSupply;
    }

    function updateMaxSupply(uint256 tokenId, uint256 maxSupply) public tokenExists(tokenId) onlyOwner {
        require(maxSupply > _maxSupply[tokenId], "Max supply must be more than previous amount");
        _maxSupply[tokenId] = maxSupply;
    }

    function uri(uint256 tokenId) public tokenExists(tokenId) view override returns (string memory) {
        return string(abi.encodePacked("ipfs://", _tokenMetadata[tokenId]));
    }
}