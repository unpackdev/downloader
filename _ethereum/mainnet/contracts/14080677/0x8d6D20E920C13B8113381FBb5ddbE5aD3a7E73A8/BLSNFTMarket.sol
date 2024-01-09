// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.0;

import "./BlocksportTreasuryNode.sol";
import "./BlocksportAdminRole.sol";
import "./NFTMarketCore.sol";
import "./SendValueWithFallbackWithdraw.sol";
import "./NFTMarketCreators.sol";
import "./NFTMarketFees.sol";
import "./NFTMarketAuction.sol";
import "./NFTMarketReserveAuction.sol";
import "./ReentrancyGuardUpgradeable.sol";

/**
 * @title A market for NFTs on Blocksport.
 * @dev This top level file holds no data directly to ease future upgrades.
 */
contract BLSNFTMarket is
    BlocksportTreasuryNode,
    BlocksportAdminRole,
    NFTMarketCore,
    ReentrancyGuardUpgradeable,
    NFTMarketCreators,
    SendValueWithFallbackWithdraw,
    NFTMarketFees,
    NFTMarketAuction,
    NFTMarketReserveAuction
{
    /**
     * @notice Called once to configure the contract after the initial deployment.
     * @dev This farms the initialize call out to inherited contracts as needed.
     */
    function initialize(address payable treasury) public initializer {
        BlocksportTreasuryNode._initializeBlocksportTreasuryNode(treasury);
        NFTMarketAuction._initializeNFTMarketAuction();
        NFTMarketReserveAuction._initializeNFTMarketReserveAuction();
    }

    /**
     * @notice Allows Blocksport to update the market configuration.
     */
    function adminUpdateConfig(
        uint256 minPercentIncrementInBasisPoints,
        uint256 duration,
        uint256 primaryblsFeeBasisPoints,
        uint256 secondaryblsFeeBasisPoints,
        uint256 secondaryCreatorFeeBasisPoints
    ) public onlyBlocksportAdmin {
        _updateReserveAuctionConfig(minPercentIncrementInBasisPoints, duration);
        _updateMarketFees(
            primaryblsFeeBasisPoints,
            secondaryblsFeeBasisPoints,
            secondaryCreatorFeeBasisPoints
        );
    }

    /**
     * @dev Checks who the seller for an NFT is, this will check escrow or return the current owner if not in escrow.
     * This is a no-op function required to avoid compile errors.
     */
    function _getSellerFor(address nftContract, uint256 tokenId)
        internal
        view
        virtual
        override(NFTMarketCore, NFTMarketReserveAuction)
        returns (address payable)
    {
        return super._getSellerFor(nftContract, tokenId);
    }
}
