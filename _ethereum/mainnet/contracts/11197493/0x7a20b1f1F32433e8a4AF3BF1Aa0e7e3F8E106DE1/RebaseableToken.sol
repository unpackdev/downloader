pragma solidity ^0.6.0;

import "./Ownable.sol";
import "./SafeMath.sol";
import "./IERC20Nameable.sol";
import "./SafeMathInt.sol";
// import "./console.sol";

/**

Heavily based on ampleforth with updates to 0.6.0 solidity and percentage change andjustments

 */
/**
 * @title uFragments ERC20 token
 * @dev This is part of an implementation of the uFragments Ideal Money protocol.
 *      uFragments is a normal ERC20 token, but its supply can be adjusted by splitting and
 *      combining tokens proportionally across all wallets.
 *
 *      uFragment balances are internally represented with a hidden denomination, 'gons'.
 *      We support splitting the currency in expansion and combining the currency on contraction by
 *      changing the exchange rate between the hidden 'gons' and the public 'fragments'.
 */
contract RebaseableToken is IERC20Nameable, Ownable {
    // PLEASE READ BEFORE CHANGING ANY ACCOUNTING OR MATH
    // Anytime there is division, there is a risk of numerical instability from rounding errors. In
    // order to minimize this risk, we adhere to the following guidelines:
    // 1) The conversion rate adopted is the number of gons that equals 1 fragment.
    //    The inverse rate must not be used--TOTAL_GONS is always the numerator and _totalSupply is
    //    always the denominator. (i.e. If you want to convert gons to fragments instead of
    //    multiplying by the inverse rate, you should divide by the normal rate)
    // 2) Gon balances converted into Fragments are always rounded down (truncated).
    //
    // We make the following guarantees:
    // - If address 'A' transfers x Fragments to address 'B'. A's resulting external balance will
    //   be decreased by precisely x Fragments, and B's external balance will be precisely
    //   increased by x Fragments.
    //
    // We do not guarantee that the sum of all balances equals the result of calling totalSupply().
    // This is because, for any conversion function 'f()' that has non-zero rounding error,
    // f(x0) + f(x1) + ... + f(xn) is not always equal to f(x0 + x1 + ... xn).
    using SafeMath for uint256;
    using SafeMathInt for int256;

    event LogRebase(uint256 indexed epoch, uint256 totalSupply);

    modifier validRecipient(address to) {
        require(to != address(0x0));
        require(to != address(this));
        require(settledAt[to] == 0);
        _;
    }

    modifier notSettling(address addr) {
        require(settledAt[addr] == 0);
        _;
    }

    string private _name;
    string private _symbol;
    uint8 private _decimals = 18;

    uint256 private constant MAX_UINT256 = ~uint256(0);

    uint256 private constant MAX_SUPPLY = ~uint128(0);  // (2^128) - 1

    uint256 private _totalSupply;
    uint256 private _totalGons;
    uint256 public _gonsPerFragment = 10**24;

    // when _totalSupply goes to zero we reset all balances to zero (ignoring old balances)
    // this is an optimization as otherwise the _gonsPerFragment gets out of hand
    // and we have multiplication overflow errors on deposit.
    mapping(uint256 => mapping(address => uint256)) private _gonBalances;
    uint256 private _currentBalances = 0;

    uint256 public epoch = 1;

    // This is denominated in Fragments, because the gons-fragments conversion might change before
    // it's fully paid.
    mapping (address => mapping (address => uint256)) private _allowedFragments;

    // When the users account was locked for a settlement
    // this is the epoch + 1 to handle the epoch 0 case.
    mapping (address => uint256) public settledAt;

    /**
     * @dev Notifies Fragments contract about a new rebase cycle.
     * @param supplyDelta The number of new fragment tokens to add into circulation via expansion.
     * @return The total number of fragments after the supply adjustment.
     */
    function rebase(uint256 epoch_, int256 supplyDelta)
        external
        onlyOwner
        returns (uint256)
    {

        // console.log(symbol(), ": starting total supply ",  epoch, _totalSupply.div(10**18));
        // console.log("gonsPerFragment: ", epoch, _gonsPerFragment);

        epoch = epoch_;

        if (supplyDelta == 0) {
            emit LogRebase(epoch, _totalSupply);
            return _totalSupply;
        }

        if (supplyDelta < 0) {
            // console.log(symbol(), ": supply delta / _totalSupply -", uint256(supplyDelta.abs()), _totalSupply);
            _totalSupply = _totalSupply.sub(uint256(supplyDelta.abs()));
        } else {
            // console.log(symbol(), ": supply delta +", uint256(supplyDelta.abs()));
            _totalSupply = _totalSupply.add(uint256(supplyDelta));
        }

        if (_totalSupply > MAX_SUPPLY) {
            _totalSupply = MAX_SUPPLY;
        }

        if (_totalSupply > 0) {
            _gonsPerFragment = _totalGons.div(_totalSupply);

            if (_gonsPerFragment == 0) {
                _gonsPerFragment = 10**24; //TODO: is this right?
            }
        } else if (_totalGons > 0) {
            _currentBalances++;
            _gonsPerFragment = 10**24;
            _totalGons = 0;
        }

        emit LogRebase(epoch, _totalSupply);
        return _totalSupply;
    }

    function mint(address who, uint256 value)
        public
        onlyOwner
        notSettling(who)
        returns (bool)
    {
        _totalSupply = _totalSupply.add(value);
        uint256 gonValue = value.mul(_gonsPerFragment);
        _gonBalances[_currentBalances][who] = _gonBalances[_currentBalances][who].add(gonValue);
        _totalGons = _totalGons.add(gonValue);
        return true;
    }

    function liquidate(address who) public onlyOwner returns (bool) {
        // console.log("settling", epoch, settledAt[who]);
        require(epoch > settledAt[who]);

        uint256 gonValue = _gonBalances[_currentBalances][who];
        _gonBalances[_currentBalances][who] = 0;
        uint256 bal = gonValue.div(_gonsPerFragment);
        // console.log(symbol(), "burn", who);
        // console.log("-", bal, gonValue, _totalSupply);

        _totalGons = _totalGons.sub(gonValue);
        if (_totalSupply > bal) {
            _totalSupply = _totalSupply.sub(bal);
        } else {
            _totalSupply = 0;
        }

        delete settledAt[who];
        return true;
    }

    function settle(address who)
        public
        onlyOwner
        notSettling(who)
        returns (bool)
    {
        // console.log(symbol(), "settling: ", who);
        settledAt[who] = epoch;
        return true;
    }

    function initialize(string memory name, string memory symbol, address operator_) onlyOwner public {
        setName(name);
        setSymbol(symbol);

        uint256 balance = _gonBalances[_currentBalances][owner()];
        _gonBalances[_currentBalances][owner()] = 0;
        _gonBalances[_currentBalances][operator_] = _gonBalances[_currentBalances][operator_].add(balance);

        transferOwnership(operator_);
    }

    constructor() Ownable() public {
        _totalSupply = 0;
    }

    function setName(string memory name) public {
        _name = name;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view override returns (string memory) {
        return _name;
    }

    function setSymbol(string memory symbol) public {
        _symbol = symbol;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view override returns (uint8) {
        return _decimals;
    }

    /**
     * @return The total number of fragments.
     */
    function totalSupply()
        public
        view
        override
        returns (uint256)
    {
        return _totalSupply;
    }

    /**
     * @param who The address to query.
     * @return The balance of the specified address.
     */
    function balanceOf(address who)
        public
        view
        override
        returns (uint256)
    {

        return _gonBalances[_currentBalances][who].div(_gonsPerFragment);
    }

    /**
     * @dev Transfer tokens to a specified address.
     * @param to The address to transfer to.
     * @param value The amount to be transferred.
     * @return True on success, false otherwise.
     */
    function transfer(address to, uint256 value)
        public
        override
        validRecipient(to)
        returns (bool)
    {
        uint256 gonValue = value.mul(_gonsPerFragment);
        _gonBalances[_currentBalances][msg.sender] = _gonBalances[_currentBalances][msg.sender].sub(gonValue);
        _gonBalances[_currentBalances][to] = _gonBalances[_currentBalances][to].add(gonValue);
        emit Transfer(msg.sender, to, value);
        // console.log("transfer", symbol(), msg.sender);
        // console.log(to, value.div(10**18));
        return true;
    }

    /**
     * @dev Function to check the amount of tokens that an owner has allowed to a spender.
     * @param owner_ The address which owns the funds.
     * @param spender The address which will spend the funds.
     * @return The number of tokens still available for the spender.
     */
    function allowance(address owner_, address spender)
        public
        view
        override
        returns (uint256)
    {
        return _allowedFragments[owner_][spender];
    }

    /**
     * @dev Transfer tokens from one address to another.
     * @param from The address you want to send tokens from.
     * @param to The address you want to transfer to.
     * @param value The amount of tokens to be transferred.
     */
    function transferFrom(address from, address to, uint256 value)
        public
        validRecipient(to)
        notSettling(from)
        override
        returns (bool)
    {
        _allowedFragments[from][msg.sender] = _allowedFragments[from][msg.sender].sub(value);
        return _transferFrom(from, to, value);
    }
    
    function _transferFrom(address from, address to, uint256 value)
        private
        returns (bool)
    {
        uint256 gonValue = value.mul(_gonsPerFragment);
        _gonBalances[_currentBalances][from] = _gonBalances[_currentBalances][from].sub(gonValue);
        _gonBalances[_currentBalances][to] = _gonBalances[_currentBalances][to].add(gonValue);
        emit Transfer(from, to, value);

        return true;
    }

    /**
     * @dev Approve the passed address to spend the specified amount of tokens on behalf of
     * msg.sender. This method is included for ERC20 compatibility.
     * increaseAllowance and decreaseAllowance should be used instead.
     * Changing an allowance with this method brings the risk that someone may transfer both
     * the old and the new allowance - if they are both greater than zero - if a transfer
     * transaction is mined before the later approve() call is mined.
     *
     * @param spender The address which will spend the funds.
     * @param value The amount of tokens to be spent.
     */
    function approve(address spender, uint256 value)
        public
        override
        returns (bool)
    {
        _allowedFragments[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    /**
     * @dev Increase the amount of tokens that an owner has allowed to a spender.
     * This method should be used instead of approve() to avoid the double approval vulnerability
     * described above.
     * @param spender The address which will spend the funds.
     * @param addedValue The amount of tokens to increase the allowance by.
     */
    function increaseAllowance(address spender, uint256 addedValue)
        public
        returns (bool)
    {
        _allowedFragments[msg.sender][spender] =
            _allowedFragments[msg.sender][spender].add(addedValue);
        emit Approval(msg.sender, spender, _allowedFragments[msg.sender][spender]);
        return true;
    }

    /**
     * @dev Decrease the amount of tokens that an owner has allowed to a spender.
     *
     * @param spender The address which will spend the funds.
     * @param subtractedValue The amount of tokens to decrease the allowance by.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        returns (bool)
    {
        uint256 oldValue = _allowedFragments[msg.sender][spender];
        if (subtractedValue >= oldValue) {
            _allowedFragments[msg.sender][spender] = 0;
        } else {
            _allowedFragments[msg.sender][spender] = oldValue.sub(subtractedValue);
        }
        emit Approval(msg.sender, spender, _allowedFragments[msg.sender][spender]);
        return true;
    }
}
