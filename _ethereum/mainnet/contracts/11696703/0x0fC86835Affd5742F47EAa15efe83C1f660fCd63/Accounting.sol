pragma solidity ^0.6.0;


// SPDX-License-Identifier: MIT
/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT
/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// import "./IERC20.sol";
contract Accounting is Ownable {

    event onSubscribe(address indexed account, string nick, uint addSecs, uint activeTill);

    using SafeMath for uint256;

    struct User {
        address _address;
        string _nick;
        uint _activeTill;
        bool _superVIP;
    }

    struct Plan {
        uint _minAddSec;
        uint _pricePerSec;
    }


    bytes4 private constant SELECTOR = bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));


    User[] public _users;
    Plan[] public _plans;

    address public _token;
    address public _treasure;

    mapping (address => uint256) public _aindexes;
    mapping (string => uint256) public _nindexes;


    constructor () public {
        _users.push(User(address(0x0), "", 0, false));
    }

    function setupToken(address token) public onlyOwner {
        _token = token;
    }

    function setupTreasure(address treasure) public onlyOwner {
        _treasure = treasure;
    }

    function setupPlansAmount(uint n) public onlyOwner {
        delete _plans;
        for (uint i = 0; i < n; i++) {
            _plans.push();
        }
    }

    function getPlansAmount() public view returns (uint r) {
        r = _plans.length;
    }

    function setupPlan(uint idx, uint pricePerSec, uint minAddSec) public onlyOwner {
        _plans[idx]._minAddSec = minAddSec;
        _plans[idx]._pricePerSec = pricePerSec;
    }

    function _safeTransfer(address from, address to, uint value) private {
        require(_token != address(0x0));
        (bool success, bytes memory data) = _token.call(abi.encodeWithSelector(SELECTOR, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TRANSFER_FAILED');
    }

    function getUsersAmount() public view returns (uint r) {
        r = _users.length;
    }


    function getNick(address account) public view returns (string memory) {
    	uint idx = _aindexes[account];
    	return _users[idx]._nick;
    }

    function getAccount(string memory nick) public view returns (address) {
        uint idx = _nindexes[nick];
        return _users[idx]._address;
    }

    function getActiveTill(address account) public view returns (uint) {
    	uint idx = _aindexes[account];
    	return _users[idx]._activeTill;
    }

    function getActiveTillByNick(string memory nick) public view returns (uint) {
        uint idx = _nindexes[nick];
        return _users[idx]._activeTill;
    }

    function _addTime(User storage user, uint addSecs) private  {
        if (user._activeTill < now) {
            user._activeTill = now;
        }
        user._activeTill = user._activeTill.add(addSecs);
    }

    function _stringsEqual(string storage _a, string memory _b) view internal returns (bool) {
        bytes storage a = bytes(_a);
        bytes memory b = bytes(_b);
        if (a.length != b.length)
            return false;

        for (uint i = 0; i < a.length; i++)
            if (a[i] != b[i])
                return false;
        return true;
    }

    function _setupNick(User storage user, string memory nick) private {
        assert(user._address != address(0x0)); //not default User
        if (_stringsEqual(user._nick, nick)) {
            return;
        }

        require(_nindexes[nick] == 0, "Nick is in use");
        uint idx = _aindexes[user._address];

        if (bytes(user._nick).length > 0) {
            assert(_nindexes[user._nick] == idx); //indexes is consistent
            delete _nindexes[user._nick];
        }

        user._nick = nick;
        _nindexes[nick] = idx;
    }

    function _setUser(address account, string memory nick, uint addSecs) private {
        assert(account != address(0x0));

        uint idx = _aindexes[account];

        if (idx == 0) {
            idx = _users.length;
            _users.push(User(account, "", 0, false));
            _aindexes[account] = idx;
        }

        User storage user = _users[idx];
        _addTime(user, addSecs);

        if (bytes(nick).length > 0)
            _setupNick(user, nick);

        emit onSubscribe(account, user._nick, addSecs, user._activeTill);
    }

    function adminSetUser(address account, string memory nick, uint addSecs) public onlyOwner {
        require(account != address(0x0));
        _setUser(account, nick, addSecs);
    }

    function checkPlans() public view {
        uint prevMinAddSec = 0;
        uint prevPricePerSec = 0;
        for (uint i = 0; i < _plans.length; i++) {
            require(i == _plans.length-1 || _plans[i]._minAddSec > 0);
            require(prevMinAddSec == 0 || _plans[i]._minAddSec < prevMinAddSec);
            require(_plans[i]._pricePerSec > prevPricePerSec);
            prevPricePerSec = _plans[i]._pricePerSec;
            prevMinAddSec = _plans[i]._minAddSec;
        }
    }

    function getPriceForPlan(uint addSecs) public view returns (uint) {
        require(_plans.length > 0);
        checkPlans();

        uint n = _plans.length-1;

        if (addSecs == 0) {
            return _plans[n]._pricePerSec;
        }

        for (uint i = 0; i < n; i++) {
            if (addSecs >= _plans[i]._minAddSec) {
                return _plans[i]._pricePerSec;
            }
        }
        return _plans[n]._pricePerSec;
    }


    function subscribe(string memory nick, uint256 addSecs) public {

        address account = msg.sender;
        require(account != address(0x0));
        require(_treasure != address(0x0));

        uint pricePerSec = getPriceForPlan(addSecs);
        uint amount = addSecs.mul(pricePerSec);

        if (amount > 0) {
            _safeTransfer(account, _treasure, amount);
        }

        // emit LogSetOwner(owner);

        _setUser(account, nick, addSecs);
    }


    function changeNick(string memory nick) public {
        address account = msg.sender;
        require(account != address(0x0));
        require(bytes(nick).length > 0);
        uint idx = _aindexes[account];
        require(idx > 0);
        _setupNick(_users[idx], nick);
    }
}