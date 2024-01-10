// SPDX-License-Identifier: MIT
pragma solidity =0.8.7;

import "./Ownable.sol";
import "./Pausable.sol";

/// @title RareBlocksSubscription contract
/// @author poster & SterMi
/// @notice Manage RareBlocks subscription for an amount of months
contract RareBlocksSubscription is Ownable, Pausable {
    /*///////////////////////////////////////////////////////////////
                             STORAGE VARIABLES
    //////////////////////////////////////////////////////////////*/

    /// @notice Subscription price per month
    uint256 public subscriptionMonthlyPrice;

    /// @notice map of subscriptions made by users that store the expire time for a subscription
    mapping(address => uint256) public subscriptions;

    /// @notice Treasury contract address
    address public treasury;

    /// @notice Affiliate fee percentage
    /// @dev 0 = 0%, 5000 = 50%, 10000 = 100%
    uint256 public referrerFee = 2000;

    /*///////////////////////////////////////////////////////////////
                             CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        uint256 _subscriptionMonthlyPrice,
        address _treasury
    ) Ownable() {
        // check that all the parameters are valid
        require(_subscriptionMonthlyPrice != 0, "INVALID_PRICE_PER_MONTH");
        require(_treasury != address(0), "INVALID_TREASURY_ADDRESSS");

        subscriptionMonthlyPrice = _subscriptionMonthlyPrice;
        treasury = _treasury;
    }

    /*///////////////////////////////////////////////////////////////
                             PAUSE LOGIC
    //////////////////////////////////////////////////////////////*/

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    /*///////////////////////////////////////////////////////////////
                             REFERRER LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice Emitted after the owner update the referrer fee
    /// @param user The authorized user who triggered the update
    /// @param newReferrerFee The referrer fee paid to referrer
    event ReferrerFeeUpdated(address indexed user, uint256 newReferrerFee);

    function setReferrerFee(uint256 newReferrerFee) external onlyOwner {
        require(newReferrerFee != 0, "INVALID_PERCENTAGE");
        require(referrerFee != newReferrerFee, "SAME_FEE");
        require(newReferrerFee <= 10_000, "MAX_REACHED");

        referrerFee = newReferrerFee;

        emit ReferrerFeeUpdated(msg.sender, newReferrerFee);
    }

    /*///////////////////////////////////////////////////////////////
                             SUBSCRIPTION LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice Emitted after the owner update the monthly price of a rareblocks
    /// @param user The authorized user who triggered the update
    /// @param newSubscriptionMonthlyPrice The price to subscribe to a RareBlocks pass for 1 month
    event SubscriptionMonthPriceUpdated(address indexed user, uint256 newSubscriptionMonthlyPrice);

    /// @notice Emitted after a user has subscribed to a RareBlocks pass
    /// @param user The user who purchased the pass subscription
    /// @param months The amount of month of the subscription
    /// @param price The price paid to subscribe to the pass
    event Subscribed(address indexed user, uint256 months, uint256 price);

    /// @notice Emitted after a user has subscribed to a RareBlocks pass
    /// @param user The user who purchased the pass subscription
    /// @param referrer The affiliate who got paid
    /// @param fee The price paid to subscribe to the pass
    event PaidReferrer(address indexed user, address indexed referrer, uint256 fee);

    function setSubscriptionMonthlyPrice(uint256 newSubscriptionMonthlyPrice) external onlyOwner {
        require(newSubscriptionMonthlyPrice != 0, "INVALID_PRICE");
        require(subscriptionMonthlyPrice != newSubscriptionMonthlyPrice, "SAME_PRICE");

        subscriptionMonthlyPrice = newSubscriptionMonthlyPrice;

        emit SubscriptionMonthPriceUpdated(msg.sender, newSubscriptionMonthlyPrice);
    }

    function subscribe(uint256 months, address referrer) external payable whenNotPaused {
        // Check that the user amount of months is valid
        require(months > 0 && months <= 12, "INVALID_AMOUNT_OF_MONTHS");

        uint256 totalPrice = months * subscriptionMonthlyPrice;

        // Provide 3 months free when signing up yearly
        if(months == 12){
            totalPrice = 9 * subscriptionMonthlyPrice;
        }

        // check if the user has sent enough funds to subscribe to the pass
        require(msg.value == totalPrice, "NOT_ENOUGH_FUNDS");

        // check that the user has not an active pass
        require(subscriptions[msg.sender] < block.timestamp, "SUBSCRIPTION_STILL_ACTIVE");

        // Update subscriptions
        subscriptions[msg.sender] = block.timestamp + (31 days * months);

        // emit the event
        emit Subscribed(msg.sender, months, totalPrice);

        // Payout affiliate if not null address and not own wallet
        if(referrer != address(0) && referrer != msg.sender){
            uint256 affiliateAmount = (msg.value * referrerFee) / 10_000;
            (bool success, ) = referrer.call{value: affiliateAmount}("");
            require(success, "WITHDRAW_FAIL");

            emit PaidReferrer(msg.sender, referrer, affiliateAmount);
        }
    }

    function isSubscriptionActive(address _address) external view returns (bool) {
        return subscriptions[_address] > block.timestamp;
    }

    /*///////////////////////////////////////////////////////////////
                             TREASURY LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice Emitted after the owner pull the funds to the treasury address
    /// @param user The authorized user who triggered the withdraw
    /// @param treasury The treasury address to which the funds have been sent
    /// @param amount The amount withdrawn
    event TreasuryWithdraw(address indexed user, address treasury, uint256 amount);

    /// @notice Emitted after the owner pull the funds to the treasury address
    /// @param user The authorized user who triggered the withdraw
    /// @param newTreasury The new treasury address
    event TreasuryUpdated(address indexed user, address newTreasury);

    function setTreasury(address _treasury) external onlyOwner {
        // check that the new treasury address is valid
        require(_treasury != address(0), "INVALID_TREASURY_ADDRESS");
        require(treasury != _treasury, "SAME_TREASURY_ADDRESS");

        // update the treasury
        treasury = _treasury;

        // emit the event
        emit TreasuryUpdated(msg.sender, _treasury);
    }

    function withdrawTreasury() external onlyOwner {
        // calc the amount of balance that can be sent to the treasury
        uint256 amount = address(this).balance;
        require(amount != 0, "NO_TREASURY");

        // emit the event
        emit TreasuryWithdraw(msg.sender, treasury, amount);

        // Transfer to the treasury
        (bool success, ) = treasury.call{value: amount}("");
        require(success, "WITHDRAW_FAIL");
    }
}