// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./IERC20.sol";
import "./IERC20Metadata.sol";

import "./Initializable.sol";
import "./UUPSUpgradeable.sol";
import "./OwnableUpgradeable.sol";

import "./WardedLivingUpgradeable.sol";
import "./IDefexaExchange.sol";

import "./console.sol";

contract DefexaExchange is Initializable,
    UUPSUpgradeable, OwnableUpgradeable, WardedLivingUpgradeable,
    IDefexaExchange {

    // Order types
    uint8 constant ORDER_TYPE_GTC = 0;

    // Order statuses
    uint8 constant ORDER_STATUS_INVALID = 0;
    uint8 constant ORDER_STATUS_NEW = 1;
    uint8 constant ORDER_STATUS_CANCELLED = 2;
    uint8 constant ORDER_STATUS_FILLED = 3;
    uint8 constant ORDER_STATUS_PARTIALLY_FILLED = 4;

    mapping(uint256 => Order) public orders;

    uint256 public takerFee; //1e4; 100 means 1%; 10000 == 100%
    mapping(address => uint256) public feeGathered;

    address public feeCollector;

    // To generate unique order ids
    uint256 orderNonce;

    uint256 constant MAXIMUM_FEE = 1000;

    mapping(address => mapping(address => uint256)) public tokenWhitelist;
    mapping(uint256 => address) private orderRecipient;

    bool public useFixedFee;
    uint256 public minimumFee;
    uint256 public minimumGasPrice;

    function initialize(
        address _feeCollector,
        uint256 _takerFee,
        uint256 _minimumFee,
        uint256 _minGasPrice,
        bool _fixedFee
    ) public initializer {
        __Ownable_init();
        __WardedLiving_init();

        if (_feeCollector == address(0)) {
            revert FeeCollectorAddressInvalid();
        }
        feeCollector = _feeCollector;
        if (_takerFee > MAXIMUM_FEE) {
            revert TakerFeeTooHigh(_takerFee);
        }
        takerFee = _takerFee;

        useFixedFee = _fixedFee;//false;
        minimumFee = _minimumFee;//3000000;
        minimumGasPrice = _minGasPrice;//20 gwei;
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    receive() external payable {}


    /* @dev
    * Creates new limit order.
    * @param _baseToken address of the base token in the pair
    * @param _quoteToken address of the quote token in the pair
    * @param _baseToken address of the base token in the pair
    * @param _amount amount of baseToken token to be sold or bought if _isBuy flag is set
    * @param _price of baseToken vs quoteToken in the pair (18 decimals always)
    * @param _isBuy - boolean flag indicates if user wants to buy baseAsset or sell
    * @param _orderType - always 0. reserved for future use
    * @return new order id
    */
    function createOrder(
        address _baseToken,
        address _quoteToken,
        uint256 _amount,
        uint256 _price,
        bool _isBuy,
        uint8 _orderType
    ) external live payable override returns (uint256) {
        return createOrderWithRecipient(_baseToken, _quoteToken, _amount, _price, _isBuy, _orderType, address(0));
    }

    /* @dev
    * Same as createOrder but _recipient will receive asset instead of message signer
    */
    function createOrderWithRecipient(
        address _baseToken,
        address _quoteToken,
        uint256 _amount,
        uint256 _price,
        bool _isBuy,
        uint8 _orderType,
        address _recipient
    ) public live payable override returns (uint256) {
        if (_baseToken == _quoteToken) {
            revert TokensMismatch();
        }
        if (tokenWhitelist[_baseToken][_quoteToken] != 1) {
            revert TokenNotSupported();
        }
        if (_orderType != ORDER_TYPE_GTC) {
            revert OrderTypeNotSupported(_orderType);
        }
        if (_amount == 0 || _price == 0) {
            revert InvalidOrder();
        }
        if (_baseToken == address(0) && !_isBuy && msg.value != _amount) {
            revert InvalidOrder();
        }

        uint256 holdAmount = _amount;
        if (_isBuy) {
            uint8 baseTokenDecimals =  18;
            if (_baseToken != address(0)) {
                baseTokenDecimals = IERC20Metadata(_baseToken).decimals();
            }
            uint8 quoteTokenDecimals = IERC20Metadata(_quoteToken).decimals();
            uint8 diff = baseTokenDecimals - quoteTokenDecimals;
            holdAmount = _amount * _price / 1e18 / 10**diff;
        }

        if (holdAmount == 0) {
            revert InvalidOrder();
        }

        if (_baseToken != address(0)) {
            uint8 tokenDecimals = IERC20Metadata(_baseToken).decimals();
            if (tokenDecimals > 18) {
                revert TokenNotSupported();
            }
            if (tokenDecimals < 18) {
                uint8 diff = 18 - tokenDecimals;
                _amount = _amount * 10**diff;
            }
        }

        uint256 newId = uint256(keccak256(abi.encode(orderNonce, msg.sender, block.timestamp, _amount)));
        orderNonce++;

        orders[newId] = Order({
            id: newId,
            createdAt: block.timestamp,
            user: msg.sender,
            tokenA: _baseToken,
            tokenB: _quoteToken,
            amount: _amount,
            initialAmount: holdAmount,
            spentAmount: 0,
            price: _price,
            isBuy: _isBuy,
            orderType: _orderType,
            status: ORDER_STATUS_NEW
        });

        if (_recipient != address(0)) {
            orderRecipient[newId] = _recipient;
        } else {
            orderRecipient[newId] = msg.sender;
        }

//        console.log("Hold amount: ", holdAmount);
        address holdToken = _baseToken;
        if (_isBuy) {
            holdToken = _quoteToken;
        }
        if (holdToken != address(0)) {
            if (!IERC20(holdToken).transferFrom(msg.sender, address(this), holdAmount)) {
                revert TransferFailed();
            }
        }

        emit NewOrder(msg.sender, newId, _amount, _price, _baseToken, _quoteToken, block.timestamp, _isBuy, _orderType);

        return newId;
    }

    /* @dev
    * Cancel new or partially filled order.
    * Only order creator can cancel it
    */
    function cancelOrder(
        uint256 _orderId
    ) external live override {
        _checkOrderIsActive(_orderId);
        Order memory order = orders[_orderId];
        if (order.user != msg.sender) {
            revert Forbidden();
        }

        orders[_orderId].status = ORDER_STATUS_CANCELLED;

        uint256 leftover = order.initialAmount - order.spentAmount;
        if (order.isBuy) {
            _send(msg.sender, orders[_orderId].tokenB, leftover);
        } else {
            _send(msg.sender, orders[_orderId].tokenA, leftover);
        }

        emit OrderCanceled(msg.sender, _orderId, block.timestamp);
    }

    // @dev
    // match taker order with makers
    // maker orders should be ordered from the best price to worse
    function matchOrders(
        uint256[] memory _makers,
        uint256 _takerId
    ) public override auth {
        if (orders[_takerId].createdAt == 0) {
            revert OrderNotFound(_takerId);
        }
        _checkOrderIsActive(_takerId);

        for (uint256 i = 0; i < _makers.length; i++) {
            Order memory taker = orders[_takerId];
            Order memory maker = orders[_makers[i]];
            if (maker.createdAt == 0) {
                revert OrderNotFound(_makers[i]);
            }
            _checkOrderIsActive(_makers[i]);

            if ((maker.tokenA != taker.tokenA) ||
                (maker.tokenB != taker.tokenB)) {
                revert TokensMismatch();
            }
            if ((maker.isBuy && taker.isBuy) ||
                (!maker.isBuy && !taker.isBuy)) {
                revert InvalidOrder();
            }
            if (taker.amount == 0) {
                break;
            }
            _fill(maker, taker);
        }
    }

    /***** Admin functions ******/

    function setTakerFee(uint256 _newFee) external auth {
        if (_newFee > MAXIMUM_FEE) {
            revert TakerFeeTooHigh(_newFee);
        }
        takerFee = _newFee;
        emit TakerFeeUpdated(_newFee, block.timestamp);
    }

    function setFeeCollector(address _feeCollector) external auth {
        if (_feeCollector == address(0)) {
            revert FeeCollectorAddressInvalid();
        }
        feeCollector = _feeCollector;
        emit FeeCollectorUpdated(feeCollector, block.timestamp);
    }

    function stopExchange() external auth {
        stop();
    }

    function startExchange() external auth {
        run();
    }

    function whitelistPair(address _baseToken, address _quoteToken) external auth {
        tokenWhitelist[_baseToken][_quoteToken] = 1;
    }

    function blacklistPair(address _baseToken, address _quoteToken) external auth {
        tokenWhitelist[_baseToken][_quoteToken] = 0;
    }

    function setUseFixedFee(bool _use) external auth {
        useFixedFee = _use;
    }

    function setMinimumFee(uint256 _minFee) external auth {
        minimumFee = _minFee;
    }

    function setMinGasPrice(uint256 _minGasPrice) external auth {
        minimumGasPrice = _minGasPrice;
    }

    /***** Internal functions ******/

    function _fill(
        Order memory maker,
        Order memory taker
    ) internal {
        if (maker.isBuy) {
            if (1e18 > maker.price * 1e18 / taker.price) {
                revert PriceMismatch(maker.price, taker.price);
            }
        } else {
            if (1e18 > taker.price * 1e18 / maker.price ) {
                revert PriceMismatch(maker.price, taker.price);
            }
        }


        (uint256 makerAmount, uint256 makerQuote, uint256 takerAmount, uint256 takerQuote) =
                        _getAmountForPrice(maker, taker);

        uint256 takerToMaker = makerQuote;
        uint256 makerToTaker = takerQuote;

        if (maker.isBuy) {
            maker.amount -= takerToMaker;
            //gas saving
            orders[maker.id].amount -= takerToMaker;
        } else {
            maker.amount -= makerToTaker;
            //gas saving
            orders[maker.id].amount -= makerToTaker;
        }
        if (taker.isBuy) {
            taker.amount -= makerToTaker;
            orders[taker.id].amount -= makerToTaker;
        } else {
            taker.amount -= takerToMaker;
            orders[taker.id].amount -= takerToMaker;
        }

        address takerToken = taker.tokenA;
        address makerToken = maker.tokenB;
        if (!taker.isBuy) {
            takerToken = taker.tokenB;
            makerToken = maker.tokenA;
        }
//        console.log("1.Maker to taker ", makerToTaker);
//        console.log("1.Taker to maker ", takerToMaker);
        makerToTaker = makerToTaker / 10**(18 - _getDecimals(takerToken));
        takerToMaker = takerToMaker / 10**(18 - _getDecimals(makerToken));
//        console.log("2.Maker to taker ", makerToTaker);
//        console.log("2.Taker to maker ", takerToMaker);

        maker.spentAmount += makerToTaker;
        taker.spentAmount += takerToMaker;
        //gas saving
        orders[maker.id].spentAmount += makerToTaker;
        orders[taker.id].spentAmount += takerToMaker;

        _setOrderStatus(maker);
        _setOrderStatus(taker);

        uint256 fee = _takeFee(taker, makerToTaker, takerToken, maker.price);
        _returnLeftover(taker);
        _returnLeftover(maker);

        _send(_getRecipient(taker), takerToken, makerToTaker - fee);
        _send(_getRecipient(maker), makerToken, takerToMaker);

        _emitOrderFilled(maker, makerToTaker, takerToMaker);
        _emitOrderFilled(taker, takerToMaker, makerToTaker);
    }

    function _getRecipient(Order memory order) internal returns (address) {
        if (orderRecipient[order.id] != address(0)) {
            return orderRecipient[order.id];
        } else {
            return order.user;
        }
    }

    function _getDecimals(address token) internal view returns(uint256) {
        if (token == address(0)) {
            return 18;
        } else {
            return IERC20Metadata(token).decimals();
        }
    }

    function _getAmountForPrice(
        Order memory maker,
        Order memory taker
    ) internal pure returns(
        uint256 makerAmount, uint256 makerQuote, uint256 takerAmount, uint256 takerQuote) {
        makerAmount = maker.amount;
        makerQuote = maker.amount * maker.price / 1e18;
        if (maker.isBuy) {
            makerAmount = maker.amount * maker.price / 1e18;
            makerQuote = maker.amount;
        }

        takerAmount = taker.amount;
        takerQuote = taker.amount * maker.price / 1e18;
        if (taker.isBuy) {
            takerQuote = taker.amount;
            takerAmount = taker.amount * maker.price / 1e18;
        }

        if (makerQuote > takerAmount) {
            makerQuote = takerAmount;
        }
        if (takerQuote > makerAmount) {
            takerQuote = makerAmount;
        }
    }

    function _checkOrderIsActive(uint256 _orderId) internal view {
        if (
            orders[_orderId].status != ORDER_STATUS_NEW &&
            orders[_orderId].status != ORDER_STATUS_PARTIALLY_FILLED
        ) {
            revert OrderStatusInvalid(orders[_orderId].status);
        }
    }

    function _send(address receiver, address token, uint256 amount) internal {
        if (amount == 0) {
            return;
        }
        if (token == address(0)) {
            payable(receiver).transfer(amount);
        } else {
            if (!IERC20(token).transfer(receiver, amount)) {
                revert TransferFailed();
            }
        }
    }

    function _returnLeftover(Order memory taker) internal returns(uint256 leftover) {
        leftover = 0;
        if (taker.isBuy && taker.amount == 0) {
            leftover = taker.initialAmount - taker.spentAmount;
            _send(taker.user, taker.tokenB, leftover);

            emit LeftoverReturned(taker.user, taker.id, taker.tokenB, leftover, block.timestamp);
        }
    }

    //
    /// @dev Gathers fee from the taker
    /// @return fee collected with 1e18 precision
    //
    function _takeFee(
        Order memory _taker,
        uint256 _takerAmount,
        address _token,
        uint256 _price
    ) internal returns (uint256) {
        uint256 fee = _calcFee(_takerAmount, _price, _taker.isBuy);
        feeGathered[_token] += fee;

        _send(feeCollector, _token, fee);

        emit FeeGathered(_taker.user, _taker.id, _token, fee, block.timestamp);
        return fee;
    }

    function _setOrderStatus(Order memory order) internal {
        if (order.amount == 0) {
            orders[order.id].status = ORDER_STATUS_FILLED;
        } else {
            orders[order.id].status = ORDER_STATUS_PARTIALLY_FILLED;
        }
    }

    function _emitOrderFilled(Order memory order, uint256 amountSent, uint256 amountReceived) internal {
        if (order.amount == 0) {
            emit OrderFilled(order.id, amountSent, amountReceived, block.timestamp);
        } else {
            emit OrderFilledPartially(order.id, amountSent, amountReceived, block.timestamp);
        }
    }

    function _calcFee(uint256 _amount, uint256 _price, bool _isBuy) internal view returns(uint256 fee) {
        fee = 0;
        if (useFixedFee) {
            uint256 gasPrice = tx.gasprice;
            fee = gasPrice * 100 / minimumGasPrice * minimumFee / 100;
            if (fee < minimumFee) {
                fee = minimumFee;
            }
            if (_isBuy) {
                fee = fee * 1e18 / _price;
            }
        } else {
            if (takerFee > 0) {
                fee = _amount * takerFee / 1e4;
            }
        }
        if (fee > _amount) {
            fee = _amount;
        }
    }
}
