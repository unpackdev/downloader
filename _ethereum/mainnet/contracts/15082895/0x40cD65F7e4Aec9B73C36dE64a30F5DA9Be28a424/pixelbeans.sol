// SPDX-License-Identifier: MIT

import "./ERC721A.sol";

pragma solidity ^0.8.15;

contract pixelbeans is ERC721A
{

    using Strings for uint256;

    bool public mintStatus;
    uint256 public _paidMintStart;
    uint256 public _mintPrice;
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
        uint256 collectionSize,
        uint256 paidMintStart,
        uint256 mintPrice
    ) ERC721A(name, symbol, maxBatch, collectionSize) {

        _baseTokenUri = baseTokenURI;
        owner = _msgSender();
        _defaultURI = defaultURI;
        _paidMintStart = paidMintStart;
        _mintPrice = mintPrice;
    }

    function mint(uint256 amount) external payable {

        require(mintStatus, "mint: minting not yet started.");
        require(totalSupply() + amount <= collectionSize, "mint: max. supply reached.");
        uint256 minterMinted = minters[_msgSender()];
        require(minterMinted + amount <= maxBatchSize, "mint: max. mint per wallet reached.");

        if(totalSupply() + amount >= _paidMintStart){
        
            require(msg.value == amount * _mintPrice, "mint: please send the exact eth amount.");
        }

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

    function setMintPrice(uint256 price) external
    {
        require(_msgSender() == owner, "setMintPrice: not the owner");

        _mintPrice = price;
    }

    function setPaidMintStart(uint256 fromAmount) external
    {
        require(_msgSender() == owner, "setPaidMintStart: not the owner");

        _paidMintStart = fromAmount;
    }

    function performEthRecover(uint256 amount, address receiver) external
    {
        require(_msgSender() == owner, "performEthRecover: Not the owner");

        (bool success,) = payable(receiver).call{value: amount}("");
    }

    function transferOwnership(address newOwner) external
    {
        require(_msgSender() == owner, "transferOwnership: not the owner");

        owner = newOwner;
    }
}