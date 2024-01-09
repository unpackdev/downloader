// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./TransferHelper.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./KeeperCompatible.sol";
import "./ISphynxRouter.sol";
import "./ISphynxFactory.sol";

contract SphynxOrder is Ownable, ReentrancyGuard, KeeperCompatible {
    using SafeERC20 for IERC20;
    struct Order {
        uint256 id;
        uint256 amountA;
        uint256 amountB;
        address tokenA;
        address tokenB;
        address user;
        uint256 expiredAt;
        address router;
        bool isCanceled;
        bool isSuccessed;
    }

    struct OrderMatchHelper {
        address tokenA;
        address tokenB;
        uint256 tokenIn;
        uint256 tokenOut;
    }

    uint256 public currentOrderId;
    mapping(uint256 => Order) public orders;
    mapping(address => uint256[]) public userOrderIds;
    mapping(address => bool) public routers;
    uint256 public staticFee = 100000000000000000; // 0.1 BNB INITIAL FEE
    uint256 public sphynxFee = 100000000000000000000; // 100 SPHYNX TOKEN INITIAL FEE
    uint256 public maxTxPoolLength = 20; // Initial max Tx Length
    address public keepersRegistry; // Keepers Registry Contract address for performUpkeep
    address public sphynxToken;
    address payable public feeWallet;
    uint256[] public activeOrderIds;

    event OrderCreated(
        uint256 id,
        uint256 amountA,
        uint256 amountB,
        address tokenA,
        address tokenB,
        address owner,
        address router
    );
    event OrderCanceled(uint256 id);
    event RouterUpdated(address router, bool value);
    event FeeUpdated(uint256 fee);
    event OrderMatched(
        uint256 id,
        address token0,
        address token1,
        uint256 amount0,
        uint256 amount1
    );
    event FeeWalletUpdated(address newWallet);
    event SphynxTokenUpdated(address newSphynx);
    event SphynxFeeUpdated(uint256 newFee);
    event MaxTxPoolUpdated(uint256 newLength);
    event KeepersRegistryUpdated(address newKeepersRegistry);

    constructor() {
        feeWallet = payable(msg.sender);
    }

    function addRouter(address _router, bool _value) external onlyOwner {
        routers[_router] = _value;
        emit RouterUpdated(_router, _value);
    }

    function updatedFee(uint256 _value) external onlyOwner {
        staticFee = _value;
        emit FeeUpdated(_value);
    }

    function updateFeeWallet(address _feeWallet) external onlyOwner {
        feeWallet = payable(_feeWallet);
        emit FeeWalletUpdated(_feeWallet);
    }

    function updateSphynxToken(address _sphynx) external onlyOwner {
        sphynxToken = _sphynx;
        emit SphynxTokenUpdated(_sphynx);
    }

    function updateSphynxFee(uint256 _newFee) external onlyOwner {
        sphynxFee = _newFee;
        emit SphynxFeeUpdated(_newFee);
    }

    function updateMaxTxPoolLength(uint256 _newLength) external onlyOwner {
        maxTxPoolLength = _newLength;
        emit MaxTxPoolUpdated(_newLength);
    }

    function updateKeepersRegistry(address _keepersRegistry)
        external
        onlyOwner
    {
        keepersRegistry = _keepersRegistry;
        emit KeepersRegistryUpdated(_keepersRegistry);
    }

    function createOrder(
        uint256 _amountA,
        uint256 _amountB,
        address _tokenA,
        address _tokenB,
        uint256 _expiredAt,
        address _router,
        bool _isSphynxFee
    ) external payable nonReentrant {
        require(routers[_router], "not-router");
        address pair = ISphynxFactory(ISphynxRouter(_router).factory()).getPair(
            _tokenA,
            _tokenB
        );
        require(pair != address(0), "pair-does-not-exist");
        require(
            msg.value >= staticFee ||
                (_isSphynxFee && sphynxToken != address(0)),
            "insuffient-fee"
        );
        if (sphynxToken != address(0) && _isSphynxFee) {
            IERC20(sphynxToken).safeTransferFrom(
                msg.sender,
                feeWallet,
                sphynxFee
            );
        } else {
            feeWallet.transfer(msg.value);
        }
        Order memory newOrder;
        newOrder.id = currentOrderId;
        newOrder.amountA = _amountA;
        newOrder.amountB = _amountB;
        newOrder.tokenA = _tokenA;
        newOrder.tokenB = _tokenB;
        newOrder.user = msg.sender;
        newOrder.router = _router;
        newOrder.expiredAt = _expiredAt;
        orders[currentOrderId] = newOrder;
        activeOrderIds.push(currentOrderId);
        userOrderIds[msg.sender].push(currentOrderId);
        emit OrderCreated(
            currentOrderId,
            _amountA,
            _amountB,
            _tokenA,
            _tokenB,
            msg.sender,
            _router
        );
        currentOrderId++;
    }

    function _removeActiveOrderId(uint256 _orderId) internal {
        bool isRemoved = false;
        for (uint256 i = 0; i < activeOrderIds.length; i++) {
            if (activeOrderIds[i] == _orderId) {
                activeOrderIds[i] = orders[activeOrderIds.length - 1].id;
                activeOrderIds.pop();
                isRemoved = true;
                break;
            }
        }
        require(isRemoved, "not-exist-on-active-order-list"); // check if removed or not
    }

    function _removeOrderIds(uint256 _orderId) internal {
        uint256 i = 0;
        for (; i < userOrderIds[msg.sender].length; i++) {
            if (userOrderIds[msg.sender][i] == _orderId) {
                userOrderIds[msg.sender][i] = orders[
                    userOrderIds[msg.sender].length - 1
                ].id;
                userOrderIds[msg.sender].pop();
                break;
            }
        }
        _removeActiveOrderId(_orderId);
    }

    function _performOrders(uint256 _orderId) internal {
        Order memory currentOrder = orders[_orderId];
        orders[_orderId].isSuccessed = true;
        address[] memory path = new address[](2);
        path[0] = currentOrder.tokenA;
        path[1] = currentOrder.tokenB;
        address creator = currentOrder.user;
        IERC20 tokenAContract = IERC20(path[0]);
        tokenAContract.safeTransferFrom(
            creator,
            address(this),
            currentOrder.amountA
        );
        ISphynxRouter router = ISphynxRouter(currentOrder.router);
        tokenAContract.approve(
            currentOrder.router,
            tokenAContract.balanceOf(address(this))
        );
        router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            tokenAContract.balanceOf(address(this)),
            0,
            path,
            creator,
            block.timestamp + 120
        );
        emit OrderMatched(
            currentOrder.id,
            currentOrder.tokenA,
            currentOrder.tokenB,
            currentOrder.amountA,
            currentOrder.amountB
        );
        _removeActiveOrderId(_orderId);
    }

    function executeOrders(
        uint256[] memory _orderIds,
        uint256 _index,
        uint256[] memory matchOrderIds,
        uint256 matchedIndex
    ) public {
        require(msg.sender == address(this), "permission-denied");
        for (uint256 i = 0; i < _index; i++) {
            _removeActiveOrderId(_orderIds[i]);
        }
        for (uint256 j = 0; j < matchedIndex; j++) {
            _performOrders(matchOrderIds[j]);
        }
    }

    function checkUpkeep(bytes calldata)
        external
        view
        override
        returns (bool upkeepNeeded, bytes memory performData)
    {
        uint256[] memory expiredOrderIds = new uint256[](activeOrderIds.length);
        uint256[] memory matchOrderIds = new uint256[](activeOrderIds.length);
        OrderMatchHelper[] memory matchHelpers = new OrderMatchHelper[](
            activeOrderIds.length
        );
        uint256 matchedIndex;
        uint256 tokenIndex;
        uint256 expiredIndex;
        for (uint256 i = 0; i < activeOrderIds.length; i++) {
            if (expiredIndex + matchedIndex > maxTxPoolLength) {
                // check if it's reach max Tx length
                break;
            }
            Order memory currentOrder = orders[activeOrderIds[i]];
            ISphynxRouter router = ISphynxRouter(currentOrder.router);
            if (currentOrder.expiredAt < block.timestamp) {
                expiredOrderIds[expiredIndex] = activeOrderIds[i];
                expiredIndex++;
                continue;
            }
            bool tokenIndexFlag = false;
            uint256 curTokenIn;
            uint256 curTokenOut;
            uint256 curTokenIndex;
            address[] memory path = new address[](2);
            path[0] = currentOrder.tokenA;
            path[1] = currentOrder.tokenB;
            for (uint256 tokenKey = 0; tokenKey < tokenIndex; tokenKey++) {
                if (
                    matchHelpers[tokenKey].tokenA == path[0] &&
                    matchHelpers[tokenKey].tokenB == path[1]
                ) {
                    tokenIndexFlag = true;
                    curTokenIn = matchHelpers[tokenKey].tokenIn;
                    curTokenOut = matchHelpers[tokenKey].tokenOut;
                    curTokenIndex = tokenKey;
                    break;
                }
            }
            if (
                IERC20(path[0]).balanceOf(currentOrder.user) >=
                currentOrder.amountA
            ) {
                if (tokenIndexFlag) {
                    uint256[] memory amountsOut = router.getAmountsOut(
                        curTokenIn + currentOrder.amountA,
                        path
                    );
                    uint256 amountOut = amountsOut[1];
                    if (amountOut > currentOrder.amountB + curTokenOut) {
                        matchOrderIds[matchedIndex] = activeOrderIds[i];
                        matchedIndex++;
                        matchHelpers[curTokenIndex].tokenIn =
                            curTokenIn +
                            currentOrder.amountA;
                        matchHelpers[curTokenIndex].tokenOut =
                            curTokenOut +
                            currentOrder.amountB;
                    }
                } else {
                    uint256[] memory amountsOut = router.getAmountsOut(
                        currentOrder.amountA,
                        path
                    );
                    uint256 amountOut = amountsOut[1];
                    if (amountOut > currentOrder.amountB) {
                        matchOrderIds[matchedIndex] = activeOrderIds[i];
                        matchedIndex++;
                        matchHelpers[tokenIndex].tokenIn = currentOrder.amountA;
                        matchHelpers[tokenIndex].tokenOut = currentOrder
                            .amountB;
                        matchHelpers[tokenIndex].tokenA = currentOrder.tokenA;
                        matchHelpers[tokenIndex].tokenB = currentOrder.tokenB;
                        tokenIndex++;
                    }
                }
            }
        }

        if (expiredIndex > 0 || matchedIndex > 0) {
            upkeepNeeded = true;
            performData = abi.encodeWithSignature(
                "executeOrders(uint256[],uint256,uint256[],uint256)",
                expiredOrderIds,
                expiredIndex,
                matchOrderIds,
                matchedIndex
            );
        }
    }

    function performUpkeep(bytes calldata performData)
        external
        override
        nonReentrant
    {
        require(msg.sender == keepersRegistry, "not-keepers-registry");
        (bool success, ) = address(this).call(performData);
        require(success, "not-success");
    }

    function cancelOrder(uint256 _orderId) external nonReentrant {
        require(orders[_orderId].user == msg.sender, "not-an-owner");
        orders[_orderId].isCanceled = true;
        _removeOrderIds(_orderId);
        emit OrderCanceled(_orderId);
    }

    function getUserOrders() external view returns (Order[] memory) {
        Order[] memory userOrders = new Order[](
            userOrderIds[msg.sender].length
        );
        uint256 orderIndex;
        for (uint256 i = 0; i < userOrderIds[msg.sender].length; i++) {
            uint256 orderId = userOrderIds[msg.sender][i];
            userOrders[orderIndex] = orders[orderId];
            orderIndex++;
        }

        return userOrders;
    }
}
