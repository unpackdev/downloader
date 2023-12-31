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
 * @dev the UniswapV2 LP Pool
 */
contract SubscriptionManager is OwnableRoles {
    uint40 internal constant MAX_UINT40 = type(uint40).max;
    uint256 public constant KEEPER_ROLE = uint256(1);

    Nchart public immutable chart;
    IUniswapV2Router02 public immutable router;

    LibMap.Uint40Map private expiration;

    uint256 public subscriptionPrice = 0.015 ether; // Price is 0.015e to start
    uint256 public referralFeePriceReduction = 0.001 ether; // Reduction of fee per address if referral is provided
    uint40 public subscriptionLength; // Lifetime subscription to start
    // Percent of fees to use to buy and burn CHART
    uint8 public burnPercent = 99;
    // Percent of fees to send to referrer if they have an active subscription
    uint8 public referralPercent = 5;

    event BurnPercentUpdated(uint8 newPercent, uint8 oldPercent);
    event ReferralPaid(address indexed referrer, uint256 amount);
    event ReferralFeePriceReductionUpdated(uint256 newAmount, uint256 oldAmount);
    event ReferralPercentUpdated(uint8 newPercent, uint8 oldPercent);
    event SubscriptionLengthUpdated(uint256 newLength, uint256 oldLength);
    event SubscriptionPaid(address indexed subscriber, uint40 expirationTimestamp, uint256 price);
    event SubscriptionPriceUpdated(uint256 newPrice, uint256 oldPrice);

    error SubscriptionManager__BurnPercentMustBeGreaterThan50();
    error SubscriptionManager__BurnPercentMustBeLessThan100();
    error SubscriptionManager__CannotReferSelf();
    error SubscriptionManager__CannotReduceMoreThanSubscriptionPrice();
    error SubscriptionManager__CannotRegisterAddressZero();
    error SubscriptionManager__CanOnlyIncreaseExpiration();
    error SubscriptionManager__ErrorRetrievingPriceFromDataFeed();
    error SubscriptionManager__ErrorSendingKeeperFunds();
    error SubscriptionManager__InvalidETHAmountProvided(uint256 msgValue, uint256 ethRequired);
    error SubscriptionManager__MaxFiftyPercentReferralPercent();
    error SubscriptionManager__MustProvideAtLeastOneAddress();
    error SubscriptionManager__OnlyOwner();
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
     * @notice Sets the amount fees are reduced per account when providing a referral
     *
     * @dev    - Throws if `msg.sender` != `owner()`
     * @dev    - Throws if provided reduction amount is greater than subscription price
     *
     * @dev    On completion:
     * @dev    - `referralFeePriceReduction` = `newAmount`
     * @dev    - Emits {ReferralFeePriceReductionUpdated} event
     *
     * @param newAmount Amount to reduce fees per address if referral provided
     */
    function setReferralFeePriceReduction(uint256 newAmount) external {
        _requireIsOwner();

        if (newAmount >= subscriptionPrice) {
            revert SubscriptionManager__CannotReduceMoreThanSubscriptionPrice();
        }

        uint256 oldReferralFeePriceReduction = referralFeePriceReduction;
        referralFeePriceReduction = newAmount;
        emit ReferralFeePriceReductionUpdated(newAmount, oldReferralFeePriceReduction);
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
        uint256 referralFeeReduction = referrer != address(0) ? referralFeePriceReduction * numSubs : 0;
        uint256 ethRequired = numSubs * subPrice;
        uint256 referralAmount;

        if (block.timestamp <= LibMap.get(expiration, uint256(uint160(referrer)))) {
            if (referralPercent > 0) {
                referralAmount = ethRequired * referralPercent / 100;
            }
        }

        if (referralFeeReduction > 0) {
            ethRequired -= referralFeeReduction;
        }

        if (msg.value != ethRequired) {
            revert SubscriptionManager__InvalidETHAmountProvided(msg.value, ethRequired);
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
                uint40 addrExpiration = LibMap.get(expiration, uint256(uint160(addr)));
                uint40 timestamp = uint40(block.timestamp);

                if (addrExpiration < timestamp) {
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

                LibMap.set(expiration, uint256(uint160(addr)), addrExpiration);

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

    function getExpiration(address user) external view returns (uint40) {
        return LibMap.get(expiration, uint256(uint160(user)));
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
