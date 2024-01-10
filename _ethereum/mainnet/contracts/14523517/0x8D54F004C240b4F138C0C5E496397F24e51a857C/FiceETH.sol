// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721URIStorage.sol";
import "./Pausable.sol";
import "./Ownable.sol";
import "./ERC721Burnable.sol";
import "./Counters.sol";

contract FiceETH is ERC721, ERC721Enumerable, ERC721URIStorage, Pausable, Ownable, ERC721Burnable {

    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    mapping(address => bool) public _permit;

    mapping(uint256 => uint256) public levels;

    constructor() ERC721("FICE", "FICE") {
        safeMint(owner(), "https://ipfs.io/ipfs/QmekVxR6sGVKTrtjNw3eso48oPreChRPEAfKsgW2PJTtTv/IFC1.json", 3);
        safeMint(owner(), "https://ipfs.io/ipfs/QmekVxR6sGVKTrtjNw3eso48oPreChRPEAfKsgW2PJTtTv/IFC2.json", 3);
        safeMint(owner(), "https://ipfs.io/ipfs/QmekVxR6sGVKTrtjNw3eso48oPreChRPEAfKsgW2PJTtTv/IFC51.json", 2);
        safeMint(owner(), "https://ipfs.io/ipfs/QmekVxR6sGVKTrtjNw3eso48oPreChRPEAfKsgW2PJTtTv/IFC52.json", 2);
        safeMint(owner(), "https://ipfs.io/ipfs/QmekVxR6sGVKTrtjNw3eso48oPreChRPEAfKsgW2PJTtTv/IFC101.json", 1);
        safeMint(owner(), "https://ipfs.io/ipfs/QmekVxR6sGVKTrtjNw3eso48oPreChRPEAfKsgW2PJTtTv/IFC102.json", 1);
        safeMint(owner(), "https://ipfs.io/ipfs/QmekVxR6sGVKTrtjNw3eso48oPreChRPEAfKsgW2PJTtTv/IFC-Plan-A.json", 4);
        safeMint(owner(), "https://ipfs.io/ipfs/QmekVxR6sGVKTrtjNw3eso48oPreChRPEAfKsgW2PJTtTv/IFC-Plan-A.json", 4);
        safeMint(owner(), "https://ipfs.io/ipfs/QmekVxR6sGVKTrtjNw3eso48oPreChRPEAfKsgW2PJTtTv/IFC-Plan-B.json", 5);
        safeMint(owner(), "https://ipfs.io/ipfs/QmekVxR6sGVKTrtjNw3eso48oPreChRPEAfKsgW2PJTtTv/IFC-Plan-B.json", 5);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function safeMint(address to, string memory uri, uint256 _level) public onlyOwner {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        levels[tokenId] = _level;
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);
    }

    function safeMint(address to, string memory uri, uint256 tokenId, uint256 _level) public onlyOwner {
        levels[tokenId] = _level;
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);
    }

    modifier checkPermit(address acount) {
        require(_permit[acount], "Not permit");
        _;
    }

    function safeMintBox(address to, string memory uri, uint256 _level) external checkPermit(msg.sender) {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        levels[tokenId] = _level;
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);
    }

    function safeMintBox(address to, string memory uri, uint256 tokenId, uint256 _level) external checkPermit(msg.sender) {
        levels[tokenId] = _level;
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        whenNotPaused
        override(ERC721, ERC721Enumerable)
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

    function setTokenURI(uint256 tokenId, string memory _tokenURI) public onlyOwner {
        _setTokenURI(tokenId, _tokenURI);
    }

    function setTokenURI(uint256[] memory tokenIds, string[] memory _tokenURIs) public onlyOwner {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            _setTokenURI(tokenIds[i], _tokenURIs[i]);
        }
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function permit(address _account) external onlyOwner {
        require(!_permit[_account], "Already permit");
        _permit[_account] = true;
    }

    function Unpermit(address _account) external onlyOwner {
        _permit[_account] = false;
    }
}