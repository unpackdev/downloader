pragma solidity 0.8.7;

// SPDX-License-Identifier: MIT

import "./ERC721.sol";
import "./IERC20.sol";
import "./Ownable.sol";
import "./IBrandCentralClaimAuction.sol";

/// @title Limited Brand Ticker Auction for composable NFTs that have a claim to a ticker
/// @notice Winners receive a composable NFT that has the SHB from their winning bid wrapped in the NFT
/// @notice Winners will be able to unwrap their SHB from their NFT at a later date
/// @notice If the NFT is sold, the rights to the underlying SHB are sold too - hence the composable nature
contract BrandCentralClaimAuction is ERC721("BrandCentralClaimNFT", "cSHNFT"), IBrandCentralClaimAuction, Ownable {

    event Deployed();
    event BidReceived(string lowerticker, uint256 shbAmount);
    event AuctionForTickerExtended(string lowerticker, uint256 newAuctionEndBlock);
    event TokenClaimed(string lowerticker, uint256 indexed tokenId);
    event URIUpdated(uint256 indexed tokenId);

    /// @dev Token ID -> Token URI set by owner
    mapping(uint256 => string) _tokenUris;

    /// @dev All auction constants
    uint256 public constant SECONDS_PER_BLOCK = 13; // This is only rough
    uint256 public constant BLOCKS_PER_DAY = 1 days / SECONDS_PER_BLOCK;
    uint256 public constant AUCTION_LENGTH_IN_DAYS = 5;
    uint256 public constant TOTAL_AUCTION_LENGTH_IN_BLOCKS = BLOCKS_PER_DAY * AUCTION_LENGTH_IN_DAYS;
    uint256 public constant BID_EXTENSION_IN_BLOCKS = 100;
    uint256 public constant NUM_OF_TICKER_PROPOSALS_PER_DAY = 10;
    uint256 public constant MAX_TICKERS_BEING_AUCTIONED = 50;
    uint256 public constant BID_STEP = 2 * 10 ** 18;

    struct Auction {
        uint256 shbBid;     // Highest SHB bid
        address bidder;     // Current highest bidder
        uint256 biddingEnd; // When the auction ends for this specific ticket
        bool shbClaimed;    // If SHB has been claimed by the NFT owner
    }

    /// @notice Lowercase brand ticker -> Auction information
    mapping(string => Auction) public auctions;

    /// @notice Token ID -> Lower brand ticker
    mapping(uint256 => string) public override tokenIdToLowerTicker;

    /// @notice Lower brand ticker -> Token ID reverse lookup
    mapping(string => uint256) public override lowerTickerToTokenId;

    /// @notice Lower brand ticker -> whether it is restricted and outside of the auction
    mapping(string => bool) public override isRestrictedBrandTicker;

    /// @notice Auction start block. Where bidding of any ticker can start
    uint256 public startBlock;

    /// @notice Auction end block. After this block, no more bids for tickers can be received
    uint256 public endBlock;

    /// @notice Block number after which NFT holders can claim attached SHB tokens
    uint256 public shbClaimBlock;

    /// @notice SHB token address - bidding token for all auctions
    IERC20 public shbToken;

    /// @notice Number of tickers that have been auctioned between start and end block
    uint256 public numberOfTickersBeingAuctioned;

    /// @notice Day number of auction -> Number of tickers that have been auctioned on the day
    mapping(uint256 => uint256) public tickersAuctionedOnDay;

    /// @notice Total supply of the NFT which is equal to the number of winners that have claimed their NFT
    uint256 public totalSupply;

    /// @param _startBlock Block number of when the first batch of tickers will be auctioned
    /// @param _shbToken SHB token address
    constructor(uint256 _startBlock, IERC20 _shbToken) {
        isRestrictedBrandTicker["bsn"] = true;
        isRestrictedBrandTicker["cbsn"] = true;
        isRestrictedBrandTicker["dart"] = true;
        isRestrictedBrandTicker["saver"] = true;
        isRestrictedBrandTicker["stake"] = true;
        isRestrictedBrandTicker["house"] = true;
        isRestrictedBrandTicker["poly"] = true;
        isRestrictedBrandTicker["wolf"] = true;
        isRestrictedBrandTicker["elevt"] = true;
        isRestrictedBrandTicker["mynt"] = true;
        isRestrictedBrandTicker["club"] = true;
        isRestrictedBrandTicker["impfi"] = true;
        isRestrictedBrandTicker["colab"] = true;
        isRestrictedBrandTicker["cland"] = true;

        startBlock = _startBlock;

        // auto calculate end block
        endBlock = startBlock + TOTAL_AUCTION_LENGTH_IN_BLOCKS;

        shbToken = _shbToken;

        emit Deployed();
    }

    /// @notice Once all auctions are open, anyone can bid for a 3-5 letter ticker using SHB tokens
    /// @notice Daily limits for number of tickers that can be auctioned
    /// @notice Only 26 letters of the English alphabet is permitted
    /// @notice A lowercase version is stored but a display version could be stored later. Off chain it would be better to be uppercase
    /// @param _ticker Ticker string that either has an active auction or not
    /// @param _shbBidAmount Bid amount in SHB for the ticker
    function bidForTicker(string calldata _ticker, uint256 _shbBidAmount) external {
        require(_blockNumber() > startBlock, "Auctions not started");
        require(bytes(_ticker).length >= 3 && bytes(_ticker).length <= 5, "Must be between 3-5 characters");

        string memory lowerBrandTicker = _toLowerCase(_ticker);
        require(!isRestrictedBrandTicker[lowerBrandTicker], "Cannot bid for restricted ticker");

        Auction storage auction = auctions[lowerBrandTicker];

        // ensure first bid and increments go up by minimum stated by minBid() function
        if (auction.shbBid == 0) {
            require(_shbBidAmount >= minBid(), "Min bid step not reached");
        } else {
            require(_shbBidAmount >= (auction.shbBid + BID_STEP), "Min bid step not reached");

            // refund previous bidder
            shbToken.transfer(auction.bidder, auction.shbBid);
        }

        auction.shbBid = _shbBidAmount;
        auction.bidder = msg.sender;

        // For the first bid, start a countdown timer. Otherwise, if near the end of the auction, go into sudden death.
        bool hasCountdownStarted = auction.biddingEnd != 0;
        if (!hasCountdownStarted) {
            auction.biddingEnd = _blockNumber() + BLOCKS_PER_DAY;

            uint256 _currentDayOfAuction = currentDayOfAuction();
            require(numberOfTickersBeingAuctioned + 1 <= MAX_TICKERS_BEING_AUCTIONED, "Max exceeded");
            require(
                tickersAuctionedOnDay[_currentDayOfAuction] + 1 <= NUM_OF_TICKER_PROPOSALS_PER_DAY,
                "Daily ticker allowance exceeded"
            );
            require(_blockNumber() < endBlock, "All auctions have ended");

            numberOfTickersBeingAuctioned += 1;
            tickersAuctionedOnDay[_currentDayOfAuction] += 1;
        } else {
            require(_blockNumber() < auction.biddingEnd, "Past bidding period for ticker");
            bool isNearEndOfBidding = _blockNumber() > auction.biddingEnd - (BID_EXTENSION_IN_BLOCKS * 2);

            // extend the auction for the ticker if someone is outbidding near the end
            if (isNearEndOfBidding) {
                auction.biddingEnd = auction.biddingEnd + BID_EXTENSION_IN_BLOCKS;
                emit AuctionForTickerExtended(lowerBrandTicker, auction.biddingEnd);
            }
        }

        // Transfer SHB to this contract to be attached to minted NFT
        shbToken.transferFrom(msg.sender, address(this), _shbBidAmount);

        emit BidReceived(lowerBrandTicker, _shbBidAmount);
    }

    /// @notice Winner of the NFT ticker auction can come and claim their composable NFT
    /// @param _ticker Brand ticker the winner won in the auction
    function claimNFT(string calldata _ticker) external {
        string memory lowerBrandTicker = _toLowerCase(_ticker);

        Auction storage auction = auctions[lowerBrandTicker];

        require(msg.sender == auction.bidder, "Only winner");
        require(_blockNumber() > auction.biddingEnd, "Bidding not yet ended");
        require(lowerTickerToTokenId[lowerBrandTicker] == 0, "Token already minted");

        // Increase total supply and use as the next token ID
        totalSupply += 1;

        // Set up the ticker <> token ID mappings
        tokenIdToLowerTicker[totalSupply] = lowerBrandTicker;
        lowerTickerToTokenId[lowerBrandTicker] = totalSupply;

        // Mint the token to the winner
        _mint(msg.sender, totalSupply);

        emit TokenClaimed(lowerBrandTicker, totalSupply);
    }

    /// @notice Once SHB claims are open, the owner of an NFT will be able to claim the underlying SHB from the auction
    function claimSHB(uint256 _tokenId) external {
        require(ownerOf(_tokenId) == msg.sender, "Only token owner");

        Auction storage auction = auctions[tokenIdToLowerTicker[_tokenId]];
        require(!auction.shbClaimed, "SHB claimed");
        require(shbClaimBlock > 0, "SHB claim block not set");
        require(_blockNumber() >= shbClaimBlock, "SHB claim block not reached");

        auction.shbClaimed = true;

        shbToken.transfer(msg.sender, auction.shbBid);
    }

    /// @dev Contract owner can set SHB claim block
    function setSHBClaimBlock(uint256 _blockNum) external onlyOwner {
        shbClaimBlock = _blockNum;
    }

    /// @notice Token owner can set their own token URI unleashing their creativity
    function setTokenUri(uint256 _tokenId, string calldata _uri) external {
        require(ownerOf(_tokenId) == msg.sender, "Only owner");
        _tokenUris[_tokenId] = _uri;
        emit URIUpdated(_tokenId);
    }

    /// @notice returns the token URI for a given token
    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        return _tokenUris[_tokenId];
    }

    /// @notice Based on the start block and auction length in days, returns the current day of the auction
    function currentDayOfAuction() public view returns (uint256) {
        if (_blockNumber() < startBlock) {
            return 1;
        }

        uint256 day;

        for(uint i = 0; i < AUCTION_LENGTH_IN_DAYS; i++) {
            day += 1;

            uint256 lastBlockOfTheDay = startBlock + (day * BLOCKS_PER_DAY);

            if (_blockNumber() < lastBlockOfTheDay) {
                break;
            }
        }

        return day;
    }

    /// @notice Based on the current day of the auction, returns the minimum SHB bid
    function minBid() public view returns (uint256) {
        return (2 ** currentDayOfAuction()) * 10 ** 18;
    }

    /// @notice Returns the current blocknumber which can be overriden by the testing contract
    function _blockNumber() internal virtual view returns (uint256) {
        return block.number;
    }

    /// @notice Converts a string to lowercase and validates characters
    function _toLowerCase(string memory _base) private pure returns (string memory) {
        bytes memory bStr = bytes(_base);
        bytes memory bLower = new bytes(bStr.length);
        for (uint i = 0; i < bStr.length; i++) {
            if ((bStr[i] >= 0x41) && (bStr[i] <= 0x5A)) {
                bLower[i] = bytes1(uint8(bStr[i]) + 32);
            } else {
                require(bStr[i] >= 0x61 && bStr[i] <= 0x7A, "Name can only contain the 26 letters of the roman alphabet");
                bLower[i] = bStr[i];
            }
        }
        return string(bLower);
    }
}
