// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721URIStorage.sol";
import "./ERC721Burnable.sol";
import "./AccessControl.sol";
import "./Counters.sol";

/**
 *  __    __     __  __     ______   ______   ______     ______
 * /\ "-./  \   /\_\_\_\   /\__  _\ /\__  _\ /\  ___\   /\  == \
 * \ \ \-./\ \  \/_/\_\/_  \/_/\ \/ \/_/\ \/ \ \  __\   \ \  __<
 *  \ \_\ \ \_\   /\_\/\_\    \ \_\    \ \_\  \ \_____\  \ \_\ \_\
 *   \/_/  \/_/   \/_/\/_/     \/_/     \/_/   \/_____/   \/_/ /_/
 *
 * @title Token contract for Mxtter DAO/auction pieces
 * @dev This contract allows the distribution of Mxtter tokens
 *
 *
 * MXTTER X BLOCK::BLOCK
 *
 * Smart contract work done by joshpeters.eth
 */

contract MxtterToken is
    AccessControl,
    ERC721,
    ERC721Enumerable,
    ERC721URIStorage,
    ERC721Burnable
{
    using Counters for Counters.Counter;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant UPDATER_ROLE = keccak256("UPDATER_ROLE");

    Counters.Counter private _tokenIdCounter;
    mapping(uint256 => bytes32) public hashForToken;

    bool public isMintActive;

    constructor() ERC721("MxtterToken", "MXTR") {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(MINTER_ROLE, msg.sender);
        _setupRole(UPDATER_ROLE, msg.sender);
        isMintActive = false;

        // Index tokens from 1
        _tokenIdCounter.increment();
    }

    function mintToken(address to, string memory uri)
        public
        onlyRole(MINTER_ROLE)
        returns (uint256)
    {
        require(isMintActive, "Mint not active");

        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);
        hashForToken[tokenId] = _getHash(tokenId);
        return tokenId;
    }

    function _getHash(uint256 tokenId) private view returns (bytes32) {
        return
            keccak256(abi.encodePacked(tokenId, blockhash(block.number - 1)));
    }

    function getTokenHash(uint256 tokenId) public view returns (bytes32) {
        return hashForToken[tokenId];
    }

    function flipMintState() external onlyRole(MINTER_ROLE) {
        isMintActive = !isMintActive;
    }

    function setTokenURI(uint256 _tokenId, string memory _tokenURI)
        public
        onlyRole(UPDATER_ROLE)
    {
        _setTokenURI(_tokenId, _tokenURI);
    }

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId)
        internal
        override(ERC721, ERC721URIStorage)
    {
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
        override(ERC721, ERC721Enumerable, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
