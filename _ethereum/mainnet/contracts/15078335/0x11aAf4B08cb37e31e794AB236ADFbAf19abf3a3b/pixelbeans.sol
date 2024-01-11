// SPDX-License-Identifier: MIT

import "./ERC721A.sol";

pragma solidity ^0.8.15;

contract pixelbeans is ERC721A
{

    using Strings for uint256;

    bool mintStatus;
    address public owner;
    string public _baseTokenUri;
    string public _defaultURI;
    mapping(address => uint256) public minters;

    constructor(
        string memory name,
        string memory symbol,
        string memory baseTokenURI,
        string memory defaultURI,
        uint256 maxBatch,
        uint256 collectionSize
    ) ERC721A(name, symbol, maxBatch, collectionSize) {

        _baseTokenUri = baseTokenURI;
        owner = _msgSender();
        _defaultURI = defaultURI;
    }

    function mint(uint256 amount) external {

        require(mintStatus, "mint: minting not yet started.");
        require(totalSupply() + amount <= collectionSize, "mint: max. supply reached.");
        uint256 minterMinted = minters[_msgSender()];
        require(minterMinted + amount <= maxBatchSize, "mint: max. mint per wallet reached.");

        minters[_msgSender()] += amount;
        _safeMint(_msgSender(), amount, "");
    }

    function _baseURI() internal view virtual override returns (string memory) {

        return _baseTokenUri;
    }
    
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
          
        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json")) : _defaultURI;
    }
    
    function setBaseUri(string calldata baseTokenURI) public virtual {

        require(_msgSender() == owner, "setBaseUri: must be owner to set base uri.");

        _baseTokenUri = baseTokenURI;
    }

    function setMintStatus(bool status) external
    {
        require(_msgSender() == owner, "setMintStatus: not the owner");

        mintStatus = status;
    }

    function transferOwnership(address newOwner) external
    {
        require(_msgSender() == owner, "transferOwnership: not the owner");

        owner = newOwner;
    }
}