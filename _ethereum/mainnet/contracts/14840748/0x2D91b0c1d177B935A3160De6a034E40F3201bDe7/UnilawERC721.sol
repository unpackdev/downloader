// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./Counters.sol";
import "./ERC721URIStorage.sol";
import "./ERC721.sol";
import "./Ownable.sol";
import "./ERC721Enumerable.sol";


contract UnilawSharesERC721 is ERC721, ERC721Enumerable, ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter internal _tokenIds;
    string private __baseURI;

    uint8 HARD_CAP = 69;

    event BatchMinted(uint256 startId, uint256 endId);

    constructor(string memory _name, string memory _symbol, string memory baseURI_)
    ERC721(_name, _symbol)
    {
        __baseURI = baseURI_;
    }


    function mint(string memory tokenURI_)
    public
    virtual
    onlyOwner
    returns (uint256)
    {
        _tokenIds.increment();
        require(_tokenIds.current() <= HARD_CAP, "All tokens already minted!");
        uint256 newItemId = _tokenIds.current();

        _mint(msg.sender, newItemId);
        _setTokenURI(newItemId, tokenURI_);

        return newItemId;
    }

    function mintTo(string memory tokenURI_, address to)
    public
    virtual
    onlyOwner
    returns (uint256)
    {
        _tokenIds.increment();
        uint256 newItemId = _tokenIds.current();
        require(_tokenIds.current() <= HARD_CAP, "All tokens already minted!");
        _mint(to, newItemId);
        _setTokenURI(newItemId, tokenURI_);

        return newItemId;
    }

    function batchMintTo(string[] memory tokenURIs_, address to)
    public
    virtual
    onlyOwner
    {
        require(HARD_CAP>=(_tokenIds.current()+tokenURIs_.length), "You try to mint too many tokens");
        uint256 startId = _tokenIds.current() + 1;

        for (uint256 i = 0; i < tokenURIs_.length; i++) {
            mintTo(tokenURIs_[i], to);
        }

        uint256 endId = _tokenIds.current();

        if (startId < endId) {
            emit BatchMinted(startId, endId);
        }
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return __baseURI;
    }

    function tokenURI(uint256 tokenId)
    public
    view
    override(ERC721, ERC721URIStorage)
    returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
    internal
    override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        revert("Burning not allowed");
    }

    function ownerOf(uint256 tokenId) public view override(ERC721, IERC721) returns (address){
        require(_exists(tokenId), "Token does not exist");
        return super.ownerOf(tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}