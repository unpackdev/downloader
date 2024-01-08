// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721URIStorage.sol";
import "./Pausable.sol";
import "./AccessControl.sol";
import "./ERC721Burnable.sol";
import "./Counters.sol";

/// @custom:security-contact contact@boogie-woogie.io
contract BoogieWoogieTokenContract is
    ERC721,
    ERC721Enumerable,
    ERC721URIStorage,
    Pausable,
    AccessControl,
    ERC721Burnable
{
    using Counters for Counters.Counter;
    using Strings for uint256;

    Counters.Counter private _printsSold;

    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant AUCTIONEER_ROLE = keccak256("AUCTIONEER_ROLE");
    uint256 public constant MAX_ELEMENTS = 1970;
    uint256 public constant MAX_BY_MINT = 1;

    constructor() ERC721("Boogie-Woogie", "DLBW") {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(PAUSER_ROLE, msg.sender);
        _setupRole(AUCTIONEER_ROLE, msg.sender);
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function safeMint(
        address to,
        uint256 tokenId,
        string memory uri
    ) public onlyRole(AUCTIONEER_ROLE) {
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) whenNotPaused {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    /* Overrides */
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

    function addAuctioneer(address auctioneer)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        grantRole(AUCTIONEER_ROLE, auctioneer);
    }

    function purchase(
        address buyer,
        uint256 tokenId,
        string memory metaUri
    ) external onlyRole(AUCTIONEER_ROLE) returns (uint256) {
        require(_printsSold.current() <= MAX_ELEMENTS, "Sold Out");

        _printsSold.increment();

        _safeMint(buyer, tokenId);
        _setTokenURI(tokenId, metaUri);

        return tokenId;
    }
}
