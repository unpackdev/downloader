// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

/**

   ◊◊◊◊◊◊◊◊◊◊ ◊◊◊◊ ◊◊◊◊  ◊◊◊◊◊◊◊◊◊       ◊◊◊◊◊◊◊    ◊◊◊◊◊◊◊   ◊◊◊◊◊◊◊◊    ◊◊◊◊◊◊◊◊    ◊◊◊◊◊◊◊◊◊  ◊◊◊◊  ◊◊◊◊
   ◊◊◊◊◊◊◊◊◊◊ ◊◊◊◊ ◊◊◊◊  ◊◊◊◊◊◊◊◊◊      ◊◊◊◊◊◊◊◊◊  ◊◊◊◊◊◊◊◊◊  ◊◊◊◊◊◊◊◊◊   ◊◊◊◊◊◊◊◊◊   ◊◊◊◊◊◊◊◊◊  ◊◊◊◊  ◊◊◊◊
      ◊◊◊◊    ◊◊◊◊ ◊◊◊◊  ◊◊◊◊          ◊◊◊◊  ◊◊◊◊  ◊◊◊◊◊◊◊◊◊  ◊◊◊◊  ◊◊◊◊  ◊◊◊◊  ◊◊◊◊  ◊◊◊◊       ◊◊◊◊  ◊◊◊◊
      ◊◊◊◊    ◊◊◊◊ ◊◊◊◊  ◊◊◊◊          ◊◊◊◊  ◊◊◊◊  ◊◊◊◊◊◊◊◊◊  ◊◊◊◊  ◊◊◊◊  ◊◊◊◊  ◊◊◊◊  ◊◊◊◊       ◊◊◊◊  ◊◊◊◊
      ◊◊◊◊    ◊◊◊◊ ◊◊◊◊  ◊◊◊◊          ◊◊◊◊  ◊◊◊◊  ◊◊◊◊ ◊◊◊◊  ◊◊◊◊  ◊◊◊◊  ◊◊◊◊  ◊◊◊◊  ◊◊◊◊       ◊◊◊◊◊ ◊◊◊◊
      ◊◊◊◊    ◊◊◊◊◊◊◊◊◊  ◊◊◊◊◊◊◊       ◊◊◊◊        ◊◊◊◊ ◊◊◊◊  ◊◊◊◊ ◊◊◊◊   ◊◊◊◊  ◊◊◊◊  ◊◊◊◊◊◊◊    ◊◊◊◊◊◊◊◊◊◊
      ◊◊◊◊    ◊◊◊◊◊◊◊◊◊  ◊◊◊◊◊◊◊       ◊◊◊◊ ◊◊◊◊◊  ◊◊◊◊◊◊◊◊◊  ◊◊◊◊◊◊◊◊◊   ◊◊◊◊  ◊◊◊◊  ◊◊◊◊◊◊◊    ◊◊◊◊◊◊◊◊◊◊
      ◊◊◊◊    ◊◊◊◊ ◊◊◊◊  ◊◊◊◊          ◊◊◊◊ ◊◊◊◊◊  ◊◊◊◊◊◊◊◊◊  ◊◊◊◊◊◊◊◊◊◊  ◊◊◊◊  ◊◊◊◊  ◊◊◊◊       ◊◊◊◊ ◊◊◊◊◊
      ◊◊◊◊    ◊◊◊◊ ◊◊◊◊  ◊◊◊◊          ◊◊◊◊  ◊◊◊◊  ◊◊◊◊ ◊◊◊◊  ◊◊◊◊  ◊◊◊◊  ◊◊◊◊  ◊◊◊◊  ◊◊◊◊       ◊◊◊◊  ◊◊◊◊
      ◊◊◊◊    ◊◊◊◊ ◊◊◊◊  ◊◊◊◊          ◊◊◊◊  ◊◊◊◊  ◊◊◊◊ ◊◊◊◊  ◊◊◊◊  ◊◊◊◊  ◊◊◊◊  ◊◊◊◊  ◊◊◊◊       ◊◊◊◊  ◊◊◊◊
      ◊◊◊◊    ◊◊◊◊ ◊◊◊◊  ◊◊◊◊◊◊◊◊◊      ◊◊◊◊◊◊◊◊◊  ◊◊◊◊ ◊◊◊◊  ◊◊◊◊  ◊◊◊◊  ◊◊◊◊◊◊◊◊◊   ◊◊◊◊◊◊◊◊◊  ◊◊◊◊  ◊◊◊◊
      ◊◊◊◊    ◊◊◊◊ ◊◊◊◊  ◊◊◊◊◊◊◊◊◊       ◊◊◊◊◊◊◊   ◊◊◊◊ ◊◊◊◊  ◊◊◊◊  ◊◊◊◊  ◊◊◊◊◊◊◊◊    ◊◊◊◊◊◊◊◊◊  ◊◊◊◊  ◊◊◊◊

 */

import "./Auth.sol";
import "./Auction.sol";
import "./FountCardCheck.sol";
import "./Withdraw.sol";
import "./ReentrancyGuard.sol";
import "./IOperatorCollectable.sol";

/**
 * @author Fount Gallery
 * @title  Arrangement One - The Garden
 * @notice The first arrangement of sale for The Garden NFT project.
 *
 *         It's a classic English auction. Each piece will be listed in this auction
 *         contract. Upon listing, the NFT will be transferred to this contract for the
 *         duration of the auction. Once a bid meeting the reserve price is placed,
 *         the auction will start.
 *
 *         Each bid must be at least 10% higher than the previous bid to be accepted. If
 *         the new bid is accepted, the previous bid will be refunded.
 *
 *         The auction will last for 24 hours, and will be extended if bids are placed
 *         within 5 minutes of the auction ending.
 *
 *         Once the auction has ended, it can then be settled. This will transfer the
 *         NFT to the highest bidder, and the proceeds will be available to withdraw.
 *
 */
contract ArrangementOne is Auction, FountCardCheck, Withdraw, Auth, ReentrancyGuard {
    /* ------------------------------------------------------------------------
       S T O R A G E / C O N F I G
    ------------------------------------------------------------------------ */

    uint256 public constant ARRANGEMENT_MAX_ID = 33;
    uint256 public constant AUCTION_RESERVE_PRICE = 0.15 ether;
    uint32 public constant AUCTION_DURATION = 24 hours;
    uint32 public constant AUCTION_TIME_BUFFER = 5 minutes;
    uint32 public constant AUCTION_INCREMENT_PERCENTAGE = 10;

    /* ------------------------------------------------------------------------
       E R R O R S
    ------------------------------------------------------------------------ */

    error TokenNotInArrangementOne();
    error InvalidRange();
    error CannotWithdrawWithActiveAuctions();

    /* ------------------------------------------------------------------------
       M O D I F I E R S
    ------------------------------------------------------------------------ */

    /**
     * @dev Checks that a token id is within the bounds of the first arrangement
     */
    modifier onlyForTokenInArrangement(uint256 id) {
        if (id == 0 || id > ARRANGEMENT_MAX_ID) revert TokenNotInArrangementOne();
        _;
    }

    /* ------------------------------------------------------------------------
       I N I T
    ------------------------------------------------------------------------ */

    /**
     * @param owner_ The owner of the contract
     * @param admin_ The admin of the contract
     * @param nft_ The address of the NFT contract to transfer tokens from
     * @param fountCard_ The address of the Fount Gallery Patron Card NFT
     */
    constructor(
        address owner_,
        address admin_,
        address nft_,
        address fountCard_
    )
        Auction(
            nft_,
            AuctionConfig(
                AUCTION_RESERVE_PRICE,
                AUCTION_DURATION,
                AUCTION_TIME_BUFFER,
                AUCTION_INCREMENT_PERCENTAGE
            )
        )
        FountCardCheck(fountCard_)
        Auth(owner_, admin_)
    {}

    /* ------------------------------------------------------------------------
       A U C T I O N   S E T U P
    ------------------------------------------------------------------------ */

    /**
     * @notice Creates an auction for a given token id
     * @dev Stores the token in this contract as escrow so it can be transferred to the winner,
     * and also prevents it being sold to someone else while an active auction is ongoing.
     *
     * Reverts if:
     *   - The auction already exists.
     *   - The caller is not the contract owner.
     *
     * @param id The token id to create the auction for
     * @param startTime The unix timestamp of when the auction should start allowing bids
     */
    function createAuction(uint256 id, uint256 startTime)
        public
        onlyForTokenInArrangement(id)
        onlyOwnerOrAdmin
    {
        _createAuction(id, startTime);
    }

    /**
     * @notice Creates an auction for each token id in the range
     * @param startId The token id at the start of the range
     * @param endId The token id at the end of the range
     * @param startTime The unix timestamp of when the auction should start allowing bids
     */
    function createAuctions(
        uint256 startId,
        uint256 endId,
        uint256 startTime
    ) public onlyOwnerOrAdmin {
        if (startId > endId) revert InvalidRange();
        if (
            startId == 0 || startId > ARRANGEMENT_MAX_ID || endId == 0 || endId > ARRANGEMENT_MAX_ID
        ) {
            revert TokenNotInArrangementOne();
        }
        for (uint256 id = startId; id <= endId; id++) {
            _createAuction(id, startTime);
        }
    }

    /**
     * @notice Cancels a given auction. Can only be cancelled when there are no bids.
     * @dev Transfers the token back to the original owner so a subsequent auction can be created.
     *
     * Reverts if:
     *   - The auction has already started.
     *   - The caller is not the contract owner
     *
     * @param id The token id used to create the auction
     */
    function cancelAuction(uint256 id) public onlyForTokenInArrangement(id) onlyOwnerOrAdmin {
        _cancelAuction(id);
    }

    /* ------------------------------------------------------------------------
       B I D S
    ------------------------------------------------------------------------ */

    /**
     * @notice Place a bid for a specific token id as a Fount Card Holder
     * @param id The token id to place a bid on (same as auction id)
     */
    function placeBid(uint256 id)
        public
        payable
        onlyForTokenInArrangement(id)
        onlyWhenFountCardHolder
        nonReentrant
    {
        _placeBid(id);
    }

    /* ------------------------------------------------------------------------
       S E T T L E M E N T
    ------------------------------------------------------------------------ */

    /**
     * @notice Allows anyone to settle the auction, which sends the winner the NFT
     * @dev Transfers the NFT to the highest bidder (winner) only once the auction is over.
     * Can be called by anyone so the artist, or the team can pay the gas if needed.
     *
     * Reverts if:
     *   - The auction hasn't started yet
     *   - The auction is not over
     *
     * @param id The token id of the auction to settle
     */
    function settleAuction(uint256 id) public onlyForTokenInArrangement(id) nonReentrant {
        // Settle the auction and transfer the token to the highest bidder
        _settleAuction(id);

        // Mark the token as collected since `_settleAuction` handles the transfer
        IOperatorCollectable(address(nft)).markAsCollected(id);
    }

    /* ------------------------------------------------------------------------
       W I T H D R A W
    ------------------------------------------------------------------------ */

    /**
     * @notice Admin function to withdraw ETH from this contract
     * @dev Withdraws to the `to` address. Reverts if there are active auctions.
     * @param to The address to withdraw ETH to
     */
    function withdrawETH(address to) public onlyOwnerOrAdmin {
        // Check there are no active auctions
        if (_activeAuctionCount > 0) revert CannotWithdrawWithActiveAuctions();

        // Go ahead and attempt to withdraw
        _withdrawETH(to);
    }

    /**
     * @notice Admin function to withdraw ERC-20 tokens from this contract
     * @dev Withdraws to the `to` address. This contract doesn't use ERC-20 tokens,
     * but this is a failsafe if tokens are sent to it by accident.
     * @param token The address of the ERC-20 token to withdraw
     * @param to The address to withdraw tokens to
     */
    function withdrawToken(address token, address to) public onlyOwnerOrAdmin {
        // Go ahead and attempt to withdraw
        _withdrawToken(token, to);
    }
}
