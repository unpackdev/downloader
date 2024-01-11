// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "Ownable.sol";
import "PrideIcons.sol";

contract PrideIconsAuction is Ownable {
    uint16 internal constant SECONDS_IN_HOUR = 3600;
    uint8 internal constant DEFAULT_INTERVAL_HOURS = 24;
    uint8 internal constant DEFAULT_BIDS_IN_PARALLEL = 3;

    uint256 public minimumBid;

    struct BidOpenTimes {
        // Timestamps - when bidding open / closed for given token.
        uint256 biddingOpen;
        uint256 biddingClosed;
    }
    mapping(uint8 => BidOpenTimes) public bidTimestamps;

    struct Bid {
        address walletBidder;
        address walletRecipient;
        uint256 bidAmount;
    }
    // Token ID => all bids
    mapping(uint8 => Bid[]) public bidHistory;

    // Token ID => auction cancelled / not cancelled
    mapping(uint8 => bool) public cancelledAuctions;

    // Paper wallets
    mapping(address => bool) private paperWallets;

    bool public locked;

    PrideIcons public prideIcons;

    // @VisibleForTesting
    address internal vaultAddress;

    event BidPlaced(
        uint8 indexed tokenId,
        address bidder,
        address recipient,
        uint256 amount
    );
    event AuctionEnded(
        uint8 indexed tokenId,
        address bidder,
        address recipient,
        uint256 amount
    );
    event AuctionCancelled(uint8 indexed tokenId, address bidder);

    constructor(
        address _vaultAddress,
        uint256 _minimumBid,
        address _prideIconsAddress,
        uint256 _timestamp,
        address[] memory _paperWallets
    ) {
        require(_vaultAddress != address(0), "NULL_ADDRESS");
        vaultAddress = _vaultAddress;
        minimumBid = _minimumBid;
        prideIcons = PrideIcons(_prideIconsAddress);
        initializeTimestamps(
            _timestamp,
            DEFAULT_INTERVAL_HOURS,
            DEFAULT_BIDS_IN_PARALLEL
        );
        initializePaperWallets(_paperWallets);
    }

    modifier notLocked() {
        require(!locked, "CONTRACT_METADATA_METHODS_ARE_LOCKED");
        _;
    }

    modifier onlyPaperOrOwner() {
        require(
            paperWallets[msg.sender] || owner() == msg.sender,
            "ONLY_PAPER_WALLETS_OR_OWNER_ALLOWED"
        );
        _;
    }

    // Method for Paper.xyz (sends on behalf of another wallet)
    function placeBid(uint8 tokenId, address recipient)
        external
        payable
        onlyPaperOrOwner
    {
        _placeBid(tokenId, recipient);
    }

    function placeBid(uint8 tokenId) external payable {
        _placeBid(tokenId, msg.sender);
    }

    function _placeBid(uint8 tokenId, address recipient) private notLocked {
        Bid memory currentTopBid = getTopBid(tokenId);
        require(
            block.timestamp >= bidTimestamps[tokenId].biddingOpen &&
                block.timestamp <= bidTimestamps[tokenId].biddingClosed,
            "BIDDING_FOR_TOKEN_CLOSED"
        );
        require(!cancelledAuctions[tokenId], "AUCTION_CANCELLED");

        Bid memory latestBid = Bid(msg.sender, recipient, msg.value);
        if (currentTopBid.bidAmount == 0) {
            require(latestBid.bidAmount >= minimumBid, "BID_UNDER_MINIMUM");
        } else {
            require(
                latestBid.bidAmount > currentTopBid.bidAmount,
                "BID_TOO_LOW"
            );
            payable(currentTopBid.walletBidder).transfer(
                currentTopBid.bidAmount
            );
        }
        bidHistory[tokenId].push(latestBid);
        emit BidPlaced(
            tokenId,
            latestBid.walletBidder,
            latestBid.walletRecipient,
            latestBid.bidAmount
        );
    }

    function endAuction(uint8 tokenId) external notLocked {
        Bid memory currentTopBid = getTopBid(tokenId);
        require(!cancelledAuctions[tokenId], "AUCTION_CANCELLED");
        require(
            msg.sender == currentTopBid.walletBidder ||
                paperWallets[msg.sender] ||
                msg.sender == owner(),
            "ONLY_BIDDER_OR_PAPER_OR_OWNER_ALLOWED"
        );
        require(
            block.timestamp >= bidTimestamps[tokenId].biddingClosed,
            "BIDDING_NOT_OVER"
        );
        require(address(prideIcons) != address(0), "NULL_CONTRACT_ADDRESS");
        require(currentTopBid.walletRecipient != address(0), "NO_WINNERS");
        prideIcons.mintPlatinum(tokenId, currentTopBid.walletRecipient);

        emit AuctionEnded(
            tokenId,
            currentTopBid.walletBidder,
            currentTopBid.walletRecipient,
            currentTopBid.bidAmount
        );
    }

    function cancelAuction(uint8 tokenId) external onlyPaperOrOwner notLocked {
        Bid memory currentTopBid = getTopBid(tokenId);
        require(!cancelledAuctions[tokenId], "ALREADY_CANCELLED");
        require(currentTopBid.bidAmount != 0, "MUST_HAVE_BID");
        require(currentTopBid.walletBidder != address(0), "MUST_HAVE_BIDDER");
        require(
            paperWallets[currentTopBid.walletBidder] || msg.sender == owner(),
            "ONLY_PAPER_BIDDER_OR_OWNER_ALLOWED"
        );
        require(address(prideIcons) != address(0), "NULL_CONTRACT_ADDRESS");
        require(
            !prideIcons.hasMintedPlatinum(tokenId),
            "AUCTION_ALREADY_ENDED"
        );

        // Pay back bid to top bidder.
        payable(currentTopBid.walletBidder).transfer(currentTopBid.bidAmount);

        // Cancel auction.
        cancelledAuctions[tokenId] = true;

        emit AuctionCancelled(tokenId, currentTopBid.walletBidder);
    }

    function getBidHistory(uint8 tokenId) external view returns (Bid[] memory) {
        return bidHistory[tokenId];
    }

    function initializeTimestamps(
        uint256 firstBidStartTime,
        uint256 intervalDurationHours,
        uint8 bidsInParallel
    ) public onlyOwner {
        require(address(prideIcons) != address(0), "NULL_CONTRACT_ADDRESS");
        uint16 platinumSupply = prideIcons.platinumSupply();

        for (uint8 i = 1; i <= platinumSupply; i++) {
            for (uint8 j = 0; j < bidsInParallel; j++) {
                // Assign biddingOpen and biddingClosed fields
                uint8 index = i + j + (bidsInParallel - 1) * (i - 1);
                if (index > platinumSupply) return;
                bidTimestamps[index] = BidOpenTimes(
                    firstBidStartTime +
                        ((i - 1) * intervalDurationHours * SECONDS_IN_HOUR),
                    firstBidStartTime +
                        (i * intervalDurationHours * SECONDS_IN_HOUR)
                );
            }
        }
    }

    function getTopBid(uint8 tokenId) public view returns (Bid memory) {
        Bid[] memory bids = bidHistory[tokenId];
        return
            bids.length == 0
                ? Bid(address(0), address(0), 0)
                : bids[bids.length - 1];
    }

    // virtual for tests
    function initializePaperWallets(address[] memory wallets)
        public
        virtual
        onlyOwner
    {
        for (uint8 i = 0; i < wallets.length; i++) {
            paperWallets[wallets[i]] = true;
        }
    }

    function withdrawAll() external onlyOwner {
        payable(vaultAddress).transfer(address(this).balance);
    }

    // Ad hoc modification of bidding times for a specific tokens.
    function modifyTimeStampForTokens(
        uint8[] calldata tokenIds,
        BidOpenTimes[] calldata biddingTimes
    ) external onlyOwner {
        require(tokenIds.length == biddingTimes.length, "UNEQUAL_LENGTH");
        for (uint8 i = 0; i < tokenIds.length; i++) {
            bidTimestamps[tokenIds[i]] = biddingTimes[i];
        }
    }

    function setVaultAddress(address newVault) external onlyOwner {
        require(newVault != address(0), "NULL_ADDRESS");
        vaultAddress = newVault;
    }

    function setMinimumBid(uint256 _minimumBid) external onlyOwner {
        minimumBid = _minimumBid;
    }

    function assignNftContractAddress(address contractAddress)
        external
        onlyOwner
    {
        require(contractAddress != address(0), "NULL_ADDRESS");
        prideIcons = PrideIcons(contractAddress);
    }

    function lockAuction() external onlyOwner {
        locked = true;
    }

    function unlockAuction() external onlyOwner {
        locked = false;
    }

    struct CancelledAuctionMap {
        uint8 tokenId;
        bool cancelled;
    }
    struct BidHistoryMap {
        uint8 tokenId;
        Bid[] bids;
    }

    // Used during emergencies when we need to replace the contract during an active auction
    function migrate(
        CancelledAuctionMap[] calldata _cancelledAuctions,
        BidHistoryMap[] calldata _bidHistory
    ) external onlyOwner {
        // Update all bid history.
        for (uint8 i = 0; i < _bidHistory.length; i++) {
            uint8 tokenId = _bidHistory[i].tokenId;
            for (uint256 j = 0; j < _bidHistory[i].bids.length; j++) {
                bidHistory[tokenId].push(
                    Bid(
                        _bidHistory[i].bids[j].walletBidder,
                        _bidHistory[i].bids[j].walletRecipient,
                        _bidHistory[i].bids[j].bidAmount
                    )
                );
            }
        }

        // Update all cancelled auctions.
        for (uint8 i = 0; i < _cancelledAuctions.length; i++) {
            uint8 tokenId = _cancelledAuctions[i].tokenId;
            cancelledAuctions[tokenId] = _cancelledAuctions[i].cancelled;
        }
    }
}
