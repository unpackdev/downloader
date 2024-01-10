// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./AccessControlEnumerable.sol";
import "./Counters.sol";

contract UnETHicalCupidsHonorary is ERC721, ERC721Enumerable, AccessControlEnumerable {
    
    using Counters for Counters.Counter;

    string public baseURI;

    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");
    Counters.Counter private _tokenIdCounter;

    constructor() ERC721("UnETHical Cupids Honorary", "UCH") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MANAGER_ROLE, msg.sender);
        _tokenIdCounter.increment();
    }

    function setBaseURI(string memory _URI) external onlyRole(MANAGER_ROLE) {
        baseURI = _URI;
    }

    function _baseURI() internal view override(ERC721) returns (string memory) {
        return baseURI;
    }

    function safeMint(address to) public onlyRole(MANAGER_ROLE) {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable, AccessControlEnumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}