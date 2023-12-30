// SPDX-License-Identifier: none

pragma solidity ^0.6.0;


// 
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

// 
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

// 
/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies in extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
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
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

interface IWageSyncer {
    
    /**
     * @dev Event emitted after a successful sync.
     */ 
    event WageSync();
    /**
     * @dev Event emitted when adding a new trading pair.
     * @param pairAddress the pair's address
     * @param callData data needed to perform the low level call
     */ 
    event PairAdded(address pairAddress, bytes callData);
    /**
     * @dev Event emitted when removing a trading pair.
     * @param pairAddress the pair's address
     */ 
    event PairRemoved(address pairAddress);
    
     /**
     * @dev The sync function. Called by Wage's contract after each rebase.
     * This function has been designed to support future trading pairs on different dexes.
     * We are sending a low level function call to apply the same syncing logic to every pair
     */ 
    function sync() external;
    /**
     * @dev Adds a pair to the pairs array. Can only be called  by the owner
     * @param pairAddress the pair's address.
     * @param data the data to send when calling the low level function `functionCall`
     */ 
    function addPair(address pairAddress, bytes calldata data) external;
    /**
     * @dev Removes a pair from tthe pairs array. Can  only be called by the owner.
     * @param pair the pair's address
     */ 
    function removePair(address pair) external;
    
}

//The WageSyncer contract.
//Syncs trading pairs across different exchanges.
contract WageSyncer is IWageSyncer, Ownable {
    
    using Address for address;
    
    /**
     * @dev Event emitted after a successful sync.
     */ 
    event WageSync();
    /**
     * @dev Event emitted when adding a new trading pair.
     * @param pairAddress the pair's address
     * @param callData data needed to perform the low level call
     */ 
    event PairAdded(address indexed pairAddress, bytes callData);
    /**
     * @dev Event emitted when removing a trading pair.
     * @param pairAddress the pair's address
     */ 
    event PairRemoved(address indexed pairAddress);
    
    /**
     * @dev Struct that holds the data needed to sync a trading pair.
     * @field pairAddress the pair's address
     * @field syncData the data needed to sync the pair.
     */
    struct Pair {
        address pairAddress;
        bytes syncData;
    }
    
    Pair[] public pairs;
    
    /**
     * @dev The sync function. Called by Wage's contract after each rebase.
     * This function has been designed to support future trading pairs on different dexes.
     * We are sending a low level function call to apply the same syncing logic to every pair
     */ 
    function sync() external override {
        for (uint i = 0; i < pairs.length; i ++) {
            pairs[i].pairAddress.functionCall(pairs[i].syncData);
        }
        
        emit WageSync();
    }
    
    
    /**
     * @dev Adds a pair to the pairs array. Can only be called  by the owner
     * @param addr the pair's address.
     * @param syncData the data to send when calling the low level function `functionCall`
     */ 
    function addPair(address addr, bytes calldata syncData) external override onlyOwner {
        Pair storage pair = pairs.push();
        
        pair.pairAddress = addr;
        pair.syncData = syncData;
        
        emit PairAdded(addr, syncData);
    }    
    
    
    /**
     * @dev Removes a pair from tthe pairs array. Can  only be called by the owner.
     * @param pairAddress the pair's address
     */ 
    function removePair(address pairAddress) external override onlyOwner {
        (bool res, uint256 index) = _findPair(pairAddress);
        
        require(res, "Pair not found");
        
        delete pairs[index];
        
        emit PairRemoved(pairAddress);
    }
    
    /**
     * @dev Finds a pair in the pairs array.
     * @param pair The pair to find
     * @return bool Whether the pair was found
     * @return uint256 The index of the pair if is present in the array, 0 if not
     */ 
    function _findPair(address pair) internal view returns (bool, uint256) {
        for (uint i = 0; i < pairs.length; i ++) {
            if (pairs[i].pairAddress == pair)
                return (true, i);
        }
        
        return (false, 0);
    }
    
}