// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./ERC20.sol";
import "./ERC721.sol";
import "./IERC721.sol";
import "./ERC721Enumerable.sol";
import "./Pausable.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./ERC721Burnable.sol";
import "./SafeMath.sol";

contract Pawn is
    ERC721,
    ERC721Enumerable,
    Pausable,
    ReentrancyGuard,
    Ownable,
    ERC721Burnable
{
    using Strings for uint256;
    mapping(uint256 => string) private _tokenURIs;
    string private _baseURIextended;

    constructor() ERC721("Pawn", "Pawn") {
        _baseURIextended = "#";
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function safeMint(address to, uint256 tokenId) internal {
        _safeMint(to, tokenId);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) whenNotPaused {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function setBaseURI(string memory baseURI_) public onlyOwner {
        _baseURIextended = baseURI_;
    }

    function _setTokenURI(uint256 tokenId, string memory _tokenURI)
        internal
        virtual
    {
        require(_exists(tokenId), "_setTokenURI: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIextended;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(tokenId), "tokenURI: URI query for nonexistent token");
        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = _baseURI();
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, tokenId.toString()));
        }
        return string(abi.encodePacked(base, tokenId.toString()));
    }

    function tokenExists(uint256 tokenId) public view returns (bool) {
        return(_exists(tokenId));
    }
}