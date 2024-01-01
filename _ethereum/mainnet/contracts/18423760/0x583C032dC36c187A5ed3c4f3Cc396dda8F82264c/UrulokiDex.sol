// SPDX-License-Identifier: UNLICENSED
// Uruloki DEX is NOT LICENSED FOR COPYING.
// Uruloki DEX (C) 2022. All Rights Reserved.

pragma solidity ^0.8.4;

import "./IERC20.sol";
import "./ReentrancyGuard.sol";

interface IUniswapV2Router {
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

    function getAmountsOut(
        uint amountIn,
        address[] calldata path
    ) external view returns (uint[] memory amounts);
}

interface IOrderMgr {
    //// Define enums
    enum OrderType {
        TargetPrice,
        PriceRange
    }
    enum OrderStatus {
        Active,
        Cancelled,
        OutOfFunds,
        Completed
    }

    //// Define structs
    // One time order, it's a base order struct
    struct OrderBase {
        address userAddress;
        address pairedTokenAddress;
        address tokenAddress;
        OrderType orderType;
        uint256 targetPrice;
        bool isBuy;
        uint256 maxPrice;
        uint256 minPrice;
        OrderStatus status;
        uint256 amount;
        uint256 predictionAmount;
        bool isContinuous;
    }

    // Continuous Order, it's an extended order struct, including the base order struct
    struct Order {
        OrderBase orderBase;
        uint256 numExecutions;
        uint256 resetPercentage;
        bool hasPriceReset;
    }

    function createOneTimeOrder(
        address userAddress,
        address pairedTokenAddress,
        address tokenAddress,
        bool isBuy,
        uint256 targetPrice,
        uint256 minPrice,
        uint256 maxPrice,
        uint256 amount,
        uint256 predictionAmount
    ) external returns (uint256);

    function createContinuousOrder(
        address userAddress,
        address pairedTokenAddress,
        address tokenAddress,
        bool isBuy,
        uint256 targetPrice,
        uint256 minPrice,
        uint256 maxPrice,
        uint256 amount,
        uint256 predictionAmount,
        uint256 resetPercentage
    ) external returns (uint256);

    function updateOrder(
        uint256 orderId,
        address pairedTokenAddress,
        address tokenAddress,
        bool isBuy,
        uint256 targetPrice,
        uint256 minPrice,
        uint256 maxPrice,
        uint256 amount,
        uint256 predictionAmount,
        uint256 resetPercentage
    ) external;

    function cancelOrder(uint256 orderId) external returns (uint256);

    function orderCounter() external view returns (uint256);

    function getOrder(uint256 orderId) external view returns (Order memory);

    function setOrderStatus(
        uint256 orderId,
        IOrderMgr.OrderStatus status
    ) external;

    function incNumExecutions(uint256 orderId) external;

    function setHasPriceReset(uint256 orderId, bool flag) external;
}

interface IERC20Ext is IERC20 {
    function decimals() external view returns (uint8);
}

contract UrulokiDEX is ReentrancyGuard {
    //// Define events
    event OneTimeOrderCreated(uint256 orderId);
    event ContinuousOrderCreated(uint256 orderId);
    event OneTimeOrderEdited(uint256 orderId);
    event ContinuousOrderEdited(uint256 orderId);
    event OrderCanceled(uint256 orderId);
    event ExecutedOutOfPrice(uint256 orderId, bool isBuy, uint256 price);
    event ExecutedOneTimeOrder(
        uint256 orderId,
        bool isBuy,
        uint256 pairAmount,
        uint256 tokenAmount,
        uint256 price
    );
    event ExecutedContinuousOrder(
        uint256 orderId,
        bool isBuy,
        uint256 price
    );
    event FundsWithdrawn(
        address userAddress,
        address tokenAddress,
        uint256 amount
    );
    event BackendOwner(address newOwner);
    event OutOfFunds(uint256 orderId);
    event SwapFailed(uint256 orderId);

    //// Define constants
    address private constant UNISWAP_V2_ROUTER =
        0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;

    //// Define variables
    mapping(address => mapping(address => uint256)) public balances;

    IUniswapV2Router private uniswapRouter =
        IUniswapV2Router(UNISWAP_V2_ROUTER);

    address public backend_owner;
    address public orderMgrAddress;
    IOrderMgr _orderMgr;

    constructor() {
        backend_owner = msg.sender;
    }

    modifier initOneTimeOrderBalance (
        uint256 orderId
    ) {
        IOrderMgr.Order memory order = _orderMgr.getOrder(orderId);

        // Validate order owner
        require(
            order.orderBase.userAddress == msg.sender,
            "msg.sender is not order owner"
        );

        // Is continous order
        require(order.orderBase.isContinuous == false, "Incorrect order type");
        require(order.orderBase.status == IOrderMgr.OrderStatus.Active, "Incorrect order status");

        if (!order.orderBase.isContinuous)
            if(!order.orderBase.isBuy) {
                balances[msg.sender][order.orderBase.tokenAddress] += order.orderBase.amount;
            } else {
                balances[msg.sender][order.orderBase.pairedTokenAddress] += order.orderBase.amount;
            }

        _;
    }

    function validateOneTimeOrder(
        address pairedTokenAddress,
        address tokenAddress,
        bool isBuy,
        uint256 amount
    ) internal returns (bool) {
        // if buying token, pair token is spendable else if sell, the token is spendable
        if (!isBuy) {
            // Check if the user has enough balance
            if(balances[msg.sender][tokenAddress] >= amount) {
                // Update the user's balance
                balances[msg.sender][tokenAddress] -= amount;
            } else 
                return false;
        } else {
            // Check if the user has enough balance
            if(balances[msg.sender][pairedTokenAddress] >= amount) {
                // Update the user's balance
                balances[msg.sender][pairedTokenAddress] -= amount;
            } else 
                return false;
        }

        return true;
    }

    // set backend owner address
    function setBackendOwner(address new_owner) public {
        require(msg.sender == backend_owner, "Not admin");
        backend_owner = new_owner;
        emit BackendOwner(backend_owner);
    }

    function setOrderMgr(address _orderMgrAddress) public {
        require(msg.sender == backend_owner, "setOrderMgr: not allowed");
        require(
            _orderMgrAddress != address(0),
            "setOrderMgr: invalid orderMgrAddress"
        );
        orderMgrAddress = _orderMgrAddress;
        _orderMgr = IOrderMgr(_orderMgrAddress);
    }

    /**
     * @notice allows users to make a deposit
     * @dev token should be transferred from the user wallet to the contract
     * @param tokenAddress token address
     * @param amount deposit amount
     */
    function addFunds(
        address tokenAddress,
        uint256 amount
    ) external nonReentrant {
        require(amount > 0, "Amount must be greater than zero");

        IERC20 token = IERC20(tokenAddress);
        uint256 balanceBefore = token.balanceOf(address(this));

        require(
            token.transferFrom(msg.sender, address(this), amount),
            "Transfer failed"
        );

        // Update the user's balance
        balances[msg.sender][tokenAddress] += token.balanceOf(address(this)) - balanceBefore;
    }

    /**
     * @dev funds withdrawal external call
     * @param tokenAddress token address
     * @param amount token amount
     */
    function withdrawFunds(
        address tokenAddress,
        uint256 amount
    ) external nonReentrant {
        require(amount > 0, "Amount must be greater than zero");

        // Check if the user has enough balance to withdraw
        require(
            balances[msg.sender][tokenAddress] >= amount,
            "Insufficient balance"
        );

        // Update the user's balance
        balances[msg.sender][tokenAddress] -= amount;

        // Transfer ERC20 token to the user
        IERC20 token = IERC20(tokenAddress);
        require(token.transfer(msg.sender, amount), "Transfer failed");
        // Emit event
        emit FundsWithdrawn(msg.sender, tokenAddress, amount);
    }

    /**
     * @notice create non-continuous price range order
     * @param pairedTokenAddress pair address
     * @param tokenAddress token address
     * @param isBuy buy or sell
     * @param minPrice minimum price
     * @param maxPrice maximum price
     * @param amount token amount
     * @param predictionAmount predictionAmount
     */
    function createNonContinuousPriceRangeOrder(
        address pairedTokenAddress,
        address tokenAddress,
        bool isBuy,
        uint256 minPrice,
        uint256 maxPrice,
        uint256 amount,
        uint256 predictionAmount
    )   external nonReentrant {
        require(validateOneTimeOrder(pairedTokenAddress, tokenAddress, isBuy, amount), "Validation failed");

        uint256 id = _orderMgr.createOneTimeOrder(
            msg.sender,
            pairedTokenAddress,
            tokenAddress,
            isBuy,
            0,
            minPrice,
            maxPrice,
            amount,
            predictionAmount
        );
        // Emit an event
        emit OneTimeOrderCreated(id);
    }

    /**
     * @notice creates a non-continuous order with a target price
     * @dev target price order is only executed when the market price is equal to the target price
     * @param pairedTokenAddress pair address
     * @param tokenAddress token address
     * @param targetPrice target price
     * @param isBuy buy or sell order
     * @param amount token amount
     * @param predictionAmount predictionAmount
     */
    function createNonContinuousTargetPriceOrder(
        address pairedTokenAddress,
        address tokenAddress,
        bool isBuy,
        uint256 targetPrice,
        uint256 amount,
        uint256 predictionAmount
    )   external nonReentrant {
        require(validateOneTimeOrder(pairedTokenAddress, tokenAddress, isBuy, amount), "Validation failed");

        // Create a new order
        uint256 id = _orderMgr.createOneTimeOrder(
            msg.sender,
            pairedTokenAddress,
            tokenAddress,
            isBuy,
            targetPrice,
            0,
            0,
            amount,
            predictionAmount
        );

        // Emit event
        emit OneTimeOrderCreated(id);
    }

    /**
     * @notice creates a continuous order with price range
     * @param pairedTokenAddress pair address
     * @param tokenAddress token address
     * @param isBuy buy or sell order
     * @param minPrice minimum price
     * @param maxPrice maximum price
     * @param amount token amount - this will be the amount of tokens to buy or sell, based on the token address provided
     * @param predictionAmount predictionAmount
     * @param resetPercentage decimal represented as an int with 2 places of precision
     */
    function createContinuousPriceRangeOrder(
        address pairedTokenAddress,
        address tokenAddress,
        bool isBuy,
        uint256 minPrice,
        uint256 maxPrice,
        uint256 amount,
        uint256 predictionAmount,
        uint256 resetPercentage
    ) external nonReentrant {
        uint256 id = _orderMgr.createContinuousOrder(
            msg.sender,
            pairedTokenAddress,
            tokenAddress,
            isBuy,
            0,
            minPrice,
            maxPrice,
            amount,
            predictionAmount,
            resetPercentage
        );

        // Emit an event
        emit ContinuousOrderCreated(id);
    }

    /**
     * @notice creates a continuous order with a target price
     * @param pairedTokenAddress pair address
     * @param tokenAddress token address
     * @param isBuy buy or sell order
     * @param targetPrice target price
     * @param amount token amount - this will be the amount of tokens to buy or sell, based on the token address provided
     * @param resetPercentage decimal represented as an int with 2 places of precision
     */
    function createContinuousTargetPriceOrder(
        address pairedTokenAddress,
        address tokenAddress,
        bool isBuy,
        uint256 targetPrice,
        uint256 amount,
        uint256 predictionAmount,
        uint256 resetPercentage
    ) external nonReentrant {
        // Create the ContinuousOrder struct
        uint256 id = _orderMgr.createContinuousOrder(
            msg.sender,
            pairedTokenAddress,
            tokenAddress,
            isBuy,
            targetPrice,
            0,
            0,
            amount,
            predictionAmount,
            resetPercentage
        );

        // Emit an event
        emit ContinuousOrderCreated(id);
    }

    /**
     * @dev cancel exist order
     * @param orderId order id
     */
    function cancelOrder(uint256 orderId) external {
        // Validate order owner
        IOrderMgr.Order memory order = _orderMgr.getOrder(orderId);
        require(
            order.orderBase.userAddress == msg.sender,
            "msg.sender is not order owner"
        );

        _orderMgr.cancelOrder(orderId);
        if (!order.orderBase.isContinuous)
            if (order.orderBase.isBuy) {
                balances[msg.sender][order.orderBase.pairedTokenAddress] += order
                    .orderBase
                    .amount;
            } else {
                balances[msg.sender][order.orderBase.tokenAddress] += order
                    .orderBase
                    .amount;
            }

        // Emit event
        emit OrderCanceled(orderId);
    }

    /**
     * @notice process a one-time order
     * @dev internal function
     * @param orderId id of the order
     */
    function _processOneTimeOrder(IOrderMgr.Order memory order, uint256 orderId) internal returns (bool) {
        // Get the price in amount
        uint256 price = _getPairPrice(
            order.orderBase.tokenAddress,
            order.orderBase.pairedTokenAddress,
            10 ** IERC20Ext(order.orderBase.tokenAddress).decimals()
        );
        address fromToken;
        address toToken;
        uint256 toAmount;
        bool swapStatus;

        // Check if the order type is PriceRange
        if (order.orderBase.orderType == IOrderMgr.OrderType.PriceRange) {
            if (
                order.orderBase.minPrice > price || price > order.orderBase.maxPrice
            ) {
                emit ExecutedOutOfPrice(orderId, order.orderBase.isBuy, price);
                return false;
            }
        }

        if (order.orderBase.isBuy) {
            // Check if the order type is TargetPrice
            if (order.orderBase.orderType == IOrderMgr.OrderType.TargetPrice) {
                if (
                    price > order.orderBase.targetPrice
                ) {
                    emit ExecutedOutOfPrice(orderId, order.orderBase.isBuy, price);
                    return false;
                }
            }
            fromToken = order.orderBase.pairedTokenAddress;
            toToken = order.orderBase.tokenAddress;
        } else {
            // Check if the order type is TargetPrice
            if (order.orderBase.orderType == IOrderMgr.OrderType.TargetPrice) {
                if (price < order.orderBase.targetPrice) {
                    emit ExecutedOutOfPrice(orderId, order.orderBase.isBuy, price);
                    return false;
                }
            }
            fromToken = order.orderBase.tokenAddress;
            toToken = order.orderBase.pairedTokenAddress;
        }

        (toAmount, swapStatus) = _swapTokens(
            fromToken, 
            toToken, 
            order.orderBase.amount,
            order.orderBase.predictionAmount
        );

        if(swapStatus) {
            balances[order.orderBase.userAddress][toToken] += toAmount;

            _orderMgr.setOrderStatus(orderId, IOrderMgr.OrderStatus.Completed);
            emit ExecutedOneTimeOrder(
                orderId,
                order.orderBase.isBuy,
                order.orderBase.amount,
                toAmount,
                price
            );

            return true;
        } else {
            emit SwapFailed(orderId);
            return false;
        }
    }

    /**
     * @notice process a continuous order
     * @dev internal function
     * @param orderId id of the order
     */
    function _processContinuousOrder(IOrderMgr.Order memory order, uint256 orderId) internal returns (bool){
        if (order.orderBase.targetPrice == 0) {
            // Price range order
            return _processContinuousPriceRangeOrder(order, orderId);
        } else {
            // Target price order
            return _processContinuousTargetPriceOrder(order, orderId);
        }
    }

    /**
     * @dev internal function to process a continuous price range order
     * @param order the order memory instance
     * @param orderId order id
     */
    function _processContinuousPriceRangeOrder(
        IOrderMgr.Order memory order,
        uint256 orderId
    ) internal returns(bool) {
        // Get the price in amount
        uint256 price = _getPairPrice(
            order.orderBase.tokenAddress,
            order.orderBase.pairedTokenAddress,
            10 ** IERC20Ext(order.orderBase.tokenAddress).decimals()
        );

        if (order.hasPriceReset) {
            if (
                !(
                price > order.orderBase.minPrice 
                && price < order.orderBase.maxPrice
                )
            ) {
                emit ExecutedOutOfPrice(orderId, order.orderBase.isBuy, price);
                return false;
            }
            address fromToken;
            address toToken;
            uint256 toAmount;
            bool swapStatus;

            if (order.orderBase.isBuy) {
                fromToken = order.orderBase.pairedTokenAddress;
                toToken = order.orderBase.tokenAddress;
            } else {
                fromToken = order.orderBase.tokenAddress;
                toToken = order.orderBase.pairedTokenAddress;
            }
            if (
                balances[order.orderBase.userAddress][fromToken] >=
                order.orderBase.amount
            ) {
                (toAmount, swapStatus) = _swapTokens(
                    fromToken,
                    toToken,
                    order.orderBase.amount,
                    order.orderBase.predictionAmount
                );

                if(swapStatus) {
                    balances[order.orderBase.userAddress][toToken] += toAmount;
                    balances[order.orderBase.userAddress][fromToken] -= order
                        .orderBase
                        .amount;

                    _orderMgr.setOrderStatus(orderId, IOrderMgr.OrderStatus.Active);
                    _orderMgr.incNumExecutions(orderId);
                    _orderMgr.setHasPriceReset(orderId, false);

                    emit ExecutedContinuousOrder(orderId, order.orderBase.isBuy, price);
                } else {
                    emit SwapFailed(orderId);
                }
            } else {
                _orderMgr.setOrderStatus(
                    orderId,
                    IOrderMgr.OrderStatus.OutOfFunds
                );
                emit OutOfFunds(orderId);
            }
        } else {
            uint256 lowerDiff = (order.orderBase.minPrice *
                order.resetPercentage) / 100;
            uint256 upperDiff = (order.orderBase.maxPrice *
                order.resetPercentage) / 100;

            if (
                !(price < order.orderBase.minPrice - lowerDiff
                || price > order.orderBase.maxPrice + upperDiff)
            ) {
                emit ExecutedOutOfPrice(orderId, order.orderBase.isBuy, price);
                return false;
            }
            _orderMgr.setHasPriceReset(orderId, true);
        }
        
        return true;
    }

    /**
     * @dev internal function to process a continuous target price order
     * @param order the order memory instance
     * @param orderId order id
     */
    function _processContinuousTargetPriceOrder(
        IOrderMgr.Order memory order,
        uint256 orderId
    ) internal returns (bool) {
        // Get the price in amount
        uint256 price = _getPairPrice(
            order.orderBase.tokenAddress,
            order.orderBase.pairedTokenAddress,
            10 ** IERC20Ext(order.orderBase.tokenAddress).decimals()
        );

        if (order.orderBase.isBuy) {
            if (order.hasPriceReset) {
                if (price > order.orderBase.targetPrice) {
                    emit ExecutedOutOfPrice(orderId, order.orderBase.isBuy, price);
                    return false;
                }
                address fromToken;
                address toToken;
                uint256 toAmount;
                bool swapStatus;

                fromToken = order.orderBase.pairedTokenAddress;
                toToken = order.orderBase.tokenAddress;

                if (
                    balances[order.orderBase.userAddress][fromToken] >=
                    order.orderBase.amount
                ) {
                    (toAmount, swapStatus) = _swapTokens(
                        fromToken,
                        toToken,
                        order.orderBase.amount,
                        order.orderBase.predictionAmount
                    );

                    if(swapStatus) {
                        balances[order.orderBase.userAddress][toToken] += toAmount;
                        balances[order.orderBase.userAddress][fromToken] -= order
                            .orderBase
                            .amount;

                        _orderMgr.setOrderStatus(
                            orderId,
                            IOrderMgr.OrderStatus.Active
                        );
                        _orderMgr.incNumExecutions(orderId);
                        _orderMgr.setHasPriceReset(orderId, false);

                        emit ExecutedContinuousOrder(orderId, order.orderBase.isBuy, price);
                    } else {
                        emit SwapFailed(orderId);
                    }
                } else {
                    _orderMgr.setOrderStatus(
                        orderId,
                        IOrderMgr.OrderStatus.OutOfFunds
                    );
                    emit OutOfFunds(orderId);
                }
            } else {
                uint256 diff = (order.orderBase.targetPrice *
                    order.resetPercentage) / 100;

                if (price < order.orderBase.targetPrice + diff) {
                    emit ExecutedOutOfPrice(orderId, order.orderBase.isBuy, price);
                    return false;
                }
                _orderMgr.setHasPriceReset(orderId, true);
            }
        } else {
            if (order.hasPriceReset) {
                if (price < order.orderBase.targetPrice) {
                    emit ExecutedOutOfPrice(orderId, order.orderBase.isBuy, price);
                    return false;
                }
                address fromToken;
                address toToken;
                uint256 toAmount;
                bool swapStatus;

                fromToken = order.orderBase.tokenAddress;
                toToken = order.orderBase.pairedTokenAddress;

                if (
                    balances[order.orderBase.userAddress][fromToken] >=
                    order.orderBase.amount
                ) {
                    (toAmount, swapStatus) = _swapTokens(
                        fromToken,
                        toToken,
                        order.orderBase.amount,
                        order.orderBase.predictionAmount
                    );

                    if(swapStatus) {
                        balances[order.orderBase.userAddress][toToken] += toAmount;
                        balances[order.orderBase.userAddress][fromToken] -= order
                            .orderBase
                            .amount;

                        _orderMgr.setOrderStatus(
                            orderId,
                            IOrderMgr.OrderStatus.Active
                        );
                        _orderMgr.incNumExecutions(orderId);
                        _orderMgr.setHasPriceReset(orderId, false);

                        emit ExecutedContinuousOrder(orderId, order.orderBase.isBuy, price);
                    } else {
                        emit SwapFailed(orderId);
                    }
                } else {
                    _orderMgr.setOrderStatus(
                        orderId,
                        IOrderMgr.OrderStatus.OutOfFunds
                    );
                    emit OutOfFunds(orderId);
                }
            } else {
                uint256 diff = (order.orderBase.targetPrice *
                    order.resetPercentage) / 100;

                if (price > order.orderBase.targetPrice - diff) {
                    emit ExecutedOutOfPrice(orderId, order.orderBase.isBuy, price);
                    return false;
                }
                _orderMgr.setHasPriceReset(orderId, true);
            }
        }
        
        return true;
    }

    function processOrders(uint256[] memory orderIds) external {
        IOrderMgr.Order memory order;
        for (uint256 i = 0; i < orderIds.length; i++) {
            order = _orderMgr.getOrder(orderIds[i]);
            uint256 orderId = orderIds[i];
            if (order.orderBase.tokenAddress == address(0))
                continue;

            if (order.orderBase.isContinuous == true) {
                if (order.orderBase.status == IOrderMgr.OrderStatus.Cancelled)
                    continue;
                _processContinuousOrder(order, orderId);
            } else {
                if (order.orderBase.status != IOrderMgr.OrderStatus.Active)
                    continue;
                _processOneTimeOrder(order, orderId);
            }
        }
    }

    function _swapTokens(
        address _fromTokenAddress,
        address _toTokenAddress,
        uint256 _amount,
        uint256 _predictionAmount
    ) internal returns (uint256 amount, bool status ) {
        IERC20 fromToken = IERC20(_fromTokenAddress);
        // Already transferred when adding Funds and deducted from balances when creating an order
        // fromToken.transferFrom(msg.sender, address(this), _amount);
        fromToken.approve(address(uniswapRouter), _amount);

        address[] memory path = new address[](2);
        path[0] = _fromTokenAddress;
        path[1] = _toTokenAddress;

        uint256 balanceBefore = IERC20(_toTokenAddress).balanceOf(address(this));
        
        try uniswapRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            _amount,
            _predictionAmount,
            path,
            address(this),
            block.timestamp
        ) {} catch (bytes memory) {
            return (0, false);
        }
        uint256 toAmount = IERC20(_toTokenAddress).balanceOf(address(this)) - balanceBefore;

        return (toAmount, true);
    }

    function _getPairPrice(
        address _fromTokenAddress,
        address _toTokenAddress,
        uint256 _amount
    ) internal view returns (uint256) {
        address[] memory path = new address[](2);
        path[0] = _fromTokenAddress;
        path[1] = _toTokenAddress;

        uint[] memory amountsOut = uniswapRouter.getAmountsOut(_amount, path);

        return amountsOut[1];
    }

    function getPairPrice(
        address _fromTokenAddress,
        address _toTokenAddress
    ) external view returns (uint256) {
        return
            _getPairPrice(
                _fromTokenAddress,
                _toTokenAddress,
                10 ** IERC20Ext(_fromTokenAddress).decimals()
            );
    }

    /*
     * @notice edit a continuous order with price range
     * @param orderId order id
     * @param pairedTokenAddress pair address
     * @param tokenAddress token address
     * @param isBuy buy or sell order
     * @param targetPrice target price
     * @param amount token amount - this will be the amount of tokens to buy or sell, based on the token address provided
     * @param resetPercentage decimal represented as an int with 2 places of precision
     */
    function editContinuousTargetPriceOrder(
        uint256 orderId,
        address pairedTokenAddress,
        address tokenAddress,
        bool isBuy,
        uint256 targetPrice,
        uint256 amount,
        uint256 predictionAmount,
        uint256 resetPercentage
    ) external {
        IOrderMgr.Order memory order = _orderMgr.getOrder(orderId);
        // Validate order owner
        require(
            order.orderBase.userAddress == msg.sender,
            "msg.sender is not order owner"
        );
        // Is continous order
        require(order.orderBase.isContinuous == true, "Incorrect order type");

        _orderMgr.updateOrder(
            orderId,
            pairedTokenAddress,
            tokenAddress,
            isBuy,
            targetPrice,
            0,
            0,
            amount,
            predictionAmount,
            resetPercentage
        );

        // Emit an event
        emit ContinuousOrderEdited(orderId);
    }

    /**
     * @notice edit a continuous order with price range
     * @param orderId order id
     * @param pairedTokenAddress pair address
     * @param tokenAddress token address
     * @param isBuy buy or sell order
     * @param minPrice minimum price
     * @param maxPrice maximum price
     * @param amount token amount - this will be the amount of tokens to buy or sell, based on the token address provided
     * @param resetPercentage decimal represented as an int with 2 places of precision
     */
    function editContinuousPriceRangeOrder(
        uint256 orderId,
        address pairedTokenAddress,
        address tokenAddress,
        bool isBuy,
        uint256 minPrice,
        uint256 maxPrice,
        uint256 amount,
        uint256 predictionAmount,
        uint256 resetPercentage
    ) external {
        IOrderMgr.Order memory order = _orderMgr.getOrder(orderId);
        // Validate order owner
        require(
            order.orderBase.userAddress == msg.sender,
            "msg.sender is not order owner"
        );
        // Is continous order
        require(order.orderBase.isContinuous == true, "Incorrect order type");

        _orderMgr.updateOrder(
            orderId,
            pairedTokenAddress,
            tokenAddress,
            isBuy,
            0,
            minPrice,
            maxPrice,
            amount,
            predictionAmount,
            resetPercentage
        );

        // Emit an event
        emit ContinuousOrderEdited(orderId);
    }

    /**
     * @notice edit non-continuous price range order
     * @param orderId order id
     * @param pairedTokenAddress pair address
     * @param tokenAddress token address
     * @param isBuy buy or sell
     * @param minPrice minimum price
     * @param maxPrice maximum price
     * @param amount token amount
     */
    function editNonContinuousPriceRangeOrder(
        uint256 orderId,
        address pairedTokenAddress,
        address tokenAddress,
        bool isBuy,
        uint256 minPrice,
        uint256 maxPrice,
        uint256 amount,
        uint256 predictionAmount
    ) 
        external
        nonReentrant
        initOneTimeOrderBalance(orderId)
    {
        require(validateOneTimeOrder(pairedTokenAddress, tokenAddress, isBuy, amount), "Validation failed");

        _orderMgr.updateOrder(
            orderId,
            pairedTokenAddress,
            tokenAddress,
            isBuy,
            0,
            minPrice,
            maxPrice,
            amount,
            predictionAmount,
            0
        );
        // Emit an event
        emit OneTimeOrderEdited(orderId);
    }

    /**
     * @notice edit a non-continuous order with a target price
     * @dev target price order is only executed when the market price is equal to the target price
     * @param orderId order id
     * @param pairedTokenAddress pair address
     * @param tokenAddress token address
     * @param targetPrice target price
     * @param isBuy buy or sell order
     * @param amount token amount
     */
    function editNonContinuousTargetPriceOrder(
        uint256 orderId,
        address pairedTokenAddress,
        address tokenAddress,
        uint256 targetPrice,
        bool isBuy,
        uint256 amount,
        uint256 predictionAmount
    ) 
        external
        nonReentrant
        initOneTimeOrderBalance(orderId)
    {
        require(validateOneTimeOrder(pairedTokenAddress, tokenAddress, isBuy, amount), "Validation failed");

        _orderMgr.updateOrder(
            orderId,
            pairedTokenAddress,
            tokenAddress,
            isBuy,
            targetPrice,
            0,
            0,
            amount,
            predictionAmount,
            0
        );

        // Emit event
        emit OneTimeOrderEdited(orderId);
    }
}
