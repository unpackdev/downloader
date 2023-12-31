/**
 * Nchart Subscription Manager
 *
 * Website: nchart.io
 * Docs: docs.nchart.io
 * twitter.com/Nchart_
 * twitter.com/Kekotron_
 */

// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import "./OwnableRoles.sol";
import "./LibMap.sol";
import "./Nchart.sol";
import "./IUniswapV2Router02.sol";

/**
 *             ........
 *         ..::::::::::::.  .
 *       .:::::::::::::::.  =+-.
 *     --::::::::::::::::.  =+++-
 *    *##*+::::::::::::::.  =+++++
 *   *#####:  .::::::::::.  =++++++
 *  -######:     .:::::::.  =++++++-
 *  *######:  :.    .::::.  =+++++++
 *  #######:  -=-:.    .:.  =+++++++
 *  +######:  -=====:.      =++++++=
 *  :######:  -========-.   =++++++:
 *   +#####:  -===========-.-+++++=
 *    =####:  -==============-==+-
 *     :*##:  -================-.
 *       :+:  -==============-.
 *            :==========-:.
 *               ......
 *
 *
 * @dev Contract which accepts ETH to pay for a subscription, which is used to buy and burn CHART from
 * @dev the UniswapV2 LP Pool.  This contract also includes a staking mechanism for users to stake CHART
 * @dev and grant a subscription in return.
 */
contract SubscriptionManager is OwnableRoles {
    struct StakingInfo {
        address staker;
        uint40 stakeLength;
        uint40 stakingExpirationTimestamp;
        uint256 stakedAmount;
    }

    struct StakingConfig {
        /// @notice Subscription length granted for staking CHART
        uint40 stakeSubscriptionLength;
        /// @notice Minimum length of time to stake CHART
        uint40 minStakingLength;
        /// @notice Maximum length of time to stake CHART
        uint40 maxStakingLength;
        /// @notice Maximum amount of CHART required to stake
        uint256 maxStakingAmount;
        /// @notice CHART per second reduction amount
        uint256 step;
    }

    uint40 internal constant MAX_UINT40 = type(uint40).max;
    uint256 public constant KEEPER_ROLE = uint256(1);

    Nchart public immutable chart;
    IUniswapV2Router02 public immutable router;

    LibMap.Uint40Map private expiration;
    mapping(address => StakingInfo) private staking;

    StakingConfig public stakingConfig = StakingConfig({
        stakeSubscriptionLength: 30 days * 6, // 6 months
        maxStakingAmount: 2000 * 1 ether,
        minStakingLength: 30 days * 6, // 6 months
        maxStakingLength: 730 days, // 2 years
        step: 31565656565657 // (maxStakingAmount - targetLowestStakingAmount) / (maxStakingLength - minStakingLength) = CHART per second
    });

    uint256 public subscriptionPrice = 0.015 ether; // Price is 0.015e to start
    uint40 public subscriptionLength; // Lifetime subscription to start
    // Percent of fees to use to buy and burn CHART
    uint8 public burnPercent = 99;
    // Percent of fees to send to referrer if they have an active subscription
    uint8 public referralPercent = 5;

    event BurnPercentUpdated(uint8 newPercent, uint8 oldPercent);
    event ReferralPaid(address indexed referrer, uint256 amount);
    event ReferralPercentUpdated(uint8 newPercent, uint8 oldPercent);
    event Restaked(address indexed subscriberAddress, uint256 amount);
    event Staked(address indexed subscriberAddress, uint40 stakeLength, uint256 chartPerAccount, uint40 stakingExpirationTimestamp);
    event SubscriptionLengthUpdated(uint256 newLength, uint256 oldLength);
    event SubscriptionPaid(address indexed subscriber, uint40 expirationTimestamp, uint256 price);
    event SubscriptionPriceUpdated(uint256 newPrice, uint256 oldPrice);
    event Unstaked(address indexed subscriberAddress, uint256 amount);

    error SubscriptionManager__BurnPercentMustBeGreaterThan50();
    error SubscriptionManager__BurnPercentMustBeLessThan100();
    error SubscriptionManager__CannotReferSelf();
    error SubscriptionManager__CannotRegisterAddressZero();
    error SubscriptionManager__CannotRestakeForAccountsWithMoreThanOneMonthRemaining();
    error SubscriptionManager__CannotRestakeForAccountsWithoutStake();
    error SubscriptionManager__CannotStakeForAccountsWithCurrentSubscription();
    error SubscriptionManager__CannotUnstakeForAccountsWithActiveStake();
    error SubscriptionManager__CannotUnstakeForAccountsWithoutStake();
    error SubscriptionManager__CanOnlyIncreaseExpiration();
    error SubscriptionManager__ErrorRetrievingPriceFromDataFeed();
    error SubscriptionManager__ErrorSendingKeeperFunds();
    error SubscriptionManager__InvalidETHAmountProvided(uint256 msgValue, uint256 ethRequired);
    error SubscriptionManager__MaxFiftyPercentReferralPercent();
    error SubscriptionManager__MustBeStakerToRestake();
    error SubscriptionManager__MustBeStakerToUnstake();
    error SubscriptionManager__MustProvideAtLeastOneAddress();
    error SubscriptionManager__MustProvideEqualLengthArrays();
    error SubscriptionManager__OnlyOwner();
    error SubscriptionManager__StakeLengthGreaterThanMaximumLength();
    error SubscriptionManager__StakeLengthLessThanMinimumLength();
    error SubscriptionManager__UseRegisterAddressesFunction();

    constructor(address payable chart_, address owner_, address router_) {
        _initializeOwner(owner_);
        chart = Nchart(chart_);
        router = IUniswapV2Router02(router_);
    }

    receive() external payable {
        revert SubscriptionManager__UseRegisterAddressesFunction();
    }

    fallback() external payable {
        revert SubscriptionManager__UseRegisterAddressesFunction();
    }

    /**
     * @notice Sets the length of the subscription period.
     *
     * @dev    The subscription length is either added to the remaining time of a user's subscription or block.timestamp if unset
     * @dev    Passing in a value of 0 will set the subscription to unlimited, and expiration will be set to MAX_UINT40
     * @dev    - Throws if caller is not owner
     *
     * @dev    On completion:
     * @dev    - `subscriptionLength` = `newSubscriptionLength`
     * @dev    - Emits {SubscriptionLengthUpdated} event
     *
     * @param  newSubscriptionLength Length to update future subscriptions to
     */
    function setSubscriptionLength(uint40 newSubscriptionLength) external {
        _requireIsOwner();

        uint40 oldSubscriptionLength = subscriptionLength;
        subscriptionLength = newSubscriptionLength;
        emit SubscriptionLengthUpdated(newSubscriptionLength, oldSubscriptionLength);
    }

    /**
     * @notice Sets the percentage of fees to send to referrers if they have an active subscription
     *
     * @dev    - Throws if `msg.sender` != `owner()`
     * @dev    - Throws if provided percent is > 5
     *
     * @dev    On completion:
     * @dev    - `referralPercent` = `newPercent`
     * @dev    - Emits {ReferralPercentUpdated} event
     *
     * @param newPercent Percentage of fees to send to referrers
     */
    function setReferralPercent(uint8 newPercent) external {
        _requireIsOwner();

        if (newPercent > 50) {
            revert SubscriptionManager__MaxFiftyPercentReferralPercent();
        }

        uint8 oldPercent = referralPercent;
        referralPercent = newPercent;
        emit ReferralPercentUpdated(newPercent, oldPercent);
    }

    /**
     * @notice Sets the price of new subscriptions.  Users will be charged this amount per address to use premium features
     *
     * @dev    Price of subscription is set in ETH, stored in 1e18 (wei)
     * @dev    Passing in a value of 0 will set premium features to free.
     * @dev    - Throws if caller is not owner
     *
     * @dev    On completion:
     * @dev    - `subscriptionPrice` = `newSubscriptionPrice`
     * @dev    - Emits {SubscriptionPriceUpdated} event
     *
     * @param  newSubscriptionPrice Price to update future subscriptions to
     */
    function setSubscriptionPrice(uint256 newSubscriptionPrice) external {
        _requireIsOwner();

        uint256 oldSubscriptionPrice = subscriptionPrice;
        subscriptionPrice = newSubscriptionPrice;
        emit SubscriptionPriceUpdated(newSubscriptionPrice, oldSubscriptionPrice);
    }

    /**
     * @notice Sets the percentage of fees used to buy and burn CHART
     *
     * @dev    - Throws if `msg.sender` != `owner()`
     * @dev    - Throws if provided percent is > 100
     *
     * @dev    On completion:
     * @dev    - `burnPercent` = `newPercent`
     * @dev    - Emits {BurnPercentUpdated} event
     *
     * @param newPercent Percentage of fees to be used to buy and burn CHART
     */
    function setBurnPercent(uint8 newPercent) external {
        _requireIsOwner();

        if (newPercent > 100) {
            revert SubscriptionManager__BurnPercentMustBeLessThan100();
        }

        if (newPercent < 50) {
            revert SubscriptionManager__BurnPercentMustBeGreaterThan50();
        }

        uint8 oldPercent = burnPercent;
        burnPercent = newPercent;
        emit BurnPercentUpdated(newPercent, oldPercent);
    }

    /**
     * @notice Updates the staking configuration
     *
     * @dev    - Throws if `msg.sender` != `owner()`
     * 
     * @dev    On completion:
     * @dev    - `stakingConfig` = `newStakingConfig`
     * 
     * @param stakeSubscriptionLength_ Length of subscription granted for staking CHART
     * @param minStakingLength_ Minimum length of time to stake CHART
     * @param maxStakingLength_ Maximum length of time to stake CHART
     * @param maxStakingAmount_ Maximum amount of CHART required to stake
     * @param step_ Step amount to reduce CHART required to stake based on stake length
     */
    function updateStakingConfig(uint40 stakeSubscriptionLength_, uint40 minStakingLength_, uint40 maxStakingLength_, uint256 maxStakingAmount_, uint256 step_) external {
        _requireIsOwner();

        stakingConfig = StakingConfig({
            stakeSubscriptionLength: stakeSubscriptionLength_,
            minStakingLength: minStakingLength_,
            maxStakingLength: maxStakingLength_,
            maxStakingAmount: maxStakingAmount_,
            step: step_
        });
    }

    /**
     * @notice Allows owner to increase the expiration timestamp for a provided user in case of 
     * @notice giveaways. Also allows for owner to revoke subscriptions in case of abuse.
     *
     * @dev    - Throws if `msg.sender` != `owner()
     * @dev    - Throws if `user` == address(0)
     *
     * @dev    On completion:
     * @dev    - User expiration is set to `newExpiration`
     */
    function setExpirationTimestamp(uint40 newExpiration, address user) external {
        _requireIsOwner();
        if (user == address(0)) {
            revert SubscriptionManager__CannotRegisterAddressZero();
        }
        LibMap.set(expiration, uint256(uint160(user)), newExpiration);
    }

    /**
     * @notice Allows owner to increase the expiration timestamp for a provided user in case of 
     * @notice giveaways. Also allows for owner to revoke subscriptions in case of abuse.
     *
     * @dev    - Throws if `msg.sender` != `owner()
     * @dev    - Throws if `user` == address(0)
     * @dev    - Throws if newExpiration.length != user.length
     *
     * @dev    On completion:
     * @dev    - User expiration is set to `newExpiration` for each user in `user`
     */
    function bulkSetExpirationTimestamp(uint40[] calldata newExpiration, address[] calldata user) external {
        _requireIsOwner();
        if (newExpiration.length != user.length) {
            revert SubscriptionManager__MustProvideEqualLengthArrays();
        }
        for (uint256 i = 0; i < newExpiration.length;) {
            _requireValidAddress(user[i]);
            LibMap.set(expiration, uint256(uint160(user[i])), newExpiration[i]);
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Grants the KEEPER_ROLE to the provided user.
     *
     * @dev    - Throws if the `msg.sender` is not `owner()`
     *
     * @dev    On completion:
     * @dev    - `newKeeper` is assigned the `KEEPER_ROLE`
     *
     * @param newKeeper Address to assign the `KEEPER_ROLE`
     */
    function grantKeeperRole(address newKeeper) external {
        grantRoles(newKeeper, KEEPER_ROLE);
    }

    /**
     * @notice Revokes the KEEPER_ROLE from the provided user.
     *
     * @dev    - Throws if the `msg.sender` is not `owner()`
     *
     * @dev    On completion:
     * @dev    - `toRevoke` is no longer assigned the `KEEPER_ROLE`
     *
     * @param toRevoke Address to revoke the `KEEPER_ROLE` from
     */
    function revokeKeeperRole(address toRevoke) external {
        revokeRoles(toRevoke, KEEPER_ROLE);
    }

    /**
     * @notice Registers a list of addresses for premium features.  There is an optional referrer address
     * @notice which will receive a percentage of the fees paid by the registered addresses if they have an active subscription.
     *
     * @dev    - Throws if the length of the provided addresses is 0
     * @dev    - Throws if `msg.value` is not equal to the exact amount required to pay for the subscriptions
     * @dev    - Throws if any address provided is address(0)
     * @dev    - Throws if the referrer address executes code > 2300 gas
     * @dev    - If the provided referral address is not subscribed, it is a no-op
     *
     * @dev    On completion:
     * @dev    - `expiration` mapping for each address is updated to add on an additional `subLength` seconds
     * @dev    - If `expiration` + the current length of subscriptions is > uint256 max, set to uint256 max
     * @dev    - If the current length of subscription is 0, set `expiration` to uint256 max
     * @dev    - The contract has `subLength` * `subPrice` - `referralAmount` more ETH
     * @dev    - If the referrer is subscribed, they receive `referralAmount` ETH
     * @dev    - Emits `addresses.length` {SubscriptionPaid} events
     * @dev    - Emits {ReferralPaid} event if referrer is subscribed
     *
     * @param  addresses A list of addresses to register
     * @param  referrer  Optional address of referrer
     */
    function registerAddresses(address[] calldata addresses, address referrer) external payable {
        uint256 numSubs = addresses.length;
        if (numSubs == 0) {
            revert SubscriptionManager__MustProvideAtLeastOneAddress();
        }
        if (referrer == msg.sender) {
            revert SubscriptionManager__CannotReferSelf();
        }

        uint256 subPrice = subscriptionPrice;
        uint256 ethRequired = numSubs * subPrice;
        uint256 referralAmount;

        if (msg.value != ethRequired) {
            revert SubscriptionManager__InvalidETHAmountProvided(msg.value, ethRequired);
        }

        if (referrer != address(0)) {
            if (block.timestamp <= LibMap.get(expiration, uint256(uint160(referrer)))) {
                if (referralPercent > 0) {
                    referralAmount = ethRequired * referralPercent / 100;
                }
            }
        }

        uint40 subLength = subscriptionLength;

        if (subLength == 0) {
            for (uint256 i = 0; i < numSubs;) {
                address addr = addresses[i];
                _requireValidAddress(addr);
                LibMap.set(expiration, uint256(uint160(addr)), type(uint40).max);

                emit SubscriptionPaid(addr, MAX_UINT40, subPrice);

                unchecked {
                    ++i;
                }
            }
        } else {
            uint40 maxExpiration = type(uint40).max - subLength;
            for (uint256 i = 0; i < numSubs;) {
                address addr = addresses[i];
                _requireValidAddress(addr);
                uint40 addrExpiration = _increaseExpiration(addr, subLength, maxExpiration);

                emit SubscriptionPaid(addr, addrExpiration, subPrice);

                unchecked {
                    ++i;
                }
            }
        }

        if (referralAmount > 0) {
            // We use `transfer` here to limit the amount of gas forwarded to the referrer
            // As such, referrer addresses should be EOAs or contracts without fallback / receive functionality
            payable(referrer).transfer(referralAmount);
            emit ReferralPaid(referrer, referralAmount);
        }
    }

    /**
     * @notice Allows a user to stake CHART for a period of time.  Successfully meeting the threshold
     * @notice will grant the user a subscription for a set amount of time.
     *
     * @dev    - Throws if the provided CHART amount is too low for the provided stake length
     * @dev    - Throws if the provided stake length is > `MAX_STAKE_LENGTH`
     * @dev    - Throws if the provided stake length is < `MIN_STAKE_LENGTH`
     * @dev    - Throws if the address already has an active subscription
     * @dev    - Throws if the required CHART amount is not approved for transfer
     *
     * @dev    On completion:
     * @dev    - `msg.sender` has `chartRequired` CHART transferred from their account to this contract
     * @dev    - `msg.sender` has `amount` CHART staked for `stakeLength` seconds
     * @dev    - `subscriberAddress` expiration timestamp is set to `block.timestamp` + `STAKE_SUBSCRIPTION_LENGTH`
     * @dev    - `subscriberAddress` staking expiration timestamp is set to `block.timestamp` + `stakeLength`
     */
    function stake(uint40 stakeLength, address[] calldata addresses) external {
        uint256 numSubs = addresses.length;
        if (numSubs == 0) {
            revert SubscriptionManager__MustProvideAtLeastOneAddress();
        }

        StakingConfig memory config = stakingConfig;
        if (stakeLength > config.maxStakingLength) {
            revert SubscriptionManager__StakeLengthGreaterThanMaximumLength();
        }
        if (stakeLength < config.minStakingLength) {
            revert SubscriptionManager__StakeLengthLessThanMinimumLength();
        }

        uint256 chartPerAccount = config.maxStakingAmount - ((stakeLength - config.minStakingLength) * config.step);
        uint256 chartRequired = chartPerAccount * numSubs;
        uint40 subscriptionExpirationTimestamp = uint40(block.timestamp + config.stakeSubscriptionLength);
        uint40 stakingExpirationTimestamp = uint40(block.timestamp + stakeLength);

        chart.transferFrom(msg.sender, address(this), chartRequired);
        
        for(uint256 i = 0; i < numSubs;) {
            address subscriberAddress = addresses[i];
            _requireValidAddress(subscriberAddress);
            if (block.timestamp <= LibMap.get(expiration, uint256(uint160(subscriberAddress)))) {
                revert SubscriptionManager__CannotStakeForAccountsWithCurrentSubscription();
            }

            LibMap.set(expiration, uint256(uint160(subscriberAddress)), subscriptionExpirationTimestamp);
            staking[subscriberAddress] = StakingInfo(msg.sender, stakeLength, stakingExpirationTimestamp, chartPerAccount);

            emit Staked(subscriberAddress, stakeLength, chartPerAccount, stakingExpirationTimestamp);

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Allows a user to unstake CHART after the expiration timestamp has passed.
     * 
     * @dev    - Throws if any of the provided addresses do not have an active stake
     * @dev    - Throws if any of the provided addresses have not passed their staking expiration timestamp
     * @dev    - Throws if `msg.sender` is not the staker for any of the addresses provided
     *
     * @dev    On completion:
     * @dev    - `msg.sender` has the sum of all `stakedAmount` assigned to the addresses CHART transferred from this contract to their account
     * @dev    - the addresses provided have their staking information removed
     *
     * @param  addresses A list of addresses to unstake for
     */
     function unstake(address[] calldata addresses) external {
        uint256 numSubs = addresses.length;
        if (numSubs == 0) {
            revert SubscriptionManager__MustProvideAtLeastOneAddress();
        }

        uint256 amountToRefund = 0;

        for(uint256 i = 0; i < numSubs;) {
            address subscriberAddress = addresses[i];
            _requireValidAddress(subscriberAddress);

            StakingInfo memory info = staking[subscriberAddress];
            if (info.stakedAmount == 0) {
                revert SubscriptionManager__CannotUnstakeForAccountsWithoutStake();
            }
            if (block.timestamp <= info.stakingExpirationTimestamp) {
                revert SubscriptionManager__CannotUnstakeForAccountsWithActiveStake();
            }
            if (msg.sender != info.staker) {
                revert SubscriptionManager__MustBeStakerToUnstake();
            }

            amountToRefund += info.stakedAmount;

            delete staking[subscriberAddress];
            emit Unstaked(subscriberAddress, info.stakedAmount);

            unchecked {
                ++i;
            }
        }
        chart.transfer(msg.sender, amountToRefund);
     }

    /**
     * @notice Allows a user to restake CHART if they have less than 1 month remaining on their stake expiration
     * @notice This function will extend your stake by the original stake length.  If you would like to 
     * @notice extend your stake by a different amount, unstake and then use the `stake` function.
     *
     * @dev    - Throws if any of the provided addresses do not have an active stake
     * @dev    - Throws if any of the provided addresses have more than 1 month remaining on their stake expiration
     * @dev    - Throws if `msg.sender` is not the staker
     * 
     * @dev    On completion:
     * @dev    - `msg.sender` has the sum of all `stakedAmount` assigned to the addresses CHART transferred from their account to this contract
     * @dev    - The addresses provided have their subscription extended by 6 months
     * @dev    - The addresses provided have their stake expiration timestamp extended by the required amount
     *
     * @param  addresses A list of addresses to restake for
     */
    function restake(address[] calldata addresses) external {
        uint256 numSubs = addresses.length;
        if (numSubs == 0) {
            revert SubscriptionManager__MustProvideAtLeastOneAddress();
        }

        for(uint256 i = 0; i < numSubs;) {
            address subscriberAddress = addresses[i];
            _requireValidAddress(subscriberAddress);

            StakingInfo memory info = staking[subscriberAddress];
            if (info.stakedAmount == 0) {
                revert SubscriptionManager__CannotRestakeForAccountsWithoutStake();
            }
            if (block.timestamp < info.stakingExpirationTimestamp - 30 days) {
                revert SubscriptionManager__CannotRestakeForAccountsWithMoreThanOneMonthRemaining();
            }
            if (info.staker != msg.sender) {
                revert SubscriptionManager__MustBeStakerToRestake();
            }

            staking[subscriberAddress].stakingExpirationTimestamp += info.stakeLength;
            StakingConfig memory config = stakingConfig;
            _increaseExpiration(subscriberAddress, config.stakeSubscriptionLength, type(uint40).max - config.stakeSubscriptionLength);
            emit Restaked(subscriberAddress, info.stakedAmount);

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Uses fees from subscriptions to buyback and burn CHART from the uniswap v2 pair
     *
     * @dev    This is a high risk function, anyone with KEEPER_ROLE could potentially sandwich this call
     * @dev    Do not give KEEPER_ROLE to addresses unless you fully trust them
     * @dev    If you would like to ignore slippage, pass in 0 for amountOutMin
     * @dev    - Throws if `msg.sender` does not have owner or `KEEPER_ROLE`
     * @dev    - Throws if there is an error sending funds to `msg.sender`
     *
     * @dev    On completion:
     * @dev    - `burnPercent`% of the balance of the contract is used to buy and burn CHART
     * @dev    - The remaining balance is sent to the `msg.sender` to cover operational expenses
     * @dev    - address(this).balance == 0
     *
     * @param  amountOutMin Minimum amount of CHART to receive from `burnPercent`% * balance ETH
     */
    function burnETH(uint256 amountOutMin) external {
        _checkRolesOrOwner(KEEPER_ROLE);
        uint256 balance = address(this).balance;

        uint256 amountToBurn = balance * burnPercent / 100;
        uint256 amountToSend = balance - amountToBurn;

        address[] memory path = new address[](2);
        path[0] = router.WETH();
        path[1] = address(chart);

        router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amountToBurn}(
            amountOutMin,
            path,
            address(0xdead),
            block.timestamp
        );

        // Gated role, do not need to worry about gas to forward
        (bool success,) = payable(msg.sender).call{value: amountToSend}("");
        if (!success) {
            revert SubscriptionManager__ErrorSendingKeeperFunds();
        }
    }

    /**
     * @notice Returns if an address has a current subscription
     *
     * @param  user Address of user
     * @return True if user has an active subscription, false if not
     */
    function isAddressRegistered(address user) external view returns (bool) {
        return block.timestamp <= LibMap.get(expiration, uint256(uint160(user)));
    }

    /**
     * @notice Returns the expiration timestamp for a given address
     *
     * @param  user Address of user
     * @return Expiration timestamp for the provided address
     */
    function getExpiration(address user) external view returns (uint40) {
        return LibMap.get(expiration, uint256(uint160(user)));
    }

    /**
     * @notice Returns the staking expiration timestamp for a given address
     *
     * @param  user Address of user
     * @return Staking expiration timestamp for the provided address
     */
    function getStakingExpiration(address user) external view returns (uint40) {
        return staking[user].stakingExpirationTimestamp;
    }

    /**
     * @notice Returns the amount of CHART required to stake for the provided amount of time
     *
     * @dev    - Throws if `stakeLength` > maxStakingLength
     * @dev    - Throws if `stakeLength` < minStakingLength
     *
     * @param  stakeLength Length of time to stake CHART
     * @return Amount of CHART required to stake
     */
    function chartRequiredForStake(uint40 stakeLength) external view returns (uint256) {
        StakingConfig memory config = stakingConfig;
        if (stakeLength > config.maxStakingLength) {
            revert SubscriptionManager__StakeLengthGreaterThanMaximumLength();
        }
        if (stakeLength < config.minStakingLength) {
            revert SubscriptionManager__StakeLengthLessThanMinimumLength();
        }
        return config.maxStakingAmount - ((stakeLength - config.minStakingLength) * config.step);
    }

    /**
     * @notice Returns if the provided address is eligible to restake
     *
     * @param  addr Address to check
     * @return True if the address is eligible to restake, false if not
     */
    function canRestake(address addr) external view returns (bool) {
        StakingInfo memory info = staking[addr];
        return info.stakedAmount > 0 && block.timestamp < info.stakingExpirationTimestamp - 30 days;
    }

    function _increaseExpiration(address addr, uint40 subLength, uint40 maxExpiration) internal returns (uint40) {
        uint256 uintAddr = uint256(uint160(addr));
        uint40 addrExpiration = LibMap.get(expiration, uintAddr);
        uint40 timestamp = uint40(block.timestamp);
        if (addrExpiration <= timestamp) {
            if (timestamp > maxExpiration) {
                addrExpiration = type(uint40).max;
            } else {
                addrExpiration = timestamp + subLength;
            }
        } else if (addrExpiration < maxExpiration) {
            // Unchecked is safe here as we know that expiration + subLength < MAX_UINT40
            unchecked {
                addrExpiration += subLength;
            }
        } else {
            addrExpiration = type(uint40).max;
        }
        LibMap.set(expiration, uintAddr, addrExpiration);

        return addrExpiration;
    }

    /// @dev Convenience function to require user is owner
    function _requireIsOwner() internal view {
        if (msg.sender != owner()) {
            revert SubscriptionManager__OnlyOwner();
        }
    }

    /// @dev Convenience function to validate address input
    function _requireValidAddress(address addr) internal pure {
        if (addr == address(0)) {
            revert SubscriptionManager__CannotRegisterAddressZero();
        }
    }
}
