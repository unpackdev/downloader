// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./Tiers.sol";
import "./PurchasingCenter.sol";
// import "./Ownable.sol";
import "./IERC20.sol";
import "./console.sol";
import "./ReentrancyGuard.sol";
import "./UnrenounceableOwnable2Step.sol";
import "./Pausable.sol";

contract ClaimingCenter is
    Tiers,
    UnrenounceableOwnable2Step,
    Pausable,
    ReentrancyGuard
{
    IERC20 public commodity;
    address payable purchasingCenterAddress;
    PurchasingCenter public purchasingCenter;

    /** @dev For accounting how many tokens are already claimed. And to determine if a user has already claimed.  */
    mapping(address => mapping(Tier => uint256))
        public address_to_tier_to_tokens_claimed;
    /** @dev For accounting the total amount of tokens claimed. */
    mapping(Tier => uint256) public tier_to_tokens_claimed;

    /** @dev For accounting how many eth a user has already been refunded.  */
    mapping(address => mapping(Tier => uint256))
        public address_to_tier_eth_to_refund_claimed;
    /** @dev For accounting the total refunds of a tier.  */
    mapping(Tier => uint256) public tier_to_refunds_claimed;

    /**  @dev For keeping track of the commodity reserves in this contract. 
    We do not simply use commodity.balanceOf(address(this)) for our reserve accounting to avoid external manipulation via deposits. */
    uint256 public commodityReserves;
    /**  @dev For keeping track of the Eth reserves in this contract. 
    We do not simply use address(this).balance for our reserve accounting to avoid external manipulation via deposits. */
    uint256 public refundReserves;

    bool public claimsStarted;
    bool public refundsStarted;

    event EntireEthBalanceWithdrawn(address to, uint256 amount);
    event EthReservesDeposited(uint256 amount);
    event EthReservesWithdrawn(address to, uint256 amount);
    event RefundsClaimed(uint256 tier, address guy, uint256 refundAmount);
    event RefundsStarted(uint256 time);
    event CommodityDeposited(uint256 amount);
    event CommodityWithdraw(address to, uint256 amount);
    event CommodityClaimed(uint256 tier, address guy, uint256 claimAmount);
    event ClaimsStarted(uint256 time);

    constructor(address _commodity, address _purchasingCenter) {
        commodity = IERC20(_commodity);
        // Since you cannot have state variables in interfaces,
        // To access the public state variables in purchasingCenter we will need the whole contract.
        purchasingCenterAddress = payable(_purchasingCenter);
        purchasingCenter = PurchasingCenter(purchasingCenterAddress);
        claimsStarted = false;
    }

    /**
     * ╭────────────────────────────────────────╮
     * │ * * * onlyOwner start functions. * * * │
     * ╰────────────────────────────────────────╯
     */

    modifier whenClaimsNotStarted() {
        require(claimsStarted == false, "Claims started already!");
        _;
    }
    modifier whenClaimsStarted() {
        require(claimsStarted == true, "Claims not started yet!");
        _;
    }

    modifier whenRefundsNotStarted() {
        require(refundsStarted == false, "Refunds started already!");
        _;
    }
    modifier whenRefundsStarted() {
        require(refundsStarted == true, "Refunds not started yet!");
        _;
    }

    function startClaims()
        external
        whenNotPaused
        onlyOwner
        whenClaimsNotStarted
    {
        // once started it's impossible unstart / pause.
        claimsStarted = true;
        emit ClaimsStarted(block.timestamp);
    }

    function startRefunds()
        external
        whenNotPaused
        onlyOwner
        whenRefundsNotStarted
    {
        // once started it's impossible unstart / pause.
        refundsStarted = true;
        emit RefundsStarted(block.timestamp);
    }

    /**
     * ╭───────────────────────────────────────────╮
     * │ * * * Miscellaneous view functions. * * * │
     * ╰───────────────────────────────────────────╯
     */

    /** @dev Function that checks how much a user has bought in a given tier
     * from the purchasingCenter contract. The point of this function is to offload
     * as many mentions of purchasingCenter as possible.
     */
    function getTokensBoughtByUserAndTier(
        address user,
        uint256 tier
    ) public view returns (uint256) {
        uint256 amount = purchasingCenter.getTokensBoughtByUserAndTier(
            user,
            tier
        );
        return amount;
    }

    function getRefundClaimedByUserAndTier(
        address guy,
        uint256 tier
    ) external view returns (uint256) {
        Tier _tier = _t(tier);
        uint256 refundsClaimed = address_to_tier_eth_to_refund_claimed[guy][
            _tier
        ];
        return refundsClaimed;
    }

    function getTokensClaimedByUserAndTier(
        address guy,
        uint256 tier
    ) external view returns (uint256) {
        Tier _tier = _t(tier);
        uint256 tokensClaimed = address_to_tier_to_tokens_claimed[guy][_tier];
        return tokensClaimed;
    }

    function getTokensClaimedByTier(
        uint256 tier
    ) external view returns (uint256) {
        Tier _tier = _t(tier);
        uint256 tokensClaimed = tier_to_tokens_claimed[_tier];
        return tokensClaimed;
    }

    /**
     * ╭─────────────────────────────────────────────╮
     * │ * * * User claim commodity functions. * * * │
     * ╰─────────────────────────────────────────────╯
     */

    /** @dev Users call this function to see how much they can claim (eventually) for a given tier.
     * This function does not care about whether a tier has been unlocked.
     */
    function claimable(
        address user,
        uint256 tier
    ) public view returns (uint256) {
        Tier _tier = _t(tier);
        uint256 amount = getTokensBoughtByUserAndTier(user, tier);
        uint256 claimed = address_to_tier_to_tokens_claimed[user][_tier];
        uint256 forClaim = amount - claimed;
        return forClaim;
    }

    /** @dev This function tells whether a tier has been unlocked.
     */
    function claimablesUnlocked(uint256 tier) external view returns (bool) {
        (, , uint256 lockupTime, ) = purchasingCenter.getTierDetails(tier);
        uint256 startTime = purchasingCenter.startTime();
        uint256 purchaseWindow = purchasingCenter.purchaseWindow();

        if (block.timestamp >= startTime + purchaseWindow + lockupTime) {
            return true;
        } else {
            return false;
        }
    }

    /** @dev The function for users to claim their tokens of a given tier.
     */
    function claim(
        uint256 tier
    )
        external
        whenNotPaused
        nonReentrant
        whenClaimsStarted
        returns (bool success)
    {
        Tier _tier = _t(tier);
        address guy = msg.sender;
        uint256 amountClaimed = address_to_tier_to_tokens_claimed[guy][_tier];
        require(amountClaimed == 0, "Claimed already!");
        uint256 claimableAmount = claimable(guy, tier);
        require(
            claimableAmount <= commodity.balanceOf(address(this)),
            "Insufficient reserves"
        );
        uint256 amountToClaim = getTokensBoughtByUserAndTier(guy, tier);
        require(amountToClaim > 0, "No amount bought");

        (, , uint256 lockupTime, ) = purchasingCenter.getTierDetails(tier);
        uint256 startTime = purchasingCenter.startTime();
        uint256 purchaseWindow = purchasingCenter.purchaseWindow();
        require(
            block.timestamp >= lockupTime + startTime + purchaseWindow,
            "Not yet unlocked!"
        );
        success = commodity.transfer(guy, amountToClaim);
        require(success, "Transfer didn't go through");
        if (success) {
            address_to_tier_to_tokens_claimed[guy][_tier] += amountToClaim;
            tier_to_tokens_claimed[_tier] += amountToClaim;
            commodityReserves -= amountToClaim;
            emit CommodityClaimed(tier, guy, amountToClaim);
            return success;
        }
    }

    /**
     * ╭─────────────────────────────────────────────────────────────────╮
     * │ * * * OnlyOwner Commodity Deposit & Withdrawal functions. * * * │
     * ╰─────────────────────────────────────────────────────────────────╯
     */

    /** @dev Function for the owner to deposit the commodity.
     */
    function depositCommodity(
        uint256 amount
    ) external onlyOwner returns (bool success) {
        success = commodity.transferFrom(
            msg.sender,
            payable(address(this)),
            amount
        );
        require(success, "Not deposited!");
        if (success) {
            commodityReserves += amount;
            emit CommodityDeposited(amount);
            return success;
        }
    }

    /** @dev Function for the owner to withdraw a certain amount
     * of the commodities living in this contract.
     */
    function withdrawCommodity(
        address to,
        uint256 amount
    ) external nonReentrant onlyOwner returns (bool success) {
        success = commodity.transfer(to, amount);

        require(success, "transfer not successful!");
        if (success) {
            commodityReserves -= amount;
            emit CommodityWithdraw(to, amount);
            return success;
        }
    }

    /** @dev Function for the owner to withdraw the entire balance of the commodity
     * living in this contract.
     */
    function withdrawEntireCommodityBalance(
        address to
    ) external nonReentrant onlyOwner returns (bool success) {
        uint256 amount = commodity.balanceOf(address(this));
        success = commodity.transfer(to, amount);

        require(success, "transfer not successful!");
        if (success) {
            commodityReserves = 0;
            emit CommodityWithdraw(to, amount);
            return success;
        }
    }

    /** @dev View function to see balance of commodities sitting in this contract.
    Not the commodityReserves. */
    function commodityBalance() external view returns (uint256 amount) {
        amount = commodity.balanceOf(address(this));
        return amount;
    }

    /**
     * ╭────────────────────────────────────╮
     * │ * * * User refund functions. * * * │
     * ╰────────────────────────────────────╯
     */

    /** @dev This function checks how much a user is entitled to claim.
     * Note that claims are not dependent on whether the commodity tokens themselves are unlocked.
     */
    function refundClaimable(
        address guy,
        uint256 tier
    ) public view returns (uint256 amount) {
        amount = purchasingCenter.refundAmount(guy, tier);
        return amount;
    }

    /** @dev User can claim their refunds here.
     * Note that claims are not dependent on whether the commodity tokens themselves are unlocked.
     */
    function claimRefunds(
        uint256 tier
    )
        external
        whenNotPaused
        whenRefundsStarted
        nonReentrant
        returns (bool success)
    {
        address guy = msg.sender;
        uint256 refundAmount = refundClaimable(guy, tier);
        Tier _tier = _t(tier);
        require(
            address_to_tier_eth_to_refund_claimed[guy][_tier] == 0,
            "claimRefunds(): already refunded!"
        );
        require(
            address(this).balance > 0,
            "claimRefunds(): insufficient balances"
        );
        require(refundAmount > 0, "Nothing to refund!");

        (success, ) = payable(guy).call{value: refundAmount}("");
        require(success, "refund didn't go through!");
        if (success) {
            address_to_tier_eth_to_refund_claimed[guy][_tier] = refundAmount; // Updates the amount of refund a guy has claimed.
            tier_to_refunds_claimed[_tier] += refundAmount; // Updates the total amount of refunds claimed in a tier.
            refundReserves -= refundAmount;
            return success;
        }
        emit RefundsClaimed(tier, guy, refundAmount);
    }

    /** @dev View function to see the total amount of refunds of a tier.
     */
    function tierRefundsClaimable(
        uint256 tier
    ) external view returns (uint256) {
        Tier _tier = _t(tier);
        uint256 totalContribution = purchasingCenter.tier_to_totalContribution(
            _tier
        );
        uint256 refundsClaimed = tier_to_refunds_claimed[_tier];
        uint256 unclaimed_refunds = totalContribution - refundsClaimed;
        return unclaimed_refunds;
    }

    /**
     * ╭─────────────────────────────────────────────────────────╮
     * │ * * * Commodity deposit and withdrawal functions. * * * │
     * ╰─────────────────────────────────────────────────────────╯
     */

    /** @dev Payable function to deposit ETH to reserves.
     */
    function depositEthToReserves()
        external
        payable
        nonReentrant
        returns (bool success)
    {
        uint256 eth_in = msg.value;
        require(eth_in > 0, "Eth deposit cannot be 0");
        refundReserves += eth_in;
        emit EthReservesDeposited(eth_in);
        return true;
    }

    /** @dev */
    // Function to withdraw ETH from reserves (onlyOwner)
    function withdrawEthReserves(
        address to,
        uint256 amount
    ) external onlyOwner nonReentrant returns (bool success) {
        require(amount > 0, "Withdrawal amount must be greater than 0");
        require(amount <= refundReserves, "Insufficient balance in reserves");

        (success, ) = payable(to).call{value: amount}("");
        require(success, "Eth not withdrawn!");
        if (success) {
            refundReserves -= amount;
            emit EthReservesWithdrawn(to, amount);
            return success;
        }
    }

    /** @dev  Function to withdraw all ETH from reserves (onlyOwner).
     */
    function withdrawEntireEthBalance(
        address to
    ) external onlyOwner nonReentrant returns (bool success) {
        uint256 balance = address(this).balance;
        require(balance > 0, "No balance in reserves to withdraw");
        (success, ) = payable(to).call{value: balance}("");
        require(success, "Eth not withdrawn!");
        if (success) {
            refundReserves = 0;
            emit EntireEthBalanceWithdrawn(to, balance);
            return success;
        }
    }

    /**
     * ╭───────────────────────────────────────────────────╮
     * │ * * * Eth deposit and withdrawal functions. * * * │
     * ╰───────────────────────────────────────────────────╯
     */

    // Helper function to check the balance of this contract - not the reserves.
    function ethBalance() external view returns (uint256 balance) {
        balance = address(this).balance;
        return balance;
    }

    // Function to receive Ether. msg.data must be empty
    receive() external payable {}

    // Fallback function is called when msg.data is not empty
    fallback() external payable {}
}
