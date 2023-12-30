
// File: @openzeppelin/contracts-ethereum-package/contracts/Initializable.sol

pragma solidity >=0.4.24 <0.7.0;


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
    address self = address(this);
    uint256 cs;
    assembly { cs := extcodesize(self) }
    return cs == 0;
  }

  // Reserved storage space to allow for layout changes in the future.
  uint256[50] private ______gap;
}

// File: @openzeppelin/contracts-ethereum-package/contracts/GSN/Context.sol

pragma solidity ^0.6.0;


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
contract ContextUpgradeSafe is Initializable {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.

    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {


    }


    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }

    uint256[50] private __gap;
}

// File: @openzeppelin/contracts-ethereum-package/contracts/access/Ownable.sol

pragma solidity ^0.6.0;


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
contract OwnableUpgradeSafe is Initializable, ContextUpgradeSafe {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */

    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {


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

    uint256[49] private __gap;
}

// File: contracts/Reputation.sol

// : GPL-3.0
pragma solidity 0.6.12;



/**
 * @title Reputation system
 * @dev A DAO has Reputation System which allows peers to rate other peers in order to build trust .
 * A reputation is use to assign influence measure to a DAO'S peers.
 * Reputation is similar to regular tokens but with one crucial difference: It is non-transferable.
 * The Reputation contract maintain a map of address to reputation value.
 * It provides an onlyOwner functions to mint and burn reputation _to (or _from) a specific address.
 */
contract Reputation is OwnableUpgradeSafe {

    uint8 public decimals = 18;             //Number of decimals of the smallest unit
    // Event indicating minting of reputation to an address.
    event Mint(address indexed _to, uint256 _amount);
    // Event indicating burning of reputation for an address.
    event Burn(address indexed _from, uint256 _amount);
    uint256 constant private ZERO_HALF_256 =  0xffffffffffffffffffffffffffffffff;

      /// @dev `Checkpoint` is the structure that attaches a block number to a
      ///  given value, the block number attached is the one that last changed the
      ///  value
      //Checkpoint is uint256 :
      // bits 0-127 `fromBlock` is the block number that the value was generated from
      // bits 128-255 `value` is the amount of reputation at a specific block number

      // `balances` is the map that tracks the balance of each address, in this
      //  contract when the balance changes the block number that the change
      //  occurred is also included in the map
    mapping (address => uint256[]) public balances;

      // Tracks the history of the `totalSupply` of the reputation
    uint256[] public totalSupplyHistory;

    /// @notice Generates `_amount` reputation that are assigned to `_owner`
    /// @param _user The address that will be assigned the new reputation
    /// @param _amount The quantity of reputation generated
    /// @return True if the reputation are generated correctly
    function mint(address _user, uint256 _amount) external onlyOwner returns (bool) {
        uint256 curTotalSupply = totalSupply();
        require(curTotalSupply + _amount >= curTotalSupply, "total supply overflow"); // Check for overflow
        uint256 previousBalanceTo = balanceOf(_user);
        require(previousBalanceTo + _amount >= previousBalanceTo, "balace overflow"); // Check for overflow
        updateValueAtNow(totalSupplyHistory, curTotalSupply + _amount);
        updateValueAtNow(balances[_user], previousBalanceTo + _amount);
        emit Mint(_user, _amount);
        return true;
    }

    /// @notice Burns `_amount` reputation from `_owner`
    /// @param _user The address that will lose the reputation
    /// @param _amount The quantity of reputation to burn
    /// @return True if the reputation are burned correctly
    function burn(address _user, uint256 _amount) external onlyOwner returns (bool) {
        uint256 curTotalSupply = totalSupply();
        uint256 amountBurned = _amount;
        uint256 previousBalanceFrom = balanceOf(_user);
        if (previousBalanceFrom < amountBurned) {
            amountBurned = previousBalanceFrom;
        }
        updateValueAtNow(totalSupplyHistory, curTotalSupply - amountBurned);
        updateValueAtNow(balances[_user], previousBalanceFrom - amountBurned);
        emit Burn(_user, amountBurned);
        return true;
    }

    /**
    * @dev initialize
    */
    function initialize(address _owner)
    public
    initializer {
        __Ownable_init_unchained();
        transferOwnership(_owner);
    }

    /// @dev This function makes it easy to get the total number of reputation
    /// @return The total number of reputation
    function totalSupply() public view returns (uint256) {
        return totalSupplyAt(block.number);
    }

  ////////////////
  // Query balance and totalSupply in History
  ////////////////
    /**
    * @dev return the reputation amount of a given owner
    * @param _owner an address of the owner which we want to get his reputation
    */
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balanceOfAt(_owner, block.number);
    }

      /// @dev Queries the balance of `_owner` at a specific `_blockNumber`
      /// @param _owner The address from which the balance will be retrieved
      /// @param _blockNumber The block number when the balance is queried
      /// @return The balance at `_blockNumber`
    function balanceOfAt(address _owner, uint256 _blockNumber)
    public view returns (uint256)
    {
        if ((balances[_owner].length == 0) || (uint128(balances[_owner][0]) > _blockNumber)) {
            return 0;
          // This will return the expected balance during normal situations
        } else {
            return getValueAt(balances[_owner], _blockNumber);
        }
    }

      /// @notice Total amount of reputation at a specific `_blockNumber`.
      /// @param _blockNumber The block number when the totalSupply is queried
      /// @return The total amount of reputation at `_blockNumber`
    function totalSupplyAt(uint256 _blockNumber) public view returns(uint256) {
        if ((totalSupplyHistory.length == 0) || (uint128(totalSupplyHistory[0]) > _blockNumber)) {
            return 0;
          // This will return the expected totalSupply during normal situations
        } else {
            return getValueAt(totalSupplyHistory, _blockNumber);
        }
    }

  ////////////////
  // Internal helper functions to query and set a value in a snapshot array
  ////////////////
      /// @dev `getValueAt` retrieves the number of reputation at a given block number
      /// @param checkpoints The history of values being queried
      /// @param _block The block number to retrieve the value at
      /// @return The number of reputation being queried
    function getValueAt(uint256[] storage checkpoints, uint256 _block) internal view returns (uint256) {
        if (checkpoints.length == 0) {
            return 0;
        }

          // Shortcut for the actual value
        if (_block >= uint128(checkpoints[checkpoints.length-1])) {
            return checkpoints[checkpoints.length-1]>>128;
        }
        if (_block < uint128(checkpoints[0])) {
            return 0;
        }

          // Binary search of the value in the array
        uint256 min = 0;
        uint256 max = checkpoints.length-1;
        while (max > min) {
            uint256 mid = (max + min + 1) / 2;
            if (uint128(checkpoints[mid]) <= _block) {
                min = mid;
            } else {
                max = mid-1;
            }
        }
        return checkpoints[min]>>128;
    }

      /// @dev `updateValueAtNow` used to update the `balances` map and the
      ///  `totalSupplyHistory`
      /// @param checkpoints The history of data being updated
      /// @param _value The new number of reputation
    function updateValueAtNow(uint256[] storage checkpoints, uint256 _value) internal {
        require(uint128(_value) == _value, "reputation overflow"); //check value is in the 128 bits bounderies
        if ((checkpoints.length == 0) || (uint128(checkpoints[checkpoints.length - 1]) < block.number)) {
            checkpoints.push(uint256(uint128(block.number)) | _value<<128);
        } else {
            checkpoints[checkpoints.length-1] =
            uint256((checkpoints[checkpoints.length-1] & uint256(ZERO_HALF_256)) | (_value<<128));
        }
    }
}
