// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "./IERC721Enumerable.sol";
import "./GenArtAccess.sol";
import "./IGenArtDutchAuctionHouse.sol";
import "./MintStateDA.sol";
import "./IGenArtInterface.sol";
import "./IGenArtSharing.sol";
import "./IGenArtDARefund.sol";

contract GenArtDutchAuctionHouse is GenArtAccess, IGenArtDutchAuctionHouse {
    using MintStateDA for MintStateDA.State;

    struct Mint {
        uint256 amount;
        uint256 eth;
    }

    mapping(address => MintStateDA.State) public _mintstate;

    // maps collections to auctions
    mapping(address => Auction) public _auctions;

    // maps the auctions to memberships mints by phase
    mapping(address => mapping(address => mapping(uint256 => uint256)))
        public _mints;

    // maps total funds earned by an auction
    mapping(address => uint256) public _auctionFunds;

    // marks if artist funds for an auction have been withdrawn
    mapping(address => bool) public _artistsWithdrawHistory;

    // maps total funds earned by an auction split by phase
    mapping(address => mapping(uint256 => uint256)) public _auctionFundsByPhase;

    // uint256 public constant BLOCKS_PER_HOUR = 260;
    uint256 public constant BLOCKS_PER_HOUR = 1;
    uint256 public constant DECAY = 20;
    uint256 public constant DECAY_PER_BLOCKS = BLOCKS_PER_HOUR * 12;
    uint256 public constant BLOCKS_TO_PUBLIC_MINT = BLOCKS_PER_HOUR * 72;
    uint256 public constant AUCTION_BLOCK_DURATION = BLOCKS_PER_HOUR * 336;
    address public _genartInterface;

    /**
     @dev Shares according to GIP# #0001
          Artist | GEN.ART | GEN.ART Token stakers
     */
    uint256[3] public _salesShares = [700, 175, 125];

    // GEN.ART | GenArtSharing (GENART Staking contract) | GenArtDARefund
    address[3] public _payoutAddresses = [owner(), address(0), address(0)];

    modifier onlyCollection(address collection) {
        require(
            _auctions[collection].startBlock > 0,
            "GenArtDutchAuctionHouse: only collection contract allowed"
        );
        _;
    }

    modifier onlyArtist(address collection) {
        require(
            _auctions[collection].artist == msg.sender,
            "GenArtDutchAuctionHouse: only artist allowed"
        );
        _;
    }

    function addAuction(
        address collection,
        address artist,
        uint256 supply,
        uint256 startPrice,
        uint256 startBlock
    ) public override onlyAdmin {
        _auctions[collection] = Auction({
            artist: artist,
            startBlock: startBlock,
            startPrice: startPrice,
            supply: supply,
            endBlock: startBlock + AUCTION_BLOCK_DURATION,
            distributed: false
        });
        _mintstate[collection].init();
    }

    function getAuction(address collection)
        public
        view
        override
        returns (Auction memory)
    {
        Auction memory auction = _auctions[collection];
        require(
            auction.startBlock > 0,
            "GenArtDutchAuctionHouse: auction not found"
        );
        return auction;
    }

    /**
    @dev Get status of an auction
    - 0 : ended
    - 1 : open for GEN.ART members
    - 2 : open for public
    */
    function getAuctionStatus(address collection)
        public
        view
        override
        returns (uint8)
    {
        Auction memory auction = getAuction(collection);
        return
            block.number > auction.endBlock
                ? 0
                : block.number > (auction.startBlock + BLOCKS_TO_PUBLIC_MINT)
                ? 2
                : 1;
    }

    /**
     * @notice An auction has 4 phases which are determinted by amount of blocks passed since start of auction
     */
    function getAuctionPhase(address collection) public view returns (uint256) {
        uint256 lambda = ((block.number - getAuction(collection).startBlock) /
            DECAY_PER_BLOCKS) + 1;
        // Maximum 4 phases
        return lambda > 4 ? 4 : lambda;
    }

    function getAuctionPriceByPhase(address collection, uint256 phase)
        public
        view
        returns (uint256)
    {
        Auction memory auction = getAuction(collection);
        return
            (auction.startPrice * ((100 - DECAY)**(phase - 1))) /
            (100**(phase - 1));
    }

    function getAuctionPrice(address collection)
        public
        view
        override
        returns (uint256)
    {
        Auction memory auction = getAuction(collection);

        // revert if auction is closed
        require(
            block.number >= auction.startBlock &&
                block.number <= auction.endBlock,
            "GenArtDutchAuctionHouse: auction closed"
        );

        uint8 status = getAuctionStatus(collection);

        // return the price based on the auction status
        return
            status == 2
                ? calcAvgPrice(collection)
                : getAuctionPriceByPhase(
                    collection,
                    getAuctionPhase(collection)
                );
    }

    function calcAvgPrice(address collection) public view returns (uint256) {
        uint256 supply = IERC721Enumerable(collection).totalSupply();

        if (supply <= 1) {
            // in case no items were sold during the auction there is no avg price
            // but the price of the last phase
            return getAuctionPriceByPhase(collection, 4);
        }
        // caclulate the average price and exclude the reserved mint
        return _auctionFunds[collection] / (supply - 1);
    }

    function getMintsByMembership(address collection, uint256 membershipId)
        public
        view
        returns (uint256)
    {
        return
            _mintstate[collection].getMints(
                membershipId,
                IGenArtInterface(_genartInterface).isGoldToken(membershipId),
                getAuctionPhase(collection)
            );
    }

    function getAvailableMintsByMembership(
        address collection,
        uint256 membershipId
    ) external view override returns (uint256) {
        return
            _mintstate[collection].getAvailableMints(
                membershipId,
                IGenArtInterface(_genartInterface).isGoldToken(membershipId),
                getAuctionPhase(collection),
                getAuction(collection).supply,
                IERC721Enumerable(collection).totalSupply()
            );
    }

    /**
        @dev Calculate the total revenue shares of an auction 
        - `index`: index of `_salesShares`
     */
    function calcShares(address collection, uint8 index)
        internal
        view
        returns (uint256)
    {
        uint256 value = ((_auctionFunds[collection] -
            calcTotalDARefundAmount(collection)) * _salesShares[index]) / 1000;

        return value;
    }

    /**
     * @notice Calculate total ETH amount to be refunded
     */
    function calcTotalDARefundAmount(address collection)
        internal
        view
        returns (uint256)
    {
        uint256 refundPhasesEth;
        uint256 refundPhasesSales;
        uint256 currentPhase = 1;
        // get avg price and exclude the reserved mint
        uint256 avgPriceDA = calcAvgPrice(collection);

        while (currentPhase <= 4) {
            uint256 price = getAuctionPriceByPhase(collection, currentPhase);
            if (price > avgPriceDA) {
                refundPhasesEth += _auctionFundsByPhase[collection][
                    currentPhase
                ];
                refundPhasesSales +=
                    _auctionFundsByPhase[collection][currentPhase] /
                    price;
            }
            currentPhase++;
        }

        uint256 totalDARefunds = refundPhasesEth -
            (refundPhasesSales * avgPriceDA);

        return totalDARefunds;
    }

    /**
     * @notice Whenever a token is minted in `GenArtERC721DA` this function is been called
     */
    function saveMint(
        uint256 membershipId,
        address minter,
        uint256 amount
    ) external onlyCollection(msg.sender) {
        uint256 phase = getAuctionPhase(msg.sender);

        // calculate amount of ETH minter has spend
        uint256 value = amount * getAuctionPriceByPhase(msg.sender, phase);

        // save amount per collection, minter and phase
        _mints[msg.sender][minter][phase] += amount;

        // update mint state
        _mintstate[msg.sender].update(
            membershipId,
            IGenArtInterface(_genartInterface).isGoldToken(membershipId),
            phase,
            amount
        );

        // adjust auction funds
        _auctionFundsByPhase[msg.sender][phase] += value;
    }

    /**
     * @notice External function called by GenArtERC721DA contract to send funds to the auction house
     */
    function sendFunds() external payable onlyCollection(msg.sender) {
        _auctionFunds[msg.sender] += msg.value;
    }

    /**
     * @notice Determine the phases that need to be refunded
     */
    function calcRefundPhase(address collection)
        external
        view
        returns (uint256)
    {
        uint256 refundPhase;
        uint256 currentPhase = 4;
        // get average price
        uint256 avgPriceDA = calcAvgPrice(collection);

        // loop through all phases
        while (currentPhase >= 1) {
            if (getAuctionPriceByPhase(collection, currentPhase) > avgPriceDA) {
                refundPhase = currentPhase;
                // break the loop since remaining phases must be refunded too
                break;
            }
            currentPhase--;
        }
        return refundPhase;
    }

    /**
     * @notice function for artists to withdraw their shares
     */
    function withdrawArtist(address collection) public onlyArtist(collection) {
        Auction memory auction = getAuction(collection);

        // revert if auction not ended yet
        require(
            block.number > auction.endBlock + 1,
            "GenArtDutchAuctionHouse: auction not ended yet"
        );

        // revert if funds for collection were already withdrawn
        require(
            !_artistsWithdrawHistory[collection],
            "GenArtDutchAuctionHouse: already widthdrawn"
        );

        _artistsWithdrawHistory[collection] = true;

        // send fund to artist
        payable(auction.artist).transfer(calcShares(collection, 0));
    }

    function distributeRewards(address collection) external onlyAdmin {
        Auction memory auction = getAuction(collection);

        // revert if auction not ended yet
        require(
            block.number > auction.endBlock,
            "GenArtDutchAuctionHouse: auction not finished yet"
        );

        // revert if funds for collection were already distributed
        require(
            !auction.distributed,
            "GenArtDutchAuctionHouse: already distributed"
        );

        // check if payout addresses were set
        require(
            _payoutAddresses[0] != address(0) &&
                _payoutAddresses[1] != address(0) &&
                _payoutAddresses[2] != address(0),
            "GenArtDutchAuctionHouse: payout addresses not set"
        );

        // calculate rewards for token stakers
        uint256 stakingRewards = calcShares(collection, 2);

        // calculate DA refund
        uint256 daRefunds = calcTotalDARefundAmount(collection);

        _auctions[collection].distributed = true;

        // send rewards to staking contact
        IGenArtSharing(_payoutAddresses[1]).updateRewards{
            value: stakingRewards
        }(BLOCKS_PER_HOUR * 24 * 30);

        // send funds to DA refund contract
        IGenArtDARefund(_payoutAddresses[2]).receiveFunds{value: daRefunds}(
            collection
        );

        // send fund to GA admin
        payable(_payoutAddresses[0]).transfer(calcShares(collection, 1));
    }

    /**
     * @notice set payout addresses
     */
    function setSalesShares(uint256[3] memory newShares) public onlyGenArtAdmin {
        uint256 totalShares;
        for (uint8 i; i < newShares.length; i++) {
            totalShares += newShares[i];
        }
        require(
            totalShares == 1000,
            "GenArtDutchAuctionHouse: total shares must be 1000"
        );
        _salesShares = newShares;
    }

    /**
    @dev set the payout address for ETH distribution
    - `index`: 0 (GEN.ART) | 1 (Staking contract) | 2 (Refund contract)
    - `payoutAddress`: new address
 */
    function setPayoutAddress(uint8 index, address payoutAddress)
        public
        onlyGenArtAdmin
    {
        _payoutAddresses[index] = payoutAddress;
    }

    /**
     *@dev Set Interface contract address
     */
    function setInterface(address interfaceAddress) public onlyAdmin {
        _genartInterface = interfaceAddress;
    }

    receive() external payable {
        payable(owner()).transfer(msg.value);
    }
}
