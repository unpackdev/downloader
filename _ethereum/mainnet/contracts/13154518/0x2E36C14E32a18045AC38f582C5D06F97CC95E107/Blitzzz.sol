// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721URIStorage.sol";
import "./ERC721Burnable.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./ReentrancyGuard.sol";

contract TokenContractDummy {
    function ownerOf(uint256 tokenId) public view virtual returns (address) {}
}

contract Blitzzz is ERC721, ERC721Enumerable, ERC721URIStorage, ERC721Burnable, ReentrancyGuard, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    struct TokenParents {
        uint256 blitmapTokenId;
        uint256 dreamloopTokenId;
    }

    TokenContractDummy blitmapContract = TokenContractDummy(0x8d04a8c79cEB0889Bdd12acdF3Fa9D207eD3Ff63);
    TokenContractDummy dreamloopsContract = TokenContractDummy(0xf1B33aC32dbC6617f7267a349be6ebb004FeCcff);

    mapping(uint256 => TokenParents) private _tokenParentIndex;
    mapping(uint256 => bool) private _blitmapTokens;
    mapping(uint256 => bool) private _dreamloopTokens;

    string private _baseTokenURI;
    uint256 private _price = 0.03 ether;

    event BaseURLUpdated(string url);
    event TokenURLUpdated(uint256 tokenId, string url);

    constructor() ERC721("Blitzzz", "BLITZ") {
        _baseTokenURI = "https://blitzzz.niftyfuse.me/tokens/";
    }

    function forge(uint256 blitmapTokenId, uint256 dreamloopTokenId) public payable nonReentrant {
        if(_tokenIdCounter.current() > 14) {
            require(msg.value == _price, "Ether sent is not correct");
        }

        require(_ownsBlitmap(blitmapTokenId) && _ownsDreamloop(dreamloopTokenId), "You don't own this Blitmap or Dream Loop");

        // Every Blitmap or Dreamloop can only be used once
        require(_blitmapTokens[blitmapTokenId] == false, "Blitmap was already used");
        require(_dreamloopTokens[dreamloopTokenId] == false, "Dreamloop was already used");

        _safeMint(msg.sender, _tokenIdCounter.current());

        TokenParents memory parents;
        parents.blitmapTokenId = blitmapTokenId;
        parents.dreamloopTokenId = dreamloopTokenId;
        _tokenParentIndex[_tokenIdCounter.current()] = parents;

        _tokenIdCounter.increment();

        _blitmapTokens[blitmapTokenId] = true;
        _dreamloopTokens[dreamloopTokenId] = true;
    }

    function withdrawAll() public payable onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }

    function updateTokenURI(uint256 tokenId, string memory _tokenURI) public onlyOwner {
        _setTokenURI(tokenId, _tokenURI);
        emit TokenURLUpdated(tokenId, _tokenURI);
    }

    function updateBaseTokenURI(string memory uri) public onlyOwner {
        _baseTokenURI = uri;
        emit BaseURLUpdated(uri);
    }

    function updatePrice(uint256 amount) public onlyOwner {
        _price = amount;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function getParentBlitmapByIndex(uint256 tokenId) public view returns (uint256) {
        TokenParents memory parents = _tokenParentIndex[tokenId];
        return parents.blitmapTokenId;
    }

    function getParentDreamloopByIndex(uint256 tokenId) public view returns (uint256) {
        TokenParents memory parents = _tokenParentIndex[tokenId];
        return parents.dreamloopTokenId;
    }

    function blitmapUsed(uint256 blitmapTokenId) public view returns (bool) {
        return _blitmapTokens[blitmapTokenId] == true;
    }

    function dreamloopUsed(uint256 dreamloopTokenId) public view returns (bool) {
        return _dreamloopTokens[dreamloopTokenId] == true;
    }

    function _ownsBlitmap(uint256 tokenId) private view returns (bool) {
        return blitmapContract.ownerOf(tokenId) == msg.sender;
    }

    function _ownsDreamloop(uint256 tokenId) private view returns (bool) {
        return dreamloopsContract.ownerOf(tokenId) == msg.sender;
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
}
