//        .__           .__  .__                    __         .__        
//   _____|  |__   ____ |  | |  |     _____ _____ _/  |________|__|__  ___
//  /  ___/  |  \_/ __ \|  | |  |    /     \\__  \\   __\_  __ \  \  \/  /
//  \___ \|   Y  \  ___/|  |_|  |__ |  Y Y  \/ __ \|  |  |  | \/  |>    < 
// /____  >___|  /\___  >____/____/ |__|_|  (____  /__|  |__|  |__/__/\_ \
//      \/     \/     \/                  \/     \/                     \/
//
//  Shell Matrix https://shell.org
//

pragma solidity >=0.5.0 <0.6.0;

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
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
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
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
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
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

/**
 * @title Roles
 * @dev Library for managing addresses assigned to a Role.
 */
library Roles {
    struct Role {
        mapping (address => bool) bearer;
    }

    /**
     * @dev Give an account access to this role.
     */
    function add(Role storage role, address account) internal {
        require(!has(role, account), "Roles: account already has role");
        role.bearer[account] = true;
    }

    /**
     * @dev Remove an account's access to this role.
     */
    function remove(Role storage role, address account) internal {
        require(has(role, account), "Roles: account does not have role");
        role.bearer[account] = false;
    }

    /**
     * @dev Check if an account has this role.
     * @return bool
     */
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0), "Roles: account is the zero address");
        return role.bearer[account];
    }
}

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
contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () internal { }
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

interface ERC20 {
    function mint(address account, uint256 amount) external returns (bool);
    function totalSupply() external view returns (uint256);
}

interface Matrix {
    function getUserX3Level(uint _userID) external view returns (uint8);
    function getUserX6Level(uint _userID) external view returns (uint8);
    function getUserContribution(uint _userID) external view returns (uint);
    function ids(address _user) external view returns (uint);
}

contract OwnershipRole is Context {
    using Roles for Roles.Role;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event AdminAdded(address indexed account);
    event AdminRemoved(address indexed account);

    address private _owner;
    Roles.Role private _admins;

    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
        _addAdmin(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    modifier onlyAdmin() {
        require(isAdmin(_msgSender()), "OwnershipRole: caller does not have the Admin role");
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }

    function isAdmin(address account) public view returns (bool) {
        return _admins.has(account);
    }

    function addAdmin(address account) public onlyOwner {
        _addAdmin(account);
    }

    function removeAdmin(address account) public onlyOwner {
        _removeAdmin(account);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function renounceAdmin() public {
        _removeAdmin(_msgSender());
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    function _addAdmin(address account) internal {
        _admins.add(account);
        emit AdminAdded(account);
    }

    function _removeAdmin(address account) internal {
        _admins.remove(account);
        emit AdminRemoved(account);
    }
}

contract ShellMiner is OwnershipRole {
    using SafeMath for uint;

    struct User {
        uint8 lvX3;
        uint8 lvX6;
        uint contribution;
        uint startBlock;
        uint mined;
    }

    mapping(address => User) public users;

    ERC20 public token;
    Matrix public matrix;

    uint public multiplier;
    uint public maxSupply;
    bool public isOpen;

    constructor(address _token, address _matrix) public {
        token = ERC20(_token);
        matrix = Matrix(_matrix);
        maxSupply = 21000000 * 1000000;
        multiplier = 1024;
        _setMultiplier();
    }

    function() external payable {
      revert("Disable fallback.");
    }

    function getUserMiners(address _user) public view returns (uint) {
        uint miners = uint(users[_user].lvX3).mul(uint(users[_user].lvX6));
        return (miners);
    }

    function getUserStartBlock(address _user) public view returns (uint) {
        return (users[_user].startBlock);
    }

    function getUserMinedTimes(address _user) public view returns (uint) {
        return (users[_user].mined);
    }

    function getUserProfit(address _user) public view returns (uint) {
        uint _current = block.number;
        uint _blocks = _current - getUserStartBlock(_user);
        uint _miners = getUserMiners(_user);
        uint _profit = _blocks.mul(_miners).mul(multiplier);
        return (_profit);
    }

    function mining() external returns (uint) {
        require(isOpen, "Shell Miner is paused.");
        require(maxSupply>token.totalSupply(), "No more token!");
        uint id = matrix.ids(_msgSender());
        uint contribution = matrix.getUserContribution(id);
        require(contribution>0, "You don't have contribution!");

        uint8 lvX3 = matrix.getUserX3Level(id);
        uint8 lvX6 = matrix.getUserX6Level(id);
        uint start = getUserStartBlock(_msgSender());
        uint mined = getUserMinedTimes(_msgSender());
        uint current = block.number;

        if (start > 0) {
            require(current > start, "You don't have profit!");
            require(mined < contribution, "You don't have enough contribution!");
            uint profit = getUserProfit(_msgSender());
            uint remain = maxSupply.sub(token.totalSupply());
            if (profit > remain) {
                profit = remain;
                isOpen = false;
            }
            _restart(_msgSender(), lvX3, lvX6, contribution, current);
            token.mint(_msgSender(), profit);
            return (profit);
        } else {
            _initialize(_msgSender(), lvX3, lvX6, contribution, current);
            return (0);
        }
    }

    function pauseOrNot() external onlyAdmin {
        isOpen = !isOpen;
    }

    function _initialize(address _user, uint8 _lvX3, uint8 _lvX6, uint _contribution, uint _block) private {
        User memory user = User({
            lvX3: _lvX3,
            lvX6: _lvX6,
            contribution: _contribution,
            startBlock: _block,
            mined: uint(0)
        });

        users[_user] = user;
    }

    function _restart(address _user, uint8 _lvX3, uint8 _lvX6, uint _contribution, uint _block) private {
        users[_user].lvX3 = _lvX3;
        users[_user].lvX6 = _lvX6;
        users[_user].contribution = _contribution;
        users[_user].startBlock = _block;
        users[_user].mined = users[_user].mined.add(1);
    }

    function _setMultiplier() private {
        uint totalSupply = token.totalSupply();
        uint remain = maxSupply.sub(totalSupply);

        for (uint i = 0; i < 10; i++) {
            uint _m = 2 ** uint(10-i);
            if (remain < totalSupply.div(_m)) {
                multiplier = 2 ** i;
                return;
            }
        }
    }
}