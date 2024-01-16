// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

import "ERC721.sol";
import "ERC721Enumerable.sol";
import "ERC721URIStorage.sol";
import "Ownable.sol";
import "Counters.sol";


contract NftCollectible is ERC721, ERC721Enumerable, ERC721URIStorage, Ownable {
//    Smart contract for saving NFT tokens

    using Counters for Counters.Counter;

    // Counter for creating ids
    Counters.Counter private _tokenIdCounter;

    constructor (string memory name_, string memory symbol_) ERC721(name_, symbol_){}

    // Mint collectible, msg.sender will owner of the minted token
    function createCollectible(string memory uri) public returns (uint256) {
        safeMint(msg.sender, uri);
        uint256 newItemId = _tokenIdCounter.current();
        return newItemId;
    }

    // From openzeppelin docs
    function safeMint(address to, string memory uri) public onlyOwner {
        _tokenIdCounter.increment();
        uint256 tokenId = _tokenIdCounter.current();
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);
    }

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
    internal
    override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
    public
    view
    override(ERC721, ERC721URIStorage)
    returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
    public
    view
    override(ERC721, ERC721Enumerable)
    returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function tokensOfOwner(address owner) public view returns (uint[] memory) {
        uint[] memory _tokensOfOwner = new uint[](balanceOf(owner));
        uint i;

        for (i = 0; i < balanceOf(owner); i++) {
            _tokensOfOwner[i] = tokenOfOwnerByIndex(owner, i);
        }
        return (_tokensOfOwner);
    }
}
