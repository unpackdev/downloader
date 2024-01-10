// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./Initializable.sol";
import "./UUPSUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";

contract CakedApesMarket is Initializable, UUPSUpgradeable, OwnableUpgradeable, PausableUpgradeable, ReentrancyGuardUpgradeable {

	enum ListingStatus {
    Blank,
    Cancelled,
		Active,
    Sold
	}

	struct Listing {
		ListingStatus status;
		address seller;
		uint amount;
		uint tokenID;
		uint price;
    uint expiration;
	}

	event Listed(
		ListingStatus status,
		address seller,
		uint amount,
		uint tokenID,
		uint price,
    uint expiration,
    uint id
	);

	event Sale(
		uint listingId,
		address buyer,
		uint amount,
		uint tokenID,
		uint price
	);

	event Cancel(
		uint listingId,
		address seller
	);

	uint private _listingId;
  address payable private _contractAddress;
  address payable _royaltiesTarget;
  uint private _royalties;
	mapping(uint => Listing) private _listings;
  mapping(uint => bool) private _listed;

  //proxy requirement
  function initialize(address nftContract, address target) initializer public {
    __ReentrancyGuard_init();
    __Ownable_init();
    __Pausable_init();
    __UUPSUpgradeable_init();
    _contractAddress = payable(nftContract);
    _royaltiesTarget = payable(target);
    _royalties = 5;
  }
  
  //proxy requirement
  function _authorizeUpgrade(address newImplementation) internal onlyOwner override {}

	function listToken(uint tokenID, uint price, uint expiration) external whenNotPaused {
    require(IERC721(_contractAddress).isApprovedForAll(_msgSender(), address(this)), "Approve the contract");
    require(IERC721(_contractAddress).ownerOf(tokenID) == _msgSender(), "You can't list a token you do no own");
    require(_listed[tokenID] == false, "Token already listed");
    _listed[tokenID] = true;
    _listingId++;
    _listings[_listingId] = Listing(ListingStatus.Active, _msgSender(), 1, tokenID, price, expiration);
		emit Listed(ListingStatus.Active, _msgSender(), 1, tokenID, price, expiration, _listingId);
	}

	function getListing(uint listingId) public view returns (Listing memory) {
    return _listings[listingId];
	}

  // step 1 approve the zingot contract for transaction
  // step 2 call buy token
	function buyToken(uint listingId) external payable nonReentrant whenNotPaused {
    Listing storage listing = _listings[listingId];
    require(listing.status == ListingStatus.Active, "Listing is not active");
		require(_msgSender() != listing.seller, "Seller cannot be buyer");
    require(block.timestamp <= listing.expiration, "Listing expired");
    require(msg.value == listing.price, "wrong eth value sent");
    _listed[listing.tokenID] = false;
    listing.status = ListingStatus.Sold;
		IERC721(_contractAddress).safeTransferFrom(listing.seller, _msgSender(), listing.tokenID, "");
    (bool success, ) = payable(listing.seller).call{value: listing.price * (100 - _royalties) / 100 }("");
    require(success, "Address: unable to send value, recipient may have reverted 1");
    if (_royalties > 0) {
      (bool success, ) = payable(_royaltiesTarget).call{value: listing.price * _royalties / 100 }("");
      require(success, "Address: unable to send value, recipient may have reverted 2");
    }
		emit Sale(listingId, _msgSender(), listing.amount, listing.tokenID, listing.price);
	}

	function cancel(uint listingId) public {
    Listing storage listing = _listings[listingId];
		require(_msgSender() == listing.seller, "Only seller can cancel listing");
		require(listing.status == ListingStatus.Active, "Listing is not active !");
    _listed[listing.tokenID] = false;
    listing.status = ListingStatus.Cancelled;

		emit Cancel(listingId, listing.seller);
	}

  function batchCancel(uint[] calldata listingIdArray) public {
    for (uint256 index = 0; index < listingIdArray.length; index++) {
      cancel(listingIdArray[index]);
    }
	}

  function getListingCount() public view returns(uint count) {
    return _listingId;
  }

  function getRoyalties() public view returns (uint royalties) {
    return _royalties;
  }

  function setRoyalties(uint royalties) public onlyOwner {
    require(royalties < 101, "Can't set the royalties above 100%.");
    _royalties = royalties;
  }

  function setTarget(address target) public onlyOwner {
    _royaltiesTarget = payable(target);
  }
}