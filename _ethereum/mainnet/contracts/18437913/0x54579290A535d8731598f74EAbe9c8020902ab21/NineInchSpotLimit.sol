// SPDX-License-Identifier: GPLv3
pragma solidity ^0.8.19;

import "./Ownable.sol";
import "./IERC20.sol";
import "./IERC20Metadata.sol";
import "./SafeERC20.sol";
import "./SafeMath.sol";
import "./SafeCast.sol";
import "./EnumerableSet.sol";
import "./ReentrancyGuard.sol";
import "./Pausable.sol";
import "./AutomationCompatible.sol";
import "./AutomationRegistryInterface2_0.sol";
import "./INineInchRouter02.sol";

/**
 * @title NineInchSpotLimit
 * @notice It allows to create programmed swaps at a certain price, each order costs credits that, depending on the credits, increase the time of the open order.
 * The accepted token to buy credits is LINK (Chainlink ERC 677), the amount of LINK is used to fund the keeper and execute the order
 */
contract NineInchSpotLimit is
    AutomationCompatible,
    ReentrancyGuard,
    Pausable,
    Ownable
{
    //---------- Libraries ----------//
    using SafeMath for uint256;
    using SafeCast for uint256;
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.Bytes32Set;

    //---------- Contracts ----------//
    AutomationRegistryInterface private immutable automationRegistryInterface; //Keeper registry contract.
    INineInchRouter02 private nineInchRouter; // JamonSwap Router contract.
    IERC20 private immutable link; // LINK (Chainlink ERC 677) contract.
    IERC20 private immutable nineInch; // 9inch token contract.

    //---------- Variables ----------//
    uint256 public creditPrice; // Price of credit in link.
    uint256 public keeperId; // Keeper ID to check and perform orders.
    uint256 public creditTime; // Time per credit to keep an open order.
    bool public returnCredit; // Allow or not to return 1 credit when canceling.

    //---------- Storage -----------//
    struct Order {
        uint256 targetPrice;
        uint256 amountIn;
        address[] path;
        address user;
        uint16 slippage;
        uint256 deadline;
    }

    mapping(bytes32 => Order) private orderBook; // Mapping from orderId to order.
    EnumerableSet.Bytes32Set private orderIndex; // Mapping of ids of orders.
    mapping(address => uint256) public credits; // Mapping of credits balances.

    //---------- Events -----------//
    event OrderCreated(
        bytes32 indexed orderId,
        uint256 currentPrice,
        uint256 targetPrice,
        uint256 amountIn,
        address tokenIn,
        address tokenOut,
        address indexed user,
        uint16 slippage,
        uint256 deadline
    );
    event OrderCancelled(bytes32 indexed orderId);
    event OrderExpired(bytes32 indexed orderId);
    event OrderFilled(bytes32 indexed orderId, uint256 executionPrice);
    event OrderFailed(bytes32 indexed orderId);
    event BoughtCredit(address indexed wallet, uint256 amount);
    event TransferCredit(
        address indexed from,
        address indexed to,
        uint256 amount
    );

    //---------- Constructor ----------//
    constructor(
        address automationRegistryAddress,
        address routerAddress,
        address linkAddress,
        address nineInchAddress
    ) {
        automationRegistryInterface = AutomationRegistryInterface(
            automationRegistryAddress // 0xE16Df59B887e3Caa439E0b29B42bA2e7976FD8b2 sepolia
        );
        nineInchRouter = INineInchRouter02(routerAddress);
        link = IERC20(linkAddress); // 0x779877A7B0D9E8603169DdbD7836e478b4624789 // sepolia
        nineInch = IERC20(nineInchAddress);
        creditPrice = 0.20 ether; // link
        creditTime = 7 days;
        returnCredit = true;
    }

    //---------- Modifiers ----------//
    /**
     * @dev Reverts if the caller is not a keeper.
     */
    modifier onlyKeeper() {
        require(
            _msgSender() == address(automationRegistryInterface),
            "Only Keeper Registry"
        );
        _;
    }

    /**
     * @dev Reverts if keeper is not active.
     */
    modifier onlyOnKeeperActive() {
        UpkeepInfo memory upkeepInfo = automationRegistryInterface.getUpkeep(
            keeperId
        );
        require(upkeepInfo.target == address(this), "Uninitialized keeper");
        _;
    }

    //----------- Internal Functions -----------//
    /**
     * @dev Convert two address in address array.
     * @param tokenA First address.
     * @param tokenB Last address.
     * @return address[] path.
     */
    function _getPath(
        address tokenA,
        address tokenB
    ) private pure returns (address[] memory) {
        address[] memory path = new address[](2);
        path[0] = tokenA;
        path[1] = tokenB;
        return path;
    }

    /**
     * @dev Register an order and index it.
     * @param orderId Order Identity.
     * @param price Price at which the order is executed.
     * @param amountIn Amount to swap.
     * @param path Path to be performed by the swap.
     * @param user Address of the order maker.
     * @param slippage Swap tolerance percentage.
     * @param deadline Expiration date if the order is not executed.
     */
    function _createOrder(
        bytes32 orderId,
        uint256 price,
        uint256 amountIn,
        address[] calldata path,
        address user,
        uint16 slippage,
        uint256 deadline
    ) private {
        Order memory newOrder = Order(
            price,
            amountIn,
            path,
            user,
            slippage,
            deadline
        );
        orderIndex.add(orderId);
        orderBook[orderId] = newOrder;
    }

    /**
     * @dev Cancel a existent order.
     * @param orderId Order Identity.
     */
    function _deleteOrder(bytes32 orderId) private {
        orderIndex.remove(orderId);
        delete orderBook[orderId];
    }

    /**
     * @dev Return funds if the order execution fails.
     * @param amount Amount to return.
     * @param token Address of the asset.
     * @param user Address of the order maker.
     */
    function _forceFail(uint256 amount, address token, address user) private {
        //Interactions
        if (token == address(nineInchRouter.WETH())) {
            (bool success, ) = payable(user).call{value: amount}("");
            require(success, "Transfer failed");
        } else {
            IERC20 _token = IERC20(token);
            _token.safeTransfer(user, amount);
        }
    }

    /**
     * @dev Perform a swap once the target price is reached.
     * @param orderId Order Identity.
     * @param amountIn Amount to swap.
     * @param path Path to be performed by the swap.
     * @param user Address of the order maker.
     * @param amountOutMin Minimum amount of tokens accepted to not revert.
     */
    function _performSwap(
        bytes32 orderId,
        uint256 amountIn,
        address[] memory path,
        address user,
        uint256 amountOutMin
    ) private {
        address WETH = nineInchRouter.WETH();
        address tokenIn = path[0];
        address tokenOut = path[path.length - 1];
        if (tokenIn == WETH) {
            try
                nineInchRouter.swapExactETHForTokens{value: amountIn}(
                    amountOutMin,
                    path,
                    user,
                    block.timestamp.add(300)
                )
            returns (uint256[] memory amounts) {
                emit OrderFilled(orderId, amounts[path.length - 1]);
            } catch {
                _forceFail(amountIn, tokenIn, user);
                emit OrderFailed(orderId);
            }
        } else if (tokenOut == WETH) {
            try
                nineInchRouter.swapExactTokensForETH(
                    amountIn,
                    amountOutMin,
                    path,
                    payable(user),
                    block.timestamp.add(300)
                )
            returns (uint256[] memory amounts) {
                emit OrderFilled(orderId, amounts[path.length - 1]);
            } catch {
                _forceFail(amountIn, tokenIn, user);
                emit OrderFailed(orderId);
            }
        } else {
            try
                nineInchRouter.swapExactTokensForTokens(
                    amountIn,
                    amountOutMin,
                    path,
                    user,
                    block.timestamp.add(300)
                )
            returns (uint256[] memory amounts) {
                emit OrderFilled(orderId, amounts[path.length - 1]);
            } catch {
                _forceFail(amountIn, tokenIn, user);
                emit OrderFailed(orderId);
            }
        }
    }

    /**
     * @dev Calculate the amount of digits in a number.
     * @param number Number to check.
     * @return uint256 amount of difits.
     */
    function _numDigits(uint256 number) private pure returns (uint256) {
        uint256 digits = 0;
        while (number != 0) {
            number /= 10;
            digits++;
        }
        return digits;
    }

    /**
     * @dev Calculate the number of pages in proportion to 100 orders per page.
     * @return book_ amount of pages.
     * @return digitpage_ difits of pages.
     */
    function _getPagination()
        private
        view
        returns (uint256 book_, uint256 digitpage_)
    {
        uint256 _book = orderIndex.length().div(100);
        uint256 remainder = _book.mul(100);
        _book = remainder < orderIndex.length() ? _book.add(1) : _book;
        return (_book, _numDigits(_book));
    }

    //----------- External Functions -----------//
    /**
     * @notice Show the number of total open orders.
     * @return The number of orders.
     */
    function totalOrders() external view returns (uint256) {
        return orderIndex.length();
    }

    /**
     * @notice Show the order in the searched index.
     * @param index Index number for query.
     * @return The id of the order.
     */
    function getOrderAt(uint256 index) external view returns (bytes32) {
        return orderIndex.at(index);
    }

    /**
     * @notice Show data of the order.
     * @param orderId ID for query.
     * @return The data of the order.
     */
    function getOrder(bytes32 orderId) external view returns (Order memory) {
        require(orderIndex.contains(orderId), "Query for nonexistent order");
        return orderBook[orderId];
    }

    /**
     * @notice Show the amounts out of path.
     * @param amountIn Amount to query.
     * @param path Path to query.
     * @return If exist and the amount out.
     */
    function getPrice(
        uint256 amountIn,
        address[] memory path
    ) public view returns (bool, uint256) {
        try nineInchRouter.getAmountsOut(amountIn, path) returns (
            uint256[] memory result
        ) {
            return (true, result[path.length - 1]);
        } catch {
            return (false, 0);
        }
    }

    function creditPriceIn9Inch(
        uint256 numCredits
    ) public view returns (uint256) {
        // calculate required amount of eth for buy required linkAmount
        uint256 linkAmount = creditPrice.mul(numCredits);
        uint256 nineInchAmount = nineInchRouter.getAmountsIn(
            linkAmount,
            _getPath(address(nineInch), address(link))
        )[0];
        return nineInchAmount;
    }

    /**
     * @notice Show the start and end index for the keeper query, these indexes change according to the block number.
     * This function is implemented so that keepers can read all open orders and not have a reduced limit.
     * @return start index to check.
     * @return end index to check.
     */
    function getBatch() public view returns (uint256 start, uint256 end) {
        if (orderIndex.length() != 0) {
            (uint256 pages, uint256 batchDigits) = _getPagination();
            uint256 blockTens = block.number.div(10);
            uint256 underBlock = blockTens.div(10 ** batchDigits);
            uint256 overBlock = underBlock.mul(10 ** batchDigits);
            uint256 result = blockTens.sub(overBlock);
            result = result == 0 ? 1 : result;
            while (result > pages) {
                result -= pages;
            }
            uint256 start_ = result.sub(1).mul(100);
            uint256 end_ = result.mul(100) > orderIndex.length()
                ? orderIndex.length()
                : result.mul(100);
            return (start_, end_);
        }
        return (0, 0);
    }

    /**
     * @notice Create new order.
     * @param targetPrice_ Price at which the order is executed.
     * @param amountIn_ Amount to swap.
     * @param path_ Path to be performed by the swap.
     * @param slippage_ Swap tolerance percentage.
     * @param credits_ Amount of credits to use.
     */
    function createOrder(
        uint256 targetPrice_,
        uint256 amountIn_,
        address[] calldata path_,
        uint16 slippage_,
        uint256 credits_
    ) external payable whenNotPaused nonReentrant onlyOnKeeperActive {
        //Checks
        require(slippage_ <= 10000, "Slippage out of bound");
        require(amountIn_ != 0, "Zero amount in");
        require(targetPrice_ > 0 && credits_ > 0, "Zero price");
        require(path_.length >= 2, "Invalid path");
        uint256 targetPrice = targetPrice_;
        uint256 amountIn = amountIn_;
        uint256 _credits = credits_;
        address[] calldata path = path_;
        address tokenIn = path[0];
        address tokenOut = path[path_.length - 1];
        uint16 slippage = slippage_;
        address user = _msgSender();
        require(
            tokenIn != address(0x0) &&
                tokenOut != address(0x0) &&
                tokenIn != tokenOut,
            "Invalid tokens"
        );

        // buy credits if user has not enough
        if (credits[_msgSender()] < _credits) {
            uint256 requiredCredits = _credits.sub(credits[_msgSender()]);
            uint256 required9InchAmount = creditPriceIn9Inch(requiredCredits);

            require(
                nineInch.allowance(user, address(this)) >= required9InchAmount,
                "Insufficient 9inch allowance"
            );
            nineInch.safeTransferFrom(user, address(this), required9InchAmount);

            if (tokenIn == address(nineInchRouter.WETH())) {
                require(
                    msg.value >= amountIn,
                    "Insufficient eth value for swap"
                );
            }

            nineInch.approve(address(nineInchRouter), required9InchAmount);

            nineInchRouter
                .swapExactTokensForTokensSupportingFeeOnTransferTokens(
                    required9InchAmount,
                    0,
                    _getPath(address(nineInch), address(link)),
                    address(this),
                    block.timestamp.add(300)
                );

            if (
                link.allowance(
                    address(this),
                    address(automationRegistryInterface)
                ) == 0
            ) {
                link.approve(address(automationRegistryInterface), ~uint256(0));
            }
            automationRegistryInterface.addFunds(
                keeperId,
                creditPrice.mul(requiredCredits).toUint96()
            );

            unchecked {
                credits[_msgSender()] += requiredCredits;
            }
        } else {
            if (tokenIn == address(nineInchRouter.WETH())) {
                require(
                    msg.value == amountIn,
                    "Insufficient eth value for swap"
                );
            }
        }

        (bool success, uint256 price) = getPrice(amountIn, path);
        require(success && price < targetPrice, "Invalid target price");
        uint256[3] memory prices;
        prices[0] = price;
        prices[1] = targetPrice;
        prices[2] = amountIn;

        bytes32 orderId = keccak256(
            abi.encodePacked(
                prices[0],
                prices[1],
                prices[2],
                tokenIn,
                tokenOut,
                user,
                slippage,
                block.number
            )
        );

        require(!orderIndex.contains(orderId), "Order id mistake");

        unchecked {
            credits[_msgSender()] -= _credits;
        }

        //Effects
        uint256 deadline = block.timestamp.add(creditTime.mul(_credits));
        _createOrder(
            orderId,
            prices[1],
            prices[2],
            path,
            user,
            slippage,
            deadline
        );

        //Interactions
        IERC20 token = IERC20(tokenIn);
        if (token.allowance(address(this), address(nineInchRouter)) == 0) {
            token.approve(address(nineInchRouter), ~uint256(0));
        }
        if (tokenIn != address(nineInchRouter.WETH())) {
            token.transferFrom(user, address(this), prices[2]);
        }

        emit OrderCreated(
            orderId,
            prices[0],
            prices[1],
            prices[2],
            tokenIn,
            tokenOut,
            user,
            slippage,
            deadline
        );
    }

    /**
     * @notice Cancel a existent order.
     * @param orderId Order identity.
     */
    function cancelOrder(bytes32 orderId) external nonReentrant {
        //Checks
        require(orderIndex.contains(orderId), "Order does not exist");
        Order memory order = orderBook[orderId];
        require(order.user == _msgSender(), "Invalid access");
        address tokenIn = order.path[0];

        //Effects
        _deleteOrder(orderId);

        //Interactions
        if (tokenIn == address(nineInchRouter.WETH())) {
            (bool success, ) = payable(order.user).call{value: order.amountIn}(
                ""
            );
            require(success, "Transfer failed");
        } else {
            IERC20 token = IERC20(tokenIn);
            token.transfer(order.user, order.amountIn);
        }

        if (returnCredit) {
            credits[order.user] += 1;
        }

        emit OrderCancelled(orderId);
    }

    /**
     * @notice Check if any order need to be execute.
     * @param checkData default data of keeper.
     * @return If need to be execute and the order id.
     */
    function checkUpkeep(
        bytes calldata checkData
    ) external view override cannotExecute returns (bool, bytes memory) {
        (uint256 start, uint256 end) = getBatch();
        for (uint256 i = start; i < end; i++) {
            bytes32 orderId = orderIndex.at(i);
            Order memory order = orderBook[orderId];
            (bool success, uint256 price) = getPrice(
                order.amountIn,
                order.path
            );
            if (
                (success == true && price >= order.targetPrice) ||
                order.deadline <= block.timestamp
            ) {
                return (true, abi.encodePacked(orderId));
            }
        }
        return (false, checkData);
    }

    /**
     * @notice Execute an order, only keepers can do this execution.
     * @param performData order id to execute.
     */
    function performUpkeep(
        bytes calldata performData
    ) external override nonReentrant onlyKeeper {
        bytes32 orderId = abi.decode(performData, (bytes32));
        require(orderIndex.contains(orderId), "Order does not exist");
        Order memory order = orderBook[orderId];
        address tokenIn = order.path[0];

        if (order.deadline <= block.timestamp) {
            //Effects
            _deleteOrder(orderId);

            //Interactions
            if (tokenIn == address(nineInchRouter.WETH())) {
                (bool transfered, ) = payable(order.user).call{
                    value: order.amountIn
                }("");
                require(transfered, "Transfer failed");
            } else {
                IERC20 token = IERC20(tokenIn);
                token.transfer(order.user, order.amountIn);
            }

            emit OrderExpired(orderId);
        } else {
            //Checks
            (bool success, uint256 price) = getPrice(
                order.amountIn,
                order.path
            );
            require(
                success == true && price >= order.targetPrice,
                "Target not reached"
            );

            uint256 amountOutMin = price.mul(10000 - order.slippage).div(10000);

            //Effects
            _deleteOrder(orderId);

            //Interactions
            _performSwap(
                orderId,
                order.amountIn,
                order.path,
                order.user,
                amountOutMin
            );
        }
    }

    /**
     * @notice Cancel a existent order by the contract owner.
     * @param orderId_ Order identity.
     */
    function forceCancelOrder(bytes32 orderId_) external onlyOwner {
        //Checks
        require(orderIndex.contains(orderId_), "Order does not exist");
        Order memory order = orderBook[orderId_];
        address tokenIn = order.path[0];

        //Effects
        _deleteOrder(orderId_);

        //Interactions
        if (tokenIn == address(nineInchRouter.WETH())) {
            (bool success, ) = payable(order.user).call{value: order.amountIn}(
                ""
            );
            require(success, "Transfer failed");
        } else {
            IERC20 token = IERC20(tokenIn);
            token.transfer(order.user, order.amountIn);
        }
        credits[order.user] += 1;
        emit OrderCancelled(orderId_);
    }

    /**
     * @notice Set if a credit is returned when canceling the order.
     * @param return_ Determines whether or not to return.
     */
    function setReturnCredit(bool return_) external onlyOwner {
        returnCredit = return_;
    }

    /**
     * @notice Set the time that extends an order per consumed credit.
     * @param newTimeCredit_ The time in timestamp that extends an order.
     */
    function setTimeCredit(uint256 newTimeCredit_) external onlyOwner {
        require(newTimeCredit_ > 0, "Invalid time");
        creditTime = newTimeCredit_;
    }

    /**
     * @notice Set the link credit price.
     * @param _creditPrice link credit price.
     */
    function setCreditPrice(uint256 _creditPrice) external onlyOwner {
        require(_creditPrice != 0, "Zero fee");
        creditPrice = _creditPrice;
    }

    /**
     * @notice Set keeper id to manage the contract.
     * @param id_ Number of the keeper id.
     */
    function setKeeperId(uint256 id_) external onlyOwner {
        require(id_ != 0, "Zero id");
        keeperId = id_;
    }

    function updateRouter(address _router) external onlyOwner {
        nineInchRouter = INineInchRouter02(_router);
    }

    /**
     * @notice Functions for pause and unpause the contract.
     */
    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }
}
