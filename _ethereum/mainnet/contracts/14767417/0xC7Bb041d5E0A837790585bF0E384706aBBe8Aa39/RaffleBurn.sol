// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./VRFCoordinatorV2Interface.sol";
import "./VRFConsumerBaseV2.sol";
import "./IERC721.sol";
import "./IERC20.sol";
import "./IERC20Burnable.sol";

contract RaffleBurn is VRFConsumerBaseV2 {
    event RaffleCreated(
        uint256 indexed raffleId,
        address indexed from,
        address indexed paymentToken,
        uint256 ticketPrice,
        uint256 startTimestamp,
        uint256 endTimestamp
    );

    event PrizeAdded(
        uint256 indexed raffleId,
        address indexed from,
        address indexed prizeToken,
        uint256 tokenId
    );

    event TicketsPurchased(
        uint256 indexed raffleId,
        address indexed to,
        uint256 startId,
        uint256 amount
    );

    event SeedInitialized(uint256 indexed raffleId, uint256 indexed requestId);

    struct Prize {
        address tokenAddress;
        uint96 tokenId;
        address owner;
        bool claimed;
    }

    struct Ticket {
        address owner;
        uint96 endId;
    }

    struct Raffle {
        address paymentToken;
        bool burnable;
        uint40 startTimestamp;
        uint40 endTimestamp;
        uint160 ticketPrice;
        uint96 seed;
    }

    /*
    GLOBAL STATE
    */

    VRFCoordinatorV2Interface COORDINATOR;

    uint256 public raffleCount;

    mapping(uint256 => Raffle) public raffles;
    mapping(uint256 => Prize[]) public rafflePrizes;
    mapping(uint256 => Ticket[]) public raffleTickets;
    mapping(uint256 => uint256) public requestIdToRaffleId;

    constructor(address vrfCoordinator) VRFConsumerBaseV2(vrfCoordinator) {
        COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
    }

    /*
    WRITE FUNCTIONS
    */

    /**
     * @notice initializes the raffle
     * @param prizeToken the address of the ERC721 token to raffle off
     * @param tokenIds the list of token ids to raffle off
     * @param paymentToken address of the ERC20 token used to buy tickets. Null address uses ETH
     * @param startTimestamp the timestamp at which the raffle starts
     * @param endTimestamp the timestamp at which the raffle ends
     * @param ticketPrice the price of each ticket
     * @return raffleId the id of the raffle
     */
    function createRaffle(
        address prizeToken,
        uint96[] calldata tokenIds,
        address paymentToken,
        bool burnable,
        uint40 startTimestamp,
        uint40 endTimestamp,
        uint160 ticketPrice
    ) external returns (uint256 raffleId) {
        require(prizeToken != address(0), "prizeToken cannot be null");
        require(paymentToken != address(0), "paymentToken cannot be null");
        require(
            endTimestamp > block.timestamp,
            "endTimestamp must be in the future"
        );
        require(ticketPrice > 0, "ticketPrice must be greater than 0");

        raffleId = raffleCount++;

        raffles[raffleId] = Raffle({
            paymentToken: paymentToken,
            burnable: burnable,
            startTimestamp: startTimestamp,
            endTimestamp: endTimestamp,
            ticketPrice: ticketPrice,
            seed: 0
        });

        emit RaffleCreated(
            raffleId,
            msg.sender,
            paymentToken,
            ticketPrice,
            startTimestamp,
            endTimestamp
        );

        addPrizes(raffleId, prizeToken, tokenIds);
    }

    /**
     * @notice add prizes to raffle. Must have transfer approval from contract
     *  owner or token owner
     * @param raffleId the id of the raffle
     * @param prizeToken the address of the ERC721 token to raffle off
     * @param tokenIds the list of token ids to raffle off
     */
    function addPrizes(
        uint256 raffleId,
        address prizeToken,
        uint96[] calldata tokenIds
    ) public {
        require(tokenIds.length > 0, "tokenIds must be non-empty");
        for (uint256 i = 0; i < tokenIds.length; i++) {
            IERC721(prizeToken).transferFrom(
                msg.sender,
                address(this),
                tokenIds[i]
            );
            rafflePrizes[raffleId].push(
                Prize({
                    tokenAddress: prizeToken,
                    tokenId: tokenIds[i],
                    owner: msg.sender,
                    claimed: false
                })
            );
            emit PrizeAdded(raffleId, msg.sender, prizeToken, tokenIds[i]);
        }
    }

    /**
     * @notice buy ticket with erc20
     * @param raffleId the id of the raffle to buy ticket for
     * @param ticketCount the number of tickets to buy
     */
    function buyTickets(uint256 raffleId, uint96 ticketCount) external {
        require(raffleStarted(raffleId), "Raffle not started");
        require(!raffleEnded(raffleId), "Raffle ended");
        // transfer payment token from account
        uint256 cost = uint256(raffles[raffleId].ticketPrice) * ticketCount;
        _burnTokens(raffleId, msg.sender, cost);
        // give tickets to account
        _mintTickets(msg.sender, raffleId, ticketCount);
    }

    /**
     * @notice claim prize
     * @param raffleId the id of the raffle to buy ticket for
     * @param prizeIndex the index of the prize to claim
     * @param ticketPurchaseIndex the index of the ticket purchase to claim prize for
     */
    function claimPrize(
        uint256 raffleId,
        uint256 prizeIndex,
        uint256 ticketPurchaseIndex
    ) external {
        require(raffles[raffleId].seed != 0, "Seed not set");
        require(
            rafflePrizes[raffleId][prizeIndex].claimed == false,
            "Prize already claimed"
        );

        address to = raffleTickets[raffleId][ticketPurchaseIndex].owner;
        uint256 winnerTicketId = getWinnerTicketId(raffleId, prizeIndex);
        uint96 purchaseStartId = _getPurchaseStartId(
            raffleId,
            ticketPurchaseIndex
        );
        uint96 purchaseEndId = _getPurchaseEndId(raffleId, ticketPurchaseIndex);
        require(
            purchaseStartId <= winnerTicketId && winnerTicketId < purchaseEndId,
            "Not winner ticket"
        );

        rafflePrizes[raffleId][prizeIndex].claimed = true;
        IERC721(rafflePrizes[raffleId][prizeIndex].tokenAddress).transferFrom(
            address(this),
            to,
            rafflePrizes[raffleId][prizeIndex].tokenId
        );
    }

    /**
     * Initialize seed for raffle
     */
    function initializeSeed(
        uint256 raffleId,
        bytes32 keyHash,
        uint64 subscriptionId
    ) external {
        require(raffleEnded(raffleId), "Raffle not ended");
        require(raffles[raffleId].seed == 0, "Seed already requested");
        // Will revert if subscription is not set and funded.
        uint256 requestId = COORDINATOR.requestRandomWords(
            keyHash,
            subscriptionId,
            3,
            300000,
            1
        );
        requestIdToRaffleId[requestId] = raffleId;
    }

    /**
     * Callback function used by VRF Coordinator
     */
    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords)
        internal
        override
    {
        uint256 raffleId = requestIdToRaffleId[requestId];
        require(raffles[raffleId].seed == 0, "Seed already initialized");
        raffles[raffleId].seed = uint96(randomWords[0]);
        emit SeedInitialized(raffleId, requestId);
    }

    /**
     * @dev mints tickets to account
     * @param to the account to send ticket to
     * @param raffleId the id of the raffle to send ticket for
     * @param ticketCount the number of tickets to send
     */
    function _mintTickets(
        address to,
        uint256 raffleId,
        uint96 ticketCount
    ) internal {
        uint96 purchaseStartId = _getPurchaseStartId(
            raffleId,
            raffleTickets[raffleId].length
        );
        uint96 purchaseEndId = purchaseStartId + ticketCount;
        Ticket memory ticket = Ticket({owner: to, endId: purchaseEndId});
        raffleTickets[raffleId].push(ticket);
        emit TicketsPurchased(
            raffleId,
            msg.sender,
            purchaseStartId,
            ticketCount
        );
    }

    function _burnTokens(
        uint256 raffleId,
        address from,
        uint256 amount
    ) internal {
        if (raffles[raffleId].burnable) {
            IERC20Burnable(raffles[raffleId].paymentToken).burnFrom(
                from,
                amount
            );
        } else {
            IERC20(raffles[raffleId].paymentToken).transferFrom(
                from,
                address(0xdead),
                amount
            );
        }
    }

    /*
    READ FUNCTIONS
    */

    /**
     * @dev binary search for winner address
     * @param raffleId the id of the raffle to get winner for
     * @param prizeIndex the index of the prize to get winner for
     * @return account the winner address
     * @return ticketPurchaseIndex the index of the winner ticket purchase
     * @return ticketId the id of the winner ticket
     */
    function getWinner(uint256 raffleId, uint256 prizeIndex)
        public
        view
        returns (
            address account,
            uint256 ticketPurchaseIndex,
            uint256 ticketId
        )
    {
        ticketId = getWinnerTicketId(raffleId, prizeIndex);
        ticketPurchaseIndex = getTicketPurchaseIndex(raffleId, ticketId);
        account = raffleTickets[raffleId][ticketPurchaseIndex].owner;
    }

    /**
     * @dev binary search for ticket purchase index of ticketId
     * @param raffleId the id of the raffle to get winner for
     * @param ticketId the id of the ticket to get index for
     * @return ticketPurchaseIndex the purchase index of the ticket
     */
    function getTicketPurchaseIndex(uint256 raffleId, uint256 ticketId)
        public
        view
        returns (uint256 ticketPurchaseIndex)
    {
        // binary search for winner
        uint256 left = 0;
        uint256 right = raffleTickets[raffleId].length - 1;
        while (left < right) {
            uint256 mid = (left + right) / 2;
            if (raffleTickets[raffleId][mid].endId < ticketId) {
                left = mid + 1;
            } else {
                right = mid;
            }
        }
        ticketPurchaseIndex = left;
    }

    /**
     * @dev salt the seed with prize index and get the winner ticket id
     * @param raffleId the id of the raffle to get winner for
     * @param prizeIndex the index of the prize to get winner for
     * @return ticketId the id of the ticket that won
     */
    function getWinnerTicketId(uint256 raffleId, uint256 prizeIndex)
        public
        view
        returns (uint256 ticketId)
    {
        // add salt to seed
        ticketId =
            uint256(keccak256((abi.encode(raffleId, prizeIndex)))) %
            rafflePrizes[raffleId].length;
    }

    /**
     * @notice get total number of tickets for a purchase
     * @param raffleId the id of the raffle to get number of tickets for
     * @param ticketPurchaseIndex the index of the ticket purchase to get number of tickets for
     * @return ticketCount the number of tickets
     */
    function getPurchaseTicketCount(
        uint256 raffleId,
        uint256 ticketPurchaseIndex
    ) public view returns (uint256 ticketCount) {
        return
            _getPurchaseEndId(raffleId, ticketPurchaseIndex) -
            _getPurchaseStartId(raffleId, ticketPurchaseIndex);
    }

    /**
     * @notice get total number of tickets purchased by an account
     * @param raffleId the id of the raffle to get number of tickets for
     * @param account the account to get number of tickets for
     * @return ticketCount the number of tickets
     */
    function getAccountTicketCount(uint256 raffleId, address account)
        public
        view
        returns (uint256 ticketCount)
    {
        for (uint256 i = 0; i < raffleTickets[raffleId].length; i++) {
            if (raffleTickets[raffleId][i].owner == account) {
                ticketCount += getPurchaseTicketCount(raffleId, i);
            }
        }
        return ticketCount;
    }

    /**
     * @notice get total number of prizes for raffle
     * @param raffleId the id of the raffle to get number of prizes for
     * @return prizeCount the number of prizes
     */
    function getPrizeCount(uint256 raffleId)
        public
        view
        returns (uint256 prizeCount)
    {
        return rafflePrizes[raffleId].length;
    }

    /**
     * @notice get total number of purchases for raffle
     * @param raffleId the id of the raffle to get number of purchases for
     * @return purchaseCount the number of tickets
     */
    function getPurchaseCount(uint256 raffleId)
        public
        view
        returns (uint256 purchaseCount)
    {
        return raffleTickets[raffleId].length;
    }

    /**
     * @notice get total number of tickets sold for raffle
     * @param raffleId the id of the raffle to get number of tickets for
     * @return ticketCount the number of tickets
     */
    function getTicketCount(uint256 raffleId)
        public
        view
        returns (uint256 ticketCount)
    {
        uint256 length = raffleTickets[raffleId].length;
        return length > 0 ? raffleTickets[raffleId][length - 1].endId : 0;
    }

    /**
     * @notice get total ticket sales for raffle
     * @param raffleId the id of the raffle to get number of tickets for
     * @return ticketSales the number of tickets
     */
    function getTicketSales(uint256 raffleId)
        public
        view
        returns (uint256 ticketSales)
    {
        return
            getTicketCount(raffleId) * uint256(raffles[raffleId].ticketPrice);
    }

    /**
     * @notice check if raffle ended
     * @param raffleId the id of the raffle to check
     * @return ended true if ended
     */
    function raffleEnded(uint256 raffleId) public view returns (bool ended) {
        return raffles[raffleId].endTimestamp <= block.timestamp;
    }

    /**
     * @notice check if raffle started
     * @param raffleId the id of the raffle to check
     * @return started true if started
     */
    function raffleStarted(uint256 raffleId)
        public
        view
        returns (bool started)
    {
        return raffles[raffleId].startTimestamp <= block.timestamp;
    }

    function _getPurchaseStartId(uint256 raffleId, uint256 ticketPurchaseIndex)
        private
        view
        returns (uint96 endId)
    {
        return
            ticketPurchaseIndex > 0
                ? raffleTickets[raffleId][ticketPurchaseIndex - 1].endId
                : 0;
    }

    function _getPurchaseEndId(uint256 raffleId, uint256 ticketPurchaseIndex)
        private
        view
        returns (uint96 startId)
    {
        return raffleTickets[raffleId][ticketPurchaseIndex].endId;
    }

    /*
    MODIFIERS
    */
}
