pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./ReentrancyGuard.sol";
import "./MISOAccessControls.sol";
import "./SafeTransfer.sol";
import "./BoringBatchable.sol";
import "./BoringMath.sol";
import "./BoringERC20.sol";
import "./Documents.sol";
import "./IMisoMarket.sol";


library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "MUL_ERROR");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "DIVIDING_ERROR");
        return a / b;
    }

    function divCeil(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 quotient = div(a, b);
        uint256 remainder = a - quotient * b;
        if (remainder > 0) {
            return quotient + 1;
        } else {
            return quotient;
        }
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SUB_ERROR");
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "ADD_ERROR");
        return c;
    }

    function sqrt(uint256 x) internal pure returns (uint256 y) {
        uint256 z = x / 2 + 1;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }
}

/**
 * @title DecimalMath
 * @author DODO Breeder
 *
 * @notice Functions for fixed point number with 18 decimals
 */
library DecimalMath {
    using SafeMath for uint256;

    uint256 constant ONE = 10**18;

    function mul(uint256 target, uint256 d) internal pure returns (uint256) {
        return target.mul(d) / ONE;
    }

    function divFloor(uint256 target, uint256 d)
        internal
        pure
        returns (uint256)
    {
        return target.mul(ONE).div(d);
    }

    function divCeil(uint256 target, uint256 d)
        internal
        pure
        returns (uint256)
    {
        return target.mul(ONE).divCeil(d);
    }
}

/// @notice Attribution to delta.financial
/// @notice Attribution to dutchswap.com

contract BatchAuction is
    MISOAccessControls,
    BoringBatchable,
    SafeTransfer,
    ReentrancyGuard
{
    using BoringMath for uint256;
    using BoringMath128 for uint128;
    using BoringMath64 for uint64;
    using BoringERC20 for IERC20;

    /// @dev The placeholder ETH address.
    address private constant ETH_ADDRESS =
        0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    /// @notice Main market variables.
    struct MarketInfo {
        uint64 startTime;
        uint64 endTime;
        uint128 totalTokens;
    }
    MarketInfo public marketInfo;

    /// @notice Market dynamic variables.
    struct MarketStatus {
        uint128 commitmentsTotal;
        uint128 minimumCommitmentAmount;
        bool finalized;
    }

    uint256 public startReleaseTime;
    uint256 public releaseDuration;
    MarketStatus public marketStatus;

    address public auctionToken;
    /// @notice The currency the crowdsale accepts for payment. Can be ETH or token address.
    address public paymentCurrency;
    address payable public wallet; // Where the auction funds will get paid

    mapping(address => uint256) public commitments;
    /// @notice Amount of tokens to claim per address.
    mapping(address => uint256) public claimed;

    /// @notice Event for updating auction times.  Needs to be before auction starts.
    event AuctionTimeUpdated(uint256 startTime, uint256 endTime);
    /// @notice Event for updating auction prices. Needs to be before auction starts.
    event AuctionPriceUpdated(uint256 minimumCommitmentAmount);
    /// @notice Event for updating auction wallet. Needs to be before auction starts.
    event AuctionWalletUpdated(address wallet);

    /// @notice Event for adding a commitment.
    event AddedCommitment(address addr, uint256 commitment);
    /// @notice Event for finalization of the auction.
    event AuctionFinalized();
    /// @notice Event for cancellation of the auction.
    event AuctionCancelled();

    /**
     * @notice Initializes main contract variables and transfers funds for the auction.
     * @dev Init function.
     * @param _funder The address that funds the token for crowdsale.
     * @param _token Address of the token being sold.
     * @param _totalTokens The total number of tokens to sell in auction.
     * @param _startTime Auction start time.
     * @param _endTime Auction end time.
     * @param _paymentCurrency The currency the crowdsale accepts for payment. Can be ETH or token address.
     * @param _minimumCommitmentAmount Minimum amount collected at which the auction will be successful.
     * @param _admin Address that can finalize auction.
     * @param _releaseDuration Time during which tokens will be released after successfull auction.
     * @param _wallet Address where collected funds will be forwarded to.
     */
    function initAuction(
        address _funder,
        address _token,
        uint256 _totalTokens,
        uint256 _startTime,
        uint256 _endTime,
        address _paymentCurrency,
        uint256 _minimumCommitmentAmount,
        address _admin,
        uint256 _releaseDuration,
        address payable _wallet
    ) public {
        require(
            _startTime < 10000000000,
            "BatchAuction: enter an unix timestamp in seconds, not miliseconds"
        );
        require(
            _endTime < 10000000000,
            "BatchAuction: enter an unix timestamp in seconds, not miliseconds"
        );
        require(
            _startTime >= block.timestamp,
            "BatchAuction: start time is before current time"
        );
        require(
            _endTime > _startTime,
            "BatchAuction: end time must be older than start time"
        );
        require(
            _totalTokens > 0,
            "BatchAuction: total tokens must be greater than zero"
        );
        require(
            _admin != address(0),
            "BatchAuction: admin is the zero address"
        );
        require(
            _wallet != address(0),
            "BatchAuction: wallet is the zero address"
        );
        require(
            IERC20(_token).decimals() == 18,
            "BatchAuction: Token does not have 18 decimals"
        );
        if (_paymentCurrency != ETH_ADDRESS) {
            require(
                IERC20(_paymentCurrency).decimals() > 0,
                "BatchAuction: Payment currency is not ERC20"
            );
        }

        marketStatus.minimumCommitmentAmount = BoringMath.to128(
            _minimumCommitmentAmount
        );

        marketInfo.startTime = BoringMath.to64(_startTime);
        marketInfo.endTime = BoringMath.to64(_endTime);
        marketInfo.totalTokens = BoringMath.to128(_totalTokens);

        auctionToken = _token;
        paymentCurrency = _paymentCurrency;
        wallet = _wallet;
        releaseDuration = _releaseDuration;

        initAccessControls(_admin);

        _safeTransferFrom(auctionToken, _funder, _totalTokens);
    }

    ///--------------------------------------------------------
    /// Commit to buying tokens!
    ///--------------------------------------------------------

    receive() external payable {
        revertBecauseUserDidNotProvideAgreement();
    }

    /**
     * @dev Attribution to the awesome delta.financial contracts
     */
    function marketParticipationAgreement()
        public
        pure
        returns (string memory)
    {
        return
            "I understand that I am interacting with a smart contract. I understand that tokens commited are subject to the token issuer and local laws where applicable. I have reviewed the code of this smart contract and understand it fully. I agree to not hold developers or other people associated with the project liable for any losses or misunderstandings";
    }

    /**
     * @dev Not using modifiers is a purposeful choice for code readability.
     */
    function revertBecauseUserDidNotProvideAgreement() internal pure {
        revert(
            "No agreement provided, please review the smart contract before interacting with it"
        );
    }

    /**
     * @notice Commit ETH to buy tokens on auction.
     * @param _beneficiary Auction participant ETH address.
     */
    function commitEth(
        address payable _beneficiary,
        bool readAndAgreedToMarketParticipationAgreement
    ) public payable {
        require(
            paymentCurrency == ETH_ADDRESS,
            "BatchAuction: payment currency is not ETH"
        );

        require(msg.value > 0, "BatchAuction: Value must be higher than 0");
        if (readAndAgreedToMarketParticipationAgreement == false) {
            revertBecauseUserDidNotProvideAgreement();
        }
        _addCommitment(_beneficiary, msg.value);
    }

    /**
     * @notice Buy Tokens by commiting approved ERC20 tokens to this contract address.
     * @param _amount Amount of tokens to commit.
     */
    function commitTokens(
        uint256 _amount,
        bool readAndAgreedToMarketParticipationAgreement
    ) public {
        commitTokensFrom(
            msg.sender,
            _amount,
            readAndAgreedToMarketParticipationAgreement
        );
    }

    /**
     * @notice Checks if amout not 0 and makes the transfer and adds commitment.
     * @dev Users must approve contract prior to committing tokens to auction.
     * @param _from User ERC20 address.
     * @param _amount Amount of approved ERC20 tokens.
     */
    function commitTokensFrom(
        address _from,
        uint256 _amount,
        bool readAndAgreedToMarketParticipationAgreement
    ) public nonReentrant {
        require(
            paymentCurrency != ETH_ADDRESS,
            "BatchAuction: Payment currency is not a token"
        );
        if (readAndAgreedToMarketParticipationAgreement == false) {
            revertBecauseUserDidNotProvideAgreement();
        }
        require(_amount > 0, "BatchAuction: Value must be higher than 0");
        _safeTransferFrom(paymentCurrency, msg.sender, _amount);
        _addCommitment(_from, _amount);
    }

    /// @notice Commits to an amount during an auction
    /**
     * @notice Updates commitment for this address and total commitment of the auction.
     * @param _addr Auction participant address.
     * @param _commitment The amount to commit.
     */
    function _addCommitment(address _addr, uint256 _commitment) internal {
        require(
            block.timestamp >= marketInfo.startTime &&
                block.timestamp <= marketInfo.endTime,
            "BatchAuction: outside auction hours"
        );

        uint256 newCommitment = commitments[_addr].add(_commitment);
        commitments[_addr] = newCommitment;
        marketStatus.commitmentsTotal = BoringMath.to128(
            uint256(marketStatus.commitmentsTotal).add(_commitment)
        );
        emit AddedCommitment(_addr, _commitment);
    }

    /**
     * @notice Calculates amount of auction tokens for user to receive.
     * @param amount Amount of tokens to commit.
     * @return Auction token amount.
     */
    function _getTokenAmount(uint256 amount) internal view returns (uint256) {
        if (marketStatus.commitmentsTotal == 0) return 0;
        return amount.mul(1e18).div(tokenPrice());
    }

    /**
     * @notice Calculates the price of each token from all commitments.
     * @return Token price.
     */
    function tokenPrice() public view returns (uint256) {
        return
            uint256(marketStatus.commitmentsTotal).mul(1e18).div(
                uint256(marketInfo.totalTokens)
            );
    }

    ///--------------------------------------------------------
    /// Finalize Auction
    ///--------------------------------------------------------

    /// @notice Auction finishes successfully above the reserve
    /// @dev Transfer contract funds to initialized wallet.
    function finalize() public nonReentrant {
        require(
            hasAdminRole(msg.sender) ||
                wallet == msg.sender ||
                hasSmartContractRole(msg.sender) ||
                finalizeTimeExpired(),
            "BatchAuction: Sender must be admin"
        );
        require(
            !marketStatus.finalized,
            "BatchAuction: Auction has already finalized"
        );
        require(
            block.timestamp > marketInfo.endTime,
            "BatchAuction: Auction has not finished yet"
        );
        if (auctionSuccessful()) {
            /// @dev Successful auction
            /// @dev Transfer contributed tokens to wallet.
            _safeTokenPayment(
                paymentCurrency,
                wallet,
                uint256(marketStatus.commitmentsTotal)
            );
        } else {
            /// @dev Failed auction
            /// @dev Return auction tokens back to wallet.
            _safeTokenPayment(auctionToken, wallet, marketInfo.totalTokens);
        }
        marketStatus.finalized = true;
        startReleaseTime = block.timestamp;
        emit AuctionFinalized();
    }

    /**
     * @notice Cancel Auction
     * @dev Admin can cancel the auction before it starts
     */
    function cancelAuction() public nonReentrant {
        require(hasAdminRole(msg.sender));
        MarketStatus storage status = marketStatus;
        require(!status.finalized, "Crowdsale: already finalized");
        require(
            uint256(status.commitmentsTotal) == 0,
            "Crowdsale: Funds already raised"
        );

        _safeTokenPayment(
            auctionToken,
            wallet,
            uint256(marketInfo.totalTokens)
        );

        status.finalized = true;
        emit AuctionCancelled();
    }

    /// @notice Withdraws bought tokens, or returns commitment if the sale is unsuccessful.
    function withdrawTokens() public {
        withdrawTokens(msg.sender);
    }

    /// @notice Withdraw your tokens once the Auction has ended.
    function withdrawTokens(address payable beneficiary) public nonReentrant {
        if (auctionSuccessful()) {
            require(marketStatus.finalized, "BatchAuction: not finalized");
            /// @dev Successful auction! Transfer claimed tokens.
            uint256 tokensToClaim = tokensClaimable(beneficiary);
            require(tokensToClaim > 0, "BatchAuction: No tokens to claim");
            _safeTokenPayment(auctionToken, beneficiary, tokensToClaim);
            claimed[beneficiary] = claimed[beneficiary].add(tokensToClaim);
        } else {
            /// @dev Auction did not meet reserve price.
            /// @dev Return committed funds back to user.
            require(
                block.timestamp > marketInfo.endTime,
                "BatchAuction: Auction has not finished yet"
            );
            uint256 fundsCommitted = commitments[beneficiary];
            require(fundsCommitted > 0, "BatchAuction: No funds committed");
            commitments[beneficiary] = 0; // Stop multiple withdrawals and free some gas
            _safeTokenPayment(paymentCurrency, beneficiary, fundsCommitted);
        }
    }

    /**
     * @notice How many tokens the user is able to claim.
     * @param _user Auction participant address.
     * @return claimable Tokens left to claim.
     */
    function tokensClaimable(address _user)
        public
        view
        returns (uint256)
    {
        if (!marketStatus.finalized) return 0;
        if (commitments[_user] == 0) return 0;
        uint256 unclaimedTokens = IERC20(auctionToken).balanceOf(address(this));
        uint256 claimerCommitment = _getTokenAmount(commitments[_user]);

        uint256 remainingToken = getRemainingAmount(_user);
        uint256 claimable = claimerCommitment.sub(remainingToken).sub(claimed[_user]);

        if (claimable > unclaimedTokens) {
            claimable = unclaimedTokens;
        }
        return claimable;
    }

    function getRemainingAmount(address _user) public view returns (uint256) {
        uint256 claimerCommitment = _getTokenAmount(commitments[_user]);
        uint256 remainingRatio = getRemainingRatio(block.timestamp);
        return DecimalMath.ONE.mul(7).div(10).mul(claimerCommitment).mul(remainingRatio);
    }

    function getRemainingRatio(uint256 timestamp)
        public
        view
        returns (uint256)
    {
        if (startReleaseTime == 0) return DecimalMath.ONE;
        uint256 timePast = timestamp.sub(startReleaseTime);
        if (timePast < releaseDuration) {
            uint256 remainingTime = releaseDuration.sub(timePast);
            return DecimalMath.ONE.mul(remainingTime).div(releaseDuration);
        } else {
            return 0;
        }
    }

    /**
     * @notice Checks if raised more than minimum amount.
     * @return True if tokens sold greater than or equals to the minimum commitment amount.
     */
    function auctionSuccessful() public view returns (bool) {
        return
            uint256(marketStatus.commitmentsTotal) >=
            uint256(marketStatus.minimumCommitmentAmount) &&
            uint256(marketStatus.commitmentsTotal) > 0;
    }

    /**
     * @notice Checks if the auction has ended.
     * @return bool True if current time is greater than auction end time.
     */
    function auctionEnded() public view returns (bool) {
        return block.timestamp > marketInfo.endTime;
    }

    /**
     * @notice Checks if the auction has been finalised.
     * @return bool True if auction has been finalised.
     */
    function finalized() public view returns (bool) {
        return marketStatus.finalized;
    }

    /// @notice Returns true if 7 days have passed since the end of the auction
    function finalizeTimeExpired() public view returns (bool) {
        return uint256(marketInfo.endTime) + 7 days < block.timestamp;
    }

    //--------------------------------------------------------
    // Setter Functions
    //--------------------------------------------------------

    /**
     * @notice Admin can set start and end time through this function.
     * @param _startTime Auction start time.
     * @param _endTime Auction end time.
     */
    function setAuctionTime(uint256 _startTime, uint256 _endTime) external {
        require(hasAdminRole(msg.sender));
        require(
            _startTime < 10000000000,
            "BatchAuction: enter an unix timestamp in seconds, not miliseconds"
        );
        require(
            _endTime < 10000000000,
            "BatchAuction: enter an unix timestamp in seconds, not miliseconds"
        );
        require(
            _startTime >= block.timestamp,
            "BatchAuction: start time is before current time"
        );
        require(
            _endTime > _startTime,
            "BatchAuction: end time must be older than start price"
        );

        require(
            marketStatus.commitmentsTotal == 0,
            "BatchAuction: auction cannot have already started"
        );

        marketInfo.startTime = BoringMath.to64(_startTime);
        marketInfo.endTime = BoringMath.to64(_endTime);

        emit AuctionTimeUpdated(_startTime, _endTime);
    }

    /**
     * @notice Admin can set start and min price through this function.
     * @param _minimumCommitmentAmount Auction minimum raised target.
     */
    function setAuctionPrice(uint256 _minimumCommitmentAmount) external {
        require(hasAdminRole(msg.sender));

        require(
            marketStatus.commitmentsTotal == 0,
            "BatchAuction: auction cannot have already started"
        );

        marketStatus.minimumCommitmentAmount = BoringMath.to128(
            _minimumCommitmentAmount
        );

        emit AuctionPriceUpdated(_minimumCommitmentAmount);
    }

    /**
     * @notice Admin can set the auction wallet through this function.
     * @param _wallet Auction wallet is where funds will be sent.
     */
    function setAuctionWallet(address payable _wallet) external {
        require(hasAdminRole(msg.sender));
        require(
            _wallet != address(0),
            "BatchAuction: wallet is the zero address"
        );

        wallet = _wallet;

        emit AuctionWalletUpdated(_wallet);
    }

    //--------------------------------------------------------
    // Market Launchers
    //--------------------------------------------------------

    function getBaseInformation()
        external
        view
        returns (
            address token,
            uint64 startTime,
            uint64 endTime,
            bool marketFinalized
        )
    {
        return (
            auctionToken,
            marketInfo.startTime,
            marketInfo.endTime,
            marketStatus.finalized
        );
    }

    function getTotalTokens() external view returns (uint256) {
        return uint256(marketInfo.totalTokens);
    }
}
