// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// File: @openzeppelin/contracts/math/SafeMath.sol

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

// File: @openzeppelin/contracts/GSN/Context.sol

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

// File: @openzeppelin/contracts/access/Ownable.sol

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
abstract contract Ownable is Context {
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

// File: @openzeppelin/contracts/utils/Counters.sol

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented or decremented by one. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 * Since it is not possible to overflow a 256 bit integer with increments of one, `increment` can skip the {SafeMath}
 * overflow check, thereby saving gas. This does assume however correct usage, in that the underlying `_value` is never
 * directly accessed.
 */
library Counters {
    using SafeMath for uint256;

    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        // The {SafeMath} overflow check can be skipped here, see the comment at the top
        counter._value += 1;
    }

    function decrement(Counter storage counter) internal {
        counter._value = counter._value.sub(1);
    }
}

// File: contracts/DonFund.sol

contract DonFund is Ownable {
  using SafeMath for uint256;
  using Counters for Counters.Counter;

  modifier causeExists(uint256 _causeId) {
    require(
      causes[_causeId].createdBy != address(0),
      "Cause with causeId provided does not exist"
    );

    _;
  }

  struct Cause {
    uint256 id;
    address recipient;
    bool isActive;
    bool isVerified;
    string title;
    string website;
    uint256 funded;
    uint256 xDonAmount;
    uint256 staked;
    address createdBy;
    mapping (address => Supporter) supporters;
  }

  struct Supporter {
    uint256 donAmount;
    uint256 xDonAmount;
  }
  
  mapping (uint256 => Cause) public causes;
  IERC20 public donCoin;
  bool isDonCoinSet = false;
  Counters.Counter public numCauses;
  uint256 public totalStaked;
  mapping (address => uint256) public stakedByAddress;
  uint256 public minDonCoin;

  event LogCauseCreated(address createdBy, uint256 causeId);
  event LogEnter(address sender, uint256 causeId, uint256 amount);
  event LogLeave(address sender, uint256 causeId, uint256 senderStaked, uint256 causeAmount);


  constructor() public {
    minDonCoin = 1000000000000000000000;
  }

  function setDonCoin(address _donCoin) public onlyOwner {
    require(
      !isDonCoinSet,
      "DonCoin already set"
    );

    donCoin = IERC20(_donCoin);

    isDonCoinSet = true;
  }

  function setMinDonCoin(uint256 _amount) public onlyOwner {
    minDonCoin = _amount;
  }

  function getNumCauses() public view returns (uint256) {
    return numCauses.current();
  }

  function createCause(
    address _recipient,
    string memory _title,
    string memory _website
  ) public {
    require(
      donCoin.balanceOf(msg.sender) > minDonCoin,
      "You do not have the minimum amount of DON to create a cause"
    );

    require(
      !isTextEmpty(_title),
      "The cause must have a title"
    );

    require(
      _recipient != address(0),
      "A recipient address must be provided"
    );

    causes[numCauses.current()] = Cause({
      id: numCauses.current(),
      recipient: _recipient,
      isActive: true,
      isVerified: false,
      title: _title,
      website: _website,
      funded: 0,
      xDonAmount: 0,
      staked: 0,
      createdBy: msg.sender
    });

    emit LogCauseCreated(msg.sender, numCauses.current());

    numCauses.increment();
  }

  function verifyCause(
    uint256 _causeId,
    bool _isVerified
  ) public onlyOwner {
    causes[_causeId].isVerified = _isVerified;
  }

  function setCauseIsActive(uint256 _causeId, bool _isActive) public {
    Cause memory cause = causes[_causeId];

    require(
      msg.sender == owner() || cause.createdBy == msg.sender,
      "You do not have access to edit this cause"
    );

    causes[_causeId].isActive = _isActive;
  }

  function causeSupporterDonAmount(
    uint256 _causeId,
    address _supporter
  ) public view causeExists(_causeId) returns(uint256) {
    return causes[_causeId].supporters[_supporter].donAmount;
  }

  function causeSupporterxDonAmount(
    uint256 _causeId,
    address _supporter
  ) public view causeExists(_causeId) returns(uint256) {
    return causes[_causeId].supporters[_supporter].xDonAmount;
  }

  function causexDon(
    uint256 _causeId
  ) public view causeExists(_causeId) returns(uint256) {
    return causes[_causeId].xDonAmount;
  }

  function getxDonAmount(
    uint256 _causeId,
    uint256 _amount
  ) public view causeExists(_causeId) returns(uint256) {
    uint256 causeStaked = causes[_causeId].staked;
    
    uint256 _causexDon = causexDon(_causeId);
    
    if (_causexDon == 0 || causeStaked == 0) {
      return _amount;
    }

    return _amount.mul(_causexDon).div(causeStaked);
  }

  function enter(
    uint256 _causeId, uint256 _amount
  ) public causeExists(_causeId) {
    require(
      _amount <= donCoin.allowance(msg.sender, address(this)),
      "You have not allowed the Don Fund to withdraw the requested of amount of DON"
    );

    require(
      causes[_causeId].isActive,
      "The cause must be active"
    );

    uint256 xDonAmount = getxDonAmount(_causeId, _amount);

    causes[_causeId].supporters[msg.sender].donAmount =
      causes[_causeId].supporters[msg.sender].donAmount.add(_amount);
    
    causes[_causeId].supporters[msg.sender].xDonAmount =
      causes[_causeId].supporters[msg.sender].xDonAmount.add(xDonAmount);

    stakedByAddress[msg.sender] =
      stakedByAddress[msg.sender].add(_amount);

    causes[_causeId].staked =
      causes[_causeId].staked.add(_amount);

    totalStaked = totalStaked.add(_amount);

    causes[_causeId].xDonAmount =
      causes[_causeId].xDonAmount.add(xDonAmount);

    // Lock the DON in the contract
    donCoin.transferFrom(msg.sender, address(this), _amount);

    emit LogEnter(msg.sender, _causeId, _amount);
  }

  function leave(uint256 _causeId) public causeExists(_causeId) {
    uint256 share = causeSupporterxDonAmount(_causeId, msg.sender);

    require(
      share > 0,
      "Your balance is 0"
    );

    uint256 causeShares = causes[_causeId].xDonAmount;

    // Get proportion of total DON in DonFund attributable to this cause
    uint256 causeStaked = causeStakedShare(_causeId);

    uint256 fundedAmount = share.mul(causeStaked).div(causeShares);

    uint256 senderStaked = causeSupporterDonAmount(
      _causeId,
      msg.sender
    );

    donCoin.transfer(msg.sender, senderStaked);

    // Due to division imprecision for fundedAmount,
    // we multiply causeAmount by 99%
    uint256 causeAmount = (fundedAmount.sub(senderStaked))
      .mul(90)
      .div(100);

    donCoin.transfer(causes[_causeId].recipient, causeAmount);

    causes[_causeId].supporters[msg.sender].donAmount = 0;
    causes[_causeId].supporters[msg.sender].xDonAmount = 0;

    causes[_causeId].xDonAmount =
      causes[_causeId].xDonAmount.sub(share);

    causes[_causeId].funded =
      causes[_causeId].funded.add(causeAmount);
    
    causes[_causeId].staked =
      causes[_causeId].staked.sub(senderStaked);

    stakedByAddress[msg.sender] =
      stakedByAddress[msg.sender].sub(senderStaked);

    totalStaked = totalStaked.sub(senderStaked);

    emit LogLeave(msg.sender, _causeId, senderStaked, causeAmount);
  }

  function causeStakedShare(
    uint256 _causeId
  ) public view returns(uint256) {
    Cause memory cause = causes[_causeId];

    if (cause.staked == 0 || totalStaked == 0) {
      return 0;
    }

    return cause.staked
      .mul(donCoin.balanceOf(address(this)))
      .div(totalStaked);
  }

  function isTextEmpty(
    string memory _string
  ) public pure returns(bool) {
    return bytes(_string).length == 0;
  }
}