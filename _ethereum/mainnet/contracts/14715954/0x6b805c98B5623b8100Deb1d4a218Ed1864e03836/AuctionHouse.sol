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

import "./Ownable.sol";
import "./interfaces.sol";
import "./interfaces.sol";

import "./IERC721.sol";
import "./IERC20.sol";

error AuctionOngoing();
error AuctionInactive();
error AuctionCancelled();

error ContractCallNotAllowed();

error InvalidTimestamp();
error BidTooLow();
error NoBidPlaced();
error CannotWithdrawWinningBid();
error IncorrectWinner();
error RequirementNotFulfilled();
error InvalidAuctionId();

error QualifierMaxEntrantsReached();
error QualifierInactive();
error QualifierSeedNotSet();
error QualifierNotEntered();
error QualifierAlreadyEntered();
error QualifierNotRequired();
error QualifierRevealInvalidTimeFrame();
error QualifierRandomSeedSet();

contract AuctionHouse is Ownable {
    event BidPlaced(uint256 indexed auctionId, address sender, uint256 price);

    struct Auction {
        uint16 qualifierNumEntrants;
        uint16 qualifierMaxEntrants;
        uint40 qualifierDuration;
        uint16 qualifierChance;
        uint16 qualifierRandomSeed;
        uint8 requirement;
        uint40 start;
        uint40 duration;
        uint40 currentBid; // in multiples of 1e18
        bool cancelled;
        address prizeNFT;
        uint40 prizeTokenId;
    }

    uint256 public numAuctions;
    mapping(uint256 => Auction) public auctions;
    mapping(uint256 => mapping(address => uint256)) public bids;

    uint256 constant ONE_MONTH = 3600 * 24 * 7 * 4;
    uint256 constant AUCTION_EXTEND_DURATION = 5 * 60;

    IGouda constant gouda = IGouda(0x3aD30C5E3496BE07968579169a96f00D56De4C1A);
    IMadMouse constant genesis = IMadMouse(0x3aD30c5e2985e960E89F4a28eFc91BA73e104b77);
    IMadMouse constant troupe = IMadMouse(0x74d9d90a7fc261FBe92eD47B606b6E0E00d75E70);

    /* ------------- External ------------- */

    function placeBid(
        uint256 auctionId,
        uint40 bid,
        uint256 requirementData
    ) external onlyEOA {
        Auction storage auction = auctions[auctionId];

        if (bid <= auction.currentBid) revert BidTooLow();

        uint256 qualifierDuration = auction.qualifierDuration;

        unchecked {
            uint256 start = uint256(auction.start) + auction.qualifierDuration;
            uint256 duration = auction.duration;

            if (duration < block.timestamp - start) revert AuctionInactive();

            uint256 end = start + duration;
            if (end - block.timestamp < AUCTION_EXTEND_DURATION) {
                auction.duration = uint40(duration + AUCTION_EXTEND_DURATION);
            }
        }

        if (auction.cancelled) revert AuctionCancelled();

        uint256 callerBid = bids[auctionId][msg.sender];

        // if callerBid is > qualifierDownpayment,
        // we don't have to re-evaluate qualifications,
        // since this check has already been performed
        if (callerBid <= 1) {
            uint256 requirement = auction.requirement;
            if (requirement != 0 && !fulfillsRequirement(msg.sender, requirement, requirementData))
                revert RequirementNotFulfilled();

            if (qualifierDuration != 0) {
                uint256 qualifierRandomSeed = auction.qualifierRandomSeed;
                if (qualifierRandomSeed == 0) revert QualifierSeedNotSet();
                if (callerBid == 0) revert QualifierNotEntered(); // non-zero for valid entry because of downpayment when entering qualifier
                uint256 roll = uint256(keccak256(abi.encodePacked(msg.sender, qualifierRandomSeed)));
                if (roll & 0xFFFF > auction.qualifierChance) revert QualifierNotEntered();
            }
        }

        unchecked {
            // type(uint40).max * 1e18 < 2^256: can't overflow
            // underflow assumption: callerBid <= auction.currentBid < bid
            gouda.burnFrom(msg.sender, (uint256(bid) - callerBid) * 1e18);
            emit BidPlaced(auctionId, msg.sender, uint256(bid) * 1e18);
        }

        bids[auctionId][msg.sender] = bid;
        auction.currentBid = bid;
    }

    function fulfillsRequirement(
        address user,
        uint256 requirement,
        uint256 data
    ) public view returns (bool) {
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

    function claimPrize(uint256 auctionId) external onlyEOA {
        resolveBid(auctionId);
    }

    function reclaimGouda(uint256 auctionId) external onlyEOA {
        resolveBid(auctionId);
    }

    function enterQualifier(uint256 auctionId, uint256 requirementData) external onlyEOA {
        Auction storage auction = auctions[auctionId];
        unchecked {
            if (++auction.qualifierNumEntrants > auction.qualifierMaxEntrants) revert QualifierMaxEntrantsReached();
            if (auction.qualifierDuration < block.timestamp - auction.start) revert QualifierInactive();
        }

        uint256 requirement = auction.requirement;
        if (requirement != 0 && !fulfillsRequirement(msg.sender, requirement, requirementData))
            revert RequirementNotFulfilled();

        if (bids[auctionId][msg.sender] >= 1) revert QualifierAlreadyEntered();

        gouda.burnFrom(msg.sender, 1e18);
        bids[auctionId][msg.sender] = 1;
    }

    /* ------------- View ------------- */

    function qualifierChosen(uint256 auctionId, address user) external view returns (bool) {
        Auction storage auction = auctions[auctionId];

        if (auction.duration == 0) return false; // no qualifier required

        uint256 callerBid = bids[auctionId][user];
        if (callerBid == 0) return false; // downpayment signals successful qualifier entry

        uint256 qualifierRandomSeed = auction.qualifierRandomSeed;
        if (qualifierRandomSeed == 0) return false;

        uint256 roll = uint256(keccak256(abi.encodePacked(user, qualifierRandomSeed)));
        if (roll & 0xFFFF > auction.qualifierChance) return false;

        return true;
    }

    /* ------------- Private ------------- */

    function resolveBid(uint256 auctionId) private {
        unchecked {
            Auction storage auction = auctions[auctionId];
            uint256 qualifierDuration = auction.qualifierDuration;
            uint256 end = auction.start + qualifierDuration + auction.duration;

            bool cancelled = auction.cancelled;

            if (block.timestamp <= end && !cancelled) revert AuctionOngoing();

            uint256 callerBid = bids[auctionId][msg.sender];
            delete bids[auctionId][msg.sender];

            if (callerBid == 0) revert NoBidPlaced();

            if (auction.currentBid == callerBid && !cancelled) {
                IERC721(auction.prizeNFT).transferFrom(owner(), msg.sender, auction.prizeTokenId);
            } else {
                // callerBid >= 1
                if (qualifierDuration != 0) callerBid -= 1; // keep the qualifier downpayment
                if (callerBid == 0) revert NoBidPlaced();
                gouda.mint(msg.sender, callerBid * 1e18);
            }
        }
    }

    /* ------------- Owner ------------- */

    function createAuction(
        address nft,
        uint40 tokenId,
        uint16 qualifierMaxEntrants,
        uint40 qualifierDuration,
        uint16 qualifierChance,
        uint8 requirement,
        uint40 start,
        uint40 duration
    ) external onlyOwner {
        uint256 auctionId;
        unchecked {
            auctionId = ++numAuctions;

            if (ONE_MONTH < start - block.timestamp || duration > ONE_MONTH || qualifierDuration > ONE_MONTH)
                revert InvalidTimestamp();
        }

        // IERC721(nft).transferFrom(msg.sender, address(this), tokenId);

        Auction storage auction = auctions[auctionId];

        auction.qualifierMaxEntrants = qualifierMaxEntrants;
        auction.qualifierDuration = qualifierDuration;
        auction.qualifierChance = qualifierChance;

        auction.requirement = requirement;
        auction.start = start;
        auction.duration = duration;

        auction.prizeNFT = nft;
        auction.prizeTokenId = tokenId;
    }

    function editAuction(
        uint256 auctionId,
        address nft,
        uint40 tokenId,
        uint16 qualifierMaxEntrants,
        uint40 qualifierDuration,
        uint16 qualifierChance,
        uint8 requirement,
        uint40 start,
        uint40 duration,
        bool cancelled
    ) external onlyOwner {
        unchecked {
            if (block.timestamp + ONE_MONTH < start || duration > ONE_MONTH || qualifierDuration > ONE_MONTH)
                revert InvalidTimestamp();
        }
        if (auctionId > numAuctions) revert InvalidAuctionId();

        Auction storage auction = auctions[auctionId];

        auction.qualifierMaxEntrants = qualifierMaxEntrants;
        auction.qualifierDuration = qualifierDuration;
        auction.qualifierChance = qualifierChance;

        auction.requirement = requirement;
        auction.start = start;
        auction.duration = duration;

        auction.prizeNFT = nft;
        auction.prizeTokenId = tokenId;

        auction.cancelled = cancelled;
    }

    function revealQualifier(uint256 auctionId) external onlyOwner {
        Auction storage auction = auctions[auctionId];

        uint256 qualifierDuration = auction.qualifierDuration;
        if (qualifierDuration == 0) revert QualifierNotRequired();

        unchecked {
            if (block.timestamp < auction.start + qualifierDuration) revert QualifierRevealInvalidTimeFrame();
            if (auction.qualifierRandomSeed != 0) revert QualifierRandomSeedSet();

            auction.qualifierRandomSeed = uint16(uint256(blockhash(block.number - 1)));
        }
    }

    function rescueToys(IERC721 toy, uint256[] calldata toyIds) external onlyOwner {
        unchecked {
            for (uint256 i; i < toyIds.length; ++i) toy.transferFrom(address(this), msg.sender, toyIds[i]);
        }
    }

    function rescueERC20(IERC20 token) external onlyOwner {
        token.transfer(msg.sender, token.balanceOf(address(this)));
    }

    /* ------------- Modifier ------------- */

    modifier onlyEOA() {
        if (msg.sender != tx.origin) revert ContractCallNotAllowed();
        _;
    }
}
