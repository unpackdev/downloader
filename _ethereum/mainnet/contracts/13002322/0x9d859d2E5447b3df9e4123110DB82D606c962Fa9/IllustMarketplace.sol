// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.4;
pragma abicoder v2;

import "./AccessControlEnumerable.sol";
import "./Context.sol";
import "./Pausable.sol";

import "./Ainsoph.sol";

/**
 * @title Illust Marketplace v3
 * @author Illust Space
 * An NFT marketplace contract that handles primary sale royalties and
 * secondary market transfers.
 */
contract IllustMarketplace3 is Context, AccessControlEnumerable, Pausable {
    /** May mint assets. */
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    /** May set primary sales. */
    bytes32 public constant PRIMARY_SALE_ROLE = keccak256("PRIMARY_SALE_ROLE");

    /** Winning bid ticket structure */
    struct WinningBid {
        bool enabled;
        address payable winner;
        uint256 price;
        bool complete;
    }

    /** Stores data about a token's primary sale royalties. */
    struct PrimarySaleRoyalties {
        bool firstSale;
        uint8 marketplaceFee;
        RoyaltySplit[] royaltySplits;
    }

    struct OpenEdition {
        /** If there was an open edition for the piece */
        bool wasOpen;
        /** If there is currently an open edition for the piece */
        bool isOpen;
        address artist;
        uint256 index;
        uint256 price;
        uint256 max;
        RoyaltySplit[] primaryRoyaltySplits;
        RoyaltySplit[] secondaryRoyaltySplits;
    }

    // address of ERC721 Token Smart contract
    address public tokenContract;

    /** Address to send marketplace fees. */
    address payable public marketplaceFeeAddress;

    // mapping of asset distributions
    mapping(uint256 => PrimarySaleRoyalties) public primarySaleRoyaltyList;
    // mapping of winning bid tickets
    mapping(uint256 => WinningBid) public winningBids;

    /** Store open edition data */
    mapping(uint256 => OpenEdition) public openEditions;

    constructor(
        address initialTokenContract,
        address payable initialMarketplaceFeeAddress
    ) {
        tokenContract = initialTokenContract;

        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(MINTER_ROLE, _msgSender());
        _setupRole(PRIMARY_SALE_ROLE, _msgSender());

        marketplaceFeeAddress = initialMarketplaceFeeAddress;
    }

    /** Set up an open edition for minting. */
    function createOpenEdition(
        uint256 tokenId,
        address artist,
        uint256 price,
        uint256 max,
        RoyaltySplit[] calldata primaryRoyaltySplits,
        RoyaltySplit[] calldata secondaryRoyaltySplits
    ) public whenNotPaused {
        require(hasRole(MINTER_ROLE, _msgSender()), "must have minter role");

        OpenEdition storage openEdition = openEditions[tokenId];

        openEdition.wasOpen = true;
        openEdition.isOpen = true;
        openEdition.artist = artist;
        openEdition.price = price;
        openEdition.max = max;

        delete openEdition.primaryRoyaltySplits;
        delete openEdition.secondaryRoyaltySplits;

        // Copy the royalty splits into from memory into storage.
        for (uint256 i = 0; i < primaryRoyaltySplits.length; i++) {
            openEdition.primaryRoyaltySplits.push(primaryRoyaltySplits[i]);
        }

        // Copy the royalty splits into from memory into storage.
        for (uint256 i = 0; i < secondaryRoyaltySplits.length; i++) {
            openEdition.secondaryRoyaltySplits.push(secondaryRoyaltySplits[i]);
        }
    }

    /** Close an open edition for minting. */
    function closeOpenEdition(uint256 tokenId) public whenNotPaused {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            "must have admin role"
        );

        openEditions[tokenId].isOpen = false;
    }

    /** Any user may mint a version of an open edition. */
    function mintOpenEdition(uint256 tokenId) public payable whenNotPaused {
        OpenEdition storage openEdition = openEditions[tokenId];

        // create Ainsoph ref
        Ainsoph3 AinsophContract = Ainsoph3(tokenContract);

        require(openEdition.isOpen == true, "minting is closed");

        require(
            AinsophContract.isApprovedForAll(openEdition.artist, address(this)),
            "Artist must approve transfers"
        );

        require(msg.value == openEdition.price, "Please send more eth");

        require(
            openEdition.index < openEdition.max || openEdition.max == 0,
            "no more pieces available"
        );

        // Increment the index for the next minting.
        openEdition.index += 1;

        uint256 openTokenId = tokenId + openEdition.index;

        // Mint into the artist's wallet.
        AinsophContract.mintAsset(
            openTokenId,
            openEdition.artist,
            marketplaceFeeAddress,
            openEdition.secondaryRoyaltySplits
        );

        // Move to the minter's wallet.
        AinsophContract.transferFrom(
            openEdition.artist,
            _msgSender(),
            openTokenId
        );

        uint256 royaltyPayment;
        uint256 marketplaceFee = msg.value;
        for (uint8 i = 0; i < openEdition.primaryRoyaltySplits.length; i++) {
            // Calculate the royalty payment value for the receiver.
            royaltyPayment =
                (msg.value *
                    openEdition.primaryRoyaltySplits[i].royaltyPercentage) /
                100;

            marketplaceFee -= royaltyPayment;

            openEdition.primaryRoyaltySplits[i].royaltyReceiver.transfer(
                royaltyPayment
            );
        }

        marketplaceFeeAddress.transfer(marketplaceFee);
    }

    /** Accept a buyer and price for transfer. */
    function acceptBid(
        uint256 asset,
        uint256 price,
        address payable winner
    ) public whenNotPaused {
        // create Ainsoph ref
        Ainsoph3 AinsophContract = Ainsoph3(tokenContract);

        // verify lister is the owner of the asset
        require(
            _msgSender() == AinsophContract.ownerOf(asset),
            "Sender must own asset"
        );
        // require seller has approved transfer
        require(
            AinsophContract.isApprovedForAll(_msgSender(), address(this)),
            "Seller must approve transfers"
        );

        // Create or replace the winning auction ticket.
        winningBids[asset] = WinningBid(true, winner, price, false);
    }

    /** Once a bid is accepted, the buyer may pay to transfer the asset. */
    function pay(uint256 tokenId) public payable whenNotPaused {
        WinningBid storage winningBid = winningBids[tokenId];

        // req asset finalized
        require(winningBid.enabled == true, "Seller has not accepted a bid.");
        // req payment incomplete
        require(winningBid.complete == false, "This auction has ended");
        // req msg sender is the winner
        require(
            winningBid.winner == _msgSender(),
            "This is not the winning address"
        );
        // req user sends enough funds
        require(msg.value == winningBid.price, "Please send more eth");
        // create Ainsoph ref
        Ainsoph3 AinsophContract = Ainsoph3(tokenContract);

        address owner = AinsophContract.ownerOf(tokenId);

        // req owner is not winner
        require(owner != winningBid.winner, "Owner can not be winner");

        // Look up the asset data.
        PrimarySaleRoyalties storage asset = primarySaleRoyaltyList[tokenId];

        /** Payment to the seller after royalties. */
        uint256 sellerPayment = msg.value;
        uint256 royaltyAmount;

        /** Number of primary royalty receivers (only used in primary sale). */
        uint256 royaltyLength = asset.royaltySplits.length;

        /**
         * Payments to the royalty receivers, in the same order as royaltySplits.
         * (only used in primary sale)
         */
        uint256[] memory royaltyPayments;

        uint256 marketplaceFee;

        // Calculate seller payment - royalties (payment will be sent at the end).
        // Do this first to prevent reentrancy attacks.
        if (asset.firstSale) {
            // First sale uses marketplace royalties instead of secondary market.

            royaltyLength = asset.royaltySplits.length;
            // Initialize for the length of the total royalty receivers.
            royaltyPayments = new uint256[](royaltyLength);

            uint256 royaltyPayment;

            // Calculate and subtract marketplace fee.
            marketplaceFee = (msg.value * asset.marketplaceFee) / 100;
            sellerPayment -= marketplaceFee;

            // For each royalty receiver:
            for (uint8 i = 0; i < royaltyLength; i++) {
                // Calculate the royalty payment value for the receiver.
                royaltyPayment =
                    (msg.value * asset.royaltySplits[i].royaltyPercentage) /
                    100;

                // Subtract it from the seller's cut.
                sellerPayment -= royaltyPayment;

                // Store it to send the payment.
                royaltyPayments[i] = royaltyPayment;
            }
        } else {
            (, royaltyAmount) = AinsophContract.royaltyInfo(tokenId, msg.value);

            sellerPayment -= royaltyAmount;
        }

        // Transfer the token.
        AinsophContract.safeTransferFrom(
            AinsophContract.ownerOf(tokenId),
            _msgSender(),
            tokenId
        );

        // Mark the winning bid as complete.
        winningBid.complete = true;

        // Distribute royalties
        if (asset.firstSale) {
            // Turn off the first sale for the next sale.
            asset.firstSale = false;

            // Pay marketplace fees
            marketplaceFeeAddress.transfer(marketplaceFee);

            // Pay the royalty receivers.
            for (uint8 i = 0; i < royaltyLength; i++) {
                asset.royaltySplits[i].royaltyReceiver.transfer(
                    royaltyPayments[i]
                );
            }
        } else {
            // Distribute secondary market royalties through NFT contract.
            AinsophContract.distributeRoyalties{value: royaltyAmount}(tokenId);
        }

        // Pay the seller the remainder.
        payable(owner).transfer(sellerPayment);
    }

    /** Set primary market royalties for the next sale. */
    function setRoyalties(
        uint256 tokenId,
        uint8 marketplaceFeePercentage,
        RoyaltySplit[] calldata primaryRoyaltySplits
    ) public payable {
        require(
            hasRole(PRIMARY_SALE_ROLE, _msgSender()),
            "must have primary sale role"
        );

        // Verify the splits meet or exceed the secondary market splits.
        Ainsoph3 AinsophContract = Ainsoph3(tokenContract);
        AinsophContract.verifyRoyalties(
            tokenId,
            marketplaceFeePercentage,
            primaryRoyaltySplits
        );

        PrimarySaleRoyalties storage primarySale = primarySaleRoyaltyList[
            tokenId
        ];

        // Reset state of primary royalty splits.
        primarySale.firstSale = true;
        primarySale.marketplaceFee = marketplaceFeePercentage;
        delete primarySale.royaltySplits;

        uint8 totalRoyaltyPercentage = 0;

        for (uint256 i = 0; i < primaryRoyaltySplits.length; i++) {
            // Update the total percentage.
            totalRoyaltyPercentage += primaryRoyaltySplits[i].royaltyPercentage;

            // Copy the royalty split into from memory into storage.
            primarySaleRoyaltyList[tokenId].royaltySplits.push(
                primaryRoyaltySplits[i]
            );
        }

        require(totalRoyaltyPercentage <= 100, "royalties cannot be > 100%");
    }

    function setAinsophContract(address payable newTokenContractAddress)
        public
    {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            "must have admin role"
        );

        // change smart contract
        tokenContract = newTokenContractAddress;
    }

    function changeMarketplaceFeeRecipient(
        address payable newMarketplaceFeeAddress
    ) public {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            "must have admin role"
        );

        marketplaceFeeAddress = newMarketplaceFeeAddress;
    }

    /**
     * @dev Pauses all token transfers.
     *
     * Requirements:
     *
     * - the caller must have the `DEFAULT_ADMIN_ROLE`.
     */
    function pause() public virtual {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            "must have admin role to pause"
        );
        _pause();
    }

    /**
     * @dev Unpauses all token transfers.
     *
     * Requirements:
     *
     * - the caller must have the `DEFAULT_ADMIN_ROLE`.
     */
    function unpause() public virtual {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            "must have admin role to unpause"
        );
        _unpause();
    }
}
