// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC721Burnable.sol";
import "./IERC721Metadata.sol";

contract WrappedODBS is ERC721Burnable {
    /// @dev Otherdeed ethereum address
    address public constant OTHERDEED_CONTRACT = 0x34d85c9CDeB23FA97cb08333b511ac86E1C4E258;

    event SafeWrap(address from, uint256 tokenId);

    event SafeUnwrap(
        address from,
        address to,
        uint256 tokenId
    );

    constructor() ERC721("Wrapped Otherdeed for Biogenic Swamp", "ODBS") {}

    /// @notice Only receive sediment tier 5, i.e, biogenic swamp
    /// @param tokenId tokenId of the otherdeed
    function safeWrap(uint256 tokenId) external {
        // tokenIds of biogenic swamp are within 10000
        require(tokenId <= 9999, "ODBS: not Biogenic Swamp");

        IERC721(OTHERDEED_CONTRACT).transferFrom(
            _msgSender(),
            address(this),
            tokenId
        );
        _safeMint(_msgSender(), tokenId);
        emit SafeWrap(_msgSender(), tokenId);
    }

    /// @notice Burn an ODBS and release the corresponding OTHR
    /// @param tokenId tokenId of the ODBS
    function safeUnwrap(uint256 tokenId) external {
        address owner = ownerOf(tokenId);
        burn(tokenId);
        IERC721(OTHERDEED_CONTRACT).safeTransferFrom(
            address(this),
            _msgSender(),
            tokenId
        );

        emit SafeUnwrap(owner, _msgSender(), tokenId);
    }

    /// @notice Returns the Uniform Resource Identifier (URI) for an ODBS.
    /// @dev This will return the corresponding otherdeed token uri
    /// @param tokenId tokenId of the ODBS
    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(
        _exists(tokenId),
        "ERC721URIStorage: URI query for nonexistent token"
        );

        return IERC721Metadata(OTHERDEED_CONTRACT).tokenURI(tokenId);
    }
}
