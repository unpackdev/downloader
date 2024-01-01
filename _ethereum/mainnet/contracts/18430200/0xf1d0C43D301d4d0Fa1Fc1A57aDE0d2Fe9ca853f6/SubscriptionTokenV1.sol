// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./StringsUpgradeable.sol";
import "./Ownable2StepUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./ERC721Upgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./Shared.sol";

/**
 * @title Subscription Token Protocol Version 1
 * @author Fabric Inc.
 * @notice An NFT contract which allows users to mint time and access token gated content while time remains.
 * @dev The balanceOf function returns the number of seconds remaining in the subscription. Token gated systems leverage
 *      the balanceOf function to determine if a user has the token, and if no time remains, the balance is 0. NFT holders
 *      can mint additional time. The creator/owner of the contract can withdraw the funds at any point. There are
 *      additional functionalities for granting time, refunding accounts, fees, rewards, etc. This contract is designed to be used with
 *      Clones, but is not designed to be upgradeable. Added functionality will come with new versions.
 */

contract SubscriptionTokenV1 is
    ERC721Upgradeable,
    Ownable2StepUpgradeable,
    ReentrancyGuardUpgradeable,
    PausableUpgradeable
{
    using SafeERC20 for IERC20;
    using StringsUpgradeable for uint256;

    /// @dev The maximum number of reward halvings (limiting this prevents overflow)
    uint256 private constant _MAX_REWARD_HALVINGS = 32;

    /// @dev Maximum protocol fee basis points (12.5%)
    uint16 private constant _MAX_FEE_BIPS = 1250;

    /// @dev Maximum basis points (100%)
    uint16 private constant _MAX_BIPS = 10000;

    /// @dev Guard to ensure the purchase amount is valid
    modifier validAmount(uint256 amount) {
        require(amount >= _minimumPurchase, "Amount must be >= minimum purchase");
        _;
    }

    /// @dev Emitted when the owner withdraws available funds
    event Withdraw(address indexed account, uint256 tokensTransferred);

    /// @dev Emitted when a subscriber withdraws their rewards
    event RewardWithdraw(address indexed account, uint256 tokensTransferred);

    /// @dev Emitted when a subscriber slashed the rewards of another subscriber
    event RewardPointsSlashed(address indexed account, address indexed slasher, uint256 rewardPointsSlashed);

    /// @dev Emitted when tokens are allocated to the reward pool
    event RewardsAllocated(uint256 tokens);

    /// @dev Emitted when time is purchased (new nft or renewed)
    event Purchase(
        address indexed account,
        uint256 indexed tokenId,
        uint256 tokensTransferred,
        uint256 timePurchased,
        uint256 rewardPoints,
        uint256 expiresAt
    );

    /// @dev Emitted when a subscriber is granted time by the creator
    event Grant(address indexed account, uint256 indexed tokenId, uint256 secondsGranted, uint256 expiresAt);

    /// @dev Emitted when the creator refunds a subscribers remaining time
    event Refund(address indexed account, uint256 indexed tokenId, uint256 tokensTransferred, uint256 timeReclaimed);

    /// @dev Emitted when the creator tops up the contract balance on refund
    event RefundTopUp(uint256 tokensIn);

    /// @dev Emitted when the fees are transferred to the collector
    event FeeTransfer(address indexed from, address indexed to, uint256 tokensTransferred);

    /// @dev Emitted when the fee collector is updated
    event FeeCollectorChange(address indexed from, address indexed to);

    /// @dev Emitted when tokens are allocated to the fee pool
    event FeeAllocated(uint256 tokens);

    /// @dev Emitted when a referral fee is paid out
    event ReferralPayout(
        uint256 indexed tokenId, address indexed referrer, uint256 indexed referralId, uint256 rewardAmount
    );

    /// @dev Emitted when a new referral code is created
    event ReferralCreated(uint256 id, uint16 rewardBps);

    /// @dev Emitted when a referral code is deleted
    event ReferralDestroyed(uint256 id);

    /// @dev Emitted when the supply cap is updated
    event SupplyCapChange(uint256 supplyCap);

    /// @dev Emitted when the transfer recipient is updated
    event TransferRecipientChange(address indexed recipient);

    /// @dev The subscription struct which holds the state of a subscription for an account
    struct Subscription {
        /// @dev The tokenId for the subscription
        uint256 tokenId;
        /// @dev The number of seconds purchased
        uint256 secondsPurchased;
        /// @dev The number of seconds granted by the creator
        uint256 secondsGranted;
        /// @dev A time offset used to adjust expiration for grants
        uint256 grantOffset;
        /// @dev A time offset used to adjust expiration for purchases
        uint256 purchaseOffset;
        /// @dev The number of reward points earned
        uint256 rewardPoints;
        /// @dev The number of rewards withdrawn
        uint256 rewardsWithdrawn;
    }

    /// @dev The metadata URI for the contract
    string private _contractURI;

    /// @dev The metadata URI for the tokens. Note: if it ends with /, then we append the tokenId
    string private _tokenURI;

    /// @dev The cost of one second in denominated token (wei or other base unit)
    uint256 private _tokensPerSecond;

    /// @dev Minimum number of seconds to purchase. Also, this is the number of seconds until the reward multiplier is halved.
    uint256 private _minPurchaseSeconds;

    /// @dev The minimum number of tokens accepted for a time purchase
    uint256 private _minimumPurchase;

    /// @dev The token contract address, or 0x0 for native tokens
    IERC20 private _token;

    /// @dev The total number of tokens transferred in (accounting)
    uint256 private _tokensIn;

    /// @dev The total number of tokens transferred out (accounting)
    uint256 private _tokensOut;

    /// @dev The token counter for mint id generation and enforcing supply caps
    uint256 private _tokenCounter;

    /// @dev The total number of tokens allocated for the fee collector (accounting)
    uint256 private _feeBalance;

    /// @dev The protocol fee basis points (10000 = 100%, max = _MAX_FEE_BIPS)
    uint16 private _feeBps;

    /// @dev The protocol fee collector address (for withdraws or sponsored transfers)
    address private _feeCollector;

    /// @dev Flag which determines if the contract is erc20 denominated
    bool private _erc20;

    /// @dev The block timestamp of the contract deployment (used for reward halvings)
    uint256 private _deployBlockTime;

    /// @dev The reward pool size (used to calculate reward withdraws accurately)
    uint256 private _totalRewardPoints;

    /// @dev The reward pool balance (accounting)
    uint256 private _rewardPoolBalance;

    /// @dev The reward pool total (used to calculate reward withdraws accurately)
    uint256 private _rewardPoolTotal;

    /// @dev The reward pool tokens slashed (used to calculate reward withdraws accurately)
    uint256 private _rewardPoolSlashed;

    /// @dev The basis points for reward allocations
    uint16 private _rewardBps;

    /// @dev The number of reward halvings. This is used to calculate the reward multiplier for early supporters, if the creator chooses to reward them.
    uint256 private _numRewardHalvings;

    /// @dev The maximum number of tokens which can be minted (adjustable over time, but will not allow setting below current count)
    uint256 private _supplyCap;

    /// @dev The address of the account which can receive transfers via sponsored calls
    address private _transferRecipient;

    /// @dev The subscription state for each account
    mapping(address => Subscription) private _subscriptions;

    /// @dev The collection of referral codes for referral rewards
    mapping(uint256 => uint16) private _referralCodes;

    ////////////////////////////////////

    /// @dev Disable initializers on the logic contract
    constructor() {
        _disableInitializers();
    }

    /// @dev Fallback function to mint time for native token contracts
    receive() external payable {
        mintFor(msg.sender, msg.value);
    }

    /**
     * @dev Initialize acts as the constructor, as this contract is intended to work with proxy contracts.
     * @param params the init params (See Common.InitParams)
     */
    function initialize(Shared.InitParams memory params) public initializer {
        require(bytes(params.name).length > 0, "Name cannot be empty");
        require(bytes(params.symbol).length > 0, "Symbol cannot be empty");
        require(bytes(params.contractUri).length > 0, "Contract URI cannot be empty");
        require(bytes(params.tokenUri).length > 0, "Token URI cannot be empty");
        require(params.owner != address(0), "Owner address cannot be 0x0");
        require(params.tokensPerSecond > 0, "Tokens per second must be > 0");
        require(params.minimumPurchaseSeconds > 0, "Min purchase seconds must be > 0");
        require(params.feeBps <= _MAX_FEE_BIPS, "Fee bps too high");
        require(params.rewardBps <= _MAX_BIPS, "Reward bps too high");
        require(params.numRewardHalvings <= _MAX_REWARD_HALVINGS, "Reward halvings too high");
        if (params.feeRecipient != address(0)) {
            require(params.feeBps > 0, "Fees required when fee recipient is present");
        }
        if (params.rewardBps > 0) {
            require(params.numRewardHalvings > 0, "Reward halvings too low");
        }

        __ERC721_init(params.name, params.symbol);
        _transferOwnership(params.owner);
        __Pausable_init_unchained();
        __ReentrancyGuard_init();
        _contractURI = params.contractUri;
        _tokenURI = params.tokenUri;
        _tokensPerSecond = params.tokensPerSecond;
        _minimumPurchase = params.minimumPurchaseSeconds * params.tokensPerSecond;
        _minPurchaseSeconds = params.minimumPurchaseSeconds;
        _rewardBps = params.rewardBps;
        _numRewardHalvings = params.numRewardHalvings;
        _feeBps = params.feeBps;
        _feeCollector = params.feeRecipient;
        _token = IERC20(params.erc20TokenAddr);
        _erc20 = params.erc20TokenAddr != address(0);
        _deployBlockTime = block.timestamp;
    }

    /////////////////////////
    // Subscriber Calls
    /////////////////////////

    /**
     * @notice Mint or renew a subscription for sender
     * @param numTokens the amount of ERC20 tokens or native tokens to transfer
     */
    function mint(uint256 numTokens) external payable {
        mintFor(msg.sender, numTokens);
    }

    /**
     * @notice Mint or renew a subscription for sender, with referral rewards for a referrer
     * @param numTokens the amount of ERC20 tokens or native tokens to transfer
     * @param referralCode the referral code to use
     * @param referrer the referrer address and reward recipient
     */
    function mintWithReferral(uint256 numTokens, uint256 referralCode, address referrer) external payable {
        mintWithReferralFor(msg.sender, numTokens, referralCode, referrer);
    }

    /**
     * @notice Withdraw available rewards. This is only possible if the subscription is active.
     */
    function withdrawRewards() external {
        Subscription memory sub = _subscriptions[msg.sender];
        require(_isActive(sub), "Subscription not active");
        uint256 rewardAmount = _rewardBalance(sub);
        require(rewardAmount > 0, "No rewards to withdraw");
        sub.rewardsWithdrawn += rewardAmount;
        _subscriptions[msg.sender] = sub;
        _rewardPoolBalance -= rewardAmount;
        _transferOut(msg.sender, rewardAmount);
        emit RewardWithdraw(msg.sender, rewardAmount);
    }

    /**
     * @notice Slash the reward points for an expired subscription after a grace period which is 50% of the purchased time
     *         Any slashable points are burned, increasing the value of remaining points.
     * @param account the account of the subscription to slash
     */
    function slashRewards(address account) external {
        require(_rewardBps > 0, "Rewards disabled");
        Subscription memory slasher = _subscriptions[msg.sender];
        require(_isActive(slasher), "Subscription not active");

        Subscription memory sub = _subscriptions[account];
        require(sub.rewardPoints > 0, "No reward points to slash");

        // Expiration + grace period (50% of purchased time)
        uint256 slashPoint = _subscriptionExpiresAt(sub) + (sub.secondsPurchased / 2);
        require(block.timestamp >= slashPoint, "Not slashable");

        // Deflate the reward points pool and account for prior reward withdrawals
        _totalRewardPoints -= sub.rewardPoints;
        _rewardPoolSlashed += sub.rewardsWithdrawn;

        // If all points are slashed, move left-over funds to creator
        if (_totalRewardPoints == 0) {
            _rewardPoolBalance = 0;
        }

        emit RewardPointsSlashed(account, msg.sender, sub.rewardPoints);
        sub.rewardPoints = 0;
        sub.rewardsWithdrawn = 0;
        _subscriptions[account] = sub;
    }

    /////////////////////////
    // Creator Calls
    /////////////////////////

    /**
     * @notice Withdraw available funds as the owner
     */
    function withdraw() external {
        withdrawTo(msg.sender);
    }

    /**
     * @notice Withdraw available funds and transfer fees as the owner
     */
    function withdrawAndTransferFees() external {
        withdrawTo(msg.sender);
        _transferFees();
    }

    /**
     * @notice Withdraw available funds as the owner to a specific account
     * @param account the account to transfer funds to
     */
    function withdrawTo(address account) public onlyOwner {
        require(account != address(0), "Account cannot be 0x0");
        uint256 balance = creatorBalance();
        require(balance > 0, "No Balance");
        _transferToCreator(account, balance);
    }

    /**
     * @notice Refund one or more accounts remaining purchased time and revoke any granted time
     * @dev This refunds accounts using creator balance, and can also transfer in to top up the fund. Any excess value is withdrawable.
     * @param numTokensIn an optional amount of tokens to transfer in before refunding
     * @param accounts the list of accounts to refund and revoke grants for
     */
    function refund(uint256 numTokensIn, address[] memory accounts) external payable onlyOwner {
        require(accounts.length > 0, "No accounts to refund");
        if (numTokensIn > 0) {
            uint256 finalAmount = _transferIn(msg.sender, numTokensIn);
            emit RefundTopUp(finalAmount);
        } else if (msg.value > 0) {
            revert("Unexpected value transfer");
        }
        require(canRefund(accounts), "Insufficient balance for refund");
        for (uint256 i = 0; i < accounts.length; i++) {
            _refund(accounts[i]);
        }
    }

    /**
     * @notice Update the contract metadata
     * @param contractUri the collection metadata URI
     * @param tokenUri the token metadata URI
     */
    function updateMetadata(string memory contractUri, string memory tokenUri) external onlyOwner {
        require(bytes(contractUri).length > 0, "Contract URI cannot be empty");
        require(bytes(tokenUri).length > 0, "Token URI cannot be empty");
        _contractURI = contractUri;
        _tokenURI = tokenUri;
    }

    /**
     * @notice Grant time to a list of accounts, so they can access content without paying
     * @param accounts the list of accounts to grant time to
     * @param secondsToAdd the number of seconds to grant for each account
     */
    function grantTime(address[] memory accounts, uint256 secondsToAdd) external onlyOwner {
        require(secondsToAdd > 0, "Seconds to add must be > 0");
        require(accounts.length > 0, "No accounts to grant time to");
        for (uint256 i = 0; i < accounts.length; i++) {
            _grantTime(accounts[i], secondsToAdd);
        }
    }

    /**
     * @notice Pause minting to allow for migrations or other actions
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @notice Unpause to resume subscription minting
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * @notice Update the maximum number of tokens (subscriptions)
     * @param supplyCap the new supply cap (must be greater than token count or 0 for unlimited)
     */
    function setSupplyCap(uint256 supplyCap) external onlyOwner {
        require(supplyCap == 0 || supplyCap >= _tokenCounter, "Supply cap must be >= current count or 0");
        _supplyCap = supplyCap;
        emit SupplyCapChange(supplyCap);
    }

    /**
     * @notice Set a transfer recipient for automated/sponsored transfers
     * @param recipient the recipient address
     */
    function setTransferRecipient(address recipient) external onlyOwner {
        _transferRecipient = recipient;
        emit TransferRecipientChange(recipient);
    }

    /////////////////////////
    // Sponsored Calls
    /////////////////////////

    /**
     * @notice Mint or renew a subscription for a specific account. Intended for automated renewals.
     * @param account the account to mint or renew time for
     * @param numTokens the amount of ERC20 tokens or native tokens to transfer
     */
    function mintFor(address account, uint256 numTokens) public payable whenNotPaused validAmount(numTokens) {
        uint256 finalAmount = _transferIn(msg.sender, numTokens);
        _purchaseTime(account, finalAmount);
    }

    /**
     * @notice Mint or renew a subscription for a specific account, with referral details
     * @param account the account to mint or renew time for
     * @param numTokens the amount of ERC20 tokens or native tokens to transfer
     * @param referralCode the referral code to use for rewards
     * @param referrer the referrer address and reward recipient
     */
    function mintWithReferralFor(address account, uint256 numTokens, uint256 referralCode, address referrer)
        public
        payable
        whenNotPaused
        validAmount(numTokens)
    {
        require(referrer != address(0), "Referrer cannot be 0x0");

        uint256 finalAmount = _transferIn(msg.sender, numTokens);
        uint256 tokenId = _purchaseTime(account, finalAmount);

        // Calculate rewards and transfer rewards out
        uint256 payout = _referralAmount(finalAmount, referralCode);
        if (payout > 0) {
            _transferOut(referrer, payout);
            emit ReferralPayout(tokenId, referrer, referralCode, payout);
        }
    }

    /**
     * @notice Transfer any available fees to the fee collector
     */
    function transferFees() external {
        require(_feeBalance > 0, "No fees to collect");
        _transferFees();
    }

    /**
     * @notice Transfer all balances to the transfer recipient and fee collector (if applicable)
     * @dev This is a way for EOAs to pay gas fees on behalf of the creator (automation, etc)
     */
    function transferAllBalances() external {
        require(_transferRecipient != address(0), "Transfer recipient not set");
        _transferAllBalances(_transferRecipient);
    }

    /////////////////////////
    // Fee Management
    /////////////////////////

    /**
     * @notice Fetch the current fee schedule
     * @return feeCollector the feeCollector address
     * @return feeBps the fee basis points
     */
    function feeSchedule() external view returns (address feeCollector, uint16 feeBps) {
        return (_feeCollector, _feeBps);
    }

    /**
     * @notice Fetch the accumulated fee balance
     * @return balance the accumulated fees which have not yet been transferred
     */
    function feeBalance() external view returns (uint256 balance) {
        return _feeBalance;
    }

    /**
     * @notice Update the fee collector address. Can be set to 0x0 to disable fees permanently.
     * @param newCollector the new fee collector address
     */
    function updateFeeRecipient(address newCollector) external {
        require(msg.sender == _feeCollector, "Unauthorized");
        // Give tokens back to creator and set fee rate to 0
        if (newCollector == address(0)) {
            _feeBalance = 0;
            _feeBps = 0;
        }
        _feeCollector = newCollector;
        emit FeeCollectorChange(msg.sender, newCollector);
    }

    /////////////////////////
    // Referral Rewards
    /////////////////////////

    /**
     * @notice Create a referral code for giving rewards to referrers on mint
     * @param code the unique integer code for the referral
     * @param bps the reward basis points
     */
    function createReferralCode(uint256 code, uint16 bps) external onlyOwner {
        require(bps <= _MAX_BIPS, "bps too high");
        require(bps > 0, "bps must be > 0");
        uint16 existing = _referralCodes[code];
        require(existing == 0, "Referral code exists");
        _referralCodes[code] = bps;
        emit ReferralCreated(code, bps);
    }

    /**
     * @notice Delete a referral code
     * @param code the unique integer code for the referral
     */
    function deleteReferralCode(uint256 code) external onlyOwner {
        delete _referralCodes[code];
        emit ReferralDestroyed(code);
    }

    /**
     * @notice Fetch the reward basis points for a given referral code
     * @param code the unique integer code for the referral
     * @return bps the reward basis points
     */
    function referralCodeBps(uint256 code) external view returns (uint16 bps) {
        return _referralCodes[code];
    }

    ////////////////////////
    // Core Internal Logic
    ////////////////////////

    /// @dev Add time to a given account (transfer happens before this is called)
    function _purchaseTime(address account, uint256 amount) internal returns (uint256) {
        require(account != address(0), "Account cannot be 0x0");

        Subscription memory sub = _fetchSubscription(account);

        // Adjust offset to account for existing time
        if (block.timestamp > sub.purchaseOffset + sub.secondsPurchased) {
            sub.purchaseOffset = block.timestamp - sub.secondsPurchased;
        }

        uint256 rp = amount * rewardMultiplier();
        uint256 tv = timeValue(amount);
        sub.secondsPurchased += tv;
        sub.rewardPoints += rp;
        _subscriptions[account] = sub;
        _totalRewardPoints += rp;

        // If fees or rewards are enabled, allocate a portion of the purchase to those pools
        _allocateFeesAndRewards(amount);

        // Mint the NFT if it does not exist before purchase event for indexers
        _maybeMint(account, sub.tokenId);

        emit Purchase(account, sub.tokenId, amount, tv, rp, _subscriptionExpiresAt(sub));
        return sub.tokenId;
    }

    /// @dev Get or build a new subscription
    function _fetchSubscription(address account) internal returns (Subscription memory) {
        Subscription memory sub = _subscriptions[account];
        if (sub.tokenId == 0) {
            require(_supplyCap == 0 || _tokenCounter < _supplyCap, "Supply cap reached");
            _tokenCounter += 1;
            sub = Subscription(_tokenCounter, 0, 0, block.timestamp, block.timestamp, 0, 0);
        }
        return sub;
    }

    /// @dev Mint the NFT if it does not exist. Used after grant/purchase state changes (check effects)
    function _maybeMint(address account, uint256 tokenId) private {
        if (_ownerOf(tokenId) == address(0)) {
            _safeMint(account, tokenId);
        }
    }

    /// @dev If fees or rewards are present, allocate a portion of the amount to the relevant pools
    function _allocateFeesAndRewards(uint256 amount) private {
        _allocateRewards(_allocateFees(amount));
    }

    /// @dev Allocate tokens to the fee collector
    function _allocateFees(uint256 amount) internal returns (uint256) {
        if (_feeBps == 0) {
            return amount;
        }
        uint256 fee = (amount * _feeBps) / _MAX_BIPS;
        _feeBalance += fee;
        emit FeeAllocated(fee);
        return amount - fee;
    }

    /// @dev Allocate tokens to the reward pool
    function _allocateRewards(uint256 amount) internal returns (uint256) {
        if (_rewardBps == 0 || _totalRewardPoints == 0) {
            return amount;
        }
        uint256 rewards = (amount * _rewardBps) / _MAX_BIPS;
        _rewardPoolBalance += rewards;
        _rewardPoolTotal += rewards;
        emit RewardsAllocated(rewards);
        return amount - rewards;
    }

    /// @dev Transfer tokens into the contract, either native or ERC20
    function _transferIn(address from, uint256 amount) internal nonReentrant returns (uint256) {
        if (!_erc20) {
            require(msg.value == amount, "Purchase amount must match value sent");
            _tokensIn += amount;
            return amount;
        }

        // Note: We support tokens which take fees, but do not support rebasing tokens
        require(msg.value == 0, "Native tokens not accepted for ERC20 subscriptions");
        uint256 preBalance = _token.balanceOf(from);
        uint256 allowance = _token.allowance(from, address(this));
        require(preBalance >= amount && allowance >= amount, "Insufficient Balance or Allowance");
        _token.safeTransferFrom(from, address(this), amount);
        uint256 postBalance = _token.balanceOf(from);
        uint256 finalAmount = preBalance - postBalance;
        _tokensIn += finalAmount;
        return finalAmount;
    }

    /// @dev Transfer tokens to the creator, after allocating protocol fees and rewards
    function _transferToCreator(address to, uint256 amount) internal {
        emit Withdraw(to, amount);
        _transferOut(to, amount);
    }

    /// @dev Transfer tokens out of the contract, either native or ERC20
    function _transferOut(address to, uint256 amount) internal nonReentrant {
        _tokensOut += amount;
        if (_erc20) {
            _token.safeTransfer(to, amount);
        } else {
            (bool sent,) = payable(to).call{value: amount}("");
            require(sent, "Failed to transfer Ether");
        }
    }

    /// @dev Transfer fees to the fee collector
    function _transferFees() internal {
        if (_feeBalance == 0) {
            return;
        }
        uint256 balance = _feeBalance;
        _feeBalance = 0;
        _transferOut(_feeCollector, balance);
        emit FeeTransfer(msg.sender, _feeCollector, balance);
    }

    /// @dev Transfer all remaining balances to the creator and fee collector (if applicable)
    function _transferAllBalances(address balanceRecipient) internal {
        uint256 balance = creatorBalance();
        if (balance > 0) {
            _transferToCreator(balanceRecipient, balance);
        }

        // Transfer protocol fees
        _transferFees();
    }

    /// @dev Grant time to a given account
    function _grantTime(address account, uint256 numSeconds) internal {
        Subscription memory sub = _fetchSubscription(account);
        // Adjust offset to account for existing time
        if (block.timestamp > sub.grantOffset + sub.secondsGranted) {
            sub.grantOffset = block.timestamp - sub.secondsGranted;
        }

        sub.secondsGranted += numSeconds;
        _subscriptions[account] = sub;

        // Mint the NFT if it does not exist before grant event for indexers
        _maybeMint(account, sub.tokenId);

        emit Grant(account, sub.tokenId, numSeconds, _subscriptionExpiresAt(sub));
    }

    /// @dev The amount of granted time remaining for a given subscription
    function _grantTimeRemaining(Subscription memory sub) internal view returns (uint256) {
        uint256 expiresAt = sub.grantOffset + sub.secondsGranted;
        if (expiresAt <= block.timestamp) {
            return 0;
        }
        return expiresAt - block.timestamp;
    }

    /// @dev The amount of purchased time remaining for a given subscription
    function _purchaseTimeRemaining(Subscription memory sub) internal view returns (uint256) {
        uint256 expiresAt = sub.purchaseOffset + sub.secondsPurchased;
        if (expiresAt <= block.timestamp) {
            return 0;
        }
        return expiresAt - block.timestamp;
    }

    /// @dev Refund the remaining time for the given accounts subscription, and clear grants
    function _refund(address account) internal {
        Subscription memory sub = _subscriptions[account];
        if (sub.secondsPurchased == 0 && sub.secondsGranted == 0) {
            return;
        }

        sub.secondsGranted = 0;
        uint256 balance = refundableBalanceOf(account);
        uint256 tokens = balance * _tokensPerSecond;
        if (balance > 0) {
            sub.secondsPurchased -= balance;
            _subscriptions[account] = sub;
            _transferOut(account, tokens);
        } else {
            _subscriptions[account] = sub;
        }

        emit Refund(account, sub.tokenId, tokens, balance);
    }

    /// @dev Compute the reward amount for a given token amount and referral code
    function _referralAmount(uint256 tokenAmount, uint256 referralCode) internal view returns (uint256) {
        uint16 referralBps = _referralCodes[referralCode];
        if (referralBps == 0) {
            return 0;
        }
        return (tokenAmount * referralBps) / _MAX_BIPS;
    }

    /// @dev The timestamp when the subscription expires
    function _subscriptionExpiresAt(Subscription memory sub) internal pure returns (uint256) {
        uint256 purchase = sub.purchaseOffset + sub.secondsPurchased;
        uint256 grant = sub.grantOffset + sub.secondsGranted;
        return purchase > grant ? purchase : grant;
    }

    /// @dev The reward balance for a given subscription
    function _rewardBalance(Subscription memory sub) internal view returns (uint256) {
        uint256 userShare = (_rewardPoolTotal - _rewardPoolSlashed) * sub.rewardPoints / _totalRewardPoints;
        if (userShare <= sub.rewardsWithdrawn) {
            return 0;
        }
        return userShare - sub.rewardsWithdrawn;
    }

    /// @dev Determine if a subscription is active
    function _isActive(Subscription memory sub) internal view returns (bool) {
        return _subscriptionExpiresAt(sub) > block.timestamp;
    }

    ////////////////////////
    // Informational
    ////////////////////////

    /**
     * @notice Determine the total cost for refunding the given accounts
     * @dev The value will change from block to block, so this is only an estimate
     * @param accounts the list of accounts to refund
     * @return numTokens total number of tokens for refund
     */
    function refundableTokenBalanceOfAll(address[] memory accounts) public view returns (uint256 numTokens) {
        uint256 amount;
        for (uint256 i = 0; i < accounts.length; i++) {
            amount += refundableBalanceOf(accounts[i]);
        }
        return amount * _tokensPerSecond;
    }

    /**
     * @notice Determines if a refund can be processed for the given accounts with the current balance
     * @param accounts the list of accounts to refund
     * @return refundable true if the refund can be processed from the current balance
     */
    function canRefund(address[] memory accounts) public view returns (bool refundable) {
        return creatorBalance() >= refundableTokenBalanceOfAll(accounts);
    }

    /**
     * @notice The current reward multiplier used to calculate reward points on mint. This is halved every _minPurchaseSeconds and goes to 0 after N halvings.
     * @return multiplier the current value
     */
    function rewardMultiplier() public view returns (uint256 multiplier) {
        if (_numRewardHalvings == 0) {
            return 0;
        }
        uint256 halvings = (block.timestamp - _deployBlockTime) / _minPurchaseSeconds;
        if (halvings > _numRewardHalvings) {
            return 0;
        }
        return (2 ** _numRewardHalvings) / (2 ** halvings);
    }

    /**
     * @notice The amount of time exchanged for the given number of tokens
     * @param numTokens the number of tokens to exchange for time
     * @return numSeconds the number of seconds purchased
     */
    function timeValue(uint256 numTokens) public view returns (uint256 numSeconds) {
        return numTokens / _tokensPerSecond;
    }

    /**
     * @notice The creators withdrawable balance
     * @return balance the number of tokens available for withdraw
     */
    function creatorBalance() public view returns (uint256 balance) {
        return _tokensIn - _tokensOut - _feeBalance - _rewardPoolBalance;
    }

    /**
     * @notice The sum of all deposited tokens over time. Fees and refunds are not accounted for.
     * @return total the total number of tokens deposited
     */
    function totalCreatorEarnings() public view returns (uint256 total) {
        return _tokensIn;
    }

    /**
     * @notice Relevant subscription information for a given account
     * @return tokenId the tokenId for the account
     * @return refundableAmount the number of seconds which can be refunded
     * @return rewardPoints the number of reward points earned
     * @return expiresAt the timestamp when the subscription expires
     */
    function subscriptionOf(address account)
        external
        view
        returns (uint256 tokenId, uint256 refundableAmount, uint256 rewardPoints, uint256 expiresAt)
    {
        Subscription memory sub = _subscriptions[account];
        return (sub.tokenId, sub.secondsPurchased, sub.rewardPoints, _subscriptionExpiresAt(sub));
    }

    /**
     * @notice The percentage (as basis points) of creator earnings which are rewarded to subscribers
     * @return bps reward basis points
     */
    function rewardBps() external view returns (uint16 bps) {
        return _rewardBps;
    }

    /**
     * @notice The number of reward points allocated to all subscribers (used to calculate rewards)
     * @return numPoints total number of reward points
     */
    function totalRewardPoints() external view returns (uint256 numPoints) {
        return _totalRewardPoints;
    }

    /**
     * @notice The balance of the reward pool (for reward withdraws)
     * @return numTokens number of tokens in the reward pool
     */
    function rewardPoolBalance() external view returns (uint256 numTokens) {
        return _rewardPoolBalance;
    }

    /**
     * @notice The number of tokens available to withdraw from the reward pool, for a given account
     * @param account the account to check
     * @return numTokens number of tokens available to withdraw
     */
    function rewardBalanceOf(address account) external view returns (uint256 numTokens) {
        Subscription memory sub = _subscriptions[account];
        return _rewardBalance(sub);
    }

    /**
     * @notice The ERC-20 address used for purchases, or 0x0 for native
     * @return erc20 address or 0x0 for native
     */
    function erc20Address() public view returns (address erc20) {
        return address(_token);
    }

    /**
     * @notice The refundable time balance for a given account
     * @param account the account to check
     * @return numSeconds the number of seconds which can be refunded
     */
    function refundableBalanceOf(address account) public view returns (uint256 numSeconds) {
        Subscription memory sub = _subscriptions[account];
        return _purchaseTimeRemaining(sub);
    }

    /**
     * @notice The contract metadata URI for accessing collection metadata
     * @return uri the collection URI
     */
    function contractURI() public view returns (string memory uri) {
        return _contractURI;
    }

    /**
     * @notice The base token URI for accessing token metadata
     * @return uri the base token URI
     */
    function baseTokenURI() public view returns (string memory uri) {
        return _tokenURI;
    }

    /**
     * @notice The number of tokens required for a single second of time
     * @return numTokens per second
     */
    function tps() external view returns (uint256 numTokens) {
        return _tokensPerSecond;
    }

    /**
     * @notice The minimum number of seconds required for a purchase
     * @return numSeconds minimum
     */
    function minPurchaseSeconds() external view returns (uint256 numSeconds) {
        return _minPurchaseSeconds;
    }

    /**
     * @notice Fetch the current supply cap (0 for unlimited)
     * @return count the current number
     * @return cap the max number of subscriptions
     */
    function supplyDetail() external view returns (uint256 count, uint256 cap) {
        return (_tokenCounter, _supplyCap);
    }

    /**
     * @notice Fetch the current transfer recipient address
     * @return recipient the address or 0x0 address for none
     */
    function transferRecipient() external view returns (address recipient) {
        return _transferRecipient;
    }

    /**
     * @notice Fetch the metadata URI for a given token
     * @dev If _tokenURI ends with a / then the tokenId is appended
     * @param tokenId the tokenId to fetch the metadata URI for
     * @return uri the URI for the token
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory uri) {
        _requireMinted(tokenId);

        bytes memory str = bytes(_tokenURI);
        uint256 len = str.length;
        if (str[len - 1] == "/") {
            return string(abi.encodePacked(_tokenURI, tokenId.toString()));
        }

        return _tokenURI;
    }

    //////////////////////
    // Overrides
    //////////////////////

    /**
     * @notice Override the default balanceOf behavior to account for time remaining
     * @param account the account to fetch the balance of
     * @return numSeconds the number of seconds remaining in the subscription
     */
    function balanceOf(address account) public view override returns (uint256 numSeconds) {
        Subscription memory sub = _subscriptions[account];
        return _purchaseTimeRemaining(sub) + _grantTimeRemaining(sub);
    }

    /**
     * @notice Renounce ownership of the contract, transferring all remaining funds to the creator and fee collector
     *         and pausing the contract to prevent further inflows.
     */
    function renounceOwnership() public override onlyOwner {
        _transferAllBalances(msg.sender);
        _pause();
        _transferOwnership(address(0));
    }

    /// @dev Transfers may occur if the destination does not have a subscription
    function _beforeTokenTransfer(address from, address to, uint256, /* tokenId */ uint256 /* batchSize */ )
        internal
        override
    {
        if (from == address(0)) {
            return;
        }

        require(_subscriptions[to].tokenId == 0, "Cannot transfer to existing subscribers");
        if (to != address(0)) {
            _subscriptions[to] = _subscriptions[from];
        }

        delete _subscriptions[from];
    }

    //////////////////////
    // Recovery Functions
    //////////////////////

    /**
     * @notice Reconcile the ERC20 balance of the contract with the internal state
     * @dev The prevents lost funds if ERC20 tokens are transferred to the contract directly
     */
    function reconcileERC20Balance() external onlyOwner {
        require(_erc20, "Only for ERC20 tokens");
        uint256 balance = _token.balanceOf(address(this));
        uint256 expectedBalance = _tokensIn - _tokensOut;
        require(balance > expectedBalance, "Tokens already reconciled");
        _tokensIn += balance - expectedBalance;
    }

    /**
     * @notice Recover ERC20 tokens which were accidentally sent to the contract
     * @param tokenAddress the address of the token to recover
     * @param recipientAddress the address to send the tokens to
     * @param tokenAmount the amount of tokens to send
     */
    function recoverERC20(address tokenAddress, address recipientAddress, uint256 tokenAmount) external onlyOwner {
        require(tokenAddress != erc20Address(), "Cannot recover subscription token");
        IERC20(tokenAddress).safeTransfer(recipientAddress, tokenAmount);
    }

    /**
     * @notice Recover native tokens which bypassed receive. Only callable for erc20 denominated contracts.
     * @param recipient the address to send the tokens to
     */
    function recoverNativeTokens(address recipient) external onlyOwner {
        require(_erc20, "Not supported, use reconcileNativeBalance");
        uint256 balance = address(this).balance;
        require(balance > 0, "No balance to recover");
        (bool sent,) = payable(recipient).call{value: balance}("");
        require(sent, "Failed to transfer Ether");
    }

    /**
     * @notice Reconcile native tokens which bypassed receive/mint. Only callable for native denominated contracts.
     */
    function reconcileNativeBalance() external onlyOwner {
        require(!_erc20, "Not supported, use recoverNativeTokens");
        uint256 balance = address(this).balance;
        require(balance > 0, "No balance to recover");
        uint256 expectedBalance = _tokensIn - _tokensOut;
        require(balance > expectedBalance, "Balance reconciled");
        _tokensIn += balance - expectedBalance;
    }
}
