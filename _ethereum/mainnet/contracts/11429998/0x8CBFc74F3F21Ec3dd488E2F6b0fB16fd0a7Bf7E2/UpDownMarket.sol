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

interface IERC20 {
  function totalSupply() external view returns (uint);
  function balanceOf(address account) external view returns (uint);
  function transfer(address recipient, uint amount) external returns (bool);
  function allowance(address owner, address spender) external view returns (uint);
  function approve(address spender, uint amount) external returns (bool);
  function transferFrom(address sender, address recipient, uint amount) external returns (bool);
}

interface IORACLE {
  function price0Last(address _pair) external view returns (uint amountOut);
  function update(address _pair) external;
  function isUpdateRequired(address _pair) external view returns(bool);
  function initialize() external;
  function addPair(address _pair, uint _startTime) external;
  function nextUpdateAt(address _pair) external view returns(uint);
  function PERIOD() external view returns(uint);
}

contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor () internal {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
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

contract UpDownMarket is Ownable, ReentrancyGuard {

  using SafeMath for uint;

  uint public constant MIN_BID_TIME = 1 minutes;

  IORACLE public oracle;
  address public oraclePair;
  address public feeRecipient;

  uint public latestBidTime = 30 minutes; // before resolution

  mapping (uint => uint) public resolvedTo; // per epoch: 1 = up, 2 = down
  mapping (uint => uint) public totalSharesUp; // per epoch
  mapping (uint => uint) public totalSharesDown; // per epoch
  mapping (uint => uint) public purchasedEpoch; // per epoch
  mapping (uint => mapping (address => uint)) public purchasedOfUp; // epoch[account]
  mapping (uint => mapping (address => uint)) public purchasedOfDown; // epoch[account]
  mapping (uint => mapping (address => uint)) public sharesOfUp; // epoch[account]
  mapping (uint => mapping (address => uint)) public sharesOfDown; // epoch[account]

  // For the sake of simplicity, purchasedOf* and sharesOfUp* had different values in the previous implementation
  // but are equal in this implementation

  uint public currentEpoch = 0;
  uint public lastTWAP;
  uint public feeBps = 0;
  uint public maxSupply = 200e18; // ETH

  modifier checkTime() {
    require(isTimeOpen(block.timestamp), "UpDownMarket: buying is closed");
    _;
  }

  modifier enforceLimits() {
    _;
    require(purchasedEpoch[currentEpoch] <= maxSupply, "UpDownMarket: maxSupply reached");
  }

  constructor(IORACLE _oracle, address _oraclePair, uint _startTime) public {
    oracle = _oracle;
    oraclePair = _oraclePair;
    oracle.initialize();
    oracle.addPair(oraclePair, _startTime);
    lastTWAP = oracle.price0Last(oraclePair);
  }

  function buyUp(uint _minShares) public payable checkTime enforceLimits nonReentrant {
    _mintUp(msg.sender, currentEpoch, msg.value, _minShares);
  }

  function buyDown(uint _minShares) public payable checkTime enforceLimits nonReentrant {
    _mintDown(msg.sender, currentEpoch, msg.value, _minShares);
  }

  function claim(uint _epoch) public nonReentrant {
    uint transferAmount = winAmount(_epoch, msg.sender);
    require(transferAmount > 0, "UpDownMarket: not a winner");

    uint fee = transferAmount.mul(feeBps).div(10000);
    _sendEth(feeRecipient, _epoch, fee);
    transferAmount = transferAmount.sub(fee);

    _sendEth(msg.sender, _epoch, transferAmount);
    _burnAll(msg.sender, _epoch);
  }

  function resolve() public {
    require(oracle.isUpdateRequired(oraclePair), "UpDownMarket: too early");
    
    oracle.update(oraclePair);

    uint currentTWAP = oracle.price0Last(oraclePair);

    if (currentTWAP > lastTWAP) {
      resolvedTo[currentEpoch] = 1;
      _claimDustUp(currentEpoch);

    } else if (currentTWAP < lastTWAP) {
      resolvedTo[currentEpoch] = 2;
      _claimDustDown(currentEpoch);
    
    } else {
      revert("UpDownMarket: twap not changed yet");
    }

    currentEpoch = currentEpoch.add(1);
    lastTWAP = currentTWAP;
  }

  function setFeeBps(uint _value) public onlyOwner {
    feeBps = _value;
  }

  function setFeeRecipent(address _feeRecipient) public onlyOwner {
    feeRecipient = _feeRecipient;
  }

  function setLatestBidTime(uint _latestBidTime) public onlyOwner {
    require(latestBidTime > MIN_BID_TIME, "UpDownMarket: latestBidTime too short");
    latestBidTime = _latestBidTime;
  }

  function setMaxSupply(uint _maxSupply) public onlyOwner {
    maxSupply = _maxSupply;
  }

  function totalSupplyEpoch(uint _epoch) public view returns(uint) {
    return totalSharesUp[_epoch].add(totalSharesDown[_epoch]);
  }

  function winAmount(uint _epoch, address _account) public view returns(uint) {

    // Up won
    if (resolvedTo[_epoch] == 1) {
      if (totalSharesUp[_epoch] == 0) {
        return 0;
      } else {
        return purchasedEpoch[_epoch].mul(sharesOfUp[_epoch][_account]).div(totalSharesUp[_epoch]);
      }

    // Down won
    } else if (resolvedTo[_epoch] == 2) {
      if (totalSharesDown[_epoch] == 0) {
        return 0;
      } else {
        return purchasedEpoch[_epoch].mul(sharesOfDown[_epoch][_account]).div(totalSharesDown[_epoch]);
      }
    } else {
      return 0;
    }
  }

  // Buying closes latestBidTime seconds before resolution
  function isTimeOpen(uint _timestamp) public view returns(bool) {
    return block.timestamp < oracle.nextUpdateAt(oraclePair).sub(latestBidTime);
  }

  // UP wins but there is nobody to collect the winnings = claim as fees
  function _claimDustUp(uint _epoch) internal {
    if (totalSharesUp[_epoch] == 0) {
      _sendEth(feeRecipient, _epoch, purchasedEpoch[_epoch]);
      purchasedEpoch[_epoch] = 0;
    }
  }

  // DOWN wins but there is nobody to collect the winnings = claim as fees
  function _claimDustDown(uint _epoch) internal {
    if (totalSharesDown[_epoch] == 0) {
      _sendEth(feeRecipient, _epoch, purchasedEpoch[_epoch]);
      purchasedEpoch[_epoch] = 0;
    }
  }

  function _mintUp(address _account, uint _epoch, uint _amount, uint _minShares) internal {
    uint shares = _shares(_amount, _minShares);
    purchasedOfUp[_epoch][_account] = purchasedOfUp[_epoch][_account].add(_amount);
    purchasedEpoch[_epoch] = purchasedEpoch[_epoch].add(_amount);
    totalSharesUp[_epoch] = totalSharesUp[_epoch].add(shares);
    sharesOfUp[_epoch][_account] = sharesOfUp[_epoch][_account].add(shares);
  }

  function _mintDown(address _account, uint _epoch, uint _amount, uint _minShares) internal {
    uint shares = _shares(_amount, _minShares);
    purchasedOfDown[_epoch][_account] = purchasedOfDown[_epoch][_account].add(_amount);
    purchasedEpoch[_epoch] = purchasedEpoch[_epoch].add(_amount);
    totalSharesDown[_epoch] = totalSharesDown[_epoch].add(shares);
    sharesOfDown[_epoch][_account] = sharesOfDown[_epoch][_account].add(shares);
  }

  function _shares(uint _amount, uint _minShares) internal view returns(uint) {
    uint shares = _amount;
    require(shares > _minShares, "UpDownMarket: shares > _minShares");
    return shares;
  }

  function _burnUp(address _account, uint _epoch, uint _amount) internal {
    totalSharesUp[_epoch] = totalSharesUp[_epoch].sub(_amount);
    sharesOfUp[_epoch][_account] = sharesOfUp[_epoch][_account].sub(_amount);
  }

  function _burnDown(address _account, uint _epoch, uint _amount) internal {
    totalSharesDown[_epoch] = totalSharesDown[_epoch].sub(_amount);
    sharesOfDown[_epoch][_account] = sharesOfDown[_epoch][_account].sub(_amount);
  }

  function _burnAll(address _account, uint _epoch) internal {
    _burnUp(_account, _epoch, sharesOfUp[_epoch][_account]);
    _burnDown(_account, _epoch, sharesOfDown[_epoch][_account]);
  }

  function _sendEth(address _recipient, uint _epoch, uint _amount) internal {
    purchasedEpoch[_epoch] = purchasedEpoch[_epoch].sub(_amount);
    address(_recipient).call { value: _amount } (new bytes(0));
  }
}