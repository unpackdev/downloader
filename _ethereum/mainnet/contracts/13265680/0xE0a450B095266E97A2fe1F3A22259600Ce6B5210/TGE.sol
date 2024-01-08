// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

import "./Ownable.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./Signature.sol";

contract TGE is Ownable, Signature {
    using SafeERC20 for IERC20;

    /** @dev Terms and conditions as a keccak256 hash */
    string public constant termsAndConditions =
        "By signing this message I agree to the $FOREX TOKEN - TERMS AND CONDITIONS identified by the hash: 0x1b42a1c6369d3efbf3b65d757e3f5e804bc26935b45dda1eaf0d90ef297289b4";
    /** @dev ERC-191 encoded Terms and Conditions for signature validation */
    bytes32 private constant termsAndConditionsERC191 =
        keccak256(
            abi.encodePacked(
                bytes1(0x19),
                bytes1("E"),
                bytes("thereum Signed Message:\n165"),
                abi.encodePacked(termsAndConditions)
            )
        );
    /** @dev Error message for claiming before allowed period */
    string private constant notClaimable = "Funds not yet claimable";
    /** @dev The amount of FOREX to be generated */
    uint256 public constant forexAmount = 20_760_000 ether;
    /** @dev The address of this contract's deployed instance */
    address private immutable self;
    /** @dev Canonical FOREX token address */
    address public immutable FOREX;
    /** @dev Per-user deposit cap */
    uint256 public immutable userCap;
    /** @dev Minimum token price in ETH (soft cap parameter) */
    uint256 public minTokenPrice;
    /** @dev Maximum token price in ETH (if hard cap is met) */
    uint256 public maxTokenPrice;
    /** @dev Generation duration (seconds)  */
    uint256 public immutable generationDuration;
    /** @dev Start date for the generation; when ETH deposits are accepted */
    uint256 public immutable generationStartDate;
    /** @dev Maximum deposit cap in ETH from which new deposits are ignored */
    uint256 public depositCap;
    /** @dev Date from when FOREX claiming is allowed */
    uint256 public claimDate;
    /** @dev Amount of ETH deposited during the TGE */
    uint256 public ethDeposited;
    /** @dev Mapping of (depositor => eth amount) for the TGE period */
    mapping(address => uint256) private deposits;
    /** @dev Mapping of (depositor => T&Cs signature status) */
    mapping(address => bool) public signedTermsAndConditions;
    /** @dev Mapping of (depositor => claimed eth) */
    mapping(address => bool) private claimedEth;
    /** @dev Mapping of (depositor => claimed forex) */
    mapping(address => bool) private claimedForex;
    /** @dev The total ETH deposited under a referral address */
    mapping(address => uint256) public referrerDeposits;
    /** @dev Number of depositors */
    uint256 public depositorCount;
    /** @dev Whether leftover FOREX tokens were withdrawn by owner
             (only possible if FOREX did not reach the max price) */
    bool private withdrawnRemainingForex;
    /** @dev Whether the TGE was aborted by the owner */
    bool private aborted;
    /** @dev ETH withdrawn by owner */
    uint256 public ethWithdrawnByOwner;

    modifier notAborted() {
        require(!aborted, "TGE aborted");
        _;
    }

    constructor(
        address _FOREX,
        uint256 _userCap,
        uint256 _depositCap,
        uint256 _minTokenPrice,
        uint256 _maxTokenPrice,
        uint256 _generationDuration,
        uint256 _generationStartDate
    ) {
        require(_generationDuration > 0, "Duration must be > 0");
        require(
            _generationStartDate > block.timestamp,
            "Start date must be in the future"
        );
        self = address(this);
        FOREX = _FOREX;
        userCap = _userCap;
        depositCap = _depositCap;
        minTokenPrice = _minTokenPrice;
        maxTokenPrice = _maxTokenPrice;
        generationDuration = _generationDuration;
        generationStartDate = _generationStartDate;
    }

    /**
     * @dev Deny direct ETH transfers.
     */
    receive() external payable {
        revert("Must call deposit to participate");
    }

    /**
     * @dev Validates a signature for the hashed terms & conditions message.
     *      The T&Cs hash is converted to an ERC-191 message before verifying.
     * @param signature The signature to validate.
     */
    function signTermsAndConditions(bytes memory signature) public {
        if (signedTermsAndConditions[msg.sender]) return;
        address signer = getSignatureAddress(
            termsAndConditionsERC191,
            signature
        );
        require(signer == msg.sender, "Invalid signature");
        signedTermsAndConditions[msg.sender] = true;
    }

    /**
     * @dev Allow incoming ETH transfers during the TGE period.
     */
    function deposit(address referrer, bytes memory signature)
        external
        payable
        notAborted
    {
        // Sign T&Cs if the signature is not empty.
        // User must pass a valid signature before the first deposit.
        if (signature.length != 0) signTermsAndConditions(signature);
        // Assert that the user can deposit.
        require(signedTermsAndConditions[msg.sender], "Must sign T&Cs");
        require(hasTgeBeenStarted(), "TGE has not started yet");
        require(!hasTgeEnded(), "TGE has finished");
        uint256 currentDeposit = deposits[msg.sender];
        // Revert if the user cap or TGE cap has already been met.
        require(currentDeposit < userCap, "User cap met");
        require(ethDeposited < depositCap, "TGE deposit cap met");
        // Assert that the deposit amount is greater than zero.
        uint256 deposit = msg.value;
        assert(deposit > 0);
        // Increase the depositorCount if first deposit by user.
        if (currentDeposit == 0) depositorCount++;
        if (currentDeposit + deposit > userCap) {
            // Ensure deposit over user cap is returned.
            safeSendEth(msg.sender, currentDeposit + deposit - userCap);
            // Adjust user deposit.
            deposit = userCap - currentDeposit;
        } else if (ethDeposited + deposit > depositCap) {
            // Ensure deposit over TGE cap is returned.
            safeSendEth(msg.sender, ethDeposited + deposit - depositCap);
            // Adjust user deposit.
            deposit -= ethDeposited + deposit - depositCap;
        }
        // Only contribute to referrals if the hard cap hasn't been met yet.
        uint256 hardCap = ethHardCap();
        if (ethDeposited < hardCap) {
            uint256 referralDepositAmount = deposit;
            // Subtract surplus from hard cap if any.
            if (ethDeposited + deposit > hardCap)
                referralDepositAmount -= ethDeposited + deposit - hardCap;
            referrerDeposits[referrer] += referralDepositAmount;
        }
        // Increase deposit variables.
        ethDeposited += deposit;
        deposits[msg.sender] += deposit;
    }

    /**
     * @dev Claim depositor funds (FOREX and ETH) once the TGE has closed.
            This may be called right after TGE closing for withdrawing surplus
            ETH (if FOREX reached max price/hard cap) or once (again when) the
            claim period starts for claiming both FOREX along with any surplus.
     */
    function claim() external notAborted {
        require(hasTgeEnded(), notClaimable);
        (uint256 forex, uint256 forexReferred, uint256 eth) = balanceOf(
            msg.sender
        );
        // Revert here if there's no ETH to withdraw as the FOREX claiming
        // period may not have yet started.
        require(eth > 0 || isTgeClaimable(), notClaimable);
        forex += forexReferred;
        // Claim forex only if the claimable period has started.
        if (isTgeClaimable() && forex > 0) claimForex(forex);
        // Claim ETH hardcap surplus if available.
        if (eth > 0) claimEthSurplus(eth);
    }

    /**
     * @dev Claims ETH for user.
     * @param eth The amount of ETH to claim.
     */
    function claimEthSurplus(uint256 eth) private {
        if (claimedEth[msg.sender]) return;
        claimedEth[msg.sender] = true;
        if (eth > 0) safeSendEth(msg.sender, eth);
    }

    /**
     * @dev Claims FOREX for user.
     * @param forex The amount of FOREX to claim.
     */
    function claimForex(uint256 forex) private {
        if (claimedForex[msg.sender]) return;
        claimedForex[msg.sender] = true;
        IERC20(FOREX).safeTransfer(msg.sender, forex);
    }

    /**
     * @dev Withdraws leftover forex in case the hard cap is not met during TGE.
     */
    function withdrawRemainingForex(address recipient) external onlyOwner {
        assert(!withdrawnRemainingForex);
        // Revert if the TGE has not ended.
        require(hasTgeEnded(), "TGE has not finished");
        (uint256 forexClaimable, ) = getClaimableData();
        uint256 remainingForex = forexAmount - forexClaimable;
        withdrawnRemainingForex = true;
        // Add address zero (null) referrals to withdrawal.
        remainingForex += getReferralForexAmount(address(0));
        if (remainingForex == 0) return;
        IERC20(FOREX).safeTransfer(recipient, remainingForex);
    }

    /**
     * @dev Returns an account's balance of claimable forex, referral forex,
            and ETH.
     * @param account The account to fetch the claimable balance for.
     */
    function balanceOf(address account)
        public
        view
        returns (
            uint256 forex,
            uint256 forexReferred,
            uint256 eth
        )
    {
        if (!hasTgeEnded()) return (0, 0, 0);
        (uint256 forexClaimable, uint256 ethClaimable) = getClaimableData();
        uint256 share = shareOf(account);
        eth = claimedEth[account] ? 0 : (ethClaimable * share) / (1 ether);
        if (claimedForex[account]) {
            forex = 0;
            forexReferred = 0;
        } else {
            forex = (forexClaimable * share) / (1 ether);
            // Forex earned through referrals is 5% of the referred deposits
            // in FOREX.
            forexReferred = getReferralForexAmount(account);
        }
    }

    /**
     * @dev Returns an account's share over the TGE deposits.
     * @param account The account to fetch the share for.
     * @return Share value as an 18 decimal ratio. 1 ether = 100%.
     */
    function shareOf(address account) public view returns (uint256) {
        if (ethDeposited == 0) return 0;
        return (deposits[account] * (1 ether)) / ethDeposited;
    }

    /**
     * @dev Returns the ETH deposited by an address.
     * @param depositor The depositor address.
     */
    function getDeposit(address depositor) external view returns (uint256) {
        return deposits[depositor];
    }

    /**
     * @dev Whether the TGE already started. It could be closed even if
            this function returns true.
     */
    function hasTgeBeenStarted() private view returns (bool) {
        return block.timestamp >= generationStartDate;
    }

    /**
     * @dev Whether the TGE has ended and is closed for new deposits.
     */
    function hasTgeEnded() private view returns (bool) {
        return block.timestamp > generationStartDate + generationDuration;
    }

    /**
     * @dev Whether the TGE funds can be claimed.
     */
    function isTgeClaimable() private view returns (bool) {
        return claimDate != 0 && block.timestamp >= claimDate;
    }

    /**
     * @dev The amount of ETH required to generate all supply at max price.
     */
    function ethHardCap() private view returns (uint256) {
        return (forexAmount * maxTokenPrice) / (1 ether);
    }

    /**
     * @dev Returns the forex price as established by the deposit amount.
     *      The formula for the price is the following:
     * minPrice + ([maxPrice - minPrice] * min(deposit, maxDeposit)/maxDeposit)
     * Where maxDeposit = ethHardCap()
     */
    function forexPrice() public view returns (uint256) {
        uint256 hardCap = ethHardCap();
        uint256 depositTowardsHardCap = ethDeposited > hardCap
            ? hardCap
            : ethDeposited;
        uint256 priceRange = maxTokenPrice - minTokenPrice;
        uint256 priceDelta = (priceRange * depositTowardsHardCap) / hardCap;
        return minTokenPrice + priceDelta;
    }

    /**
     * @dev Returns TGE data to be used for claims once the TGE closes.
     */
    function getClaimableData()
        private
        view
        returns (uint256 forexClaimable, uint256 ethClaimable)
    {
        assert(hasTgeEnded());
        uint256 forexPrice = forexPrice();
        uint256 hardCap = ethHardCap();
        // ETH is only claimable if the deposits exceeded the hard cap.
        ethClaimable = ethDeposited > hardCap ? ethDeposited - hardCap : 0;
        // Forex is claimable up to the maximum supply -- when deposits match
        // the hard cap amount.
        forexClaimable =
            ((ethDeposited - ethClaimable) * (1 ether)) /
            forexPrice;
    }

    /**
     * @dev Returns the amount of FOREX earned by a referrer.
     * @param referrer The referrer's address.
     */
    function getReferralForexAmount(address referrer)
        private
        view
        returns (uint256)
    {
        // Referral claims are disabled.
        return 0;
    }

    /**
     * @dev Aborts the TGE, stopping new deposits and withdrawing all funds
     *      for the owner.
     *      The only use case for this function is in the
     *      event of an emergency.
     */
    function emergencyAbort() external onlyOwner {
        assert(!aborted);
        aborted = true;
        emergencyWithdrawAllFunds();
    }

    /**
     * @dev Withdraws all contract funds for the owner.
     *      The only use case for this function is in the
     *      event of an emergency.
     */
    function emergencyWithdrawAllFunds() public onlyOwner {
        // Transfer ETH.
        uint256 balance = self.balance;
        if (balance > 0) safeSendEth(msg.sender, balance);
        // Transfer FOREX.
        IERC20 forex = IERC20(FOREX);
        balance = forex.balanceOf(self);
        if (balance > 0) forex.transfer(msg.sender, balance);
    }

    /**
     * @dev Withdraws all ETH funds for the owner.
     *      This function may be called at any time, as it correctly
     *      withdraws only the correct contribution amount, ignoring
     *      the ETH amount to be refunded if the deposits exceed
     *      the hard cap.
     */
    function collectContributions() public onlyOwner {
        uint256 hardCap = ethHardCap();
        require(
            ethWithdrawnByOwner < hardCap,
            "Cannot withdraw more than hard cap amount"
        );
        uint256 amount = self.balance;
        if (amount + ethWithdrawnByOwner > hardCap)
            amount = hardCap - ethWithdrawnByOwner;
        ethWithdrawnByOwner += amount;
        require(amount > 0, "Nothing available for withdrawal");
        safeSendEth(msg.sender, amount);
    }

    /**
     * @dev Enables FOREX claiming from the next block.
     *      Requires the TGE to have been closed.
     */
    function enableForexClaims() external onlyOwner {
        assert(hasTgeEnded() && !isTgeClaimable());
        claimDate = block.timestamp + 1;
    }

    /**
     * @dev Sets the minimum and maximum token prices before the TGE starts.
     *      Also sets the deposit cap.
     * @param min The minimum token price in ETH.
     * @param max The maximum token price in ETH.
     * @param _depositCap The ETH deposit cap.
     */
    function setMinMaxForexPrices(
        uint256 min,
        uint256 max,
        uint256 _depositCap
    ) external onlyOwner {
        assert(!hasTgeBeenStarted());
        require(max > min && _depositCap > max, "Invalid values");
        minTokenPrice = min;
        maxTokenPrice = max;
        depositCap = _depositCap;
    }

    /**
     * @dev Sends ETH and reverts if the transfer fails.
     * @param recipient The transfer recipient.
     * @param amount The transfer amount.
     */
    function safeSendEth(address recipient, uint256 amount) private {
        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Failed to send ETH");
    }
}
