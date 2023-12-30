/**

  Source code of Opium Protocol Oracle
  Web https://opium.network
  Telegram https://t.me/opium_network
  Twitter https://twitter.com/opium_network

 */

// File: LICENSE

/**

The software and documentation available in this repository (the "Software") is protected by copyright law and accessible pursuant to the license set forth below. Copyright © 2020 Blockeys BV. All rights reserved.

Permission is hereby granted, free of charge, to any person or organization obtaining the Software (the “Licensee”) to privately study, review, and analyze the Software. Licensee shall not use the Software for any other purpose. Licensee shall not modify, transfer, assign, share, or sub-license the Software or any derivative works of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/


// File: openzeppelin-solidity/contracts/GSN/Context.sol

pragma solidity ^0.5.0;

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

// File: openzeppelin-solidity/contracts/ownership/Ownable.sol

pragma solidity ^0.5.0;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
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
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
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

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// File: opium-contracts/contracts/Interface/IOracleId.sol

pragma solidity 0.5.16;

/// @title Opium.Interface.IOracleId contract is an interface that every oracleId should implement
interface IOracleId {
    /// @notice Requests data from `oracleId` one time
    /// @param timestamp uint256 Timestamp at which data are needed
    function fetchData(uint256 timestamp) external payable;

    /// @notice Requests data from `oracleId` multiple times
    /// @param timestamp uint256 Timestamp at which data are needed for the first time
    /// @param period uint256 Period in seconds between multiple timestamps
    /// @param times uint256 How many timestamps are requested
    function recursivelyFetchData(uint256 timestamp, uint256 period, uint256 times) external payable;

    /// @notice Requests and returns price in ETH for one request. This function could be called as `view` function. Oraclize API for price calculations restricts making this function as view.
    /// @return fetchPrice uint256 Price of one data request in ETH
    function calculateFetchPrice() external returns (uint256 fetchPrice);

    // Event with oracleId metadata JSON string (for DIB.ONE derivative explorer)
    event MetadataSet(string metadata);
}

// File: openzeppelin-solidity/contracts/utils/ReentrancyGuard.sol

pragma solidity ^0.5.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 *
 * _Since v2.5.0:_ this module is now much more gas efficient, given net gas
 * metering changes introduced in the Istanbul hardfork.
 */
contract ReentrancyGuard {
    bool private _notEntered;

    constructor () internal {
        // Storing an initial non-zero value makes deployment a bit more
        // expensive, but in exchange the refund on every call to nonReentrant
        // will be lower in amount. Since refunds are capped to a percetange of
        // the total transaction's gas, it is best to keep them low in cases
        // like this one, to increase the likelihood of the full refund coming
        // into effect.
        _notEntered = true;
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
        require(_notEntered, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _notEntered = false;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _notEntered = true;
    }
}

// File: openzeppelin-solidity/contracts/math/SafeMath.sol

pragma solidity ^0.5.0;

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

// File: opium-contracts/contracts/Errors/OracleAggregatorErrors.sol

pragma solidity 0.5.16;

contract OracleAggregatorErrors {
    string constant internal ERROR_ORACLE_AGGREGATOR_NOT_ENOUGH_ETHER = "ORACLE_AGGREGATOR:NOT_ENOUGH_ETHER";

    string constant internal ERROR_ORACLE_AGGREGATOR_QUERY_WAS_ALREADY_MADE = "ORACLE_AGGREGATOR:QUERY_WAS_ALREADY_MADE";

    string constant internal ERROR_ORACLE_AGGREGATOR_DATA_DOESNT_EXIST = "ORACLE_AGGREGATOR:DATA_DOESNT_EXIST";

    string constant internal ERROR_ORACLE_AGGREGATOR_DATA_ALREADY_EXIST = "ORACLE_AGGREGATOR:DATA_ALREADY_EXIST";
}

// File: opium-contracts/contracts/OracleAggregator.sol

pragma solidity 0.5.16;





/// @title Opium.OracleAggregator contract requests and caches the data from `oracleId`s and provides them to the Core for positions execution
contract OracleAggregator is OracleAggregatorErrors, ReentrancyGuard {
    using SafeMath for uint256;

    // Storage for the `oracleId` results
    // dataCache[oracleId][timestamp] => data
    mapping (address => mapping(uint256 => uint256)) public dataCache;

    // Flags whether data were provided
    // dataExist[oracleId][timestamp] => bool
    mapping (address => mapping(uint256 => bool)) public dataExist;

    // Flags whether data were requested
    // dataRequested[oracleId][timestamp] => bool
    mapping (address => mapping(uint256 => bool)) public dataRequested;

    // MODIFIERS

    /// @notice Checks whether enough ETH were provided withing data request to proceed
    /// @param oracleId address Address of the `oracleId` smart contract
    /// @param times uint256 How many times the `oracleId` is being requested
    modifier enoughEtherProvided(address oracleId, uint256 times) {
        // Calling Opium.IOracleId function to get the data fetch price per one request
        uint256 oneTimePrice = calculateFetchPrice(oracleId);

        // Checking if enough ether was provided for `times` amount of requests
        require(msg.value >= oneTimePrice.mul(times), ERROR_ORACLE_AGGREGATOR_NOT_ENOUGH_ETHER);
        _;
    }

    // PUBLIC FUNCTIONS

    /// @notice Requests data from `oracleId` one time
    /// @param oracleId address Address of the `oracleId` smart contract
    /// @param timestamp uint256 Timestamp at which data are needed
    function fetchData(address oracleId, uint256 timestamp) public payable nonReentrant enoughEtherProvided(oracleId, 1) {
        // Check if was not requested before and mark as requested
        _registerQuery(oracleId, timestamp);

        // Call the `oracleId` contract and transfer ETH
        IOracleId(oracleId).fetchData.value(msg.value)(timestamp);
    }

    /// @notice Requests data from `oracleId` multiple times
    /// @param oracleId address Address of the `oracleId` smart contract
    /// @param timestamp uint256 Timestamp at which data are needed for the first time
    /// @param period uint256 Period in seconds between multiple timestamps
    /// @param times uint256 How many timestamps are requested
    function recursivelyFetchData(address oracleId, uint256 timestamp, uint256 period, uint256 times) public payable nonReentrant enoughEtherProvided(oracleId, times) {
        // Check if was not requested before and mark as requested in loop for each timestamp
        for (uint256 i = 0; i < times; i++) {	
            _registerQuery(oracleId, timestamp + period * i);
        }

        // Call the `oracleId` contract and transfer ETH
        IOracleId(oracleId).recursivelyFetchData.value(msg.value)(timestamp, period, times);
    }

    /// @notice Receives and caches data from `msg.sender`
    /// @param timestamp uint256 Timestamp of data
    /// @param data uint256 Data itself
    function __callback(uint256 timestamp, uint256 data) public {
        // Don't allow to push data twice
        require(!dataExist[msg.sender][timestamp], ERROR_ORACLE_AGGREGATOR_DATA_ALREADY_EXIST);

        // Saving data
        dataCache[msg.sender][timestamp] = data;

        // Flagging that data were received
        dataExist[msg.sender][timestamp] = true;
    }

    /// @notice Requests and returns price in ETH for one request. This function could be called as `view` function. Oraclize API for price calculations restricts making this function as view.
    /// @param oracleId address Address of the `oracleId` smart contract
    /// @return fetchPrice uint256 Price of one data request in ETH
    function calculateFetchPrice(address oracleId) public returns(uint256 fetchPrice) {
        fetchPrice = IOracleId(oracleId).calculateFetchPrice();
    }

    // PRIVATE FUNCTIONS

    /// @notice Checks if data was not requested and provided before and marks as requested
    /// @param oracleId address Address of the `oracleId` smart contract
    /// @param timestamp uint256 Timestamp at which data are requested
    function _registerQuery(address oracleId, uint256 timestamp) private {
        // Check if data was not requested and provided yet
        require(!dataRequested[oracleId][timestamp] && !dataExist[oracleId][timestamp], ERROR_ORACLE_AGGREGATOR_QUERY_WAS_ALREADY_MADE);

        // Mark as requested
        dataRequested[oracleId][timestamp] = true;	
    }

    // VIEW FUNCTIONS

    /// @notice Returns cached data if they exist, or reverts with an error
    /// @param oracleId address Address of the `oracleId` smart contract
    /// @param timestamp uint256 Timestamp at which data were requested
    /// @return dataResult uint256 Cached data provided by `oracleId`
    function getData(address oracleId, uint256 timestamp) public view returns(uint256 dataResult) {
        // Check if Opium.OracleAggregator has data
        require(hasData(oracleId, timestamp), ERROR_ORACLE_AGGREGATOR_DATA_DOESNT_EXIST);

        // Return cached data
        dataResult = dataCache[oracleId][timestamp];
    }

    /// @notice Getter for dataExist mapping
    /// @param oracleId address Address of the `oracleId` smart contract
    /// @param timestamp uint256 Timestamp at which data were requested
    /// @param result bool Returns whether data were provided already
    function hasData(address oracleId, uint256 timestamp) public view returns(bool result) {
        return dataExist[oracleId][timestamp];
    }
}

// File: contracts/oracles/aave/CreditDelegationAaveOracleId.sol

pragma solidity 0.5.16;




interface AaveLendingPool {
  function getUserReserveData(address _reserve, address _user)
    external
    view
    returns (
      uint256 currentATokenBalance,
      uint256 currentBorrowBalance,
      uint256 principalBorrowBalance,
      uint256 borrowRateMode,
      uint256 borrowRate,
      uint256 liquidityRate,
      uint256 originationFee,
      uint256 variableBorrowIndex,
      uint256 lastUpdateTimestamp,
      bool usageAsCollateralEnabled
  );
}

contract CreditDelegationAaveOracleId is IOracleId, Ownable {
  using SafeMath for uint256;

  event Requested(bytes32 indexed queryId, uint256 indexed timestamp);
  event Provided(bytes32 indexed queryId, uint256 indexed timestamp, uint256 result);

  mapping (bytes32 => uint256) public pendingQueries;

  // Opium
  OracleAggregator public oracleAggregator;

  // Credit Delegation
  AaveLendingPool public aaveLendingPool;
  address public wBTC;
  address public creditVault;

  // Governance
  uint256 public EMERGENCY_PERIOD;

  constructor(AaveLendingPool _aaveLendingPool, address _wBTC, address _creditVault, OracleAggregator _oracleAggregator, uint256 _emergencyPeriod) public {
    aaveLendingPool = _aaveLendingPool;
    wBTC = _wBTC;
    creditVault = _creditVault;

    oracleAggregator = _oracleAggregator;

    EMERGENCY_PERIOD = _emergencyPeriod;
    /*
    {
      "author": "Opium.Team",
      "description": "AAVE Credit Delegation Oracle",
      "asset": "AAVE-CREDIT-DELEGATION",
      "type": "onchain",
      "source": "aave",
      "logic": "none",
      "path": "getUserReserveData()"
    }
    */
    emit MetadataSet("{\"author\":\"Opium.Team\",\"description\":\"AAVE Credit Delegation Oracle\",\"asset\":\"AAVE-CREDIT-DELEGATION\",\"type\":\"onchain\",\"source\":\"aave\",\"logic\":\"none\",\"path\":\"getUserReserveData()\"}");
  }

  /** OPIUM */
  function fetchData(uint256 _timestamp) external payable {
    require(_timestamp > 0, "Timestamp must be nonzero");

    bytes32 queryId = keccak256(abi.encodePacked(address(this), _timestamp));
    pendingQueries[queryId] = _timestamp;
    emit Requested(queryId, _timestamp);
  }

  function recursivelyFetchData(uint256 _timestamp, uint256 _period, uint256 _times) external payable {
    require(_timestamp > 0, "Timestamp must be nonzero");

    for (uint256 i = 0; i < _times; i++) {
      uint256 moment = _timestamp + _period * i;
      bytes32 queryId = keccak256(abi.encodePacked(address(this), moment));
      pendingQueries[queryId] = moment;
      emit Requested(queryId, moment);
    }
  }

  function calculateFetchPrice() external returns (uint256) {
    return 0;
  }
  
  function _callback(bytes32 _queryId) public {
    uint256 timestamp = pendingQueries[_queryId];
    require(
      !oracleAggregator.hasData(address(this), timestamp) &&
      timestamp < now,
      "Only when no data and after timestamp allowed"
    );

    uint256 result = getPrincipalBorrowBalance();
    oracleAggregator.__callback(timestamp, result);

    emit Provided(_queryId, timestamp, result);
  }

  /** AAVE */
  /**
    @notice Returns principalBorrowBalance
   */
  function getPrincipalBorrowBalance() public view returns (uint256) {
    (,,
      uint256 principalBorrowBalance,
      ,,,,,,
    ) = aaveLendingPool.getUserReserveData(wBTC, creditVault);
    return principalBorrowBalance;
  }

  /** GOVERNANCE */
  /** 
    Emergency callback allows to push data manually in case EMERGENCY_PERIOD elapsed and no data were provided
   */
  function emergencyCallback(bytes32 _queryId, uint256 _result) public onlyOwner {
    uint256 timestamp = pendingQueries[_queryId];
    require(
      !oracleAggregator.hasData(address(this), timestamp) &&
      timestamp + EMERGENCY_PERIOD  < now,
      "Only when no data and after emergency period allowed"
    );

    oracleAggregator.__callback(timestamp, _result);

    emit Provided(_queryId, timestamp, _result);
  }

  function setEmergencyPeriod(uint256 _emergencyPeriod) public onlyOwner {
    EMERGENCY_PERIOD = _emergencyPeriod;
  }
}