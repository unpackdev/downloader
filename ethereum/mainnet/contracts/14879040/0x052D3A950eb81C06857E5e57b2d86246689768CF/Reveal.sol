// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

// Imports.
import "./Strings.sol";
import "./Ownable.sol";

/**
 * @title The NFT Reveal contract.
 */
contract Reveal is Ownable {
    using Strings for uint256;
    /// The base URL.
    string private _baseUri = "ipfs://none";
    /// The URL that used until NFTs are revealed.
    string private _unrevealedUri;
    /// The flag that indicates if NFTs have been revealed.
    bool public revealed = false;

    /**
     * @notice The constructor that initializes the reveal smart contract.
     * @param unrevealedUrl The URL of a media that is used with unrevealed NFTs.
     */
    constructor(string memory unrevealedUrl) {
        _unrevealedUri = unrevealedUrl;
    }

    /**
     * @notice Reveals the NFTs.
     * @dev Sets the `revealed` flag to `true` that causes `getTokenUri` to return the real NFT URI.
     *      Is only available for the users with the `DEFAULT_ADMIN_ROLE` role.
     */
    function reveal() external onlyOwner {
        revealed = true;
    }

    /**
     * @notice Unreveals the NFTs.
     * @dev Sets the `revealed` flag to `false` that causes `getTokenUri` to return the unrevealed media URL.
     *      Is only available for the users with the `DEFAULT_ADMIN_ROLE` role.
     */
    function unreveal() external onlyOwner {
        revealed = false;
    }

    /**
     * @notice Sets the base URL that is used to generate custom NFT URIs.
     * @dev Automatically reveals the NFTs.
     *      Is only available for the users with the `DEFAULT_ADMIN_ROLE` role.
     * @param baseUri The URL to set as the base URL.
     */
    function setBaseUri(string memory baseUri) external onlyOwner {
        _baseUri = baseUri;
        revealed = true;
    }

    /**
     * @notice Sets the URL of a media that will be shown while NFTs are unrevealed.
     * @dev Is only available for the users with the `DEFAULT_ADMIN_ROLE` role.
     * @param unrevealedUri The URL of the media to show for unrevealed NFTs.
     */
    function setUnrevealedUri(string memory unrevealedUri) external onlyOwner {
        _unrevealedUri = unrevealedUri;
    }

    /**
     * @notice Returns the base URL.
     * @return The base URL.
     */
    function getBaseUri() public view returns (string memory) {
        return _baseUri;
    }

    /**
     * @notice Generates the NFT URI.
     * @dev If the `revealed` flag is `false` the `_unrevealedUrl` is returned, else the function calculates
     *      the real NFT URI.
     * @param tokenId The ID of the token to get the URI for.
     * @return The NFT URI.
     */
    function _getTokenUri(uint256 tokenId) internal view returns (string memory) {
        if (!revealed) {
            return _unrevealedUri;
        }

        return
        bytes(_baseUri).length != 0
        ? string(abi.encodePacked(_baseUri, tokenId.toString(), ".json"))
        : "";
    }
}
