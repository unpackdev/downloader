// SPDX-License-Identifier: UNLICENSED
/**
 * @author Madhumitha Rathinasamy 
 */
pragma solidity ^0.8.16;

import "./Vesting.sol";

import "./Initializable.sol";
import "./UUPSUpgradeable.sol";
import "./IERC20Upgradeable.sol";
import "./ContextUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./SafeERC20Upgradeable.sol";

/**
 * @title Crowdsale
 * @dev Crowdsale is a base contract for managing a token crowdsale,
 * allowing investors to purchase tokens with ether. This contract implements
 * such functionality in its most fundamental form and can be extended to provide additional
 * functionality and/or custom behavior.
 * The external interface represents the basic interface for purchasing tokens, and conform
 * the base architecture for crowdsales. They are *not* intended to be modified / overriden.
 * The internal interface conforms the extensible and modifiable surface of crowdsales. Override
 * the methods to add functionality. Consider using 'super' where appropiate to concatenate
 * behavior.
 */
abstract contract Crowdsale is Initializable {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    // The token being sold
    IERC20Upgradeable public token;

    // Address where funds are collected
    address public wallet;

    // How many token units a buyer gets per wei
    uint256 public rate;

    // Amount of wei raised
    uint256 public weiRaised;

    /**
     * Event for token purchase logging
     * @param purchaser who paid for the tokens
     * @param beneficiary who got the tokens
     * @param value weis paid for purchase
     * @param amount amount of tokens purchased
     */
    event TokenPurchase(
        address indexed purchaser,
        address indexed beneficiary,
        uint256 value,
        uint256 amount
    );

    /**
     * @param _rate Number of token units a buyer gets per wei
     * @param _wallet Address where collected funds will be forwarded to
     * @param _token Address of the token being sold
     */
    function _Crowdsale_init_unchained(
        uint256 _rate,
        address _wallet,
        IERC20Upgradeable _token
    ) internal onlyInitializing {
        require(_rate > 0, "Rate cant be 0");
        require(_wallet != address(0), "Address cant be zero address");

        rate = _rate;
        wallet = _wallet;
        token = _token;
    }

    // -----------------------------------------
    // Crowdsale external interface
    // -----------------------------------------

    /**
     * @dev fallback function ***DO NOT OVERRIDE***
     */
    receive() external payable {
        buyTokens(msg.sender);
    }

    /**
     * @dev low level token purchase ***DO NOT OVERRIDE***
     * @param _beneficiary Address performing the token purchase
     */
    function buyTokens(address _beneficiary) internal {
        uint256 weiAmount = msg.value;
        _preValidatePurchase(_beneficiary, weiAmount);
        weiRaised = weiRaised + weiAmount;
        _forwardFunds();
    }

    // -----------------------------------------
    // Internal interface (extensible)
    // -----------------------------------------

    /**
     * @dev Validation of an incoming purchase. Use require statements to revert state when conditions are not met. Use super to concatenate validations.
     * @param _beneficiary Address performing the token purchase
     * @param _weiAmount Value in wei involved in the purchase
     */
    function _preValidatePurchase(
        address _beneficiary,
        uint256 _weiAmount
    ) internal virtual {
        require(_beneficiary != address(0), "Address cant be zero address");
        require(_weiAmount != 0, "Amount cant be 0");
    }

    /**
     * @dev Source of tokens. Override this method to modify the way in which the crowdsale ultimately gets and sends its tokens.
     * @param _beneficiary Address performing the token purchase
     * @param _tokenAmount Number of tokens to be emitted
     */
    function _deliverTokens(
        address _beneficiary,
        uint256 _tokenAmount
    ) internal {
        token.safeTransfer(_beneficiary, _tokenAmount);
    }

    /**
     * @dev Executed when a purchase has been validated and is ready to be executed. Not necessarily emits/sends tokens.
     * @param _beneficiary Address receiving the tokens
     * @param _tokenAmount Number of tokens to be purchased
     */
    function _processPurchase(
        address _beneficiary,
        uint256 _tokenAmount
    ) internal {
        _deliverTokens(_beneficiary, _tokenAmount);
    }

    /**
     * @dev Override to extend the way in which ether is converted to tokens.
     * @param _weiAmount Value in wei to be converted into tokens
     * @return Number of tokens that can be purchased with the specified _weiAmount
     */
    function _getTokenAmount(
        uint256 _weiAmount
    ) internal view returns (uint256) {
        return _weiAmount * rate;
    }

    /**
     * @dev Determines how ETH is stored/forwarded on purchases.
     */
    function _forwardFunds() internal {
        payable(wallet).transfer(msg.value);
    }

    /**
     * @dev Change Rate.
     * @param newRate Crowdsale rate
     */
    function _changeRate(uint256 newRate) internal virtual {
        rate = newRate;
    }

    /**
     * @dev Change Token.
     * @param newToken Crowdsale token
     */
    function _changeToken(IERC20Upgradeable newToken) internal virtual {
        token = newToken;
    }

    /**
     * @dev Change Wallet.
     * @param newWallet Crowdsale wallet
     */
    function _changeWallet(address newWallet) internal virtual {
        wallet = newWallet;
    }
}

/**
 * @title TimedCrowdsale
 * @dev Crowdsale accepting contributions only within a time frame.
 */
abstract contract TimedCrowdsale is Crowdsale {
    uint256 public openingTime;
    uint256 public closingTime;

    event TimedCrowdsaleExtended(
        uint256 prevClosingTime,
        uint256 newClosingTime
    );
    event TimedNewCrowdsaleExtended(
        uint256 roundOpeningTime,
        uint256 roundClosingTime,
        uint256 roundRate
    );

    /**
     * @dev Reverts if not in crowdsale time range.
     */
    modifier onlyWhileOpen() {
        // solium-disable-next-line security/no-block-members
        require(
            block.timestamp >= openingTime && block.timestamp <= closingTime,
            "Crowdsale has not started or has been ended"
        );
        _;
    }

    /**
     * @dev Constructor, takes crowdsale opening and closing times.
     * @param _openingTime Crowdsale opening time
     * @param _closingTime Crowdsale closing time
     */
    function _TimedCrowdsale_init_unchained(
        uint256 _openingTime,
        uint256 _closingTime
    ) internal onlyInitializing {
        // solium-disable-next-line security/no-block-members
        require(
            _openingTime >= block.timestamp,
            "OpeningTime must be greater than current timestamp"
        );
        require(
            _closingTime >= _openingTime,
            "Closing time cant be before opening time"
        );

        openingTime = _openingTime;
        closingTime = _closingTime;
    }

    /**
     * @dev Checks whether the period in which the crowdsale is open has already elapsed.
     * @return Whether crowdsale period has elapsed
     */
    function hasClosed() public view returns (bool) {
        // solium-disable-next-line security/no-block-members
        return block.timestamp > closingTime;
    }

    /**
     * @dev Extend crowdsale.
     * @param newClosingTime Crowdsale closing time
     */
    function _extendTime(uint256 newClosingTime) internal {
        require(
            newClosingTime >= block.timestamp,
            "Closing Time must be greater than current timestamp"
        );
        closingTime = newClosingTime;
        emit TimedCrowdsaleExtended(closingTime, newClosingTime);
    }

    /**
     * @dev new round crowdsale.
     * @param roundOpeningTime Crowdsale opening time
     * @param roundClosingTime Crowdsale closing time
     */
    function _createNewRound(
        uint256 roundOpeningTime,
        uint256 roundClosingTime,
        uint256 roundRate
    ) internal {
        require(
            roundOpeningTime >= block.timestamp,
            "opening Time must be greater than current timestamp"
        );
        require(
            roundClosingTime >= block.timestamp,
            "closing Time must be greater than current timestamp"
        );
        openingTime = roundOpeningTime;
        closingTime = roundClosingTime;
        rate = roundRate;
        emit TimedNewCrowdsaleExtended(openingTime, closingTime, rate);
    }
}

/**
 * @title FinalizableCrowdsale
 * @dev Extension of Crowdsale where an owner can do extra work
 * after finishing.
 */
abstract contract FinalizableCrowdsale is
    TimedCrowdsale,
    OwnableUpgradeable,
    PausableUpgradeable
{
    bool public isFinalized;

    event Finalized();

    /**
     * @dev Must be called after crowdsale ends, to do some extra finalization
     * work. Calls the contract's finalization function.
     */
    function finalize(bool _withdrawToken) public onlyOwner whenNotPaused {
        require(!isFinalized, "Already Finalized");
        require(hasClosed(), "Crowdsale is not yet closed");

        if (_withdrawToken) {
            finalization();
        }
        emit Finalized();

        isFinalized = true;
    }

    /**
     * @dev Can be overridden to add finalization logic. The overriding function
     * should call super.finalization() to ensure the chain of finalization is
     * executed entirely.
     */
    function finalization() internal virtual {}

    function _updateFinalization() internal {
        isFinalized = false;
    }
}

contract CrowdSale is Crowdsale, FinalizableCrowdsale, UUPSUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    mapping(address => bool) private _whitelist;
    mapping(address => bool) private _blacklist;
    mapping(address => bool) public isReferredBy;
    mapping(address => address) public _referredBy;
    mapping(address => uint256) public totalPurchaseAmount;
    mapping(address => uint256) public totalReferralAmount;

    // uint256 public purchaseLimitInWei;
    uint256 public vestingMonths;
    uint256 public _tier1;
    uint256 public _tier2;
    uint256 public _tier3;
    uint256 public minPurchaseAmount;
    uint256 public bonusPercentage;
    uint256 public round;
    uint256 public tier1MinPurchaseLimit;
    uint256 public tier2MinPurchaseLimit;
    uint256 public tier3MinPurchaseLimit;

    VestingVault vestingToken;
    address public vestingAddress;
    address public adminWallet;

    bool public whiteListingStatus;
    bool public referralStatus;

    // event SetPurchaseLimitInWei(uint256 amount);
    event SetVestingAddress(address vestingAddress);
    event UpdateWhitelistingStatus(bool enable);
    event UpdateVestingMonths(uint256 months);
    event NewTierPercentage(uint256 tier1, uint256 tier2, uint256 tier3);
    event AddReferral(address indexed _beneficiary, address indexed referredTo);
    event UpdateReferralStatus(bool isReferralStatusOn);
    event MinimumPurchaseAmountForReferral(uint256 _minimumPurchaseAmount);
    event UpdateBonusPercentage(uint256 _bonusPercentage);
    event Bonus(uint256 bonus);
    event TierPurchaseLimitForReferral(
        uint256 _tier1MinPurchaseLimit,
        uint256 _tier2MinPurchaseLimit,
        uint256 _tier3MinPurchaseLimit
    );
    event UpdateAdminWallet(address admin);

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The defaut value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize(
        uint256 rate, // rate, in TKNbits
        address payable wallet, // wallet to send Ether
        IERC20Upgradeable token, // the token
        VestingVault vesting, // the token
        uint256 openingTime, // opening time in unix epoch seconds
        uint256 closingTime, // closing time in unix epoch seconds
        address vestingVaultAddress // vesting Contract Address
    ) public initializer {
        vestingToken = vesting;
        // purchaseLimitInWei = 1500000000000000000000;
        minPurchaseAmount = 15750000000000000;
        vestingAddress = vestingVaultAddress;
        whiteListingStatus = false;
        vestingMonths = 4;
        round = 1;
        _tier1 = 10;
        _tier2 = 12;
        _tier3 = 15;
        bonusPercentage = 1;
        referralStatus = true;
        tier1MinPurchaseLimit = 10000;
        tier2MinPurchaseLimit = 20000;
        tier3MinPurchaseLimit = 500000;
        adminWallet = msg.sender;

        _TimedCrowdsale_init_unchained(openingTime, closingTime);
        _Crowdsale_init_unchained(rate, wallet, token);
        __Pausable_init_unchained();
        __Ownable_init_unchained();
        __Context_init_unchained();
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}

    /**
     * @dev Addding a account to Whitelisting
     * @param _beneficiary address of the account.
     */
    function addToWhitelist(address _beneficiary) external onlyOwner {
        _whitelist[_beneficiary] = true;
    }

    /**
     * @dev Addding multiple account to Whitelisting
     * @param _beneficiers address of the account.
     */
    function addMultipleAccountToWhitelist(
        address[] calldata _beneficiers
    ) external onlyOwner {
        for (uint256 i = 0; i < _beneficiers.length; i++) {
            _whitelist[_beneficiers[i]] = true;
        }
    }

    /**
     * @dev Removing account to Whitelisting
     * @param _beneficiary address of the account.
     */
    function removeFromWhitelist(address _beneficiary) external onlyOwner {
        _whitelist[_beneficiary] = false;
    }

    /**
     * @dev Check weather account to Whitelisted or not.
     * @param _beneficiary address of the account.
     */
    function checkWhitelisted(
        address _beneficiary
    ) external view returns (bool) {
        return _whitelist[_beneficiary];
    }

    /**
     * @dev Addding a account to Whitelisting
     * @param _beneficiary address of the account.
     */
    function addToBlacklist(address _beneficiary) external onlyOwner {
        _blacklist[_beneficiary] = true;
    }

    /**
     * @dev Addding multiple account to blacklisting
     * @param _beneficiers address of the account.
     */
    function addMultipleAccountToBlacklist(
        address[] calldata _beneficiers
    ) external onlyOwner {
        for (uint256 i = 0; i < _beneficiers.length; i++) {
            _blacklist[_beneficiers[i]] = true;
        }
    }

    /**
     * @dev Removing account to blacklisting
     * @param _beneficiary address of the account.
     */
    function removeFromBlacklist(address _beneficiary) external onlyOwner {
        _blacklist[_beneficiary] = false;
    }

    /**
     * @dev Check weather account to blacklisted or not.
     * @param _beneficiary address of the account.
     */
    function checkBlacklisted(
        address _beneficiary
    ) external view returns (bool) {
        return _blacklist[_beneficiary];
    }

    /**
     * @dev Pause `contract` - pause events.
     *
     * See {ERC20Pausable-_pause}.
     */
    function pauseContract() external virtual onlyOwner {
        _pause();
    }

    /**
     * @dev Pause `contract` - pause events.
     *
     * See {ERC20Pausable-_pause}.
     */
    function unPauseContract() external virtual onlyOwner {
        _unpause();
    }

    /**
     * @dev user can buy the token
     */
    function buyToken() external payable onlyWhileOpen whenNotPaused {
        address _beneficiary = msg.sender;
        require(
            !_blacklist[_beneficiary],
            "blacklist: Your Account has been blacklisted"
        );
        if (whiteListingStatus) {
            require(
                _whitelist[_beneficiary],
                "whitelist: Your Account has not been whitelisted"
            );
        }

        // require(
        //     msg.value <= purchaseLimitInWei,
        //     "Maximum purchase Limit exceed"
        // );
        buyTokens(_beneficiary);
        // calculate token amount to be created
        uint256 token_amount = _getTokenAmount(msg.value);

        address referredBy = _referredBy[_beneficiary];

        totalPurchaseAmount[_beneficiary] += token_amount;

        require(
            referredBy != 0x0000000000000000000000000000000000000000,
            "You cannot buy without referral address"
        );
        uint256 tokens = token_amount / 5;
        uint256 balanceAmount = token_amount - tokens;

        vestingToken.addTokenGrant(
            _beneficiary,
            balanceAmount,
            vestingMonths,
            1,
            round
        );
        token.safeTransfer(_beneficiary, tokens);
        token.safeTransfer(vestingAddress, balanceAmount);
    }

    /**
     * @dev buy token for referral users
     * @param referredTo the user type
     */
    function buyToken(
        address referredTo
    ) external payable onlyWhileOpen whenNotPaused {
        if (msg.sender != adminWallet) {
            addReferral(referredTo);
        }

        address _beneficiary = msg.sender;
        require(
            !_blacklist[_beneficiary],
            "blacklist: Your Account has been blacklisted"
        );
        if (whiteListingStatus) {
            require(
                _whitelist[_beneficiary],
                "whitelist: Your Account has not been whitelisted"
            );
        }
        // require(
        //     msg.value <= purchaseLimitInWei,
        //     "Maximum purchase Limit exceed"
        // );
        buyTokens(_beneficiary);
        // calculate token amount to be created
        uint256 token_amount = _getTokenAmount(msg.value);

        address referredBy = _referredBy[_beneficiary];

        uint256 referralAmount = 0;

        uint256 bonus = 0;

        if (
            totalPurchaseAmount[_beneficiary] == 0 &&
            referralStatus &&
            referredBy != adminWallet
        ) {
            bonus = calculateBonus(token_amount);
            emit Bonus(bonus);
        }

        if (
            referralStatus &&
            referredBy != 0x0000000000000000000000000000000000000000
        ) {
            referralAmount = calculateReferral(token_amount, referredBy);
            totalReferralAmount[referredBy] += referralAmount;
            token.safeTransfer(referredBy, referralAmount);
        }

        totalPurchaseAmount[_beneficiary] += token_amount;

        uint256 tokens = token_amount / 5;
        uint256 balanceAmount = token_amount - tokens;

        tokens += bonus;

        vestingToken.addTokenGrant(
            _beneficiary,
            balanceAmount,
            vestingMonths,
            1,
            round
        );

        token.safeTransfer(_beneficiary, tokens);
        token.safeTransfer(vestingAddress, balanceAmount);
    }

    /**
     * @dev crowd Sale has been completed and balance token has sent back to owner account
     */
    function finalization() internal virtual override {
        uint256 balance = token.balanceOf(address(this));
        require(balance > 0, "Finalization: Insufficient token balance");
        token.transfer(owner(), balance);
    }

    /**
     * @dev extending the crowd Sale closing time
     * @param newClosingTime closing time in unix format.
     */
    function extendSale(
        uint256 newClosingTime
    ) external virtual onlyOwner whenNotPaused {
        _extendTime(newClosingTime);
        _updateFinalization();
    }

    /**
     * @dev create a new round for crowd Sale with new timing
     * @param roundOpeningTime opening time in unix format.
     * @param roundClosingTime closing time in unix format.
     * @param roundRate rate for round.
     */
    function newCrowdSaleRound(
        uint256 roundOpeningTime,
        uint256 roundClosingTime,
        uint256 roundRate
    ) external virtual onlyOwner whenNotPaused {
        require(isFinalized, "Crowdsale is not yet closed");
        require(hasClosed(), "Crowdsale is not yet closed");
        require(roundRate > 0, "Rate: Amount cannot be 0");
        _createNewRound(roundOpeningTime, roundClosingTime, roundRate);
        _updateFinalization();
        round += 1;
    }

    /**
     * @dev Change the rate of the token
     * @param newRate number of token.
     */
    function changeRate(
        uint256 newRate
    ) external virtual onlyOwner onlyWhileOpen whenNotPaused {
        require(newRate > 0, "Rate: Amount cannot be 0");
        _changeRate(newRate);
    }

    /**
     * @dev Change the base token address of the token
     * @param newToken address of the token.
     */
    function changeToken(
        IERC20Upgradeable newToken
    ) external virtual onlyOwner onlyWhileOpen whenNotPaused {
        require(
            address(newToken) != address(0),
            "Token: Address cant be zero address"
        );
        _changeToken(newToken);
    }

    /**
     * @dev Change the rate of the token
     * @param newWallet number of token.
     */
    function changeWallet(
        address newWallet
    ) external virtual onlyOwner onlyWhileOpen whenNotPaused {
        require(
            newWallet != address(0),
            "Wallet: Address cant be zero address"
        );
        _changeWallet(newWallet);
    }

    // /**
    //  * @dev set the purchase limit for buy
    //  * @param amount  Amount in Wei.
    //  */
    // function setPurchaseLimitInWei(
    //     uint256 amount
    // ) external onlyOwner onlyWhileOpen whenNotPaused {
    //     purchaseLimitInWei = amount;
    //     emit SetPurchaseLimitInWei(purchaseLimitInWei);
    // }

    /**
     * @dev set the vesting Address to trnsfer the token
     * @param _vestingAddress address of the vesting concept
     */
    function setVestingAddress(
        VestingVault _vestingToken,
        address _vestingAddress
    ) external onlyOwner onlyWhileOpen whenNotPaused {
        vestingAddress = _vestingAddress;
        vestingToken = _vestingToken;
        emit SetVestingAddress(vestingAddress);
    }

    /**
     * @dev withdraw tokens from the contract
     * @param to address to receive tokens
     * @param amount amount of token to withdraw
     */
    function withdrawToken(
        address to,
        uint256 amount
    ) external onlyOwner onlyWhileOpen whenNotPaused {
        require(to != address(0), "ERC20: transfer to the zero address");
        token.safeTransfer(to, amount);
    }

    /**
     * @dev update the status of the Whitelisting
     * @param enable update the status of enable/Disable
     */
    function updateWhitelistingStatus(
        bool enable
    ) external onlyOwner onlyWhileOpen whenNotPaused {
        whiteListingStatus = enable;
        emit UpdateWhitelistingStatus(whiteListingStatus);
    }

    /**
     * @dev Vesting Months to get the values
     * @param months update the status of enable/Disable
     */
    function updateVestingMonths(
        uint256 months
    ) external onlyOwner onlyWhileOpen whenNotPaused {
        vestingMonths = months;
        emit UpdateVestingMonths(vestingMonths);
    }

    /**
     * @dev Owner can update the tier values
     * @param tier1, tier2, tier3 - updating values
     */

    function updateTierPercentage(
        uint256 tier1,
        uint256 tier2,
        uint256 tier3
    ) external onlyOwner {
        _tier1 = tier1;
        _tier2 = tier2;
        _tier3 = tier3;
        emit NewTierPercentage(tier1, tier2, tier3);
    }

    /**
     * @dev calculate referral values
     * @param tokens - token to calculate the referral value
     */

    function calculateReferral(
        uint256 tokens,
        address referredBy
    ) internal view returns (uint256) {
        if (
            totalPurchaseAmount[referredBy] >=
            (tier1MinPurchaseLimit * 10 ** 18) &&
            totalPurchaseAmount[referredBy] < (tier2MinPurchaseLimit * 10 ** 18)
        ) {
            // uint256 referralAmount =
            return (tokens * _tier1) / 100;
        } else if (
            totalPurchaseAmount[referredBy] >=
            (tier2MinPurchaseLimit * 10 ** 18) &&
            totalPurchaseAmount[referredBy] < (tier3MinPurchaseLimit * 10 ** 18)
        ) {
            return (tokens * _tier2) / 100;
        } else if (
            totalPurchaseAmount[referredBy] >=
            (tier3MinPurchaseLimit * 10 ** 18)
        ) {
            return (tokens * _tier3) / 100;
        } else {
            return 0;
        }
    }

    /**
     * @dev add referral
     * @param _beneficiary, referred the msg.sender
     */

    function addReferral(address _beneficiary) internal {
        require(
            totalPurchaseAmount[_beneficiary] >= minPurchaseAmount,
            "The person cannot refer"
        );
        require(
            _referredBy[msg.sender] ==
                0x0000000000000000000000000000000000000000,
            "Already referred"
        );
        require(
            totalPurchaseAmount[msg.sender] == 0,
            "User cannot add referral"
        );
        _referredBy[msg.sender] = _beneficiary;
        isReferredBy[msg.sender] = true;
        emit AddReferral(_beneficiary, msg.sender);
    }

    /**
     * @dev owner can update the referral status
     * @param isReferralStatusOn - get the boolean value
     */

    function updateReferralStatus(bool isReferralStatusOn) external onlyOwner {
        referralStatus = isReferralStatusOn;
        emit UpdateReferralStatus(isReferralStatusOn);
    }

    /* *
     * @dev owner can update minimum purchase amount for referral
     * @param minPurchaseAmount minimum purchase amount
     */

    function updateMinPurchaseAmountForReferral(
        uint256 _minPurchaseAmount
    ) external onlyOwner {
        minPurchaseAmount = _minPurchaseAmount;
        emit MinimumPurchaseAmountForReferral(_minPurchaseAmount);
    }

    /**
     * @dev to calculateUserBonus
     * @param amount to calculate the bonus
     */

    function calculateBonus(uint256 amount) internal view returns (uint256) {
        uint256 bonus = (amount * bonusPercentage) / 100;
        return bonus;
    }

    /**
     @dev to update bonus percentage
     @param _bonusPercentage changing value
     */

    function updateBonusPercentage(
        uint256 _bonusPercentage
    ) external onlyOwner {
        bonusPercentage = _bonusPercentage;
        emit UpdateBonusPercentage(_bonusPercentage);
    }

    /**
    * @dev to update the minimum to maxmum purchase limit for calculating referral percentage
    * @param _tier1MinPurchaseLimit and _tier2MinPurchaseLimit and _tier3MinPurchaseLimit
     */

    function updateTierEligibleAmount(
        uint256 _tier1MinPurchaseLimit,
        uint256 _tier2MinPurchaseLimit,
        uint256 _tier3MinPurchaseLimit
    ) external onlyOwner {
        tier1MinPurchaseLimit = _tier1MinPurchaseLimit;
        tier2MinPurchaseLimit = _tier2MinPurchaseLimit;
        tier3MinPurchaseLimit = _tier3MinPurchaseLimit;
        emit TierPurchaseLimitForReferral(
            _tier1MinPurchaseLimit,
            _tier2MinPurchaseLimit,
            _tier3MinPurchaseLimit
        );
    }

    /**
     * update admin wallet
     */
    function updateAdminWallet(address admin) external onlyOwner {
        adminWallet = admin;
        emit UpdateAdminWallet(admin);
    }
}
