// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity 0.8.4;

import "./ERC721Upgradeable.sol";
import "./AddressUpgradeable.sol";
import "./WethioMarketNode.sol";
import "./NFT721Metadata.sol";
import "./WethioAdminRole.sol";

/**
 * @notice Allows creators to mint NFTs.
 */
abstract contract NFT721Mint is
    WethioAdminRole,
    ERC721Upgradeable,
    WethioMarketNode,
    NFT721Metadata
{
    using AddressUpgradeable for address;

    uint256 private nextTokenId;

    event Minted(
        address indexed creator,
        uint256 indexed tokenId,
        string tokenUri
    );

    /**
     * @notice Gets the tokenId of the next NFT minted.
     */
    function getNextTokenId() public view returns (uint256) {
        return nextTokenId;
    }

    /**
     * @dev Called once after the initial deployment to set the initial tokenId.
     */
    function _initializeNFT721Mint() internal initializer {
        // Use ID 1 for the first NFT tokenId
        nextTokenId = 0;
    }

    /**
     * @notice Allows a creator to mint an NFT.
     */
    function mintAndApproveMarket(string memory tokenPath)
        public
        returns (uint256 tokenId)
    {
        tokenId = nextTokenId++;
        _mint(address(msg.sender), tokenId);
        _setTokenUriPath(tokenId, tokenPath);
        setApprovalForAll(getWethioMarket(), true);
        emit Minted(msg.sender, tokenId, tokenPath);
    }

    /**
     * @dev Explicit override to address compile errors.
     */
    function _burn(uint256 tokenId)
        internal
        virtual
        override(ERC721Upgradeable, NFT721Metadata)
    {
        super._burn(tokenId);
    }

    uint256[1000] private __gap;
}
