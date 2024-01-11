// SPDX-License-Identifier: MIT
//
// Marketplace from the Art101 team (https://art101.io/devs.html).
// Developed by @lza_menace
//
// This is our take on a decentralized NFT marketplace. Big thanks to those
// who came before us; CryptoPunks, CryptoPhunks, etc. Their marketplaces and
// tools were highly influential and provided the initial contract code and
// reference implementations.
//
// This implementation supports many collections/contracts to be added to it.
// The only requirements are that the contract implements `Ownable` and ERC-721
// or ERC-1155 token standards. Contract owners must submit their collection.
// This contract is free to use, but contract owners can enforce their own royalties.
//
// Teams may use this contract with an integrated frontend of their choice or
// fork this code and launch one of their own. We hope it becomes useful to the
// NFT and web3 scene and furthers the push for decentralization. Much of the
// infrastructure has been consolidated to the largest players/organizations
// which have normalized censorship, favoritism, wash trading, skimming/capital
// extraction, and supporting and enabling scams and predatory behavior. We
// believe in the need for NFT projects and teams to leverage their own
// (or community) smart contract based exchange methods and open source trading
// contracts.
//
// A frontend implementation can be found at https://gallery.art101.io. We
// intend to release a more general purpose template which teams can fork for
// their own projects.
//
// If anyone is so inclined and interested, please join us:
// @art101nft - @j_winter_m - @cartyisme - @lza_menace

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC1155.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./SafeMath.sol";


contract Marketplace is ReentrancyGuard, Ownable {
    using SafeMath for uint256;

    // Define offers, bids, and collection details
    struct Offer {
        bool isForSale;
        uint256 tokenIndex;
        address seller;
        uint256 minValue;
        address onlySellTo;
    }

    struct Bid {
        bool hasBid;
        uint256 tokenIndex;
        address bidder;
        uint256 value;
    }

    struct Collection {
        bool status;
        bool erc1155;
        uint256 royaltyPercent;
        string metadataURL;
    }

    // Nested mappings for each collection's offers and bids
    mapping (address => mapping(uint256 => Offer)) public tokenOffers;
    mapping (address => mapping(uint256 => Bid)) public tokenBids;

    // Mapping of collection status and details
    mapping (address => Collection) public collectionState;

    // Mapping of each wallet's pending balances
    mapping (address => uint256) public pendingBalance;

    // Log events
    event TokenTransfer(address indexed collectionAddress, address indexed from, address indexed to, uint256 tokenIndex);
    event TokenOffered(address indexed collectionAddress, uint256 indexed tokenIndex, uint256 minValue, address indexed toAddress);
    event TokenBidEntered(address indexed collectionAddress, uint256 indexed tokenIndex, uint256 value, address indexed fromAddress);
    event TokenBidWithdrawn(address indexed collectionAddress, uint256 indexed tokenIndex, uint256 value, address indexed fromAddress);
    event TokenBought(address indexed collectionAddress, uint256 indexed tokenIndex, uint256 value, address fromAddress, address toAddress);
    event TokenNoLongerForSale(address indexed collectionAddress, uint256 indexed tokenIndex);
    event CollectionUpdated(address indexed collectionAddress);
    event CollectionDisabled(address indexed collectionAddress);

    constructor() {
        // do stuff...
    }

    /*************************
    Modifiers
    **************************/

    modifier onlyIfTokenOwner(
        address contractAddress,
        uint256 tokenIndex
    ) {
        if (collectionState[contractAddress].erc1155) {
            require(IERC1155(contractAddress).balanceOf(msg.sender, tokenIndex) > 0, "You must own the token.");
        } else {
            require(msg.sender == IERC721(contractAddress).ownerOf(tokenIndex), "You must own the token.");
        }
        _;
    }

    modifier notIfTokenOwner(
        address contractAddress,
        uint256 tokenIndex
    ) {
        if (collectionState[contractAddress].erc1155) {
            require(IERC1155(contractAddress).balanceOf(msg.sender, tokenIndex) == 0, "Token owner cannot enter bid to self.");
        } else {
            require(msg.sender != IERC721(contractAddress).ownerOf(tokenIndex), "Token owner cannot enter bid to self.");
        }
        _;
    }

    modifier onlyIfContractOwner(
        address contractAddress
    ) {
        require(msg.sender == Ownable(contractAddress).owner(), "You must own the contract.");
        _;
    }

    modifier collectionMustBeEnabled(
        address contractAddress
    ) {
        require(true == collectionState[contractAddress].status, "Collection must be enabled on this contract by project owner.");
        _;
    }

    /*************************
    Administration
    **************************/

    // Allow owners of contracts to update their collection details
    function updateCollection(
        address contractAddress,
        bool erc1155,
        uint256 royaltyPercent,
        string memory metadataURL
    ) external onlyIfContractOwner(contractAddress) {
        require(royaltyPercent >= 0, "Must be greater than or equal to 0.");
        require(royaltyPercent <= 100, "Cannot exceed 100%");
        collectionState[contractAddress] = Collection(true, erc1155, royaltyPercent, metadataURL);
        emit CollectionUpdated(contractAddress);
    }

    // Allow owners of contracts to remove their collections
    function disableCollection(
        address contractAddress
    ) external collectionMustBeEnabled(contractAddress) onlyIfContractOwner(contractAddress) {
        collectionState[contractAddress] = Collection(false, false, 0, "");
        emit CollectionDisabled(contractAddress);
    }

    /*************************
    Offering
    **************************/

    // List (offer) token
    function offerTokenForSale(
        address contractAddress,
        uint256 tokenIndex,
        uint256 minSalePriceInWei
    ) external collectionMustBeEnabled(contractAddress) onlyIfTokenOwner(contractAddress, tokenIndex) nonReentrant() {
        if (collectionState[contractAddress].erc1155) {
            require(IERC1155(contractAddress).isApprovedForAll(msg.sender, address(this)), "Marketplace not approved to spend token on seller behalf.");
        } else {
            require(IERC721(contractAddress).getApproved(tokenIndex) == address(this), "Marketplace not approved to spend token on seller behalf.");
        }
        tokenOffers[contractAddress][tokenIndex] = Offer(true, tokenIndex, msg.sender, minSalePriceInWei, address(0x0));
        emit TokenOffered(contractAddress, tokenIndex, minSalePriceInWei, address(0x0));
    }

    // List (offer) token for specific address
    function offerTokenForSaleToAddress(
        address contractAddress,
        uint256 tokenIndex,
        uint256 minSalePriceInWei,
        address toAddress
    ) external collectionMustBeEnabled(contractAddress) onlyIfTokenOwner(contractAddress, tokenIndex) nonReentrant() {
        if (collectionState[contractAddress].erc1155) {
            require(IERC1155(contractAddress).isApprovedForAll(msg.sender, address(this)), "Marketplace not approved to spend token on seller behalf.");
        } else {
            require(IERC721(contractAddress).getApproved(tokenIndex) == address(this), "Marketplace not approved to spend token on seller behalf.");
        }
        tokenOffers[contractAddress][tokenIndex] = Offer(true, tokenIndex, msg.sender, minSalePriceInWei, toAddress);
        emit TokenOffered(contractAddress, tokenIndex, minSalePriceInWei, toAddress);
    }

    // Remove token listing (offer)
    function tokenNoLongerForSale(
        address contractAddress,
        uint256 tokenIndex
    ) public collectionMustBeEnabled(contractAddress) onlyIfTokenOwner(contractAddress, tokenIndex) nonReentrant() {
        tokenOffers[contractAddress][tokenIndex] = Offer(false, tokenIndex, msg.sender, 0, address(0x0));
        emit TokenNoLongerForSale(contractAddress, tokenIndex);
    }

    /*************************
    Bidding
    **************************/

    // Open bid on a token
    function enterBidForToken(
        address contractAddress,
        uint256 tokenIndex
    ) external payable collectionMustBeEnabled(contractAddress) notIfTokenOwner(contractAddress, tokenIndex) nonReentrant() {
        require(msg.value > 0, "Must bid some amount of Ether.");
        Bid memory existing = tokenBids[contractAddress][tokenIndex];
        require(msg.value > existing.value, "Must bid higher than current bid.");
        // Refund the failing bid
        pendingBalance[existing.bidder] = pendingBalance[existing.bidder].add(existing.value);
        tokenBids[contractAddress][tokenIndex] = Bid(true, tokenIndex, msg.sender, msg.value);
        emit TokenBidEntered(contractAddress, tokenIndex, msg.value, msg.sender);
    }

    // Remove an open bid on a token
    function withdrawBidForToken(
        address contractAddress,
        uint256 tokenIndex
    ) external payable collectionMustBeEnabled(contractAddress) notIfTokenOwner(contractAddress, tokenIndex) nonReentrant() {
        Bid memory bid = tokenBids[contractAddress][tokenIndex];
        require(msg.sender == bid.bidder, "Only original bidder can withdraw this bid.");
        emit TokenBidWithdrawn(contractAddress, tokenIndex, bid.value, msg.sender);
        uint256 amount = bid.value;
        tokenBids[contractAddress][tokenIndex] = Bid(false, tokenIndex, address(0x0), 0);
        // Refund the bid money
        payable(msg.sender).transfer(amount);
    }

    /*************************
    Sales
    **************************/

    // Buyer accepts an offer to buy the token
    function acceptOfferForToken(
        address contractAddress,
        uint256 tokenIndex
    ) external payable collectionMustBeEnabled(contractAddress) notIfTokenOwner(contractAddress, tokenIndex) nonReentrant() {
        Offer memory offer = tokenOffers[contractAddress][tokenIndex];
        address seller = offer.seller;
        address buyer = msg.sender;
        uint256 amount = msg.value;

        // Checks
        require(amount >= offer.minValue, "Not enough Ether sent.");
        require(offer.isForSale, "Token must be for sale by owner.");
        if (offer.onlySellTo != address(0x0)) {
            require(buyer == offer.onlySellTo, "Offer applies to other address.");
        }

        // Confirm ownership then transfer the token from seller to buyer
        if (collectionState[contractAddress].erc1155) {
            require(IERC1155(contractAddress).balanceOf(seller, tokenIndex) > 0, "Seller is no longer the owner, cannot accept offer.");
            require(IERC1155(contractAddress).isApprovedForAll(seller, address(this)), "Marketplace not approved to spend token on seller behalf.");
            IERC1155(contractAddress).safeTransferFrom(seller, buyer, tokenIndex, 1, bytes(""));
        } else {
            require(seller == IERC721(contractAddress).ownerOf(tokenIndex), "Seller is no longer the owner, cannot accept offer.");
            require(IERC721(contractAddress).getApproved(tokenIndex) == address(this), "Marketplace not approved to spend token on seller behalf.");
            IERC721(contractAddress).safeTransferFrom(seller, buyer, tokenIndex);
        }

        // Remove token offers
        tokenOffers[contractAddress][tokenIndex] = Offer(false, tokenIndex, buyer, 0, address(0x0));

        // Take cut for the project if royalties
        collectRoyalties(contractAddress, seller, amount);

        // Check for the case where there is a bid from the new owner and refund it.
        // Any other bid can stay in place.
        Bid memory bid = tokenBids[contractAddress][tokenIndex];
        if (bid.bidder == buyer) {
            // Kill bid and refund value
            pendingBalance[buyer] = pendingBalance[buyer].add(bid.value);
            tokenBids[contractAddress][tokenIndex] = Bid(false, tokenIndex, address(0x0), 0);
        }

        // Emit token events
        emit TokenTransfer(contractAddress, seller, buyer, tokenIndex);
        emit TokenNoLongerForSale(contractAddress, tokenIndex);
        emit TokenBought(contractAddress, tokenIndex, amount, seller, buyer);
    }

    // Seller accepts a bid to sell the token
    function acceptBidForToken(
        address contractAddress,
        uint256 tokenIndex,
        uint256 minPrice
    ) external payable collectionMustBeEnabled(contractAddress) onlyIfTokenOwner(contractAddress, tokenIndex) nonReentrant() {
        Bid memory bid = tokenBids[contractAddress][tokenIndex];
        address seller = msg.sender;
        address buyer = bid.bidder;
        uint256 amount = bid.value;

        // Checks
        require(bid.hasBid == true, "Bid must be active.");
        require(amount > 0, "Bid must be greater than 0.");
        require(amount >= minPrice, "Bid must be greater than minimum price.");

        // Confirm ownership then transfer the token from seller to buyer
        if (collectionState[contractAddress].erc1155) {
            require(IERC1155(contractAddress).balanceOf(seller, tokenIndex) > 0, "Seller is no longer the owner, cannot accept offer.");
            require(IERC1155(contractAddress).isApprovedForAll(seller, address(this)), "Marketplace not approved to spend token on seller behalf.");
            IERC1155(contractAddress).safeTransferFrom(seller, buyer, tokenIndex, 1, bytes(""));
        } else {
            require(seller == IERC721(contractAddress).ownerOf(tokenIndex), "Seller is no longer the owner, cannot accept offer.");
            require(IERC721(contractAddress).getApproved(tokenIndex) == address(this), "Marketplace not approved to spend token on seller behalf.");
            IERC721(contractAddress).safeTransferFrom(seller, buyer, tokenIndex);
        }

        // Remove token offers
        tokenOffers[contractAddress][tokenIndex] = Offer(false, tokenIndex, buyer, 0, address(0x0));

        // Take cut for the project if royalties
        collectRoyalties(contractAddress, seller, amount);

        // Clear bid
        tokenBids[contractAddress][tokenIndex] = Bid(false, tokenIndex, address(0x0), 0);

        // Emit token events
        emit TokenTransfer(contractAddress, seller, buyer, tokenIndex);
        emit TokenNoLongerForSale(contractAddress, tokenIndex);
        emit TokenBought(contractAddress, tokenIndex, amount, seller, buyer);
    }

    /*************************
    Fund management
    **************************/

    function withdraw() external nonReentrant() {
        uint256 amount = pendingBalance[msg.sender];
        // Zero the pending refund before
        // sending to prevent re-entrancy attacks
        pendingBalance[msg.sender] = 0;
        payable(msg.sender).transfer(amount);
    }

    /*************************
    Internal
    **************************/

    // Take cut for the project if royalties
    function collectRoyalties(address contractAddress, address seller, uint256 amount) private {
        // ownerRoyalty = amount / (100 / royalty)
        // sellerReceives = amount - ownerRoyalty
        // amount = ownerRoyalty + sellerReceives
        if (collectionState[contractAddress].royaltyPercent > 0) {
            uint256 hundo = 100;
            address owner = Ownable(contractAddress).owner();
            uint256 collectionRoyalty = amount.div(hundo.div(collectionState[contractAddress].royaltyPercent));
            uint256 sellerAmount = amount.sub(collectionRoyalty);
            pendingBalance[seller] = pendingBalance[seller].add(sellerAmount);
            pendingBalance[owner] = pendingBalance[owner].add(collectionRoyalty);
        }
    }

}
