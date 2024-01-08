//SPDX-License-Identifier: MIT
pragma solidity 0.7.5;
pragma experimental ABIEncoderV2;

import "./SafeMath.sol";
import "./Ownable.sol";
import "./INft.sol";
import "./IAuction.sol";
import "./IHub.sol";
import "./Registry.sol";

contract AuctionHub is Ownable, IHub {
    using SafeMath for uint256;

    /**
     * Needed information about an auction request
     */
    struct LotRequest {
        address owner;              // Owner of token
        uint256 tokenID;            // ID of the token
        uint256 auctionID;          // ID of the auction
        LotStatus status;           // Status of the auction
    }
    // Enum for the state of an auction
    enum AuctionStatus { INACTIVE, ACTIVE, PAUSED }
    /**
     * Needed information around an auction
     */
    struct Auctions {
        AuctionStatus status;       // If the auction type is valid for requests
        string auctionName;         // Name of the auction 
        address auctionContract;    // Address of auction implementation
        bool onlyPrimarySales;      // If the auction can only do primary sales
    }

    // Scaling factor for splits. Allows for more decimal precision on percentages 
    uint256 constant internal SPLIT_SCALING_FACTOR = 10000;

    // Lot ID to lot request
    mapping(uint256 => LotRequest) internal lotRequests_;
    // Auction types
    mapping(uint256 => Auctions) internal auctions_;
    // Address to auction ID
    mapping(address => uint256) internal auctionAddress_;
    // A mapping to keep track of token IDs to if it is not the first sale
    mapping(uint256 => bool) internal isSecondarySale_;
    // Interface for NFT contract
    INft internal nftInstance_;
    // Storage for the registry instance 
    Registry internal registryInstance_;
    // Auction counter
    uint256 internal auctionCounter_;
    // Lot ID counters for auctions 
    uint256 internal lotCounter_;
    // First sale splits
    // Split to creator
    uint256 internal creatorSplitFirstSale_;
    // Split for system
    uint256 internal systemSplitFirstSale_;
    // Secondary sale splits
    // Split to creator
    uint256 internal creatorSplitSecondary_;
    // Split to seller
    uint256 internal sellerSplitSecondary_;
    // Split to system
    uint256 internal systemSplitSecondary_;

    // -----------------------------------------------------------------------
    // EVENTS  
    // -----------------------------------------------------------------------

    event AuctionRegistered(
        address owner,
        uint256 indexed auctionID,
        string auctionName,
        address auctionContract    
    );

    event AuctionUpdated(
        address owner,
        uint256 indexed auctionID,
        address oldAuctionContract,
        address newAuctionContract
    );

    event AuctionRemoved(
        address owner,
        uint256 indexed auctionID
    );

    event LotStatusChange(
        uint256 indexed lotID,
        uint256 indexed auctionID,
        address indexed auction,
        LotStatus status
    );

    event FirstSaleSplitUpdated(
        uint256 oldCreatorSplit,
        uint256 newCreatorSplit,
        uint256 oldSystemSplit,
        uint256 newSystemSplit
    );

    event SecondarySalesSplitUpdated(
        uint256 oldCreatorSplit,
        uint256 newCreatorSplit,
        uint256 oldSellerSplit,
        uint256 newSellerSplit,
        uint256 oldSystemSplit,
        uint256 newSystemSplit
    );

    event LotRequested(
        address indexed requester,
        uint256 indexed tokenID,
        uint256 indexed lotID
    );

    // -----------------------------------------------------------------------
    // MODIFIERS  
    // -----------------------------------------------------------------------

    modifier onlyAuction() {
        uint256 auctionID = this.getAuctionID(msg.sender);
        require(
            auctions_[auctionID].auctionContract == msg.sender &&
            auctions_[auctionID].status != AuctionStatus.INACTIVE,
            "Invalid auction"
        );
        _;
    }

    modifier onlyTokenOwner(uint256 _lotID) {
        require(
            msg.sender == lotRequests_[_lotID].owner,
            "Address not original owner"
        );
        _;
    }  

    modifier onlyRegistry() {
        require(
            msg.sender == address(registryInstance_),
            "Caller can only be registry"
        );
        _;
    }

    // -----------------------------------------------------------------------
    // CONSTRUCTOR 
    // -----------------------------------------------------------------------

    constructor(
        address _registry,
        uint256 _primaryCreatorSplit,
        uint256 _primarySystemSplit,
        uint256 _secondaryCreatorSplit,
        uint256 _secondarySellerSplit,
        uint256 _secondarySystemSplit
    ) 
        Ownable() 
    {
        registryInstance_ = Registry(_registry);
        nftInstance_ = INft(registryInstance_.getNft());
        require(
            nftInstance_.isActive(),
            "NFT contract not active"
        );
        _updateFirstSaleSplit(
            _primaryCreatorSplit,
            _primarySystemSplit
        );
        _updateSecondarySalesSplit(
            _secondaryCreatorSplit,
            _secondarySellerSplit,
            _secondarySystemSplit
        );
    }

    // -----------------------------------------------------------------------
    // NON-MODIFYING FUNCTIONS (VIEW)
    // -----------------------------------------------------------------------

    function getLotInformation(
        uint256 _lotID
    ) 
        external 
        view 
        override
        returns(
            address owner,
            uint256 tokenID,
            uint256 auctionID,
            LotStatus status
        ) 
    {
        owner= lotRequests_[_lotID].owner;
        tokenID= lotRequests_[_lotID].tokenID;
        auctionID= lotRequests_[_lotID].auctionID;
        status= lotRequests_[_lotID].status;
    }

    function getAuctionInformation(
        uint256 _auctionID
    )
        external
        view
        override
        returns(
            bool active,
            string memory auctionName,
            address auctionContract,
            bool onlyPrimarySales
        )
    {
        active = auctions_[_auctionID].status == AuctionStatus.ACTIVE ? true : false;
        auctionName = auctions_[_auctionID].auctionName;
        auctionContract = auctions_[_auctionID].auctionContract;
        onlyPrimarySales = auctions_[_auctionID].onlyPrimarySales;
    }

    function getAuctionID(
        address _auction
    ) 
        external 
        view 
        override 
        returns(uint256) 
    {
        return auctionAddress_[_auction];
    }

    function isAuctionActive(uint256 _auctionID) external view override returns(bool) {
        return auctions_[_auctionID].status == AuctionStatus.ACTIVE ? true : false;
    }

    function getAuctionCount() external view override returns(uint256) {
        return auctionCounter_;
    }

    function isAuctionHubImplementation() external view override returns(bool) {
        return true;
    }

    function isFirstSale(uint256 _tokenID) external view override returns(bool) {
        return !isSecondarySale_[_tokenID];
    }

    function getFirstSaleSplit() 
        external 
        view 
        override
        returns(
            uint256 creatorSplit,
            uint256 systemSplit
        )
    {
        creatorSplit = creatorSplitFirstSale_;
        systemSplit = systemSplitFirstSale_;
    }

    function getSecondarySaleSplits()
        external
        view
        override
        returns(
            uint256 creatorSplit,
            uint256 sellerSplit,
            uint256 systemSplit
        )
    {
        creatorSplit = creatorSplitSecondary_;
        sellerSplit = sellerSplitSecondary_;
        systemSplit = systemSplitSecondary_;
    }

    function getScalingFactor() external view override returns(uint256) {
        return SPLIT_SCALING_FACTOR;
    }

    // -----------------------------------------------------------------------
    // PUBLIC STATE MODIFYING FUNCTIONS
    // -----------------------------------------------------------------------

    function requestAuctionLot(
        uint256 _auctionType,
        uint256 _tokenID
    )
        external 
        override
        returns(uint256 lotID)
    {
        require(
            auctions_[_auctionType].status == AuctionStatus.ACTIVE,
            "Auction is inactive"
        );
        require(
            nftInstance_.ownerOf(_tokenID) == msg.sender,
            "Only owner can request lot"
        );
        // Enforces auction first sales limitation (not all auctions)
        if(auctions_[_auctionType].onlyPrimarySales) {
            require(
                this.isFirstSale(_tokenID),
                "Auction can only do first sales"
            );
        }
        lotCounter_ = lotCounter_.add(1);
        lotID = lotCounter_;

        lotRequests_[lotID] = LotRequest(
            msg.sender,
            _tokenID,
            _auctionType,
            LotStatus.LOT_REQUESTED
        );
        require(
            nftInstance_.isApprovedSpenderOf(
                msg.sender,
                address(this),
                _tokenID
            ),
            "Approve hub as spender first"
        );
        // Transferring the token from msg.sender to the hub
        nftInstance_.transferFrom(
            msg.sender,
            address(this),
            _tokenID
        );
        // Approving the auction as a spender of the token
        nftInstance_.approveSpender(
            auctions_[_auctionType].auctionContract,
            _tokenID,
            true
        );

        emit LotRequested(
            msg.sender,
            _tokenID,
            lotID
        );
    }

    function init() external override onlyRegistry() returns(bool) {
        return true;
    }
    

    // -----------------------------------------------------------------------
    // ONLY AUCTIONS STATE MODIFYING FUNCTIONS
    // -----------------------------------------------------------------------

    function firstSaleCompleted(uint256 _tokenID) external override onlyAuction() {
        isSecondarySale_[_tokenID] = true;
    }

    function lotCreated(
        uint256 _auctionID, 
        uint256 _lotID
    ) 
        external 
        override
        onlyAuction() 
    {
        lotRequests_[_lotID].status = LotStatus.LOT_CREATED;
        
        emit LotStatusChange(
            _lotID,
            _auctionID,
            msg.sender,
            LotStatus.LOT_CREATED
        );
    }

    function lotAuctionStarted(
        uint256 _auctionID, 
        uint256 _lotID
    ) 
        external 
        override
        onlyAuction() 
    {
        lotRequests_[_lotID].status = LotStatus.AUCTION_ACTIVE;

        emit LotStatusChange(
            _lotID,
            _auctionID,
            msg.sender,
            LotStatus.AUCTION_ACTIVE
        );
    }

    function lotAuctionCompleted(
        uint256 _auctionID, 
        uint256 _lotID
    ) 
        external 
        override
        onlyAuction() 
    {
        lotRequests_[_lotID].status = LotStatus.AUCTION_RESOLVED;

        emit LotStatusChange(
            _lotID,
            _auctionID,
            msg.sender,
            LotStatus.AUCTION_RESOLVED
        );
    }    

    function lotAuctionCompletedAndClaimed(
        uint256 _auctionID, 
        uint256 _lotID
    ) 
        external 
        override
        onlyAuction() 
    {
        lotRequests_[_lotID].status = LotStatus.AUCTION_RESOLVED_AND_CLAIMED;

        emit LotStatusChange(
            _lotID,
            _auctionID,
            msg.sender,
            LotStatus.AUCTION_RESOLVED_AND_CLAIMED
        );
    }    

    function cancelLot(
        uint256 _auctionID, 
        uint256 _lotID
    ) 
        external 
        override
        onlyTokenOwner(_lotID)
    {
        // Get the address of the current holder of the token
        address currentHolder = nftInstance_.ownerOf(
            lotRequests_[_lotID].tokenID
        );
        IAuction auction = IAuction(
            auctions_[lotRequests_[_lotID].auctionID].auctionContract
        );

        require(
            lotRequests_[_lotID].status == LotStatus.LOT_REQUESTED ||
            lotRequests_[_lotID].status == LotStatus.LOT_CREATED ||
            lotRequests_[_lotID].status == LotStatus.AUCTION_ACTIVE,
            "State invalid for cancellation"
        );
        require(
            !auction.hasBiddingStarted(_lotID),
            "Bidding has started, cannot cancel"
        );
        require(
            lotRequests_[_lotID].owner != currentHolder,
            "Token already with owner"
        );
        // If auction is a primary sale
        if(auctions_[lotRequests_[_lotID].auctionID].onlyPrimarySales) {
            require(
            lotRequests_[_lotID].status != LotStatus.AUCTION_ACTIVE,
            "Cant cancel active primary sales"
            );
        }
        // If the owner of the token is currently the auction hub
        if(currentHolder == address(this)) {
            // Transferring the token back to the owner
            nftInstance_.transfer(
                lotRequests_[_lotID].owner,
                lotRequests_[_lotID].tokenID
            );
            // If the owner of the token is currently the auction spoke
        } else if(
            auctions_[lotRequests_[_lotID].auctionID].auctionContract ==
            currentHolder
        ) {
            auction.cancelLot(_lotID);
        } else {
            // If the owner is neither the hub nor the spoke
            revert("Owner is not auction or hub");
        }
        // Setting lot status to canceled 
        lotRequests_[_lotID].status = LotStatus.AUCTION_CANCELED;

        emit LotStatusChange(
            _lotID,
            _auctionID,
            msg.sender,
            LotStatus.AUCTION_CANCELED
        );
    }

    // -----------------------------------------------------------------------
    // ONLY OWNER STATE MODIFYING FUNCTIONS
    // -----------------------------------------------------------------------

    /**
     * @param   _newCreatorSplit The new split for the creator on primary sales. 
     *          Scaled for more precision. 20% would be entered as 2000
     * @param   _newSystemSplit The new split for the system on primary sales.
     *          Scaled for more precision. 20% would be entered as 2000
     * @notice  Will revert if the sum of the two new splits does not equal 
     *          10000 (the scaled resolution)
     */
    function updateFirstSaleSplit(
        uint256 _newCreatorSplit,
        uint256 _newSystemSplit
    )
        external
        onlyOwner()
    {
        _updateFirstSaleSplit(
            _newCreatorSplit,
            _newSystemSplit
        );
    }

    /**
     * @param   _newCreatorSplit The new split for the creator on secondary sales.
     *          Scaled for more precision. 20% would be entered as 2000
     * @param   _newSellerSplit The new split to the seller on secondary sales.
                Scaled for more precision. 20% would be entered as 2000
     * @param   _newSystemSplit The new split for the system on secondary sales.
     *          Scaled for more precision. 20% would be entered as 2000
     * @notice  Will revert if the sum of the three new splits does not equal 
     *          10000 (the scaled resolution)
     */
    function updateSecondarySalesSplit(
        uint256 _newCreatorSplit,
        uint256 _newSellerSplit,
        uint256 _newSystemSplit
    )
        external
        onlyOwner()
    {
        _updateSecondarySalesSplit(
            _newCreatorSplit,
            _newSellerSplit,
            _newSystemSplit
        );
    }

    function registerAuction(
        string memory _name,
        address _auctionInstance,
        bool _onlyPrimarySales
    )
        external
        onlyOwner()
        returns(uint256 auctionID)
    {
        // Incrementing auction ID counter
        auctionCounter_ = auctionCounter_.add(1);
        auctionID = auctionCounter_;
        // Saving auction ID to address
        auctionAddress_[_auctionInstance] = auctionID;
        // Storing all information around auction 
        auctions_[auctionID] = Auctions(
            AuctionStatus.INACTIVE,
            _name,
            _auctionInstance,
            _onlyPrimarySales
        );
        // Initialising auction
        require(
            IAuction(_auctionInstance).init(auctionID),
            "Auction initialisation failed"
        );
        // Setting auction to active
        auctions_[auctionID].status = AuctionStatus.ACTIVE;

        emit AuctionRegistered(
            msg.sender,
            auctionID,
            _name,
            _auctionInstance    
        );
    }

    /**
     * @param   _auctionID The ID of the auction to be paused.
     * @notice  This function allows the owner to pause the auction type. While
     *          the auction is paused no new lots can be created, but old lots
     *          can still complete. 
     */
    function pauseAuction(uint256 _auctionID) external onlyOwner() {
        require(
            auctions_[_auctionID].status == AuctionStatus.ACTIVE,
            "Cannot pause inactive auction"
        );

        auctions_[_auctionID].status = AuctionStatus.PAUSED;
    }

    function updateAuctionInstance(
        uint256 _auctionID,
        address _newImplementation
    )
        external 
        onlyOwner()
    {
        require(
            auctions_[_auctionID].status == AuctionStatus.PAUSED,
            "Auction must be paused before update"
        );
        require(
            auctions_[_auctionID].auctionContract != _newImplementation,
            "Auction address already set"
        );

        IAuction newAuction = IAuction(_newImplementation);

        require(
            newAuction.isActive() == false,
            "Auction has been activated"
        );

        newAuction.init(_auctionID);

        address oldAuctionContract = auctions_[_auctionID].auctionContract;
        auctionAddress_[oldAuctionContract] = 0;
        auctions_[_auctionID].auctionContract = _newImplementation;
        auctionAddress_[_newImplementation] = _auctionID;

        emit AuctionUpdated(
            msg.sender,
            _auctionID,
            oldAuctionContract,
            _newImplementation
        );
    }

    function removeAuction(
        uint256 _auctionID
    )
        external 
        onlyOwner()
    {
        require(
            auctions_[_auctionID].status == AuctionStatus.PAUSED,
            "Auction must be paused before update"
        );

        auctions_[_auctionID].status = AuctionStatus.INACTIVE;
        auctions_[_auctionID].auctionName = "";
        auctionAddress_[auctions_[_auctionID].auctionContract] = 0;
        auctions_[_auctionID].auctionContract = address(0);

        emit AuctionRemoved(
            msg.sender,
            _auctionID
        );
    } 

    // -----------------------------------------------------------------------
    // INTERNAL MODIFYING FUNCTIONS
    // -----------------------------------------------------------------------

    function _updateSecondarySalesSplit(
        uint256 _newCreatorSplit,
        uint256 _newSellerSplit,
        uint256 _newSystemSplit
    )
        internal
    {
        uint256 total = _newCreatorSplit
            .add(_newSellerSplit)
            .add(_newSystemSplit);

        require(
            total == SPLIT_SCALING_FACTOR,
            "New split not equal to 100%"
        );

        emit SecondarySalesSplitUpdated(
            creatorSplitSecondary_,
            _newCreatorSplit,
            sellerSplitSecondary_,
            _newSellerSplit,
            systemSplitSecondary_,
            _newSystemSplit
        );

        creatorSplitSecondary_ = _newCreatorSplit;
        sellerSplitSecondary_ = _newSellerSplit;
        systemSplitSecondary_ = _newSystemSplit;
    }

    function _updateFirstSaleSplit(
        uint256 _newCreatorSplit,
        uint256 _newSystemSplit
    )
        internal
    {
        uint256 total = _newCreatorSplit.add(_newSystemSplit);

        require(
            total == SPLIT_SCALING_FACTOR,
            "New split not equal to 100%"
        );
        
        emit FirstSaleSplitUpdated(
            creatorSplitFirstSale_,
            _newCreatorSplit,
            systemSplitFirstSale_,
            _newSystemSplit
        );

        creatorSplitFirstSale_ = _newCreatorSplit;
        systemSplitFirstSale_ = _newSystemSplit;
    }
}