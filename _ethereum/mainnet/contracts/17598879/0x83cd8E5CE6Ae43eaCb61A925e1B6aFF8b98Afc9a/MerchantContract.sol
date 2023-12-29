pragma solidity ^0.8.14;
//SPDX-License-Identifier: MIT

import "./Initializable.sol";
import "./IERC20Upgradeable.sol";
import "./SafeERC20Upgradeable.sol";
import "./OwnableUpgradeable.sol";

/*
@title MerchantContract
@notice This contract is used to create and manage subscriptions for a merchant.
*/
contract MerchantContract is Initializable, OwnableUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    // STATE
    string public organizationId;

    enum SubscriptionStatus {
        ACTIVE,
        INACTIVE
    }

    struct Subscription {
        uint256 id;
        address subscriber;
        uint256 maxAmount;
        uint256 dueBy;
        uint256 paymentInterval;
        SubscriptionStatus status;
        IERC20Upgradeable paymentToken;
    }

    Subscription[] subscriptions;
    uint256 public subscriptionId;

    mapping(string => bool) invoicePaidMap;

    string baseUrl;

    // EVENTS
    event SubscriptionCreated(
        uint256 indexed subscriptionId,
        address subscriber,
        uint256 paymentAmount,
        uint256 paymentInterval,
        string planId,
        string customerExtId
    );
    event MaxAmountUpdated(uint256 indexed subscriptionId, uint256 maxAmount);
    event SubscriptionCancelled(uint256 indexed subscriptionId);
    event SubsPaymentMade(
        uint256 indexed subscriptionId,
        string paymentId,
        address subscriber,
        uint256[] amounts,
        address[] recipients
    );
    event OnetimePaymentMade(
        string paymentId,
        address from,
        uint256[] amounts,
        address[] recipients
    );

    // INITIALIZATION
    function initialize(string memory _organizationId) public initializer {
        organizationId = _organizationId;
        subscriptionId = 0;

        __Ownable_init();
        transferOwnership(tx.origin);
    }

    function createSubscription(
        address _subscriber,
        uint256 _maxAmount,
        uint256 _dueBy,
        uint256 _paymentInterval,
        IERC20Upgradeable _paymentToken,
        string memory _planId,
        string memory _customerId
    ) external onlyOwner {
        Subscription memory subscription = Subscription(
            subscriptionId,
            _subscriber,
            _maxAmount,
            _dueBy,
            _paymentInterval,
            SubscriptionStatus.ACTIVE,
            _paymentToken
        );

        subscriptions.push(subscription);

        emit SubscriptionCreated(
            subscriptionId,
            _subscriber,
            _maxAmount,
            _paymentInterval,
            _planId,
            _customerId
        );

        subscriptionId++;
    }

    function updateSubsMaxAmount(
        uint256 _subscriptionId,
        uint256 _maxAmount
    ) external onlyOwner {
        Subscription memory subscription = subscriptions[_subscriptionId];

        require(
            subscription.status == SubscriptionStatus.ACTIVE,
            "Subscription not active"
        );

        subscription.maxAmount = _maxAmount;
        subscriptions[_subscriptionId] = subscription;
        emit MaxAmountUpdated(_subscriptionId, _maxAmount);
    }

    function cancelSubscription(uint256 _subscriptionId) external onlyOwner {
        Subscription memory subscription = subscriptions[_subscriptionId];
        require(
            subscription.status == SubscriptionStatus.ACTIVE,
            "Subscription not active"
        );

        subscription.status = SubscriptionStatus.INACTIVE;
        subscriptions[_subscriptionId] = subscription;

        emit SubscriptionCancelled(_subscriptionId);
    }

    function getSubscription(
        uint256 _subscriptionId
    ) external view returns (Subscription memory) {
        Subscription memory subscription = subscriptions[_subscriptionId];
        return subscription;
    }

    function getSubscriptions() external view returns (Subscription[] memory) {
        return subscriptions;
    }

    // SUBSCRIPTION PAYMENTS
    function makeSubsPayments(
        uint256 _subscriptionId,
        string memory _paymentId,
        uint256[] memory _amounts,
        address[] memory _recipients
    ) external onlyOwner {
        _checkMakeSubsPayments(
            _subscriptionId,
            _paymentId,
            _amounts,
            _recipients
        );
    }

    function paySubsWithSwap(
        uint256[][] memory _subsData,
        string memory _paymentId,
        address[] memory _recipients,
        address _swapTarget, // API: "to"
        bytes calldata _swapCallData // API: "data",
    ) external onlyOwner {
        _paySubsWithSwap(
            _subsData,
            _paymentId,
            _recipients,
            _swapTarget,
            _swapCallData
        );
    }

    // ONETIME PAYMENTS
    function makePayments(
        address _from,
        string memory _paymentId,
        uint256[] memory _amounts,
        address[] memory _recipients,
        IERC20Upgradeable _paymentToken
    ) external onlyOwner {
        _checkMakePayments(
            _from,
            _paymentId,
            _amounts,
            _recipients,
            _paymentToken
        );
    }

    function makeSwapPayments(
        address _from,
        string memory _paymentId,
        uint256[][] memory _amounts,
        address[] memory _recipients,
        address _swapTarget, // API: "to"
        bytes calldata _swapCallData, // API: "data",
        IERC20Upgradeable _paymentToken
    ) external onlyOwner {
        _checkMakeSwapPayments(
            _from,
            _paymentId,
            _amounts,
            _recipients,
            _swapTarget,
            _swapCallData,
            _paymentToken
        );
    }

    // INTERNAL FUNCTIONS

    // SUBSCRIPTION PAYMENTS
    function _checkMakeSubsPayments(
        uint256 _subscriptionId,
        string memory _paymentId,
        uint256[] memory _amounts,
        address[] memory _recipients
    ) internal {
        Subscription memory subscription = subscriptions[_subscriptionId];

        // Validate

        // Check that the subscription is active
        require(
            subscription.status == SubscriptionStatus.ACTIVE,
            "Subscription not active"
        );
        // Check that the invoice has not been paid
        require(
            invoicePaidMap[_paymentId] == false,
            "Invoice already processed"
        );
        // Check that the subscription is due
        require(
            subscription.dueBy <= block.timestamp,
            "Subscription payment not due yet"
        );

        uint256 totalAmount = 0;
        for (uint256 i = 0; i < _amounts.length; i++) {
            totalAmount += _amounts[i];
        }

        require(
            totalAmount <= subscription.maxAmount,
            "Payment req exceeds max amount"
        );

        IERC20Upgradeable token = IERC20Upgradeable(subscription.paymentToken);

        // Check token allowance
        uint256 allowance = token.allowance(
            subscription.subscriber,
            address(this)
        );

        require(allowance > totalAmount, "Token allowance insufficient");

        // Check user token balance
        uint256 balance = token.balanceOf(subscription.subscriber);
        require(balance > totalAmount, "Token balance insufficient");

        _makeSubsPayments(
            subscription.subscriber,
            subscription,
            _amounts,
            _recipients,
            _paymentId
        );
    }

    // _subsData[0] = subscriptionId
    // _subsData[1] = sellAmounts[]
    // _subsData[2] = buyAmounts[]
    function _paySubsWithSwap(
        uint256[][] memory _subsData,
        string memory _paymentId,
        address[] memory _recipients,
        address _swapTarget, // API: "to"
        bytes calldata _swapCallData // API: "data",
    ) private {
        Subscription memory subscription = subscriptions[_subsData[0][0]];

        // Validate
        require(
            subscription.status == SubscriptionStatus.ACTIVE,
            "Subscription not active"
        );
        require(
            invoicePaidMap[_paymentId] == false,
            "Invoice already processed"
        );
        require(
            subscription.dueBy <= block.timestamp,
            "Subscription payment not due yet"
        );

        uint256 totalSellAmount = 0;

        for (uint256 i = 0; i < _subsData[1].length; i++) {
            totalSellAmount += _subsData[1][i];
        }

        require(
            totalSellAmount <= subscription.maxAmount,
            "Payment req exceeds max amount"
        );

        IERC20Upgradeable paymentToken = IERC20Upgradeable(
            subscription.paymentToken
        );

        // Check token allowance
        uint256 allowance = paymentToken.allowance(
            subscription.subscriber,
            address(this)
        );

        require(allowance > totalSellAmount, "Token allowance insufficient");

        // Check user token balance
        uint256 balance = paymentToken.balanceOf(subscription.subscriber);
        require(balance > totalSellAmount, "Token balance insufficient");

        // Transfer tokens to this contract
        paymentToken.safeTransferFrom(
            subscription.subscriber,
            address(this),
            totalSellAmount
        );

        // Perform swap
        (bool success, ) = _swapTarget.call(_swapCallData);
        require(success, "Swap failed");

        // Make payments
        _makeSubsSwapPayments(
            subscription,
            _subsData[2],
            _recipients,
            _paymentId
        );
    }

    function _makeSubsSwapPayments(
        Subscription memory _subscription,
        uint256[] memory _amounts,
        address[] memory _recipients,
        string memory _paymentId
    ) internal {
        _makeSubsPayments(
            address(this),
            _subscription,
            _amounts,
            _recipients,
            _paymentId
        );
    }

    function _makeSubsPayments(
        address from,
        Subscription memory _subscription,
        uint256[] memory _amounts,
        address[] memory _recipients,
        string memory _paymentId
    ) internal {
        IERC20Upgradeable token = IERC20Upgradeable(_subscription.paymentToken);

        // Make subscription payments
        for (uint256 i = 0; i < _amounts.length; i++) {
            token.safeTransferFrom(from, _recipients[i], _amounts[i]);
        }

        // Update payment due time
        _subscription.dueBy = block.timestamp + _subscription.paymentInterval;
        subscriptions[_subscription.id] = _subscription;

        // Update invoice map
        invoicePaidMap[_paymentId] = true;

        emit SubsPaymentMade(
            _subscription.id,
            _paymentId,
            _subscription.subscriber,
            _amounts,
            _recipients
        );
    }

    // ONETIME PAYMENTS
    function _checkMakePayments(
        address _from,
        string memory _paymentId,
        uint256[] memory _amounts,
        address[] memory _recipients,
        IERC20Upgradeable _paymentToken
    ) internal {
        // Validate
        require(
            invoicePaidMap[_paymentId] == false,
            "Invoice already processed"
        );

        IERC20Upgradeable paymentToken = IERC20Upgradeable(_paymentToken);

        uint256 totalAmount = 0;

        for (uint256 i = 0; i < _amounts.length; i++) {
            totalAmount += _amounts[i];
        }

        // Check token allowance
        uint256 allowance = paymentToken.allowance(_from, address(this));

        require(allowance > totalAmount, "Token allowance insufficient");

        // Check user token balance
        uint256 balance = paymentToken.balanceOf(_from);
        require(balance > totalAmount, "Token balance insufficient");

        _makePayments(_from, _amounts, _recipients, _paymentId, _paymentToken);
    }

    function _checkMakeSwapPayments(
        address _from,
        string memory _paymentId,
        uint256[][] memory _amounts,
        address[] memory _recipients,
        address _swapTarget, // API: "to"
        bytes calldata _swapCallData, // API: "data",
        IERC20Upgradeable _paymentToken
    ) private {
        // Validate
        require(
            invoicePaidMap[_paymentId] == false,
            "Invoice already processed"
        );

        uint256 totalSellAmount = 0;

        for (uint256 i = 0; i < _amounts[0].length; i++) {
            totalSellAmount += _amounts[0][i];
        }

        IERC20Upgradeable paymentToken = IERC20Upgradeable(_paymentToken);

        // Check token allowance
        uint256 allowance = paymentToken.allowance(_from, address(this));

        require(allowance > totalSellAmount, "Token allowance insufficient");

        // Check user token balance
        uint256 balance = paymentToken.balanceOf(_from);
        require(balance > totalSellAmount, "Token balance insufficient");

        // Transfer tokens to this contract
        paymentToken.safeTransferFrom(_from, address(this), totalSellAmount);

        // Perform swap
        (bool success, ) = _swapTarget.call(_swapCallData);
        require(success, "Swap failed");

        // Make payments
        _makeSwapPayments(_amounts[1], _recipients, _paymentId, _paymentToken);
    }

    function _makeSwapPayments(
        uint256[] memory _amounts,
        address[] memory _recipients,
        string memory _paymentId,
        IERC20Upgradeable _paymentToken
    ) internal {
        _makePayments(
            address(this),
            _amounts,
            _recipients,
            _paymentId,
            _paymentToken
        );
    }

    function _makePayments(
        address _from,
        uint256[] memory _amounts,
        address[] memory _recipients,
        string memory _paymentId,
        IERC20Upgradeable _paymentToken
    ) internal {
        IERC20Upgradeable token = IERC20Upgradeable(_paymentToken);

        // Make subscription payments
        for (uint256 i = 0; i < _amounts.length; i++) {
            token.safeTransferFrom(_from, _recipients[i], _amounts[i]);
            (_from, _recipients[i], _amounts[i]);
        }

        // Update invoice map
        invoicePaidMap[_paymentId] = true;

        emit OnetimePaymentMade(_paymentId, _from, _amounts, _recipients);
    }
}
