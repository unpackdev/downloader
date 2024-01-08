// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./SafeMath.sol";
import "./Official_BuffDoge.sol";

/**
 * @notice ERC20 token PreSale contract
 */
contract PreSaleBuff is Ownable {
    using SafeMath for uint256;

    Official_BuffDoge private _buffToken;

    // Address where funds are collected
    address payable public _wallet;

    // How many token units a buyer gets per wei
    uint256 public _rate;

    // Amount of wei raised
    uint256 public _weiRaised;

    // Amount of token released
    uint256 public _tokenReleased;

    bool private _paused;

    mapping ( address => uint256) private _tokenPurchased;

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
    constructor (address payable buffToken, uint rate, address payable wallet) {
        require(rate > 0);
        require(wallet != address(0));
        require(buffToken != address(0));
        _buffToken = Official_BuffDoge(buffToken);
        _rate = rate;
        _wallet = wallet;
        _paused = true;
    }

    modifier isNotPaused() {
        require(_paused == false, "ERR: paused already");
        _;
    }

    function pausedEnable() external onlyOwner returns (bool) {
        require(_paused == false, "ERR: already pause enabled");
        _paused = true;
        return true;
    }

    function pausedNotEnable() external onlyOwner returns (bool) {
        require(_paused == true, "ERR: already pause disabled");
        _paused = false;
        return true;
    }

    receive() external payable {
        buyTokens(msg.sender);
    }

    function buyTokens(address _beneficiary) public payable isNotPaused {
        uint256 weiAmount = msg.value;
        _preValidatePurchase(_beneficiary, weiAmount);

        // calculate token amount to be created
        uint256 tokens = _getTokenAmount(weiAmount);

        // update state
        _weiRaised = _weiRaised.add(weiAmount);

        _processPurchase(_beneficiary, tokens);
        emit TokenPurchase(
            msg.sender,
            _beneficiary,
            weiAmount,
            tokens
        );

        _updatePurchasingState(_beneficiary);

        _forwardFunds();
    }

    function _preValidatePurchase(
        address _beneficiary,
        uint256 _weiAmount
    )
        internal
    {
        require(_beneficiary != address(0));
        require(_weiAmount != 0);
        require(_weiAmount <= 1 ether, 'ERR: Exceed presale plan ETH');
        require(_weiAmount >= 0.1 ether, 'ERR: So less presale plan ETH');
        uint256 tokenBalance = _buffToken.balanceOf(address(this));
        uint256 tokens = _getTokenAmount(_weiAmount);
        require(tokens <= tokenBalance, 'ERR: Exceed presale plan');
        require(_tokenPurchased[_beneficiary].add(tokens) <= 1e7 ether, 'ERR: Exceed presale plan Buff');
        _buffToken.timeLockReleaseForPresale(_beneficiary);
    }

    function _deliverTokens(
        address _beneficiary,
        uint256 _tokenAmount
    )
        internal
    {
        _buffToken.transfer(_beneficiary, _tokenAmount);
        _tokenReleased = _tokenReleased.add(_tokenAmount);
        _tokenPurchased[_beneficiary] = _tokenPurchased[_beneficiary].add(_tokenAmount);
    }

    function _processPurchase(
        address _beneficiary,
        uint256 _tokenAmount
    )
        internal
    {
        _deliverTokens(_beneficiary, _tokenAmount);
    }

    function _updatePurchasingState(
        address _beneficiary
    )
        internal
    {
        _buffToken.timeLockFromPresale(_beneficiary);
    }

    function _getTokenAmount(uint256 _weiAmount)
        internal view returns (uint256)
    {
        return _weiAmount.mul(_rate);
    }

    function _forwardFunds() internal {
        _wallet.transfer(msg.value);
    }

    function setRate(uint rate) public onlyOwner isNotPaused {
        require(rate > 0, 'ERR: zero rate');
        _rate = rate;
    }
}