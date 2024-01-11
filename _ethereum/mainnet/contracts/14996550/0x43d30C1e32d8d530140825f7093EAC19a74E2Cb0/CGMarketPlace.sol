// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "./IMarket.sol";
import "./IUtils.sol";

import "./ECDSA.sol";

import "./IAccessControl.sol";
import "./AccessControl.sol";
import "./Strings.sol";
import "./Address.sol";
import "./SafeMath.sol";
import "./Pausable.sol";

import "./ERC721.sol";

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./ReentrancyGuard.sol";
import "./Counters.sol";


// Market Place Implementation
contract CGMarketPlaceContract is IMarket, AccessControl, Pausable {
    using SafeERC20 for IERC20;
    using Counters for Counters.Counter;
    Counters.Counter private _orderIds;
    Counters.Counter private _bidIds;

    address public _adminAddress = 0xAbb590532A0FA89F0DAB20f3C121712957A7976D; // CG VAULT ADDRESS For Commission

    // To store commission percentage for each mint
    uint8 private _adminCommissionPercentage = 25;

    // Mapping from token to the current ask for the token
    mapping(uint256 => IUtils.Order) private _orders;

    // Mapping from token to the current ask for the token
    mapping(uint256 => IUtils.Bid) private _bids;

    mapping(address => bool) public approvedCurrency;

    mapping(address => bool) public approvedNfts;


    uint256 private constant EXPO = 1e18;

    uint256 private constant BASE = 1000 * EXPO;

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    /**
    * Update Admin wallet where all commission will go.
    */
    function setAdminAddress(address _newAdminWallet) external override returns (bool) {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Caller is not a admin");
        require(_newAdminWallet != address(0), "Admin Wallet cannot be empty address");
        emit UpdateAdminWallet(_adminAddress, _newAdminWallet);
        _adminAddress = _newAdminWallet;
        return true;
    }


    // Get Current Order Id
    function getCurrentOrderId() public view returns (uint256) {
        return _orderIds.current();
    }

    // Get Current Bid Id
    function getCurrentBidId() public view returns (uint256) {
        return _bidIds.current();
    }

    /**
     * @dev Update Pause State
     */
    function setPauseStatus(bool _pauseStatus)
        external
        returns (bool)
    {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Caller is not a admin");
        if (_pauseStatus) {
             _pause();
        } else {
            _unpause();
        }
        return true;
    }

    /**
     * @dev See {IMarket}
     */
    function setCommissionPercentage(uint8 _commissionPercentage)
        external
        override
        returns (bool)
    {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Caller is not a admin");
        _adminCommissionPercentage = _commissionPercentage;
        emit CommissionUpdated(_adminCommissionPercentage);
        return true;
    }
    /**
     * @dev See {IMarket}
     */
    function updateCurrency(address _tokenAddress, bool _status) external override returns (bool) {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Caller is not a admin");
        approvedCurrency[_tokenAddress] = _status;
        return true;
    }

    /**
     * @dev See {IMarket}
     */
    function updateNFTContract(address _tokenAddress, bool _status) external override returns (bool) {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Caller is not a admin");
        approvedNfts[_tokenAddress] = _status;
        return true;
    }

    /**
     * @dev See {IMarket}
     */
    function getCommissionPercentage()
        external
        view
        override
        returns (uint8)
    {
        return _adminCommissionPercentage;
    } // end of function

    /**
     * @dev See {IMarket}
     */
    function setOrder(address _nftContract, uint256 _tokenId, address _currency, uint256 _askAmount, uint256 _expiryTime)
        whenNotPaused
        external
        override
    {

        _orderIds.increment();

        require(approvedNfts[_nftContract], "NFT is not approved by admin");
        require(approvedCurrency[_currency], "Currency is not approved by admin");
        require(_askAmount > 0, "Ask Amount Cannot be Zero");
        require(_expiryTime > block.timestamp, "Expiry Time cannot be in Past");
        ERC721 nftContract = ERC721(_nftContract);
        require(nftContract.ownerOf(_tokenId) == msg.sender, "You are not owner of Token Id");
        bool isAllTokenApproved = nftContract.isApprovedForAll(_msgSender(), address(this));
        address approvedSpenderOfToken = nftContract.getApproved(_tokenId);
        require((isAllTokenApproved || approvedSpenderOfToken == address(this)), "Market Contract is not allowed to manage this Token ID");

        uint256 currentOrderId = _orderIds.current();
        IUtils.Order storage order = _orders[currentOrderId];

        order.orderId = currentOrderId;
        order.sender = _msgSender();
        order.askAmount = _askAmount;
        order.currency = _currency;
        order.nftContract = _nftContract;
        order.tokenId = _tokenId;
        order.expiryTime = _expiryTime;
        order.orderStatus = IUtils.OrderStatus.OPEN;
        order.createdAt = block.timestamp;
        order.updatedAt = block.timestamp;

        emit OrderCreated(currentOrderId, order);
    } // end of create order


    /**
     * @dev See {IMarket}
     */
    function getOrder(uint256 _orderId)
        external
        override
        view
        returns (IUtils.Order memory) {
            return _orders[_orderId];
    }

    /**
     * @dev See {IMarket}
     */
    function cancelOrder(uint256 _orderId)
        whenNotPaused
        external
        override
        returns (bool) {
        IUtils.Order storage order = _orders[_orderId];
        
        require(order.sender != address(0), "Invalid Order Id");
        require(order.orderStatus == IUtils.OrderStatus.OPEN, "Order status is not Open");
        bool hasAdminRole = hasRole(DEFAULT_ADMIN_ROLE, _msgSender());
        require(order.sender == _msgSender() || hasAdminRole, "You Don't have right to cancel order");

        order.orderStatus = IUtils.OrderStatus.CANCELED;
        emit OrderRemoved(_orderId, order);
        return true;
    } // end of  cancel order

    /**
     * @dev See {IMarket}
     */
    function completeOrder(uint256 _orderId)
        whenNotPaused
        external
        override
        returns (bool) {

        IUtils.Order storage order = _orders[_orderId];
        
        require(order.sender != address(0), "Invalid Order Id");
        require(order.orderStatus == IUtils.OrderStatus.OPEN, "Order status is not Open");
        IERC20 token = IERC20(order.currency);
        ERC721 nft = ERC721(order.nftContract);
        require(block.timestamp <= order.expiryTime, "Order is expired");
        require(token.balanceOf(_msgSender()) >= order.askAmount, "Not enough funds available to buy");
        require(
            token.allowance(_msgSender(), address(this)) >= order.askAmount,
            "Please Approve Tokens Before You Buy"
        );


        uint256 _amountToDistribute = order.askAmount;
        uint256 adminCommission = (_amountToDistribute *
            (_adminCommissionPercentage * EXPO)) / (BASE);
        uint256 _amount = _amountToDistribute - adminCommission;

        token.safeTransferFrom(_msgSender(), _adminAddress, adminCommission);
        token.safeTransferFrom(_msgSender(), order.sender, _amount);
        nft.transferFrom(order.sender, _msgSender(), order.tokenId);

        order.orderStatus = IUtils.OrderStatus.COMPLETED;
        order.recipient = _msgSender();
        emit OrderCompleted(order.orderId, order);
        return true;
    } // end of function


    /**
     * @dev See {IMarket}
     */
    function getBid(uint256 _bidId)
        external
        override
        view
        returns (IUtils.Bid memory) {
            return _bids[_bidId];
    }

        /**
     * @dev See {IMarket}
     */
    function addBid(address _nftContract, uint256 _tokenId, address _currency, uint256 _bidAmount, uint256 _expiryTime)
        whenNotPaused
        external
        override
    {

        _bidIds.increment();

        require(approvedNfts[_nftContract], "NFT is not approved by admin");
        require(approvedCurrency[_currency], "Currency is not approved by admin");
        require(_bidAmount > 0, "Bid Amount Cannot be Zero");
        require(_expiryTime > block.timestamp, "Expiry Time cannot be in Past");
        
        ERC721 nft = ERC721(_nftContract);
        require(nft.ownerOf(_tokenId) != msg.sender, "You Can't Bid on your Own Token");

        IERC20 token = IERC20(_currency);
        require(token.balanceOf(_msgSender()) >= _bidAmount, "Not enough funds available to add bid");
        require(
            token.allowance(_msgSender(), address(this)) >= _bidAmount,
            "Please Approve Tokens Before You Bid"
        );

        uint256 currentBidId = _bidIds.current();
        IUtils.Bid storage bid = _bids[currentBidId];

        bid.bidId = currentBidId;
        bid.sender = _msgSender();
        bid.bidAmount = _bidAmount;
        bid.currency = _currency;
        bid.nftContract = _nftContract;
        bid.tokenId = _tokenId;
        bid.expiryTime = _expiryTime;
        bid.bidStatus = IUtils.OrderStatus.OPEN;
        bid.createdAt = block.timestamp;
        bid.updatedAt = block.timestamp;

        emit BidAdded(currentBidId, bid);
    } // end of create order

    /**
     * @dev See {IMarket}
     */
    function cancelBid(uint256 _bidId)
        whenNotPaused
        external
        override
        returns (bool) {
        IUtils.Bid storage bid = _bids[_bidId];
        
        require(bid.sender != address(0), "Invalid Bid Id");
        require(bid.bidStatus == IUtils.OrderStatus.OPEN, "Bid status is not Open");
        bool hasAdminRole = hasRole(DEFAULT_ADMIN_ROLE, _msgSender());

        ERC721 nft = ERC721(bid.nftContract);
        require(bid.sender == _msgSender() || nft.ownerOf(bid.tokenId) == _msgSender() || hasAdminRole, "You Don't have right to cancel order");

        bid.bidStatus = IUtils.OrderStatus.CANCELED;
        emit BidRemoved(_bidId, bid);
        return true;
    } // end of  cancel bid

    /**
     * @dev See {IMarket}
     */
    function acceptBid(uint256 _bidId)
        whenNotPaused
        external
        override
        returns (bool) {

        IUtils.Bid storage bid = _bids[_bidId];
        
        require(bid.sender != address(0), "Invalid Order Id");
        require(bid.bidStatus == IUtils.OrderStatus.OPEN, "Bid status is not Open");
        require(block.timestamp <= bid.expiryTime, "Bid is expired");

        IERC20 token = IERC20(bid.currency);
        ERC721 nft = ERC721(bid.nftContract);
        require(nft.ownerOf(bid.tokenId) == msg.sender, "You are not owner of Token Id");

        require(token.balanceOf(bid.sender) >= bid.bidAmount, "Bidder don't have Enough Funds");
        require(
            token.allowance(bid.sender, address(this)) >= bid.bidAmount,
            "Bidder has not Approved Tokens"
        );

        bool isAllTokenApproved = nft.isApprovedForAll(_msgSender(), address(this));
        address approvedSpenderOfToken = nft.getApproved(bid.tokenId);
        require((isAllTokenApproved || approvedSpenderOfToken == address(this)), "Market Contract is not allowed to manage this Token ID");

        uint256 _amountToDistribute = bid.bidAmount;
        uint256 adminCommission = (_amountToDistribute *
            (_adminCommissionPercentage * EXPO)) / (BASE);
        uint256 _amount = _amountToDistribute - adminCommission;

        nft.transferFrom(_msgSender(), bid.sender, bid.tokenId);
        token.safeTransferFrom(bid.sender, _adminAddress, adminCommission);
        token.safeTransferFrom(bid.sender, _msgSender(), _amount);

        bid.bidStatus = IUtils.OrderStatus.COMPLETED;
        bid.recipient = _msgSender();
        emit BidAccepted(bid.bidId, bid);
        return true;
    } // end of function
} // end of contract