
// File: contracts/interface/ICash.sol

pragma solidity >=0.4.24;


interface ICash {
    function claimDividends(address account) external returns (uint256);

    function transfer(address to, uint256 value) external returns(bool);
    function transferFrom(address from, address to, uint256 value) external returns(bool);
    function balanceOf(address who) external view returns(uint256);
    function allowance(address owner_, address spender) external view returns(uint256);
    function approve(address spender, uint256 value) external returns (bool);
    function increaseAllowance(address spender, uint256 addedValue) external returns (bool);
    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool);
    function totalSupply() external view returns (uint256);
    function rebase(uint256 epoch, int256 supplyDelta) external returns (uint256);
    function redeemedShare(address account) external view returns (uint256);
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

// File: openzeppelin-eth/contracts/utils/ReentrancyGuard.sol

pragma solidity ^0.4.24;


/**
 * @title Helps contracts guard against reentrancy attacks.
 * @author Remco Bloemen <remco@2π.com>, Eenae <alexey@mixbytes.io>
 * @dev If you mark a function `nonReentrant`, you should also
 * mark it `external`.
 */
contract ReentrancyGuard is Initializable {

  /// @dev counter to allow mutex lock with only one SSTORE operation
  uint256 private _guardCounter;

  function initialize() public initializer {
    _guardCounter = 1;
  }

  /**
   * @dev Prevents a contract from calling itself, directly or indirectly.
   * If you mark a function `nonReentrant`, you should also
   * mark it `external`. Calling one `nonReentrant` function from
   * another is not supported. Instead, you can implement a
   * `private` function doing the actual work, and an `external`
   * wrapper marked as `nonReentrant`.
   */
  modifier nonReentrant() {
    _guardCounter += 1;
    uint256 localCounter = _guardCounter;
    _;
    require(localCounter == _guardCounter);
  }

  uint256[50] private ______gap;
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

// File: contracts/usd/stake.sol

pragma solidity >=0.4.24;






contract stakingUSDx is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeMathInt for int256;

    // eslint-ignore
    ICash public Dollars;

    struct Stake {
        uint256 lastDollarPoints;   // variable to keep track of pending payouts
        uint256 stakingSeconds;     // when user started staking
        uint256 stakingAmount;      // how much user deposited in USDx
        uint256 unstakingSeconds;   // when user starts to unstake
        uint256 stakingStatus;      // 0 = unstaked, 1 = staked, 2 = commit to unstake
    }

    address timelock;
    uint256 public totalStaked;                                 // value that tracks the total amount of USDx staked
    uint256 public totalCommitted;                              // value that tracks the total amount of USDx committed to unstake
    uint256 public totalDollarPoints;                           // variable for keeping track of payouts
    uint256 public stakingMinimumSeconds;                       // minimum amount of allocated staking time per user
    mapping (address => Stake) public userStake;
    uint256 public coolDownPeriodSeconds;                       // how long it takes for a user to get paid their money back
    uint256 public constant POINT_MULTIPLIER = 10 ** 18;

    function initialize(address owner_, address dollar_, address timelock_) public initializer {
        Ownable.initialize(owner_);
        ReentrancyGuard.initialize();
        Dollars = ICash(dollar_);

        timelock = timelock_;
        stakingMinimumSeconds = 432000;                         // 432000 seconds = 5 days
        coolDownPeriodSeconds = 432000;                         // 5 days for getting out principal
    }

    function changeStakingMinimumSeconds(uint256 seconds_) external {
        require(msg.sender == timelock, "unauthorized");
        stakingMinimumSeconds = seconds_;
    }

    function changeCoolDownSeconds(uint256 seconds_) external {
        require(msg.sender == timelock, "unauthorized");
        coolDownPeriodSeconds = seconds_;
    }

    // make sure to add USD to this contract during rebase
    function addRebaseFunds(uint256 newUsdAmount) external {
        require(msg.sender == address(Dollars), "unauthorized");
        totalDollarPoints += newUsdAmount.mul(POINT_MULTIPLIER).div(totalStaked);
    }

    function stake(uint256 amount) external updateAccount(msg.sender) {
        require(userStake[msg.sender].stakingStatus != 2, "cannot stake while committed");
        require(amount != 0, "invalid stake amount");
        require(amount <= Dollars.balanceOf(msg.sender), "insufficient balance");
        require(Dollars.transferFrom(msg.sender, address(this), amount), "staking failed");

        userStake[msg.sender].stakingSeconds = now;
        userStake[msg.sender].stakingAmount += amount;
        totalStaked += amount;
        userStake[msg.sender].stakingStatus = 1;
    }

    function commitUnstake() external updateAccount(msg.sender) {
        require(userStake[msg.sender].stakingSeconds + stakingMinimumSeconds < now, "minimum time unmet");
        require(userStake[msg.sender].stakingStatus == 1, "user must be staked first");

        userStake[msg.sender].stakingStatus = 2;
        userStake[msg.sender].unstakingSeconds = now;
        totalStaked -= userStake[msg.sender].stakingAmount; // remove staked from pool for rewards
        totalCommitted += userStake[msg.sender].stakingAmount;
    }

    function unstake() external updateAccount(msg.sender) {
        require(userStake[msg.sender].stakingStatus == 2, "user must commit to unstaking first");
        require(userStake[msg.sender].unstakingSeconds + coolDownPeriodSeconds < now, "minimum time unmet");

        userStake[msg.sender].stakingStatus = 0;
        require(Dollars.transfer(msg.sender, userStake[msg.sender].stakingAmount), "unstaking failed");
        totalCommitted -= userStake[msg.sender].stakingAmount;

        userStake[msg.sender].stakingAmount = 0;
    }

    function pendingReward(address user_) public view returns (uint256) {
        if (totalDollarPoints > userStake[user_].lastDollarPoints && userStake[user_].stakingStatus == 1) {
            uint256 newDividendPoints = totalDollarPoints.sub(userStake[user_].lastDollarPoints);
            uint256 owedDollars = (userStake[user_].stakingAmount).mul(newDividendPoints).div(POINT_MULTIPLIER);

            return owedDollars > Dollars.balanceOf(address(this)) ? Dollars.balanceOf(address(this)).div(2) : owedDollars;
        } else {
            return 0;
        }
    }

    function claimReward(address user_) public updateAccount(user_) {
        uint256 reward = pendingReward(user_);
        if (reward > 0) require(Dollars.transfer(user_, reward), "claiming reward failed");

        userStake[user_].lastDollarPoints = totalDollarPoints;
    }
 
    modifier updateAccount(address account) {
        Dollars.claimDividends(account);
        claimReward(account);
        _;
    }
}
