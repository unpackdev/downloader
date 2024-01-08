// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity 0.8.4;

import "./ERC721Upgradeable.sol";
import "./MomentsAdminRole.sol";
import "./MarketNode.sol";
import "./NFT721Metadata.sol";
import "./NFT721Mint.sol";
import "./AccessControlUpgradeable.sol";
import "./ERC165StorageUpgradeable.sol";

/**
 * @title Moments NFTs implemented using the ERC-721 standard.
 * @dev This top level file holds no data directly to ease future upgrades.
 */

contract MOMENTSNFT is
    ERC165StorageUpgradeable,
    AccessControlUpgradeable,
    MomentsAdminRole,
    ERC721Upgradeable,
    NFT721Metadata,
    NFT721Mint
{
    /**
     * @notice Called once to configure the contract after the initial deployment.
     * @dev This farms the initialize call out to inherited contracts as needed.
     */
    function initialize(
        address market,
        address admin,
        string memory name,
        string memory symbol,
        string memory _baseURI
    ) public initializer {
        MarketNode._initializeMarketNode(market);
        MomentsAdminRole._initializeAdminRole(admin);
        ERC721Upgradeable.__ERC721_init(name, symbol);
        NFT721Mint._initializeNFT721Mint();
        _updateBaseURI(_baseURI);
    }

    /**
     * @notice Allows a Moments admin to update NFT config variables.
     * @dev This must be called right after the initial call to `initialize`.
     */
    function adminUpdateConfig(string memory _baseURI, address market)
        external
        onlyMomentsAdmin
    {
        _updateBaseURI(_baseURI);
        _updateMarket(market);
    }

    /**
     *  @notice Overrided before transfer to restrict multiple perk transfer  .
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721Upgradeable) {
        if (perkTransfer[tokenId] >= 1 && to != getMarket()) {
            perkTransfer[tokenId] = ++perkTransfer[tokenId];
        }
        require(
            perkTransfer[tokenId] <= 2 || to == address(0),
            "Perk transfer limit reached"
        );
        super._beforeTokenTransfer(from, to, tokenId);
    }

    /**
     * @notice Allows a Moments admin to update perk transfer count.
     */
    function perkTransferCount(uint256 tokenId) external onlyMomentsAdmin {
        require(perkTransfer[tokenId] > 1, "No change required");

        perkTransfer[tokenId] = 1;
    }

    /**
     * @dev Explicit override to address compile errors.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(
            ERC165StorageUpgradeable,
            AccessControlUpgradeable,
            NFT721Metadata,
            NFT721Mint
        )
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
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
