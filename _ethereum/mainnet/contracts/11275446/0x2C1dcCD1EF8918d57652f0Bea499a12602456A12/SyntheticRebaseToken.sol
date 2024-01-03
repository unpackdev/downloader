pragma solidity ^0.6.0;

import "./Ownable.sol";
import "./SafeMath.sol";
import "./SafeERC20.sol";
import "./IERC20Nameable.sol";
import "./IMinimalUniswap.sol";
import "./IStatisticProvider.sol";

// import "./console.sol";

/**
 * @title SelfRebasingToken ERC20 token
 * @dev This is part of an implementation of the uFragments Ideal Money protocol.
 *      uFragments is a normal ERC20 token, but its supply can be adjusted by splitting and
 *      combining tokens proportionally across all wallets.
 *
 *      uFragment balances are internally represented with a hidden denomination, 'gons'.
 *      We support splitting the currency in expansion and combining the currency on contraction by
 *      changing the exchange rate between the hidden 'gons' and the public 'fragments'.
 */
contract SyntheticRebaseToken is IERC20Nameable, Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    event LogRebase(uint256 totalSupply);

    string private _name;
    string private _symbol;
    uint8 private constant DECIMALS = 18;

    // this is similar to GONS in the ampleforth code
    uint256 private _totalGons;

    uint256 public _gonsPerFragment = 10**24;
    mapping(address => uint256) private _gonBalances;

    // This is denominated in Fragments, because the gons-fragments conversion might change before
    // it's fully paid.
    mapping(address => mapping(address => uint256)) private _allowedFragments;

    IStatisticProvider public statProvider;
    uint256 public currentStat;
    int8 multiplier;

    address public pairAddress;
    IERC20 public perpetualContract;

    modifier validRecipient(address to) {
        require(to != address(0x0));
        require(to != address(this));
        _;
    }

    modifier adjustFactor() {
        // console.log("adjusting");
        checkForRebase();
        _;
    }

    constructor() public Ownable() {}

    function initialize(
        address owner_,
        uint cap,
        string memory symbol,
        string memory name,
        address statProvider_,
        int8 multiplier_
    ) public onlyOwner {
        setName(name);
        setSymbol(symbol);
        transferOwnership(owner_);
        _mint(owner_, cap);
        statProvider = IStatisticProvider(statProvider_);
        currentStat = statProvider.current();
        multiplier = multiplier_;
    }

    function setName(string memory name) public {
        _name = name;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public override view returns (string memory) {
        return _name;
    }

    function setSymbol(string memory symbol) public {
        _symbol = symbol;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public override view returns (string memory) {
        return _symbol;
    }

    function decimals() public override view returns (uint8) {
        return DECIMALS;
    }

    function setPairAddress(address addr_) public onlyOwner {
        pairAddress = addr_;
    }

    function setPerpetualAddress(address addr_) public onlyOwner {
        perpetualContract = IERC20(addr_);
    }

    function transferOwnershipWithBalance(address newOwner) public onlyOwner {
        uint gonBalance = _gonBalances[msg.sender];
        delete _gonBalances[msg.sender];
        _gonBalances[newOwner] = _gonBalances[newOwner].add(gonBalance);

        emit Transfer(msg.sender, newOwner, gonBalance.div(_gonsPerFragment));
    }

    /**
     * @return The total number of fragments.
     */
    function totalSupply() public override view returns (uint256) {
        return _totalGons.div(_gonsPerFragment);
    }

    /**
     * @param who The address to query.
     * @return The balance of the specified address.
     */
    function balanceOf(address who) public override view returns (uint256) {
        return _gonBalances[who].div(_gonsPerFragment);
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
        adjustFactor
        returns (bool)
    {
        // console.log("transfer", msg.sender, to, value);
        uint256 gonValue = value.mul(_gonsPerFragment);
        _gonBalances[msg.sender] = _gonBalances[msg.sender].sub(gonValue);
        _gonBalances[to] = _gonBalances[to].add(gonValue);
        emit Transfer(msg.sender, to, value);
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
        override
        view
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
    function transferFrom(
        address from,
        address to,
        uint256 value
    ) public override validRecipient(to) adjustFactor returns (bool) {
        // console.log("transfer operator: ", value, msg.sender, _allowedFragments[from][msg.sender]);
        _allowedFragments[from][msg.sender] = _allowedFragments[from][msg.sender].sub(value);

        uint256 gonValue = value.mul(_gonsPerFragment);
        // console.log("worked, val: ", gonValue, _gonBalances[from]);

        _gonBalances[from] = _gonBalances[from].sub(gonValue);
        // console.log("sub worked");
        _gonBalances[to] = _gonBalances[to].add(gonValue);
        // console.log("Bal: ", balanceOf(to));
        emit Transfer(from, to, value);
        // console.log("true");
        return true;
    }

    // This is used to cash in a perpetual contract
    // basically it reduces everyone's supply but then
    // gives it to the minter.
    function _mintFromOthers(address who, uint256 value) 
        private
        returns (bool)
    {
        _rebase(totalSupply().sub(value));
        return _mint(who, value);
    }

    function acceptPerpetuals(uint value) public {
        perpetualContract.safeTransferFrom(msg.sender, address(this), value);
        _mintFromOthers(msg.sender, value);
    }

    // this will only allow creating if there is supply in the contract
    function createPerpetual(uint value) public {
        _burn(msg.sender, value);
        perpetualContract.safeTransfer(msg.sender, value);
    }

    function _mint(address who, uint256 value)
        private
        returns (bool)
    {
        uint256 gonValue = value.mul(_gonsPerFragment);
        _totalGons = _totalGons.add(gonValue);
        _gonBalances[who] = _gonBalances[who].add(gonValue);
        return true;
    }

    function _burn(address who, uint256 value)
        private
        returns (bool)
    {
        uint256 gonValue = value.mul(_gonsPerFragment);
        _totalGons = _totalGons.sub(gonValue);
        _gonBalances[who] = _gonBalances[who].sub(gonValue);
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
        // console.log("allowing operator: ", spender, value);

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
        _allowedFragments[msg.sender][spender] = _allowedFragments[msg
            .sender][spender]
            .add(addedValue);
        emit Approval(
            msg.sender,
            spender,
            _allowedFragments[msg.sender][spender]
        );
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
            _allowedFragments[msg.sender][spender] = oldValue.sub(
                subtractedValue
            );
        }
        emit Approval(
            msg.sender,
            spender,
            _allowedFragments[msg.sender][spender]
        );
        return true;
    }

    function percentChangeMax100(uint256 diff, uint256 base)
        internal
        pure
        returns (uint256)
    {
        if (base == 0) {
            return 0; // ignore zero price
        }
        uint256 percent = (diff * 10**18).mul(10**18).div(base.mul(10**18));
        if (percent >= 10**18) {
            percent = uint256(10**18).sub(1);
        }
        return percent;
    }

    function _rebase(uint newSupply) private {
        _gonsPerFragment = _totalGons.div(newSupply);

        emit LogRebase(totalSupply());
        if (pairAddress != address(0)) {
            IMinimalUniswapV2Pair(pairAddress).sync();
        }
    }
    
    function _newTotalSupply(uint newStat) private view returns (uint) {
        uint256 currentStat_ = currentStat;

        uint256 diff;
        if (newStat > currentStat_) {
            diff = newStat.sub(currentStat_);
        } else if (currentStat_ > newStat) {
            diff = currentStat_.sub(newStat);
        } else {
            return 0; // no change so no need to do anything
        }
        uint256 percent = percentChangeMax100(diff, currentStat_);

        uint totalSupply_ = totalSupply();
        diff = totalSupply_.mul(percent).div(10**18);

        if (newStat > currentStat_) {
            return totalSupply_.sub(diff);
        } else {
            return totalSupply_.add(diff);
        }
    }

    // TODO: lock
    function checkForRebase() public {
        uint256 newStat = statProvider.current();
        uint256 newSupply = _newTotalSupply(newStat);
        if (newSupply > 0) {
            _rebase(newSupply);
        }
        currentStat = newStat;
    }

    // TO REMOVE in the future
    function testOnlyAdminReset(
        uint newTotalSupply,
        uint newStat
    ) public onlyOwner {
        _rebase(newTotalSupply);
        currentStat = newStat;
    }

}
