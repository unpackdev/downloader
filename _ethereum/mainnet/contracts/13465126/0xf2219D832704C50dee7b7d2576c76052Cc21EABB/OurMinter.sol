// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.4;
pragma experimental ABIEncoderV2;

import "./OurManagement.sol";
import "./IZora.sol";
import "./IERC721.sol";

/**
 * @title OurMinter
 * @author Nick A.
 * https://github.com/ourz-network/our-contracts
 *
 * These contracts enable creators, builders, & collaborators of all kinds
 * to receive royalties for their collective work, forever.
 *
 * Thank you,
 * @author Mirror       @title Splits   https://github.com/mirror-xyz/splits
 * @author Gnosis       @title Safe     https://github.com/gnosis/safe-contracts
 * @author OpenZeppelin                 https://github.com/OpenZeppelin/openzeppelin-contracts
 * @author Zora                         https://github.com/ourzora
 *
 *
 *
 * @notice Some functions are marked as 'untrusted'Function. Use caution when interacting
 * with these, as any contracts you supply could be potentially unsafe.
 * 'Trusted' functions on the other hand -- implied by the absence of 'untrusted' --
 * are hardcoded to use the Zora Protocol addresses.
 * https://consensys.github.io/smart-contract-best-practices/recommendations/#mark-untrusted-contracts
 */

contract OurMinter is OurManagement {
    address public constant ZORA_MEDIA =
        0xabEFBc9fD2F806065b4f3C237d4b59D9A97Bcac7;
    address public constant ZORA_MARKET =
        0xE5BFAB544ecA83849c53464F85B7164375Bdaac1;
    address public constant ZORA_AH =
        0xE468cE99444174Bd3bBBEd09209577d25D1ad673;
    address public constant ZORA_EDITIONS =
        0x91A8713155758d410DFAc33a63E193AE3E89F909;

    //======== Subgraph =========
    event ZNFTMinted(uint256 tokenId);
    event EditionCreated(
        address editionAddress,
        string name,
        string symbol,
        string description,
        string animationUrl,
        string imageUrl,
        uint256 editionSize,
        uint256 royaltyBPS
    );

    /**======== IZora =========
     * @notice Various functions allowing a Split to interact with Zora Protocol
     * @dev see IZora.sol
     * Media -> Market -> AH -> Editions -> QoL Functions
     */

    /** Media
     * @notice Mint new Zora NFT for Split Contract.
     */
    function mintZNFT(
        IZora.MediaData calldata mediaData,
        IZora.BidShares calldata bidShares
    ) external onlyOwners {
        IZora(ZORA_MEDIA).mint(mediaData, bidShares);
        emit ZNFTMinted(_getID());
    }

    /** Media
     * @notice Update the token URIs for a Zora NFT owned by Split Contract
     */
    function updateZNFTURIs(
        uint256 tokenId,
        string calldata tokenURI,
        string calldata metadataURI
    ) external onlyOwners {
        IZora(ZORA_MEDIA).updateTokenURI(tokenId, tokenURI);
        IZora(ZORA_MEDIA).updateTokenMetadataURI(tokenId, metadataURI);
    }

    /** Media
     * @notice Update the token URI
     */
    function updateZNFTTokenURI(uint256 tokenId, string calldata tokenURI)
        external
        onlyOwners
    {
        IZora(ZORA_MEDIA).updateTokenURI(tokenId, tokenURI);
    }

    /** Media
     * @notice Update the token metadata uri
     */
    function updateZNFTMetadataURI(uint256 tokenId, string calldata metadataURI)
        external
    {
        IZora(ZORA_MEDIA).updateTokenMetadataURI(tokenId, metadataURI);
    }

    /** Market
     * @notice Update zora/core/market bidShares (NOT zora/auctionHouse)
     */
    function setZMarketBidShares(
        uint256 tokenId,
        IZora.BidShares calldata bidShares
    ) external {
        IZora(ZORA_MARKET).setBidShares(tokenId, bidShares);
    }

    /** Market
     * @notice Update zora/core/market ask
     */
    function setZMarketAsk(uint256 tokenId, IZora.Ask calldata ask)
        external
        onlyOwners
    {
        IZora(ZORA_MARKET).setAsk(tokenId, ask);
    }

    /** Market
     * @notice Remove zora/core/market ask
     */
    function removeZMarketAsk(uint256 tokenId) external onlyOwners {
        IZora(ZORA_MARKET).removeAsk(tokenId);
    }

    /** Market
     * @notice Accept zora/core/market bid
     */
    function acceptZMarketBid(uint256 tokenId, IZora.Bid calldata expectedBid)
        external
        onlyOwners
    {
        IZora(ZORA_MARKET).acceptBid(tokenId, expectedBid);
    }

    /** AuctionHouse
     * @notice Create auction on Zora's AuctionHouse for an owned/approved NFT
     * @dev reccomended auctionCurrency: ETH or WETH
     *      ERC20s may not be split perfectly. If the amount is indivisible
     *      among ALL recipients, the remainder will be sent to a single recipient.
     */
    function createZoraAuction(
        uint256 tokenId,
        address tokenContract,
        uint256 duration,
        uint256 reservePrice,
        address payable curator,
        uint8 curatorFeePercentage,
        address auctionCurrency
    ) external onlyOwners {
        IZora(ZORA_AH).createAuction(
            tokenId,
            tokenContract,
            duration,
            reservePrice,
            curator,
            curatorFeePercentage,
            auctionCurrency
        );
    }

    /** AuctionHouse
     * @notice Approves an Auction proposal that requested the Split be the curator
     */
    function setZAuctionApproval(uint256 auctionId, bool approved)
        external
        onlyOwners
    {
        IZora(ZORA_AH).setAuctionApproval(auctionId, approved);
    }

    /** AuctionHouse
     * @notice Set an Auction's reserve price
     */
    function setZAuctionReservePrice(uint256 auctionId, uint256 reservePrice)
        external
        onlyOwners
    {
        IZora(ZORA_AH).setAuctionReservePrice(auctionId, reservePrice);
    }

    /** AuctionHouse
     * @notice Cancel an Auction before any bids have been placed
     */
    function cancelZAuction(uint256 auctionId) external onlyOwners {
        IZora(ZORA_AH).cancelAuction(auctionId);
    }

    /** NFT-Editions
     * @notice Creates a new edition contract as a factory with a deterministic address
     * @dev if publicMint is true & salePrice is more than 0:
     *      anyone will be able to mint immediately after the edition is deployed
     *      Set salePrice to 0 if you wish to enable purchasing at a later time
     */
    function createZoraEdition(
        string memory name,
        string memory symbol,
        string memory description,
        string memory animationUrl,
        bytes32 animationHash,
        string memory imageUrl,
        bytes32 imageHash,
        uint256 editionSize,
        uint256 royaltyBPS,
        uint256 salePrice,
        bool publicMint
    ) external onlyOwners {
        uint256 editionId = IZora(ZORA_EDITIONS).createEdition(
            name,
            symbol,
            description,
            animationUrl,
            animationHash,
            imageUrl,
            imageHash,
            editionSize,
            royaltyBPS
        );

        address editionAddress = IZora(ZORA_EDITIONS).getEditionAtId(editionId);

        if (salePrice > 0) {
            IZora(editionAddress).setSalePrice(salePrice);
        }

        if (publicMint) {
            IZora(editionAddress).setApprovedMinter(address(0x0), true);
        }

        emit EditionCreated(
            editionAddress,
            name,
            symbol,
            description,
            animationUrl,
            imageUrl,
            editionSize,
            royaltyBPS
        );
    }

    /** NFT-Editions
     * @param salePrice if sale price is 0 sale is stopped, otherwise that amount
     *                  of ETH is needed to start the sale.
     * @dev This sets a simple ETH sales price
     *      Setting a sales price allows users to mint the edition until it sells out.
     *      For more granular sales, use an external sales contract.
     */
    function setEditionPrice(address editionAddress, uint256 salePrice)
        external
        onlyOwners
    {
        IZora(editionAddress).setSalePrice(salePrice);
    }

    /** NFT-Editions
     * @param editionAddress the address of the Edition Contract to call
     * @param minter address to set approved minting status for
     * @param allowed boolean if that address is allowed to mint
     * @dev Sets the approved minting status of the given address.
     *      This requires that msg.sender is the owner of the given edition id.
     *      If the ZeroAddress (address(0x0)) is set as a minter,
     *      anyone will be allowed to mint.
     *      This setup is similar to setApprovalForAll in the ERC721 spec.
     */
    function setEditionMinter(
        address editionAddress,
        address minter,
        bool allowed
    ) external onlyOwners {
        IZora(editionAddress).setApprovedMinter(minter, allowed);
    }

    /** NFT-Editions
     * @param editionAddress the address of the Edition Contract to call
     * @param recipients list of addresses to send the newly minted editions to
     * @dev This mints multiple editions to the given list of addresses.
     */
    function mintEditionsTo(
        address editionAddress,
        address[] calldata recipients
    ) external onlyOwners {
        IZora(editionAddress).mintEditions(recipients);
    }

    /** NFT-Editions
     * @param editionAddress the address of the Edition Contract to call
     * @dev Withdraws all funds from Edition to split
     * @notice callable by anyone, as funds are sent to the Split
     */
    function withdrawEditionFunds(address editionAddress) external {
        IZora(editionAddress).withdraw();
    }

    /** NFT-Editions
     * @param editionAddress the address of the Edition Contract to call
     * @dev Allows for updates of edition urls by the owner of the edition.
     *      Only URLs can be updated (data-uris are supported), hashes cannot be updated.
     */
    function updateEditionURLs(
        address editionAddress,
        string memory imageUrl,
        string memory animationUrl
    ) external onlyOwners {
        IZora(editionAddress).updateEditionURLs(imageUrl, animationUrl);
    }

    /** QoL
     * @notice Approve the Zora Auction House to manage Split's ERC-721s
     * @dev Called internally in Proxy's Constructo
     */
    /* solhint-disable ordering */
    function _setApprovalForAH() internal {
        IERC721(ZORA_MEDIA).setApprovalForAll(ZORA_AH, true);
    }

    /** QoL
     * @notice Mints a Zora NFT with this Split as the Creator,
     * and then list it on AuctionHouse for ETH
     */
    function mintToAuctionForETH(
        IZora.MediaData calldata mediaData,
        IZora.BidShares calldata bidShares,
        uint256 duration,
        uint256 reservePrice
    ) external onlyOwners {
        IZora(ZORA_MEDIA).mint(mediaData, bidShares);

        uint256 tokenId_ = _getID();
        emit ZNFTMinted(tokenId_);

        IZora(ZORA_AH).createAuction(
            tokenId_,
            ZORA_MEDIA,
            duration,
            reservePrice,
            payable(address(this)),
            0,
            address(0)
        );
    }

    /* solhint-enable ordering */

    /**======== IERC721 =========
     * NOTE: Althought OurMinter.sol is generally implemented to work with Zora,
     *       the functions below allow a Split to work with any ERC-721 spec'd platform;
     *       (except for minting, @dev 's see untrustedExecuteTransaction() below)
     * @dev see IERC721.sol
     */

    /**
     * NOTE: Marked as >> untrusted << Use caution when supplying tokenContract_
     * @dev In case non-Zora ERC721 gets stuck in Account.
     * @notice safeTransferFrom(address from, address to, uint256 tokenId)
     */
    function untrustedSafeTransferERC721(
        address tokenContract_,
        address newOwner_,
        uint256 tokenId_
    ) external onlyOwners {
        IERC721(tokenContract_).safeTransferFrom(
            address(this),
            newOwner_,
            tokenId_
        );
    }

    /**
     * NOTE: Marked as >> untrusted << Use caution when supplying tokenContract_
     * @dev sets approvals for non-Zora ERC721 contract
     * @notice setApprovalForAll(address operator, bool approved)
     */
    function untrustedSetApprovalERC721(
        address tokenContract_,
        address operator_,
        bool approved_
    ) external onlyOwners {
        IERC721(tokenContract_).setApprovalForAll(operator_, approved_);
    }

    /**
     * NOTE: Marked as >> untrusted << Use caution when supplying tokenContract_
     * @dev burns non-Zora ERC721 that Split contract owns/isApproved
     * @notice setApprovalForAll(address operator, bool approved)
     */
    function untrustedBurnERC721(address tokenContract_, uint256 tokenId_)
        external
        onlyOwners
    {
        IERC721(tokenContract_).burn(tokenId_);
    }

    /** ======== CAUTION =========
     * NOTE: As always, avoid interacting with contracts you do not trust entirely.
     * @dev allows a Split Contract to call (non-payable) functions of any other contract
     * @notice This function is added for 'future-proofing' capabilities, & to support the use of 
               custom ERC721 creator contracts.
     * @notice In the interest of securing the Split's funds for Recipients from a rogue owner,
     *         the msg.value is hardcoded to zero.
     */
    function executeTransaction(address to, bytes memory data)
        external
        onlyOwners
        returns (bool success)
    {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            success := call(gas(), to, 0, add(data, 0x20), mload(data), 0, 0)
        }
    }

    /// @dev calculates tokenID of newly minted ZNFT
    function _getID() private returns (uint256 id) {
        id = IZora(ZORA_MEDIA).tokenByIndex(
            IZora(ZORA_MEDIA).totalSupply() - 1
        );
    }
}
