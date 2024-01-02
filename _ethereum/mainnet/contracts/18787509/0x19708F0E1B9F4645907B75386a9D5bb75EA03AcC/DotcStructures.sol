// solhint-disable
//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.19;

/**
 * @title Structures for DOTC management (as part of the "SwarmX.eth Protocol")
 * ////////////////DISCLAIMER////////////////DISCLAIMER////////////////DISCLAIMER////////////////
 * Please read the Disclaimer featured on the SwarmX.eth website ("Terms") carefully before accessing,
 * interacting with, or using the SwarmX.eth Protocol software, consisting of the SwarmX.eth Protocol
 * technology stack (in particular its smart contracts) as well as any other SwarmX.eth technology such
 * as e.g., the launch kit for frontend operators (together the "SwarmX.eth Protocol Software").
 * By using any part of the SwarmX.eth Protocol you agree (1) to the Terms and acknowledge that you are
 * aware of the existing risk and knowingly accept it, (2) that you have read, understood and accept the
 * legal information and terms of service and privacy note presented in the Terms, and (3) that you are
 * neither a US person nor a person subject to international sanctions (in particular as imposed by the
 * European Union, Switzerland, the United Nations, as well as the USA). If you do not meet these
 * requirements, please refrain from using the SwarmX.eth Protocol.
 * ////////////////DISCLAIMER////////////////DISCLAIMER////////////////DISCLAIMER////////////////
 */

/**
 * @title Asset Types Enum
 * @notice Defines the different types of assets that can be used in the system.
 * @dev Enum representing various asset types supported in DOTC trades.
 * @author Swarm
 * - NoType: Represents a state with no specific asset type.
 * - ERC20: Represents an ERC20 token asset.
 * - ERC721: Represents an ERC721 token (NFT) asset.
 * - ERC1155: Represents an ERC1155 token (multi-token standard) asset.
 */
enum AssetType {
    NoType,
    ERC20,
    ERC721,
    ERC1155
}

/**
 * @title Asset Structure
 * @notice Represents an asset in the DOTC trading system.
 * @dev Defines the structure for an asset including type, address, amount, and token ID for NFTs.
 * @param assetType The type of the asset (ERC20, ERC721, ERC1155).
 * @param assetAddress The contract address of the asset.
 * @param amount The amount of the asset (relevant for ERC20 and ERC1155).
 * @param tokenId The token ID (relevant for ERC721 and ERC1155).
 * @author Swarm
 */
struct Asset {
    AssetType assetType;
    address assetAddress;
    uint256 amount;
    uint256 tokenId;
}

/**
 * @title DOTC Offer Structure
 * @notice Represents an offer in the DOTC trading system.
 * @dev Structure containing details of an offer including maker, assets involved, and trading conditions.
 * @param maker The address of the offer creator.
 * @param isFullType Indicates whether the offer is for the full amount of the deposit asset.
 * @param isFullyTaken Indicates whether the offer has been completely taken.
 * @param depositAsset The asset being offered by the maker.
 * @param withdrawalAsset The asset requested by the maker in exchange.
 * @param availableAmount The amount of the deposit asset that is currently available for trading.
 * @param unitPrice The price per unit of the deposit asset in terms of the withdrawal asset.
 * @param specialAddress An optional address that can exclusively take the offer.
 * @param expiryTime The timestamp when the offer expires.
 * @param timelockPeriod The period for which the offer is locked before it can be taken.
 * @author Swarm
 */
struct DotcOffer {
    address maker;
    bool isFullType;
    bool isFullyTaken;
    Asset depositAsset; // assets in
    Asset withdrawalAsset; // assets out
    uint256 availableAmount; // available amount
    uint256 unitPrice;
    address specialAddress; // makes the offer avaiable for one account.
    uint256 expiryTime;
    uint256 timelockPeriod;
}
