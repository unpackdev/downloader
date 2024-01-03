// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.6.12;

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


library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * This test is non-exhaustive, and there may be false-negatives: during the
     * execution of a contract's constructor, its address will be reported as
     * not containing a contract.
     *
     * IMPORTANT: It is unsafe to assume that an address for which this
     * function returns false is an externally-owned account (EOA) and not a
     * contract.
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies in extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != 0x0 && codehash != accountHash);
    }

    /**
     * @dev Converts an `address` into `address payable`. Note that this is
     * simply a type cast: the actual underlying value is not changed.
     *
     * _Available since v2.4.0._
     */
    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     *
     * _Available since v2.4.0._
     */
    function sendValue(address payable recipient, uint amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-call-value
        (bool success, ) = recipient.call { value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

contract Ownable {

  address public owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  constructor() internal {
    owner = msg.sender;
    emit OwnershipTransferred(address(0), owner);
  }

  modifier onlyOwner() {
    require(isOwner(), "Ownable: caller is not the owner");
    _;
  }

  function isOwner() public view returns (bool) {
    return msg.sender == owner;
  }

  function renounceOwnership() public onlyOwner {
    emit OwnershipTransferred(owner, address(0));
    owner = address(0);
  }

  function transferOwnership(address newOwner) public onlyOwner {
    _transferOwnership(newOwner);
  }

  function _transferOwnership(address newOwner) internal {
    require(newOwner != address(0), "Ownable: new owner is the zero address");
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }
}

interface IUniswapV2Pair {
  function totalSupply() external view returns (uint);
  function token0() external view returns (address);
  function token1() external view returns (address);

  event Mint(address indexed sender, uint amount0, uint amount1);
  event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
  event Sync(uint112 reserve0, uint112 reserve1);
  event Swap(
      address indexed sender,
      uint amount0In,
      uint amount1In,
      uint amount0Out,
      uint amount1Out,
      address indexed to
  );
}

contract Controller is Ownable {

  using Address for address;
  using SafeMath for uint;

  mapping (address => uint) public storedUniSupply;
  mapping (address => address) public poolReceiver;

  address public protocolReceiver;
  address public mainPool; // Hype / ETH pool

  uint public poolTransferBps = 75;
  uint public poolWithdrawalBps = 3000;
  uint public protocolTransferBps = 25;
  uint public protocolWithdrawalBps = 1000;

  function setFees(
    uint _poolTransferBps,
    uint _poolWithdrawalBps,
    uint _protocolTransferBps,
    uint _protocolWithdrawalBps
  ) public onlyOwner {
    require(_poolTransferBps <= 250 && _protocolTransferBps <= 250, "invalid fees");

    poolTransferBps = _poolTransferBps;
    poolWithdrawalBps = _poolWithdrawalBps;
    protocolTransferBps = _protocolTransferBps;
    protocolWithdrawalBps = _protocolWithdrawalBps;
  }

  function setProtocolReceiver(address _protocolReceiver) public onlyOwner {
    protocolReceiver = _protocolReceiver;
  }

  function setMainPool(address _pool, address _receiver) public onlyOwner {
    mainPool = _pool;
    setPool(_pool, _receiver);
  }

  function setPool(address _pool, address _receiver) public onlyOwner {
    poolReceiver[_pool] = _receiver;
  }

  // There are 2 kinds of fees: a transfer fee (lower) and a withdrawal fee (higher)
  // It's always one or the other, never both
  function getFees(address _sender, address _recipient) public returns(uint, uint, address, address) {
    bool isWithdrawal;
    address feePool = mainPool; // Fees from all non-UniPair transfers go to mainPool

    if (_isUniPair(_sender)) {
      isWithdrawal = _approveTransfer(_sender);
      if (_sender != mainPool) {
        feePool = _sender;
      }
    }

    if (_isUniPair(_recipient)) {
      if (!isWithdrawal && _approveTransfer(_recipient)) {
        isWithdrawal = true;
      }
      if (_recipient != mainPool) {
        feePool = _recipient;
      }
    }

    uint poolBps = poolTransferBps;
    uint protocolBps = protocolTransferBps;

    // Apply withdrawal fee if sender / recipient is UniPair and it's withdrawing
    if (isWithdrawal) {
      poolBps = poolWithdrawalBps;
      protocolBps = protocolWithdrawalBps;
    }

    return(poolBps, protocolBps, poolReceiver[feePool], protocolReceiver);
  }

  // Returns True is the transfer is a withdrawal
  function _approveTransfer(address _pair) internal returns(bool) {
    uint currentUniSupply = IUniswapV2Pair(_pair).totalSupply();

    bool result = storedUniSupply[_pair] > currentUniSupply;

    if (result) {
      uint diff = storedUniSupply[_pair].sub(currentUniSupply);
      // To prevent random withdrawals from LPs not familiar with the withdrawal tax
      // Amount of LP tokens must end with 1111111111
      require(diff.add(8888888889).mod(10000000000) == 0, "withdrawal rejected");
    }

    storedUniSupply[_pair] = currentUniSupply;

    return result;
  }

  // This does not detect all Uni pairs
  // It only tells us is the Uni pair has been whitelisted
  function _isUniPair(address _pair) internal view returns(bool) {
    return poolReceiver[_pair] != address(0);
  }
}