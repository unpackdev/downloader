
// File: contracts/lib/UInt256Lib.sol

pragma solidity >=0.4.24;


/**
 * @title Various utilities useful for uint256.
 */
library UInt256Lib {

    uint256 private constant MAX_INT256 = ~(uint256(1) << 255);

    /**
     * @dev Safely converts a uint256 to an int256.
     */
    function toInt256Safe(uint256 a)
        internal
        pure
        returns (int256)
    {
        require(a <= MAX_INT256);
        return int256(a);
    }
}

// File: contracts/lib/SafeMathInt.sol

/*
MIT License

Copyright (c) 2018 requestnetwork

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
*/

pragma solidity >=0.4.24;


/**
 * @title SafeMathInt
 * @dev Math operations for int256 with overflow safety checks.
 */
library SafeMathInt {
    int256 private constant MIN_INT256 = int256(1) << 255;
    int256 private constant MAX_INT256 = ~(int256(1) << 255);

    /**
     * @dev Multiplies two int256 variables and fails on overflow.
     */
    function mul(int256 a, int256 b)
        internal
        pure
        returns (int256)
    {
        int256 c = a * b;

        // Detect overflow when multiplying MIN_INT256 with -1
        require(c != MIN_INT256 || (a & MIN_INT256) != (b & MIN_INT256));
        require((b == 0) || (c / b == a));
        return c;
    }

    /**
     * @dev Division of two int256 variables and fails on overflow.
     */
    function div(int256 a, int256 b)
        internal
        pure
        returns (int256)
    {
        // Prevent overflow when dividing MIN_INT256 by -1
        require(b != -1 || a != MIN_INT256);

        // Solidity already throws when dividing by 0.
        return a / b;
    }

    /**
     * @dev Subtracts two int256 variables and fails on overflow.
     */
    function sub(int256 a, int256 b)
        internal
        pure
        returns (int256)
    {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a));
        return c;
    }

    /**
     * @dev Adds two int256 variables and fails on overflow.
     */
    function add(int256 a, int256 b)
        internal
        pure
        returns (int256)
    {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a));
        return c;
    }

    /**
     * @dev Converts to absolute value, and fails on overflow.
     */
    function abs(int256 a)
        internal
        pure
        returns (int256)
    {
        require(a != MIN_INT256);
        return a < 0 ? -a : a;
    }
}

// File: contracts/interface/ISeigniorageShares.sol

pragma solidity >=0.4.24;


interface ISeigniorageShares {
    function setDividendPoints(address account, uint256 totalDividends) external returns (bool);
    function setDividendPointsEuro(address account, uint256 totalDividends) external returns (bool);

    function mintShares(address account, uint256 amount) external returns (bool);

    function lastDividendPoints(address who) external view returns (uint256);
    function lastDividendPointsEuro(address who) external view returns (uint256);
    
    function externalRawBalanceOf(address who) external view returns (uint256);
    function externalTotalSupply() external view returns (uint256);

    function deleteShare(address account, uint256 amount) external;
}

// File: openzeppelin-eth/contracts/math/SafeMath.sol

pragma solidity ^0.4.24;


/**
 * @title SafeMath
 * @dev Math operations with safety checks that revert on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, reverts on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b);

    return c;
  }

  /**
  * @dev Integer division of two numbers truncating the quotient, reverts on division by zero.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0); // Solidity only automatically asserts when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold

    return c;
  }

  /**
  * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    uint256 c = a - b;

    return c;
  }

  /**
  * @dev Adds two numbers, reverts on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);

    return c;
  }

  /**
  * @dev Divides two numbers and returns the remainder (unsigned integer modulo),
  * reverts when dividing by zero.
  */
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0);
    return a % b;
  }
}

// File: zos-lib/contracts/Initializable.sol

pragma solidity >=0.4.24 <0.6.0;


/**
 * @title Initializable
 *
 * @dev Helper contract to support initializer functions. To use it, replace
 * the constructor with a function that has the `initializer` modifier.
 * WARNING: Unlike constructors, initializer functions must be manually
 * invoked. This applies both to deploying an Initializable contract, as well
 * as extending an Initializable contract via inheritance.
 * WARNING: When used with inheritance, manual care must be taken to not invoke
 * a parent initializer twice, or ensure that all initializers are idempotent,
 * because this is not dealt with automatically as with constructors.
 */
contract Initializable {

  /**
   * @dev Indicates that the contract has been initialized.
   */
  bool private initialized;

  /**
   * @dev Indicates that the contract is in the process of being initialized.
   */
  bool private initializing;

  /**
   * @dev Modifier to use in the initializer function of a contract.
   */
  modifier initializer() {
    require(initializing || isConstructor() || !initialized, "Contract instance has already been initialized");

    bool isTopLevelCall = !initializing;
    if (isTopLevelCall) {
      initializing = true;
      initialized = true;
    }

    _;

    if (isTopLevelCall) {
      initializing = false;
    }
  }

  /// @dev Returns true if and only if the function is running in the constructor
  function isConstructor() private view returns (bool) {
    // extcodesize checks the size of the code stored in an address, and
    // address returns the current address. Since the code is still not
    // deployed when running a constructor, any checks on its code size will
    // yield zero, making it an effective way to detect if a contract is
    // under construction or not.
    uint256 cs;
    assembly { cs := extcodesize(address) }
    return cs == 0;
  }

  // Reserved storage space to allow for layout changes in the future.
  uint256[50] private ______gap;
}

// File: openzeppelin-eth/contracts/token/ERC20/IERC20.sol

pragma solidity ^0.4.24;


/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
interface IERC20 {
  function totalSupply() external view returns (uint256);

  function balanceOf(address who) external view returns (uint256);

  function allowance(address owner, address spender)
    external view returns (uint256);

  function transfer(address to, uint256 value) external returns (bool);

  function approve(address spender, uint256 value)
    external returns (bool);

  function transferFrom(address from, address to, uint256 value)
    external returns (bool);

  event Transfer(
    address indexed from,
    address indexed to,
    uint256 value
  );

  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

// File: openzeppelin-eth/contracts/token/ERC20/ERC20Detailed.sol

pragma solidity ^0.4.24;




/**
 * @title ERC20Detailed token
 * @dev The decimals are only for visualization purposes.
 * All the operations are done using the smallest and indivisible token unit,
 * just as on Ethereum all the operations are done in wei.
 */
contract ERC20Detailed is Initializable, IERC20 {
  string private _name;
  string private _symbol;
  uint8 private _decimals;

  function initialize(string name, string symbol, uint8 decimals) public initializer {
    _name = name;
    _symbol = symbol;
    _decimals = decimals;
  }

  /**
   * @return the name of the token.
   */
  function name() public view returns(string) {
    return _name;
  }

  /**
   * @return the symbol of the token.
   */
  function symbol() public view returns(string) {
    return _symbol;
  }

  /**
   * @return the number of decimals of the token.
   */
  function decimals() public view returns(uint8) {
    return _decimals;
  }

  uint256[50] private ______gap;
}

// File: openzeppelin-eth/contracts/ownership/Ownable.sol

pragma solidity ^0.4.24;


/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable is Initializable {
  address private _owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function initialize(address sender) public initializer {
    _owner = sender;
  }

  /**
   * @return the address of the owner.
   */
  function owner() public view returns(address) {
    return _owner;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(isOwner());
    _;
  }

  /**
   * @return true if `msg.sender` is the owner of the contract.
   */
  function isOwner() public view returns(bool) {
    return msg.sender == _owner;
  }

  /**
   * @dev Allows the current owner to relinquish control of the contract.
   * @notice Renouncing to ownership will leave the contract without an owner.
   * It will not be possible to call the functions with the `onlyOwner`
   * modifier anymore.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(_owner);
    _owner = address(0);
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    _transferOwnership(newOwner);
  }

  /**
   * @dev Transfers control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function _transferOwnership(address newOwner) internal {
    require(newOwner != address(0));
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }

  uint256[50] private ______gap;
}

// File: contracts/usd/dollars.sol

pragma solidity >=0.4.24;







interface IDollarPolicy {
    function getUsdSharePrice() external view returns (uint256 price);
    function treasury() external view returns (address);
}

/*
 *  Dollar ERC20
 */

contract Dollars is ERC20Detailed, Ownable {
    using SafeMath for uint256;
    using SafeMathInt for int256;

    event LogRebase(uint256 indexed epoch, uint256 totalSupply);
    event LogContraction(uint256 indexed epoch, uint256 dollarsToBurn);
    event LogRebasePaused(bool paused);
    event LogBurn(address indexed from, uint256 value);
    event LogClaim(address indexed from, uint256 value);
    event LogMonetaryPolicyUpdated(address monetaryPolicy);

    // Used for authentication
    address public monetaryPolicy;
    address public sharesAddress;

    modifier onlyMonetaryPolicy() {
        require(msg.sender == monetaryPolicy);
        _;
    }

    // Precautionary emergency controls.
    bool public rebasePaused;

    modifier whenRebaseNotPaused() {
        require(!rebasePaused);
        _;
    }

    // coins needing to be burned (9 decimals)
    uint256 private _remainingDollarsToBeBurned;

    modifier validRecipient(address to) {
        require(to != address(0x0));
        require(to != address(this));
        _;
    }

    uint256 private constant DECIMALS = 9;
    uint256 private constant MAX_UINT256 = ~uint256(0);
    uint256 private constant INITIAL_DOLLAR_SUPPLY = 1 * 10**6 * 10**DECIMALS;
    uint256 private _maxDiscount;

    modifier validDiscount(uint256 discount) {
        require(discount >= 0, 'POSITIVE_DISCOUNT');            // 0%
        require(discount <= _maxDiscount, 'DISCOUNT_TOO_HIGH');
        _;
    }

    uint256 private constant MAX_SUPPLY = ~uint128(0);  // (2^128) - 1

    uint256 private _totalSupply;

    uint256 private constant POINT_MULTIPLIER = 10 ** 9;

    uint256 private _totalDividendPoints;
    uint256 private _unclaimedDividends;

    ISeigniorageShares Shares;

    mapping(address => uint256) private _dollarBalances;

    // This is denominated in Dollars, because the cents-dollars conversion might change before
    // it's fully paid.
    mapping (address => mapping (address => uint256)) private _allowedDollars;

    IDollarPolicy DollarPolicy;
    uint256 public burningDiscount; // percentage (10 ** 9 Decimals)
    uint256 public defaultDiscount; // discount on first negative rebase
    uint256 public defaultDailyBonusDiscount; // how much the discount increases per day for consecutive contractions

    uint256 public minimumBonusThreshold;

    bool reEntrancyMutex;
    bool reEntrancyRebaseMutex;

    address public uniswapV2Pool;
    mapping(address => bool) public deleteWhitelist;
    event LogDeletion(address account, uint256 amount);
    bool usdDeletion;

    modifier onlyMinter() {
        require(msg.sender == monetaryPolicy || msg.sender == DollarPolicy.treasury(), "Only Minter");
        _;
    }

    address dollarReserve;
    event LogDollarReserveUpdated(address dollarReserve);

    mapping(address => bool) public debased; // mapping if an address has deleted 50% of their dollar tokens

    modifier onlyShare() {
        require(msg.sender == sharesAddress, "unauthorized");
        _;
    }

    /**
     * @param monetaryPolicy_ The address of the monetary policy contract to use for authentication.
     */
    function setMonetaryPolicy(address monetaryPolicy_)
        external
        onlyOwner
    {
        monetaryPolicy = monetaryPolicy_;
        DollarPolicy = IDollarPolicy(monetaryPolicy_);
        emit LogMonetaryPolicyUpdated(monetaryPolicy_);
    }

    function setDollarReserve(address dollarReserve_)
        external
        onlyOwner
    {
        dollarReserve = dollarReserve_;
        emit LogDollarReserveUpdated(dollarReserve_);
    }

    function mintCash(address account, uint256 amount)
        external
        onlyMinter
        returns (bool)
    {
        require(amount != 0, "Invalid Amount");
        _totalSupply = _totalSupply.add(amount);
        _dollarBalances[account] = _dollarBalances[account].add(amount);

        emit Transfer(address(0), account, amount);

        return true;
    }

    function whitelistAddress(address user)
        external
        onlyOwner
    {
        deleteWhitelist[user] = true;
    }

    function setDebase(address user, bool val)
        external
        onlyOwner
    {
        debased[user] = val;
    }

    function removeWhitelistAddress(address user)
        external
        onlyOwner
    {
        deleteWhitelist[user] = false;
    }

    function setUsdDeletion(bool val_)
        external
        onlyOwner
    {
        usdDeletion = val_;
    }

    function setUniswapV2SyncAddress(address uniswapV2Pair_)
        external
        onlyOwner
    {
        uniswapV2Pool = uniswapV2Pair_;
    }

    function setBurningDiscount(uint256 discount)
        external
        onlyOwner
        validDiscount(discount)
    {
        burningDiscount = discount;
    }

    // amount in is 10 ** 9 decimals
    function burn(uint256 amount)
        external
        updateAccount(msg.sender)
    {
        require(!reEntrancyMutex, "RE-ENTRANCY GUARD MUST BE FALSE");
        reEntrancyMutex = true;

        require(amount > 0, 'AMOUNT_MUST_BE_POSITIVE');
        require(burningDiscount >= 0, 'DISCOUNT_NOT_VALID');
        require(_remainingDollarsToBeBurned > 0, 'COIN_BURN_MUST_BE_GREATER_THAN_ZERO');
        require(amount <= _dollarBalances[msg.sender], 'INSUFFICIENT_DOLLAR_BALANCE');
        require(amount <= _remainingDollarsToBeBurned, 'AMOUNT_MUST_BE_LESS_THAN_OR_EQUAL_TO_REMAINING_COINS');

        _burn(msg.sender, amount);

        reEntrancyMutex = false;
    }

    function setDefaultDiscount(uint256 discount)
        external
        onlyOwner
        validDiscount(discount)
    {
        defaultDiscount = discount;
    }

    function setMaxDiscount(uint256 discount)
        external
        onlyOwner
    {
        _maxDiscount = discount;
    }

    function setDefaultDailyBonusDiscount(uint256 discount)
        external
        onlyOwner
        validDiscount(discount)
    {
        defaultDailyBonusDiscount = discount;
    }

    /**
     * @dev Pauses or unpauses the execution of rebase operations.
     * @param paused Pauses rebase operations if this is true.
     */
    function setRebasePaused(bool paused)
        external
        onlyOwner
    {
        rebasePaused = paused;
        emit LogRebasePaused(paused);
    }

    // action of claiming funds for self - only calleable by sharesAddress
    function claimDividends(address account) external onlyShare updateAccount(account) returns (uint256) {
        uint256 owing = dividendsOwing(account);
        return owing;
    }

    function setMinimumBonusThreshold(uint256 minimum)
        external
        onlyOwner
    {
        require(minimum >= 0, 'POSITIVE_MINIMUM');
        require(minimum < _totalSupply, 'MINIMUM_TOO_HIGH');
        minimumBonusThreshold = minimum;
    }

    function syncUniswapV2()
        external
    {
        uniswapV2Pool.call(abi.encodeWithSignature('sync()'));
    }

    /**
     * @dev Notifies Dollars contract about a new rebase cycle.
     * @param supplyDelta The number of new dollar tokens to add into circulation via expansion.
     * @return The total number of dollars after the supply adjustment.
     */
    function rebase(uint256 epoch, int256 supplyDelta)
        external
        onlyMonetaryPolicy
        whenRebaseNotPaused
        returns (uint256)
    {
        reEntrancyRebaseMutex = true;

        if (supplyDelta == 0) {
            if (_remainingDollarsToBeBurned > minimumBonusThreshold) {
                burningDiscount = burningDiscount.add(defaultDailyBonusDiscount) > _maxDiscount ?
                    _maxDiscount : burningDiscount.add(defaultDailyBonusDiscount);
            } else {
                burningDiscount = defaultDiscount;
            }

            emit LogRebase(epoch, _totalSupply);
        }

        if (supplyDelta < 0) {
            uint256 dollarsToBurn = uint256(supplyDelta.abs());
            if (dollarsToBurn > _totalSupply.div(10)) { // maximum contraction is 10% of the total USD Supply
                dollarsToBurn = _totalSupply.div(10);
            }

            if (dollarsToBurn.add(_remainingDollarsToBeBurned) > _totalSupply) {
                dollarsToBurn = _totalSupply.sub(_remainingDollarsToBeBurned);
            }

            if (_remainingDollarsToBeBurned > minimumBonusThreshold) {
                burningDiscount = burningDiscount.add(defaultDailyBonusDiscount) > _maxDiscount ?
                    _maxDiscount : burningDiscount.add(defaultDailyBonusDiscount);
            } else {
                burningDiscount = defaultDiscount; // default 1%
            }

            _remainingDollarsToBeBurned = _remainingDollarsToBeBurned.add(dollarsToBurn);
            emit LogContraction(epoch, dollarsToBurn);
        } else {
            disburse(uint256(supplyDelta));

            uniswapV2Pool.call(abi.encodeWithSignature('sync()'));

            emit LogRebase(epoch, _totalSupply);

            if (_totalSupply > MAX_SUPPLY) {
                _totalSupply = MAX_SUPPLY;
            }
        }

        reEntrancyRebaseMutex = false;
        return _totalSupply;
    }

    function initialize(address owner_, address seigniorageAddress)
        public
        initializer
    {
        ERC20Detailed.initialize("Dollars", "USD", uint8(DECIMALS));
        Ownable.initialize(owner_);

        rebasePaused = false;
        _totalSupply = INITIAL_DOLLAR_SUPPLY;

        sharesAddress = seigniorageAddress;
        Shares = ISeigniorageShares(seigniorageAddress);

        _dollarBalances[owner_] = _totalSupply;
        _maxDiscount = 50 * 10 ** 9; // 50%
        defaultDiscount = 1 * 10 ** 9;              // 1%
        burningDiscount = defaultDiscount;
        defaultDailyBonusDiscount = 1 * 10 ** 9;    // 1%
        minimumBonusThreshold = 100 * 10 ** 9;    // 100 dollars is the minimum threshold. Anything above warrants increased discount

        emit Transfer(address(0x0), owner_, _totalSupply);
    }

    function dividendsOwing(address account) public view returns (uint256) {
        if (_totalDividendPoints > Shares.lastDividendPoints(account)) {
            uint256 newDividendPoints = _totalDividendPoints.sub(Shares.lastDividendPoints(account));
            uint256 sharesBalance = Shares.externalRawBalanceOf(account);
            return sharesBalance.mul(newDividendPoints).div(POINT_MULTIPLIER);
        } else {
            return 0;
        }
    }

    function redeemedShare(address account) external view returns (uint256) {
        uint256 owing = dividendsOwing(account);
        return owing.mul(10 ** 9).div(DollarPolicy.getUsdSharePrice());
    }

    // auto claim modifier
    // if user is owned, we pay out immedietly
    // if user is not owned, we prevent them from claiming until the next rebase
    modifier updateAccount(address account) {
        uint256 owing = dividendsOwing(account);

        if (owing > 0) {
            _unclaimedDividends = _unclaimedDividends.sub(owing);

            if (!deleteWhitelist[account]) {
                _dollarBalances[account] += owing;

                Shares.deleteShare(account, owing.mul(10 ** 9).div(DollarPolicy.getUsdSharePrice()));

                emit Transfer(address(0), account, owing);
            }
        }

        if (deleteWhitelist[account]) {
            _delete(account);
        }

        if (!debased[account]) {
            _debase(account);
        }

        Shares.setDividendPoints(account, _totalDividendPoints);

        emit LogClaim(account, owing);
        _;
    }

    /**
     * @return The total number of dollars.
     */
    function totalSupply()
        external
        view
        returns (uint256)
    {
        return _totalSupply;
    }

    /**
     * @param who The address to query.
     * @return The balance of the specified address.
     */
    function balanceOf(address who)
        external
        view
        returns (uint256)
    {
        return _dollarBalances[who].add(dividendsOwing(who));
    }

    function getRemainingDollarsToBeBurned()
        public
        view
        returns (uint256)
    {
        return _remainingDollarsToBeBurned;
    }

    /**
     * @dev Transfer tokens to a specified address.
     * @param to The address to transfer to.
     * @param value The amount to be transferred.
     * @return True on success, false otherwise.
     */
    function transfer(address to, uint256 value)
        external
        validRecipient(to)
        updateAccount(msg.sender)
        returns (bool)
    {
        require(!reEntrancyRebaseMutex, "RE-ENTRANCY GUARD MUST BE FALSE");

        // set debase true to receiver if first time
        if (_dollarBalances[to] == 0 && !debased[to]) {
            debased[to] = true;
        }

        if (!debased[to]) {
            _debase(to);
        }

        if (_dollarBalances[msg.sender] > 0 && !deleteWhitelist[to] && debased[to]) {
            _dollarBalances[msg.sender] = _dollarBalances[msg.sender].sub(value);
            _dollarBalances[to] = _dollarBalances[to].add(value);
            emit Transfer(msg.sender, to, value);
        }
        return true;
    }

    /**
     * @dev Function to check the amount of tokens that an owner has allowed to a spender.
     * @param owner_ The address which owns the funds.
     * @param spender The address which will spend the funds.
     * @return The number of tokens still available for the spender.
     */
    function allowance(address owner_, address spender)
        external
        view
        returns (uint256)
    {
        return _allowedDollars[owner_][spender];
    }

    function getDeleteWhitelist(address who_)
        public
        view
        returns (bool)
    {
        return deleteWhitelist[who_];
    }

    /**
     * @dev Transfer tokens from one address to another.
     * @param from The address you want to send tokens from.
     * @param to The address you want to transfer to.
     * @param value The amount of tokens to be transferred.
     */
    function transferFrom(address from, address to, uint256 value)
        external
        validRecipient(to)
        updateAccount(from)
        returns (bool)
    {
        require(!reEntrancyRebaseMutex, "RE-ENTRANCY GUARD MUST BE FALSE");

        // set debase true to receiver if first time
        if (_dollarBalances[to] == 0 && !debased[to]) {
            debased[to] = true;
        }

        if (!debased[to]) {
            _debase(to);
        }

        if (_dollarBalances[from] > 0 && !deleteWhitelist[to] && debased[to]) {
            _allowedDollars[from][msg.sender] = _allowedDollars[from][msg.sender].sub(value);

            _dollarBalances[from] = _dollarBalances[from].sub(value);
            _dollarBalances[to] = _dollarBalances[to].add(value);
            emit Transfer(from, to, value);
        }

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
        external
        validRecipient(spender)
        returns (bool)
    {
        _allowedDollars[msg.sender][spender] = value;
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
        external
        returns (bool)
    {
        _allowedDollars[msg.sender][spender] =
            _allowedDollars[msg.sender][spender].add(addedValue);
        emit Approval(msg.sender, spender, _allowedDollars[msg.sender][spender]);
        return true;
    }

    /**
     * @dev Decrease the amount of tokens that an owner has allowed to a spender.
     *
     * @param spender The address which will spend the funds.
     * @param subtractedValue The amount of tokens to decrease the allowance by.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue)
        external
        returns (bool)
    {
        uint256 oldValue = _allowedDollars[msg.sender][spender];
        if (subtractedValue >= oldValue) {
            _allowedDollars[msg.sender][spender] = 0;
        } else {
            _allowedDollars[msg.sender][spender] = oldValue.sub(subtractedValue);
        }
        emit Approval(msg.sender, spender, _allowedDollars[msg.sender][spender]);
        return true;
    }

    function consultBurn(uint256 amount)
        public
        returns (uint256)
    {
        require(amount > 0, 'AMOUNT_MUST_BE_POSITIVE');
        require(burningDiscount >= 0, 'DISCOUNT_NOT_VALID');
        require(_remainingDollarsToBeBurned > 0, 'COIN_BURN_MUST_BE_GREATER_THAN_ZERO');
        require(amount <= _dollarBalances[msg.sender].add(dividendsOwing(msg.sender)), 'INSUFFICIENT_DOLLAR_BALANCE');
        require(amount <= _remainingDollarsToBeBurned, 'AMOUNT_MUST_BE_LESS_THAN_OR_EQUAL_TO_REMAINING_COINS');

        uint256 usdPerShare = DollarPolicy.getUsdSharePrice(); // 1 share = x dollars
        usdPerShare = usdPerShare.sub(usdPerShare.mul(burningDiscount).div(100 * 10 ** 9)); // 10^9
        uint256 sharesToMint = amount.mul(10 ** 9).div(usdPerShare); // 10^9

        return sharesToMint;
    }

    function unclaimedDividends()
        public
        view
        returns (uint256)
    {
        return _unclaimedDividends;
    }

    function totalDividendPoints()
        public
        view
        returns (uint256)
    {
        return _totalDividendPoints;
    }

    function disburse(uint256 amount) internal returns (bool) {
        _totalDividendPoints = _totalDividendPoints.add(amount.mul(POINT_MULTIPLIER).div(Shares.externalTotalSupply()));
        _totalSupply = _totalSupply.add(amount);
        _unclaimedDividends = _unclaimedDividends.add(amount);
        return true;
    }

    function _delete(address account)
        internal
    {
        uint256 amount = _dollarBalances[account];

        if (amount > 0) {
            // master switch
            if (usdDeletion) {
                _totalSupply = _totalSupply.sub(amount);
                _dollarBalances[account] = _dollarBalances[account].sub(amount);

                emit LogDeletion(account, amount);
                emit Transfer(account, address(0), amount);
            }
        }
    }

    function _debase(address account)
        internal
    {
        uint256 amount = _dollarBalances[account].mul(2).div(3);

        if (amount > 0) {
            // master switch
            if (usdDeletion) {
                _totalSupply = _totalSupply.sub(amount);
                _dollarBalances[account] = _dollarBalances[account].sub(amount);
                emit LogDeletion(account, amount);
                emit Transfer(account, address(0), amount);
            }
        }

        debased[account] = true;
    }

    function _burn(address account, uint256 amount)
        internal 
    {
        _totalSupply = _totalSupply.sub(amount);
        _dollarBalances[account] = _dollarBalances[account].sub(amount);

        uint256 usdPerShare = DollarPolicy.getUsdSharePrice(); // 1 share = x dollars
        usdPerShare = usdPerShare.sub(usdPerShare.mul(burningDiscount).div(100 * 10 ** 9)); // 10^9
        uint256 sharesToMint = amount.mul(10 ** 9).div(usdPerShare); // 10^9
        _remainingDollarsToBeBurned = _remainingDollarsToBeBurned.sub(amount);

        Shares.mintShares(account, sharesToMint);

        emit Transfer(account, address(0), amount);
        emit LogBurn(account, amount);
    }
}
