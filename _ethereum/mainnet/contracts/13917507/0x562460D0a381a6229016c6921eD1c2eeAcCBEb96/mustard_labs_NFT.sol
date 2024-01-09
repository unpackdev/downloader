// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC721.sol";
import "./ERC721URIStorage.sol";
import "./Pausable.sol";
import "./Ownable.sol";
import "./Counters.sol";

contract MustardLabsContributor is ERC721, ERC721URIStorage, Pausable, Ownable {
    using Counters for Counters.Counter;

    uint version = 2;
    bool frozen = false;
    string baseURI = "ipfs://QmRUiVuLfnAGm2iGMKdzfLknQ71g55euvhtE3KZk3YqHaR/";
    Counters.Counter private _tokenIdCounter;

    constructor() ERC721("MustardLabs", "ML") {}

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function getBaseURI() public view returns (string memory){
        return baseURI;
    }

    function setBaseURI(string memory __baseURI) public onlyOwner {
        require(frozen == false, "Contract is locked");
        string memory _pre = "ipfs://";
        string memory _post = "/";
        __baseURI = string(abi.encodePacked(_pre, __baseURI, _post));
        baseURI = __baseURI;
    }

    function freeze() public onlyOwner {
        frozen = true;
    }

    function isFrozen() public view returns (bool) {
        return frozen;
    }

    function getVersion() public view returns (uint) {
        return version;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function safeMint(address to) public onlyOwner {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
    }

    function setTokenURI(uint _tokenId, string memory uri) public onlyOwner {
        require(frozen == false, "Contract is locked");
        _setTokenURI(_tokenId, uri);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        whenNotPaused
        override
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    // The following functions are overrides required by Solidity.

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
}