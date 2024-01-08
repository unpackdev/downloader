// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./IERC1155.sol";
import "./SafeMath.sol";
import "./Ownable.sol";
import "./INafterMarketAuction.sol";
import "./INafterRoyaltyRegistry.sol";
import "./IMarketplaceSettings.sol";
import "./Payments.sol";
import "./INafter.sol";

contract NafterMarketAuction is INafterMarketAuction, Ownable, Payments {
    using SafeMath for uint256;

    /////////////////////////////////////////////////////////////////////////
    // Structs
    /////////////////////////////////////////////////////////////////////////

    // The active bid for a given token, contains the bidder, the marketplace fee at the time of the bid, and the amount of wei placed on the token
    struct ActiveBid {
        address payable bidder;
        uint8 marketplaceFee;
        uint256 amount;
    }

    struct ActiveBidRange {
        uint256 startTime;
        uint256 endTime;
    }

    // The sale price for a given token containing the seller and the amount of wei to be sold for
    struct SalePrice {
        address payable seller;
        uint256 amount;
    }

    /////////////////////////////////////////////////////////////////////////
    // State Variables
    /////////////////////////////////////////////////////////////////////////

    // Marketplace Settings Interface
    IMarketplaceSettings public iMarketplaceSettings;

    // Creator Royalty Interface
    INafterRoyaltyRegistry public iERC1155CreatorRoyalty;

    // Nafter contract
    INafter public nafter;
    //erc1155 contract
    IERC1155 public erc1155;

    // Mapping from ERC1155 contract to mapping of tokenId to sale price.
    mapping(uint256 => mapping(address => SalePrice)) private salePrice;
    // Mapping of ERC1155 contract to mapping of token ID to the current bid amount.
    mapping(uint256 => mapping(address => ActiveBid)) private activeBid;
    mapping(uint256 => mapping(address => ActiveBidRange)) private activeBidRange;

    mapping(address => uint256) public bidBalance;
    // A minimum increase in bid amount when out bidding someone.
    uint8 public minimumBidIncreasePercentage; // 10 = 10%

    /////////////////////////////////////////////////////////////////////////////
    // Events
    /////////////////////////////////////////////////////////////////////////////
    event Sold(
        address indexed _buyer,
        address indexed _seller,
        uint256 _amount,
        uint256 _tokenId
    );

    event SetSalePrice(
        uint256 _amount,
        uint256 _tokenId
    );

    event Bid(
        address indexed _bidder,
        uint256 _amount,
        uint256 _tokenId
    );

    event SetInitialBidPriceWithRange(
        uint256 _bidAmount,
        uint256 _startTime,
        uint256 _endTime,
        address _owner,
        uint256 _tokenId
    );
    event AcceptBid(
        address indexed _bidder,
        address indexed _seller,
        uint256 _amount,
        uint256 _tokenId
    );

    event CancelBid(
        address indexed _bidder,
        uint256 _amount,
        uint256 _tokenId
    );

    /////////////////////////////////////////////////////////////////////////
    // Constructor
    /////////////////////////////////////////////////////////////////////////
    /**
     * @dev Initializes the contract setting the market settings and creator royalty interfaces.
     * @param _iMarketSettings address to set as iMarketplaceSettings.
     * @param _iERC1155CreatorRoyalty address to set as iERC1155CreatorRoyalty.
     * @param _nafter address of the nafter contract
     */
    constructor(address _iMarketSettings, address _iERC1155CreatorRoyalty, address _nafter)
    public
    {
        require(
            _iMarketSettings != address(0),
            "constructor::Cannot have null address for _iMarketSettings"
        );

        require(
            _iERC1155CreatorRoyalty != address(0),
            "constructor::Cannot have null address for _iERC1155CreatorRoyalty"
        );

        require(
            _nafter != address(0),
            "constructor::Cannot have null address for _nafter"
        );

        // Set iMarketSettings
        iMarketplaceSettings = IMarketplaceSettings(_iMarketSettings);

        // Set iERC1155CreatorRoyalty
        iERC1155CreatorRoyalty = INafterRoyaltyRegistry(_iERC1155CreatorRoyalty);

        nafter = INafter(_nafter);
        erc1155 = IERC1155(_nafter);

        minimumBidIncreasePercentage = 10;
    }

    /////////////////////////////////////////////////////////////////////////
    // Get owner of the token
    /////////////////////////////////////////////////////////////////////////
    /**
     * @dev get owner of the token
     * @param _tokenId uint256 ID of the token
     * @param _owner address of the token owner
     */
    function isOwnerOfTheToken(uint256 _tokenId, address _owner) public view returns (bool) {
        uint256 balance = erc1155.balanceOf(_owner, _tokenId);
        return balance > 0;
    }

    /////////////////////////////////////////////////////////////////////////
    // Get token sale price against token id
    /////////////////////////////////////////////////////////////////////////
    /**
     * @dev get the token sale price against token id
     * @param _tokenId uint256 ID of the token
     * @param _owner address of the token owner
     */
    function getSalePrice(uint256 _tokenId, address _owner) external view returns (address payable, uint256){
        SalePrice memory sp = salePrice[_tokenId][_owner];
        return (sp.seller, sp.amount);
    }

    /////////////////////////////////////////////////////////////////////////
    // get active bid against tokenId
    /////////////////////////////////////////////////////////////////////////
    /**
     * @dev get active bid against token Id
     * @param _tokenId uint256 ID of the token
     * @param _owner address of the token owner
     */
    function getActiveBid(uint256 _tokenId, address _owner) external view returns (address payable, uint8, uint256){
        ActiveBid memory ab = activeBid[_tokenId][_owner];
        return (ab.bidder, ab.marketplaceFee, ab.amount);
    }

    /////////////////////////////////////////////////////////////////////////
    // has active bid
    /////////////////////////////////////////////////////////////////////////
    /**
     * @dev has active bid
     * @param _tokenId uint256 ID of the token
     * @param _owner address of the token owner
     */
    function hasTokenActiveBid(uint256 _tokenId, address _owner) external view override returns (bool){
        ActiveBid memory ab = activeBid[_tokenId][_owner];
        if (ab.bidder == _owner || ab.bidder == address(0))
            return false;

        return true;
    }

    /////////////////////////////////////////////////////////////////////////
    // get bid balance of user
    /////////////////////////////////////////////////////////////////////////
    /**
     * @dev get bid balance of user
     * @param _user address of the user
     */
    function getBidBalance(address _user) external view returns (uint256){
        return bidBalance[_user];
    }

    /////////////////////////////////////////////////////////////////////////
    // get active bid range against token id
    /////////////////////////////////////////////////////////////////////////
    /**
     * @dev get active bid range against token id
     * @param _tokenId uint256 ID of the token
     */
    function getActiveBidRange(uint256 _tokenId, address _owner) external view returns (uint256, uint256){
        ActiveBidRange memory abr = activeBidRange[_tokenId][_owner];
        return (abr.startTime, abr.endTime);
    }

    /////////////////////////////////////////////////////////////////////////
    // withdrawMarketFunds
    /////////////////////////////////////////////////////////////////////////
    /**
     * @dev Admin function to withdraw market funds
     * Rules:
     * - only owner
     */
    function withdrawMarketFunds() external onlyOwner {
        uint256 balance = address(this).balance;
        _makePayable(owner()).transfer(balance);
    }

    /////////////////////////////////////////////////////////////////////////
    // setIMarketplaceSettings
    /////////////////////////////////////////////////////////////////////////
    /**
     * @dev Admin function to set the marketplace settings.
     * Rules:
     * - only owner
     * - _address != address(0)
     * @param _address address of the IMarketplaceSettings.
     */
    function setMarketplaceSettings(address _address) public onlyOwner {
        require(
            _address != address(0),
            "setMarketplaceSettings::Cannot have null address for _iMarketSettings"
        );

        iMarketplaceSettings = IMarketplaceSettings(_address);
    }

    /////////////////////////////////////////////////////////////////////////
    // seNafter
    /////////////////////////////////////////////////////////////////////////
    /**
     * @dev Admin function to set the marketplace settings.
     * Rules:
     * - only owner
     * - _address != address(0)
     * @param _address address of the IMarketplaceSettings.
     */
    function setNafter(address _address) public onlyOwner {
        require(
            _address != address(0),
            "setNafter::Cannot have null address for _INafter"
        );

        nafter = INafter(_address);
        erc1155 = IERC1155(_address);
    }

    /////////////////////////////////////////////////////////////////////////
    // setIERC1155CreatorRoyalty
    /////////////////////////////////////////////////////////////////////////
    /**
     * @dev Admin function to set the IERC1155CreatorRoyalty.
     * Rules:
     * - only owner
     * - _address != address(0)
     * @param _address address of the IERC1155CreatorRoyalty.
     */
    function setIERC1155CreatorRoyalty(address _address) public onlyOwner {
        require(
            _address != address(0),
            "setIERC1155CreatorRoyalty::Cannot have null address for _iERC1155CreatorRoyalty"
        );

        iERC1155CreatorRoyalty = INafterRoyaltyRegistry(_address);
    }

    /////////////////////////////////////////////////////////////////////////
    // setMinimumBidIncreasePercentage
    /////////////////////////////////////////////////////////////////////////
    /**
     * @dev Admin function to set the minimum bid increase percentage.
     * Rules:
     * - only owner
     * @param _percentage uint8 to set as the new percentage.
     */
    function setMinimumBidIncreasePercentage(uint8 _percentage)
    public
    onlyOwner
    {
        minimumBidIncreasePercentage = _percentage;
    }

    /////////////////////////////////////////////////////////////////////////
    // Modifiers (as functions)
    /////////////////////////////////////////////////////////////////////////
    /**
     * @dev Checks that the token owner is approved for the ERC1155Market
     * @param _owner address of the token owner
     */
    function ownerMustHaveMarketplaceApproved(
        address _owner
    ) internal view {
        require(
            erc1155.isApprovedForAll(_owner, address(this)),
            "owner must have approved contract"
        );
    }

    /**
     * @dev Checks that the token is owned by the sender
     * @param _tokenId uint256 ID of the token
     */
    function senderMustBeTokenOwner(uint256 _tokenId)
    internal
    view
    {
        bool isOwner = isOwnerOfTheToken(_tokenId, msg.sender);

        require(isOwner || msg.sender == address(nafter), 'sender must be the token owner');
    }

    /////////////////////////////////////////////////////////////////////////
    // setSalePrice
    /////////////////////////////////////////////////////////////////////////
    /**
     * @dev Set the token for sale. The owner of the token must be the sender and have the marketplace approved.
     * @param _tokenId uint256 ID of the token
     * @param _amount uint256 wei value that the item is for sale
     * @param _owner address of the token owner
     */
    function setSalePrice(
        uint256 _tokenId,
        uint256 _amount,
        address _owner
    ) external override {
        // The owner of the token must have the marketplace approved
        ownerMustHaveMarketplaceApproved(_owner);

        // The sender must be the token owner
        senderMustBeTokenOwner(_tokenId);

        if (_amount == 0) {
            // Set not for sale and exit
            _resetTokenPrice(_tokenId, _owner);
            emit SetSalePrice(_amount, _tokenId);
            return;
        }

        salePrice[_tokenId][_owner] = SalePrice(payable(_owner), _amount);
        nafter.setPrice(_amount, _tokenId, _owner);
        // nafter.putOnSale(0, _tokenId, _owner);
        // nafter.setPriceType(0, _tokenId);
        // nafter.setIsForSale(true, _tokenId, _owner);
        emit SetSalePrice(_amount, _tokenId);
    }

    /**
     * @dev restore data from old contract, only call by owner
     * @param _oldAddress address of old contract.
     * @param _oldNafterAddress get the token ids from the old nafter contract.
     * @param _startIndex start index of array
     * @param _endIndex end index of array
     */
    function restore(address _oldAddress, address _oldNafterAddress, uint256 _startIndex, uint256 _endIndex) external onlyOwner {
        NafterMarketAuction oldContract = NafterMarketAuction(_oldAddress);
        INafter oldNafterContract = INafter(_oldNafterAddress);

        uint256 length = oldNafterContract.getTokenIdsLength();
        require(_startIndex < length, "wrong start index");
        require(_endIndex <= length, "wrong end index");

        for (uint i = _startIndex; i < _endIndex; i++) {
            uint256 tokenId = oldNafterContract.getTokenId(i);

            address[] memory owners = oldNafterContract.getOwners(tokenId);
            for (uint j = 0; j < owners.length; j++) {
                address owner = owners[j];
                (address payable sender, uint256 amount) = oldContract.getSalePrice(tokenId, owner);
                salePrice[tokenId][owner] = SalePrice(sender, amount);

                (address payable bidder, uint8 marketplaceFee, uint256 bidAmount) = oldContract.getActiveBid(tokenId, owner);
                activeBid[tokenId][owner] = ActiveBid(bidder, marketplaceFee, bidAmount);
                uint256 serviceFee = bidAmount.mul(marketplaceFee).div(100);
                bidBalance[bidder] = bidBalance[bidder].add(bidAmount.add(serviceFee));


                (uint256 startTime, uint256 endTime) = oldContract.getActiveBidRange(tokenId, owner);
                activeBidRange[tokenId][owner] = ActiveBidRange(startTime, endTime);
            }
        }
        setMinimumBidIncreasePercentage(oldContract.minimumBidIncreasePercentage());
    }
    /////////////////////////////////////////////////////////////////////////
    // safeBuy
    /////////////////////////////////////////////////////////////////////////
    /**
     * @dev Purchase the token with the expected amount. The current token owner must have the marketplace approved.
     * @param _tokenId uint256 ID of the token
     * @param _amount uint256 wei amount expecting to purchase the token for.
     * @param _owner address of the token owner
     */
    function safeBuy(
        uint256 _tokenId,
        uint256 _amount,
        address _owner
    ) external payable {
        // Make sure the tokenPrice is the expected amount
        require(
            salePrice[_tokenId][_owner].amount == _amount,
            "safeBuy::Purchase amount must equal expected amount"
        );
        buy(_tokenId, _owner);
    }

    /////////////////////////////////////////////////////////////////////////
    // buy
    /////////////////////////////////////////////////////////////////////////
    /**
     * @dev Purchases the token if it is for sale.
     * @param _tokenId uint256 ID of the token.
     * @param _owner address of the token owner
     */
    function buy(uint256 _tokenId, address _owner) public payable {
        require(nafter.getIsForSale(_tokenId, _owner) == true, "bid::not for sale");
        // The owner of the token must have the marketplace approved
        ownerMustHaveMarketplaceApproved(_owner);

        // Check that the person who set the price still owns the token.
        require(
            _priceSetterStillOwnsTheToken(_tokenId, _owner),
            "buy::Current token owner must be the person to have the latest price."
        );

        uint8 priceType = nafter.getPriceType(_tokenId, _owner);
        require(priceType == 0, "buy is only allowed for fixed sale");

        SalePrice memory sp = salePrice[_tokenId][_owner];

        // Check that token is for sale.
        require(sp.amount > 0, "buy::Tokens priced at 0 are not for sale.");

        // Check that enough ether was sent.
        require(
            tokenPriceFeeIncluded(_tokenId, _owner) == msg.value,
            "buy::Must purchase the token for the correct price"
        );

        // Wipe the token price.
        _resetTokenPrice(_tokenId, _owner);

        // Transfer token.
        erc1155.safeTransferFrom(_owner, msg.sender, _tokenId, 1, '');

        // if the buyer had an existing bid, return it
        if (_addressHasBidOnToken(msg.sender, _tokenId, _owner)) {
            _refundBid(_tokenId, _owner);
        }

        // Payout all parties.
        address payable marketOwner = _makePayable(owner());
        Payments.payout(
            sp.amount,
            !iMarketplaceSettings.hasTokenSold(_tokenId),
            nafter.getServiceFee(_tokenId),
            iERC1155CreatorRoyalty.getTokenRoyaltyPercentage(
                _tokenId
            ),
            iMarketplaceSettings.getERC1155ContractPrimarySaleFeePercentage(),
            _makePayable(_owner),
            marketOwner,
            iERC1155CreatorRoyalty.tokenCreator(_tokenId),
            marketOwner
        );

        // Set token as sold
        iMarketplaceSettings.markERC1155Token(_tokenId, true);

        //remove from sale after buy
        nafter.removeFromSale(_tokenId, _owner);

        emit Sold(msg.sender, _owner, sp.amount, _tokenId);
    }

    /////////////////////////////////////////////////////////////////////////
    // tokenPrice
    /////////////////////////////////////////////////////////////////////////
    /**
     * @dev Gets the sale price of the token
     * @param _tokenId uint256 ID of the token
     * @param _owner address of the token owner
     * @return uint256 sale price of the token
     */
    function tokenPrice(uint256 _tokenId, address _owner)
    external
    view
    returns (uint256)
    {
        // The owner of the token must have the marketplace approved
        ownerMustHaveMarketplaceApproved(_owner);
        // TODO: Make sure to write test to verify that this returns 0 when it fails

        if (_priceSetterStillOwnsTheToken(_tokenId, _owner)) {
            return salePrice[_tokenId][_owner].amount;
        }
        return 0;
    }

    /////////////////////////////////////////////////////////////////////////
    // tokenPriceFeeIncluded
    /////////////////////////////////////////////////////////////////////////
    /**
     * @dev Gets the sale price of the token including the marketplace fee.
     * @param _tokenId uint256 ID of the token
     * @param _owner address of the token owner
     * @return uint256 sale price of the token including the fee.
     */
    function tokenPriceFeeIncluded(uint256 _tokenId, address _owner)
    public
    view
    returns (uint256)
    {
        // The owner of the token must have the marketplace approved
        ownerMustHaveMarketplaceApproved(_owner);
        // TODO: Make sure to write test to verify that this returns 0 when it fails

        if (_priceSetterStillOwnsTheToken(_tokenId, _owner)) {
            return
            salePrice[_tokenId][_owner].amount.add(
                salePrice[_tokenId][_owner].amount.mul(
                    nafter.getServiceFee(_tokenId)
                ).div(100)
            );
        }
        return 0;
    }

    /////////////////////////////////////////////////////////////////////////
    // setInitialBidPriceWithRange
    /////////////////////////////////////////////////////////////////////////
    /**
     * @dev set
     * @param _bidAmount uint256 value in wei to bid.
     * @param _startTime end time of bid
     * @param _endTime end time of bid
     * @param _owner address of the token owner
     * @param _tokenId uint256 ID of the token
     */
    function setInitialBidPriceWithRange(uint256 _bidAmount, uint256 _startTime, uint256 _endTime, address _owner, uint256 _tokenId) external override {
        require(_bidAmount > 0, "setInitialBidPriceWithRange::Cannot bid 0 Wei.");
        senderMustBeTokenOwner(_tokenId);
        activeBid[_tokenId][_owner] = ActiveBid(
            payable(_owner),
            nafter.getServiceFee(_tokenId),
            _bidAmount
        );
        _setBidRange(_startTime, _endTime, _tokenId, _owner);

        emit SetInitialBidPriceWithRange(_bidAmount, _startTime, _endTime, _owner, _tokenId);
    }

    /////////////////////////////////////////////////////////////////////////
    // bid
    /////////////////////////////////////////////////////////////////////////
    /**
     * @dev Bids on the token, replacing the bid if the bid is higher than the current bid. You cannot bid on a token you already own.
     * @param _newBidAmount uint256 value in wei to bid.
     * @param _tokenId uint256 ID of the token
     * @param _owner address of the token owner
     */
    function bid(
        uint256 _newBidAmount,
        uint256 _tokenId,
        address _owner
    ) external payable {
        // Check that bid is greater than 0.
        require(_newBidAmount > 0, "bid::Cannot bid 0 Wei.");

        require(nafter.getIsForSale(_tokenId, _owner) == true, "bid::not for sale");

        // Check that bid is higher than previous bid
        uint256 currentBidAmount =
        activeBid[_tokenId][_owner].amount;
        require(
            _newBidAmount > currentBidAmount &&
            _newBidAmount >=
            currentBidAmount.add(
                currentBidAmount.mul(minimumBidIncreasePercentage).div(100)
            ),
            "bid::Must place higher bid than existing bid + minimum percentage."
        );

        // Check that enough ether was sent.
        uint256 requiredCost =
        _newBidAmount.add(
            _newBidAmount.mul(
                nafter.getServiceFee(_tokenId)
            ).div(100)
        );
        require(
            requiredCost <= msg.value,
            "bid::Must purchase the token for the correct price."
        );

        //Check bid range
        ActiveBidRange memory range = activeBidRange[_tokenId][_owner];
        uint8 priceType = nafter.getPriceType(_tokenId, _owner);

        require(priceType == 1 || priceType == 2, "bid is not valid for fixed sale");
        if (priceType == 1)
            require(range.startTime < block.timestamp && range.endTime > block.timestamp, "bid::can't place bid'");

        // Check that bidder is not owner.
        require(_owner != msg.sender, "bid::Bidder cannot be owner.");

        // Refund previous bidder.
        _refundBid(_tokenId, _owner);

        // Set the new bid.
        _setBid(_newBidAmount, msg.sender, _tokenId, _owner);
        nafter.setBid(_newBidAmount, msg.sender, _tokenId, _owner);
        emit Bid(msg.sender, _newBidAmount, _tokenId);
    }

    /////////////////////////////////////////////////////////////////////////
    // safeAcceptBid
    /////////////////////////////////////////////////////////////////////////
    /**
     * @dev Accept the bid on the token with the expected bid amount.
     * @param _tokenId uint256 ID of the token
     * @param _amount uint256 wei amount of the bid
     * @param _owner address of the token owner
     */
    function safeAcceptBid(
        uint256 _tokenId,
        uint256 _amount,
        address _owner
    ) external {
        // Make sure accepting bid is the expected amount
        require(
            activeBid[_tokenId][_owner].amount == _amount,
            "safeAcceptBid::Bid amount must equal expected amount"
        );
        acceptBid(_tokenId, _owner);
    }

    /////////////////////////////////////////////////////////////////////////
    // acceptBid
    /////////////////////////////////////////////////////////////////////////
    /**
     * @dev Accept the bid on the token.
     * @param _tokenId uint256 ID of the token
     * @param _owner address of the token owner
     */
    function acceptBid(uint256 _tokenId, address _owner) public {
        // The sender must be the token owner
        senderMustBeTokenOwner(_tokenId);

        // The owner of the token must have the marketplace approved
        ownerMustHaveMarketplaceApproved(_owner);


        // Check that a bid exists.
        require(
            _tokenHasBid(_tokenId, _owner),
            "acceptBid::Cannot accept a bid when there is none."
        );

        // Get current bid on token

        ActiveBid memory currentBid =
        activeBid[_tokenId][_owner];

        // Wipe the token price and bid.
        _resetTokenPrice(_tokenId, _owner);
        _resetBid(_tokenId, _owner);

        // Transfer token.
        erc1155.safeTransferFrom(msg.sender, currentBid.bidder, _tokenId, 1, '');

        // Payout all parties.
        address payable marketOwner = _makePayable(owner());
        Payments.payout(
            currentBid.amount,
            !iMarketplaceSettings.hasTokenSold(_tokenId),
            nafter.getServiceFee(_tokenId),
            iERC1155CreatorRoyalty.getTokenRoyaltyPercentage(
                _tokenId
            ),
            iMarketplaceSettings.getERC1155ContractPrimarySaleFeePercentage(),
            msg.sender,
            marketOwner,
            iERC1155CreatorRoyalty.tokenCreator(_tokenId),
            marketOwner
        );

        iMarketplaceSettings.markERC1155Token(_tokenId, true);
        uint256 serviceFee = currentBid.amount.mul(currentBid.marketplaceFee).div(100);
        bidBalance[currentBid.bidder] = bidBalance[currentBid.bidder].sub(currentBid.amount.add(serviceFee));

        //remove from sale after accepting the bid
        nafter.removeFromSale(_tokenId, _owner);
        emit AcceptBid(
            currentBid.bidder,
            msg.sender,
            currentBid.amount,
            _tokenId
        );
    }

    /////////////////////////////////////////////////////////////////////////
    // cancelBid
    /////////////////////////////////////////////////////////////////////////
    /**
     * @dev Cancel the bid on the token.
     * @param _tokenId uint256 ID of the token.
     * @param _owner address of the token owner
     */
    function cancelBid(uint256 _tokenId, address _owner) external {
        // Check that sender has a current bid.
        require(
            _addressHasBidOnToken(msg.sender, _tokenId, _owner),
            "cancelBid::Cannot cancel a bid if sender hasn't made one."
        );

        // Refund the bidder.
        _refundBid(_tokenId, _owner);

        emit CancelBid(
            msg.sender,
            activeBid[_tokenId][_owner].amount,
            _tokenId
        );
    }

    /////////////////////////////////////////////////////////////////////////
    // currentBidDetailsOfToken
    /////////////////////////////////////////////////////////////////////////
    /**
     * @dev Function to get current bid and bidder of a token.
     * @param _tokenId uin256 id of the token.
     * @param _owner address of the token owner
     */
    function currentBidDetailsOfToken(uint256 _tokenId, address _owner)
    public
    view
    returns (uint256, address)
    {
        return (
        activeBid[_tokenId][_owner].amount,
        activeBid[_tokenId][_owner].bidder
        );
    }

    /////////////////////////////////////////////////////////////////////////
    // _priceSetterStillOwnsTheToken
    /////////////////////////////////////////////////////////////////////////
    /**
     * @dev Checks that the token is owned by the same person who set the sale price.
     * @param _tokenId uint256 id of the.
     * @param _owner address of the token owner
     */
    function _priceSetterStillOwnsTheToken(
        uint256 _tokenId,
        address _owner
    ) internal view returns (bool) {

        return
        _owner ==
        salePrice[_tokenId][_owner].seller;
    }

    /////////////////////////////////////////////////////////////////////////
    // _resetTokenPrice
    /////////////////////////////////////////////////////////////////////////
    /**
     * @dev Internal function to set token price to 0 for a given contract.
     * @param _tokenId uin256 id of the token.
     * @param _owner address of the token owner
     */
    function _resetTokenPrice(uint256 _tokenId, address _owner)
    internal
    {
        salePrice[_tokenId][_owner] = SalePrice(address(0), 0);
    }

    /////////////////////////////////////////////////////////////////////////
    // _addressHasBidOnToken
    /////////////////////////////////////////////////////////////////////////
    /**
     * @dev Internal function see if the given address has an existing bid on a token.
     * @param _bidder address that may have a current bid.
     * @param _tokenId uin256 id of the token.
     * @param _owner address of the token owner
     */
    function _addressHasBidOnToken(
        address _bidder,
        uint256 _tokenId,
        address _owner)
    internal view returns (bool) {
        return activeBid[_tokenId][_owner].bidder == _bidder;
    }

    /////////////////////////////////////////////////////////////////////////
    // _tokenHasBid
    /////////////////////////////////////////////////////////////////////////
    /**
     * @dev Internal function see if the token has an existing bid.
     * @param _tokenId uin256 id of the token.
     * @param _owner address of the token owner
     */
    function _tokenHasBid(
        uint256 _tokenId,
        address _owner)
    internal
    view
    returns (bool)
    {
        return activeBid[_tokenId][_owner].bidder != address(0);
    }

    /////////////////////////////////////////////////////////////////////////
    // _refundBid
    /////////////////////////////////////////////////////////////////////////
    /**
     * @dev Internal function to return an existing bid on a token to the
     *      bidder and reset bid.
     * @param _tokenId uin256 id of the token.
     * @param _owner address of the token owner
     */
    function _refundBid(uint256 _tokenId, address _owner) internal {
        ActiveBid memory currentBid =
        activeBid[_tokenId][_owner];
        if (currentBid.bidder == address(0)) {
            return;
        }
        //current bidder should not be owner
        if (bidBalance[currentBid.bidder] > 0 && currentBid.bidder != _owner)
        {
            Payments.refund(
                currentBid.marketplaceFee,
                currentBid.bidder,
                currentBid.amount
            );
            //subtract bid balance
            uint256 serviceFee = currentBid.amount.mul(currentBid.marketplaceFee).div(100);

            bidBalance[currentBid.bidder] = bidBalance[currentBid.bidder].sub(currentBid.amount.add(serviceFee));
        }
        _resetBid(_tokenId, _owner);
    }

    /////////////////////////////////////////////////////////////////////////
    // _resetBid
    /////////////////////////////////////////////////////////////////////////
    /**
     * @dev Internal function to reset bid by setting bidder and bid to 0.
     * @param _tokenId uin256 id of the token.
     * @param _owner address of the token owner
     */
    function _resetBid(uint256 _tokenId, address _owner) internal {
        activeBid[_tokenId][_owner] = ActiveBid(
            address(0),
            0,
            0
        );
    }

    /////////////////////////////////////////////////////////////////////////
    // _setBid
    /////////////////////////////////////////////////////////////////////////
    /**
     * @dev Internal function to set a bid.
     * @param _amount uint256 value in wei to bid. Does not include marketplace fee.
     * @param _bidder address of the bidder.
     * @param _tokenId uin256 id of the token.
     * @param _owner address of the token owner
     */
    function _setBid(
        uint256 _amount,
        address payable _bidder,
        uint256 _tokenId,
        address _owner
    ) internal {
        // Check bidder not 0 address.
        require(_bidder != address(0), "Bidder cannot be 0 address.");

        // Set bid.
        activeBid[_tokenId][_owner] = ActiveBid(
            _bidder,
            nafter.getServiceFee(_tokenId),
            _amount
        );
        //add bid balance
        uint256 serviceFee = _amount.mul(nafter.getServiceFee(_tokenId)).div(100);
        bidBalance[_bidder] = bidBalance[_bidder].add(_amount.add(serviceFee));

    }

    /////////////////////////////////////////////////////////////////////////
    // _setBidRange
    /////////////////////////////////////////////////////////////////////////
    /**
     * @dev Internal function to set a bid range.
     * @param _startTime start time UTC.
     * @param _endTime end Time range.
     * @param _tokenId uin256 id of the token.
     */
    function _setBidRange(
        uint256 _startTime,
        uint256 _endTime,
        uint256 _tokenId,
        address _owner
    ) internal {
        activeBidRange[_tokenId][_owner] = ActiveBidRange(_startTime, _endTime);
    }

    /////////////////////////////////////////////////////////////////////////
    // _makePayable
    /////////////////////////////////////////////////////////////////////////
    /**
     * @dev Internal function to set a bid.
     * @param _address non-payable address
     * @return payable address
     */
    function _makePayable(address _address)
    internal
    pure
    returns (address payable)
    {
        return address(uint160(_address));
    }


}