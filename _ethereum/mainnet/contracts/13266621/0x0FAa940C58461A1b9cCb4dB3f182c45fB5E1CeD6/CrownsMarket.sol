// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ERC721Enumerable.sol";

contract CrownsMarket is Ownable, ERC721Enumerable, ReentrancyGuard {
    string public  standard = 'Crowns';
	string public  baseTokenURI;

	uint256 public  constant MAX_SUPPLY = 12;

	uint256 public  maxTitleLength;
	uint256 public  maxTitles;

	uint256 public  crownSharePct;
	uint256 public  jokerSharePct;

	mapping (uint256 => string[]) public crownTitles;
	mapping (uint256 => uint256) public inscriptionThreshold;
	mapping (uint256 => uint256) public lastPrices;

    struct Offer {
        bool isForSale;
        uint256 crownIndex;
        address seller;
        uint256 minValue; 
        address onlySellTo;
    }

    struct Bid {
        bool hasBid;
        uint256 crownIndex;
        address bidder;
        uint256 value;
    }

    mapping (uint256 => Offer) public crownsOfferedForSale;
    mapping (uint256 => Bid) public crownBids;
    mapping (address => uint256) public pendingWithdrawals;

    event CrownMinted(address indexed to, uint256 indexed crownIndex);
    event CrownTransfer(address indexed from, address indexed to, uint256 indexed crownIndex);
    event CrownOffered(uint256 indexed crownIndex, uint256 minValue, address indexed toAddress);
    event CrownBidEntered(uint256 indexed crownIndex, uint256 value, address indexed fromAddress);
    event CrownBidWithdrawn(uint256 indexed crownIndex, uint256 value, address indexed fromAddress);
    event CrownBought(uint256 indexed crownIndex, uint256 value, address indexed fromAddress, address indexed toAddress);
    event CrownNoLongerForSale(uint256 indexed crownIndex);
	event InscriptionThresholdUpdate(uint256 indexed crownIndex, uint256 threshold);

    constructor() ERC721("Crowns", "C") {
		baseTokenURI = "";

		maxTitleLength = 50;
		maxTitles = 50;
		crownSharePct = 3;
		jokerSharePct = 1;

		crownTitles[0].push('King of Spades');
		crownTitles[1].push('King of Clubs');
		crownTitles[2].push('King of Diamonds');
		crownTitles[3].push('King of Hearts');
		crownTitles[4].push('Queen of Spades');
		crownTitles[5].push('Queen of Clubs');
		crownTitles[6].push('Queen of Diamonds');
		crownTitles[7].push('Queen of Hearts');
		crownTitles[8].push('Jack of Spades');
		crownTitles[9].push('Jack of Clubs');
		crownTitles[10].push('Jack of Diamonds');
		crownTitles[11].push('Jack of Hearts');

        uint256 threshold = 1000000000;
		setInitialInscriptionThreshold(threshold);
    }

    function setBaseURI(string memory baseURI) external onlyOwner {
        baseTokenURI = baseURI;
    }

	function setInitialInscriptionThreshold(uint256 threshold) internal onlyOwner {
		for (uint256 i = 0; i < MAX_SUPPLY; i++) {
			inscriptionThreshold[i] = threshold;
			emit InscriptionThresholdUpdate(i, threshold);
		}
	}

	function claim(uint256 id) external nonReentrant {
	    require(id <= MAX_SUPPLY, "Count too high");
		_safeMint(msg.sender, id);
		emit CrownMinted(msg.sender, id);
    }

    function withdraw() external nonReentrant {
        uint256 amount = pendingWithdrawals[msg.sender];
        pendingWithdrawals[msg.sender] = 0;
		_withdraw(msg.sender, amount);
    }

	function _withdraw(address _address, uint256 _amount) internal {
		(bool success, ) = _address.call{value: _amount}("");
		require(success, "Transfer failed.");
	}

    function offerCrownForSale(uint256 crownIndex, uint256 minSalePriceInWei) external {
        require(ownerOf(crownIndex) == msg.sender, "Not the holder");
        crownsOfferedForSale[crownIndex] = Offer(true, crownIndex, msg.sender, minSalePriceInWei, address(0));
        emit CrownOffered(crownIndex, minSalePriceInWei, address(0));
    }

    function offerCrownForSaleToAddress(uint256 crownIndex, uint256 minSalePriceInWei, address toAddress) external {
        require(ownerOf(crownIndex) == msg.sender, "Not the holder");
        crownsOfferedForSale[crownIndex] = Offer(true, crownIndex, msg.sender, minSalePriceInWei, toAddress);
        emit CrownOffered(crownIndex, minSalePriceInWei, toAddress);
    }

	function crownNoLongerForSale(uint256 crownIndex) public {
        require(ownerOf(crownIndex) == msg.sender, "Not the holder");
        crownsOfferedForSale[crownIndex] = Offer(false, crownIndex, msg.sender, 0, address(0));
        emit CrownNoLongerForSale(crownIndex);
    }

    // Add an inscripton. Inscription price doubles.
	function inscribe(uint256 crownIndex, string memory title) external nonReentrant {
        require(ownerOf(crownIndex) == msg.sender, "Not the holder");
		require(lastPrices[crownIndex] >= inscriptionThreshold[crownIndex], "Purchased price was too low");
		bytes memory bs = bytes(title);
		require(bs.length <= maxTitleLength, "Title too long");
		require(crownTitles[crownIndex].length < maxTitles, "Too many titles");
		crownTitles[crownIndex].push(title);
		while (inscriptionThreshold[crownIndex] <= lastPrices[crownIndex]) {
			inscriptionThreshold[crownIndex] *= 2;
		}
	}

    // Try to buy a crown. If the price offered is high enough the holder cannot refuse.
    function buyCrown(uint256 crownIndex) payable external nonReentrant {
        require(ownerOf(crownIndex) != address(0), "Unowned");
        require(ownerOf(crownIndex) != msg.sender, "Not the holder");
        
        // If the price is higher than last purchase price and inscription price, holder cannot refuse.
        if (msg.value <= lastPrices[crownIndex] || msg.value < inscriptionThreshold[crownIndex]) {
            Offer memory offer = crownsOfferedForSale[crownIndex];
			require(offer.isForSale, "Not for sale");
			require(offer.onlySellTo == address(0) || offer.onlySellTo == msg.sender, "Not for sale to the sender");
			require(msg.value >= offer.minValue, "Too cheap");
			require(offer.seller == ownerOf(crownIndex), "Already sold");
        }

        address seller = ownerOf(crownIndex);

		uint256 crownType;
		if (crownIndex < 4) {
			crownType = 4;
		} else if (crownIndex < 8) {
			crownType = 8;
		} else {
			crownType = 12;
		}

		// Joker cut.
		uint256 jokerShare = msg.value * jokerSharePct / 100;
		pendingWithdrawals[owner()] += jokerShare;
		uint256 remaining = msg.value - jokerShare;
		
		// Crown cut.
		uint256 crownShare = msg.value * crownSharePct / 100;
		for (uint256 i = crownType - 4; i < crownType; i++) {
			pendingWithdrawals[ownerOf(i)] += crownShare;
			remaining -= crownShare;
		}
		pendingWithdrawals[seller] += remaining;

		lastPrices[crownIndex] = msg.value;

		_transfer(seller, msg.sender, crownIndex);

        crownNoLongerForSale(crownIndex);

        emit CrownBought(crownIndex, msg.value, seller, msg.sender);

        // Check for the case where there is a bid from the new owner and refund it.
        // Any other bid can stay in place.
        Bid memory bid = crownBids[crownIndex];
        if (bid.bidder == msg.sender) {
            // Kill bid and refund value
            pendingWithdrawals[msg.sender] += bid.value;
            crownBids[crownIndex] = Bid(false, crownIndex, address(0), 0);
        }
    }

    function enterBidForCrown(uint256 crownIndex) payable external {
        require(ownerOf(crownIndex) != address(0), "Unowned");
        require(ownerOf(crownIndex) != msg.sender, "Holder can't bid");
		require(msg.value > 0, "Zero bid");
        Bid memory existing = crownBids[crownIndex];
		require(msg.value > existing.value, "Lower bid than existing");
        if (existing.value > 0) {
            // Refund the failing bid
            pendingWithdrawals[existing.bidder] += existing.value;
        }
        crownBids[crownIndex] = Bid(true, crownIndex, msg.sender, msg.value);
        emit CrownBidEntered(crownIndex, msg.value, msg.sender);
    }

    function acceptBidForCrown(uint256 crownIndex, uint256 minPrice) external nonReentrant {
        require(ownerOf(crownIndex) == msg.sender, "Not the holder");
        address seller = msg.sender;
        Bid memory bid = crownBids[crownIndex];
		require(bid.value > 0, "Zero bid");
		// In case the top bidder withdrew.
		require(bid.value >= minPrice, "Low bid");

		uint256 crownType;
		if (crownIndex < 4) {
			crownType = 4;
		} else if (crownIndex < 8) {
			crownType = 8;
		} else {
			crownType = 12;
		}

		// Joker cut.
		uint256 jokerShare = bid.value * jokerSharePct / 100;
		pendingWithdrawals[owner()] += jokerShare;
		uint256 remaining = bid.value - jokerShare;
		
		// Crown cut.
		uint256 crownShare = bid.value * crownSharePct / 100;
		for (uint256 i = crownType - 4; i < crownType; i++) {
			pendingWithdrawals[ownerOf(i)] += crownShare;
			remaining -= crownShare;
		}
		pendingWithdrawals[seller] += remaining;

		lastPrices[crownIndex] = bid.value;

		_transfer(seller, bid.bidder, crownIndex);

        crownsOfferedForSale[crownIndex] = Offer(false, crownIndex, bid.bidder, 0, address(0));

        crownBids[crownIndex] = Bid(false, crownIndex, address(0), 0);
        emit CrownBought(crownIndex, bid.value, seller, bid.bidder);
    }

    function withdrawBidForCrown(uint256 crownIndex) external nonReentrant {
        require(ownerOf(crownIndex) != address(0), "Unowned");
        require(ownerOf(crownIndex) != msg.sender, "Holder can't bid");
        Bid memory bid = crownBids[crownIndex];
		require(bid.bidder == msg.sender, "Only bidder can withdraw bid");
        emit CrownBidWithdrawn(crownIndex, bid.value, msg.sender);
        uint256 amount = bid.value;
        crownBids[crownIndex] = Bid(false, crownIndex, address(0), 0);
        // Refund the bid money
		_withdraw(msg.sender, amount);
    }
}

