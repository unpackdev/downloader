// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./BatchSize.sol";
import "./CommonState.sol";
import "./Constants.sol";
import "./ProcessorManager.sol";
import "./TokenManager.sol";
import "./ISubscriptions.sol";
import "./IWeth.sol";

import "./AggregatorV3Interface.sol";
import "./Denominations.sol";
import "./Ownable.sol";
import "./Initializable.sol";
import "./SafeCast.sol";
import "./IERC20Metadata.sol";
import "./SafeERC20.sol";

/**
 * @title The subscription template implementation contract
 * @author Shane van Coller
 * @dev Contains implementation logic for the SaaS/subscription vertical
 */
contract Subscriptions is
    ISubscriptions,
    Ownable,
    Initializable,
    CommonState,
    Constants,
    BatchSize,
    ProcessorManager,
    TokenManager
{
    using SafeCast for int256;
    using SafeCast for uint256;
    using SafeERC20 for IERC20Metadata;

    /**
     * @dev The address that all subscription funds will be transferred to
     */
    address payable public receivingAddress;

    /**
     * @dev List of the various subscription tier/plan names that have been configured in the
     * contract. For example, Developer, Professional or Enterprise
     */
    string[] public subscriptionTiersList;

    /**
     * @dev List of subscriber addresses. If the address is in the list, it has an active subscription
     */
    address[] public activeSubscriptionList;

    /**
     * @dev Subscription tier/plan details mapped by the bytes representation of the tier name. The
     * SubscriptionTier has the following attributes:
     *
     * uint256 frequency - how often to collect payment
     * uint256 usdSubAmount - the USD value of the subscription. Must be 8 decimal precision
     * uint256 usdStakeAmount - the USD value of the stake. Must be 8 decimal precision
     * uint256 feePercentage - the processing fee percentage. Must be 18 decimal precision
     */
    mapping(string => SubscriptionTier) public subscriptionTiers;

    /**
     * @dev Details of each subscriber. Each Subscriber has the following attributes:
     *
     * uint256 idx - the index of the subscriber, 1st subscriber is idx 1
     * IERC20Metadata tokenPaid - the token address used to pay for subscription
     * string tier - the tier name
     * uint256 usdAmount - the USD amount of the subscription, must be 8 decimal precision
     * uint256 frequency - the frequency with with to collect funds for the subscription, in seconds
     * uint256 startDate - the subscription start date, as seconds from epoch
     * uint256 endDate - the subscription end date, as seconds from epoch
     * uint256 stakedAmount - the amount staked in token at the time it was staked
     * uint256 processedAt - date the subscription was last successfully processed
     * uint256 processedAmount - the last amount collected in the payment token
     */
    mapping(address => Subscription) public subscriptions;

    event Initialized(
        string[] tierNames,
        uint256[] tierFrequencies,
        uint256[] tierUsdSubAmounts,
        uint256[] tierUsdStakeAmounts,
        uint256[] tierFeePercentages,
        address[] acceptedTokenAddresses,
        address[] chainlinkAggregators,
        address wEthAddress
    );
    event Subscribed(
        address indexed subscriber,
        string tierName,
        uint256 usdAmount,
        uint256 usdStakeAmount,
        uint256 startDate,
        uint256 frequency,
        uint256 stakedAmount,
        address indexed paymentToken,
        string paymentTokenSymbol,
        uint256 createdAt
    );
    event Unsubscribed(
        address indexed subscriber,
        string tierName,
        uint256 usdAmount,
        uint256 startDate,
        uint256 endDate,
        uint256 stakedAmount,
        address indexed paymentToken,
        string paymentTokenSymbol,
        uint256 createdAt
    );
    event OverridePayment(
        address indexed sender,
        address indexed subscriber,
        uint256 processedAt,
        uint256 createdAt
    );
    event TierSet(
        address indexed caller,
        string tierName,
        uint256 oldTierFrequency,
        uint256 oldTierUsdAmount,
        uint256 oldTierUsdStakeAmount,
        uint256 oldFeePercentage,
        uint256 newTierFrequency,
        uint256 newTierUsdAmount,
        uint256 newTierUsdStakeAmount,
        uint256 newFeePercentage
    );
    event FeeUpdated(
        address indexed caller,
        string tier,
        uint256 oldFeePercentage,
        uint256 newFeePercentage
    );
    event ReceivingAccountUpdated(
        address indexed caller,
        address oldValue,
        address newValue,
        uint256 createdAt
    );
    event ProcessPaymentSuccess(
        address indexed processor,
        address indexed accountProcessed,
        uint256 processedForDate,
        uint256 grossAmount,
        uint256 feeAmount,
        uint256 netAmount,
        address indexed paymentToken,
        address receivingAddress,
        uint256 date
    );
    event PaymentNotProcessedWarning(
        address indexed processor,
        address indexed accountProcessed,
        bytes reason,
        uint256 lastProcessDate,
        uint256 date
    );
    event ProcessPaymentFailure(
        address indexed processor,
        address indexed accountProcessed,
        bytes reason,
        address token,
        uint256 date
    );
    event StakeWithdrawn(
        address indexed caller,
        uint256 stakeAmount,
        address indexed paymentToken,
        uint256 createdAt
    );

    /**
     * @notice Initializes contract state variables

     * @dev - Address parameters cannot be 0x0 addresses
     *      - Indexes of each respective tier array represent a different tier
     *      - i.e tierNames[0], tierFrequencies[0] and tierUsdAmounts[0] are the details for
     *        a single tier
     * 
     * @param tierNames_ list of subscription tier names
     * @param tierFrequencies_ list of subscription frequencies 
     * @param tierUsdSubAmounts_ list of subscription amounts - 8 decimal precision
     * @param tierUsdStakeAmounts_ list of stake amounts require when subscribing - 8 decimal precision
     * @param tierFeePercentages_ list of processing fee percentages based on $ value of subscription tier amounts
     * @param acceptedTokenAddresses_ list of tokens accepted for payment
     * @param chainlinkAggregators_ list of aggregator addresses to lookup price feeds
     * @param loopFactory_ address of the Loop factory
     * @param wEthAddress_ wrapped ETH address
     * @param receivingAddress_ account that the subscription funds will go to
     */
    function initialize(
        string[] memory tierNames_,
        uint256[] memory tierFrequencies_,
        uint256[] memory tierUsdSubAmounts_,
        uint256[] memory tierUsdStakeAmounts_,
        uint256[] memory tierFeePercentages_,
        address[] calldata acceptedTokenAddresses_,
        address[] calldata chainlinkAggregators_,
        address loopFactory_,
        address wEthAddress_,
        address payable receivingAddress_
    ) public initializer {
        _transferOwnership(_msgSender());
        __BatchSize_init(40);
        __CommonState_init(loopFactory_, wEthAddress_);
        __ProcessorManager_init(20, 0);
        __TokenManager_init(acceptedTokenAddresses_, chainlinkAggregators_);

        require(
            tierNames_.length == tierFrequencies_.length &&
                tierNames_.length == tierUsdSubAmounts_.length &&
                tierNames_.length == tierUsdStakeAmounts_.length &&
                tierNames_.length == tierFeePercentages_.length,
            "LC:MISSING_TIER_INFO"
        );

        updateReceivingAddress(receivingAddress_);

        for (uint8 i = 0; i < tierNames_.length; i++) {
            require(tierUsdSubAmounts_[i] > 0, "LC:SUB_AMOUNT_ZERO");
            setSubscriptionTier(
                tierNames_[i],
                tierFrequencies_[i],
                tierUsdSubAmounts_[i],
                tierUsdStakeAmounts_[i],
                tierFeePercentages_[i]
            );
        }

        emit Initialized(
            tierNames_,
            tierFrequencies_,
            tierUsdSubAmounts_,
            tierUsdStakeAmounts_,
            tierFeePercentages_,
            acceptedTokenAddresses_,
            chainlinkAggregators_,
            WETH
        );
    }

    /**
     * @notice receive function to facilitate the unwrapping of WETH
     */
    receive() external payable {} // solhint-disable-line

    /**
     * @notice Allows a sender to subscribe to a tier and enable auto pay to collect funds from their account.
     *         Sender stays subscribed until they cancel - i.e. no end date set
     *
     * @dev - The payment token address must be in the list of accepted tokens
     *      - Sender cannot already be subscribed
     *      - Must send a valid tier name that already exists in the contract
     *      - Sender must have given at least the subscription amount + stake as an allowance on the token
     *
     * @param paymentTokenAddress_ address of the token being used for payment
     * @param tierName_ name of the tier to subscribe to
     * @param startDate_ start date of the subscription. If 0, then start date is block timestamp
     */
    function subscribe(
        address paymentTokenAddress_,
        string calldata tierName_,
        uint256 startDate_
    ) external {
        require(
            startDate_ == 0 || startDate_ > block.timestamp, // solhint-disable-line not-rely-on-time
            "LC:INVALID_START_DATE"
        );
        Subscription storage _subscription = subscriptions[msg.sender];
        require(_subscription.idx == 0, "LC:ALREADY_SUBSCRIBED");

        SubscriptionTier memory _tier = subscriptionTiers[tierName_];
        require(_tier.usdAmount > 0, "LC:TIER_NOT_FOUND");
        require(_tier.frequency > 0, "LC:TIER_PAUSED");

        require(
            tokenInfo[paymentTokenAddress_].accepted > 0,
            "LC:TOKEN_NOT_ACCEPTED"
        );

        (uint256 _stakeTokenCost, ) = _convertUsdToTokenAmount(
            paymentTokenAddress_,
            _tier.usdStakeAmount
        );

        activeSubscriptionList.push(msg.sender);
        _subscription.idx = activeSubscriptionList.length;
        _subscription.tokenPaid = paymentTokenAddress_;
        _subscription.tier = tierName_;
        _subscription.frequency = _tier.frequency;
        _subscription.usdAmount = _tier.usdAmount;
        _subscription.startDate = startDate_ == 0
            ? block.timestamp // solhint-disable-line not-rely-on-time
            : startDate_;
        _subscription.stakedAmount = _stakeTokenCost;

        _processPayment(msg.sender, address(0));

        string memory symbol = IERC20Metadata(paymentTokenAddress_).symbol();
        emit Subscribed(
            msg.sender,
            tierName_,
            _tier.usdAmount,
            _tier.usdStakeAmount,
            _subscription.startDate,
            _tier.frequency,
            _stakeTokenCost,
            paymentTokenAddress_,
            symbol,
            block.timestamp // solhint-disable-line not-rely-on-time
        );
    }

    /**
     * @notice Effectively cancels the subscription but allows continued service until end date.
     *
     * @dev - Sets an end date on the subscription
     *      - Stake stays locked until end date reached
     */
    function unsubscribe() external {
        _unsubscribe(msg.sender);
    }

    /**
     * @notice Allows sender to withdraw their stake once its unlocked
     *
     * @dev Stake only unlocks once end date has been reached
     */
    function withdrawStake() external {
        Subscription storage _subscription = subscriptions[msg.sender];
        require(
            _subscription.endDate > 0 &&
                _subscription.endDate < block.timestamp, // solhint-disable-line not-rely-on-time
            "LC:STAKE_LOCKED"
        );

        (address _tokenPaid, uint256 _stakeAmt) = _cancelSubscription(
            msg.sender
        );
        IERC20Metadata(_tokenPaid).safeTransfer(msg.sender, _stakeAmt);

        emit StakeWithdrawn(msg.sender, _stakeAmt, _tokenPaid, block.timestamp); // solhint-disable-line not-rely-on-time
    }

    /**
     * @notice Function to collect payments from a list of given addresses
     *
     * @dev - Can only process a limited number of addresses per call to limit gas used
     *      - Can only be called by senders that have been added to the allow list
     *
     * @param addressesToProcess_ list of addresses to process
     */
    function processPayments(address[] calldata addressesToProcess_)
        external
        onlyValidProcessorExt
        _checkBatchSizeAddr(addressesToProcess_)
    {
        for (uint8 i = 0; i < addressesToProcess_.length; i++) {
            // solhint-disable-next-line avoid-low-level-calls
            (bool success, bytes memory returnData) = address(this).call(
                abi.encodeWithSelector(
                    this.processPayment.selector,
                    addressesToProcess_[i],
                    msg.sender
                )
            );

            if (!success) {
                emit ProcessPaymentFailure(
                    msg.sender,
                    addressesToProcess_[i],
                    returnData,
                    subscriptions[addressesToProcess_[i]].tokenPaid,
                    block.timestamp // solhint-disable-line not-rely-on-time
                );
            }
        }
    }

    /*************************************************/
    /*************   EXTERNAL  GETTERS   *************/
    /*************************************************/
    /**
     * @notice Gets the number of active subscriptions
     *
     * @return number of active subscriptions
     */
    function getActiveSubscriptionCount() external view returns (uint256) {
        return activeSubscriptionList.length;
    }

    /**
     * @notice Gets the number of subscription tiers
     *
     * @return number of tiers
     */
    function getSubscriptionTiersCount() external view returns (uint256) {
        return subscriptionTiersList.length;
    }

    /**********************************************/
    /***********   SELF ONLY FUNCTIONS   **********/
    /**********************************************/
    /**
     * @notice Intermediate function to process payments
     *
     * @dev Can only be called by this contract
     */
    function processPayment(address addressToProcess_, address processor_)
        public
    {
        require(msg.sender == address(this), "LC:INVALID_CALLER");
        _processPayment(addressToProcess_, processor_);
    }

    /**********************************************/
    /**********   OWNER ONLY FUNCTIONS   **********/
    /**********************************************/
    /**
     * @notice Updates the address the subscriptions funds are sent to
     *
     * @dev - Can only be called by the owner of the contract
     *
     * @param newReceivingAddress_ new address to send subscription funds to
     */
    function updateReceivingAddress(address payable newReceivingAddress_)
        public
        onlyOwner
    {
        require(newReceivingAddress_ != address(0), "LC:INVALID_ADDRESS");
        emit ReceivingAccountUpdated(
            msg.sender,
            receivingAddress,
            newReceivingAddress_,
            block.timestamp // solhint-disable-line
        );
        receivingAddress = newReceivingAddress_;
    }

    /**
     * @notice Updates tier details for the given tier name, or adds a new one if it doesn't exist

     * @dev - Updates will only affect new subscriptions
     *      - Existing subscriptions continue to use the values that were set when originally subscribing
     *      - tierName_ param uses `memory` storage rather than `calldata` due to the internal call from 
     *        `initialize()` having to define its arguments as `memory` to avoid `stack to deep` compile
     *        error.
     *
     * @param tierName_ name of the tier to update
     * @param newTierFrequency_ new frequency for the tier
     * @param newTierUsdAmount_ new USD subscription amount for the tier
     * @param newTierUsdStakeAmount_ new USD stake amount for the tier
     * @param newTierFeePercentage_ new fee percentage amount for the tier
     */
    function setSubscriptionTier(
        string memory tierName_,
        uint256 newTierFrequency_,
        uint256 newTierUsdAmount_,
        uint256 newTierUsdStakeAmount_,
        uint256 newTierFeePercentage_
    ) public onlyOwner {
        require(newTierUsdAmount_ > 0, "LC:SUB_AMOUNT_ZERO");
        SubscriptionTier storage _tier = subscriptionTiers[tierName_];
        if (_tier.usdAmount == 0) subscriptionTiersList.push(tierName_);

        emit TierSet(
            msg.sender,
            tierName_,
            _tier.frequency,
            _tier.usdAmount,
            _tier.usdStakeAmount,
            _tier.feePercentage,
            newTierFrequency_,
            newTierUsdAmount_,
            newTierUsdStakeAmount_,
            newTierFeePercentage_
        );
        _tier.frequency = newTierFrequency_;
        _tier.usdAmount = newTierUsdAmount_;
        _tier.usdStakeAmount = newTierUsdStakeAmount_;
        _tier.feePercentage = newTierFeePercentage_;
    }

    /**
     * @notice Override payment for given list of subscriptions. Can be used to give a subscriber a
     *         free subscription for example
     *
     * @param overrideAddresses_ list of addresses to override
     */
    function overridePayment(address[] calldata overrideAddresses_)
        external
        onlyOwner
        _checkBatchSizeAddr(overrideAddresses_)
    {
        for (uint8 i = 0; i < overrideAddresses_.length; i++) {
            Subscription storage _subscription = subscriptions[
                overrideAddresses_[i]
            ];
            _subscription.processedAmount = 0;
            _subscription.processedAt += _subscription.frequency;
            emit OverridePayment(
                msg.sender,
                overrideAddresses_[i],
                _subscription.processedAt,
                block.timestamp // solhint-disable-line not-rely-on-time
            );
        }
    }

    /**
     * @notice Admin function that cancels a subscription
     *
     * @dev Caller can decide whether to slash the stake when calling this function
     *
     * @param subscriptionAddress_ address of the subscription to cancel
     * @param slashStake_ slash the subscribers stake
     */
    function cancelSubscription(address subscriptionAddress_, bool slashStake_)
        external
        onlyOwner
    {
        _unsubscribe(subscriptionAddress_);

        if (slashStake_) {
            (address _tokenPaid, uint256 _stakeAmt) = _cancelSubscription(
                subscriptionAddress_
            );
            IERC20Metadata(_tokenPaid).safeTransfer(
                receivingAddress,
                _stakeAmt
            );
        }
    }

    /**
     * @notice Updates the fee percentage value for a particular tier
     *
     * @param newFeePercentage_ new percentage, must be have FEE_PRECISION decimals
     */
    function updateFeePercentage(
        string calldata tierName_,
        uint256 newFeePercentage_
    ) external onlyOwner {
        SubscriptionTier storage _tier = subscriptionTiers[tierName_];
        require(_tier.usdAmount > 0, "LC:TIER_NOT_FOUND");

        emit FeeUpdated(
            msg.sender,
            tierName_,
            _tier.feePercentage,
            newFeePercentage_
        );
        _tier.feePercentage = newFeePercentage_;
    }

    /**********************************************/
    /***********   INTERNAL FUNCTIONS   ***********/
    /**********************************************/
    /**
     * @notice Internal function that collects the subscription payment and the fee from the subscriber
     *
     * @dev - Txn doesn't fail on unsuccessful transfer, just emits a failure event
     *      - Ignores subscription if not subscribed
     *      - Ignores subscription if not up for renewal
     *
     * @param subscriberAddress_ address of the subscription from which to withdraw the funds
     * @param processor_ address of the processor bot
     */
    function _processPayment(address subscriberAddress_, address processor_)
        internal
    {
        Subscription storage _subscription = subscriptions[subscriberAddress_];
        if (_subscription.idx == 0) {
            emit PaymentNotProcessedWarning(
                processor_,
                subscriberAddress_,
                "Not subscribed",
                _subscription.processedAt,
                block.timestamp // solhint-disable-line not-rely-on-time
            );
            return;
        }
        if (_subscription.endDate > 0) {
            emit PaymentNotProcessedWarning(
                processor_,
                subscriberAddress_,
                "Cancelled",
                _subscription.processedAt,
                block.timestamp // solhint-disable-line not-rely-on-time
            );
            return;
        }
        if (
            _subscription.processedAt + _subscription.frequency >
            block.timestamp // solhint-disable-line not-rely-on-time
        ) {
            emit PaymentNotProcessedWarning(
                processor_,
                subscriberAddress_,
                "Not due",
                _subscription.processedAt,
                block.timestamp // solhint-disable-line not-rely-on-time
            );
            return;
        }

        SubscriptionTier memory _tier = subscriptionTiers[_subscription.tier];

        address _token = _subscription.tokenPaid;
        (uint256 _totalSubscriptionTokenCost, ) = _convertUsdToTokenAmount(
            address(_token),
            _subscription.usdAmount
        );

        uint256 _feeAmount;

        if (_subscription.processedAt == 0) {
            _subscription.processedAt = block.timestamp; // solhint-disable-line not-rely-on-time
            _subscription.processedAmount =
                _totalSubscriptionTokenCost +
                _subscription.stakedAmount;
            require(
                IERC20Metadata(_token).allowance(
                    subscriberAddress_,
                    address(this)
                ) >= _totalSubscriptionTokenCost,
                "LC:INSUFFICIENT_ALLOWANCE"
            );
        } else {
            _subscription.processedAt += _subscription.frequency;
            _subscription.processedAmount = _totalSubscriptionTokenCost;
            (uint256 _baseFeeTokenAmt, ) = _convertUsdToTokenAmount(
                _token,
                baseFee
            );
            _feeAmount = _calculateProcessingFee(
                _baseFeeTokenAmt,
                _tier.feePercentage,
                _totalSubscriptionTokenCost
            );
        }

        IERC20Metadata(_token).safeTransferFrom(
            subscriberAddress_,
            address(this),
            _subscription.processedAmount
        );

        uint256 _netAmount = _totalSubscriptionTokenCost - _feeAmount;

        processorBalances[processor_][_token] += _feeAmount;

        // Only unwrap WETH on ETH mainnet
        if (block.chainid == 1 && _token == WETH) {
            IWeth(WETH).withdraw(_netAmount);
            receivingAddress.transfer(_netAmount);
        } else {
            IERC20Metadata(_token).safeTransfer(receivingAddress, _netAmount);
        }

        emit ProcessPaymentSuccess(
            processor_,
            subscriberAddress_,
            _subscription.processedAt,
            _totalSubscriptionTokenCost,
            _feeAmount,
            _netAmount,
            _token,
            receivingAddress,
            block.timestamp // solhint-disable-line
        );
    }

    /**
     * @notice Internal function that sets an end date on the subscription
     *
     * @dev - Sets the end date to the remaining time in the period for the subscription
     *      - For example, if you unsubscribe 2 weeks into a 4 week subscription, you will still
     *        have active service for 2 weeks
     *
     * @param subscriberAddress_ address of the subscription to cancel
     */
    function _unsubscribe(address subscriberAddress_) internal {
        Subscription storage _subscription = subscriptions[subscriberAddress_];
        require(_subscription.idx > 0, "LC:NOT_SUBSCRIBED");
        require(_subscription.endDate == 0, "LC:ALREADY_UNSUBSCRIBED");

        _subscription.endDate =
            block.timestamp + // solhint-disable-line not-rely-on-time
            (_subscription.frequency -
                ((block.timestamp - _subscription.startDate) % // solhint-disable-line not-rely-on-time
                    _subscription.frequency));

        emit Unsubscribed(
            subscriberAddress_,
            _subscription.tier,
            _subscription.usdAmount,
            _subscription.startDate,
            _subscription.endDate,
            _subscription.stakedAmount,
            _subscription.tokenPaid,
            IERC20Metadata(_subscription.tokenPaid).symbol(),
            block.timestamp // solhint-disable-line not-rely-on-time
        );
    }

    /**
     * @notice Internal function that removes a subscriber from storage
     *
     * @dev - Need to manually manage the list of active subscriptions once a subscriber is removed
     *      - Move the last subscriptions address in the list to the idx of the subscription being removed
     *      - Remove the last element of the list
     *
     * @param subscriberAddress_ address of the subscription to remove
     */
    function _cancelSubscription(address subscriberAddress_)
        internal
        returns (address tokenPaid, uint256 stakeAmt)
    {
        Subscription memory _subscription = subscriptions[subscriberAddress_];
        stakeAmt = _subscription.stakedAmount;
        tokenPaid = _subscription.tokenPaid;
        uint256 subscriberIdx = _subscription.idx;

        delete subscriptions[subscriberAddress_];

        if (
            subscriberIdx != activeSubscriptionList.length &&
            activeSubscriptionList.length > 1
        ) {
            address _lastSubscriptionAddress = activeSubscriptionList[
                activeSubscriptionList.length - 1
            ];
            // Update the subscriber at the last position with the new idx
            Subscription storage _lastSubscription = subscriptions[
                _lastSubscriptionAddress
            ];
            _lastSubscription.idx = subscriberIdx;
            // Move the subscriber in the last position to the idx of the removed subscriber
            activeSubscriptionList[
                subscriberIdx - 1
            ] = _lastSubscriptionAddress;
        }
        activeSubscriptionList.pop();
    }
}
