// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "./Initializable.sol";
import "./UUPSUpgradeable.sol";
import "./IERC20Upgradeable.sol";
import "./ContextUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./PausableUpgradeable.sol";

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
    // The token being sold
    IERC20Upgradeable public token;

    // Address where funds are collected
    address public wallet;

    // How many token units a buyer gets per wei
    uint256 public rate;

    // Amount of wei raised
    uint256 public weiRaised;

    // Date and time of token claim
    uint256 public claimDateTime;

    // User's token contribution
    mapping(address => uint256) public userTokenContribution;

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
     * Event for token claim logging
     * @param beneficiary token receiver
     * @param amount amount of tokens beneficiary receives
     */
    event TokenClaim(address indexed beneficiary, uint256 amount);

    /**
     * @param _rate Number of token units a buyer gets per wei
     * @param _claimDateTime Date and time of token claim
     * @param _wallet Address where collected funds will be forwarded to
     * @param _token Address of the token being sold
     */
    function __Crowdsale_init_unchained(
        uint256 _rate,
        uint256 _claimDateTime,
        address _wallet,
        IERC20Upgradeable _token
    ) internal {
        require(_rate > 0, "Rate cant be 0");
        require(_wallet != address(0), "Address cant be zero address");

        rate = _rate;
        claimDateTime = _claimDateTime;
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

        // calculate token amount to be created
        uint256 tokens = _getTokenAmount(weiAmount);

        // update state
        weiRaised = weiRaised + weiAmount;

        // incrementing beneficiary's token contribution
        userTokenContribution[_beneficiary] += tokens;

        emit TokenPurchase(msg.sender, _beneficiary, weiAmount, tokens);

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
        token.transfer(_beneficiary, _tokenAmount);
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

    /**
     * @dev Change Date and Time of Token Claim.
     * @param newClaimDateTime New Date and Time of Token Claim.
     */
    function _changeClaimDateTime(uint256 newClaimDateTime) internal virtual {
        claimDateTime = newClaimDateTime;
    }

    /**
     * @dev Handles the process of users claiming their tokens.
     * Emits a {TokenClaim} event upon a successful token claim.
     */
    function _claimTokens() internal {
        uint256 tokenAmount = userTokenContribution[msg.sender];
        userTokenContribution[msg.sender] = 0;
        require(
            block.timestamp >= claimDateTime,
            "Claim time has not been reached yet"
        );
        require(tokenAmount > 0, "User token contribution is zero");
        _processPurchase(msg.sender, tokenAmount);
        emit TokenClaim(msg.sender, tokenAmount);
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
     * @dev __TimedCrowdsale_init_unchained, takes crowdsale opening and closing times.
     * @param _openingTime Crowdsale opening time
     * @param _closingTime Crowdsale closing time
     * @param _claimDateTime Date and time of token claim
     */
    function __TimedCrowdsale_init_unchained(
        uint256 _openingTime,
        uint256 _closingTime,
        uint256 _claimDateTime
    ) internal {
        // solium-disable-next-line security/no-block-members
        require(
            _openingTime >= block.timestamp,
            "OpeningTime must be greater than current timestamp"
        );
        require(
            _closingTime >= _openingTime,
            "Closing time cant be before opening time"
        );
        require(
            _claimDateTime >= _closingTime,
            "Token claiming is only available after the sale closes."
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
            claimDateTime >= newClosingTime,
            "Sale closing time must be less than token claim time."
        );
        closingTime = newClosingTime;
        emit TimedCrowdsaleExtended(closingTime, newClosingTime);
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
    function finalize() public onlyOwner whenNotPaused {
        require(!isFinalized, "Already Finalized");
        require(hasClosed(), "Crowdsale is not yet closed");

        finalization();
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

/**
 * @title BOBNETCROWDSALE
 * @dev A crowdsale contract with various features such as pausing, finalization, rate changes,
 * token changes, wallet changes, and extension of sale duration.
 */
contract BOBNETCROWDSALE is
    Crowdsale,
    PausableUpgradeable,
    FinalizableCrowdsale,
    UUPSUpgradeable
{
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    /**
     * @dev Initialize the crowdsale contract.
     * @param rate The rate at which tokens are sold per wei.
     * @param wallet The address where funds are collected.
     * @param token The token to be sold.
     * @param openingTime The start time of the crowdsale.
     * @param closingTime The end time of the crowdsale.
     * @param claimDateTime Date and time of token claim.
     */
    function initialize(
        uint256 rate,
        address payable wallet,
        IERC20Upgradeable token,
        uint256 openingTime,
        uint256 closingTime,
        uint256 claimDateTime
    ) public initializer {
        __TimedCrowdsale_init_unchained(
            openingTime,
            closingTime,
            claimDateTime
        );
        __Crowdsale_init_unchained(rate, claimDateTime, wallet, token);
        __Pausable_init_unchained();
        __Ownable_init_unchained();
        __Context_init_unchained();
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}

    /**
     * @dev Pause the contract, preventing token purchases and transfers.
     * See {ERC20Pausable-_pause}.
     */
    function pauseContract() external virtual onlyOwner {
        _pause();
    }

    /**
     * @dev Unpause the contract, allowing token purchases and transfers to resume.
     * See {ERC20Pausable-_unpause}.
     */
    function unPauseContract() external virtual onlyOwner {
        _unpause();
    }

    /**
     * @dev Purchase tokens for a specified beneficiary.
     * @param _beneficiary The address of the beneficiary.
     */
    function buyToken(
        address _beneficiary
    ) external payable onlyWhileOpen whenNotPaused {
        buyTokens(_beneficiary);
    }

    /**
     * @dev Allows an eligible user to claim their entitled tokens.
     */
    function claimToken() external whenNotPaused {
        _claimTokens();
    }

    /**
     * @dev Finalize the crowdsale by transferring any remaining tokens to the owner.
     */
    function finalization() internal virtual override {
        uint256 balance = token.balanceOf(address(this));
        require(balance > 0, "Finalization: Insufficient token balance");
        token.transfer(owner(), balance);
    }

    /**
     * @dev Extend the sale duration by updating the closing time.
     * @param newClosingTime The new closing time for the crowdsale.
     */
    function extendSale(
        uint256 newClosingTime
    ) external virtual onlyOwner whenNotPaused {
        _extendTime(newClosingTime);
        _updateFinalization();
    }

    /**
     * @dev Change the rate at which tokens are sold per wei.
     * @param newRate The new rate to be set.
     */
    function changeRate(
        uint256 newRate
    ) external virtual onlyOwner onlyWhileOpen whenNotPaused {
        require(newRate > 0, "Rate: Amount cannot be 0");
        _changeRate(newRate);
    }

    /**
     * @dev Change the token being sold in the crowdsale.
     * @param newToken The new token contract address to be used.
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
     * @dev Change the wallet address where funds are collected.
     * @param newWallet The new wallet address to be used.
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

    /**
     * @dev Change Date and Time of Token Claim.
     * @param newClaimDateTime New Date and Time of Token Claim.
     */
    function changeClaimDateTime(
        uint256 newClaimDateTime
    ) external virtual onlyOwner whenNotPaused {
        require(
            newClaimDateTime >= closingTime,
            "Sale closing time must be less than token claim time."
        );
        _changeClaimDateTime(newClaimDateTime);
    }
}