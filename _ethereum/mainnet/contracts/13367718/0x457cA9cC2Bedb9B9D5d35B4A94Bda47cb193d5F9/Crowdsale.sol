pragma solidity ^0.5.0;

import "./Context.sol";
import "./IERC20.sol";
import "./SafeMath.sol";
import "./SafeERC20.sol";
import "./ReentrancyGuard.sol";

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
contract Crowdsale is Context, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;


    IERC20 private _token; // The token being sold
    address payable private _wallet; // Address where funds are collected
    uint256 private _rate; // How many token units a buyer gets per funding token.
    uint256 private _fundsRaised; // How many FundingTokens have been raised

//    event SetFundingAmount(address indexed purchaser, uint256 fundingAmount);
//    event SetTokenAmount(address indexed purchaser, uint256 tokenAmount);
    event BuyTokenComplete(address indexed purchaser, address indexed beneficiary, uint256 fundingAmount, uint256 numberTokensPurchased);

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
    function () external payable {
        buyTokens(_msgSender(), msg.value);
    }

    function token() public view returns (IERC20) {
        return _token;
    }

    function wallet() public view returns (address payable) {
        return _wallet;
    }

    function rate() public view returns (uint256) {
        return _rate;
    }

    function fundsRaised() public view returns (uint256) {
        return _fundsRaised;
    }

    /**
     * @dev low level token purchase ***DO NOT OVERRIDE***
     * This function has a non-reentrancy guard, so it shouldn't be called by
     * another `nonReentrant` function.
     * @param beneficiary Recipient of the token purchase
     */
    function buyTokens(address beneficiary, uint256 fundingTokenAmount) public nonReentrant {
        // How much USDC IN
        uint256 fundingAmount = _fundingAmount(fundingTokenAmount);

        // Vaidate: address is not crowdsale address
        // Vaidate: fundingAmount > 4999000000
        // Vaidate: isWhitelisted
        _preValidatePurchase(beneficiary, fundingAmount);

        // How much ECHO is purchased
        // Vaidate: remaining tokens still has enough
        uint256 numberTokensPurchased = _getTokenAmount(fundingAmount);

        // Bump fundsRaised
        _fundsRaised = _fundsRaised.add(fundingAmount);

        // Updated Balances mapping and BalancesList
         _processPurchase(beneficiary, numberTokensPurchased);

        // Does nothing
        _updatePurchasingState(beneficiary, fundingAmount);

        // Sends USDC to Multi-sig Wallet
        _forwardFunds(fundingTokenAmount);

        // Does nothing
        _postValidatePurchase(beneficiary, fundingAmount);

        // Complete
        emit BuyTokenComplete(_msgSender(), beneficiary, fundingAmount, numberTokensPurchased);
    }

    /**
    * @dev Determines the value (in Wei) included with a purchase.
    */
    function _fundingAmount(uint256 fundingTokenAmount) internal returns (uint256) {
//        emit SetFundingAmount(_msgSender(), msg.value);
        return msg.value;
    }

    function _preValidatePurchase(address beneficiary, uint256 fundingAmount) internal view {
        require(beneficiary != address(0), "Crowdsale: beneficiary is the zero address");
        require(fundingAmount != 0, "Crowdsale: Amount is 0");
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
    }

    /**
     * @dev Validation of an executed purchase. Observe state and use revert statements to undo rollback when valid
     * conditions are not met.
     * @param beneficiary Address performing the token purchase
     * @param fundingAmount Value involved in the purchase
     */
    function _postValidatePurchase(address beneficiary, uint256 fundingAmount) internal view {
        // solhint-disable-previous-line no-empty-blocks
    }

    /**
     * @dev Source of tokens. Override this method to modify the way in which the crowdsale ultimately gets and sends
     * its tokens.
     * @param beneficiary Address performing the token purchase
     * @param tokenAmount Number of tokens to be emitted
     */
    function _deliverTokens(address beneficiary, uint256 tokenAmount) internal {
        _token.safeTransfer(beneficiary, tokenAmount);
    }

    /**
     * @dev Executed when a purchase has been validated and is ready to be executed. Doesn't necessarily emit/send
     * tokens.
     * @param beneficiary Address receiving the tokens
     * @param tokenAmount Number of tokens to be purchased
     */
    function _processPurchase(address beneficiary, uint256 tokenAmount) internal {
        // Not Delivering Tokens - this will be vested and batched.
        // _deliverTokens(beneficiary, tokenAmount);
    }

    /**
     * @dev Override for extensions that require an internal state to check for validity (current user contributions,
     * etc.)
     * @param beneficiary Address receiving the tokens
     * @param fundingAmount Value involved in the purchase
     */
    function _updatePurchasingState(address beneficiary, uint256 fundingAmount) internal {
        // solhint-disable-previous-line no-empty-blocks
    }

    /**
     * @dev Override to extend the way in which ether is converted to tokens.
     * @param fundingAmount Value to be converted into tokens
     * @return Number of tokens that can be purchased with the specified _fundingAmount
     */
    function _getTokenAmount(uint256 fundingAmount) internal view returns (uint256) {
        // USDC has 6 decimal places, ECHO has 18 decimal places,
        // Adding 12 extra 0's to compensate for the missing decimals.
//        emit SetTokenAmount(_msgSender(), fundingAmount.mul(1000000000000).mul(100).div(_rate));
        return fundingAmount.mul(1000000000000).mul(100).div(_rate);
    }

    /**
     * @dev Determines how ETH is stored/forwarded on purchases.
     */
    function _forwardFunds(uint256 fundingTokenAmount) internal {
        _wallet.transfer(msg.value);
        //        (bool success, ) = _wallet.call.value(msg.value)("");
//        require(success, "Failed to forward funds");
    }
}
