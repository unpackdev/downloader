pragma solidity ^0.8.0;

import "./Context.sol";
import "./IERC20.sol";
import "./Math.sol";
import "./SafeMath.sol";
import "./SafeERC20.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";

/**
 * @title Crowdsale
 * @dev Crowdsale is a base contract for managing a token crowdsale,
 * allowing investors to purchase tokens with ether. This contract implements
 * such functionality in its most fundamental form and can be extended to provide additional
 * functionality and/or custom behavior.
 * The external interface represents the basic interface for purchasing tokens, and conforms
 * the base architecture for crowdsales. It is *not* intended to be modified / overridden.
 * The internal interface conforms the extensible and modifiable surface of crowdsales. Override
 * the methods to add functionality. Consider using 'super' where appropriate to concatenate
 * behavior.
 */
contract Crowdsale is Context, ReentrancyGuard, Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // The token being sold
    IERC20 private _token;

    // Address where funds are collected
    address payable private _wallet;

    // How many token units a buyer gets per wei.
    // The rate is the conversion between wei and the smallest and indivisible token unit.
    // So, if you are using a rate of 1 with a ERC20Detailed token with 3 decimals called TOK
    // 1 wei will give you 1 unit, or 0.001 TOK.
    uint256 private _rate;

    // Amount of wei raised
    uint256 private _weiRaised;

    /**
     * Event for token purchase logging
     * @param purchaser who paid for the tokens
     * @param beneficiary who got the tokens
     * @param value weis paid for purchase
     * @param amount amount of tokens purchased
     */
    event TokensPurchased(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

    /**
     * @param rate Number of token units a buyer gets per wei
     * @dev The rate is the conversion between wei and the smallest and indivisible
     * token unit. So, if you are using a rate of 1 with a ERC20Detailed token
     * with 3 decimals called TOK, 1 wei will give you 1 unit, or 0.001 TOK.
     * @param wallet Address where collected funds will be forwarded to
     * @param token Address of the token being sold
     */
    constructor (uint256 rate, address payable wallet, IERC20 token) public {
        require(rate > 0, "Crowdsale: rate is 0");
        require(wallet != address(0), "Crowdsale: wallet is the zero address");
        require(address(token) != address(0), "Crowdsale: token is the zero address");

        _rate = rate;
        _wallet = wallet;
        _token = token;
    }

    /**
     * @dev fallback function ***DO NOT OVERRIDE***
     * Note that other contracts will transfer funds with a base gas stipend
     * of 2300, which is not enough to call buyTokens. Consider calling
     * buyTokens directly when purchasing tokens from a contract.
     */
    fallback () external payable {
        buyTokens(_msgSender());
    }

    /**
     * @return the token being sold.
     */
    function token() public view returns (IERC20) {
        return _token;
    }

    /**
     * @return the address where funds are collected.
     */
    function wallet() public view returns (address payable) {
        return _wallet;
    }

    /**
     * @return the number of token units a buyer gets per wei.
     */
    function rate() public view returns (uint256) {
        return _rate;
    }

    /**
     * @dev set the number of token units a buyer gets per wei.
     */
    function setRate(uint256 newRate) public onlyOwner {
        _rate = newRate;
    }

    /**
     * @return the amount of wei raised.
     */
    function weiRaised() public view returns (uint256) {
        return _weiRaised;
    }

    /**
     * @dev low level token purchase ***DO NOT OVERRIDE***
     * This function has a non-reentrancy guard, so it shouldn't be called by
     * another `nonReentrant` function.
     * @param beneficiary Recipient of the token purchase
     */
    function buyTokens(address beneficiary) public virtual nonReentrant payable {
        uint256 weiAmount = msg.value;
        _preValidatePurchase(beneficiary, weiAmount);

        // calculate token amount to be created
        uint256 tokens = _getTokenAmount(weiAmount);

        // update state
        _weiRaised = _weiRaised.add(weiAmount);

        _processPurchase(beneficiary, tokens);
        emit TokensPurchased(_msgSender(), beneficiary, weiAmount, tokens);

        _updatePurchasingState(beneficiary, weiAmount);

        _forwardFunds();
        _postValidatePurchase(beneficiary, weiAmount);
    }

    /**
     * @dev Validation of an incoming purchase. Use require statements to revert state when conditions are not met.
     * Use `super` in contracts that inherit from Crowdsale to extend their validations.
     * Example from CappedCrowdsale.sol's _preValidatePurchase method:
     *     super._preValidatePurchase(beneficiary, weiAmount);
     *     require(weiRaised().add(weiAmount) <= cap);
     * @param beneficiary Address performing the token purchase
     * @param weiAmount Value in wei involved in the purchase
     */
    function _preValidatePurchase(address beneficiary, uint256 weiAmount) internal view {
        require(beneficiary != address(0), "Crowdsale: beneficiary is the zero address");
        require(weiAmount != 0, "Crowdsale: weiAmount is 0");
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
    }

    /**
     * @dev Validation of an executed purchase. Observe state and use revert statements to undo rollback when valid
     * conditions are not met.
     * @param beneficiary Address performing the token purchase
     * @param weiAmount Value in wei involved in the purchase
     */
    function _postValidatePurchase(address beneficiary, uint256 weiAmount) internal view {
        // solhint-disable-previous-line no-empty-blocks
    }

    /**
     * @dev Source of tokens. Override this method to modify the way in which the crowdsale ultimately gets and sends
     * its tokens.
     * @param beneficiary Address performing the token purchase
     * @param tokenAmount Number of tokens to be emitted
     */
    function _deliverTokens(address beneficiary, uint256 tokenAmount) virtual internal {
        _token.safeTransfer(beneficiary, tokenAmount);
    }

    /**
     * @dev Executed when a purchase has been validated and is ready to be executed. Doesn't necessarily emit/send
     * tokens.
     * @param beneficiary Address receiving the tokens
     * @param tokenAmount Number of tokens to be purchased
     */
    function _processPurchase(address beneficiary, uint256 tokenAmount) internal {
        _deliverTokens(beneficiary, tokenAmount);
    }

    /**
     * @dev Override for extensions that require an internal state to check for validity (current user contributions,
     * etc.)
     * @param beneficiary Address receiving the tokens
     * @param weiAmount Value in wei involved in the purchase
     */
    function _updatePurchasingState(address beneficiary, uint256 weiAmount) internal {
        // solhint-disable-previous-line no-empty-blocks
    }

    /**
     * @dev Override to extend the way in which ether is converted to tokens.
     * @param weiAmount Value in wei to be converted into tokens
     * @return Number of tokens that can be purchased with the specified _weiAmount
     */
    function _getTokenAmount(uint256 weiAmount) virtual internal view returns (uint256) {
        return weiAmount.mul(_rate);
    }

    /**
     * @dev Determines how ETH is stored/forwarded on purchases.
     */
    function _forwardFunds() virtual internal {
        _wallet.transfer(msg.value);
    }
}

/**
 * @title AllowanceCrowdsale
 * @dev Extension of Crowdsale where tokens are held by a wallet, which approves an allowance to the crowdsale.
 */
abstract contract AllowanceCrowdsale is Crowdsale {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    address private _tokenWallet;

    /**
     * @dev Constructor, takes token wallet address.
     * @param tokenWallet Address holding the tokens, which has approved allowance to the crowdsale.
     */
    constructor (address tokenWallet) {
        require(tokenWallet != address(0), "AllowanceCrowdsale: token wallet is the zero address");
        _tokenWallet = tokenWallet;
    }

    /**
     * @return the address of the wallet that will hold the tokens.
     */
    function tokenWallet() public view returns (address) {
        return _tokenWallet;
    }

    /**
     * @dev Checks the amount of tokens left in the allowance.
     * @return Amount of tokens left in the allowance
     */
    function remainingTokens() public view returns (uint256) {
        return Math.min(token().balanceOf(_tokenWallet), token().allowance(_tokenWallet, address(this)));
    }

    /**
     * @dev Overrides parent behavior by transferring tokens from wallet.
     * @param beneficiary Token purchaser
     * @param tokenAmount Amount of tokens purchased
     */
    function _deliverTokens(address beneficiary, uint256 tokenAmount) override internal {
        token().safeTransferFrom(_tokenWallet, beneficiary, tokenAmount);
    }
}

contract Referral{
    using SafeMath for uint256;

    uint256 private constant _referralPercent = 10;
    mapping(address => uint256) internal _referralCommission;
    mapping(address => uint256) private _commissionPaid;
    mapping(address => address) private _parent;

    /**
     * Event for register new account
     * @param beneficiary who got the tokens
     * @param referrer Refer purchaser to purchase token
     */
    event Register(address indexed beneficiary, address referrer);

    /**
     * Event for token purchase logging
     * @param beneficiary who got the tokens
     * @param value weis paid for purchase
     */
    event CommissionPaid(address indexed beneficiary, uint256 value);

    constructor(){

    }

    /**
     * @dev return amount of referral percent.
     */
    function referralPercent() public view returns (uint256) {
        return _referralPercent;
    }
    
    /**
     * @dev return amount of referral commission.
     */
    function referralCommission(address account) public view returns (uint256) {
        return _referralCommission[account];
    }
    
    /**
     * @dev return amount of referral commission.
     */
    function commissionPaid(address account) public view returns (uint256) {
        return _commissionPaid[account];
    }

    /**
     * @dev Getter the address of parent participant.
     */
    function parent(address account) public view returns (address) {
        return _parent[account];
    }

    /**
     * @dev Getter the address of parent participant.
     */
    function withdrawReferralCommission() public {
        require(referralCommission(msg.sender) > 0, "Your Commission must be greater than zero");
        uint256 value = _referralCommission[msg.sender];
        _referralCommission[msg.sender] = 0;
        _commissionPaid[msg.sender] = _commissionPaid[msg.sender].add(value);
        payable(msg.sender).transfer(value);
        emit CommissionPaid(msg.sender, value);
    }
    
    /**
     * @dev check referrer account for purchase
     * @param beneficiary Recipient of the token purchase
     * @param referrer Refer purchaser to purchase token
     */
    function _preValidateReferrer(address beneficiary, address referrer) internal view {
        require(referrer != beneficiary, "Beneficiary can't refer to self");
        require(parent(beneficiary) == address(0) || parent(beneficiary) == referrer, "Invalid referrer");
    }
    
    /**
     * @dev update referrer account for purchase
     * @param beneficiary Recipient of the token purchase
     * @param referrer Refer purchaser to purchase token
     */
    function _updateReferral(address beneficiary, address referrer) virtual internal {
        if (parent(beneficiary) == address(0)){
            _parent[beneficiary] = referrer;
            emit Register(beneficiary, referrer);
        }
    }
}

/**
 * @title CLDSale_V2
 * @dev The CLDSale enables the purchasing of CLD token at rates determined by the current block time.
 *      It requires the crowdsale contract address be given an allowance of 14000000 CLD enabling it to distribute the purchased tokens.
 */
contract CLDSale_V2 is AllowanceCrowdsale, Referral{
    using SafeMath for uint256;

    /**
     * @dev Constructor, calls the inherited classes constructors
     * @param rate Number of token units a buyer gets per wei
     * @param landToken The landToken address, must be an ERC20 contract
     * @param landTokensOwner Address holding the tokens, which has approved allowance to the crowdsale
     * @param fundWallet Address that will receive the deposited fund
     */
    constructor(uint256 rate, IERC20 landToken, address landTokensOwner, address payable fundWallet)
        Crowdsale(rate, fundWallet, landToken)
        AllowanceCrowdsale(landTokensOwner)
        public
    {
    }

     /**
     * @dev This function to purchase
     * @param beneficiary Recipient of the token purchase
     */
    function buyTokens(address beneficiary) public override payable {
        super.buyTokens(beneficiary);
        wallet().transfer(msg.value.mul(10).div(100)); // transfer referral Commission to wallet
    }

    
     /**
     * @dev This function to purchase via reffral account
     * @param beneficiary Recipient of the token purchase
     * @param referrer Refer purchaser to purchase token
     */
    function buyTokensWithRefer(address beneficiary, address referrer) public payable {
        _preValidateReferrer(beneficiary, referrer);
        super.buyTokens(beneficiary);
        _updateReferral(beneficiary, referrer);
        _referralCommission[referrer] = _referralCommission[referrer].add(msg.value.mul(referralPercent()).div(100));
    }

    /**
     * @dev Overrides function in the Crowdsale contract to enable a custom phased distribution
     * @param weiAmount Value in wei to be converted into tokens
     * @return Number of tokens that can be purchased with the specified weiAmount
     */
    function _getTokenAmount(uint256 weiAmount) override internal view returns (uint256) {
        uint256 amount = weiAmount.mul(rate());
        if (amount >= 500000 * 1e18) {
            return amount.mul(120).div(100);
        } else if (amount >= 200000 * 1e18) {
            return amount.mul(114).div(100);
        } else if (amount >= 70000 * 1e18) {
            return amount.mul(109).div(100);
        } else if (amount >= 30000 * 1e18) {
            return amount.mul(106).div(100);
        } else if (amount >= 10000 * 1e18) {
            return amount.mul(104).div(100);
        } else {
            return amount;
        }
    }

    /**
     * @dev Determines how ETH is stored/forwarded on purchases.
     */
    function _forwardFunds() override internal {
        wallet().transfer(msg.value.sub(msg.value.mul(referralPercent()).div(100)));
    }
}