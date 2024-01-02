// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "./ERC1155.sol";
import "./ERC1155Holder.sol";
import "./IERC20.sol";
import "./Ownable.sol";

contract RaffleTicket is ERC1155, ERC1155Holder, Ownable {
    IERC20 public pokeboxes;

    uint256 public constant RAFFLE_TICKET = 0;

    uint256 public ticketPrice;

    bytes32[] public allRaffles;

    struct Participant {
        uint256 enteredWithTicket;
        bool enteredWithEth;
        uint256 ethAmount;
    }

    struct Raffle {
        bytes32 raffleId;
        uint256 ticketsEntered;
        uint256 ticketCost;
        string name;
    }

    mapping(bytes32 => mapping(address => Participant))
        public raffleParticipants;

    mapping(bytes32 => Raffle) public raffles;

    mapping(bytes32 => bool) public isActiveRaffle;

    mapping(bytes32 => mapping(address => bool)) public enteredWithETH;

    mapping(address => bool) public ticketUsed;
    mapping(uint256 => uint256) public _totalSupply;
    mapping(bytes32 => uint256) public raffleById;
    mapping(bytes32 => bool) public endById;
    mapping(bytes32 => uint256) public raffleTicketId;
    mapping(bytes32 => mapping(address => uint256)) public ticketsEntered;
    mapping(bytes32 => mapping(uint256 => address)) public ticketOwnership;
    mapping(bytes32 => address) public ticketWinner;
    mapping(bytes32 => mapping(address => bool)) public ethTicket;
    mapping(bytes32 => uint256) public ticketCost;

    event TicketMinted(address indexed to, uint256 quantity);
    event TicketUsed(address indexed user, bytes32 raffleId);
    event TicketClaimed(
        address indexed user,
        bytes32 raffleId,
        uint256 quantity
    );

    /**
     * @dev Emitted when an auction is started.
     * @param raffleId Unique ID of the auction.
     * @param duration Duration of the auction.
     */
    event RaffleStarted(bytes32 indexed raffleId, uint256 duration);

    constructor(
        uint256 _ticketPrice,
        address _pokeboxes
    ) ERC1155("YourMetadataURI") {
        _initializeOwner(msg.sender);
        ticketPrice = _ticketPrice * 1e18;
        pokeboxes = IERC20(_pokeboxes);
        _mint(msg.sender, RAFFLE_TICKET, 50, ""); // tickets to airdrop
    }

    function startRaffle(
        string memory raffleName,
        uint256 _ticketCost,
        uint256 duration
    ) public onlyOwner returns (bytes32) {
        bytes32 raffleId = keccak256(
            abi.encodePacked(raffleName, block.timestamp)
        );

        raffleById[raffleId] = block.timestamp + duration;
        isActiveRaffle[raffleId] = true;
        allRaffles.push(raffleId);
        ticketCost[raffleId] = _ticketCost;
        Raffle storage raffle = raffles[raffleId];
        raffle.raffleId = raffleId;
        raffle.ticketCost = _ticketCost;
        raffle.name = raffleName;

        emit RaffleStarted(raffleId, duration);
        return raffleId;
    }

    function mintTicket(address to, uint256 quantity) public payable {
        pokeboxes.transferFrom(msg.sender, address(this), ticketPrice);
        _mint(to, RAFFLE_TICKET, quantity, "");
        emit TicketMinted(to, quantity);
    }

    function enterWithEth(bytes32 _raffleId) public payable {
        require(
            msg.value >= ticketCost[_raffleId],
            "This raffle costs more eth"
        );
        Participant storage participant = raffleParticipants[_raffleId][
            msg.sender
        ];
        Raffle storage raffle = raffles[_raffleId];
        participant.enteredWithEth = true;
        participant.ethAmount = msg.value;
        ticketOwnership[_raffleId][raffleTicketId[_raffleId]] = msg.sender;
        raffleTicketId[_raffleId]++;
        raffle.ticketsEntered++;
        emit TicketUsed(msg.sender, _raffleId);
    }

    function useTicket(bytes32 _raffleId) public {
        require(balanceOf(msg.sender, RAFFLE_TICKET) > 0, "No tickets owned");
        require(raffleById[_raffleId] > block.timestamp, "Raffle is over");

        Participant storage participant = raffleParticipants[_raffleId][
            msg.sender
        ];
        Raffle storage raffle = raffles[_raffleId];
        participant.enteredWithTicket += 1;

        safeTransferFrom(msg.sender, address(this), RAFFLE_TICKET, 1, "");
        ticketOwnership[_raffleId][raffleTicketId[_raffleId]] = msg.sender;
        raffleTicketId[_raffleId]++;
        ticketsEntered[_raffleId][msg.sender]++;
        raffle.ticketsEntered++;

        emit TicketUsed(msg.sender, _raffleId);
    }

    function raffleWinner(
        bytes32 _raffleId,
        bool overrideDuration,
        address _winner
    ) public onlyOwner {
        require(
            raffleById[_raffleId] < block.timestamp || overrideDuration,
            "Raffle is Active"
        );

        Participant storage participant = raffleParticipants[_raffleId][
            msg.sender
        ];

        raffleById[_raffleId] = block.timestamp;
        endById[_raffleId] = true;
        ticketWinner[_raffleId] = _winner;
        isActiveRaffle[_raffleId] = false;
        if (participant.enteredWithTicket > 0) {
            _burn(address(this), RAFFLE_TICKET, 1);
        }
    }

    function claimLostTickets(bytes32 _raffleId) public {
        require(endById[_raffleId], "Raffle not concluded");
        uint256 quantity = ticketsEntered[_raffleId][msg.sender];
        require(quantity > 0, "No tickets to claim");
        if (ticketWinner[_raffleId] == msg.sender) {
            quantity--;
        }
        ticketsEntered[_raffleId][msg.sender] = 0;
        if (quantity == 0) {
            return;
        }
        safeTransferFrom(
            address(this),
            msg.sender,
            RAFFLE_TICKET,
            quantity,
            ""
        );
        emit TicketClaimed(msg.sender, _raffleId, quantity);
    }

    function totalSupply(uint256 id) public view returns (uint256) {
        return _totalSupply[id];
    }

    function getUserTicketEntries(
        bytes32 _raffleId,
        address user
    ) public view returns (Participant memory) {
        Participant memory participant = raffleParticipants[_raffleId][user];
        return participant;
    }

    function getActiveRaffles() public view returns (Raffle[] memory) {
        uint256 count = 0;
        for (uint256 i = 0; i < allRaffles.length; i++) {
            if (isActiveRaffle[allRaffles[i]]) {
                count++;
            }
        }

        Raffle[] memory activeRaffles = new Raffle[](count);
        uint256 index = 0;
        for (uint256 i = 0; i < allRaffles.length; i++) {
            if (isActiveRaffle[allRaffles[i]]) {
                activeRaffles[index] = raffles[allRaffles[i]];
                index++;
            }
        }

        return activeRaffles;
    }

    /**
     * @dev Withdraws ETH from the contract.
     * @param amount The amount of ETH to withdraw.
     * @param to The address to send ETH to.
     */
    function withdrawETH(
        uint256 amount,
        address payable to
    ) external onlyOwner {
        require(amount <= address(this).balance, "Insufficient balance");
        (bool sent, ) = to.call{value: amount}("");
        require(sent, "Failed to send Ether");
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(
        bytes4 interfaceId
    ) public view override(ERC1155, ERC1155Holder) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function setTokenURI(string calldata uri_) external onlyOwner {
        _setURI(uri_);
    }
}
