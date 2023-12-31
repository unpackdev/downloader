// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./ERC721MetadataStorage.sol";
import "./AccessControlInternal.sol";
import "./IRenderMetadata.sol";
import "./SeedStorage.sol";
import "./Strings.sol";
import "./MintStorage.sol";

/**
 *  ╔╗  ╔╗╔╗      ╔╗ ╔╗     ╔╗
 *  ║╚╗╔╝╠╝╚╗     ║║ ║║     ║║
 *  ╚╗║║╔╬╗╔╬═╦╦══╣║ ║║  ╔══╣╚═╦══╗
 *   ║╚╝╠╣║║║╔╬╣╔╗║║ ║║ ╔╣╔╗║╔╗║══╣
 *   ╚╗╔╣║║╚╣║║║╚╝║╚╗║╚═╝║╔╗║╚╝╠══║
 *    ╚╝╚╝╚═╩╝╚╩══╩═╝╚═══╩╝╚╩══╩══╝
 */

/**
 * @title  RenderMetadataFacet
 * @author slvrfn
 * @notice The role of this contract is to handle how each Relic is rendered.
 * @dev    This contract is separated to allow for later rendering updates if needed
 */
contract OffChainMetadataFacet is IRenderMetadata, AccessControlInternal {
    using SeedStorage for SeedStorage.Layout;
    using MintStorage for MintStorage.Layout;
    using ERC721MetadataStorage for ERC721MetadataStorage.Layout;

    /**
     * @dev Raised if a user tries to use an Invalid Token id.
     */
    error InvalidToken();

    /**
     * @dev Broadcast there is a metadata update when the base URI is updated
     */
    event BatchMetadataUpdate(uint256 _fromTokenId, uint256 _toTokenId);

    /**
     * @notice Returns DNA associated with a Relic
     * @param  tokenId - the token id associated with some DNA.
     */
    function tokenDna(uint256 tokenId) public view returns (uint256) {
        MintStorage.Layout storage m = MintStorage.layout();
        // if checking un-minted token, raise error
        if (tokenId >= m._tokenIdCounter()) {
            revert InvalidToken();
        }

        uint256 globalSeed = SeedStorage.layout()._seed();
        // derive the tokens "dna" from its tokenId hashed with the global seed
        return uint256(keccak256(abi.encodePacked(globalSeed, tokenId)));
    }

    /**
     * @notice Renders metadata for a Relic.
     * @dev    Bytes used here to allow for potential future iterations to pass different data required for rendering.
     * @param  tokenId - the tokenId associated with this seed update.
     * @param  data - Encoded data for use in rendering Relic metadata.
     */
    function renderMetadata(uint256 tokenId, bytes calldata data) public view returns (string memory) {
        // derive the tokens "dna" from its tokenId hashed with the global seed
        uint256 tokenDNA = tokenDna(tokenId);

        // solhint-disable-next-line no-unused-vars
        (string memory baseUrl, string memory unusedBaseRelicUrl) = abi.decode(data, (string, string));

        string memory tokenStr = Strings.toString(tokenId);

        string memory tokenDNAStr = Strings.toHexString(tokenDNA);

        return string.concat(baseUrl, tokenStr, "/", tokenDNAStr);
    }

    /**
     * @notice Updates baseUri used for all relics, and raises a metadata update event.
     * @param  newUri - the new uri.
     */
    function setBaseUri(string calldata newUri) external onlyRole(keccak256("admin")) {
        ERC721MetadataStorage.Layout storage m = ERC721MetadataStorage.layout();
        m.baseURI = newUri;
        emit BatchMetadataUpdate(0, type(uint256).max);
    }
}
