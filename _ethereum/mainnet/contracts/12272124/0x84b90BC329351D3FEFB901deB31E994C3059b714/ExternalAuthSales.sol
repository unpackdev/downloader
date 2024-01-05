// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./EnumerableSet.sol";
import "./ECDSA.sol";

import "./Strings.sol";

import "./OwnableClone.sol";
import "./RevenueSplit.sol";
import "./SalesHistory.sol";
import "./ISaleable.sol";

contract ExternalAuthSales is OwnableClone, RevenueSplit, SalesHistory {
    using EnumerableSet for EnumerableSet.UintSet;

    struct Listing {
        address tokenAddress;
        uint256 offeringId;
        mapping (address => bool) authorizers;
        mapping(uint64 => bool) consumedNonces;
    }

    mapping(uint256 => Listing) public listingsById;
    uint256 internal nextListingId;
    EnumerableSet.UintSet currentListingIds;

    string public name;

    event ListingPurchased( address indexed authorizer, uint256 indexed listingId, address buyer, address recipient );
    event ListingAdded(uint256 indexed listingId, address tokenAddress, uint256 offeringId);
    event ListingAuthorizerAdded(uint256 indexed listingId, address authorizer);
    event ListingAuthorizerRemoved(uint256 indexed listingId, address authorizer);
    event ListingRemoved(uint256 indexed listingId);

 	constructor(string memory _name, address _owner) {
        _init(_name, _owner);
    }

    function _init(string memory _name, address _owner) internal {
        name = _name;
        nextListingId = 0;
        transferOwnership(_owner);
    }

    function init(string memory _name, address _owner) public {
        require(owner() == address(0), "already initialized");
        OwnableClone.init(msg.sender);
        _init(_name, _owner);
    }

    /**
     * bearer token format == abi encoding of 
     *   | sales contract address | listing Id | expiration | strike price | nonce |
     * 
     * Signature is over Eth Signed Message of Keccak256 hash of the bearer token
     */
    function purchase(uint256 listingId, address _recipient, uint64 expiration, uint256 price, uint64 nonce, bytes memory signature) public payable {
        require(currentListingIds.contains(listingId), "No such listing");
        require(expiration >= block.timestamp, "Bearer token expired");
        require(price == msg.value, "Price does not match payment");

        bytes memory packedBearerToken = abi.encode(address(this), listingId, expiration, price, nonce);
        bytes32 bearerTokenHash = keccak256(packedBearerToken);
        bytes32 signedMessageHash = ECDSA.toEthSignedMessageHash(bearerTokenHash);
        address signer = ECDSA.recover(signedMessageHash, signature);

        Listing storage listing = listingsById[listingId];

        require(listing.authorizers[signer], string(abi.encodePacked("Signer is not authorized to sell this listing: ", Strings.toHexString(uint160(signer)))));
        
        ISaleable(listing.tokenAddress).processSale(listing.offeringId, _recipient);

        processRevenue(msg.value, payable(owner()));

        postSale(listing.tokenAddress, listing.offeringId, msg.sender, _recipient, price, block.timestamp);
        emit ListingPurchased(signer, listingId, msg.sender, _recipient);
	}

    function addListing(address tokenAddress, uint256 offeringId) public onlyOwner {
        uint256 idx = nextListingId++;
        listingsById[idx].tokenAddress = tokenAddress;
        listingsById[idx].offeringId = offeringId;

        currentListingIds.add(idx);
        emit ListingAdded(idx, tokenAddress, offeringId);
    }

    function removeListing(uint256 listingId) public onlyOwner {
        require(currentListingIds.contains(listingId), "No such listing");
        delete(listingsById[listingId]);
        
        currentListingIds.remove(listingId);
        emit ListingRemoved(listingId);
    }

    function addAuthorizer(uint256 listingId, address authorizer) public onlyOwner {
        require(currentListingIds.contains(listingId), "No such listing");
        Listing storage listing = listingsById[listingId];

        require(!listing.authorizers[authorizer], "Authorizer already added");
        listing.authorizers[authorizer] = true;

        emit ListingAuthorizerAdded(listingId, authorizer);
    }

    function removeAuthorizer(uint256 listingId, address authorizer) public onlyOwner {
        require(currentListingIds.contains(listingId), "No such listing");
        Listing storage listing = listingsById[listingId];

        require(listing.authorizers[authorizer], "Authorizer not added");
        delete(listing.authorizers[authorizer]);

        emit ListingAuthorizerRemoved(listingId, authorizer);
    }

    function clearNonces(uint256 listingId, uint64[] memory nonces) public onlyOwner {
        require(currentListingIds.contains(listingId), "No such listing");
        Listing storage listing = listingsById[listingId];
        for (uint idx = 0; idx < nonces.length; idx++) {
            delete(listing.consumedNonces[nonces[idx]]);
        }
    }

    function authorizeRevenueChange(address, bool) virtual internal override {
        require(msg.sender == owner(), "only owner can change revenue split");
    }

}
