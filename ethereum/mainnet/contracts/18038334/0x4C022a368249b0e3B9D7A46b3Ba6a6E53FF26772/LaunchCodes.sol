// File: contracts/ILaunchCodeErrors.sol


pragma solidity ^0.8.21;

contract ILaunchCodeErrors {
    // General errors
    error LCDMismatchedArrayLengths();
    error LCDQuantityMustBeGreaterThanZero();
    error LCDQueryForZeroAddress();

    // Token errors
    error LCDCannotUpdateLocksOnUnlockedOrStakedTokens();
    error LCDCanOnlyStakeUnlockedTokens();
    error LCDCanOnlyUnstakeStakedTokens();
    error LCDLockedToken();
    error LCDNotTokenOwnerOrApproved();
    error LCDNotTokenOwner();
    error LCDTokenNotFound();

    // Minting errors
    error LCDGlobalMintingLimitMet();
    error LCDIndividualMintingLimitMet();

    // Approval and transfer errors
    error LCDApproveCallerNotOwnerNorApproved();
    error LCDApproveToCaller();
    error LCDApproveToCurrentOwner();
    error LCDFundsTransferFailed();
    error LCDNoFundsToTransfer();
    error LCDTransferToNonERC721Receiver();

    // Class specific errors
    error LCDClassAlreadyArchived();
    error LCDClassAlreadyExists();
    error LCDClassNotFound();
    error LCDClassStillBackstopped();

    // Other errors
    error LCDBackstopEndInTheFuture();
    error LCDCannotAssignStakingLocks();
    error LCDInvalidPaidPrice();
}
// File: solidity-bits/contracts/Popcount.sol


/**
   _____       ___     ___ __           ____  _ __      
  / ___/____  / (_)___/ (_) /___  __   / __ )(_) /______
  \__ \/ __ \/ / / __  / / __/ / / /  / __  / / __/ ___/
 ___/ / /_/ / / / /_/ / / /_/ /_/ /  / /_/ / / /_(__  ) 
/____/\____/_/_/\__,_/_/\__/\__, /  /_____/_/\__/____/  
                           /____/                        

- npm: https://www.npmjs.com/package/solidity-bits
- github: https://github.com/estarriolvetch/solidity-bits

 */

pragma solidity ^0.8.0;

library Popcount {
    uint256 private constant m1 = 0x5555555555555555555555555555555555555555555555555555555555555555;
    uint256 private constant m2 = 0x3333333333333333333333333333333333333333333333333333333333333333;
    uint256 private constant m4 = 0x0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f;
    uint256 private constant h01 = 0x0101010101010101010101010101010101010101010101010101010101010101;

    function popcount256A(uint256 x) internal pure returns (uint256 count) {
        unchecked{
            for (count=0; x!=0; count++)
                x &= x - 1;
        }
    }

    function popcount256B(uint256 x) internal pure returns (uint256) {
        if (x == type(uint256).max) {
            return 256;
        }
        unchecked {
            x -= (x >> 1) & m1;             //put count of each 2 bits into those 2 bits
            x = (x & m2) + ((x >> 2) & m2); //put count of each 4 bits into those 4 bits 
            x = (x + (x >> 4)) & m4;        //put count of each 8 bits into those 8 bits 
            x = (x * h01) >> 248;  //returns left 8 bits of x + (x<<8) + (x<<16) + (x<<24) + ... 
        }
        return x;
    }
}
// File: solidity-bits/contracts/BitScan.sol


/**
   _____       ___     ___ __           ____  _ __      
  / ___/____  / (_)___/ (_) /___  __   / __ )(_) /______
  \__ \/ __ \/ / / __  / / __/ / / /  / __  / / __/ ___/
 ___/ / /_/ / / / /_/ / / /_/ /_/ /  / /_/ / / /_(__  ) 
/____/\____/_/_/\__,_/_/\__/\__, /  /_____/_/\__/____/  
                           /____/                        

- npm: https://www.npmjs.com/package/solidity-bits
- github: https://github.com/estarriolvetch/solidity-bits

 */

pragma solidity ^0.8.0;


library BitScan {
    uint256 constant private DEBRUIJN_256 = 0x818283848586878898a8b8c8d8e8f929395969799a9b9d9e9faaeb6bedeeff;
    bytes constant private LOOKUP_TABLE_256 = hex"0001020903110a19042112290b311a3905412245134d2a550c5d32651b6d3a7506264262237d468514804e8d2b95569d0d495ea533a966b11c886eb93bc176c9071727374353637324837e9b47af86c7155181ad4fd18ed32c9096db57d59ee30e2e4a6a5f92a6be3498aae067ddb2eb1d5989b56fd7baf33ca0c2ee77e5caf7ff0810182028303840444c545c646c7425617c847f8c949c48a4a8b087b8c0c816365272829aaec650acd0d28fdad4e22d6991bd97dfdcea58b4d6f29fede4f6fe0f1f2f3f4b5b6b607b8b93a3a7b7bf357199c5abcfd9e168bcdee9b3f1ecf5fd1e3e5a7a8aa2b670c4ced8bbe8f0f4fc3d79a1c3cde7effb78cce6facbf9f8";

    /**
        @dev Isolate the least significant set bit.
     */ 
    function isolateLS1B256(uint256 bb) pure internal returns (uint256) {
        require(bb > 0);
        unchecked {
            return bb & (0 - bb);
        }
    } 

    /**
        @dev Isolate the most significant set bit.
     */ 
    function isolateMS1B256(uint256 bb) pure internal returns (uint256) {
        require(bb > 0);
        unchecked {
            bb |= bb >> 128;
            bb |= bb >> 64;
            bb |= bb >> 32;
            bb |= bb >> 16;
            bb |= bb >> 8;
            bb |= bb >> 4;
            bb |= bb >> 2;
            bb |= bb >> 1;
            
            return (bb >> 1) + 1;
        }
    } 

    /**
        @dev Find the index of the lest significant set bit. (trailing zero count)
     */ 
    function bitScanForward256(uint256 bb) pure internal returns (uint8) {
        unchecked {
            return uint8(LOOKUP_TABLE_256[(isolateLS1B256(bb) * DEBRUIJN_256) >> 248]);
        }   
    }

    /**
        @dev Find the index of the most significant set bit.
     */ 
    function bitScanReverse256(uint256 bb) pure internal returns (uint8) {
        unchecked {
            return 255 - uint8(LOOKUP_TABLE_256[((isolateMS1B256(bb) * DEBRUIJN_256) >> 248)]);
        }   
    }

    function log2(uint256 bb) pure internal returns (uint8) {
        unchecked {
            return uint8(LOOKUP_TABLE_256[(isolateMS1B256(bb) * DEBRUIJN_256) >> 248]);
        } 
    }
}

// File: solidity-bits/contracts/BitMaps.sol


/**
   _____       ___     ___ __           ____  _ __      
  / ___/____  / (_)___/ (_) /___  __   / __ )(_) /______
  \__ \/ __ \/ / / __  / / __/ / / /  / __  / / __/ ___/
 ___/ / /_/ / / / /_/ / / /_/ /_/ /  / /_/ / / /_(__  ) 
/____/\____/_/_/\__,_/_/\__/\__, /  /_____/_/\__/____/  
                           /____/                        

- npm: https://www.npmjs.com/package/solidity-bits
- github: https://github.com/estarriolvetch/solidity-bits

 */
pragma solidity ^0.8.0;



/**
 * @dev This Library is a modified version of Openzeppelin's BitMaps library with extra features.
 *
 * 1. Functions of finding the index of the closest set bit from a given index are added.
 *    The indexing of each bucket is modifed to count from the MSB to the LSB instead of from the LSB to the MSB.
 *    The modification of indexing makes finding the closest previous set bit more efficient in gas usage.
 * 2. Setting and unsetting the bitmap consecutively.
 * 3. Accounting number of set bits within a given range.   
 *
*/

/**
 * @dev Library for managing uint256 to bool mapping in a compact and efficient way, providing the keys are sequential.
 * Largelly inspired by Uniswap's https://github.com/Uniswap/merkle-distributor/blob/master/contracts/MerkleDistributor.sol[merkle-distributor].
 */

library BitMaps {
    using BitScan for uint256;
    uint256 private constant MASK_INDEX_ZERO = (1 << 255);
    uint256 private constant MASK_FULL = type(uint256).max;

    struct BitMap {
        mapping(uint256 => uint256) _data;
    }

    /**
     * @dev Returns whether the bit at `index` is set.
     */
    function get(BitMap storage bitmap, uint256 index) internal view returns (bool) {
        uint256 bucket = index >> 8;
        uint256 mask = MASK_INDEX_ZERO >> (index & 0xff);
        return bitmap._data[bucket] & mask != 0;
    }

    /**
     * @dev Sets the bit at `index` to the boolean `value`.
     */
    function setTo(
        BitMap storage bitmap,
        uint256 index,
        bool value
    ) internal {
        if (value) {
            set(bitmap, index);
        } else {
            unset(bitmap, index);
        }
    }

    /**
     * @dev Sets the bit at `index`.
     */
    function set(BitMap storage bitmap, uint256 index) internal {
        uint256 bucket = index >> 8;
        uint256 mask = MASK_INDEX_ZERO >> (index & 0xff);
        bitmap._data[bucket] |= mask;
    }

    /**
     * @dev Unsets the bit at `index`.
     */
    function unset(BitMap storage bitmap, uint256 index) internal {
        uint256 bucket = index >> 8;
        uint256 mask = MASK_INDEX_ZERO >> (index & 0xff);
        bitmap._data[bucket] &= ~mask;
    }


    /**
     * @dev Consecutively sets `amount` of bits starting from the bit at `startIndex`.
     */    
    function setBatch(BitMap storage bitmap, uint256 startIndex, uint256 amount) internal {
        uint256 bucket = startIndex >> 8;

        uint256 bucketStartIndex = (startIndex & 0xff);

        unchecked {
            if(bucketStartIndex + amount < 256) {
                bitmap._data[bucket] |= MASK_FULL << (256 - amount) >> bucketStartIndex;
            } else {
                bitmap._data[bucket] |= MASK_FULL >> bucketStartIndex;
                amount -= (256 - bucketStartIndex);
                bucket++;

                while(amount > 256) {
                    bitmap._data[bucket] = MASK_FULL;
                    amount -= 256;
                    bucket++;
                }

                bitmap._data[bucket] |= MASK_FULL << (256 - amount);
            }
        }
    }


    /**
     * @dev Consecutively unsets `amount` of bits starting from the bit at `startIndex`.
     */    
    function unsetBatch(BitMap storage bitmap, uint256 startIndex, uint256 amount) internal {
        uint256 bucket = startIndex >> 8;

        uint256 bucketStartIndex = (startIndex & 0xff);

        unchecked {
            if(bucketStartIndex + amount < 256) {
                bitmap._data[bucket] &= ~(MASK_FULL << (256 - amount) >> bucketStartIndex);
            } else {
                bitmap._data[bucket] &= ~(MASK_FULL >> bucketStartIndex);
                amount -= (256 - bucketStartIndex);
                bucket++;

                while(amount > 256) {
                    bitmap._data[bucket] = 0;
                    amount -= 256;
                    bucket++;
                }

                bitmap._data[bucket] &= ~(MASK_FULL << (256 - amount));
            }
        }
    }

    /**
     * @dev Returns number of set bits within a range.
     */
    function popcountA(BitMap storage bitmap, uint256 startIndex, uint256 amount) internal view returns(uint256 count) {
        uint256 bucket = startIndex >> 8;

        uint256 bucketStartIndex = (startIndex & 0xff);

        unchecked {
            if(bucketStartIndex + amount < 256) {
                count +=  Popcount.popcount256A(
                    bitmap._data[bucket] & (MASK_FULL << (256 - amount) >> bucketStartIndex)
                );
            } else {
                count += Popcount.popcount256A(
                    bitmap._data[bucket] & (MASK_FULL >> bucketStartIndex)
                );
                amount -= (256 - bucketStartIndex);
                bucket++;

                while(amount > 256) {
                    count += Popcount.popcount256A(bitmap._data[bucket]);
                    amount -= 256;
                    bucket++;
                }
                count += Popcount.popcount256A(
                    bitmap._data[bucket] & (MASK_FULL << (256 - amount))
                );
            }
        }
    }

    /**
     * @dev Returns number of set bits within a range.
     */
    function popcountB(BitMap storage bitmap, uint256 startIndex, uint256 amount) internal view returns(uint256 count) {
        uint256 bucket = startIndex >> 8;

        uint256 bucketStartIndex = (startIndex & 0xff);

        unchecked {
            if(bucketStartIndex + amount < 256) {
                count +=  Popcount.popcount256B(
                    bitmap._data[bucket] & (MASK_FULL << (256 - amount) >> bucketStartIndex)
                );
            } else {
                count += Popcount.popcount256B(
                    bitmap._data[bucket] & (MASK_FULL >> bucketStartIndex)
                );
                amount -= (256 - bucketStartIndex);
                bucket++;

                while(amount > 256) {
                    count += Popcount.popcount256B(bitmap._data[bucket]);
                    amount -= 256;
                    bucket++;
                }
                count += Popcount.popcount256B(
                    bitmap._data[bucket] & (MASK_FULL << (256 - amount))
                );
            }
        }
    }


    /**
     * @dev Find the closest index of the set bit before `index`.
     */
    function scanForward(BitMap storage bitmap, uint256 index) internal view returns (uint256 setBitIndex) {
        uint256 bucket = index >> 8;

        // index within the bucket
        uint256 bucketIndex = (index & 0xff);

        // load a bitboard from the bitmap.
        uint256 bb = bitmap._data[bucket];

        // offset the bitboard to scan from `bucketIndex`.
        bb = bb >> (0xff ^ bucketIndex); // bb >> (255 - bucketIndex)
        
        if(bb > 0) {
            unchecked {
                setBitIndex = (bucket << 8) | (bucketIndex -  bb.bitScanForward256());    
            }
        } else {
            while(true) {
                require(bucket > 0, "BitMaps: The set bit before the index doesn't exist.");
                unchecked {
                    bucket--;
                }
                // No offset. Always scan from the least significiant bit now.
                bb = bitmap._data[bucket];
                
                if(bb > 0) {
                    unchecked {
                        setBitIndex = (bucket << 8) | (255 -  bb.bitScanForward256());
                        break;
                    }
                } 
            }
        }
    }

    function getBucket(BitMap storage bitmap, uint256 bucket) internal view returns (uint256) {
        return bitmap._data[bucket];
    }
}

// File: @openzeppelin/contracts/utils/Address.sol


// OpenZeppelin Contracts (last updated v4.9.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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
     *
     * Furthermore, `isContract` will also return true if the target contract within
     * the same transaction is already scheduled for destruction by `SELFDESTRUCT`,
     * which only has an effect at the end of a transaction.
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
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
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.8.0/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

// File: @openzeppelin/contracts/utils/math/SignedMath.sol


// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/SignedMath.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard signed math utilities missing in the Solidity language.
 */
library SignedMath {
    /**
     * @dev Returns the largest of two signed numbers.
     */
    function max(int256 a, int256 b) internal pure returns (int256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two signed numbers.
     */
    function min(int256 a, int256 b) internal pure returns (int256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two signed numbers without overflow.
     * The result is rounded towards zero.
     */
    function average(int256 a, int256 b) internal pure returns (int256) {
        // Formula from the book "Hacker's Delight"
        int256 x = (a & b) + ((a ^ b) >> 1);
        return x + (int256(uint256(x) >> 255) & (a ^ b));
    }

    /**
     * @dev Returns the absolute unsigned value of a signed value.
     */
    function abs(int256 n) internal pure returns (uint256) {
        unchecked {
            // must be unchecked in order to support `n = type(int256).min`
            return uint256(n >= 0 ? n : -n);
        }
    }
}

// File: @openzeppelin/contracts/utils/math/Math.sol


// OpenZeppelin Contracts (last updated v4.9.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(uint256 x, uint256 y, uint256 denominator) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                // Solidity will revert if denominator == 0, unlike the div opcode on its own.
                // The surrounding unchecked block does not change this fact.
                // See https://docs.soliditylang.org/en/latest/control-structures.html#checked-or-unchecked-arithmetic.
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1, "Math: mulDiv overflow");

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(uint256 x, uint256 y, uint256 denominator, Rounding rounding) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10 ** 64) {
                value /= 10 ** 64;
                result += 64;
            }
            if (value >= 10 ** 32) {
                value /= 10 ** 32;
                result += 32;
            }
            if (value >= 10 ** 16) {
                value /= 10 ** 16;
                result += 16;
            }
            if (value >= 10 ** 8) {
                value /= 10 ** 8;
                result += 8;
            }
            if (value >= 10 ** 4) {
                value /= 10 ** 4;
                result += 4;
            }
            if (value >= 10 ** 2) {
                value /= 10 ** 2;
                result += 2;
            }
            if (value >= 10 ** 1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10 ** result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 256, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result << 3) < value ? 1 : 0);
        }
    }
}

// File: @openzeppelin/contracts/utils/Strings.sol


// OpenZeppelin Contracts (last updated v4.9.0) (utils/Strings.sol)

pragma solidity ^0.8.0;



/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `int256` to its ASCII `string` decimal representation.
     */
    function toString(int256 value) internal pure returns (string memory) {
        return string(abi.encodePacked(value < 0 ? "-" : "", toString(SignedMath.abs(value))));
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, Math.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }

    /**
     * @dev Returns true if the two strings are equal.
     */
    function equal(string memory a, string memory b) internal pure returns (bool) {
        return keccak256(bytes(a)) == keccak256(bytes(b));
    }
}

// File: @openzeppelin/contracts/token/ERC721/IERC721Receiver.sol


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// File: @openzeppelin/contracts/utils/Context.sol


// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

pragma solidity ^0.8.0;


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
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File: @openzeppelin/contracts/security/Pausable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;


/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// File: contracts/Administrable.sol


pragma solidity ^0.8.21;



contract Administrable is Pausable, Ownable {
    error AdministrableCallerMustBeAdmin();
    error AdministrableAlreadyAnAdmin();
    error AdministrableNotAnAdmin();

    mapping(address => bool) private _admins;

    constructor(address[] memory _initialAdmins) {
        for (uint256 i = 0; i < _initialAdmins.length; i++) {
            _admins[_initialAdmins[i]] = true;
        }
    }

    function addAdminRights(address _newAdmin) external onlyOwner {
        if (_isAdmin(_newAdmin)) revert AdministrableAlreadyAnAdmin();
        _admins[_newAdmin] = true;
    }

    function revokeAdminRights(address _admin) external onlyOwner {
        if (!_isAdmin(_admin)) revert AdministrableNotAnAdmin();
        delete _admins[_admin];
    }

    function pause() public onlyAdmin {
        _pause();
    }

    function unpause() public onlyAdmin {
        _unpause();
    }

    function _isAdmin(address _user) internal view returns (bool){
        return _admins[_user];
    }

    modifier onlyAdmin(){
        if (!_admins[_msgSender()]) revert AdministrableCallerMustBeAdmin();
        _;
    }
}
// File: @openzeppelin/contracts/utils/introspection/IERC165.sol


// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// File: @openzeppelin/contracts/utils/introspection/ERC165.sol


// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;


/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// File: @openzeppelin/contracts/token/ERC721/IERC721.sol


// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;


/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// File: @openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;


/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// File: contracts/TokenDataBasedERC721Psi.sol

//SPDX-License-Identifier: MIT

/*
The MIT License (MIT)

Copyright (2023) ctor.xyz

ERC721Psi is an ERC721 compliant implementation designed for scalable and gas-efficient
on-chain application with built-in randomized metadata generation.

Inspired by AzukiZen's awesome ERC721A, ERC721Psi also provides batch minting at a fixed
gas cost. However, ERC721Psi manages to solve the scaling issue of token transfer through
the mathematical power of the de Bruijn sequence.

This software is provided under the MIT License and is free to use. For commercial
support/service regarding ERC721Psi, contact ctor.xyz.

Modifications to the ERC721Psi made by EAL-13 (contracted by the Launch Codes NFT creators):
- Enhanced custom control over on-chain token data.
- Introduced new token classes for better categorization and management.

For the original code:
- github: https://github.com/estarriolvetch/ERC721Psi
- npm: https://www.npmjs.com/package/erc721psi
*/

pragma solidity ^0.8.21;










contract TokenDataBasedERC721Psi is Context, ERC165, IERC721, IERC721Metadata, ILaunchCodeErrors {
    uint8 public constant NO_LOCK = 0;
    uint8 public constant PENDING_LOCK = 1;
    uint8 public constant STAKING_LOCK = 2;
    uint8 public constant FIRST_ADMIN_LOCK = 3;

    using Address for address;
    using Strings for uint256;
    using BitMaps for BitMaps.BitMap;

    BitMaps.BitMap private _batchHead;
    BitMaps.BitMap private _burnedToken;

    string private _name;
    string private _symbol;
    string private _metadataBaseURI;
    uint256 public totalMinted;
    uint256 public totalBurned;

    mapping(uint256 => address) private _tokenApprovals;
    mapping(address => mapping(address => bool)) private _operatorApprovals;
    mapping(uint256 => uint8) private _lockedTokens;
    mapping(uint256 => TokenData) private _tokenData;
    mapping(uint8 => Class) public classes;
    mapping(address => BalanceCounts) public individualCounts;

    struct Class {
        bool active;
        bool archived;
        uint32 mintedCount;
        uint32 mintingLimit;
        uint256 price;
        uint256 totalUnstakedHeldAssets;
        uint256 totalUnstakedHeldFunding;
        uint256 backstopEnd;
    }

    struct TokenData {
        uint8 classId;
        address owner;
        uint256 heldAssets;
        uint256 heldFunding;
    }

    struct BalanceCounts {
        uint256 balance;
        uint256 mintedCount;
    }

    constructor(string memory name_, string memory symbol_, string memory baseURI_) {
        _name = name_;
        _symbol = symbol_;
        _metadataBaseURI = baseURI_;
    }

    function _baseURI() internal view virtual returns (string memory) {
        return _metadataBaseURI;
    }

    function _setBaseURI(string memory baseURI) internal {
        _metadataBaseURI = baseURI;
    }

    function _nextTokenId() internal view virtual returns (uint256) {
        return totalMinted;
    }

    function _setTokenDataOf(uint256 tokenId, uint8 classId, uint256 heldAssets, uint256 heldFunding) internal virtual {
        _tokenData[tokenId].classId = classId;
        _tokenData[tokenId].heldAssets = heldAssets;
        _tokenData[tokenId].heldFunding = heldFunding;
    }

    function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(ERC165, IERC165)
    returns (bool)
    {
        return
        interfaceId == type(IERC721).interfaceId ||
        interfaceId == type(IERC721Metadata).interfaceId ||
        super.supportsInterface(interfaceId);
    }

    function tokenDataOf(uint256 tokenId) public view returns (TokenData memory) {
        TokenData memory data = _unfilteredTokenDataOf(tokenId);
        if (_isClassBackstopExpired(data.classId)) {
            return TokenData(data.classId, data.owner, 0, 0);
        }
        return data;
    }

    function _unfilteredTokenDataOf(uint256 tokenId) internal view virtual returns (TokenData memory) {
        if (!_exists(tokenId)) revert LCDTokenNotFound();
        (, uint256 tokenIdBatchHead) = _ownerAndBatchHeadOf(tokenId);
        return _tokenData[tokenIdBatchHead];
    }


    function balanceOf(address owner)
    public
    view
    virtual
    override
    returns (uint)
    {
        if (owner == address(0)) revert LCDQueryForZeroAddress();
        return individualCounts[owner].balance;
    }

    function ownerOf(uint256 tokenId)
    public
    view
    virtual
    override
    returns (address)
    {
        (address owner,) = _ownerAndBatchHeadOf(tokenId);
        return owner;
    }

    function _ownerAndBatchHeadOf(uint256 tokenId) internal view returns (address owner, uint256 tokenIdBatchHead){
        if (!_exists(tokenId)) revert LCDTokenNotFound();
        tokenIdBatchHead = _getBatchHead(tokenId);
        owner = _tokenData[tokenIdBatchHead].owner;
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert LCDTokenNotFound();
        return string(abi.encodePacked(_baseURI(), tokenId.toString()));
    }

    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ownerOf(tokenId);
        if (to == owner) revert LCDApproveToCurrentOwner();
        if (_msgSender() != owner && !isApprovedForAll(owner, _msgSender()))
            revert LCDApproveCallerNotOwnerNorApproved();
        _approve(to, tokenId);
    }

    function getApproved(uint256 tokenId)
    public
    view
    virtual
    override
    returns (address)
    {
        if (!_exists(tokenId)) revert LCDTokenNotFound();
        return _tokenApprovals[tokenId];
    }

    function setApprovalForAll(address operator, bool approved)
    public
    virtual
    override
    {
        if (operator == _msgSender()) revert LCDApproveToCaller();
        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    function isApprovedForAll(address owner, address operator)
    public
    view
    virtual
    override
    returns (bool)
    {
        return _operatorApprovals[owner][operator];
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        if (!_isApprovedOrOwner(_msgSender(), tokenId)) revert LCDNotTokenOwnerOrApproved();
        _transfer(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        if (!_isApprovedOrOwner(_msgSender(), tokenId)) revert LCDNotTokenOwnerOrApproved();
        _safeTransfer(from, to, tokenId, _data);
    }

    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        if (!_checkOnERC721Received(from, to, tokenId, 1, _data)) revert LCDTransferToNonERC721Receiver();
    }

    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return tokenId < _nextTokenId() && 0 <= tokenId && !_burnedToken.get(tokenId);
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId)
    internal
    view
    virtual
    returns (bool)
    {
        if (!_exists(tokenId)) revert LCDTokenNotFound();
        address owner = ownerOf(tokenId);
        return (spender == owner ||
        getApproved(tokenId) == spender ||
            isApprovedForAll(owner, spender));
    }

    function _safeMint(address to, uint256 quantity) internal virtual {
        _safeMint(to, quantity, "");
    }


    function _safeMint(
        address to,
        uint256 quantity,
        bytes memory _data
    ) internal virtual {
        uint256 nextTokenId = _nextTokenId();
        _mint(to, quantity);
        if (!_checkOnERC721Received(address(0), to, nextTokenId, quantity, _data)) revert LCDTransferToNonERC721Receiver();
    }

    function _mint(
        address to,
        uint256 quantity
    ) internal virtual {
        uint256 nextTokenId = _nextTokenId();

        if (quantity == 0) revert LCDQuantityMustBeGreaterThanZero();
        if (to == address(0)) revert LCDQueryForZeroAddress();

        _beforeTokenTransfers(address(0), to, nextTokenId, quantity);
        totalMinted += quantity;
        individualCounts[to].balance += quantity;
        individualCounts[to].mintedCount += quantity;
        _tokenData[nextTokenId] = TokenData(0, to, 0, 0);
        _batchHead.set(nextTokenId);

        for (uint256 tokenId = nextTokenId; tokenId < nextTokenId + quantity; tokenId++) {
            emit Transfer(address(0), to, tokenId);
        }
    }

    function _burn(uint256 tokenId) internal virtual {
        address from = ownerOf(tokenId);
        _beforeTokenTransfers(from, address(0), tokenId, 1);

        _burnedToken.set(tokenId);
        individualCounts[from].balance -= 1;
        totalBurned += 1;

        _afterTokenTransfers(from, address(0), tokenId, 1);
    }

    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        (address owner, uint256 tokenIdBatchHead) = _ownerAndBatchHeadOf(tokenId);

        if (owner != from) revert LCDNotTokenOwner();
        if (to == address(0)) revert LCDQueryForZeroAddress();

        _beforeTokenTransfers(from, to, tokenId, 1);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        uint256 subsequentTokenId = tokenId + 1;

        if (!_batchHead.get(subsequentTokenId) &&
        subsequentTokenId < _nextTokenId()
        ) {
            _tokenData[subsequentTokenId].owner = from;
            _batchHead.set(subsequentTokenId);
        }

        _lockedTokens[tokenId] = PENDING_LOCK;
        _tokenData[tokenId].owner = to;
        if (tokenId != tokenIdBatchHead) {
            _batchHead.set(tokenId);
        }

        emit Transfer(from, to, tokenId);

        _afterTokenTransfers(from, to, tokenId, 1);
    }

    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ownerOf(tokenId), to, tokenId);
    }

    function _checkOnERC721Received(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity,
        bytes memory _data
    ) private returns (bool r) {
        if (to.isContract()) {
            r = true;
            for (uint256 tokenId = startTokenId; tokenId < startTokenId + quantity; tokenId++) {
                try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                    r = r && retval == IERC721Receiver.onERC721Received.selector;
                } catch (bytes memory reason) {
                    if (reason.length == 0) {
                        revert LCDTransferToNonERC721Receiver();
                    } else {
                        assembly {
                            revert(add(32, reason), mload(reason))
                        }
                    }
                }
            }
            return r;
        } else {
            return true;
        }
    }

    function _getBatchHead(uint256 tokenId) internal view returns (uint256 tokenIdBatchHead) {
        tokenIdBatchHead = _batchHead.scanForward(tokenId);
    }

    function getBatchHeadTest(uint256 tokenId) public virtual view returns (uint256) {
        return _getBatchHead(tokenId);
    }

    function totalSupply() public virtual view returns (uint256) {
        return totalMinted - totalBurned;
    }

    function tokensOfOwner(address owner) external view virtual returns (uint256[] memory) {
        unchecked {
            uint256 tokenIdsIdx;
            uint256 tokenIdsLength = balanceOf(owner);
            uint256[] memory tokenIds = new uint256[](tokenIdsLength);
            for (uint256 i = 0; tokenIdsIdx != tokenIdsLength; ++i) {
                if (_exists(i)) {
                    if (ownerOf(i) == owner) {
                        tokenIds[tokenIdsIdx++] = i;
                    }
                }
            }
            return tokenIds;
        }
    }

    function tokenLockOf(uint256 tokenId) public view returns (uint8){
        if (!_exists(tokenId)) revert LCDTokenNotFound();
        return _lockedTokens[tokenId];
    }

    function _setTokenLock(uint256 tokenId, uint8 lockType) internal virtual {
        _lockedTokens[tokenId] = lockType;
    }

    function _isClassBackstopExpired(uint8 classId) internal view virtual returns (bool) {
        return classes[classId].backstopEnd < block.timestamp;
    }

    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual {}

    function _afterTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual {}

    modifier unlocked(uint256 tokenId){
        if (_lockedTokens[tokenId] > PENDING_LOCK) revert LCDLockedToken();
        _;
    }
}
// File: @openzeppelin/contracts/interfaces/IERC2981.sol


// OpenZeppelin Contracts (last updated v4.9.0) (interfaces/IERC2981.sol)

pragma solidity ^0.8.0;


/**
 * @dev Interface for the NFT Royalty Standard.
 *
 * A standardized way to retrieve royalty payment information for non-fungible tokens (NFTs) to enable universal
 * support for royalty payments across all NFT marketplaces and ecosystem participants.
 *
 * _Available since v4.5._
 */
interface IERC2981 is IERC165 {
    /**
     * @dev Returns how much royalty is owed and to whom, based on a sale price that may be denominated in any unit of
     * exchange. The royalty amount is denominated and should be paid in that same unit of exchange.
     */
    function royaltyInfo(
        uint256 tokenId,
        uint256 salePrice
    ) external view returns (address receiver, uint256 royaltyAmount);
}

// File: contracts/LaunchCodes.sol


pragma solidity ^0.8.21;




contract LaunchCodes is TokenDataBasedERC721Psi, IERC2981, Administrable {
    uint8 public mintFundingPercentage = 10;
    uint8 public burnFundingPercentage = 0;
    uint8 public mintedClassId = 5;
    uint32 public individualMintingLimit;
    address public fundingDistributionAddress;
    address public stakingDistributionAddress;
    uint256 public frozenAssets;
    uint256 public fundsPool;

    event AdminParametersUpdated(uint8 mintFundingPercentage, uint8 burnFundingPercentage, uint8 mintedClassId, uint32 individualMintingLimit,
        address fundingDistributionAddress, address stakingDistributionAddress);
    event BatchMetadataUpdate(uint256 _fromTokenId, uint256 _toTokenId);
    event ClassArchivedAndFundsReleased(uint256 classId, uint256 heldAssets, uint256 heldFunding);
    event FundsTransfers(uint256 amount, address to);
    event Locked(uint256 tokenId);
    event LockUpdatedByAdmins(uint256 tokenId, uint8 lockId);
    event TokenBurned(address owner, uint8 classId, uint256 tokenId);
    event TokenMinted(address initiater, address receipent, uint8 classId, uint256 firstTokenId, uint256 lastTokenId);
    event TokenStaked(uint256 tokenId, uint256 stakedFunds);
    event TokenUnstaked(uint256 tokenId);
    event Unlocked(uint256 tokenId);

    constructor(
        string memory _baseURI,
        address _fundingDistributionAddress,
        address _stakingDistributionAddress,
        address[] memory _initialAdmins,
        address[] memory _founderAddresses,
        uint32[] memory _initialFounderTokenAmounts,
        uint32 _individualLimit,
        uint32 _communityClassGlobalLimit
    ) TokenDataBasedERC721Psi("Launch Codes", "LCD", _baseURI) Administrable(_initialAdmins) {
        if (_founderAddresses.length != _initialFounderTokenAmounts.length) revert LCDMismatchedArrayLengths();

        fundingDistributionAddress = _fundingDistributionAddress;
        stakingDistributionAddress = _stakingDistributionAddress;
        individualMintingLimit = _individualLimit;

        uint8 founderClassId = 254;
        classes[mintedClassId] = Class(true, false, 0, _communityClassGlobalLimit, 0.1 ether, 0, 0, block.timestamp + 730 days);
        classes[founderClassId] = Class(true, false, 0, type(uint32).max, 0, 0, 0, type(uint32).max);

        for (uint i = 0; i < _founderAddresses.length; i++) {
            _processMint(_founderAddresses[i], founderClassId, _initialFounderTokenAmounts[i], 0);
        }
    }

    function royaltyInfo(uint tokenId, uint salePrice) public view override returns (address, uint256) {
        if (!_exists(tokenId)) revert LCDTokenNotFound();
        return (fundingDistributionAddress, salePrice * (mintFundingPercentage + burnFundingPercentage) / 100);
    }

    function mint(uint32 _amount) external payable classNotArchived(mintedClassId) correctMintingPrice(msg.value, mintedClassId, _amount) globalLimitNotMet(mintedClassId, _amount) {
        if (individualCounts[_msgSender()].mintedCount + _amount > individualMintingLimit) revert LCDIndividualMintingLimitMet();
        _processMint(_msgSender(), mintedClassId, _amount, msg.value);
    }

    function adminMint(address _to, uint8 _classId, uint32 _amount) external payable onlyAdmin classNotArchived(_classId) globalLimitNotMet(_classId, _amount)
    classExists(_classId) correctMintingPrice(msg.value, _classId, _amount) {
        _processMint(_to, _classId, _amount, msg.value);
    }

    function burn(uint256[] calldata _tokenIds) external {
        if (_tokenIds.length == 0) revert LCDQuantityMustBeGreaterThanZero();
        uint256 refundAmount = 0;
        for (uint i = 0; i < _tokenIds.length; i++) {
            refundAmount += _processBurn(_tokenIds[i]);
        }
        _sendFundsTo(_msgSender(), refundAmount);
    }

    function transferFundsPool() public whenNotPaused {
        if (fundsPool == 0) revert LCDNoFundsToTransfer();
        emit FundsTransfers(fundsPool, fundingDistributionAddress);

        uint256 transferredAmount = fundsPool;
        fundsPool = 0;
        _sendFundsTo(fundingDistributionAddress, transferredAmount);
    }

    function registerClass(uint8 _id, uint32 _globalLimit, uint256 _price, uint256 _backstopEnd) external onlyAdmin {
        if (classes[_id].active) revert LCDClassAlreadyExists();
        if (block.timestamp >= _backstopEnd) revert LCDBackstopEndInTheFuture();
        classes[_id] = Class(true, false, 0, _globalLimit, _price, 0, 0, _backstopEnd);
    }

    function updateAdminParameters(uint8 _mintFundingPercentage, uint8 _burnFundingPercentage, uint8 _mintedClassId, uint32 _individualMintingLimit,
        address _fundingDistributionAddress, address _stakingDistributionAddress) external onlyAdmin classExists(_mintedClassId) {
        fundingDistributionAddress = _fundingDistributionAddress;
        stakingDistributionAddress = _stakingDistributionAddress;
        mintedClassId = _mintedClassId;
        individualMintingLimit = _individualMintingLimit;
        mintFundingPercentage = _mintFundingPercentage;
        burnFundingPercentage = _burnFundingPercentage;
        emit AdminParametersUpdated(_mintFundingPercentage, _burnFundingPercentage, _mintedClassId, _individualMintingLimit,
            _fundingDistributionAddress, _stakingDistributionAddress);
    }

    function setBaseURI(string memory _metadataBaseURI) external onlyAdmin {
        _setBaseURI(_metadataBaseURI);
        emit BatchMetadataUpdate(0, _nextTokenId() - 1);
    }

    function updateLocks(uint256[] calldata _tokenIds, uint8 _newLockType) external onlyAdmin {
        uint256 currentTokenId;
        uint8 currentTokenLockType;
        for (uint256 i = 0; i < _tokenIds.length; ++i) {
            currentTokenId = _tokenIds[i];
            currentTokenLockType = tokenLockOf(currentTokenId);
            if (currentTokenLockType == NO_LOCK || currentTokenLockType == STAKING_LOCK) revert LCDCannotUpdateLocksOnUnlockedOrStakedTokens();
            if (_newLockType == STAKING_LOCK) revert LCDCannotAssignStakingLocks();
            _setTokenLock(currentTokenId, _newLockType);

            emit LockUpdatedByAdmins(currentTokenId, _newLockType);
            if (_newLockType <= PENDING_LOCK) {
                emit Unlocked(currentTokenId);
            } else {
                emit Locked(currentTokenId);
            }
        }
    }

    function stakeTokens(uint256[] calldata _tokenIds) external {
        uint256 transferFunds;
        uint256 currentTokenId;
        TokenData memory currentTokenData;
        for (uint256 i = 0; i < _tokenIds.length; ++i) {
            currentTokenId = _tokenIds[i];
            if (!_isApprovedOrOwner(_msgSender(), currentTokenId)) revert LCDNotTokenOwnerOrApproved();
            if (tokenLockOf(currentTokenId) > PENDING_LOCK) revert LCDCanOnlyStakeUnlockedTokens();
            _setTokenLock(currentTokenId, STAKING_LOCK);

            currentTokenData = _unfilteredTokenDataOf(currentTokenId);
            if (!_isClassBackstopExpired(currentTokenData.classId)) {
                transferFunds += currentTokenData.heldAssets;
                classes[currentTokenData.classId].totalUnstakedHeldAssets -= currentTokenData.heldAssets;
                emit TokenStaked(currentTokenId, currentTokenData.heldAssets);
            } else {
                emit TokenStaked(currentTokenId, 0);
            }
            emit Locked(currentTokenId);
        }
        if (transferFunds > 0) {
            frozenAssets -= transferFunds;
            _sendFundsTo(stakingDistributionAddress, transferFunds);
        }
    }

    function unstakeTokens(uint256[] calldata _tokenIds) external payable {
        uint256 neededFunds;
        uint8 lockType;
        uint256 currentTokenId;
        TokenData memory currentTokenData;
        for (uint256 i = 0; i < _tokenIds.length; ++i) {
            currentTokenId = _tokenIds[i];
            if (!_isApprovedOrOwner(_msgSender(), currentTokenId)) revert LCDNotTokenOwnerOrApproved();

            lockType = tokenLockOf(currentTokenId);
            if (tokenLockOf(currentTokenId) != STAKING_LOCK) revert LCDCanOnlyUnstakeStakedTokens();

            currentTokenData = _unfilteredTokenDataOf(currentTokenId);
            if (!_isClassBackstopExpired(currentTokenData.classId)) {
                neededFunds += currentTokenData.heldAssets;
                classes[currentTokenData.classId].totalUnstakedHeldAssets += currentTokenData.heldAssets;
            }
            _setTokenLock(currentTokenId, NO_LOCK);
            emit TokenUnstaked(currentTokenId);
            emit Unlocked(currentTokenId);
        }
        if (neededFunds != msg.value) revert LCDInvalidPaidPrice();
        frozenAssets += msg.value;
    }

    function archiveClassAndReleaseFunds(uint8[] calldata _classIds) external onlyAdmin {
        uint256 totalUnstakedHeldAssets = 0;
        uint256 totalUnstakedHeldFunding = 0;

        for (uint i = 0; i < _classIds.length; ++i) {
            Class storage currentClass = classes[_classIds[i]];
            if (!currentClass.active) revert LCDClassNotFound();
            if (!_isClassBackstopExpired(_classIds[i])) revert LCDClassStillBackstopped();
            if (currentClass.archived) revert LCDClassAlreadyArchived();

            totalUnstakedHeldAssets += currentClass.totalUnstakedHeldAssets;
            totalUnstakedHeldFunding += currentClass.totalUnstakedHeldFunding;
            emit ClassArchivedAndFundsReleased(_classIds[i], currentClass.totalUnstakedHeldAssets, currentClass.totalUnstakedHeldFunding);

            currentClass.totalUnstakedHeldAssets = 0;
            currentClass.totalUnstakedHeldFunding = 0;
            currentClass.archived = true;
        }

        frozenAssets -= totalUnstakedHeldAssets;
        fundsPool += totalUnstakedHeldAssets + totalUnstakedHeldFunding;
    }

    function _processMint(address _to, uint8 _classId, uint32 _amount, uint256 _pricePaid) internal {
        if (_amount == 0) revert LCDQuantityMustBeGreaterThanZero();
        classes[_classId].mintedCount += _amount;

        uint256 heldAssets;
        (uint256 mintFunding, uint256 burnFunding) = _getFundingAmounts(_amount, _classId);
        if (mintFunding + burnFunding > 0) {
            uint256 asset = _pricePaid - mintFunding - burnFunding;
            fundsPool += mintFunding;
            frozenAssets += asset;
            heldAssets = asset / _amount;

            classes[_classId].totalUnstakedHeldAssets += asset;
            classes[_classId].totalUnstakedHeldFunding += burnFunding;
        }

        uint256 fistMintedTokenId = _nextTokenId();
        _safeMint(_to, _amount);
        _setTokenDataOf(fistMintedTokenId, _classId, heldAssets, burnFunding / _amount);

        emit TokenMinted(_msgSender(), _to, _classId, fistMintedTokenId, _nextTokenId() - 1);
    }

    function _processBurn(uint256 _tokenId) internal unlocked(_tokenId) returns (uint256){
        if (!_isApprovedOrOwner(_msgSender(), _tokenId)) revert LCDNotTokenOwnerOrApproved();
        TokenData memory currentTokenData = tokenDataOf(_tokenId);

        _burn(_tokenId);
        emit TokenBurned(_msgSender(), currentTokenData.classId, _tokenId);

        if (!_isClassBackstopExpired(currentTokenData.classId)) {
            frozenAssets -= currentTokenData.heldAssets;
            fundsPool += currentTokenData.heldFunding;

            classes[currentTokenData.classId].totalUnstakedHeldAssets -= currentTokenData.heldAssets;
            classes[currentTokenData.classId].totalUnstakedHeldFunding -= currentTokenData.heldFunding;

            return currentTokenData.heldAssets;
        }
        return 0;
    }

    function _getFundingAmounts(uint256 _amount, uint8 _classId) internal view returns (uint256, uint256){
        uint256 price = _amount * classes[_classId].price;
        return (price * mintFundingPercentage / 100, price * burnFundingPercentage / 100);
    }

    function _sendFundsTo(address _to, uint256 _amount) internal {
        (bool sent,) = payable(_to).call{value: _amount}("");
        if (!sent) revert LCDFundsTransferFailed();
    }

    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal override whenNotPaused unlocked(startTokenId) {}

    modifier classExists(uint8 _classId){
        if (!classes[_classId].active) revert LCDClassNotFound();
        _;
    }

    modifier correctMintingPrice(uint256 _paidAmount, uint8 _classId, uint32 _amountOfTokens){
        if (_paidAmount != classes[_classId].price * _amountOfTokens) revert LCDInvalidPaidPrice();
        _;
    }

    modifier classNotArchived(uint8 _classId){
        if (classes[_classId].archived) revert LCDClassAlreadyArchived();
        _;
    }

    modifier globalLimitNotMet(uint8 _classId, uint32 _amount){
        if (classes[_classId].mintedCount + _amount > classes[_classId].mintingLimit) revert LCDGlobalMintingLimitMet();
        _;
    }
}