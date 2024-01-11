//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;
import "./SafeMath.sol";
import "./Counters.sol";
import "./ReentrancyGuard.sol";
import "./IERC20.sol";

import "./TokenListManager.sol";
import "./PermissionManager.sol";
import "./IdOTC.sol";
import "./AdminFunctions.sol";
import "./IEscrow.sol";

contract DOTCManager is IdOTC, AdminFunctions, ReentrancyGuard {
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    Counters.Counter private _offerId;
    Counters.Counter private _takerOrdersId;

    /**
     *    @dev takerOrders this is store partial offer takers,
     *    ref the offerId  to the taker address and ref the amount paid
     */
    mapping(uint256 => Order) internal takerOrders;
    mapping(uint256 => Offer) internal allOffers;
    mapping(address => Offer[]) internal offersFromAddress;
    mapping(address => Offer[]) internal takenOffersFromAddress;

    // Event Of the DOTC SC

    event CreatedOffer(
        uint256 indexed offerId,
        address indexed maker,
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 amountOut,
        OfferType offerType,
        address specialAddress,
        bool isComplete,
        uint256 expiryTime
    );
    event CreatedOrder(
        uint256 indexed offerId,
        uint256 indexed orderId,
        uint256 amountPaid,
        address indexed orderedBy,
        uint256 amountToReceive
    );
    event CompletedOffer(uint256 offerId);
    event CanceledOffer(uint256 indexed offerId, address canceledBy, uint256 amountToReceive);
    event freezeOffer(uint256 indexed offerId, address freezedBy);
    event unFreezeOffer(uint256 indexed offerId, address unFreezedBy);
    event AdminRemoveOffer(uint256 indexed offerId, address freezedBy);
    event TokenOfferUpdated(uint256 indexed offerId, uint256 newOffer);
    event UpdatedTokenOfferExpiry(uint256 indexed offerId, uint256 newExpiryTimestamp);
    event NftOfferUpdated(uint256 indexed offerId, uint256 newOffer);
    event UpdatedNftOfferExpiry(uint256 indexed offerId, uint256 newExpiryTimestamp);

    constructor(address _tokenListManagerAddress, address _permission) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        tokenListManagerAddress = _tokenListManagerAddress;
        permissionAddress = _permission;
    }

    /**
     *  @dev makeOffer this create an Offer which can be sell or buy
     *  Requirements: msg.sender must be a Tier 2
     *  Requirements: _tokenInAddress and _tokenOutAddress must be allowed on swarm market
     *  @param  _amountOut uint256
     *  @param  _tokenInAddress address
     *  @param  _tokenOutAddress address
     *  @param  _amountIn uint256
     *  @param  _amountOut uint256
     *  @param  _expiryTimestamp uint256 in Days
     *  @param  _offerType uint8 is the offer PARTIAL or FULL
     *  @param _specialAddress special Adress of taker and if specified
     *  only this address can take the offer else anyone can take the offer
     *  @return offerId uint256
     */
    //  Address of specific taker
    function makeOffer(
        address _tokenInAddress,
        address _tokenOutAddress,
        uint256 _amountIn,
        uint256 _amountOut,
        uint256 _expiryTimestamp,
        uint8 _offerType,
        address _specialAddress
    )
        public
        allowedERC20Asset(_tokenInAddress)
        allowedERC20Asset(_tokenOutAddress)
        _accountIsTierTwo
        _accountSuspended
        nonReentrant
        returns (uint256 offerId)
    {
        require(IERC20(_tokenInAddress).balanceOf(msg.sender) >= (_amountIn), "Insufficient_balance");
        require(_expiryTimestamp > block.timestamp, "EXPIRATION_TIMESTAMP_HAS_PASSED");
        require(_tokenInAddress != _tokenOutAddress, "SAME_TOKEN");
        require(_offerType <= uint8(OfferType.FULL), "Out of range");
        require(_amountIn > 0, "ZERO_AMOUNTIN");
        require(_amountOut > 0, "ZERO_AMOUNTOUT");
        _offerId.increment();
        uint256 currentOfferId = _offerId.current();
        Offer memory _offer =
            setOffer(
                currentOfferId,
                _amountIn,
                _tokenInAddress,
                _tokenOutAddress,
                _amountOut,
                _expiryTimestamp,
                OfferType(_offerType),
                _specialAddress
            );
        offersFromAddress[msg.sender].push(_offer);
        allOffers[currentOfferId] = _offer;
        IEscrow(allOffers[currentOfferId].escrowAddress).setMakerDeposit(currentOfferId);
        safeTransfertokenIn(_tokenInAddress, _amountIn);
        emit CreatedOffer(
            currentOfferId,
            msg.sender,
            _tokenInAddress,
            _tokenOutAddress,
            _amountIn,
            _amountOut,
            OfferType(_offerType),
            _specialAddress,
            false,
            _offer.expiryTime
        );
        return currentOfferId;
    }

    /**
     * @dev returns a memory for order Structure
     */
    function setOffer(
        uint256 _currentOfferId,
        uint256 _amountIn,
        address _tokenInAddress,
        address _tokenOutAddress,
        uint256 _amountOut,
        uint256 _expiryTimestamp,
        OfferType _offerType,
        address _specialAddress
    ) internal view returns (Offer memory offer) {
        uint256 sandaradAmountIn = standardiseNumber(_amountIn, _tokenInAddress);
        uint256 sandaradAmountOut = standardiseNumber(_amountOut, _tokenOutAddress);
        uint256[] memory emptyArray;
        Offer memory _offer =
            Offer({
                isNft: false,
                offerId: _currentOfferId,
                maker: msg.sender,
                tokenInAddress: _tokenInAddress,
                tokenOutAddress: _tokenOutAddress,
                amountIn: sandaradAmountIn,
                availableAmount: sandaradAmountIn,
                expiryTime: _expiryTimestamp,
                unitPrice: sandaradAmountOut.mul(10**DECIMAL).div(sandaradAmountIn),
                amountOut: sandaradAmountOut,
                fullyTaken: false,
                offerType: _offerType,
                specialAddress: address(_specialAddress),
                escrowAddress: escrow,
                offerFee: feeAmount,
                nftIds: emptyArray, // list nft ids
                nftAddress: address(0),
                offerPrice: 0,
                nftAmounts: emptyArray
            });
        return _offer;
    }

    /**
     *  @dev takeOffer this take an Offer that is available
     *  Requirements: msg.sender must be a Tier 2
     *  @param  offerId uint256
     *  @param  _amount uint256
     */
    function takeOffer(
        uint256 offerId,
        uint256 _amount,
        uint256 minExpectedAmount
    )
        public
        _accountIsTierTwo
        _accountSuspended
        isSpecial(offerId)
        isAvailable(offerId)
        can_buy(offerId)
        nonReentrant
        returns (uint256 takenOderId)
    {
        uint256 amountToReceiveByTaker = 0;
        uint256 standardAmount = standardiseNumber(_amount, allOffers[offerId].tokenOutAddress);
        require(_amount > 0, "ZERO_AMOUNT");
        require(standardAmount <= allOffers[offerId].amountOut, "AMOUNT_IS_TOO_BIG");
        require(IERC20(allOffers[offerId].tokenOutAddress).balanceOf(msg.sender) >= _amount, "Insufficient balance");

        if (allOffers[offerId].offerType == OfferType.FULL) {
            require(standardAmount == allOffers[offerId].amountOut, "FULL_REQUEST_REQUIRED");
            amountToReceiveByTaker = allOffers[offerId].amountIn;
            allOffers[offerId].amountOut = 0;
            allOffers[offerId].availableAmount = 0;
            allOffers[offerId].fullyTaken = true;
            emit CompletedOffer(offerId);
        } else {
            if (standardAmount == allOffers[offerId].amountOut) {
                amountToReceiveByTaker = allOffers[offerId].availableAmount;
                allOffers[offerId].amountOut = 0;
                allOffers[offerId].availableAmount = 0;
                allOffers[offerId].fullyTaken = true;
                emit CompletedOffer(offerId);
            } else {
                amountToReceiveByTaker = standardAmount.mul(10**DECIMAL).div(allOffers[offerId].unitPrice);
                allOffers[offerId].amountOut -= standardAmount;
                allOffers[offerId].availableAmount -= amountToReceiveByTaker;
            }
            if (allOffers[offerId].amountOut == 0 || allOffers[offerId].availableAmount == 0) {
                allOffers[offerId].fullyTaken = true;
                emit CompletedOffer(offerId);
            }
        }
        takenOffersFromAddress[msg.sender].push(allOffers[offerId]);
        _takerOrdersId.increment();
        uint256 orderId = _takerOrdersId.current();
        takerOrders[orderId] = Order(
            offerId,
            _amount,
            msg.sender,
            amountToReceiveByTaker,
            standardiseNumber(minExpectedAmount, allOffers[offerId].tokenInAddress)
        );
        uint256 amountFeeRatio = _amount.mul(allOffers[offerId].offerFee).div(BPSNUMBER);
        IEscrow(allOffers[offerId].escrowAddress).withdrawDeposit(offerId, orderId);
        payFee(allOffers[offerId].tokenOutAddress, amountFeeRatio);
        safeTransferAsset(
            allOffers[offerId].tokenOutAddress,
            allOffers[offerId].maker,
            msg.sender,
            (_amount.sub(amountFeeRatio))
        );
        uint256 realAmount = unstandardisedNumber(amountToReceiveByTaker, allOffers[offerId].tokenInAddress);
        emit CreatedOrder(offerId, orderId, _amount, msg.sender, realAmount);
        return orderId;
    }

    /**
     *  @dev cancel an offer, refunds offer maker.
     *  @param offerId uint256 order id
     */
    function cancelOffer(uint256 offerId) external can_cancel(offerId) nonReentrant returns (bool success) {
        Offer memory offer = allOffers[offerId];
        delete allOffers[offerId];
        uint256 _amountToSend = offer.availableAmount;
        uint256 realAmount = unstandardisedNumber(_amountToSend, offer.tokenInAddress);
        require(_amountToSend > 0, "CAN'T_CANCEL");
        require(
            IEscrow(offer.escrowAddress).cancelDeposit(offerId, offer.tokenInAddress, offer.maker, realAmount),
            "Escrow:CAN'T_CANCEL"
        );
        emit CanceledOffer(offerId, msg.sender, _amountToSend);
        return true;
    }

    /**
     * @dev update offer amountOut
     * @param offerId uint256
     * @param newOffer uint256
     * @return status bool
     */
    function updateOffer(
        uint256 offerId,
        uint256 newOffer,
        uint256 _expiryTimestamp
    ) external returns (bool status) {
        require(newOffer > 0, "ZERO_NOT_ALLOWED");
        require(_expiryTimestamp > 0, "ZERO_NOT_ALLOWED");
        require(_expiryTimestamp > block.timestamp, "EXPIRATION_TIMESTAMP_HAS_PASSED");
        require(allOffers[offerId].maker == msg.sender, "NOT_OWNER");
        uint256 standardNewOfferOut = standardiseNumber(newOffer, allOffers[offerId].tokenOutAddress);
        if (standardNewOfferOut != allOffers[offerId].amountOut) {
            allOffers[offerId].amountOut = standardNewOfferOut;
            allOffers[offerId].unitPrice = standardiseNumber(newOffer, allOffers[offerId].tokenOutAddress)
                .mul(10**DECIMAL)
                .div(allOffers[offerId].availableAmount);
            emit TokenOfferUpdated(offerId, newOffer);
        }
        if (_expiryTimestamp != allOffers[offerId].expiryTime) {
            allOffers[offerId].expiryTime = _expiryTimestamp;
            emit UpdatedTokenOfferExpiry(offerId, _expiryTimestamp);
        }
        return true;
    }

    /**
        @dev getOfferOwner returns the address of the maker
        @param offerId uint256 the Id of the order
        @return owner address
     */
    function getOfferOwner(uint256 offerId) external view override returns (address owner) {
        return allOffers[offerId].maker;
    }

    /**
     *  @dev getTaker returns the address of the taker
     *  @param orderId uint256 the id of the order
     *  @return taker address
     */
    function getTaker(uint256 orderId) external view override returns (address taker) {
        return takerOrders[orderId].takerAddress;
    }

    /**
     *   @dev getOffer returns the Offer Struct of the offerId
     *   @param offerId uint256 the Id of the offer
     *   @return offer Offer
     */
    function getOffer(uint256 offerId) external view override returns (Offer memory offer) {
        return allOffers[offerId];
    }

    /**
     *   @dev getTakerOrders returns the Order Struct of the oreder_id
     *   @param orderId uint256
     *   @return order Order
     */
    function getTakerOrders(uint256 orderId) external view override returns (Order memory order) {
        return takerOrders[orderId];
    }

    /**
     *   @dev freezeXOffer this freeze a particular offer
     *   @param offerId uint256
     */
    function freezeXOffer(uint256 offerId) external isAdmin returns (bool hasfrozen) {
        if (IEscrow(escrow).freezeOneDeposit(offerId, msg.sender)) {
            emit freezeOffer(offerId, msg.sender);
            return true;
        }
        return false;
    }

    /**
     *   @dev adminRemoveOffer this freeze a particular offer
     *   @param offerId uint256
     */
    function adminRemoveOffer(uint256 offerId) external isAdmin returns (bool hasRemoved) {
        delete allOffers[offerId];
        if (IEscrow(escrow).removeOffer(offerId, msg.sender)) {
            emit AdminRemoveOffer(offerId, msg.sender);
            return true;
        }
        return false;
    }

    /**
     *   @dev unFreezeXOffer
     *   Requirement : caller must have admin role
     *   @param offerId uint256
     *   @return hasUnfrozen bool
     */
    function unFreezeXOffer(uint256 offerId) external isAdmin returns (bool hasUnfrozen) {
        if (IEscrow(escrow).unFreezeOneDeposit(offerId, msg.sender)) {
            emit unFreezeOffer(offerId, msg.sender);
            return true;
        }
        return false;
    }

    /**
     *  @dev getOffersFromAddress all offers from an account
     *  @param account address
     *  @return Offer[] memory
     */
    function getOffersFromAddress(address account) external view returns (Offer[] memory) {
        return offersFromAddress[account];
    }

    /**
     *  @dev getTakenOffersFromAddress all offers from an account
     *  @param account address
     *  @return Offer[] memory
     */
    function getTakenOffersFromAddress(address account) external view returns (Offer[] memory) {
        return takenOffersFromAddress[account];
    }

    /**
     *   @dev safeTransfer Asset revert transaction if failed
     *   @param token address
     *   @param amount uint256
     */
    function safeTransfertokenIn(address token, uint256 amount) internal {
        //checks
        require(amount > 0, "Amount is 0");
        //transfer to address
        require(IERC20(token).transferFrom(msg.sender, escrow, amount), "Transfer failed");
    }

    /**
     *   @dev safeTransfer Asset revert transaction if failed
     *   @param token address
     *   @param amount uint256
     */
    function payFee(address token, uint256 amount) internal {
        //checks
        require(amount > 0, "Amount is 0");
        //transfer to address
        require(IERC20(token).transferFrom(msg.sender, feeAddress, amount), "Transfer failed");
    }

    /**
     *   @dev safeTransferAsset Asset revert transaction if failed
     *   @param erc20Token address
     *   @param _to address
     *   @param _from address
     *   @param _amount address
     */
    function safeTransferAsset(
        address erc20Token,
        address _to,
        address _from,
        uint256 _amount
    ) internal {
        require(IERC20(erc20Token).transferFrom(_from, _to, _amount), "Transfer failed");
    }

    /**
     *    @dev isActive bool that checks if the expirydate is < now
     *    @param offerId uint256
     *    @return active bool
     */
    function isActive(uint256 offerId) public view returns (bool active) {
        return allOffers[offerId].expiryTime > block.timestamp;
    }

    function isWrapperedERC20(address token) internal view returns (bool wrapped) {
        return TokenListManager(tokenListManagerAddress).allowedErc20tokens(token) != 0;
    }

    function standardiseNumber(uint256 amount, address _token) internal view returns (uint256) {
        uint8 decimal = ERC20(_token).decimals();
        return amount.mul(BPSNUMBER).div(10**decimal);
    }

    function unstandardisedNumber(uint256 _amount, address _token) internal view returns (uint256) {
        uint8 decimal = ERC20(_token).decimals();
        return _amount.mul(10**decimal).div(BPSNUMBER);
    }

    /**
     *   @dev Asset is Approve on the Swarm DOTC Market
     *   @param tokenAddress address
     */
    modifier allowedERC20Asset(address tokenAddress) {
        require(isWrapperedERC20(tokenAddress), "Asset not allowed");
        _;
    }

    /**
        @dev can_buy check if an Order is Active
        @param offerId uint256
    */
    modifier can_buy(uint256 offerId) {
        require(isActive(offerId), "IN_ACTIVE_OFFER");
        _;
    }

    /**
     *   @dev checks if sender account is a tier on the swarm market protocol
     */
    modifier _accountIsTierTwo() {
        require(PermissionManager(permissionAddress).hasTier2(msg.sender), "NOT_ALLOWED_ON_THIS_PROTOCOL");
        _;
    }
    /**
     *   @dev checks if sender account is suspended on the swarm market protocol
     */
    modifier _accountSuspended() {
        require(!PermissionManager(permissionAddress).isSuspended(msg.sender), "Account is suspended");
        _;
    }
    /**
     *   @dev check if an offer can be cancled
     *   @param id uint256 id of the offer
     */

    modifier can_cancel(uint256 id) {
        require(allOffers[id].maker == msg.sender, "CAN'T_CANCEL");
        _;
    }

    /**
     *    @dev check if an offer is special Offer assigined to a particular user
     *   @param offerId uint256
     */
    modifier isSpecial(uint256 offerId) {
        if (allOffers[offerId].specialAddress != address(0)) {
            require(allOffers[offerId].specialAddress == msg.sender, "CAN'T_TAKE_OFFER");
        }
        _;
    }

    /**
     *   @dev check if the offer is available
     */
    modifier isAvailable(uint256 offerId) {
        require(allOffers[offerId].amountIn != 0, "Offer not found");
        _;
    }
}
