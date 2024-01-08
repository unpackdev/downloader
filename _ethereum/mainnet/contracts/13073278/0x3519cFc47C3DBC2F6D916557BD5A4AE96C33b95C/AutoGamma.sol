// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

import "./GammaOperator.sol";
import "./IAutoGamma.sol";
import "./IUniswapRouter.sol";
import "./IPokeMe.sol";
import "./ITaskTreasury.sol";
import "./IResolver.sol";
import "./SafeERC20.sol";
import "./IERC20.sol";

/// @author Willy Shen
/// @title Opyn Gamma Automatic Redeemer
/// @notice An automatic redeemer for Gamma otoken holders and writers
contract AutoGamma is IAutoGamma, GammaOperator {
    using SafeERC20 for IERC20;

    Order[] public orders;

    IUniswapRouter public uniRouter;
    IPokeMe public automator;
    ITaskTreasury public automatorTreasury;
    bool public isAutomatorEnabled;

    mapping(address => mapping(address => bool)) public uniPair;

    // fee in 1/10.000: 1% = 100, 0.01% = 1
    uint256 public redeemFee = 100;
    uint256 public settleFee = 15;

    /**
     * @notice only automator or owner
     */
    modifier onlyAuthorized() {
        require(
            msg.sender == address(automator) || msg.sender == owner(),
            "AutoGamma::onlyAuthorized: Only automator or owner"
        );
        _;
    }

    constructor(
        address _gammaAddressBook,
        address _uniRouter,
        address _automator,
        address _automatorTreasury
    ) GammaOperator(_gammaAddressBook) {
        uniRouter = IUniswapRouter(_uniRouter);
        automator = IPokeMe(_automator);
        automatorTreasury = ITaskTreasury(_automatorTreasury);
        isAutomatorEnabled = false;
    }

    /**
     * @notice tell automator to start executing orders
     * @param _resolver the address of automation resolver
     * @dev automator will start calling resolver to fetch and execute processable orders
     */
    function startAutomator(address _resolver) public onlyOwner {
        require(
            !isAutomatorEnabled,
            "AutoGamma::startAutomator: already started"
        );
        isAutomatorEnabled = true;
        automator.createTask(
            address(this),
            bytes4(0x895f7952), //processOrders selector
            _resolver,
            abi.encodeWithSelector(IResolver.getProcessableOrders.selector)
        );
    }

    /**
     * @notice tell automator to stop executing orders
     */
    function stopAutomator() public onlyOwner {
        require(
            isAutomatorEnabled,
            "AutoGamma::stopAutomator: already stopped"
        );
        isAutomatorEnabled = false;
        automator.cancelTask(
            automator.getTaskId(
                address(this),
                address(this),
                bytes4(0x895f7952) //processOrders selector
            )
        );
    }

    /**
     * @notice create automation order
     * @param _otoken the address of otoken (only holders)
     * @param _amount amount of otoken (only holders)
     * @param _vaultId the id of specific vault to settle (only writers)
     * @param _toToken token address for custom token settlement
     */
    function createOrder(
        address _otoken,
        uint256 _amount,
        uint256 _vaultId,
        address _toToken
    ) public override {
        uint256 fee;
        bool isSeller;
        if (_otoken == address(0)) {
            require(
                _amount == 0,
                "AutoGamma::createOrder: Amount must be 0 when creating settlement order"
            );
            fee = settleFee;
            isSeller = true;
        } else {
            require(
                isWhitelistedOtoken(_otoken),
                "AutoGamma::createOrder: Otoken not whitelisted"
            );
            fee = redeemFee;
        }

        if (_toToken != address(0)) {
            address payoutToken;
            if (isSeller) {
                address otoken = getVaultOtoken(msg.sender, _vaultId);
                payoutToken = getOtokenCollateral(otoken);
            } else {
                payoutToken = getOtokenCollateral(_otoken);
            }
            require(
                payoutToken != _toToken,
                "AutoGamma::createOrder: same settlement token and collateral"
            );
            require(
                uniPair[payoutToken][_toToken],
                "AutoGamma::createOrder: settlement token not allowed"
            );
        }

        uint256 orderId = orders.length;

        Order memory order;
        order.owner = msg.sender;
        order.otoken = _otoken;
        order.amount = _amount;
        order.vaultId = _vaultId;
        order.isSeller = isSeller;
        order.fee = fee;
        order.toToken = _toToken;
        orders.push(order);

        emit OrderCreated(orderId, msg.sender, _otoken);
    }

    /**
     * @notice cancel automation order
     * @param _orderId the id of specific order to be cancelled
     */
    function cancelOrder(uint256 _orderId) public override {
        Order storage order = orders[_orderId];
        require(
            order.owner == msg.sender,
            "AutoGamma::cancelOrder: Sender is not order owner"
        );
        require(
            !order.finished,
            "AutoGamma::cancelOrder: Order is already finished"
        );

        order.finished = true;
        emit OrderFinished(_orderId, true);
    }

    /**
     * @notice check if processing order is profitable
     * @param _orderId the id of specific order to be processed
     * @return true if settling vault / redeeming returns more than 0 amount
     */
    function shouldProcessOrder(uint256 _orderId)
        public
        view
        override
        returns (bool)
    {
        Order memory order = orders[_orderId];
        if (order.finished) return false;

        if (order.isSeller) {
            bool shouldSettle = shouldSettleVault(order.owner, order.vaultId);
            if (!shouldSettle) return false;
        } else {
            bool shouldRedeem = shouldRedeemOtoken(
                order.owner,
                order.otoken,
                order.amount
            );
            if (!shouldRedeem) return false;
        }

        return true;
    }

    /**
     * @notice process an order
     * @dev only automator allowed
     * @param _orderId the id of specific order to process
     */
    function processOrder(uint256 _orderId, ProcessOrderArgs calldata orderArgs)
        public
        override
        onlyAuthorized
    {
        Order storage order = orders[_orderId];
        require(
            shouldProcessOrder(_orderId),
            "AutoGamma::processOrder: Order should not be processed"
        );
        order.finished = true;

        address payoutToken;
        uint256 payoutAmount;
        if (order.isSeller) {
            (payoutToken, payoutAmount) = settleVault(
                order.owner,
                order.vaultId
            );
        } else {
            (payoutToken, payoutAmount) = redeemOtoken(
                order.owner,
                order.otoken,
                order.amount
            );
        }

        // minus fee
        payoutAmount = payoutAmount - ((order.fee * payoutAmount) / 10000);

        if (order.toToken == address(0)) {
            IERC20(payoutToken).safeTransfer(order.owner, payoutAmount);
        } else {
            require(
                payoutToken == orderArgs.swapPath[0] &&
                    order.toToken == orderArgs.swapPath[1],
                "AutoGamma::processOrder: Invalid swap path"
            );
            require(
                uniPair[payoutToken][order.toToken],
                "AutoGamma::processOrder: token pair not allowed"
            );

            IERC20(payoutToken).approve(address(uniRouter), payoutAmount);
            uint256[] memory amounts = swap(
                payoutAmount,
                orderArgs.swapAmountOutMin,
                orderArgs.swapPath
            );
            IERC20(order.toToken).safeTransfer(order.owner, amounts[1]);
        }

        emit OrderFinished(_orderId, false);
    }

    /**
     * @notice process multiple orders
     * @param _orderIds array of order ids to process
     */
    function processOrders(
        uint256[] calldata _orderIds,
        ProcessOrderArgs[] calldata _orderArgs
    ) public override {
        require(
            _orderIds.length == _orderArgs.length,
            "AutoGamma::processOrders: Params lengths must be same"
        );
        for (uint256 i = 0; i < _orderIds.length; i++) {
            processOrder(_orderIds[i], _orderArgs[i]);
        }
    }

    /**
     * @notice withdraw funds from automator
     * @param _token address of token to withdraw
     * @param _amount amount of token to withdraw
     */
    function withdrawFund(address _token, uint256 _amount) public onlyOwner {
        automatorTreasury.withdrawFunds(payable(this), _token, _amount);
    }

    /**
     * @notice uniswap token swap
     * @param _amountIn amount of token to swap
     * @param _amountOutMin minimal amount of token to receive
     * @param _path token pair to swap
     * @return amounts amount of each tokens being swapped
     */
    function swap(
        uint256 _amountIn,
        uint256 _amountOutMin,
        address[] calldata _path
    ) internal returns (uint256[] memory amounts) {
        return
            IUniswapRouter(uniRouter).swapExactTokensForTokens(
                _amountIn,
                _amountOutMin,
                _path,
                address(this),
                block.timestamp
            );
    }

    /**
     * @notice allow token pair for swap
     * @param _token0 first token
     * @param _token1 second token
     */
    function allowPair(address _token0, address _token1) public onlyOwner {
        require(
            !uniPair[_token0][_token1],
            "AutoGamma::allowPair: already allowed"
        );
        uniPair[_token0][_token1] = true;
        uniPair[_token1][_token0] = true;
    }

    /**
     * @notice disallow token pair for swap
     * @param _token0 first token
     * @param _token1 second token
     */
    function disallowPair(address _token0, address _token1) public onlyOwner {
        require(
            uniPair[_token0][_token1],
            "AutoGamma::allowPair: already disallowed"
        );
        uniPair[_token0][_token1] = false;
        uniPair[_token1][_token0] = false;
    }

    function setUniRouter(address _uniRouter) public onlyOwner {
        uniRouter = IUniswapRouter(_uniRouter);
    }

    function setAutomator(address _automator) public onlyOwner {
        automator = IPokeMe(_automator);
    }

    function setAutomatorTreasury(address _automatorTreasury) public onlyOwner {
        automatorTreasury = ITaskTreasury(_automatorTreasury);
    }

    function setRedeemFee(uint256 _redeemFee) public onlyOwner {
        redeemFee = _redeemFee;
    }

    function setSettleFee(uint256 _settleFee) public onlyOwner {
        settleFee = _settleFee;
    }

    function getOrdersLength() public view override returns (uint256) {
        return orders.length;
    }

    function getOrders() public view override returns (Order[] memory) {
        return orders;
    }

    function getOrder(uint256 _orderId)
        public
        view
        override
        returns (Order memory)
    {
        return orders[_orderId];
    }

    function isPairAllowed(address _token0, address _token1)
        public
        view
        override
        returns (bool)
    {
        return uniPair[_token0][_token1];
    }
}
