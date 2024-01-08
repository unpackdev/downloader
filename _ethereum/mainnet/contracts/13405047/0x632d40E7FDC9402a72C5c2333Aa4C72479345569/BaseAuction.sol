//SPDX-License-Identifier: MIT
pragma solidity 0.7.5;

import "./IHub.sol";
import "./IAuction.sol";
import "./INft.sol";
import "./Registry.sol";
import "./IRoyalties.sol";
import "./SafeMath.sol";
import "./IERC20.sol";
import "./ReentrancyGuard.sol";

abstract contract BaseAuction is IAuction, ReentrancyGuard {
    // Libraries
    using SafeMath for uint256;

    // -----------------------------------------------------------------------
    // STATE VARIABLES
    // -----------------------------------------------------------------------

    // Instance of the registry
    Registry internal registryInstance_;
    // Instance of the auction Hub
    IHub internal auctionHubInstance_;
    // Instance of the NFT contract being used (modified ERC1155)
    INft internal nftInstance_;
    // Instance of the royalties contract
    IRoyalties internal royaltiesInstance_;
    // ID of this auction instance
    uint256 internal auctionID_;
    // Bool check to ensure that the auction can only be initialised once.
    // Variable is private so it cannot be changed in child contracts, and
    // can only be set once on initialisation
    bool private isInit_;

    struct Lot {
        address owner;
        uint256 tokenID;
        bool biddingStarted;
    }

    mapping(uint256 => Lot) internal lots_;

    uint256 internal constant SPLIT_SCALING_FACTOR = 10000;

    // -----------------------------------------------------------------------
    // EVENTS
    // -----------------------------------------------------------------------

    event Initialised(address auctionHub, uint256 auctionID);

    event AuctionLotCreated(
        address indexed creator,
        uint256 auctionID,
        uint256 lotID,
        uint256 tokenID
    );

    event LotWinner(
        uint256 indexed auctionID,
        uint256 indexed lotID,
        address indexed winner
    );

    event LotLoserClaim(
        uint256 indexed auctionID,
        uint256 indexed lotID,
        address indexed claimer,
        uint256 claimAmount
    );

    // -----------------------------------------------------------------------
    // MODIFIERS
    // -----------------------------------------------------------------------

    /**
     * @notice  A modifier to restrict access to only the auction hub
     */
    modifier onlyHub() {
        require(
            msg.sender == address(auctionHubInstance_),
            "Access restricted to Hub"
        );
        _;
    }

    /**
     * @notice  A modifier to protect the initialisation call so that an auction
     *          can only be initialised once
     */
    modifier initialise() {
        require(isInit_ == false, "Auction has already been init");
        _;
    }

    modifier onlyActive() {
        require(
            isInit_ && auctionHubInstance_.isAuctionActive(auctionID_),
            "Auction not in valid use state"
        );
        _;
    }

    modifier onlyLotOwner(uint256 _lotID) {
        address owner;
        (owner, , , ) = auctionHubInstance_.getLotInformation(_lotID);
        // Ensuring the lot information is correct
        require(owner == msg.sender, "Creator must own token");
        _;
    }

    // -----------------------------------------------------------------------
    // CONSTRUCTOR
    // -----------------------------------------------------------------------

    constructor(address _registryInstance) {
        registryInstance_ = Registry(_registryInstance);
        auctionHubInstance_ = IHub(registryInstance_.getHub());
        nftInstance_ = INft(registryInstance_.getNft());
        royaltiesInstance_ = IRoyalties(registryInstance_.getRoyalties());
    }

    // -----------------------------------------------------------------------
    // NON-MODIFYING FUNCTIONS (VIEW)
    // -----------------------------------------------------------------------

    /**
     * @return  bool The active status of the auction. Will only return true if
     *          the auction has been initialised and is active.
     */
    function isActive() external view override returns (bool) {
        if (isInit_ && auctionHubInstance_.isAuctionActive(auctionID_)) {
            return true;
        }
        return false;
    }

    /**
     * @param   _lotID The ID of the lot.
     * @return  bool If bidding has started on the lot.
     */
    function hasBiddingStarted(uint256 _lotID) external view override returns (bool) {
        return lots_[_lotID].biddingStarted;
    }

    /**
     * @return  uint256 The auction ID as set by the auction hub of this
     *          auction.
     */
    function getAuctionID() external view override returns (uint256) {
        return auctionID_;
    }

    // -----------------------------------------------------------------------
    // ONLY AUCTION HUB STATE MODIFYING FUNCTIONS
    // -----------------------------------------------------------------------

    /**
     * @param   _auctionID ID of the auction this auction is
     * @dev     This call will be protected so only the Auction hub can call it.
     *          This function will also set the auction state to active.
     */
    function init(uint256 _auctionID)
        external
        override
        onlyHub()
        initialise()
        returns (bool)
    {
        auctionID_ = _auctionID;
        isInit_ = true;

        emit Initialised(msg.sender, _auctionID);

        return true;
    }

    /**
     * @param   _lotID ID of the lot
     * @dev     Transfers the token from the auction back to the lot requester
     */
    function cancelLot(uint256 _lotID) external override onlyHub() {
        // Transferring the token to the lot owner
        nftInstance_.transfer(lots_[_lotID].owner, lots_[_lotID].tokenID);
    }

    // -----------------------------------------------------------------------
    // INTERNAL STATE MODIFYING FUNCTIONS
    // -----------------------------------------------------------------------

    /**
     * @param   _lotID ID of the new lot auction being created within this
     *          auction instance.
     * @param   _tokenID ID of the token being sold in the auction type.
     * @dev     Only the Auction Hub is able to call this function.
     */
    function _createAuctionLot(uint256 _lotID, uint256 _tokenID) internal {
        // Getting the relevant lot information
        address owner;
        uint256 tokenID;
        uint256 auctionID;
        IHub.LotStatus status;
        (owner, tokenID, auctionID, status) = auctionHubInstance_
        .getLotInformation(_lotID);
        // Ensuring the lot information is correct
        require(owner == msg.sender, "Creator must own token");
        require(tokenID == _tokenID, "Given lot ID mismatch token lot");
        require(auctionID == auctionID_, "Lot on different auction");
        require(status == IHub.LotStatus.LOT_REQUESTED, "Lot status incorrect");
        // Storing the lot information
        lots_[_lotID].owner = owner;
        lots_[_lotID].tokenID = tokenID;
        // Updating the Lot's status to created
        auctionHubInstance_.lotCreated(auctionID_, _lotID);
        // Transferring the token to this auction
        nftInstance_.transferFrom(
            address(auctionHubInstance_),
            address(this),
            tokenID
        );

        emit AuctionLotCreated(msg.sender, auctionID, _lotID, tokenID);
    }

    /**
     * @param   _lotID The ID of the lot
     * @notice  This function will revert if the lot is not in the created
     *          state or active state. Will also revert if the state is
     *          canceled.
     */
    function _isLotInBiddableState(uint256 _lotID) internal {
        IHub.LotStatus status;
        (, , , status) = auctionHubInstance_.getLotInformation(_lotID);
        require(
            (status != IHub.LotStatus.AUCTION_CANCELED &&
                status == IHub.LotStatus.LOT_CREATED) ||
                status == IHub.LotStatus.AUCTION_ACTIVE,
            "Bid has ended or canceled"
        );
        
        if(!lots_[_lotID].biddingStarted) {
            lots_[_lotID].biddingStarted = true;
        }
    }

    /**
     * @param   _lotID The ID of the lot
     * @param   _winner The address of the lot winner
     * @notice  Shared functionality that all the auctions will need for
     *          executing the needed winning functionality.
     */
    function _winner(uint256 _lotID, address _winner) internal {
        // Sending the winner their token
        nftInstance_.transfer(_winner, lots_[_lotID].tokenID);
        // Setting the lot to completed on the hub
        auctionHubInstance_.lotAuctionCompletedAndClaimed(auctionID_, _lotID);
        // Emitting that the lot has been resolved
        emit LotWinner(auctionID_, _lotID, msg.sender);
    }

    /**
     * @param   _loserAddress Address of loser
     * @param   _bidAmount The amount that was bid
     * @notice  This function transfers the loser their bid amount. NOTE not all
     *          auction types will use this function, which is why it does no
     *          data validation.
     */
    function _insecureLoser(
        uint256 lotID,
        address _loserAddress,
        uint256 _bidAmount
    ) internal {
        // Sending loser amount
        (bool success, ) = _loserAddress.call{value: _bidAmount}("");
        // Ensuring transfer succeeded
        require(success, "Transfer failed.");

        emit LotLoserClaim(auctionID_, lotID, _loserAddress, _bidAmount);
    }

    /**
     * @param   _lotID The ID of the lot
     * @param   _totalCollateralAmount The total amount of collateral that was
     *          bid.
     * @notice  This function will call first or secondary payment functions
     *          as needed.
     */
    function _insecureHandlePayment(
        uint256 _lotID,
        uint256 _totalCollateralAmount
    ) internal {
        if (auctionHubInstance_.isFirstSale(lots_[_lotID].tokenID)) {
            _handleFirstSalePayment(_lotID, _totalCollateralAmount);
        } else {
            _insecureHandleSecondarySalesPayment(
                _lotID,
                _totalCollateralAmount
            );
        }
    }

    function _handleFirstSalePayment(
        uint256 _lotID,
        uint256 _totalCollateralAmount
    ) internal {
        require(
            auctionHubInstance_.isFirstSale(lots_[_lotID].tokenID),
            "Not first sale"
        );
        // Temporary storage for splits and shares
        uint256 creatorSplit;
        uint256 systemSplit;
        uint256 creatorShare;
        uint256 systemShare;
        // Getting the split for the
        (creatorSplit, systemSplit) = auctionHubInstance_.getFirstSaleSplit();
        // Working out the creators share according to the split
        creatorShare = _totalCollateralAmount.mul(creatorSplit).div(
            SPLIT_SCALING_FACTOR
        );
        // Working out the systems share according to the split
        systemShare = _totalCollateralAmount.mul(systemSplit).div(
            SPLIT_SCALING_FACTOR
        );
        require(
            creatorShare.add(systemShare) <= _totalCollateralAmount,
            "BAU: Fatal: value mismatch"
        );
        // Depositing creator share
        royaltiesInstance_.deposit{value: creatorShare}(
            nftInstance_.creatorOf(lots_[_lotID].tokenID),
            creatorShare
        );
        // Depositing the system share
        royaltiesInstance_.deposit{value: systemShare}(address(0), systemShare);
        // Setting on the auction hub that the first sale is completed
        auctionHubInstance_.firstSaleCompleted(lots_[_lotID].tokenID);
    }

    function _insecureHandleSecondarySalesPayment(
        uint256 _lotID,
        uint256 _totalCollateralAmount
    ) internal {
        require(
            !auctionHubInstance_.isFirstSale(lots_[_lotID].tokenID),
            "Not secondary sale"
        );
        // Temporary storage for splits and shares
        uint256 creatorSplit;
        uint256 sellerSplit;
        uint256 systemSplit;
        uint256 creatorShare;
        uint256 sellerShare;
        uint256 systemShare;
        // Getting the split for the
        (creatorSplit, sellerSplit, systemSplit) = auctionHubInstance_
        .getSecondarySaleSplits();
        // Working out the creators share according to the split
        creatorShare = _totalCollateralAmount.mul(creatorSplit).div(
            SPLIT_SCALING_FACTOR
        );
        // Working out the sellers share according to the split
        sellerShare = _totalCollateralAmount.mul(sellerSplit).div(
            SPLIT_SCALING_FACTOR
        );
        // Working out the systems share according to the split
        systemShare = _totalCollateralAmount.mul(systemSplit).div(
            SPLIT_SCALING_FACTOR
        );
        // Depositing creator share
        royaltiesInstance_.deposit{value: creatorShare}(
            nftInstance_.creatorOf(lots_[_lotID].tokenID),
            creatorShare
        );
        // Depositing the system share
        royaltiesInstance_.deposit{value: systemShare}(address(0), systemShare);
        // Sending user amount
        (bool success, ) = lots_[_lotID].owner.call{value: sellerShare}("");
        // Ensuring transfer succeeded
        require(success, "Transfer failed.");
    }
}
