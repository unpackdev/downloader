// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

import "./Counters.sol";
import "./EnumerableSet.sol";
import "./ReentrancyGuard.sol";

import "./ERC721.sol";
import "./IERC721.sol";
import "./ERC721Burnable.sol";
import "./ERC721Enumerable.sol";
import "./ERC721URIStorage.sol";

import "./ITux.sol";


contract Tux is
    ITux,
    ERC721,
    ERC721URIStorage,
    ERC721Enumerable,
    ERC721Burnable,
    ReentrancyGuard
{
    using Counters for Counters.Counter;
    using EnumerableSet for EnumerableSet.UintSet;

    string private _baseTokenURI = 'ipfs://';

    Counters.Counter private _tokenIdTracker;

    mapping(uint256 => address) public tokenCreators;

    mapping(address => EnumerableSet.UintSet) private _creatorTokens;


    constructor(
        string memory name,
        string memory symbol
    ) ERC721(name, symbol) {}

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);

        address creator = tokenCreators[tokenId];
        delete tokenCreators[tokenId];
        _creatorTokens[creator].remove(tokenId);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function owner() public pure returns (address) {
        return address(0);
    }

    function tokenCreator(uint256 tokenId) public view override returns (address) {
        return tokenCreators[tokenId];
    }

    function getCreatorTokens(address creator) public view override returns (uint256[] memory) {
        return _creatorTokens[creator].values();
    }

    function tokenURI(uint256 tokenId)
        public view virtual override(ERC721, ERC721URIStorage) returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function mint(string memory _tokenURI)
        public
        nonReentrant
    {
        require(bytes(_tokenURI).length != 0, 'Tux: empty tokenURI');

        _tokenIdTracker.increment();

        uint256 tokenId = _tokenIdTracker.current();

        _safeMint(msg.sender, tokenId);

        _setTokenURI(tokenId, _tokenURI);

        _creatorTokens[msg.sender].add(tokenId);

        tokenCreators[tokenId] = msg.sender;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(IERC165, ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
