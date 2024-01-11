// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM`MMM NMM MMM MMM MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMM  MMMMhMMMMMMM  MMMMMMMM MMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMM  MM-MMMMM   MMMM    MMMM   lMMMDMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMM jMMMMl   MM    MMM  M  MMM   M   MMMM MMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMM MMMMMMMMM  , `     M   Y   MM  MMM  BMMMMMM MMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMM MMMMMMMMMMMM  IM  MM  l  MMM  X   MM.  MMMMMMMMMM MMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMM.nlMMMMMMMMMMMMMMMMM]._  MMMMMMMMMMMMMMMNMMMMMMMMMMMMMM
// MMMMMMMMMMMMMM TMMMMMMMMMMMMMMMMMM          +MMMMMMMMMMMM:  rMMMMMMMMN MMMMMMMMMMMMMM
// MMMMMMMMMMMM MMMMMMMMMMMMMMMM                  MMMMMM           MMMMMMMM qMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMM^                   MMMb              .MMMMMMMMMMMMMMMMMMM
// MMMMMMMMMM MMMMMMMMMMMMMMM                     MM                  MMMMMMM MMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMM                     M                   gMMMMMMMMMMMMMMMMM
// MMMMMMMMu MMMMMMMMMMMMMMM                                           MMMMMMM .MMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMM                                           :MMMMMMMMMMMMMMMM
// MMMMMMM^ MMMMMMMMMMMMMMMl                                            MMMMMMMM MMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMM                                             MMMMMMMMMMMMMMMM
// MMMMMMM MMMMMMMMMMMMMMMM                                             MMMMMMMM MMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMM                                             MMMMMMMMMMMMMMMM
// MMMMMMr MMMMMMMMMMMMMMMM                                             MMMMMMMM .MMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMM                                           MMMMMMMMMMMMMMMMM
// MMMMMMM MMMMMMMMMMMMMMMMM                                         DMMMMMMMMMM MMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMM                              MMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMM|`MMMMMMMMMMMMMMMM         q                      MMMMMMMMMMMMMMMMMMM  MMMMMMM
// MMMMMMMMMTMMMMMMMMMMMMMMM                               qMMMMMMMMMMMMMMMMMMgMMMMMMMMM
// MMMMMMMMq MMMMMMMMMMMMMMMh                             jMMMMMMMMMMMMMMMMMMM nMMMMMMMM
// MMMMMMMMMM MMMMMMMMMMMMMMMQ      nc    -MMMMMn        MMMMMMMMMMMMMMMMMMMM MMMMMMMMMM
// MMMMMMMMMM.MMMMMMMMMMMMMMMMMMl            M1       `MMMMMMMMMMMMMMMMMMMMMMrMMMMMMMMMM
// MMMMMMMMMMMM MMMMMMMMMMMMMMMMMMMM               :MMMMMMMMMM MMMMMMMMMMMM qMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMM  MMMMMMX       MMMMMMMMMMMMMMM  uMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMM DMMMMMMMMM   IMMMMMMMMMMMMMMMMMMMMMMM   M   Y  MMMMMMMN MMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMM MMMMMM    ``    M      MM  MMM   , MMMM    Mv  MMM MMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMM MMh  Ml  .   M  MMMM  I  MMMT  M     :M   ,MMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMM MMMMMMMMt  MM  MMMMB m  ]MMM  MMMM   MMMMMM MMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMM MMMMM  MMM   TM   MM  9U  .MM  _MMMMM MMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMM YMMMMMMMn     MMMM    +MMMMMMM1`MMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMM MMMMMMMMMMMMMMMMMMMMMMM MMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM.`MMM MMM MMMMM`.MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM author: phaze MMM

import "./Strings.sol";
import "./IERC721.sol";
import "./IERC721Metadata.sol";

import "./interfaces.sol";
import "./Ownable.sol";
import "./Choice.sol";

import "./SoulboundTickets.sol";

error RaffleNotActive();
error RaffleOngoing();
error RaffleRandomSeedSet();
error RaffleAlreadyCancelled();
error TicketsMaxSupplyReached();

error RaffleUnrevealed();
error PrizeAlreadyClaimed();

error BetterLuckNextTime();
error MachineBeDoinWork();
error NeedsMoarTickets();
error TicketsImplementationUnset();
error InvalidTimestamps();
error InvalidTicketPrice();
error RequirementNotFulfilled();

error ContractCallNotAllowed();

contract Gachapon is Ownable {
    using Strings for uint256;

    event Chachingg();
    event GrappleGrapple();
    event BZZzzt();

    struct Raffle {
        uint40 start;
        uint40 end;
        uint40 ticketSupply;
        uint40 maxTicketSupply;
        uint40 ticketPrice; // in multiples of 1e18
        uint8 requirement;
        uint16 refundRate;
        bool cancelled;
        address tickets;
        uint40 randomSeed;
        address prizeNFT;
        uint32[] prizeTokenIds;
    }

    string ticketURI = "ipfs://QmSwrzsySKnkQmRQoZYmZ2XuJx3NMn2awdHwf1fezAJbq3/silver-ticket.json";
    string losingTicketURI = "ipfs://QmSwrzsySKnkQmRQoZYmZ2XuJx3NMn2awdHwf1fezAJbq3/red-ticket.json";
    string winningTicketURI = "ipfs://QmSwrzsySKnkQmRQoZYmZ2XuJx3NMn2awdHwf1fezAJbq3/gold-ticket.json";

    address ticketsImplementation;

    uint256 public numRaffles;
    mapping(uint256 => Raffle) private raffles;
    mapping(address => uint256) public ticketsToRaffleId;
    mapping(uint256 => uint256) requestIdToLot;

    mapping(uint256 => mapping(uint256 => bool)) public claimedPrize;

    uint256 constant ONE_MONTH = 3600 * 24 * 28;

    IGouda constant gouda = IGouda(0x3aD30C5E3496BE07968579169a96f00D56De4C1A);
    IMadMouse constant genesis = IMadMouse(0x3aD30c5e2985e960E89F4a28eFc91BA73e104b77);
    IMadMouse constant troupe = IMadMouse(0x74d9d90a7fc261FBe92eD47B606b6E0E00d75E70);

    /* ------------- External ------------- */

    function buyTicket(uint256 raffleId, uint256 requirementData) external noContract {
        Raffle storage raffle = raffles[raffleId];
        uint256 ticketSupply = raffle.ticketSupply;

        if (raffle.cancelled || raffle.end < block.timestamp || block.timestamp < raffle.start)
            revert RaffleNotActive();
        if (ticketSupply == raffle.maxTicketSupply) revert TicketsMaxSupplyReached();

        uint256 requirement = raffle.requirement;
        if (requirement != 0 && !fulfillsRequirement(msg.sender, requirement, requirementData))
            revert RequirementNotFulfilled();

        unchecked {
            gouda.burnFrom(msg.sender, raffle.ticketPrice * 1e18);
        }

        uint256 ticketId = ++ticketSupply;
        raffle.ticketSupply = uint40(ticketSupply);

        Tickets(raffle.tickets).mint(msg.sender, ticketId);
    }

    function claimPrize(uint256 raffleId, uint256 ticketId) external noContract {
        Raffle storage raffle = raffles[raffleId];
        Tickets tickets = Tickets(raffle.tickets);

        uint256 randomSeed = raffle.randomSeed;

        if (raffle.cancelled) revert RaffleNotActive();
        if (randomSeed == 0) revert RaffleUnrevealed();

        uint256 numPrizes = raffle.prizeTokenIds.length;
        uint256 numEntrants = raffle.ticketSupply;

        // ticketId starts at 1
        (bool win, uint256 prizeId) = Choice.indexOfSelectNOfM(ticketId - 1, numPrizes, numEntrants, randomSeed);

        if (tickets.ownerOf(ticketId) != msg.sender || !win) revert BetterLuckNextTime();
        if (claimedPrize[raffleId][ticketId]) revert PrizeAlreadyClaimed();

        claimedPrize[raffleId][ticketId] = true;

        IERC721 prizeNFT = IERC721(raffle.prizeNFT);
        prizeNFT.transferFrom(address(this), msg.sender, raffle.prizeTokenIds[prizeId]);
    }

    function burnTickets(uint256[] calldata burnRaffleIds, uint256[] calldata burnTicketIds) external noContract {
        Raffle storage raffle;

        uint256 refund;
        uint256 refundRate;

        uint256 numBurnTickets = burnTicketIds.length;
        if (numBurnTickets == 0) revert NeedsMoarTickets();

        unchecked {
            for (uint256 i; i < numBurnTickets; ++i) {
                raffle = raffles[burnRaffleIds[i]];
                Tickets tickets = Tickets(raffle.tickets);

                tickets.burnFrom(msg.sender, burnTicketIds[i]);

                refundRate = raffle.refundRate;
                if (refundRate > 0) refund += (raffle.ticketPrice * 1e18 * refundRate) >> 16;
            }
        }

        gouda.mint(msg.sender, refund);
    }

    /* ------------- View ------------- */

    function isWinningTicket(uint256 raffleId, uint256 ticketId) public view returns (bool win) {
        Raffle storage raffle = raffles[raffleId];
        uint256 randomSeed = raffle.randomSeed;

        if (raffle.cancelled || randomSeed == 0) return false;

        uint256 numPrizes = raffle.prizeTokenIds.length;
        uint256 numEntrants = raffle.ticketSupply;

        unchecked {
            (win, ) = Choice.indexOfSelectNOfM(ticketId - 1, numPrizes, numEntrants, randomSeed);
        }
        return win;
    }

    function getWinningTickets(uint256 raffleId) public view returns (uint256[] memory ticketIds) {
        Raffle storage raffle = raffles[raffleId];

        uint256 randomSeed = raffle.randomSeed;

        if (raffle.cancelled || randomSeed == 0) return ticketIds;

        uint256 numPrizes = raffle.prizeTokenIds.length;
        uint256 numEntrants = raffle.ticketSupply;

        return Choice.selectNOfM(numPrizes, numEntrants, randomSeed, 1);
    }

    function getWinners(uint256 raffleId) public view returns (address[] memory winners) {
        Tickets tickets = Tickets(raffles[raffleId].tickets);

        uint256[] memory prizeTokenIds = getWinningTickets(raffleId);
        uint256 numIds = prizeTokenIds.length;

        winners = new address[](numIds);
        for (uint256 i; i < numIds; ++i) winners[i] = tickets.ownerOf(prizeTokenIds[i]);
    }

    function getRaffle(uint256 raffleId) external view returns (Raffle memory) {
        return raffles[raffleId];
    }

    function fulfillsRequirement(
        address user,
        uint256 requirement,
        uint256 data
    ) public returns (bool) {
        unchecked {
            if (requirement == 1 && genesis.numOwned(user) > 0) return true;
            else if (requirement == 2 && troupe.numOwned(user) > 0) return true;
            else if (
                requirement == 3 &&
                // specify data == 1 to direct that user is holding troupe and potentially save an sload;
                // or leave unspecified and worst-case check both
                ((data != 2 && troupe.numOwned(user) > 0) || (data != 1 && genesis.numOwned(user) > 0))
            ) return true;
            else if (
                requirement == 4 &&
                (
                    data > 5000 // specify owner-held id: data > 5000 refers to genesis collection
                        ? genesis.getLevel(data - 5000) > 1 && genesis.ownerOf(data - 5000) == user
                        : troupe.getLevel(data) > 1 && troupe.ownerOf(data) == user
                )
            ) return true;
            else if (
                requirement == 5 &&
                (
                    data > 5000
                        ? genesis.getLevel(data - 5000) > 2 && genesis.ownerOf(data - 5000) == user
                        : troupe.getLevel(data) > 2 && troupe.ownerOf(data) == user
                )
            ) return true;
            return false;
        }
    }

    /* ------------- Tickets Callbacks ------------- */

    function ticketsSupply() external view returns (uint256) {
        uint256 raffleId = ticketsToRaffleId[msg.sender];
        return raffles[raffleId].ticketSupply;
    }

    function ticketsName() external view returns (string memory) {
        uint256 raffleId = ticketsToRaffleId[msg.sender];
        string memory prizeNFTName = IERC721Metadata(raffles[raffleId].prizeNFT).name();
        return string.concat("Gouda Slot Machine Raffle #", raffleId.toString(), ": ", prizeNFTName);
    }

    function ticketsSymbol() external view returns (string memory) {
        uint256 raffleId = ticketsToRaffleId[msg.sender];
        return string.concat("GRAFF", raffleId.toString());
    }

    function ticketsTokenURI(uint256 id) external view returns (string memory) {
        uint256 raffleId = ticketsToRaffleId[msg.sender];
        return
            raffles[raffleId].randomSeed != 0
                ? isWinningTicket(raffleId, id) ? winningTicketURI : losingTicketURI
                : ticketURI;
    }

    /* ------------- Owner ------------- */

    function feedToys(
        address prizeNFT,
        uint32[] calldata prizeTokenIds,
        uint40 start,
        uint40 end,
        uint40 ticketPrice,
        uint16 refundRate,
        uint40 maxTicketSupply,
        uint8 requirement
    ) external onlyOwner {
        unchecked {
            for (uint256 i; i < prizeTokenIds.length; ++i)
                IERC721(prizeNFT).transferFrom(msg.sender, address(this), prizeTokenIds[i]);

            uint256 raffleId = ++numRaffles;
            Raffle storage raffle = raffles[raffleId];

            if (ticketsImplementation == address(0)) revert TicketsImplementationUnset();
            if (start < block.timestamp || end <= start || end - start > ONE_MONTH) revert InvalidTimestamps();
            if (ticketPrice >= 1e18) revert InvalidTicketPrice();

            address tickets = createTicketsClone(ticketsImplementation);
            ticketsToRaffleId[tickets] = raffleId;

            raffle.tickets = tickets;
            raffle.prizeNFT = prizeNFT;
            raffle.prizeTokenIds = prizeTokenIds;
            raffle.start = start;
            raffle.end = end;
            raffle.ticketPrice = ticketPrice;
            raffle.refundRate = refundRate;
            raffle.maxTicketSupply = maxTicketSupply;
            raffle.requirement = requirement;

            emit Chachingg();
        }
    }

    function rescueToys(IERC721 toy, uint256[] calldata toyIds) external onlyOwner {
        unchecked {
            for (uint256 i; i < toyIds.length; ++i) toy.transferFrom(address(this), msg.sender, toyIds[i]);
        }
    }

    function cancelRaffle(uint256 raffleId) external onlyOwner {
        unchecked {
            Raffle storage raffle = raffles[raffleId];

            uint256 numToys = raffle.prizeTokenIds.length;

            if (raffle.cancelled) revert RaffleAlreadyCancelled();

            IERC721 prizeNFT = IERC721(raffle.prizeNFT);
            for (uint256 i; i < numToys; ++i) {
                try prizeNFT.transferFrom(address(this), msg.sender, raffles[raffleId].prizeTokenIds[i]) {} catch {}
            }

            raffle.cancelled = true;
        }
    }

    function initiateGrappler(uint256 raffleId) external onlyOwner {
        Raffle storage raffle = raffles[raffleId];

        if (raffle.cancelled) revert RaffleNotActive();
        if (block.timestamp < raffle.end) revert RaffleOngoing();
        if (raffle.randomSeed != 0) revert MachineBeDoinWork();

        emit GrappleGrapple();
        emit BZZzzt();

        raffle.randomSeed = uint40(uint256(blockhash(block.number - 1)));
    }

    function setTicketsImplementation(address ticketsImplementation_) external onlyOwner {
        ticketsImplementation = ticketsImplementation_;
    }

    function setTicketURIs(
        string calldata ticketURI_,
        string calldata losingTicketURI_,
        string calldata winningTicketURI_
    ) external onlyOwner {
        ticketURI = ticketURI_;
        losingTicketURI = losingTicketURI_;
        winningTicketURI = winningTicketURI_;
    }

    /* ------------- Private ------------- */

    // https://github.com/optionality/clone-factory/blob/master/contracts/CloneFactory.sol
    function createTicketsClone(address target) private returns (address result) {
        bytes20 targetBytes = bytes20(target);
        assembly {
            let clone := mload(0x40)
            mstore(clone, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(clone, 0x14), targetBytes)
            mstore(add(clone, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            result := create(0, clone, 0x37)
        }
    }

    /* ------------- Modifier ------------- */

    modifier noContract() {
        if (msg.sender != tx.origin) revert ContractCallNotAllowed();
        _;
    }
}
