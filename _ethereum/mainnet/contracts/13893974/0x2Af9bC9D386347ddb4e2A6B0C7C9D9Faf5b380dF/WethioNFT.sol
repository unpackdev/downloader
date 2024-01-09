// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity 0.8.4;

import "./ERC721Upgradeable.sol";
import "./WethioAdminRole.sol";
import "./WethioOperatorRole.sol";
import "./WethioMarketNode.sol";
import "./WethioTreasuryNode.sol";
import "./NFT721Metadata.sol";
import "./NFT721Mint.sol";
import "./OwnableUpgradeable.sol";

/**
 * @title Wethio NFTs implemented using the ERC-721 standard.
 * @dev This top level file holds no data directly to ease future upgrades.
 */

contract WethioNFT is
    WethioTreasuryNode,
    WethioAdminRole,
    WethioOperatorRole,
    ERC721Upgradeable,
    WethioMarketNode,
    NFT721Metadata,
    NFT721Mint,
    OwnableUpgradeable
{
    /**
     * @notice Called once to configure the contract after the initial deployment.
     * @dev This farms the initialize call out to inherited contracts as needed.
     */
    function initialize(
        address treasury,
        address market,
        string memory name,
        string memory symbol,
        string memory baseURI
    ) public initializer {
        WethioTreasuryNode._initializeWethioTreasuryNode(treasury);
        WethioMarketNode._initializeWethioMarketNode(market);
        ERC721Upgradeable.__ERC721_init(name, symbol);
        NFT721Mint._initializeNFT721Mint();
        _updateBaseURI(baseURI);
        __Ownable_init();
    }

    /**
     * @notice Allows a Wethio admin to update NFT config variables.
     * @dev This must be called right after the initial call to `initialize`.
     */
    function adminUpdateConfig(
        string memory _baseURI,
        address market,
        address treasury
    ) external onlyWethioAdmin {
        _updateBaseURI(_baseURI);
        _updateWethioMarket(market);
        _updateWethioTreasury(treasury);
    }

    /**
     * @dev This is a no-op, just an explicit override to address compile errors due to inheritance.
     */
    function _burn(uint256 tokenId)
        internal
        virtual
        override(ERC721Upgradeable, NFT721Metadata, NFT721Mint)
    {
        super._burn(tokenId);
    }
}
