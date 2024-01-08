// SPDX-License-Identifier: MIT

pragma solidity =0.8.4;

import "./RetrieveTokensFeature.sol";
import "./IERC20UpgradeableBurnable.sol";

/**
 * Contract to handle a seed sale of diversify
 */
contract SeedSaleRound is RetrieveTokensFeature {
    // The State of the seed sale
    enum State {
        Setup,
        Active,
        Refunding,
        Closed
    }

    // ERC20 basic token contract being held
    IERC20UpgradeableBurnable private _token;

    // Balance sheet of the invested weis
    mapping(address => uint256) private _balances;

    // Tracks the state of the seedsale
    State private _state;

    //  Start date of seedsale (unix timestamp)
    uint256 private _startDate;

    // the duration of the seed sale (seconds)
    uint256 private _duration;

    // beneficiary of tokens (weis) after the sale ends
    address private _beneficiary;

    // How many token units a buyer gets per wei (wei)
    uint256 private _rate;

    // Supply of seed round in momos
    uint256 private _totalSupply;

    // The total supply in wei
    uint256 private _weiTotalSupply;

    // Amount of wei raised
    uint256 private _weiRaised;

    // Amount of wei to raise
    uint256 private _weiGoal;

    // Min investment limit per transaction (wei)
    uint256 private _weiMinTransactionLimit;

    // Max investment limit for investor, zero(0) for unlimited (wei)
    uint256 private _weiMaxInvestmentLimit;

    // Locking period of tokens if sale was successful (seconds)
    uint256 private _lockingPeriod;

    /*
     * Event seedsale announced
     * @param startDate when the sales start
     * @param rate How many token units a buyer gets per wei
     * @param weiGoal amount of wei to reach for success
     * @param weiMinTransactionLimit min investment limit per transaction
     * @param weiMaxInvestmentLimit max investment limit for investor
     * @param totalSupply of momos in the round
     * @param duration the duration of the seed sale in seconds
     * @param lockingPeriod Locking period of tokens in seconds if sale was successful
     */
    event Setup(
        uint256 startDate,
        uint256 rate,
        uint256 weiGoal,
        uint256 weiMinTransactionLimit,
        uint256 weiMaxInvestmentLimit,
        uint256 totalSupply,
        uint256 duration,
        uint256 lockingPeriod
    );

    /*
     * Event for seedsale closed logging
     */
    event Closed();

    /*
     * Event for refunds enabled
     */
    event RefundsEnabled();

    /*
     * Event for logging the refund
     * @param beneficiary who get the refund
     * @param weiAmount weis refunded
     */
    event Refunded(address indexed beneficiary, uint256 weiAmount);

    /*
     * Event for token purchase logging
     * @param purchaser who paid for the tokens
     * @param value weis paid for purchase
     * @param amount amount of tokens purchased
     */
    event TokenPurchased(address indexed purchaser, uint256 value, uint256 amount);

    /**
     * Create a new instance of the seed sale
     */
    constructor() {
        _state = State.Setup;
    }

    /**
     * @return the state of the sales round
     */
    function state() public view returns (State) {
        return _state;
    }

    /**
     * @return the token being held.
     */
    function token() public view returns (IERC20UpgradeableBurnable) {
        return _token;
    }

    /**
     * @return  the start date of seedsale (unix timestamp)
     */
    function startDate() public view returns (uint256) {
        return _startDate;
    }

    /**
     * @return  the duration of seedsale (seconds)
     */
    function duration() public view returns (uint256) {
        return _duration;
    }

    /**
     * @return the beneficiary of the tokens.
     */
    function beneficiary() public view returns (address) {
        return _beneficiary;
    }

    /**
     * @return the rate how many momos one get per gwei
     */
    function rate() public view returns (uint256) {
        return _rate;
    }

    /**
     * @return  Supply of seed round in momos
     */
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @return the total supply in wei
     */
    function weiTotalSupply() public view returns (uint256) {
        return _weiTotalSupply;
    }

    /**
     * @return the amount of wei raised
     */
    function weiRaised() public view returns (uint256) {
        return _weiRaised;
    }

    /**
     * @return the wei min transaction limit
     */
    function weiMinTransactionLimit() public view returns (uint256) {
        return _weiMinTransactionLimit;
    }

    /**
     * @return the wei Max Investment Limit
     */
    function weiMaxInvestmentLimit() public view returns (uint256) {
        return _weiMaxInvestmentLimit;
    }

    /**
     * @return the locking period time in seconds
     */
    function lockingPeriod() public view returns (uint256) {
        return _lockingPeriod;
    }

    /**
     * @return the goal of wei to raise
     */
    function weiGoal() public view returns (uint256) {
        return _weiGoal;
    }

    /**
     * @return the balance of momos for the given address
     */
    function balanceOf(address address_) public view returns (uint256) {
        return _getMomoAmount(_balances[address_]);
    }

    /**
     * @dev setup the sale
     * @param beneficiary_ beneficiary of tokens (weis) after the sale ends
     * @param startDate_ The date in a unix timestamp when the seedsale starts
     * @param duration_ the duration of the seed sale in seconds
     * @param lockingPeriod_ Locking period of tokens in seconds if sale was successful
     * @param rate_ How many momos a buyer gets per wei
     * @param weiGoal_ The goal in wei to reach for round success
     * @param weiMinTransactionLimit_ Min investment limit per transaction
     * @param weiMaxInvestmentLimit_  Max investment limit per investor, zero for unlimited
     * @param token_ The div token
     */

    function setup(
        address beneficiary_,
        uint256 startDate_,
        uint256 duration_,
        uint256 lockingPeriod_,
        uint256 rate_,
        uint256 weiGoal_,
        uint256 weiMinTransactionLimit_,
        uint256 weiMaxInvestmentLimit_,
        IERC20UpgradeableBurnable token_
    ) public onlyOwner {
        require(_state == State.Setup, 'Seed already started');
        require(beneficiary_ != address(0), 'Beneficary not specified');
        require(duration_ > 0, 'Duration needs to be bigger than 0');
        require(address(token_) != address(0), 'Token must be set');
        require(token_.balanceOf(address(this)) > 0, 'Seedsale has no amount for the given token');
        require(rate_ > 0, 'Rate needs to be bigger than 0');
        require(weiGoal_ > 0, 'Goal needs to be bigger than 0');

        _beneficiary = beneficiary_;
        _duration = duration_;
        _lockingPeriod = lockingPeriod_;
        _token = token_;
        _rate = rate_;
        _startDate = startDate_;
        _totalSupply = _token.balanceOf(address(this));
        _weiTotalSupply = _totalSupply / _rate;
        _weiGoal = weiGoal_;
        _weiMinTransactionLimit = weiMinTransactionLimit_;
        _weiMaxInvestmentLimit = weiMaxInvestmentLimit_;
        _state = State.Active;

        emit Setup(
            _startDate,
            _rate,
            _weiGoal,
            _weiMinTransactionLimit,
            _weiMaxInvestmentLimit,
            _totalSupply,
            _duration,
            _lockingPeriod
        );
    }

    /**
     * @dev token purchase
     */
    function buyTokens() public payable {
        require(_state != State.Setup, 'SeedSale not ready');
        require(block.timestamp > _startDate, 'SeedSale not started');

        require(_state == State.Active, 'SeedSale not active');
        require(block.timestamp < _startDate + _duration, 'End duration reached');
        require(_msgSender() != address(0), 'Address 0 as sender is not allowed');

        uint256 weiAmount = msg.value;
        require(weiAmount != 0, 'Wei amount cant be zero');

        // limit the minimum amount for one transaction (WEI)
        require(weiAmount >= _weiMinTransactionLimit, 'Transaction doesnt reach minTransactionLimit');
        require(_weiRaised + weiAmount <= _weiTotalSupply, 'Transaction overeaches totalSupply');

        // limit the maximum amount that one user can spend during sale (WEI),
        // if initalized with 0, we allow unlimited
        if (_weiMaxInvestmentLimit > 0) {
            uint256 maxAllowableValue = _weiMaxInvestmentLimit - _balances[_msgSender()];
            require(weiAmount <= maxAllowableValue, 'Transaction exceeds investment limit!');
        }

        // calculate token amount for event
        uint256 tokens = _getMomoAmount(weiAmount);

        // update state
        _weiRaised += weiAmount;

        _balances[_msgSender()] = _balances[_msgSender()] + msg.value;
        emit TokenPurchased(_msgSender(), weiAmount, tokens);
    }

    /**
     * Closes the sale, when enduration reached
     */
    function close() public onlyOwner {
        require(_state == State.Active, 'Seedsale needs to be active state');
        require(block.timestamp >= _startDate + _duration, 'End duration not reached');

        if (_weiRaised >= _weiGoal) {
            _state = State.Closed;
            emit Closed();
            retrieveETH(payable(beneficiary()));
            // Burn remaining tokens
            uint256 momosSold = _getMomoAmount(_weiRaised);
            _token.burn(totalSupply() - momosSold);
        } else {
            _state = State.Refunding;
            emit RefundsEnabled();
        }
    }

    /**
     * @dev Investors can claim refunds here if crowdsale is unsuccessful
     */
    function claimRefund(address payable investor) public {
        require(_state == State.Refunding, 'Refunding disabled');
        uint256 balanceValue = _balances[investor];
        _balances[investor] = 0;
        investor.transfer(balanceValue);
        emit Refunded(investor, balanceValue);
    }

    /**
     * @dev payout the freezed amount of token
     */
    function retrieveFreezedTokens() public {
        require(_state == State.Closed, 'Sale not closed');
        require(block.timestamp >= (_startDate + _duration + _lockingPeriod), 'Seed locking period not ended');
        uint256 momoAmount = _getMomoAmount(_balances[_msgSender()]);
        _balances[_msgSender()] = 0;
        _token.transfer(_msgSender(), momoAmount);
    }

    /**
     * @dev retrieve wrongly assigned tokens
     */
    function retrieveTokens(address to, address anotherToken) public override onlyOwner {
        require(address(_token) != anotherToken, 'You should only use this method to withdraw extraneous tokens.');
        require(to == beneficiary(), 'You can only transfer tokens to the beneficiary');
        super.retrieveTokens(to, anotherToken);
    }

    /**
     * @dev retrieve wrongly assigned tokens
     */
    function retrieveETH(address payable to) public override onlyOwner {
        require(_state == State.Closed, 'Only allowed when closed');
        require(to == beneficiary(), 'You can only transfer tokens to the beneficiary');
        super.retrieveETH(to);
    }

    /**
     * @param _weiAmount Value in wei to momos
     * @return Number of token (momo's) one receives for the _weiAmount
     */
    function _getMomoAmount(uint256 _weiAmount) internal view returns (uint256) {
        return _weiAmount * rate();
    }
}
