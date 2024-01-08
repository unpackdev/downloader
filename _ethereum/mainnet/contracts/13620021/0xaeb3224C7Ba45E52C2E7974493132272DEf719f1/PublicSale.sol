pragma solidity >=0.8.0 <0.9.0;
//SPDX-License-Identifier: MIT
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./ReentrancyGuard.sol";
import "./Pausable.sol";

contract PublicSale is Ownable, ReentrancyGuard, Pausable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    mapping(address => uint256) private _contributions;
    uint256 private _individualMaxCap;
    uint256 private _individualMinCap;
    uint256 private _openingTime;

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
    event TokensPurchased(
        address indexed purchaser,
        address indexed beneficiary,
        uint256 value,
        uint256 amount
    );
    constructor(
        uint256 pRate,
        address payable pWallet,
        IERC20 pToken,
        uint256 pIndividualMinCap,
        uint256 pIndividualMaxCap,
        uint256 pOpeningTime
    ) {
        require(pRate > 0, "DexGame Public Sale: rate is 0");
        require(pIndividualMaxCap > 0, "DexGame Public Sale: IndividualMaxCap is 0");
        require(pWallet != address(0), "DexGame Public Sale: wallet is the zero address");
        require(pOpeningTime >= block.timestamp, "Opening time is before current time");
        require(
            address(pToken) != address(0),
            "DexGame Public Sale: token is the zero address"
        );

        _rate = pRate;
        _wallet = pWallet;
        _token = pToken;
        _individualMinCap = pIndividualMinCap;
        _individualMaxCap = pIndividualMaxCap;
        _openingTime = pOpeningTime;
    }

    /**
     * @dev fallback function ***DO NOT OVERRIDE***
     * Note that other contracts will transfer funds with a base gas stipend
     * of 2300, which is not enough to call buyTokens. Consider calling
     * buyTokens directly when purchasing tokens from a contract.
     */
    receive() external payable {
        buyTokens();
    }

    /**
     * @return the token being sold.
     */
    function token() public view returns (IERC20) {
        return _token;
    }
    function individualMinCap() public view returns (uint256) {
        return _individualMinCap;
    }
    function individualMaxCap() public view returns (uint256) {
        return _individualMaxCap;
    }
    /**
     * @return the crowdsale opening time.
     */
    function openingTime() public view returns (uint256) {
        return _openingTime;
    }
    /**
     * @return true if the crowdsale is open, false otherwise.
     */
    function isOpen() public view returns (bool) {
        // solhint-disable-next-line not-rely-on-time
        return block.timestamp >= _openingTime;
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
     * @return the amount of wei raised.
     */
    function weiRaised() public view returns (uint256) {
        return _weiRaised;
    }

    /**
     * @dev low level token purchase ***DO NOT OVERRIDE***
     * This function has a non-reentrancy guard, so it shouldn't be called by
     * another `nonReentrant` function.
     */
    function buyTokens() public payable nonReentrant {
        uint256 weiAmount = msg.value;
        address beneficiary = _msgSender();

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
    function _preValidatePurchase(address beneficiary, uint256 weiAmount)
        internal
        view
        whenNotPaused
    {
        require(
            beneficiary != address(0),
            "DexGame Public Sale: beneficiary is the zero address"
        );
        require(isOpen(), "DexGame Public Sale: not open");
        require(weiAmount != 0, "DexGame Public Sale: weiAmount is 0");
        require(
            _individualMinCap >= 0 && _individualMaxCap > 0,
            "DexGame Public Sale: individualMinCap or individualMaxCap is 0"
        );
        require(
            weiAmount >= _individualMinCap,
            "Beneficiary purchase amount must be greater than min cap"
        );
        require(
            _contributions[beneficiary].add(weiAmount) <= _individualMaxCap,
            "Beneficiary max cap exceeded"
        );

        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
    }

    /**
     * @dev Validation of an executed purchase. Observe state and use revert statements to undo rollback when valid
     * conditions are not met.
     * @param beneficiary Address performing the token purchase
     * @param weiAmount Value in wei involved in the purchase
     */
    function _postValidatePurchase(address beneficiary, uint256 weiAmount)
        internal
        view
    {
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
    function _processPurchase(address beneficiary, uint256 tokenAmount)
        internal
    {
        require(
            _token.balanceOf(address(this)) >= tokenAmount,
            "Sale max cap reached"
        );

        _deliverTokens(beneficiary, tokenAmount);
    }

    /**
     * @dev Override for extensions that require an internal state to check for validity (current user contributions,
     * etc.)
     * @param beneficiary Address receiving the tokens
     * @param weiAmount Value in wei involved in the purchase
     */
    function _updatePurchasingState(address beneficiary, uint256 weiAmount)
        internal
    {
        _contributions[beneficiary] = _contributions[beneficiary].add(weiAmount);
    }

    /**
     * @dev Override to extend the way in which ether is converted to tokens.
     * @param weiAmount Value in wei to be converted into tokens
     * @return Number of tokens that can be purchased with the specified _weiAmount
     */
    function _getTokenAmount(uint256 weiAmount)
        internal
        view
        returns (uint256)
    {
        return weiAmount.mul(_rate);
    }

    /**
     * @dev Determines how ETH is stored/forwarded on purchases.
     */
    function _forwardFunds() internal {
        _wallet.transfer(msg.value);
    }

    /**
     * @dev Returns the amount contributed so far by a specific beneficiary.
     * @param beneficiary Address of contributor
     * @return Beneficiary contribution so far
     */
    function getContribution(address beneficiary)
        public
        view
        returns (uint256)
    {
        return _contributions[beneficiary];
    }

    /**
     * @dev Sets a specific Beneficiary maximum contribution.
     * @param minCap Min Wei limit for individual contribution
     * @param maxCap Max Wei limit for individual contribution
     */
    function setIndividualCap(uint256 minCap, uint256 maxCap)
        external
        onlyOwner
    {
        _individualMinCap = minCap;
        _individualMaxCap = maxCap;
    }

    function pause() public virtual onlyOwner {
        _pause();
    }

    function unpause() public virtual onlyOwner {
        _unpause();
    }

    function endSale() public virtual onlyOwner {
        _token.safeTransfer(owner(), _token.balanceOf(address(this)));
        pause();
    }
    function updateRate(uint256 pRate) public virtual onlyOwner {
        _rate = pRate;
    }
}
