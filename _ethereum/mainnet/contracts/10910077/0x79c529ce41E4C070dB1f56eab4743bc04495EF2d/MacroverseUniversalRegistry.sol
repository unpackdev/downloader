/**
SPDX-License-Identifier: UNLICENSED
See https://github.com/OpenZeppelin/openzeppelin-contracts/blob/2a0f2a8ba807b41360e7e092c3d5bb1bfbeb8b50/LICENSE and https://github.com/NovakDistributed/macroverse/blob/eea161aff5dba9d21204681a3b0f5dbe1347e54b/LICENSE
*/

pragma solidity ^0.6.10;


// This code is part of OpenZeppelin and is licensed: MIT
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

// This code is part of OpenZeppelin and is licensed: MIT
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

/**
 * @title Contracts that should not own Ether
 * @author Remco Bloemen <remco@2π.com>
 * @author Novak Distributed
 * @dev This tries to block incoming ether to prevent accidental loss of Ether. Should Ether end up
 * in the contract, it will allow the owner to reclaim this Ether.
 * @notice Ether can still be sent to this contract by:
 * calling functions labeled `payable`
 * `selfdestruct(contract_address)`
 * mining directly to the contract address
 */
contract HasNoEther is Ownable {
  /**
  * @dev Constructor that rejects incoming Ether
  * The `payable` flag is added so we can access `msg.value` without compiler warning. If we
  * leave out payable, then Solidity will allow inheriting contracts to implement a payable
  * constructor. By doing it this way we prevent a payable constructor from working. Alternatively
  * we could use assembly to access msg.value.
  */
  constructor() public payable {
    require(msg.value == 0);
  }
  /**
   * @dev Disallows direct send by throwing in the receive function.
   */
  receive() external payable {
    revert();
  }
  /**
   * @dev Transfer all Ether held by the contract to the owner.
   */
  function reclaimEther() external onlyOwner {
    // For some reason Ownable doesn't insist that the owner is payable.
    // This makes it payable.
    address(uint160(owner())).transfer(address(this).balance);
  }
}

// This code is part of Macroverse and is licensed: MIT
/*
The MIT License (MIT)

Copyright (c) 2016 Smart Contract Solutions, Inc.
Copyright (c) 2020 Novak Distributed

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be included
in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

/** 
 * @title Contracts that should not own Contracts
 * @author Remco Bloemen <remco@2π.com>
 * @dev Should contracts (anything Ownable) end up being owned by this contract, it allows the owner
 * of this contract to reclaim ownership of the contracts.
 */
contract HasNoContracts is Ownable {

  /**
   * @dev Reclaim ownership of Ownable contracts
   * @param contractAddr The address of the Ownable to be reclaimed.
   */
  function reclaimContract(address contractAddr) external onlyOwner {
    Ownable contractInst = Ownable(contractAddr);
    contractInst.transferOwnership(owner());
  }
}

// This code is part of Macroverse and is licensed: MIT
/*
The MIT License (MIT)

Copyright (c) 2016 Smart Contract Solutions, Inc.

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be included
in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

// This code is part of OpenZeppelin and is licensed: MIT
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

// This code is part of OpenZeppelin and is licensed: MIT
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

/**
 * This library contains utility functions for creating, parsing, and
 * manipulating Macroverse virtual real estate non-fungible token (NFT)
 * identifiers. The uint256 that identifies a piece of Macroverse virtual real
 * estate includes the type of object that is claimed and its location in the
 * macroverse world, as defined by this library.
 *
 * NFT tokens carry metadata about the object they describe, in the form of a
 * bit-packed keypath in the 192 low bits of a uint256. Form LOW to HIGH bits,
 * the fields are:
 *
 * - token type (5): sector (0), system (1), planet (2), moon (3),
 *   land on planet or moon at increasing granularity (4-31)
 * - sector x (16)
 * - sector y (16)
 * - sector z (16)
 * - star number (16) or 0 if a sector
 * - planet number (16) or 0 if a star
 * - moon number (16) or 0 if a planet, or -1 if land on a planet
 * - 0 to 27 trixel numbers, at 3 bits each
 *
 * More specific claims use more of the higher-value bits, producing larger
 * numbers in general.
 *
 * The "trixel" numbers refer to dubdivisions of the surface of a planet or
 * moon, or the area of an asteroid belt or ring. See the documentation for the
 * MacroverseUniversalRegistry for more information on the trixel system.
 *
 * Small functions in the library are internal, because inlining them will take
 * less space than a call.
 *
 * Larger functions are public.
 *
 */
library MacroverseNFTUtils {

    //
    // Code for working on token IDs
    //
    
    // Define the types of tokens that can exist
    uint256 constant TOKEN_TYPE_SECTOR = 0;
    uint256 constant TOKEN_TYPE_SYSTEM = 1;
    uint256 constant TOKEN_TYPE_PLANET = 2;
    uint256 constant TOKEN_TYPE_MOON = 3;
    // Land tokens are a range of type field values.
    // Land tokens of the min type use one trixel field
    uint256 constant TOKEN_TYPE_LAND_MIN = 4;
    uint256 constant TOKEN_TYPE_LAND_MAX = 31;

    // Define the packing format
    uint8 constant TOKEN_SECTOR_X_SHIFT = 5;
    uint8 constant TOKEN_SECTOR_X_BITS = 16;
    uint8 constant TOKEN_SECTOR_Y_SHIFT = TOKEN_SECTOR_X_SHIFT + TOKEN_SECTOR_X_BITS;
    uint8 constant TOKEN_SECTOR_Y_BITS = 16;
    uint8 constant TOKEN_SECTOR_Z_SHIFT = TOKEN_SECTOR_Y_SHIFT + TOKEN_SECTOR_Y_BITS;
    uint8 constant TOKEN_SECTOR_Z_BITS = 16;
    uint8 constant TOKEN_SYSTEM_SHIFT = TOKEN_SECTOR_Z_SHIFT + TOKEN_SECTOR_Z_BITS;
    uint8 constant TOKEN_SYSTEM_BITS = 16;
    uint8 constant TOKEN_PLANET_SHIFT = TOKEN_SYSTEM_SHIFT + TOKEN_SYSTEM_BITS;
    uint8 constant TOKEN_PLANET_BITS = 16;
    uint8 constant TOKEN_MOON_SHIFT = TOKEN_PLANET_SHIFT + TOKEN_PLANET_BITS;
    uint8 constant TOKEN_MOON_BITS = 16;
    uint8 constant TOKEN_TRIXEL_SHIFT = TOKEN_MOON_SHIFT + TOKEN_MOON_BITS;
    uint8 constant TOKEN_TRIXEL_EACH_BITS = 3;

    // How many trixel fields are there
    uint256 constant TOKEN_TRIXEL_FIELD_COUNT = 27;

    // How many children does a trixel have?
    uint256 constant CHILDREN_PER_TRIXEL = 4;
    // And how many top level trixels does a world have?
    uint256 constant TOP_TRIXELS = 8;

    // We keep a bit mask of the high bits of all but the least specific trixel.
    // None of these may be set in a valid token.
    // We rely on it being left-shifted TOKEN_TRIXEL_SHIFT bits before being applied.
    // Note that this has 26 1s, with one every 3 bits, except the last 3 bits are 0.
    uint256 constant TOKEN_TRIXEL_HIGH_BIT_MASK = 0x124924924924924924920;

    // Sentinel for no moon used (for land on a planet)
    uint16 constant MOON_NONE = 0xFFFF;

    /**
     * Work out what type of real estate a token represents.
     * Land claims of different granularities are different types.
     */
    function getTokenType(uint256 token) internal pure returns (uint256) {
        // Grab off the low 5 bits
        return token & 0x1F;
    }

    /**
     * Modify the type of a token. Does not fix up the other fields to correspond to the new type
     */
    function setTokenType(uint256 token, uint256 newType) internal pure returns (uint256) {
        assert(newType <= 31);
        // Clear and replace the low 5 bits
        return (token & ~uint256(0x1F)) | newType;
    }

    /**
     * Get the 16 bits of the token, at the given offset from the low bit.
     */
    function getTokenUInt16(uint256 token, uint8 offset) internal pure returns (uint16) {
        return uint16(token >> offset);
    }

    /**
     * Set the 16 bits of the token, at the given offset from the low bit, to the given value.
     */
    function setTokenUInt16(uint256 token, uint8 offset, uint16 data) internal pure returns (uint256) {
        // Clear out the bits we want to set, and then or in their values
        return (token & ~(uint256(0xFFFF) << offset)) | (uint256(data) << offset);
    }

    /**
     * Get the X, Y, and Z coordinates of a token's sector.
     */
    function getTokenSector(uint256 token) internal pure returns (int16 x, int16 y, int16 z) {
        x = int16(getTokenUInt16(token, TOKEN_SECTOR_X_SHIFT));
        y = int16(getTokenUInt16(token, TOKEN_SECTOR_Y_SHIFT));
        z = int16(getTokenUInt16(token, TOKEN_SECTOR_Z_SHIFT));
    }

    /**
     * Set the X, Y, and Z coordinates of the sector data in the given token.
     */
    function setTokenSector(uint256 token, int16 x, int16 y, int16 z) internal pure returns (uint256) {
        return setTokenUInt16(setTokenUInt16(setTokenUInt16(token, TOKEN_SECTOR_X_SHIFT, uint16(x)),
            TOKEN_SECTOR_Y_SHIFT, uint16(y)), TOKEN_SECTOR_Z_SHIFT, uint16(z));
    }

    /**
     * Get the system number of a token.
     */
    function getTokenSystem(uint256 token) internal pure returns (uint16) {
        return getTokenUInt16(token, TOKEN_SYSTEM_SHIFT);
    }

    /**
     * Set the system number of a token.
     */
    function setTokenSystem(uint256 token, uint16 system) internal pure returns (uint256) {
        return setTokenUInt16(token, TOKEN_SYSTEM_SHIFT, system);
    }

    /**
     * Get the planet number of a token.
     */
    function getTokenPlanet(uint256 token) internal pure returns (uint16) {
        return getTokenUInt16(token, TOKEN_PLANET_SHIFT);
    }

    /**
     * Set the planet number of a token.
     */
    function setTokenPlanet(uint256 token, uint16 planet) internal pure returns (uint256) {
        return setTokenUInt16(token, TOKEN_PLANET_SHIFT, planet);
    }

    /**
     * Get the moon number of a token.
     */
    function getTokenMoon(uint256 token) internal pure returns (uint16) {
        return getTokenUInt16(token, TOKEN_MOON_SHIFT);
    }

    /**
     * Set the moon number of a token.
     */
    function setTokenMoon(uint256 token, uint16 moon) internal pure returns (uint256) {
        return setTokenUInt16(token, TOKEN_MOON_SHIFT, moon);
    }

    /**
     * Get the number of used trixel fields in a token. From 0 (not land) to 27.
     */
    function getTokenTrixelCount(uint256 token) internal pure returns (uint256) {
        uint256 token_type = getTokenType(token);
        if (token_type < TOKEN_TYPE_LAND_MIN) {
            return 0;
        }
    
        // Remember that at the min type one trixel is used.
        return token_type - TOKEN_TYPE_LAND_MIN + 1;
    }

    /**
     * Set the number of used trixel fields in a token. From 1 to 27.
     * Automatically makes the token land type.
     */
    function setTokenTrixelCount(uint256 token, uint256 count) internal pure returns (uint256) {
        assert(count > 0);
        assert(count <= TOKEN_TRIXEL_FIELD_COUNT);
        uint256 token_type = TOKEN_TYPE_LAND_MIN + count - 1;
        return setTokenType(token, token_type);
    }

    /**
     * Get the value of the trixel at the given index in the token. Index can be from 0 through 26.
     * At trixel 0, values are 0-7. At other trixels, values are 0-3.
     * Assumes the token is land and has sufficient trixels to query this one.
     */
    function getTokenTrixel(uint256 token, uint256 trixel_index) internal pure returns (uint256) {
        assert(trixel_index < TOKEN_TRIXEL_FIELD_COUNT);
        // Shift down to the trixel we want and get the low 3 bits.
        return (token >> (TOKEN_TRIXEL_SHIFT + TOKEN_TRIXEL_EACH_BITS * trixel_index)) & 0x7;
    }

    /**
     * Set the value of the trixel at the given index. Trixel indexes can be
     * from 0 throug 26. Values can be 0-7 for the first trixel, and 0-3 for
     * subsequent trixels.  Assumes the token trixel count will be updated
     * separately if necessary.
     */
    function setTokenTrixel(uint256 token, uint256 trixel_index, uint256 value) internal pure returns (uint256) {
        assert(trixel_index < TOKEN_TRIXEL_FIELD_COUNT);
        if (trixel_index == 0) {
            assert(value < TOP_TRIXELS);
        } else {
            assert(value < CHILDREN_PER_TRIXEL);
        }
        
        // Compute the bit shift distance
        uint256 trixel_shift = (TOKEN_TRIXEL_SHIFT + TOKEN_TRIXEL_EACH_BITS * trixel_index);
    
        // Clear out the field and then set it again
        return (token & ~(uint256(0x7) << trixel_shift)) | (value << trixel_shift); 
    }

    /**
     * Return true if the given token number/bit-packed keypath corresponds to a land trixel, and false otherwise.
     */
    function tokenIsLand(uint256 token) internal pure returns (bool) {
        uint256 token_type = getTokenType(token);
        return (token_type >= TOKEN_TYPE_LAND_MIN && token_type <= TOKEN_TYPE_LAND_MAX); 
    }

    /**
     * Get the token number representing the parent of the given token (i.e. the system if operating on a planet, etc.).
     * That token may or may not be currently owned.
     * May return a token representing a sector; sectors can't be claimed.
     * Will fail if called on a token that is a sector
     */
    function parentOfToken(uint256 token) internal pure returns (uint256) {
        uint256 token_type = getTokenType(token);

        assert(token_type != TOKEN_TYPE_SECTOR);

        if (token_type == TOKEN_TYPE_SYSTEM) {
            // Zero out the system and make it a sector token
            return setTokenType(setTokenSystem(token, 0), TOKEN_TYPE_SECTOR);
        } else if (token_type == TOKEN_TYPE_PLANET) {
            // Zero out the planet and make it a system token
            return setTokenType(setTokenPlanet(token, 0), TOKEN_TYPE_SYSTEM);
        } else if (token_type == TOKEN_TYPE_MOON) {
            // Zero out the moon and make it a planet token
            return setTokenType(setTokenMoon(token, 0), TOKEN_TYPE_PLANET);
        } else if (token_type == TOKEN_TYPE_LAND_MIN) {
            // Move from top level trixel to planet or moon
            if (getTokenMoon(token) == MOON_NONE) {
                // It's land on a planet
                // Make sure to zero out the moon field
                return setTokenType(setTokenMoon(setTokenTrixel(token, 0, 0), 0), TOKEN_TYPE_PLANET);
            } else {
                // It's land on a moon. Leave the moon in.
                return setTokenType(setTokenTrixel(token, 0, 0), TOKEN_TYPE_PLANET);
            }
        } else {
            // It must be land below the top level
            uint256 last_trixel = getTokenTrixelCount(token) - 1;
            // Clear out the last trixel and pop it off
            return setTokenTrixelCount(setTokenTrixel(token, last_trixel, 0), last_trixel);
        }
    }

    /**
     * If the token has a parent, get the token's index among all children of the parent.
     * Planets have surface trixels and moons as children; the 8 surface trixels come first, followed by any moons. 
     * Fails if the token has no parent.
     */
    function childIndexOfToken(uint256 token) internal pure returns (uint256) {
        uint256 token_type = getTokenType(token);

        assert(token_type != TOKEN_TYPE_SECTOR);

        if (token_type == TOKEN_TYPE_SYSTEM) {
            // Get the system field of a system token
            return getTokenSystem(token);
        } else if (token_type == TOKEN_TYPE_PLANET) {
            // Get the planet field of a planet token
            return getTokenPlanet(token);
        } else if (token_type == TOKEN_TYPE_MOON) {
            // Get the moon field of a moon token. Offset it by the 0-7 top trixels of the planet's land.
            return getTokenMoon(token) + TOP_TRIXELS;
        } else if (token_type >= TOKEN_TYPE_LAND_MIN && token_type <= TOKEN_TYPE_LAND_MAX) {
            // Get the value of the last trixel. Top-level trixels are the first children of planets.
            uint256 last_trixel = getTokenTrixelCount(token) - 1;
            return getTokenTrixel(token, last_trixel);
        } else {
            // We have an invalid token type somehow
            assert(false);
        }
    }

    /**
     * If a token has a possible child for which childIndexOfToken would return the given index, returns that child.
     * Fails otherwise.
     * Index must not be wider than uint16 or it may be truncated.
     */
    function childTokenAtIndex(uint256 token, uint256 index) public pure returns (uint256) {
        uint256 token_type = getTokenType(token);

        assert(token_type != TOKEN_TYPE_LAND_MAX);

        if (token_type == TOKEN_TYPE_SECTOR) {
            // Set the system field and make it a system token
            return setTokenType(setTokenSystem(token, uint16(index)), TOKEN_TYPE_SYSTEM);
        } else if (token_type == TOKEN_TYPE_SYSTEM) {
            // Set the planet field and make it a planet token
            return setTokenType(setTokenPlanet(token, uint16(index)), TOKEN_TYPE_PLANET);
        } else if (token_type == TOKEN_TYPE_PLANET) {
            // Child could be a land or moon. The land trixels are first as 0-7
            if (index < TOP_TRIXELS) {
                // Make it land and set the first trixel
                return setTokenType(setTokenTrixel(token, 0, uint16(index)), TOKEN_TYPE_LAND_MIN);
            } else {
                // Make it a moon
                return setTokenType(setTokenMoon(token, uint16(index - TOP_TRIXELS)), TOKEN_TYPE_MOON);
            }
        } else if (token_type == TOKEN_TYPE_MOON) {
            // Make it land and set the first trixel
            return setTokenType(setTokenTrixel(token, 0, uint16(index)), TOKEN_TYPE_LAND_MIN);
        } else if (token_type >= TOKEN_TYPE_LAND_MIN && token_type < TOKEN_TYPE_LAND_MAX) {
            // Add another trixel with this value.
            // Its index will be the *count* of existing trixels.
            uint256 next_trixel = getTokenTrixelCount(token);
            return setTokenTrixel(setTokenTrixelCount(token, next_trixel + 1), next_trixel, uint16(index));
        } else {
            // We have an invalid token type somehow
            assert(false);
        }
    }

    /**
     * Not all uint256 values are valid tokens.
     * Returns true if the token represents something that may exist in the Macroverse world.
     * Only does validation of the bitstring representation (i.e. no extraneous set bits).
     * We still need to check in with the generator to validate that the system/planet/moon actually exists.
     */
    function tokenIsCanonical(uint256 token) public pure returns (bool) {
        
        if (token >> (TOKEN_TRIXEL_SHIFT + TOKEN_TRIXEL_EACH_BITS * getTokenTrixelCount(token)) != 0) {
            // There are bits set above the highest used trixel (for land) or in any trixel (for non-land)
            return false;
        }

        if (tokenIsLand(token)) {
            if (token & (TOKEN_TRIXEL_HIGH_BIT_MASK << TOKEN_TRIXEL_SHIFT) != 0) {
                // A high bit in a trixel other than the first is set
                return false;
            }
        }

        uint256 token_type = getTokenType(token);

        if (token_type == TOKEN_TYPE_MOON) {
            if (getTokenMoon(token) == MOON_NONE) {
                // Not a real moon
                return false;
            }
        } else if (token_type < TOKEN_TYPE_MOON) {
            if (getTokenMoon(token) != 0) {
                // Moon bits need to be clear
                return false;
            }

            if (token_type < TOKEN_TYPE_PLANET) {
                if (getTokenPlanet(token) != 0) {
                    // Planet bits need to be clear
                    return false;
                }

                if (token_type < TOKEN_TYPE_SYSTEM) {
                    if (getTokenSystem(token) != 0) {
                        // System bits need to be clear
                        return false;
                    }
                }
            }
        }

        // We found no problems. Still might not exist, though. Could be an out of range sector or a non-present system, planet or moon.
        return true;
    }

}

// This code is part of Macroverse and is licensed: UNLICENSED

/**
 * RealMath: fixed-point math library, based on fractional and integer parts.
 * Using int128 as real88x40, which isn't in Solidity yet.
 * 40 fractional bits gets us down to 1E-12 precision, while still letting us
 * go up to galaxy scale counting in meters.
 * Internally uses the wider int256 for some math.
 *
 * Note that for addition, subtraction, and mod (%), you should just use the
 * built-in Solidity operators. Functions for these operations are not provided.
 *
 * Note that the fancy functions like sqrt, atan2, etc. aren't as accurate as
 * they should be. They are (hopefully) Good Enough for doing orbital mechanics
 * on block timescales in a game context, but they may not be good enough for
 * other applications.
 */
library RealMath {
    
    /**@dev
     * How many total bits are there?
     */
    int256 constant REAL_BITS = 128;
    
    /**@dev
     * How many fractional bits are there?
     */
    int256 constant REAL_FBITS = 40;
    
    /**@dev
     * How many integer bits are there?
     */
    int256 constant REAL_IBITS = REAL_BITS - REAL_FBITS;
    
    /**@dev
     * What's the first non-fractional bit
     */
    int128 constant REAL_ONE = int128(1) << int128(REAL_FBITS);
    
    /**@dev
     * What's the last fractional bit?
     */
    int128 constant REAL_HALF = REAL_ONE >> int128(1);
    
    /**@dev
     * What's two? Two is pretty useful.
     */
    int128 constant REAL_TWO = REAL_ONE << int128(1);
    
    /**@dev
     * And our logarithms are based on ln(2).
     */
    int128 constant REAL_LN_TWO = 762123384786;
    
    /**@dev
     * It is also useful to have Pi around.
     */
    int128 constant REAL_PI = 3454217652358;
    
    /**@dev
     * And half Pi, to save on divides.
     * TODO: That might not be how the compiler handles constants.
     */
    int128 constant REAL_HALF_PI = 1727108826179;
    
    /**@dev
     * And two pi, which happens to be odd in its most accurate representation.
     */
    int128 constant REAL_TWO_PI = 6908435304715;
    
    /**@dev
     * What's the sign bit?
     */
    int128 constant SIGN_MASK = int128(1) << int128(127);
    

    /**
     * Convert an integer to a real. Preserves sign.
     */
    function toReal(int88 ipart) public pure returns (int128) {
        return int128(ipart) * REAL_ONE;
    }
    
    /**
     * Convert a real to an integer. Preserves sign.
     */
    function fromReal(int128 real_value) public pure returns (int88) {
        return int88(real_value / REAL_ONE);
    }
    
    /**
     * Round a real to the nearest integral real value.
     */
    function round(int128 real_value) public pure returns (int128) {
        // First, truncate.
        int88 ipart = fromReal(real_value);
        if ((fractionalBits(real_value) & (uint40(1) << uint40(REAL_FBITS - 1))) > 0) {
            // High fractional bit is set. Round up.
            if (real_value < int128(0)) {
                // Rounding up for a negative number is rounding down.
                ipart -= 1;
            } else {
                ipart += 1;
            }
        }
        return toReal(ipart);
    }
    
    /**
     * Get the absolute value of a real. Just the same as abs on a normal int128.
     */
    function abs(int128 real_value) public pure returns (int128) {
        if (real_value > 0) {
            return real_value;
        } else {
            return -real_value;
        }
    }
    
    /**
     * Returns the fractional bits of a real. Ignores the sign of the real.
     */
    function fractionalBits(int128 real_value) public pure returns (uint40) {
        return uint40(abs(real_value) % REAL_ONE);
    }
    
    /**
     * Get the fractional part of a real, as a real. Ignores sign (so fpart(-0.5) is 0.5).
     */
    function fpart(int128 real_value) public pure returns (int128) {
        // This gets the fractional part but strips the sign
        return abs(real_value) % REAL_ONE;
    }

    /**
     * Get the fractional part of a real, as a real. Respects sign (so fpartSigned(-0.5) is -0.5).
     */
    function fpartSigned(int128 real_value) public pure returns (int128) {
        // This gets the fractional part but strips the sign
        int128 fractional = fpart(real_value);
        if (real_value < 0) {
            // Add the negative sign back in.
            return -fractional;
        } else {
            return fractional;
        }
    }
    
    /**
     * Get the integer part of a fixed point value.
     */
    function ipart(int128 real_value) public pure returns (int128) {
        // Subtract out the fractional part to get the real part.
        return real_value - fpartSigned(real_value);
    }
    
    /**
     * Multiply one real by another. Truncates overflows.
     */
    function mul(int128 real_a, int128 real_b) public pure returns (int128) {
        // When multiplying fixed point in x.y and z.w formats we get (x+z).(y+w) format.
        // So we just have to clip off the extra REAL_FBITS fractional bits.
        return int128((int256(real_a) * int256(real_b)) >> REAL_FBITS);
    }
    
    /**
     * Divide one real by another real. Truncates overflows.
     */
    function div(int128 real_numerator, int128 real_denominator) public pure returns (int128) {
        // We use the reverse of the multiplication trick: convert numerator from
        // x.y to (x+z).(y+w) fixed point, then divide by denom in z.w fixed point.
        return int128((int256(real_numerator) * REAL_ONE) / int256(real_denominator));
    }
    
    /**
     * Create a real from a rational fraction.
     */
    function fraction(int88 numerator, int88 denominator) public pure returns (int128) {
        return div(toReal(numerator), toReal(denominator));
    }
    
    // Now we have some fancy math things (like pow and trig stuff). This isn't
    // in the RealMath that was deployed with the original Macroverse
    // deployment, so it needs to be linked into your contract statically.
    
    /**
     * Raise a number to a positive integer power in O(log power) time.
     * See <https://stackoverflow.com/a/101613>
     */
    function ipow(int128 real_base, int88 exponent) public pure returns (int128) {
        if (exponent < 0) {
            // Negative powers are not allowed here.
            revert();
        }
        
        // Start with the 0th power
        int128 real_result = REAL_ONE;
        while (exponent != 0) {
            // While there are still bits set
            if ((exponent & 0x1) == 0x1) {
                // If the low bit is set, multiply in the (many-times-squared) base
                real_result = mul(real_result, real_base);
            }
            // Shift off the low bit
            exponent = exponent >> 1;
            // Do the squaring
            real_base = mul(real_base, real_base);
        }
        
        // Return the final result.
        return real_result;
    }
    
    /**
     * Zero all but the highest set bit of a number.
     * See <https://stackoverflow.com/a/53184>
     */
    function hibit(uint256 val) internal pure returns (uint256) {
        // Set all the bits below the highest set bit
        val |= (val >>  1);
        val |= (val >>  2);
        val |= (val >>  4);
        val |= (val >>  8);
        val |= (val >> 16);
        val |= (val >> 32);
        val |= (val >> 64);
        val |= (val >> 128);
        return val ^ (val >> 1);
    }
    
    /**
     * Given a number with one bit set, finds the index of that bit.
     */
    function findbit(uint256 val) internal pure returns (uint8 index) {
        index = 0;
        // We and the value with alternating bit patters of various pitches to find it.
        
        if (val & 0xAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA != 0) {
            // Picth 1
            index |= 1;
        }
        if (val & 0xCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC != 0) {
            // Pitch 2
            index |= 2;
        }
        if (val & 0xF0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0 != 0) {
            // Pitch 4
            index |= 4;
        }
        if (val & 0xFF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00 != 0) {
            // Pitch 8
            index |= 8;
        }
        if (val & 0xFFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000 != 0) {
            // Pitch 16
            index |= 16;
        }
        if (val & 0xFFFFFFFF00000000FFFFFFFF00000000FFFFFFFF00000000FFFFFFFF00000000 != 0) {
            // Pitch 32
            index |= 32;
        }
        if (val & 0xFFFFFFFFFFFFFFFF0000000000000000FFFFFFFFFFFFFFFF0000000000000000 != 0) {
            // Pitch 64
            index |= 64;
        }
        if (val & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF00000000000000000000000000000000 != 0) {
            // Pitch 128
            index |= 128;
        }
    }
    
    /**
     * Shift real_arg left or right until it is between 1 and 2. Return the
     * rescaled value, and the number of bits of right shift applied. Shift may be negative.
     *
     * Expresses real_arg as real_scaled * 2^shift, setting shift to put real_arg between [1 and 2).
     *
     * Rejects 0 or negative arguments.
     */
    function rescale(int128 real_arg) internal pure returns (int128 real_scaled, int88 shift) {
        if (real_arg <= 0) {
            // Not in domain!
            revert();
        }
        
        // Find the high bit
        int88 high_bit = findbit(hibit(uint256(real_arg)));
        
        // We'll shift so the high bit is the lowest non-fractional bit.
        shift = high_bit - int88(REAL_FBITS);
        
        if (shift < 0) {
            // Shift left
            real_scaled = real_arg << int128(-shift);
        } else if (shift >= 0) {
            // Shift right
            real_scaled = real_arg >> int128(shift);
        }
    }
    
    /**
     * Calculate the natural log of a number. Rescales the input value and uses
     * the algorithm outlined at <https://math.stackexchange.com/a/977836> and
     * the ipow implementation.
     *
     * Lets you artificially limit the number of iterations.
     *
     * Note that it is potentially possible to get an un-converged value; lack
     * of convergence does not throw.
     */
    function lnLimited(int128 real_arg, int max_iterations) public pure returns (int128) {
        if (real_arg <= 0) {
            // Outside of acceptable domain
            revert();
        }
        
        if (real_arg == REAL_ONE) {
            // Handle this case specially because people will want exactly 0 and
            // not ~2^-39 ish.
            return 0;
        }
        
        // We know it's positive, so rescale it to be between [1 and 2)
        int128 real_rescaled;
        int88 shift;
        (real_rescaled, shift) = rescale(real_arg);
        
        // Compute the argument to iterate on
        int128 real_series_arg = div(real_rescaled - REAL_ONE, real_rescaled + REAL_ONE);
        
        // We will accumulate the result here
        int128 real_series_result = 0;
        
        for (int88 n = 0; n < max_iterations; n++) {
            // Compute term n of the series
            int128 real_term = div(ipow(real_series_arg, 2 * n + 1), toReal(2 * n + 1));
            // And add it in
            real_series_result += real_term;
            if (real_term == 0) {
                // We must have converged. Next term is too small to represent.
                break;
            }
            // If we somehow never converge I guess we will run out of gas
        }
        
        // Double it to account for the factor of 2 outside the sum
        real_series_result = mul(real_series_result, REAL_TWO);
        
        // Now compute and return the overall result
        return mul(toReal(shift), REAL_LN_TWO) + real_series_result;
        
    }
    
    /**
     * Calculate a natural logarithm with a sensible maximum iteration count to
     * wait until convergence. Note that it is potentially possible to get an
     * un-converged value; lack of convergence does not throw.
     */
    function ln(int128 real_arg) public pure returns (int128) {
        return lnLimited(real_arg, 100);
    }
    
    /**
     * Calculate e^x. Uses the series given at
     * <http://pages.mtu.edu/~shene/COURSES/cs201/NOTES/chap04/exp.html>.
     *
     * Lets you artificially limit the number of iterations.
     *
     * Note that it is potentially possible to get an un-converged value; lack
     * of convergence does not throw.
     */
    function expLimited(int128 real_arg, int max_iterations) public pure returns (int128) {
        // We will accumulate the result here
        int128 real_result = 0;
        
        // We use this to save work computing terms
        int128 real_term = REAL_ONE;
        
        for (int88 n = 0; n < max_iterations; n++) {
            // Add in the term
            real_result += real_term;
            
            // Compute the next term
            real_term = mul(real_term, div(real_arg, toReal(n + 1)));
            
            if (real_term == 0) {
                // We must have converged. Next term is too small to represent.
                break;
            }
            // If we somehow never converge I guess we will run out of gas
        }
        
        // Return the result
        return real_result;
        
    }
    
    /**
     * Calculate e^x with a sensible maximum iteration count to wait until
     * convergence. Note that it is potentially possible to get an un-converged
     * value; lack of convergence does not throw.
     */
    function exp(int128 real_arg) public pure returns (int128) {
        return expLimited(real_arg, 100);
    }
    
    /**
     * Raise any number to any power, except for negative bases to fractional powers.
     */
    function pow(int128 real_base, int128 real_exponent) public pure returns (int128) {
        if (real_exponent == 0) {
            // Anything to the 0 is 1
            return REAL_ONE;
        }
        
        if (real_base == 0) {
            if (real_exponent < 0) {
                // Outside of domain!
                revert();
            }
            // Otherwise it's 0
            return 0;
        }
        
        if (fpart(real_exponent) == 0) {
            // Anything (even a negative base) is super easy to do to an integer power.
            
            if (real_exponent > 0) {
                // Positive integer power is easy
                return ipow(real_base, fromReal(real_exponent));
            } else {
                // Negative integer power is harder
                return div(REAL_ONE, ipow(real_base, fromReal(-real_exponent)));
            }
        }
        
        if (real_base < 0) {
            // It's a negative base to a non-integer power.
            // In general pow(-x^y) is undefined, unless y is an int or some
            // weird rational-number-based relationship holds.
            revert();
        }
        
        // If it's not a special case, actually do it.
        return exp(mul(real_exponent, ln(real_base)));
    }
    
    /**
     * Compute the square root of a number.
     */
    function sqrt(int128 real_arg) public pure returns (int128) {
        return pow(real_arg, REAL_HALF);
    }
    
    /**
     * Compute the sin of a number to a certain number of Taylor series terms.
     */
    function sinLimited(int128 real_arg, int88 max_iterations) public pure returns (int128) {
        // First bring the number into 0 to 2 pi
        // TODO: This will introduce an error for very large numbers, because the error in our Pi will compound.
        // But for actual reasonable angle values we should be fine.
        real_arg = real_arg % REAL_TWO_PI;
        
        int128 accumulator = REAL_ONE;
        
        // We sum from large to small iteration so that we can have higher powers in later terms
        for (int88 iteration = max_iterations - 1; iteration >= 0; iteration--) {
            accumulator = REAL_ONE - mul(div(mul(real_arg, real_arg), toReal((2 * iteration + 2) * (2 * iteration + 3))), accumulator);
            // We can't stop early; we need to make it to the first term.
        }
        
        return mul(real_arg, accumulator);
    }
    
    /**
     * Calculate sin(x) with a sensible maximum iteration count to wait until
     * convergence.
     */
    function sin(int128 real_arg) public pure returns (int128) {
        return sinLimited(real_arg, 15);
    }
    
    /**
     * Calculate cos(x).
     */
    function cos(int128 real_arg) public pure returns (int128) {
        return sin(real_arg + REAL_HALF_PI);
    }
    
    /**
     * Calculate tan(x). May overflow for large results. May throw if tan(x)
     * would be infinite, or return an approximation, or overflow.
     */
    function tan(int128 real_arg) public pure returns (int128) {
        return div(sin(real_arg), cos(real_arg));
    }
    
    /**
     * Calculate atan(x) for x in [-1, 1].
     * Uses the Chebyshev polynomial approach presented at
     * https://www.mathworks.com/help/fixedpoint/examples/calculate-fixed-point-arctangent.html
     * Uses polynomials received by personal communication.
     * 0.999974x-0.332568x^3+0.193235x^5-0.115729x^7+0.0519505x^9-0.0114658x^11
     */
    function atanSmall(int128 real_arg) public pure returns (int128) {
        int128 real_arg_squared = mul(real_arg, real_arg);
        return mul(mul(mul(mul(mul(mul(
            - 12606780422,  real_arg_squared) // x^11
            + 57120178819,  real_arg_squared) // x^9
            - 127245381171, real_arg_squared) // x^7
            + 212464129393, real_arg_squared) // x^5
            - 365662383026, real_arg_squared) // x^3
            + 1099483040474, real_arg);       // x^1
    }
    
    /**
     * Compute the nice two-component arctangent of y/x.
     */
    function atan2(int128 real_y, int128 real_x) public pure returns (int128) {
        int128 atan_result;
        
        // Do the angle correction shown at
        // https://www.mathworks.com/help/fixedpoint/examples/calculate-fixed-point-arctangent.html
        
        // We will re-use these absolute values
        int128 real_abs_x = abs(real_x);
        int128 real_abs_y = abs(real_y);
        
        if (real_abs_x > real_abs_y) {
            // We are in the (0, pi/4] region
            // abs(y)/abs(x) will be in 0 to 1.
            atan_result = atanSmall(div(real_abs_y, real_abs_x));
        } else {
            // We are in the (pi/4, pi/2) region
            // abs(x) / abs(y) will be in 0 to 1; we swap the arguments
            atan_result = REAL_HALF_PI - atanSmall(div(real_abs_x, real_abs_y));
        }
        
        // Now we correct the result for other regions
        if (real_x < 0) {
            if (real_y < 0) {
                atan_result -= REAL_PI;
            } else {
                atan_result = REAL_PI - atan_result;
            }
        } else {
            if (real_y < 0) {
                atan_result = -atan_result;
            }
        }
        
        return atan_result;
    }
}

// This code is part of Macroverse and is licensed: MIT

library RNG {
    using RealMath for *;

    /**
     * We are going to define a RandNode struct to allow for hash chaining.
     * You can extend a RandNode with a bunch of different stuff and get a new RandNode.
     * You can then use a RandNode to get a single, repeatable random value.
     * This eliminates the need for concatenating string selfs, which is a huge pain in Solidity.
     */
    struct RandNode {
        // We hash this together with whatever we're mixing in to get the child hash.
        bytes32 _hash;
    }
    
    // All the functions that touch RandNodes need to be internal.
    // If you want to pass them in and out of contracts just use the bytes32.
    
    // You can get all these functions as methods on RandNodes by "using RNG for *" in your library/contract.
    
    /**
     * Mix string data into a RandNode. Returns a new RandNode.
     */
    function derive(RandNode memory self, string memory entropy) internal pure returns (RandNode memory) {
        // Hash what's there now with the new stuff.
        return RandNode(sha256(abi.encodePacked(self._hash, entropy)));
    }
    
    /**
     * Mix signed int data into a RandNode. Returns a new RandNode.
     */
    function derive(RandNode memory self, int256 entropy) internal pure returns (RandNode memory) {
        return RandNode(sha256(abi.encodePacked(self._hash, entropy)));
    }
    
     /**
     * Mix unsigned int data into a RandNode. Returns a new RandNode.
     */
    function derive(RandNode memory self, uint256 entropy) internal pure returns (RandNode memory) {
        return RandNode(sha256(abi.encodePacked(self._hash, entropy)));
    }

    /**
     * Returns the base RNG hash for the given RandNode.
     * Does another round of hashing in case you made a RandNode("Stuff").
     */
    function getHash(RandNode memory self) internal pure returns (bytes32) {
        return sha256(abi.encodePacked(self._hash));
    }
    
    /**
     * Return true or false with 50% probability.
     */
    function getBool(RandNode memory self) internal pure returns (bool) {
        return uint256(getHash(self)) & 0x1 > 0;
    }
    
    /**
     * Get an int128 full of random bits.
     */
    function getInt128(RandNode memory self) internal pure returns (int128) {
        // Just cast to int and truncate
        return int128(int256(getHash(self)));
    }
    
    /**
     * Get a real88x40 between 0 (inclusive) and 1 (exclusive).
     */
    function getReal(RandNode memory self) internal pure returns (int128) {
        return getInt128(self).fpart();
    }
    
    /**
     * Get an integer between low, inclusive, and high, exclusive. Represented as a normal int, not a real.
     */
    function getIntBetween(RandNode memory self, int88 low, int88 high) internal pure returns (int88) {
        return RealMath.fromReal((getReal(self).mul(RealMath.toReal(high) - RealMath.toReal(low))) + RealMath.toReal(low));
    }
    
    /**
     * Get a real between realLow (inclusive) and realHigh (exclusive).
     * Only actually has the bits of entropy from getReal, so some values will not occur.
     */
    function getRealBetween(RandNode memory self, int128 realLow, int128 realHigh) internal pure returns (int128) {
        return getReal(self).mul(realHigh - realLow) + realLow;
    }
    
    /**
     * Roll a number of die of the given size, add/subtract a bonus, and return the result.
     * Max size is 100.
     */
    function d(RandNode memory self, int8 count, int8 size, int8 bonus) internal pure returns (int16) {
        if (count == 1) {
            // Base case
            return int16(getIntBetween(self, 1, size)) + bonus;
        } else {
            // Loop and sum
            int16 sum = bonus;
            for(int8 i = 0; i < count; i++) {
                // Roll each die with no bonus
                sum += d(derive(self, i), 1, size, 0);
            }
            return sum;
        }
    }
}

// This code is part of Macroverse and is licensed: MIT

/**
 * Interface for an access control strategy for Macroverse contracts.
 * Can be asked if a certain query should be allowed, and will return true or false.
 * Allows for different access control strategies (unrestricted, minimum balance, subscription, etc.) to be swapped in.
 */
abstract contract AccessControl {
    /**
     * Should a query be allowed for this msg.sender (calling contract) and this tx.origin (calling user)?
     */
    function allowQuery(address sender, address origin) virtual public view returns (bool);
}

// This code is part of Macroverse and is licensed: UNLICENSED

/**
 * Represents a contract that is Ownable, and which has methods that are to be protected by an AccessControl strategy selected by the owner.
 */
contract ControlledAccess is Ownable {

    // This AccessControl contract determines who can run onlyControlledAccess methods.
    AccessControl accessControl;
    
    /**
     * Make a new ControlledAccess contract, controlling access with the given AccessControl strategy.
     */
    constructor(address originalAccessControl) internal {
        accessControl = AccessControl(originalAccessControl);
    }
    
    /**
     * Change the access control strategy of the prototype.
     */
    function changeAccessControl(address newAccessControl) public onlyOwner {
        accessControl = AccessControl(newAccessControl);
    }
    
    /**
     * Only allow queries approved by the access control contract.
     */
    modifier onlyControlledAccess {
        if (!accessControl.allowQuery(msg.sender, tx.origin)) revert();
        _;
    }
    

}

// This code is part of Macroverse and is licensed: UNLICENSED

/**
 * Represents a Macroverse Generator for a galaxy.
 *
 * Permission to call methods on this contract is regulated by a configurable
 * AccessControl contract. One such set of terms might be to require that the
 * account initiating a transaction have a certain minimum MRV token balance.
 *
 * The owner of this contract reserves the right to supersede it with a new
 * version, and to modify the terms for accessing this contract, at any time,
 * for any reason, and without notice. This includes the right to indefinitely
 * or permanently suspend or terminate access to this contract for any person,
 * account, or other contract, or for all persons, accounts, or other
 * contracts. The owner also reserves the right to not do any of the above.
 */
contract MacroverseStarGenerator is ControlledAccess {
    // TODO: RNG doesn't get linked against because we can't pass the struct to the library...
    using RNG for *;
    using RealMath for *;
    // No SafeMath or it might confuse RealMath

    // How big is a sector on a side in LY?
    int16 constant SECTOR_SIZE = 25;
    // How far out does the sector system extend?
    int16 constant MAX_SECTOR = 10000;
    // How big is the galaxy?
    int16 constant DISK_RADIUS_IN_SECTORS = 6800;
    // How thick is its disk?
    int16 constant DISK_HALFHEIGHT_IN_SECTORS = 40;
    // How big is the central sphere?
    int16 constant CORE_RADIUS_IN_SECTORS = 1000;
    
    // There are kinds of stars.
    // We can add more later; these are from http://www.mit.edu/afs.new/sipb/user/sekullbe/furble/planet.txt
    //                 0           1      2             3           4            5
    enum ObjectClass { Supergiant, Giant, MainSequence, WhiteDwarf, NeutronStar, BlackHole }
    // Actual stars have a spectral type
    //                  0      1      2      3      4      5      6      7
    enum SpectralType { TypeO, TypeB, TypeA, TypeF, TypeG, TypeK, TypeM, NotApplicable }
    // Each type has subtypes 0-9, except O which only has 5-9
    
    // This root RandNode provides the seed for the universe.
    RNG.RandNode root;
    
    /**
     * Deploy a new copy of the Macroverse generator contract. Use the given seed to generate a galaxy, down to the star level.
     * Use the contract at the given address to regulate access.
     */
    constructor(bytes32 baseSeed, address accessControlAddress) ControlledAccess(accessControlAddress) public {
        root = RNG.RandNode(baseSeed);
    }
    
    /**
     * Get the density (between 0 and 1 as a fixed-point real88x40) of stars in the given sector. Sector 0,0,0 is centered on the galactic origin.
     * +Y is upwards.
     */
    function getGalaxyDensity(int16 sectorX, int16 sectorY, int16 sectorZ) public view onlyControlledAccess returns (int128 realDensity) {
        // We have a central sphere and a surrounding disk.
        
        // Enforce absolute bounds.
        if (sectorX > MAX_SECTOR) return 0;
        if (sectorY > MAX_SECTOR) return 0;
        if (sectorZ > MAX_SECTOR) return 0;
        if (sectorX < -MAX_SECTOR) return 0;
        if (sectorY < -MAX_SECTOR) return 0;
        if (sectorZ < -MAX_SECTOR) return 0;
        
        if (int(sectorX) * int(sectorX) + int(sectorY) * int(sectorY) + int(sectorZ) * int(sectorZ) < int(CORE_RADIUS_IN_SECTORS) * int(CORE_RADIUS_IN_SECTORS)) {
            // Central sphere
            return RealMath.fraction(9, 10);
        } else if (int(sectorX) * int(sectorX) + int(sectorZ) * int(sectorZ) < int(DISK_RADIUS_IN_SECTORS) * int(DISK_RADIUS_IN_SECTORS) && sectorY < DISK_HALFHEIGHT_IN_SECTORS && sectorY > -DISK_HALFHEIGHT_IN_SECTORS) {
            // Disk
            return RealMath.fraction(1, 2);
        } else {
            // General background object rate
            // Set so that some background sectors do indeed have an object in them.
            return RealMath.fraction(1, 60);
        }
    }
    
    /**
     * Get the number of objects in the sector at the given coordinates.
     */
    function getSectorObjectCount(int16 sectorX, int16 sectorY, int16 sectorZ) public view onlyControlledAccess returns (uint16) {
        // Decide on a base item count
        RNG.RandNode memory sectorNode = root.derive(sectorX).derive(sectorY).derive(sectorZ);
        int16 maxObjects = sectorNode.derive("count").d(3, 20, 0);
        
        // Multiply by the density function
        int128 presentObjects = RealMath.toReal(maxObjects).mul(getGalaxyDensity(sectorX, sectorY, sectorZ));
        
        return uint16(RealMath.fromReal(RealMath.round(presentObjects)));
    }
    
    /**
     * Get the seed for an object in a sector.
     */
    function getSectorObjectSeed(int16 sectorX, int16 sectorY, int16 sectorZ, uint16 object) public view onlyControlledAccess returns (bytes32) {
        return root.derive(sectorX).derive(sectorY).derive(sectorZ).derive(uint(object))._hash;
    }
    
    /**
     * Get the class of the star system with the given seed.
     */
    function getObjectClass(bytes32 seed) public view onlyControlledAccess returns (ObjectClass) {
        // Make a node for rolling for the class.
        RNG.RandNode memory node = RNG.RandNode(seed).derive("class");
        // Roll an impractical d10,000
        int88 roll = node.getIntBetween(1, 10000);
        
        if (roll == 1) {
            // Should be a black hole
            return ObjectClass.BlackHole;
        } else if (roll <= 3) {
            // Should be a neutron star
            return ObjectClass.NeutronStar;
        } else if (roll <= 700) {
            // Should be a white dwarf
            return ObjectClass.WhiteDwarf;
        } else if (roll <= 9900) {
            // Most things are main sequence
            return ObjectClass.MainSequence;
        } else if (roll <= 9990) {
            return ObjectClass.Giant;
        } else {
            return ObjectClass.Supergiant;
        }
    }
    
    /**
     * Get the spectral type for an object with the given seed of the given class.
     */
    function getObjectSpectralType(bytes32 seed, ObjectClass objectClass) public view onlyControlledAccess returns (SpectralType) {
        RNG.RandNode memory node = RNG.RandNode(seed).derive("type");
        int88 roll = node.getIntBetween(1, 10000000); // Even more implausible dice

        if (objectClass == ObjectClass.MainSequence) {
            if (roll <= 3) {
                return SpectralType.TypeO;
            } else if (roll <= 13003) {
                return SpectralType.TypeB;
            } else if (roll <= 73003) {
                return SpectralType.TypeA;
            } else if (roll <= 373003) {
                return SpectralType.TypeF;
            } else if (roll <= 1133003) {
                return SpectralType.TypeG;
            } else if (roll <= 2343003) {
                return SpectralType.TypeK;
            } else {
                return SpectralType.TypeM;
            }
        } else if (objectClass == ObjectClass.Giant) {
            if (roll <= 500000) {
                return SpectralType.TypeF;
            } else if (roll <= 1000000) {
                return SpectralType.TypeG;
            } else if (roll <= 5500000) {
                return SpectralType.TypeK;
            } else {
                return SpectralType.TypeM;
            }
        } else if (objectClass == ObjectClass.Supergiant) {
            if (roll <= 1000000) {
                return SpectralType.TypeB;
            } else if (roll <= 2000000) {
                return SpectralType.TypeA;
            } else if (roll <= 4000000) {
                return SpectralType.TypeF;
            } else if (roll <= 6000000) {
                return SpectralType.TypeG;
            } else if (roll <= 8000000) {
                return SpectralType.TypeK;
            } else {
                return SpectralType.TypeM;
            }
        } else {
            // TODO: No spectral class for anyone else.
            return SpectralType.NotApplicable;
        }
        
    }
    
    /**
     * Get the position of a star within its sector, as reals from 0 to 25.
     * Note that stars may end up implausibly close together. Such is life in the Macroverse.
     */
    function getObjectPosition(bytes32 seed) public view onlyControlledAccess returns (int128 realX, int128 realY, int128 realZ) {
        RNG.RandNode memory node = RNG.RandNode(seed).derive("position");
        
        realX = node.derive("x").getRealBetween(RealMath.toReal(0), RealMath.toReal(25));
        realY = node.derive("y").getRealBetween(RealMath.toReal(0), RealMath.toReal(25));
        realZ = node.derive("z").getRealBetween(RealMath.toReal(0), RealMath.toReal(25));
    }
    
    /**
     * Get the mass of a star, in solar masses as a real, given its seed and class and spectral type.
     */
    function getObjectMass(bytes32 seed, ObjectClass objectClass, SpectralType spectralType) public view onlyControlledAccess returns (int128) {
        RNG.RandNode memory node = RNG.RandNode(seed).derive("mass");
         
        if (objectClass == ObjectClass.BlackHole) {
            return node.getRealBetween(RealMath.toReal(5), RealMath.toReal(50));
        } else if (objectClass == ObjectClass.NeutronStar) {
            return node.getRealBetween(RealMath.fraction(11, 10), RealMath.toReal(2));
        } else if (objectClass == ObjectClass.WhiteDwarf) {
            return node.getRealBetween(RealMath.fraction(3, 10), RealMath.fraction(11, 10));
        } else if (objectClass == ObjectClass.MainSequence) {
            if (spectralType == SpectralType.TypeO) {
                return node.getRealBetween(RealMath.toReal(16), RealMath.toReal(40));
            } else if (spectralType == SpectralType.TypeB) {
                return node.getRealBetween(RealMath.fraction(21, 10), RealMath.toReal(16));
            } else if (spectralType == SpectralType.TypeA) {
                return node.getRealBetween(RealMath.fraction(14, 10), RealMath.fraction(21, 10));
            } else if (spectralType == SpectralType.TypeF) {
                return node.getRealBetween(RealMath.fraction(104, 100), RealMath.fraction(14, 10));
            } else if (spectralType == SpectralType.TypeG) {
                return node.getRealBetween(RealMath.fraction(80, 100), RealMath.fraction(104, 100));
            } else if (spectralType == SpectralType.TypeK) {
                return node.getRealBetween(RealMath.fraction(45, 100), RealMath.fraction(80, 100));
            } else if (spectralType == SpectralType.TypeM) {
                return node.getRealBetween(RealMath.fraction(8, 100), RealMath.fraction(45, 100));
            }
        } else if (objectClass == ObjectClass.Giant) {
            // Just make it really big
            return node.getRealBetween(RealMath.toReal(40), RealMath.toReal(50));
        } else if (objectClass == ObjectClass.Supergiant) {
            // Just make it really, really big
            return node.getRealBetween(RealMath.toReal(50), RealMath.toReal(70));
        }
    }
    
    /**
     * Determine if the given star has any orbiting planets or not.
     */
    function getObjectHasPlanets(bytes32 seed, ObjectClass objectClass, SpectralType spectralType) public view onlyControlledAccess returns (bool) {
        RNG.RandNode memory node = RNG.RandNode(seed).derive("hasplanets");
        int88 roll = node.getIntBetween(1, 1000);

        if (objectClass == ObjectClass.MainSequence) {
            if (spectralType == SpectralType.TypeO || spectralType == SpectralType.TypeB) {
                return (roll <= 1);
            } else if (spectralType == SpectralType.TypeA) {
                return (roll <= 500);
            } else if (spectralType == SpectralType.TypeF || spectralType == SpectralType.TypeG || spectralType == SpectralType.TypeK) {
                return (roll <= 990);
            } else if (spectralType == SpectralType.TypeM) {
                return (roll <= 634);
            }
        } else if (objectClass == ObjectClass.Giant) {
            return (roll <= 90);
        } else if (objectClass == ObjectClass.Supergiant) {
            return (roll <= 50);
        } else {
           // Black hole, neutron star, or white dwarf
           return (roll <= 70);
        }
    }
    

}

// This code is part of Macroverse and is licensed: UNLICENSED

/**
 * Provides extra methods not present in the original MacroverseStarGenerator
 * that generate new properties of the galaxy's stars. Meant to be deployed and
 * queried alongside the original.
 *
 * Permission to call methods on this contract is regulated by a configurable
 * AccessControl contract. One such set of terms might be to require that the
 * account initiating a transaction have a certain minimum MRV token balance.
 *
 * The owner of this contract reserves the right to supersede it with a new
 * version, and to modify the terms for accessing this contract, at any time,
 * for any reason, and without notice. This includes the right to indefinitely
 * or permanently suspend or terminate access to this contract for any person,
 * account, or other contract, or for all persons, accounts, or other
 * contracts. The owner also reserves the right to not do any of the above.
 */
contract MacroverseStarGeneratorPatch1 is ControlledAccess {
    // TODO: RNG doesn't get linked against because we can't pass the struct to the library...
    using RNG for *;
    using RealMath for *;
    // No SafeMath or it might confuse RealMath

    /**@dev
     * How many fractional bits are there?
     */
    int256 constant REAL_FBITS = 40;
    
    /**@dev
     * What's the first non-fractional bit
     */
    int128 constant REAL_ONE = int128(1) << int128(REAL_FBITS);

    /**@dev
     * What's the last fractional bit?
     */
    int128 constant REAL_HALF = REAL_ONE >> 1;

    /**@dev
     * It is useful to have Pi around.
     * We can't pull it in from the library.
     */
    int128 constant REAL_PI = 3454217652358;

    /**
     * Deploy a new copy of the patch generator.
     * Use the contract at the given address to regulate access.
     */
    constructor(address accessControlAddress) ControlledAccess(accessControlAddress) public {
        // Nothing to do!
    }

    /**
     * If the object has any planets at all, get the planet count. Will return
     * nonzero numbers always, so make sure to check getObjectHasPlanets in the
     * Star Generator.
     */
    function getObjectPlanetCount(bytes32 starSeed, MacroverseStarGenerator.ObjectClass objectClass,
        MacroverseStarGenerator.SpectralType spectralType) public view onlyControlledAccess returns (uint16) {
        
        RNG.RandNode memory node = RNG.RandNode(starSeed).derive("planetcount");
        
        
        uint16 limit;

        if (objectClass == MacroverseStarGenerator.ObjectClass.MainSequence) {
            if (spectralType == MacroverseStarGenerator.SpectralType.TypeO ||
                spectralType == MacroverseStarGenerator.SpectralType.TypeB) {
                
                limit = 5;
            } else if (spectralType == MacroverseStarGenerator.SpectralType.TypeA) {
                limit = 7;
            } else if (spectralType == MacroverseStarGenerator.SpectralType.TypeF ||
                spectralType == MacroverseStarGenerator.SpectralType.TypeG ||
                spectralType == MacroverseStarGenerator.SpectralType.TypeK) {
                
                limit = 12;
            } else if (spectralType == MacroverseStarGenerator.SpectralType.TypeM) {
                limit = 14;
            }
        } else if (objectClass == MacroverseStarGenerator.ObjectClass.Giant) {
            limit = 2;
        } else if (objectClass == MacroverseStarGenerator.ObjectClass.Supergiant) {
            limit = 2;
        } else {
           // Black hole, neutron star, or white dwarf
           limit = 2;
        }
        
        uint16 roll = uint16(node.getIntBetween(1, int88(limit + 1)));
        
        return roll;
    }

    /**
     * Compute the luminosity of a stellar object given its mass and class.
     * We didn't define this in the star generator, but we need it for the planet generator.
     *
     * Returns luminosity in solar luminosities.
     */
    function getObjectLuminosity(bytes32 starSeed, MacroverseStarGenerator.ObjectClass objectClass, int128 realObjectMass) public view onlyControlledAccess returns (int128) {
        
        RNG.RandNode memory node = RNG.RandNode(starSeed);

        int128 realBaseLuminosity;
        if (objectClass == MacroverseStarGenerator.ObjectClass.BlackHole) {
            // Black hole luminosity is going to be from the accretion disk.
            // See <https://astronomy.stackexchange.com/q/12567>
            // We'll return pretty much whatever and user code can back-fill the accretion disk if any.
            if(node.derive("accretiondisk").getBool()) {
                // These aren't absurd masses; they're on the order of world annual food production per second.
                realBaseLuminosity = node.derive("luminosity").getRealBetween(RealMath.toReal(1), RealMath.toReal(5));
            } else {
                // No accretion disk
                realBaseLuminosity = 0;
            }
        } else if (objectClass == MacroverseStarGenerator.ObjectClass.NeutronStar) {
            // These will be dim and not really mass-related
            realBaseLuminosity = node.derive("luminosity").getRealBetween(RealMath.fraction(1, 20), RealMath.fraction(2, 10));
        } else if (objectClass == MacroverseStarGenerator.ObjectClass.WhiteDwarf) {
            // These are also dim
            realBaseLuminosity = RealMath.pow(realObjectMass.mul(REAL_HALF), RealMath.fraction(35, 10));
        } else {
            // Normal stars follow a normal mass-lumoinosity relationship
            realBaseLuminosity = RealMath.pow(realObjectMass, RealMath.fraction(35, 10));
        }
        
        // Perturb the generated luminosity for fun
        return realBaseLuminosity.mul(node.derive("luminosityScale").getRealBetween(RealMath.fraction(95, 100), RealMath.fraction(105, 100)));
    }

    /**
     * Get the inner and outer boundaries of the habitable zone for a star, in meters, based on its luminosity in solar luminosities.
     * This is just a rule-of-thumb; actual habitability is going to depend on atmosphere (see Venus, Mars)
     */
    function getObjectHabitableZone(int128 realLuminosity) public view onlyControlledAccess returns (int128 realInnerRadius, int128 realOuterRadius) {
        // Light per unit area scales with the square of the distance, so if we move twice as far out we get 1/4 the light.
        // So if our star is half as bright as the sun, the habitable zone radius is 1/sqrt(2) = sqrt(1/2) as big
        // So we scale this by the square root of the luminosity.
        int128 realScale = RealMath.sqrt(realLuminosity);
        // Wikipedia says nobody knows the bounds for Sol, but let's say 0.75 to 2.0 AU to be nice and round and also sort of average
        realInnerRadius = RealMath.toReal(112198400000).mul(realScale);
        realOuterRadius = RealMath.toReal(299195700000).mul(realScale);
    }

    /**
     * Get the Y and X axis angles for the rotational axis of the object, relative to galactic up.
     *
     * Defines a vector normal to the XY plane for the star system's local
     * coordinates, relative to which orbital inclinations are measured.
     *
     * The object's rotation axis starts straight up towards galactic +Z.
     * Then the object is rotated in Y, around the axis by the Y angle.
     * Then it is rotated forward (what would be toward the viewer) in the
     * object's transformed X by the X axis angle.
     * Both angles are in radians.
     * The X angle is never negative, because the Y angle would just be the opposite direction.
     * It is also never greater than Pi, because otherwise we would just measure around the other way.
     *
     * Most users won't need this unless they want to be able to work out
     * directions from things in one system to other systems.
     */
    function getObjectYXAxisAngles(bytes32 seed) public view onlyControlledAccess returns (int128 realYRadians, int128 realXRadians) {
        // The Y angle should be uniform over all angles.
        realYRadians = RNG.RandNode(seed).derive("axisy").getRealBetween(-REAL_PI, REAL_PI);

        // The X angle will also be uniform from 0 to pi.
        // This makes us pick a point in a flat 2d angle plane, so we will, on the sphere, have more density towards the poles.
        // See http://corysimon.github.io/articles/uniformdistn-on-sphere/
        // Being uniform on the sphere would require some trig, and non-uniformity makes sense since the galaxy has a preferred plane.
        realXRadians = RNG.RandNode(seed).derive("axisx").getRealBetween(0, REAL_PI);
        
    }

    

}

// This code is part of Macroverse and is licensed: UNLICENSED

/**
 * Library which exists to hold types shared across the Macroverse ecosystem.
 * Never actually needs to be linked into any dependents, since it has no functions.
 */
library Macroverse {

    /**
     * Define different types of planet or moon.
     * 
     * There are two main progressions:
     * Asteroidal, Lunar, Terrestrial, Jovian are rocky things.
     * Cometary, Europan, Panthalassic, Neptunian are icy/watery things, depending on temperature.
     * The last thing in each series is the gas/ice giant.
     *
     * Asteroidal and Cometary are only valid for moons; we don't track such tiny bodies at system scale.
     *
     * We also have rings and asteroid belts. Rings can only be around planets, and we fake the Roche limit math we really should do.
     * 
     */
    enum WorldClass {Asteroidal, Lunar, Terrestrial, Jovian, Cometary, Europan, Panthalassic, Neptunian, Ring, AsteroidBelt}

}

// This code is part of Macroverse and is licensed: UNLICENSED

/**
 * Contains a portion of the MacroverseStstemGenerator implementation code.
 * The contract is split up due to contract size limitations.
 * We can't do access control here sadly.
 */
library MacroverseSystemGeneratorPart1 {
    // TODO: RNG doesn't get linked against because we can't pass the struct to the library...
    using RNG for *;
    using RealMath for *;
    // No SafeMath or it might confuse RealMath

    /**@dev
     * It is useful to have Pi around.
     * We can't pull it in from the library.
     */
    int128 constant REAL_PI = 3454217652358;

    /**@dev
     * Also perpare pi/2
     */
    int128 constant REAL_HALF_PI = REAL_PI >> 1;

    /**@dev
     * How many fractional bits are there?
     */
    int256 constant REAL_FBITS = 40;
    
    /**@dev
     * What's the first non-fractional bit
     */
    int128 constant REAL_ONE = int128(1) << int128(REAL_FBITS);
    
    /**@dev
     * What's the last fractional bit?
     */
    int128 constant REAL_HALF = REAL_ONE >> 1;
    
    /**@dev
     * What's two? Two is pretty useful.
     */
    int128 constant REAL_TWO = REAL_ONE << int128(1);

    /**@dev
     * And zero
     */
    int128 constant REAL_ZERO = 0;

    /**
     * Get the seed for a planet or moon from the seed for its parent (star or planet) and its child number.
     */
    function getWorldSeed(bytes32 parentSeed, uint16 childNumber) public pure returns (bytes32) {
        return RNG.RandNode(parentSeed).derive(uint(childNumber))._hash;
    }
    
    /**
     * Decide what kind of planet a given planet is.
     * It depends on its place in the order.
     * Takes the *planet*'s seed, its number, and the total planets in the system.
     */
    function getPlanetClass(bytes32 seed, uint16 planetNumber, uint16 totalPlanets) public pure returns (Macroverse.WorldClass) {
        // TODO: do something based on metallicity?
        RNG.RandNode memory node = RNG.RandNode(seed).derive("class");
        
        int88 roll = node.getIntBetween(0, 100);
        
        // Inner planets should be more planet-y, ideally smaller
        // Asteroid belts shouldn't be first that often
        
        if (planetNumber == 0 && totalPlanets != 1) {
            // Innermost planet of a multi-planet system
            // No asteroid belts allowed!
            // Also avoid too much watery stuff here because we don't want to deal with the water having been supposed to boil off.
            if (roll < 69) {
                return Macroverse.WorldClass.Lunar;
            } else if (roll < 70) {
                return Macroverse.WorldClass.Europan;
            } else if (roll < 79) {
                return Macroverse.WorldClass.Terrestrial;
            } else if (roll < 80) {
                return Macroverse.WorldClass.Panthalassic;
            } else if (roll < 90) {
                return Macroverse.WorldClass.Neptunian;
            } else {
                return Macroverse.WorldClass.Jovian;
            }
        } else if (planetNumber < totalPlanets / 2) {
            // Inner system
            if (roll < 15) {
                return Macroverse.WorldClass.Lunar;
            } else if (roll < 20) {
                return Macroverse.WorldClass.Europan;
            } else if (roll < 35) {
                return Macroverse.WorldClass.Terrestrial;
            } else if (roll < 40) {
                return Macroverse.WorldClass.Panthalassic;
            } else if (roll < 70) {
                return Macroverse.WorldClass.Neptunian;
            } else if (roll < 80) {
                return Macroverse.WorldClass.Jovian;
            } else {
                return Macroverse.WorldClass.AsteroidBelt;
            }
        } else {
            // Outer system
            if (roll < 5) {
                return Macroverse.WorldClass.Lunar;
            } else if (roll < 20) {
                return Macroverse.WorldClass.Europan;
            } else if (roll < 22) {
                return Macroverse.WorldClass.Terrestrial;
            } else if (roll < 30) {
                return Macroverse.WorldClass.Panthalassic;
            } else if (roll < 60) {
                return Macroverse.WorldClass.Neptunian;
            } else if (roll < 90) {
                return Macroverse.WorldClass.Jovian;
            } else {
                return Macroverse.WorldClass.AsteroidBelt;
            }
        }
    }
    
    /**
     * Decide what the mass of the planet or moon is. We can't do even the mass of
     * Jupiter in the ~88 bits we have in a real (should we have used int256 as
     * the backing type?) so we work in Earth masses.
     *
     * Also produces the masses for moons.
     */
    function getWorldMass(bytes32 seed, Macroverse.WorldClass class) public pure returns (int128) {
        RNG.RandNode memory node = RNG.RandNode(seed).derive("mass");
        
        if (class == Macroverse.WorldClass.Asteroidal) {
            // For tiny bodies like this we work in nano-earths
            return node.getRealBetween(RealMath.fraction(1, 1000000000), RealMath.fraction(10, 1000000000));
        } else if (class == Macroverse.WorldClass.Cometary) {
            return node.getRealBetween(RealMath.fraction(1, 1000000000), RealMath.fraction(10, 1000000000));
        } else if (class == Macroverse.WorldClass.Lunar) {
            return node.getRealBetween(RealMath.fraction(1, 100), RealMath.fraction(9, 100));
        } else if (class == Macroverse.WorldClass.Europan) {
            return node.getRealBetween(RealMath.fraction(8, 1000), RealMath.fraction(80, 1000));
        } else if (class == Macroverse.WorldClass.Terrestrial) {
            return node.getRealBetween(RealMath.fraction(10, 100), RealMath.toReal(9));
        } else if (class == Macroverse.WorldClass.Panthalassic) {
            return node.getRealBetween(RealMath.fraction(80, 1000), RealMath.toReal(9));
        } else if (class == Macroverse.WorldClass.Neptunian) {
            return node.getRealBetween(RealMath.toReal(7), RealMath.toReal(20));
        } else if (class == Macroverse.WorldClass.Jovian) {
            return node.getRealBetween(RealMath.toReal(50), RealMath.toReal(400));
        } else if (class == Macroverse.WorldClass.AsteroidBelt) {
            return node.getRealBetween(RealMath.fraction(1, 100), RealMath.fraction(20, 100));
        } else if (class == Macroverse.WorldClass.Ring) {
            // Saturn's rings are maybe about 5-15 micro-earths
            return node.getRealBetween(RealMath.fraction(1, 1000000), RealMath.fraction(20, 1000000));
        } else {
            // Not real!
            revert();
        }
    }
    
    // Define the orbit shape

    /**
     * Given the parent star's habitable zone bounds, the planet seed, the planet class
     * to be generated, and the "clearance" radius around the previous planet
     * in meters, produces orbit statistics (periapsis, apoapsis, and
     * clearance) in meters.
     *
     * The first planet uses a previous clearance of 0.
     *
     * TODO: realOuterRadius from the habitable zone never gets used. We should remove it.
     */
    function getPlanetOrbitDimensions(int128 realInnerRadius, int128 realOuterRadius, bytes32 seed, Macroverse.WorldClass class, int128 realPrevClearance)
        public pure returns (int128 realPeriapsis, int128 realApoapsis, int128 realClearance) {

        // We scale all the random generation around the habitable zone distance.

        // Make the planet RNG node to use for all the computations
        RNG.RandNode memory node = RNG.RandNode(seed);
        
        // Compute the statistics with their own functions
        realPeriapsis = getPlanetPeriapsis(realInnerRadius, realOuterRadius, node, class, realPrevClearance);
        realApoapsis = getPlanetApoapsis(realInnerRadius, realOuterRadius, node, class, realPeriapsis);
        realClearance = getPlanetClearance(realInnerRadius, realOuterRadius, node, class, realApoapsis);
    }

    /**
     * Decide what the planet's orbit's periapsis is, in meters.
     * This is the first statistic about the orbit to be generated.
     *
     * For the first planet, realPrevClearance is 0. For others, it is the
     * clearance (i.e. distance from star that the planet has cleared out) of
     * the previous planet.
     */
    function getPlanetPeriapsis(int128 realInnerRadius, int128 /* realOuterRadius */, RNG.RandNode memory planetNode, Macroverse.WorldClass class, int128 realPrevClearance)
        internal pure returns (int128) {
        
        // We're going to sample 2 values and take the minimum, to get a nicer distribution than uniform.
        // We really kind of want a log scale but that's expensive.
        RNG.RandNode memory node1 = planetNode.derive("periapsis");
        RNG.RandNode memory node2 = planetNode.derive("periapsis2");
        
        // Define minimum and maximum periapsis distance above previous planet's
        // cleared band. Work in % of the habitable zone inner radius.
        int88 minimum;
        int88 maximum;
        if (class == Macroverse.WorldClass.Lunar || class == Macroverse.WorldClass.Europan) {
            minimum = 20;
            maximum = 60;
        } else if (class == Macroverse.WorldClass.Terrestrial || class == Macroverse.WorldClass.Panthalassic) {
            minimum = 20;
            maximum = 70;
        } else if (class == Macroverse.WorldClass.Neptunian) {
            minimum = 50;
            maximum = 1000;
        } else if (class == Macroverse.WorldClass.Jovian) {
            minimum = 300;
            maximum = 500;
        } else if (class == Macroverse.WorldClass.AsteroidBelt) {
            minimum = 20;
            maximum = 500;
        } else {
            // Not real!
            revert();
        }
        
        int128 realSeparation1 = node1.getRealBetween(RealMath.toReal(minimum), RealMath.toReal(maximum));
        int128 realSeparation2 = node2.getRealBetween(RealMath.toReal(minimum), RealMath.toReal(maximum));
        int128 realSeparation = realSeparation1 < realSeparation2 ? realSeparation1 : realSeparation2;
        return realPrevClearance + RealMath.mul(realSeparation, realInnerRadius).div(RealMath.toReal(100)); 
    }
    
    /**
     * Decide what the planet's orbit's apoapsis is, in meters.
     * This is the second statistic about the orbit to be generated.
     */
    function getPlanetApoapsis(int128 realInnerRadius, int128 /* realOuterRadius */, RNG.RandNode memory planetNode, Macroverse.WorldClass class, int128 realPeriapsis)
        internal pure returns (int128) {
        
        RNG.RandNode memory node1 = planetNode.derive("apoapsis");
        RNG.RandNode memory node2 = planetNode.derive("apoapsis2");
        
        // Define minimum and maximum apoapsis distance above planet's periapsis.
        // Work in % of the habitable zone inner radius.
        int88 minimum;
        int88 maximum;
        if (class == Macroverse.WorldClass.Lunar || class == Macroverse.WorldClass.Europan) {
            minimum = 0;
            maximum = 6;
        } else if (class == Macroverse.WorldClass.Terrestrial || class == Macroverse.WorldClass.Panthalassic) {
            minimum = 0;
            maximum = 10;
        } else if (class == Macroverse.WorldClass.Neptunian) {
            minimum = 20;
            maximum = 500;
        } else if (class == Macroverse.WorldClass.Jovian) {
            minimum = 10;
            maximum = 200;
        } else if (class == Macroverse.WorldClass.AsteroidBelt) {
            minimum = 10;
            maximum = 100;
        } else {
            // Not real!
            revert();
        }
        
        int128 realWidth1 = node1.getRealBetween(RealMath.toReal(minimum), RealMath.toReal(maximum));
        int128 realWidth2 = node2.getRealBetween(RealMath.toReal(minimum), RealMath.toReal(maximum));
        int128 realWidth = realWidth1 < realWidth2 ? realWidth1 : realWidth2; 
        return realPeriapsis + RealMath.mul(realWidth, realInnerRadius).div(RealMath.toReal(100)); 
    }
    
    /**
     * Decide how far out the cleared band after the planet's orbit is.
     */
    function getPlanetClearance(int128 realInnerRadius, int128 /* realOuterRadius */, RNG.RandNode memory planetNode, Macroverse.WorldClass class, int128 realApoapsis)
        internal pure returns (int128) {
        
        RNG.RandNode memory node1 = planetNode.derive("cleared");
        RNG.RandNode memory node2 = planetNode.derive("cleared2");
        
        // Define minimum and maximum clearance.
        // Work in % of the habitable zone inner radius.
        int88 minimum;
        int88 maximum;
        if (class == Macroverse.WorldClass.Lunar || class == Macroverse.WorldClass.Europan) {
            minimum = 20;
            maximum = 60;
        } else if (class == Macroverse.WorldClass.Terrestrial || class == Macroverse.WorldClass.Panthalassic) {
            minimum = 40;
            maximum = 70;
        } else if (class == Macroverse.WorldClass.Neptunian) {
            minimum = 300;
            maximum = 700;
        } else if (class == Macroverse.WorldClass.Jovian) {
            minimum = 300;
            maximum = 500;
        } else if (class == Macroverse.WorldClass.AsteroidBelt) {
            minimum = 20;
            maximum = 500;
        } else {
            // Not real!
            revert();
        }
        
        int128 realSeparation1 = node1.getRealBetween(RealMath.toReal(minimum), RealMath.toReal(maximum));
        int128 realSeparation2 = node2.getRealBetween(RealMath.toReal(minimum), RealMath.toReal(maximum));
        int128 realSeparation = realSeparation1 < realSeparation2 ? realSeparation1 : realSeparation2;
        return realApoapsis + RealMath.mul(realSeparation, realInnerRadius).div(RealMath.toReal(100)); 
    }
}

// This code is part of Macroverse and is licensed: UNLICENSED

/**
 * Contains a portion of the MacroverseStstemGenerator implementation code.
 * The contract is split up due to contract size limitations.
 * We can't do access control here sadly.
 */
library MacroverseSystemGeneratorPart2 {
    using RNG for *;
    using RealMath for *;
    // No SafeMath or it might confuse RealMath

    /**@dev
     * It is useful to have Pi around.
     * We can't pull it in from the library.
     */
    int128 constant REAL_PI = 3454217652358;

    /**@dev
     * Also perpare pi/2
     */
    int128 constant REAL_HALF_PI = REAL_PI >> 1;

    /**@dev
     * How many fractional bits are there?
     */
    int256 constant REAL_FBITS = 40;
    
    /**@dev
     * What's the first non-fractional bit
     */
    int128 constant REAL_ONE = int128(1) << int128(REAL_FBITS);
    
    /**@dev
     * What's the last fractional bit?
     */
    int128 constant REAL_HALF = REAL_ONE >> 1;
    
    /**@dev
     * What's two? Two is pretty useful.
     */
    int128 constant REAL_TWO = REAL_ONE << int128(1);

    /**@dev
     * And zero
     */
    int128 constant REAL_ZERO = 0;
    
    /**
     * Convert from periapsis and apoapsis to semimajor axis and eccentricity.
     */
    function convertOrbitShape(int128 realPeriapsis, int128 realApoapsis) public pure returns (int128 realSemimajor, int128 realEccentricity) {
        // Semimajor axis is average of apoapsis and periapsis
        realSemimajor = RealMath.div(realApoapsis + realPeriapsis, RealMath.toReal(2));
        
        // Eccentricity is ratio of difference and sum
        realEccentricity = RealMath.div(realApoapsis - realPeriapsis, realApoapsis + realPeriapsis);
    }
    
    // Define the orbital plane
    
    /**
     * Get the longitude of the ascending node for a planet or moon. For
     * planets, this is the angle from system +X to ascending node. For
     * moons, we use system +X transformed into the planet's equatorial plane
     * by the equatorial plane/rotation axis angles.
     */ 
    function getWorldLan(bytes32 seed) public pure returns (int128) {
        RNG.RandNode memory node = RNG.RandNode(seed).derive("LAN");
        // Angles should be uniform from 0 to 2 PI
        return node.getRealBetween(RealMath.toReal(0), RealMath.mul(RealMath.toReal(2), REAL_PI));
    }
    
    /**
     * Get the inclination (angle from system XZ plane to orbital plane at the ascending node) for a planet.
     * For a moon, this is done in the moon generator instead.
     * Inclination is always positive. If it were negative, the ascending node would really be the descending node.
     * Result is a real in radians.
     */ 
    function getPlanetInclination(bytes32 seed, Macroverse.WorldClass class) public pure returns (int128) {
        RNG.RandNode memory node = RNG.RandNode(seed).derive("inclination");
    
        // Define minimum and maximum inclinations in milliradians
        // 175 milliradians = ~ 10 degrees
        int88 minimum;
        int88 maximum;
        if (class == Macroverse.WorldClass.Lunar || class == Macroverse.WorldClass.Europan) {
            minimum = 0;
            maximum = 175;
        } else if (class == Macroverse.WorldClass.Terrestrial || class == Macroverse.WorldClass.Panthalassic) {
            minimum = 0;
            maximum = 87;
        } else if (class == Macroverse.WorldClass.Neptunian) {
            minimum = 0;
            maximum = 35;
        } else if (class == Macroverse.WorldClass.Jovian) {
            minimum = 0;
            maximum = 52;
        } else if (class == Macroverse.WorldClass.AsteroidBelt) {
            minimum = 0;
            maximum = 262;
        } else {
            // Not real!
            revert();
        }
        
        // Decide if we should be retrograde (PI-ish inclination)
        int128 real_retrograde_offset = 0;
        if (node.derive("retrograde").d(1, 100, 0) < 3) {
            // This planet ought to move retrograde
            real_retrograde_offset = REAL_PI;
        }

        return real_retrograde_offset + RealMath.div(node.getRealBetween(RealMath.toReal(minimum), RealMath.toReal(maximum)), RealMath.toReal(1000));    
    }
    
    // Define the orbit's embedding in the plane (and in time)
    
    /**
     * Get the argument of periapsis (angle from ascending node to periapsis position, in the orbital plane) for a planet or moon.
     */
    function getWorldAop(bytes32 seed) public pure returns (int128) {
        RNG.RandNode memory node = RNG.RandNode(seed).derive("AOP");
        // Angles should be uniform from 0 to 2 PI.
        // We already made sure planets/moons wouldn't get too close together when laying out the orbits.
        return node.getRealBetween(RealMath.toReal(0), RealMath.mul(RealMath.toReal(2), REAL_PI));
    }
    
    /**
     * Get the mean anomaly (which sweeps from 0 at periapsis to 2 pi at the next periapsis) at epoch (time 0) for a planet or moon.
     */
    function getWorldMeanAnomalyAtEpoch(bytes32 seed) public pure returns (int128) {
        RNG.RandNode memory node = RNG.RandNode(seed).derive("MAE");
        // Angles should be uniform from 0 to 2 PI.
        return node.getRealBetween(RealMath.toReal(0), RealMath.mul(RealMath.toReal(2), REAL_PI));
    }

    /**
     * Determine if the world is tidally locked, given its seed and its number
     * out from the parent, starting with 0.
     * Overrides getWorldZXAxisAngles and getWorldSpinRate. 
     * Not used for asteroid belts or rings.
     */
    function isTidallyLocked(bytes32 seed, uint16 worldNumber) public pure returns (bool) {
        // Tidal lock should be common near the parent and less common further out.
        return RNG.RandNode(seed).derive("tidal_lock").getReal() < RealMath.fraction(1, int88(worldNumber + 1));
    }

    /**
     * Get the Y and X axis angles for a world, in radians.
     * The world's rotation axis starts straight up in its orbital plane.
     * Then the planet is rotated in Y, around the axis by the Y angle.
     * Then it is rotated forward (what would be toward the pureer) in the
     * world's transformed X by the X axis angle.
     * Both angles are in radians.
     * The X angle is never negative, because the Y angle would just be the opposite direction.
     * It is also never greater than Pi, because otherwise we would just measure around the other way.
     * Not used for asteroid belts or rings.
     * For a tidally locked world, ignore these values and use 0 for both angles.
     */
    function getWorldYXAxisAngles(bytes32 seed) public pure returns (int128 realYRadians, int128 realXRadians) {
       
        // The Y angle should be uniform over all angles.
        realYRadians = RNG.RandNode(seed).derive("axisy").getRealBetween(-REAL_PI, REAL_PI);

        // The X angle will be mostly small positive or negative, with some sideways and some near Pi/2 (meaning retrograde rotation)
        int16 tilt_die = RNG.RandNode(seed).derive("tilt").d(1, 6, 0);
        
        // Start with low tilt, right side up
        // Earth is like 0.38 radians overall
        int128 real_tilt_limit = REAL_HALF;
        if (tilt_die >= 5) {
            // Be high tilt
            real_tilt_limit = REAL_HALF_PI;
        }
    
        RNG.RandNode memory x_node = RNG.RandNode(seed).derive("axisx");
        realXRadians = x_node.getRealBetween(0, real_tilt_limit);

        if (tilt_die == 4 || tilt_die == 5) {
            // Flip so the tilt we have is relative to upside-down
            realXRadians = REAL_PI - realXRadians;
        }

        // So we should have 1/2 low tilt prograde, 1/6 low tilt retrograde, 1/6 high tilt retrograde, and 1/6 high tilt prograde
    }

    /**
     * Get the spin rate of the world in radians per Julian year around its axis.
     * For a tidally locked world, ignore this value and use the mean angular
     * motion computed by the OrbitalMechanics contract, given the orbit
     * details.
     * Not used for asteroid belts or rings.
     */
    function getWorldSpinRate(bytes32 seed) public pure returns (int128) {
        // Earth is something like 2k radians per Julian year.
        return RNG.RandNode(seed).derive("spin").getRealBetween(REAL_ZERO, RealMath.toReal(8000)); 
    }

}

// This code is part of Macroverse and is licensed: UNLICENSED

/**
 * Represents a Macroverse generator for planetary systems around stars and
 * other stellar objects.
 *
 * Because of contract size limitations, some code in this contract is shared
 * between planets and moons, while some code is planet-specific. Moon-specific
 * code lives in the MacroverseMoonGenerator.
 *
 * Permission to call methods on this contract is regulated by a configurable
 * AccessControl contract. One such set of terms might be to require that the
 * account initiating a transaction have a certain minimum MRV token balance.
 *
 * The owner of this contract reserves the right to supersede it with a new
 * version, and to modify the terms for accessing this contract, at any time,
 * for any reason, and without notice. This includes the right to indefinitely
 * or permanently suspend or terminate access to this contract for any person,
 * account, or other contract, or for all persons, accounts, or other
 * contracts. The owner also reserves the right to not do any of the above.
 */
contract MacroverseSystemGenerator is ControlledAccess {
    

    /**
     * Deploy a new copy of the MacroverseSystemGenerator.
     */
    constructor(address accessControlAddress) ControlledAccess(accessControlAddress) public {
        // Nothing to do!
    }
    
    /**
     * Get the seed for a planet or moon from the seed for its parent (star or planet) and its child number.
     */
    function getWorldSeed(bytes32 parentSeed, uint16 childNumber) public view onlyControlledAccess returns (bytes32) {
        return MacroverseSystemGeneratorPart1.getWorldSeed(parentSeed, childNumber);
    }
    
    /**
     * Decide what kind of planet a given planet is.
     * It depends on its place in the order.
     * Takes the *planet*'s seed, its number, and the total planets in the system.
     */
    function getPlanetClass(bytes32 seed, uint16 planetNumber, uint16 totalPlanets) public view onlyControlledAccess returns (Macroverse.WorldClass) {
        return MacroverseSystemGeneratorPart1.getPlanetClass(seed, planetNumber, totalPlanets);
    }
    
    /**
     * Decide what the mass of the planet or moon is. We can't do even the mass of
     * Jupiter in the ~88 bits we have in a real (should we have used int256 as
     * the backing type?) so we work in Earth masses.
     *
     * Also produces the masses for moons.
     */
    function getWorldMass(bytes32 seed, Macroverse.WorldClass class) public view onlyControlledAccess returns (int128) {
        return MacroverseSystemGeneratorPart1.getWorldMass(seed, class);
    }
    
    // Define the orbit shape

    /**
     * Given the parent star's habitable zone bounds, the planet seed, the planet class
     * to be generated, and the "clearance" radius around the previous planet
     * in meters, produces orbit statistics (periapsis, apoapsis, and
     * clearance) in meters.
     *
     * The first planet uses a previous clearance of 0.
     *
     * TODO: realOuterRadius from the habitable zone never gets used. We should remove it.
     */
    function getPlanetOrbitDimensions(int128 realInnerRadius, int128 realOuterRadius, bytes32 seed, Macroverse.WorldClass class, int128 realPrevClearance)
        public view onlyControlledAccess returns (int128 realPeriapsis, int128 realApoapsis, int128 realClearance) {
        
        return MacroverseSystemGeneratorPart1.getPlanetOrbitDimensions(realInnerRadius, realOuterRadius, seed, class, realPrevClearance);
    }

    /**
     * Convert from periapsis and apoapsis to semimajor axis and eccentricity.
     */
    function convertOrbitShape(int128 realPeriapsis, int128 realApoapsis) public view onlyControlledAccess returns (int128 realSemimajor, int128 realEccentricity) {
        return MacroverseSystemGeneratorPart2.convertOrbitShape(realPeriapsis, realApoapsis);
    }
    
    // Define the orbital plane
    
    /**
     * Get the longitude of the ascending node for a planet or moon. For
     * planets, this is the angle from system +X to ascending node. For
     * moons, we use system +X transformed into the planet's equatorial plane
     * by the equatorial plane/rotation axis angles.
     */ 
    function getWorldLan(bytes32 seed) public view onlyControlledAccess returns (int128) {
        return MacroverseSystemGeneratorPart2.getWorldLan(seed);
    }
    
    /**
     * Get the inclination (angle from system XZ plane to orbital plane at the ascending node) for a planet.
     * For a moon, this is done in the moon generator instead.
     * Inclination is always positive. If it were negative, the ascending node would really be the descending node.
     * Result is a real in radians.
     */ 
    function getPlanetInclination(bytes32 seed, Macroverse.WorldClass class) public view onlyControlledAccess returns (int128) {
        return MacroverseSystemGeneratorPart2.getPlanetInclination(seed, class);
    }
    
    // Define the orbit's embedding in the plane (and in time)
    
    /**
     * Get the argument of periapsis (angle from ascending node to periapsis position, in the orbital plane) for a planet or moon.
     */
    function getWorldAop(bytes32 seed) public view onlyControlledAccess returns (int128) {
        return MacroverseSystemGeneratorPart2.getWorldAop(seed);
    }
    
    /**
     * Get the mean anomaly (which sweeps from 0 at periapsis to 2 pi at the next periapsis) at epoch (time 0) for a planet or moon.
     */
    function getWorldMeanAnomalyAtEpoch(bytes32 seed) public view onlyControlledAccess returns (int128) {
        return MacroverseSystemGeneratorPart2.getWorldMeanAnomalyAtEpoch(seed);
    }

    /**
     * Determine if the world is tidally locked, given its seed and its number
     * out from the parent, starting with 0.
     * Overrides getWorldZXAxisAngles and getWorldSpinRate. 
     * Not used for asteroid belts or rings.
     */
    function isTidallyLocked(bytes32 seed, uint16 worldNumber) public view onlyControlledAccess returns (bool) {
        return MacroverseSystemGeneratorPart2.isTidallyLocked(seed, worldNumber);
    }

    /**
     * Get the Y and X axis angles for a world, in radians.
     * The world's rotation axis starts straight up in its orbital plane.
     * Then the planet is rotated in Y, around the axis by the Y angle.
     * Then it is rotated forward (what would be toward the viewer) in the
     * world's transformed X by the X axis angle.
     * Both angles are in radians.
     * The X angle is never negative, because the Y angle would just be the opposite direction.
     * It is also never greater than Pi, because otherwise we would just measure around the other way.
     * Not used for asteroid belts or rings.
     * For a tidally locked world, ignore these values and use 0 for both angles.
     */
    function getWorldYXAxisAngles(bytes32 seed) public view onlyControlledAccess returns (int128 realYRadians, int128 realXRadians) {
        return MacroverseSystemGeneratorPart2.getWorldYXAxisAngles(seed); 
    }

    /**
     * Get the spin rate of the world in radians per Julian year around its axis.
     * For a tidally locked world, ignore this value and use the mean angular
     * motion computed by the OrbitalMechanics contract, given the orbit
     * details.
     * Not used for asteroid belts or rings.
     */
    function getWorldSpinRate(bytes32 seed) public view onlyControlledAccess returns (int128) {
        return MacroverseSystemGeneratorPart2.getWorldSpinRate(seed);
    }

}

// This code is part of Macroverse and is licensed: UNLICENSED

/**
 * Represents a Macroverse generator for moons around planets.
 *
 * Not part of the system generator to keep it from going over the contract
 * size limit.
 *
 * Permission to call methods on this contract is regulated by a configurable
 * AccessControl contract. One such set of terms might be to require that the
 * account initiating a transaction have a certain minimum MRV token balance.
 *
 * The owner of this contract reserves the right to supersede it with a new
 * version, and to modify the terms for accessing this contract, at any time,
 * for any reason, and without notice. This includes the right to indefinitely
 * or permanently suspend or terminate access to this contract for any person,
 * account, or other contract, or for all persons, accounts, or other
 * contracts. The owner also reserves the right to not do any of the above.
 */
contract MacroverseMoonGenerator is ControlledAccess {
    // TODO: RNG doesn't get linked against because we can't pass the struct to the library...
    using RNG for *;
    using RealMath for *;
    // No SafeMath or it might confuse RealMath

    /**@dev
     * It is useful to have Pi around.
     * We can't pull it in from the library.
     */
    int128 constant REAL_PI = 3454217652358;

    /**@dev
     * How many fractional bits are there?
     */
    int256 constant REAL_FBITS = 40;

    /**@dev
     * What's the first non-fractional bit
     */
    int128 constant REAL_ONE = int128(1) << int128(REAL_FBITS);
    
    /**@dev
     * What's the last fractional bit?
     */
    int128 constant REAL_HALF = REAL_ONE >> 1;
    
    /**@dev
     * What's two? Two is pretty useful.
     */
    int128 constant REAL_TWO = REAL_ONE << int128(1);

    /**@dev
     * For having moons, we need to be able to run the orbit calculations (all
     * specified in solar masses for the central mass) on
     * Earth-mass-denominated planet masses.
     * See the "Equivalent Planetary masses" table at https://en.wikipedia.org/wiki/Astronomical_system_of_units
     */
    int256 constant EARTH_MASSES_PER_SOLAR_MASS = 332950;

    /**@dev
     * We define the number of earth masses per solar mass as a real, so we don't have to convert it always.
     */
    int128 constant REAL_EARTH_MASSES_PER_SOLAR_MASS = int128(EARTH_MASSES_PER_SOLAR_MASS) * REAL_ONE; 

    /**@dev
     * We also keep a "stowage factor" for planetary material in m^3 per earth mass, at water density, for
     * faking planetary radii during moon orbit calculations.
     */
    int128 constant REAL_M3_PER_EARTH = 6566501804087548000000000000000000; // 6.566501804087548E33 as an int, 5.97219E21 m^3/earth

    /**
     * Deploy a new copy of the MacroverseMoonGenerator.
     */
    constructor(address accessControlAddress) ControlledAccess(accessControlAddress) public {
        // Nothing to do!
    }

    /**
     * Get the number of moons a planet has, using its class. Will sometimes return 0; there is no hasMoons boolean flag to check.
     * The seed of each moon is obtained from the MacroverseSystemGenerator.
     */
    function getPlanetMoonCount(bytes32 planetSeed, Macroverse.WorldClass class) public view onlyControlledAccess returns (uint16) {
        // We will roll n of this kind of die and subtract n to get our moon count
        int8 die;
        int8 n = 2;
        // We can also divide by this
        int8 divisor = 1;

        if (class == Macroverse.WorldClass.Lunar || class == Macroverse.WorldClass.Europan) {
            die = 2;
            divisor = 2;
            // (2d2 - 2) / 2 = 25% chance of 1, 75% chance of 0
        } else if (class == Macroverse.WorldClass.Terrestrial || class == Macroverse.WorldClass.Panthalassic) {
            die = 3;
            // 2d3-2: https://www.wolframalpha.com/input/?i=roll+2d3
        } else if (class == Macroverse.WorldClass.Neptunian) {
            die = 8;
            n = 2;
            divisor = 2;
        } else if (class == Macroverse.WorldClass.Jovian) {
            die = 6;
            n = 3;
            divisor = 2;
        } else if (class == Macroverse.WorldClass.AsteroidBelt) {
            // Just no moons here
            return 0;
        } else {
            // Not real!
            revert();
        }
        
        RNG.RandNode memory node = RNG.RandNode(planetSeed).derive("mooncount");

        uint16 roll = uint16(node.d(n, die, -n) / int88(divisor));
        
        return roll;
    }

    /**
     * Get the class of a moon, given the moon's seed and the class of its parent planet.
     * The seed of each moon is obtained from the MacroverseSystemGenerator.
     * The actual moon body properties (i.e. mass) are generated with the MacroverseSystemGenerator as if it were a planet.
     */
    function getMoonClass(Macroverse.WorldClass parent, bytes32 moonSeed, uint16 moonNumber) public view onlyControlledAccess
        returns (Macroverse.WorldClass) {
        
        // We can have moons of smaller classes than us only.
        // Classes are Asteroidal, Lunar, Terrestrial, Jovian, Cometary, Europan, Panthalassic, Neptunian, Ring, AsteroidBelt
        // AsteroidBelts never have moons and never are moons.
        // Asteroidal and Cometary planets only ever are moons.
        // Moons of the same type (rocky or icy) should be more common than cross-type.
        // Jovians can have Neptunian moons

        RNG.RandNode memory moonNode = RNG.RandNode(moonSeed);

        if (moonNumber == 0 && moonNode.derive("ring").d(1, 100, 0) < 20) {
            // This should be a ring
            return Macroverse.WorldClass.Ring;
        }

        // Should we be of the opposite ice/rock type to our parent?
        bool crossType = moonNode.derive("crosstype").d(1, 100, 0) < 30;

        // What type is our parent? 0=rock, 1=ice
        uint parentType = uint(parent) / 4;

        // What number is the parent in its type? 0=Asteroidal/Cometary, 3=Jovian/Neptunian
        // The types happen to be arranged so this works.
        uint rankInType = uint(parent) % 4;

        if (parent == Macroverse.WorldClass.Jovian && crossType) {
            // Say we can have the gas giant type (Neptunian)
            rankInType++;
        }

        // Roll a lower rank. Bias upward by subtracting 1 instead of 2, so we more or less round up.
        uint lowerRank = uint(moonNode.derive("rank").d(2, int8(rankInType), -1) / 2);

        // Determine the type of the moon (0=rock, 1=ice)
        uint moonType = crossType ? parentType : (parentType + 1) % 2;

        return Macroverse.WorldClass(moonType * 4 + lowerRank);

    }

    /**
     * Use the mass of a planet to compute its moon scale distance in AU. This is sort of like the Roche limit and must be bigger than the planet's radius.
     */
    function getPlanetMoonScale(bytes32 planetSeed, int128 planetRealMass) public view onlyControlledAccess returns (int128) {
        // We assume a fictional inverse density of 1 cm^3/g = 5.9721986E21 cubic meters per earth mass
        // Then we take cube root of volume / (4/3 pi) to get the radius of such a body
        // Then we derive the scale factor from a few times that.

        RNG.RandNode memory node = RNG.RandNode(planetSeed).derive("moonscale");

        // Get the volume. We can definitely hold Jupiter's volume in m^3
        int128 realVolume = planetRealMass.mul(REAL_M3_PER_EARTH);
        
        // Get the radius in meters
        int128 realRadius = realVolume.div(REAL_PI.mul(RealMath.fraction(4, 3))).pow(RealMath.fraction(1, 3));

        // Return some useful, randomized multiple of it.
        return realRadius.mul(node.getRealBetween(RealMath.fraction(5, 2), RealMath.fraction(7, 2)));
    }

    /**
     * Given the parent planet's scale radius, a moon's seed, the moon's class, and the previous moon's outer clearance (or 0), return the orbit shape of the moon.
     * Other orbit properties come from the system generator.
     */
    function getMoonOrbitDimensions(int128 planetMoonScale, bytes32 seed, Macroverse.WorldClass class, int128 realPrevClearance)
        public view onlyControlledAccess returns (int128 realPeriapsis, int128 realApoapsis, int128 realClearance) {

        RNG.RandNode memory moonNode = RNG.RandNode(seed);

        if (class == Macroverse.WorldClass.Ring) {
            // Rings are special
            realPeriapsis = realPrevClearance + planetMoonScale.mul(REAL_HALF).mul(moonNode.derive("ringstart").getRealBetween(REAL_ONE, REAL_TWO));
            realApoapsis = realPeriapsis + realPeriapsis.mul(moonNode.derive("ringwidth").getRealBetween(REAL_HALF, REAL_TWO));
            realClearance = realApoapsis + planetMoonScale.mul(REAL_HALF).mul(moonNode.derive("ringclear").getRealBetween(REAL_HALF, REAL_TWO));
        } else {
            // Otherwise just roll some stuff
            realPeriapsis = realPrevClearance + planetMoonScale.mul(moonNode.derive("periapsis").getRealBetween(REAL_HALF, REAL_ONE));
            realApoapsis = realPeriapsis.mul(moonNode.derive("apoapsis").getRealBetween(REAL_ONE, RealMath.fraction(120, 100)));

            if (class == Macroverse.WorldClass.Asteroidal || class == Macroverse.WorldClass.Cometary) {
                // Captured tiny things should be more eccentric
                realApoapsis = realApoapsis + (realApoapsis - realPeriapsis).mul(REAL_TWO);
            }

            realClearance = realApoapsis.mul(moonNode.derive("clearance").getRealBetween(RealMath.fraction(110, 100), RealMath.fraction(130, 100)));
        }
    }

    /**
     * Get the inclination (angle from parent body's equatorial plane to orbital plane at the ascending node) for a moon.
     * Inclination is always positive. If it were negative, the ascending node would really be the descending node.
     * Result is a real in radians.
     */ 
    function getMoonInclination(bytes32 seed, Macroverse.WorldClass class) public view onlyControlledAccess returns (int128 real_inclination) {
        
        RNG.RandNode memory node = RNG.RandNode(seed).derive("inclination");

        // Define maximum inclination in milliradians
        // 175 milliradians = ~ 10 degrees
        int88 maximum;
        if (class == Macroverse.WorldClass.Asteroidal || class == Macroverse.WorldClass.Cometary) {
            // Tiny captured things can be pretty free
            maximum = 850;
        } else if (class == Macroverse.WorldClass.Lunar || class == Macroverse.WorldClass.Europan) {
            maximum = 100;
        } else if (class == Macroverse.WorldClass.Terrestrial || class == Macroverse.WorldClass.Panthalassic) {
            maximum = 80;
        } else if (class == Macroverse.WorldClass.Neptunian) {
            maximum = 50;
        } else if (class == Macroverse.WorldClass.Ring) {
            maximum = 350;
        } else {
            // Not real!
            revert();
        }
        
        // Compute the inclination
        real_inclination = node.getRealBetween(0, RealMath.toReal(maximum)).div(RealMath.toReal(1000));

        if (node.derive("retrograde").d(1, 100, 0) < 10) {
            // This moon ought to move retrograde (subtract inclination from pi instead of adding it to 0)
            real_inclination = REAL_PI - real_inclination;
        }

        return real_inclination;  
    }
}

// This code is part of Macroverse and is licensed: UNLICENSED

/**
 * The MacroverseExistenceChecker queries Macroverse generator contracts to
 * determine if a particular thing (e.g. the nth planet of such-and-such a
 * star) exists in the Macroverse world.
 *
 * It does not need to be ControlledAccess because the Macroverse contracts it
 * calls into are. It does not have defenses against receiving stuck Ether and
 * tokens because it is not intended to be involved in end-user token
 * transactions in any capacity.
 *
 * Serves as an example for how Macroverse can be queried from on-chain logic.
 */
contract MacroverseExistenceChecker {

    using MacroverseNFTUtils for uint256;

    // These constants are shared with the TokenUtils library

    // Define the types of tokens that can exist
    uint256 constant TOKEN_TYPE_SECTOR = 0;
    uint256 constant TOKEN_TYPE_SYSTEM = 1;
    uint256 constant TOKEN_TYPE_PLANET = 2;
    uint256 constant TOKEN_TYPE_MOON = 3;
    // Land tokens are a range of type field values.
    // Land tokens of the min type use one trixel field
    uint256 constant TOKEN_TYPE_LAND_MIN = 4;
    uint256 constant TOKEN_TYPE_LAND_MAX = 31;

    // Sentinel for no moon used (for land on a planet)
    uint16 constant MOON_NONE = 0xFFFF;

    // These constants are shared with the generator contracts

    // How far out does the sector system extend?
    int16 constant MAX_SECTOR = 10000;

    //
    // Contract state
    //

    // Keep track of all of the generator contract addresses
    MacroverseStarGenerator private starGenerator;
    MacroverseStarGeneratorPatch1 private starGeneratorPatch;
    MacroverseSystemGenerator private systemGenerator;
    MacroverseMoonGenerator private moonGenerator;

    /**
     * Deploy a new copy of the Macroverse Existence Checker.
     *
     * The given generator contracts will be queried.
     */
    constructor(address starGeneratorAddress, address starGeneratorPatchAddress,
        address systemGeneratorAddress, address moonGeneratorAddress) public {

        // Remember where all the generators are
        starGenerator = MacroverseStarGenerator(starGeneratorAddress);
        starGeneratorPatch = MacroverseStarGeneratorPatch1(starGeneratorPatchAddress);
        systemGenerator = MacroverseSystemGenerator(systemGeneratorAddress);
        moonGenerator = MacroverseMoonGenerator(moonGeneratorAddress);
        
    }

    /**
     * Return true if a sector with the given coordinates exists in the
     * Macroverse universe, and false otherwise.
     */
    function sectorExists(int16 sectorX, int16 sectorY, int16 sectorZ) public pure returns (bool) {
        // Enforce absolute bounds.
        if (sectorX > MAX_SECTOR) return false;
        if (sectorY > MAX_SECTOR) return false;
        if (sectorZ > MAX_SECTOR) return false;
        if (sectorX < -MAX_SECTOR) return false;
        if (sectorY < -MAX_SECTOR) return false;
        if (sectorZ < -MAX_SECTOR) return false;

        return true;
    }

    /**
     * Determine if the given system (which might be a star, black hole, etc.)
     * exists in the given sector. If the sector doesn't exist, returns false.
     */
    function systemExists(int16 sectorX, int16 sectorY, int16 sectorZ, uint16 system) public view returns (bool) {
        if (!sectorExists(sectorX, sectorY, sectorZ)) {
            // The system can't exist if the sector doesn't.
            return false;
        }

        // If the sector does exist, the system exists if it is in bounds
        return (system < starGenerator.getSectorObjectCount(sectorX, sectorY, sectorZ));
    }


    /**
     * Determine if the given planet exists, and if so returns some information
     * generated about it for re-use.
     */
    function planetExistsVerbose(int16 sectorX, int16 sectorY, int16 sectorZ, uint16 system, uint16 planet) internal view returns (bool exists,
        bytes32 systemSeed, uint16 totalPlanets) {

        if (!systemExists(sectorX, sectorY, sectorZ, system)) {
            // The planet can't exist if the parent system doesn't.
            exists = false;
        } else {
            // Get the system seed for the parent star/black hole/whatever
            // TODO: unify with above to save on derives?
            systemSeed = starGenerator.getSectorObjectSeed(sectorX, sectorY, sectorZ, system);

            // Get class and spectral type
            MacroverseStarGenerator.ObjectClass systemClass = starGenerator.getObjectClass(systemSeed);
            MacroverseStarGenerator.SpectralType systemType = starGenerator.getObjectSpectralType(systemSeed, systemClass);

            if (starGenerator.getObjectHasPlanets(systemSeed, systemClass, systemType)) {
                // There are some planets. Are there enough?
                totalPlanets = starGeneratorPatch.getObjectPlanetCount(systemSeed, systemClass, systemType);
                exists = (planet < totalPlanets);
            } else {
                // This system doesn't actually have planets
                exists = false;
            }
        }
    }

    /**
     * Determine if the given moon exists, and if so returns some information
     * generated about it for re-use.
     */
    function moonExistsVerbose(int16 sectorX, int16 sectorY, int16 sectorZ, uint16 system, uint16 planet, uint16 moon) public view returns (bool exists,
        bytes32 planetSeed, Macroverse.WorldClass planetClass) {
        
        (bool havePlanet, bytes32 systemSeed, uint16 totalPlanets) = planetExistsVerbose(sectorX, sectorY, sectorZ, system, planet);

        if (!havePlanet) {
            // Moon can't exist without its planet
            exists = false;
        } else {

            // Otherwise, work out the seed of the planet.
            planetSeed = systemGenerator.getWorldSeed(systemSeed, planet);
            
            // Use it to get the class of the planet, which is important for knowing if there is a moon
            planetClass = systemGenerator.getPlanetClass(planetSeed, planet, totalPlanets);

            // Count its moons
            uint16 moonCount = moonGenerator.getPlanetMoonCount(planetSeed, planetClass);

            // This moon exists if it is less than the count
            exists = (moon < moonCount);
        }
    }

    /**
     * Determine if the given planet exists.
     */
    function planetExists(int16 sectorX, int16 sectorY, int16 sectorZ, uint16 system, uint16 planet) public view returns (bool) {
        // Get only one return value. Ignore the others with these extra commas
        (bool exists, , ) = planetExistsVerbose(sectorX, sectorY, sectorZ, system, planet);

        // Caller only cares about existence
        return exists;
    }

    /**
     * Determine if the given moon exists.
     */
    function moonExists(int16 sectorX, int16 sectorY, int16 sectorZ, uint16 system, uint16 planet, uint16 moon) public view returns (bool) {
        // Get only the existence flag
        (bool exists, , ) = moonExistsVerbose(sectorX, sectorY, sectorZ, system, planet, moon);
    
        // Return it
        return exists;
    }

    /**
     * Determine if the thing referred to by the given packed NFT token number
     * exists.
     *
     * Token is assumed to be canonical/valid. Use MacroverseNFTUtils
     * tokenIsCanonical() to validate it first.
     */
    function exists(uint256 token) public view returns (bool) {
        // Get the type
        uint256 tokenType = token.getTokenType();

        // Unpack the sector. There's always a sector.
        (int16 sectorX, int16 sectorY, int16 sectorZ) = token.getTokenSector();

        if (tokenType == TOKEN_TYPE_SECTOR) {
            // Check if the requested sector exists
            return sectorExists(sectorX, sectorY, sectorZ);
        }

        // There must be a system number
        uint16 system = token.getTokenSystem();

        if (tokenType == TOKEN_TYPE_SYSTEM) {
            // Check if the requested system exists
            return systemExists(sectorX, sectorY, sectorZ, system);
        }

        // There must be a planet number
        uint16 planet = token.getTokenPlanet();

        // And there may be a moon
        uint16 moon = token.getTokenMoon();

        if (tokenType == TOKEN_TYPE_PLANET) {
            // We exist if the planet exists.
            // TODO: maybe check for ring/asteroid field types and don't let their land exist at all?
            return planetExists(sectorX, sectorY, sectorZ, system, planet);
        }

        if (tokenType == TOKEN_TYPE_MOON) {
             // We exist if the moon exists
            return moonExists(sectorX, sectorY, sectorZ, system, planet, moon);
        }

        // Otherwise it must be land.
        assert(token.tokenIsLand());

        // We exist if the planet or moon exists and isn't a ring or asteroid belt
        // We need the parent existence flag
        bool haveParent;
        // We will need a seed scratch.
        bytes32 seed;

        if (moon == MOON_NONE) {
            // Make sure the planet exists and isn't a ring
            uint16 totalPlanets;
            (haveParent, seed, totalPlanets) = planetExistsVerbose(sectorX, sectorY, sectorZ, system, planet);

            if (!haveParent) {
                return false;
            }

            // Get the planet's seed
            seed = systemGenerator.getWorldSeed(seed, planet);

            // Land exists if the planet isn't an AsteroidBelt
            return systemGenerator.getPlanetClass(seed, planet, totalPlanets) != Macroverse.WorldClass.AsteroidBelt;

        } else {
            // Make sure the moon exists and isn't a ring
            Macroverse.WorldClass planetClass;
            (haveParent, seed, planetClass) = moonExistsVerbose(sectorX, sectorY, sectorZ, system, planet, moon);

            if (!haveParent) {
                return false;
            }

            // Get the moon's seed
            seed = systemGenerator.getWorldSeed(seed, moon);

            // Land exists if the moon isn't a Ring
            return moonGenerator.getMoonClass(planetClass, seed, moon) != Macroverse.WorldClass.Ring;
        }
    }

}

// This code is part of Macroverse and is licensed: UNLICENSED

// This code is part of OpenZeppelin and is licensed: MIT
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

// This code is part of OpenZeppelin and is licensed: MIT
/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transfered from `from` to `to`.
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
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

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
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

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
}

// This code is part of OpenZeppelin and is licensed: MIT
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

// This code is part of OpenZeppelin and is licensed: MIT
/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {

    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// This code is part of OpenZeppelin and is licensed: MIT
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
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data)
    external returns (bytes4);
}

// This code is part of OpenZeppelin and is licensed: MIT
/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts may inherit from this and call {_registerInterface} to declare
 * their support of an interface.
 */
contract ERC165 is IERC165 {
    /*
     * bytes4(keccak256('supportsInterface(bytes4)')) == 0x01ffc9a7
     */
    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;

    /**
     * @dev Mapping of interface ids to whether or not it's supported.
     */
    mapping(bytes4 => bool) private _supportedInterfaces;

    constructor () internal {
        // Derived contracts need only register support for their own interfaces,
        // we register support for ERC165 itself here
        _registerInterface(_INTERFACE_ID_ERC165);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     *
     * Time complexity O(1), guaranteed to always use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) public view override returns (bool) {
        return _supportedInterfaces[interfaceId];
    }

    /**
     * @dev Registers the contract as an implementer of the interface defined by
     * `interfaceId`. Support of the actual ERC165 interface is automatic and
     * registering its interface id is not required.
     *
     * See {IERC165-supportsInterface}.
     *
     * Requirements:
     *
     * - `interfaceId` cannot be the ERC165 invalid interface (`0xffffffff`).
     */
    function _registerInterface(bytes4 interfaceId) internal virtual {
        require(interfaceId != 0xffffffff, "ERC165: invalid interface id");
        _supportedInterfaces[interfaceId] = true;
    }
}

// This code is part of OpenZeppelin and is licensed: MIT
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
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
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

// This code is part of OpenZeppelin and is licensed: MIT
/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.0.0, only sets of type `address` (`AddressSet`) and `uint256`
 * (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;

        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping (bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) { // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(value)));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(value)));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(value)));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint256(_at(set._inner, index)));
    }


    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}

// This code is part of OpenZeppelin and is licensed: MIT
/**
 * @dev Library for managing an enumerable variant of Solidity's
 * https://solidity.readthedocs.io/en/latest/types.html#mapping-types[`mapping`]
 * type.
 *
 * Maps have the following properties:
 *
 * - Entries are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Entries are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableMap for EnumerableMap.UintToAddressMap;
 *
 *     // Declare a set state variable
 *     EnumerableMap.UintToAddressMap private myMap;
 * }
 * ```
 *
 * As of v3.0.0, only maps of type `uint256 -> address` (`UintToAddressMap`) are
 * supported.
 */
library EnumerableMap {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Map type with
    // bytes32 keys and values.
    // The Map implementation uses private functions, and user-facing
    // implementations (such as Uint256ToAddressMap) are just wrappers around
    // the underlying Map.
    // This means that we can only create new EnumerableMaps for types that fit
    // in bytes32.

    struct MapEntry {
        bytes32 _key;
        bytes32 _value;
    }

    struct Map {
        // Storage of map keys and values
        MapEntry[] _entries;

        // Position of the entry defined by a key in the `entries` array, plus 1
        // because index 0 means a key is not in the map.
        mapping (bytes32 => uint256) _indexes;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function _set(Map storage map, bytes32 key, bytes32 value) private returns (bool) {
        // We read and store the key's index to prevent multiple reads from the same storage slot
        uint256 keyIndex = map._indexes[key];

        if (keyIndex == 0) { // Equivalent to !contains(map, key)
            map._entries.push(MapEntry({ _key: key, _value: value }));
            // The entry is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            map._indexes[key] = map._entries.length;
            return true;
        } else {
            map._entries[keyIndex - 1]._value = value;
            return false;
        }
    }

    /**
     * @dev Removes a key-value pair from a map. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function _remove(Map storage map, bytes32 key) private returns (bool) {
        // We read and store the key's index to prevent multiple reads from the same storage slot
        uint256 keyIndex = map._indexes[key];

        if (keyIndex != 0) { // Equivalent to contains(map, key)
            // To delete a key-value pair from the _entries array in O(1), we swap the entry to delete with the last one
            // in the array, and then remove the last entry (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = keyIndex - 1;
            uint256 lastIndex = map._entries.length - 1;

            // When the entry to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            MapEntry storage lastEntry = map._entries[lastIndex];

            // Move the last entry to the index where the entry to delete is
            map._entries[toDeleteIndex] = lastEntry;
            // Update the index for the moved entry
            map._indexes[lastEntry._key] = toDeleteIndex + 1; // All indexes are 1-based

            // Delete the slot where the moved entry was stored
            map._entries.pop();

            // Delete the index for the deleted slot
            delete map._indexes[key];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function _contains(Map storage map, bytes32 key) private view returns (bool) {
        return map._indexes[key] != 0;
    }

    /**
     * @dev Returns the number of key-value pairs in the map. O(1).
     */
    function _length(Map storage map) private view returns (uint256) {
        return map._entries.length;
    }

   /**
    * @dev Returns the key-value pair stored at position `index` in the map. O(1).
    *
    * Note that there are no guarantees on the ordering of entries inside the
    * array, and it may change when more entries are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function _at(Map storage map, uint256 index) private view returns (bytes32, bytes32) {
        require(map._entries.length > index, "EnumerableMap: index out of bounds");

        MapEntry storage entry = map._entries[index];
        return (entry._key, entry._value);
    }

    /**
     * @dev Returns the value associated with `key`.  O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function _get(Map storage map, bytes32 key) private view returns (bytes32) {
        return _get(map, key, "EnumerableMap: nonexistent key");
    }

    /**
     * @dev Same as {_get}, with a custom error message when `key` is not in the map.
     */
    function _get(Map storage map, bytes32 key, string memory errorMessage) private view returns (bytes32) {
        uint256 keyIndex = map._indexes[key];
        require(keyIndex != 0, errorMessage); // Equivalent to contains(map, key)
        return map._entries[keyIndex - 1]._value; // All indexes are 1-based
    }

    // UintToAddressMap

    struct UintToAddressMap {
        Map _inner;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(UintToAddressMap storage map, uint256 key, address value) internal returns (bool) {
        return _set(map._inner, bytes32(key), bytes32(uint256(value)));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(UintToAddressMap storage map, uint256 key) internal returns (bool) {
        return _remove(map._inner, bytes32(key));
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(UintToAddressMap storage map, uint256 key) internal view returns (bool) {
        return _contains(map._inner, bytes32(key));
    }

    /**
     * @dev Returns the number of elements in the map. O(1).
     */
    function length(UintToAddressMap storage map) internal view returns (uint256) {
        return _length(map._inner);
    }

   /**
    * @dev Returns the element stored at position `index` in the set. O(1).
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(UintToAddressMap storage map, uint256 index) internal view returns (uint256, address) {
        (bytes32 key, bytes32 value) = _at(map._inner, index);
        return (uint256(key), address(uint256(value)));
    }

    /**
     * @dev Returns the value associated with `key`.  O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(UintToAddressMap storage map, uint256 key) internal view returns (address) {
        return address(uint256(_get(map._inner, bytes32(key))));
    }

    /**
     * @dev Same as {get}, with a custom error message when `key` is not in the map.
     */
    function get(UintToAddressMap storage map, uint256 key, string memory errorMessage) internal view returns (address) {
        return address(uint256(_get(map._inner, bytes32(key), errorMessage)));
    }
}

// This code is part of OpenZeppelin and is licensed: MIT
/**
 * @dev String operations.
 */
library Strings {
    /**
     * @dev Converts a `uint256` to its ASCII `string` representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        uint256 index = digits - 1;
        temp = value;
        while (temp != 0) {
            buffer[index--] = byte(uint8(48 + temp % 10));
            temp /= 10;
        }
        return string(buffer);
    }
}

// This code is part of OpenZeppelin and is licensed: MIT
/**
 * @title ERC721 Non-Fungible Token Standard basic implementation
 * @dev see https://eips.ethereum.org/EIPS/eip-721
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata, IERC721Enumerable {
    using SafeMath for uint256;
    using Address for address;
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableMap for EnumerableMap.UintToAddressMap;
    using Strings for uint256;

    // Equals to `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
    // which can be also obtained as `IERC721Receiver(0).onERC721Received.selector`
    bytes4 private constant _ERC721_RECEIVED = 0x150b7a02;

    // Mapping from holder address to their (enumerable) set of owned tokens
    mapping (address => EnumerableSet.UintSet) private _holderTokens;

    // Enumerable mapping from token ids to their owners
    EnumerableMap.UintToAddressMap private _tokenOwners;

    // Mapping from token ID to approved address
    mapping (uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping (address => mapping (address => bool)) private _operatorApprovals;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Optional mapping for token URIs
    mapping(uint256 => string) private _tokenURIs;

    // Base URI
    string private _baseURI;

    /*
     *     bytes4(keccak256('balanceOf(address)')) == 0x70a08231
     *     bytes4(keccak256('ownerOf(uint256)')) == 0x6352211e
     *     bytes4(keccak256('approve(address,uint256)')) == 0x095ea7b3
     *     bytes4(keccak256('getApproved(uint256)')) == 0x081812fc
     *     bytes4(keccak256('setApprovalForAll(address,bool)')) == 0xa22cb465
     *     bytes4(keccak256('isApprovedForAll(address,address)')) == 0xe985e9c5
     *     bytes4(keccak256('transferFrom(address,address,uint256)')) == 0x23b872dd
     *     bytes4(keccak256('safeTransferFrom(address,address,uint256)')) == 0x42842e0e
     *     bytes4(keccak256('safeTransferFrom(address,address,uint256,bytes)')) == 0xb88d4fde
     *
     *     => 0x70a08231 ^ 0x6352211e ^ 0x095ea7b3 ^ 0x081812fc ^
     *        0xa22cb465 ^ 0xe985e9c ^ 0x23b872dd ^ 0x42842e0e ^ 0xb88d4fde == 0x80ac58cd
     */
    bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;

    /*
     *     bytes4(keccak256('name()')) == 0x06fdde03
     *     bytes4(keccak256('symbol()')) == 0x95d89b41
     *     bytes4(keccak256('tokenURI(uint256)')) == 0xc87b56dd
     *
     *     => 0x06fdde03 ^ 0x95d89b41 ^ 0xc87b56dd == 0x5b5e139f
     */
    bytes4 private constant _INTERFACE_ID_ERC721_METADATA = 0x5b5e139f;

    /*
     *     bytes4(keccak256('totalSupply()')) == 0x18160ddd
     *     bytes4(keccak256('tokenOfOwnerByIndex(address,uint256)')) == 0x2f745c59
     *     bytes4(keccak256('tokenByIndex(uint256)')) == 0x4f6ccce7
     *
     *     => 0x18160ddd ^ 0x2f745c59 ^ 0x4f6ccce7 == 0x780e9d63
     */
    bytes4 private constant _INTERFACE_ID_ERC721_ENUMERABLE = 0x780e9d63;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor (string memory name, string memory symbol) public {
        _name = name;
        _symbol = symbol;

        // register the supported interfaces to conform to ERC721 via ERC165
        _registerInterface(_INTERFACE_ID_ERC721);
        _registerInterface(_INTERFACE_ID_ERC721_METADATA);
        _registerInterface(_INTERFACE_ID_ERC721_ENUMERABLE);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");

        return _holderTokens[owner].length();
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view override returns (address) {
        return _tokenOwners.get(tokenId, "ERC721: owner query for nonexistent token");
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory _tokenURI = _tokenURIs[tokenId];

        // If there is no base URI, return the token URI.
        if (bytes(_baseURI).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(_baseURI, _tokenURI));
        }
        // If there is a baseURI but no tokenURI, concatenate the tokenID to the baseURI.
        return string(abi.encodePacked(_baseURI, tokenId.toString()));
    }

    /**
    * @dev Returns the base URI set via {_setBaseURI}. This will be
    * automatically added as a prefix in {tokenURI} to each token's URI, or
    * to the token ID if no specific URI is set for that token ID.
    */
    function baseURI() public view returns (string memory) {
        return _baseURI;
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view override returns (uint256) {
        return _holderTokens[owner].at(index);
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view override returns (uint256) {
        // _tokenOwners are indexed by tokenIds, so .length() returns the number of tokenIds
        return _tokenOwners.length();
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view override returns (uint256) {
        (uint256 tokenId, ) = _tokenOwners.at(index);
        return tokenId;
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(_msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(operator != _msgSender(), "ERC721: approve to caller");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(address from, address to, uint256 tokenId) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mecanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory _data) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view returns (bool) {
        return _tokenOwners.contains(tokenId);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     d*
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(address to, uint256 tokenId, bytes memory _data) internal virtual {
        _mint(to, tokenId);
        require(_checkOnERC721Received(address(0), to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _holderTokens[to].add(tokenId);

        _tokenOwners.set(tokenId, to);

        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        // Clear metadata (if any)
        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }

        _holderTokens[owner].remove(tokenId);

        _tokenOwners.remove(tokenId);

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(address from, address to, uint256 tokenId) internal virtual {
        require(ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _holderTokens[from].remove(tokenId);
        _holderTokens[to].add(tokenId);

        _tokenOwners.set(tokenId, to);

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Sets `_tokenURI` as the tokenURI of `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(_exists(tokenId), "ERC721Metadata: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }

    /**
     * @dev Internal function to set the base URI for all token IDs. It is
     * automatically added as a prefix to the value returned in {tokenURI},
     * or to the token ID if {tokenURI} is empty.
     */
    function _setBaseURI(string memory baseURI_) internal virtual {
        _baseURI = baseURI_;
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data)
        private returns (bool)
    {
        if (!to.isContract()) {
            return true;
        }
        bytes memory returndata = to.functionCall(abi.encodeWithSelector(
            IERC721Receiver(to).onERC721Received.selector,
            _msgSender(),
            from,
            tokenId,
            _data
        ), "ERC721: transfer to non ERC721Receiver implementer");
        bytes4 retval = abi.decode(returndata, (bytes4));
        return (retval == _ERC721_RECEIVED);
    }

    function _approve(address to, uint256 tokenId) private {
        _tokenApprovals[tokenId] = to;
        emit Approval(ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual { }
}

/**
 * The MacroverseRealEstate contract keeps track of who currently owns virtual
 * real estate in the Macroverse world, at all scales. It supersedes the
 * MacroverseStarRegistry. Registration and Macroverse-specific manipulation of
 * tokens is accomplished through the MacroverseUniversalRegistry, which owns
 * this contract.
 *
 * The split between this contract and the MacroverseUniversalRegistry exists
 * to keep contract size under the limit. 
 */
contract MacroverseRealEstate is ERC721, Ownable {

    
    /**
     * Deploy the backend, taking mint, burn, and set-user commands from the deployer.
     * Use the given domain as the domain for token URIs.
     */
    constructor(string memory domain) public ERC721("Macroverse Real Estate", "MRE") {
        _setTokenMetadataDomain(domain);
    }
    
    /**
     * Allow this contract to change the ERC721 metadata URI domain.
     */
    function _setTokenMetadataDomain(string memory domain) internal {
        // Set up new OpenZeppelin 3.0 automatic token URI system.
        // Good thing we match their format or we'd have to fork OZ.
        uint chainId = 0;
        assembly {
            chainId := chainid()
        }
        _setBaseURI(string(abi.encodePacked("https://", domain, "/vre/v1/chain/", Strings.toString(chainId), "/token/")));
    }
    
    /**
     * Allow this the owner to change the ERC721 metadata URI domain.
     */
    function setTokenMetadataDomain(string memory domain) external onlyOwner {
        _setTokenMetadataDomain(domain);
    }

    /**
     * Mint tokens at the direction of the owning contract.
     */
    function mint(address to, uint256 tokenId) external onlyOwner {
        _mint(to, tokenId);
    }

    /**
     * Burn tokens at the direction of the owning contract.
     */
    function burn(uint256 tokenId) external onlyOwner {
        _burn(tokenId);
    }

    /**
     * Publically expose a token existence test. Returns true if the given
     * token is owned by someone, and false otherwise. Note that tokens sent to
     * 0x0 but not burned may still exist.
     */
    function exists(uint256 tokenId) external view returns (bool) {
        return _exists(tokenId);
    }
}

// This code is part of Macroverse and is licensed: UNLICENSED

/**
 * The MacroverseUniversalRegistry manages the creation and Macroverse-specific
 * manipulation of non-fungible tokens (NFTs) representing virtual real estate,
 * which are tracked by the MacroverseRealEstate contract.
 *
 * Ownership is based on a claim system, where unowned objects can be claimed
 * by people by putting up a deposit in MRV. The MRV deposit is returned when
 * the owner releases their claim on the corresponding object.
 *
 * The claim system is protected against front-running by a commit/reveal
 * system with a mandatory waiting period. You first commit to the claim you
 * want to make, by putting up the deposit and publishing a hash. After a
 * certain mandatory waiting period, you can reveal what it is you are trying
 * to claim, and actually take ownership of the object.
 *
 * The first person to reveal wins in case two or more people try to claim the
 * same object, or if they try to claim things that are
 * parents/children/overlapping in such a way that the claims conflict. Since
 * there's a mandatory waiting period between the commit and reveal, and since
 * a malicious front-runner cannot commit until they see a reveal they are
 * trying to front-run, then as long as malicious front-runners cannot keep
 * transactions off the chain for the duration of the mandatory wait period,
 * then they can't steal things other people are trying to claim.
 *
 * It's still possible for an organic conflict to end up getting resolved in
 * favor of whoever is willing to pay more for gas, or for people to leave many
 * un-revealed claims and grief people by revealing them when someone else
 * tries to claim the same objects.
 *
 * To further mitigate griefing, committed claims will expire after a while if
 * not revealed.
 *
 * Revealing requires demonstrating that the Macroverse object being claimed
 * actually exists, and so claiming can only be done by people who can pass the
 * Macroverse generator's AccessControl checks.
 *
 * Note that ownership of a star system does not necessarily imply ownership of
 * everything in it. Just as one person can own a condo in another person's
 * building, one person can own a planet in another person's star system.
 * Non-containment of different ownership claims is only enforced for claims of
 * land on planets and moons.
 *
 * The surface of a world is subdivided using a Hierarchical Triangular Mesh
 * approach, as described in <http://www.skyserver.org/HTM/> and in
 * <https://www.microsoft.com/en-us/research/wp-content/uploads/2005/09/tr-2005-123.pdf>
 * "Indexing the Sphere with the Hierarchical Triangular Mesh". At the top
 * level, the surface of a world is an octahedron of equilateral triangles.
 * Each triangle is then recursively subdivided into 4 children by inscribing
 * another equilateral triangle between the center points of its edges. Each
 * HTM "trixel" is a plot of virtual real estate that can be claimed. Land
 * trixels can be subdivided and merged, and ownership of a trixel implies
 * ownership of all contained trixels, because this logic can be done without
 * any reference to the AccessControl-protected Macroverse generator logic.
 *
 * The mapping from systems, planets, moons, and land trixels to token ID
 * numbers is defined in the MacroverseNFTUtils library.
 *
 * "Planets" which are asteroid belts and "moons" which are ring systems also
 * are subdivided into 8 triangles, and then recursively into nested sets of 4
 * sub-triangles. However, the initial 8 triangles are defined as wedges, with
 * the points at the central body and with the outer edges being curved. They
 * are numbered prograde, with the division from 0 to 7 corresponding to the
 * object's notional position, computed as if it were a point body with the
 * same orbital parameters. Note that this means that some ownership claims do
 * not actually overlap the orbital range (and thus do not contain anything),
 * and that any actual particles would move relative to the positions of the
 * claims over time, depending on their actual orbits. 
 *
 * At the astronomical level (stars, planets, moons), tokens can be issued
 * for the children of things already claimed, if the lowest owned parent token
 * has homesteading enabled.  At the land level, only one token can cover
 * a given point at a given time, but plots can be subdivided and merged
 * according to the trixel structure.
 *
 * Internally, bookkeeping data is kept to allow the tree of all issued tokens
 * to be traversed. All issued tokens exist in the tree, as well as the
 * internal nodes of the token hierarchy necessary to connect them. The
 * presence of child nodes in the tree is tracked using a bitmap for each node.
 *
 * The deployer of this contract reserves the right to supersede it with a new
 * version at any time, for any reason, and without notice. The deployer of
 * this contract reserves the right to leave it in place as is indefinitely.
 *
 * The deployer of this contract reserves the right to claim and keep any
 * tokens or ETH or contracts sent to this contract, in excess of the MRV
 * balance that this contract thinks it is supposed to have.
 */
contract MacroverseUniversalRegistry is Ownable, HasNoEther, HasNoContracts {

    using SafeMath for uint256;
    using MacroverseNFTUtils for uint256;

    // These constants are shared with the TokenUtils library

    // Define the types of tokens that can exist
    uint256 constant TOKEN_TYPE_SECTOR = 0;
    uint256 constant TOKEN_TYPE_SYSTEM = 1;
    uint256 constant TOKEN_TYPE_PLANET = 2;
    uint256 constant TOKEN_TYPE_MOON = 3;
    // Land tokens are a range of type field values.
    // Land tokens of the min type use one trixel field
    uint256 constant TOKEN_TYPE_LAND_MIN = 4;
    uint256 constant TOKEN_TYPE_LAND_MAX = 31;

    // Define the packing format
    uint8 constant TOKEN_SECTOR_X_SHIFT = 5;
    uint8 constant TOKEN_SECTOR_X_BITS = 16;
    uint8 constant TOKEN_SECTOR_Y_SHIFT = TOKEN_SECTOR_X_SHIFT + TOKEN_SECTOR_X_BITS;
    uint8 constant TOKEN_SECTOR_Y_BITS = 16;
    uint8 constant TOKEN_SECTOR_Z_SHIFT = TOKEN_SECTOR_Y_SHIFT + TOKEN_SECTOR_Y_BITS;
    uint8 constant TOKEN_SECTOR_Z_BITS = 16;
    uint8 constant TOKEN_SYSTEM_SHIFT = TOKEN_SECTOR_Z_SHIFT + TOKEN_SECTOR_Z_BITS;
    uint8 constant TOKEN_SYSTEM_BITS = 16;
    uint8 constant TOKEN_PLANET_SHIFT = TOKEN_SYSTEM_SHIFT + TOKEN_SYSTEM_BITS;
    uint8 constant TOKEN_PLANET_BITS = 16;
    uint8 constant TOKEN_MOON_SHIFT = TOKEN_PLANET_SHIFT + TOKEN_PLANET_BITS;
    uint8 constant TOKEN_MOON_BITS = 16;
    uint8 constant TOKEN_TRIXEL_SHIFT = TOKEN_MOON_SHIFT + TOKEN_MOON_BITS;
    uint8 constant TOKEN_TRIXEL_EACH_BITS = 3;

    // How many trixel fields are there
    uint256 constant TOKEN_TRIXEL_FIELD_COUNT = 27;

    // How many children does a trixel have?
    uint256 constant CHILDREN_PER_TRIXEL = 4;
    // And how many top level trixels does a world have?
    uint256 constant TOP_TRIXELS = 8;

    // We keep a bit mask of the high bits of all but the least specific trixel.
    // None of these may be set in a valid token.
    // We rely on it being left-shifted TOKEN_TRIXEL_SHIFT bits before being applied.
    // Note that this has 26 1s, with one every 3 bits, except the last 3 bits are 0.
    uint256 constant TOKEN_TRIXEL_HIGH_BIT_MASK = 0x124924924924924924920;

    // Sentinel for no moon used (for land on a planet)
    uint16 constant MOON_NONE = 0xFFFF; 

    //
    // Events for the commit/reveal system
    //

    // Note that in addition to these special events, transfers to/from 0 are
    // fired as tokens are created and destroyed.

    /// Fired when an owner makes a commitment. Includes the commitment hash of token, nonce.
    event Commit(bytes32 indexed hash, address indexed owner);
    /// Fired when a commitment is successfully revealed and the token issued.
    event Reveal(bytes32 indexed hash, uint256 indexed token, address indexed owner);
    /// Fired when a commitment is canceled without being revealed.
    event Cancel(bytes32 indexed hash, address indexed owner);

    /// Fired when a token is released to be claimed by others.
    /// Use this instead of transfers to 0, because those also happen when subdividing/merging land.
    event Release(uint256 indexed token, address indexed former_owner);

    /// Fired when homesteading under a token is enabled or disabled.
    /// Not fired when the token is issued; it starts disabled.
    event Homesteading(uint256 indexed token, bool indexed value);
    /// Fired when a parcel of land is split out of another
    /// Gets emitted once per child.
    event LandSplit(uint256 indexed parent, uint256 indexed child);
    /// Fired when a parcel of land is merged into another.
    /// Gets emitted once per child.
    event LandMerge(uint256 indexed child, uint256 indexed parent);

    /// Fired when the deposit scale for the registry is updated by the administrator.
    event DepositScaleChange(uint256 new_min_system_deposit_in_atomic_units);
    /// Fired when the commitment min wait time is updated by the administrator.
    event CommitmentMinWaitChange(uint256 new_commitment_min_wait_in_seconds);

    //
    // Contract state
    //

    /**
     * This is the backend contract that actually has the machinery to track token ownership
     */
    MacroverseRealEstate public backend;

    /**
     * This is the contract we check virtual real estate existence against;
     */
    MacroverseExistenceChecker public existenceChecker;

    /**
     * This is the token in which ownership deposits have to be paid.
     */
    IERC20 public depositTokenContract;
    /**
     * This is the minimum ownership deposit in atomic token units.
     */
    uint public minSystemDepositInAtomicUnits;
    
    /**
     * This tracks how much of the deposit token the contract is supposed to have.
     * If it ends up with extra (because someone incorrectly used transfer() instead of approve()), the owner can remove it.
     */
    uint public expectedDepositBalance;

    /**
     * How long should a commitment be required to sit before it can be revealed, in Ethereum time?
     * This is also the maximum delay that we can let a bad actor keep good transactions off the chain, in our front-running security model.
     */
    uint public commitmentMinWait;

    /**
     * How long should a commitment be allowed to sit un-revealed before it becomes invalid and can only be canceled?
     * This protects against unrevealed commitments being used as griefing traps.
     * This is a multiple of the min wait.
     */
    uint public constant COMMITMENT_MAX_WAIT_FACTOR = 7;

    /**
     * A Commitment represents an outstanding attempt to claim a deed.
     * It also needs to be referenced to look up the deposit associated with an owned token when the token is destroyed.
     * It is identified by a "key", which is the hash of the committing hash and the owner address.
     * This is the mapping key under which it is stored.
     * We don't need to store the owner because the mapping key hash binds the commitment to the owner.
     */
    struct Commitment {
        // Hash (keccak256) of the token we want to claim and a uint256 nonce to be revealed with it.
        bytes32 hash;        
        // Number of atomic token units deposited with the commitment
        uint256 deposit;
        // Time number at which the commitment was created.
        uint256 creationTime;
    }
    
    /**
     * This is all the commitments that are currently outstanding.
     * The mapping key is keccak256(hash, owner address).
     * When they are revealed or canceled, they are deleted from the map.
     */
    mapping(bytes32 => Commitment) public commitments;

    /**
     * Tokens have some configuration info to them, beyond what the base ERC721 implementation tracks.
     */
    struct TokenConfig {
        // This holds the deposit amount associated with the token, which will be released when the token is unclaimed.
        uint256 deposit;
        // True if the token allows homesteading (i.e. the claiming of child tokens by others)
        bool homesteading;
    }

    /**@dev
     * This holds the TokenConfig for each token
     */
    mapping(uint256 => TokenConfig) tokenConfigs;

    /**@dev
     * This maps from each hierarchical bit-packed keypath entry to a bitmap of
     * which of its direct children have deed tokens issued at or under them.
     * If all the bits would be 0, an entry need not exist (which is the
     * Solidity mapping default behavior).
     */
    mapping (uint256 => uint256) internal childTree;

    /**
     * Deploy a new copy of the Macroverse Universal Registry.
     * The given existence checker will be used to check object existence.
     * The given token will be used to pay deposits, and the given minimum
     * deposit size will be required to claim a star system.
     * Other deposit sizes will be calculated from that.
     * The given min wait time will be the required time you must wait after committing before revealing.
     */
    constructor(address backend_address, address existence_checker_address, address deposit_token_address,
        uint initial_min_system_deposit_in_atomic_units, uint commitment_min_wait) public {
        // We can only use one backend for the lifetime of the contract, and we have to own it before it will work.
        backend = MacroverseRealEstate(backend_address);
        // We can only use one existence checker for the lifetime of the contract.
        existenceChecker = MacroverseExistenceChecker(existence_checker_address);
        // We can only use one token for the lifetime of the contract.
        depositTokenContract = IERC20(deposit_token_address);
        // But the minimum deposit for new claims can change
        minSystemDepositInAtomicUnits = initial_min_system_deposit_in_atomic_units;
        // Set the wait time
        commitmentMinWait = commitment_min_wait;
    }

    //
    // Child tree functions
    //

    // First we need some bit utilities

    /**
     * Set the value of a bit by index in a uint256.
     * Bits are counted from the LSB left.
     */
    function setBit(uint256 bitmap, uint256 index, bool value) internal pure returns (uint256) {
        uint256 bit = 0x1 << index;
        if (value) {
            // Set it
            return bitmap | bit;
        } else {
            // Clear it
            return bitmap & (~bit);
        }
    }

    /**
     * Get the value of a bit by index in a uint256.
     * Bits are counted from the LSB left.
     */
    function getBit(uint256 bitmap, uint256 index) internal pure returns (bool) {
        uint256 bit = 0x1 << index;
        return (bitmap & bit != 0);
    }

    /**
     * Register a token/internal node and all parents as having an extant token
     * present under them in the child tree.
     */
    function addChildToTree(uint256 token) internal {
        
        if (token.getTokenType() == TOKEN_TYPE_SECTOR) {
            // No parent exists; we're a tree root.
            return;
        }

        // Find the parent
        uint256 parent = token.parentOfToken();

        // Find what child index we are of the parent
        uint256 child_index = token.childIndexOfToken();
        
        // Get the parent's child tree entry
        uint256 bitmap = childTree[parent];

        if (getBit(bitmap, child_index)) {
            // Stop if the correct bit is set already
            return;
            // TODO: reuse the mask for the bit?
        }

        // Set the correct bit if unset
        childTree[parent] = setBit(bitmap, child_index, true);

        // Continue until we hit the top of the tree
        addChildToTree(parent);
    }

    /**
     * Record in the child tree that a token no longer exists. Also handles
     * cleanup of internal nodes that now have no children.
     */
    function removeChildFromTree(uint256 token) internal {

        if (token.getTokenType() == TOKEN_TYPE_SECTOR) {
            // No parent exists; we're a tree root.
            return;
        }

        // See if we have any children that still exist
        if (childTree[token] == 0) {
            // We are not an existing token ourselves, and we have no existing children.

            // Find the parent
            uint256 parent = token.parentOfToken();

            // Find what child index we are of the parent
            uint256 child_index = token.childIndexOfToken();
            
            // Getmthe parent's child tree entry
            uint256 bitmap = childTree[parent];

            if (getBit(bitmap, child_index)) {
                // Our bit in our immediate parent is set.

                // Clear it
                childTree[parent] = setBit(bitmap, child_index, false);

                if (!backend.exists(parent)) {
                    // Recurse up to maybe clean up the parent, if we were the
                    // last child and the parent doesn't exist as a token
                    // itself.
                    removeChildFromTree(parent);
                }
            }
        }
    }

    //
    // State-aware token utility functions
    //

    /**
     * Get the lowest-in-the-hierarchy token that exists (is owned).
     * Returns a 0-value sentinel if no parent token exists.
     */
    function lowestExistingParent(uint256 token) public view returns (uint256) {
        if (token.getTokenType() == TOKEN_TYPE_SECTOR) {
            // No parent exists, and we can't exist.
            return 0;
        }

        uint256 parent = token.parentOfToken();

        if (backend.exists(parent)) {
            // We found a token that really exists
            return parent;
        }

        // Otherwise, recurse on the parent
        return lowestExistingParent(parent);

        // Recursion depth is limited to a reasonable maximum by the maximum
        // depth of the land hierarchy.
    }

    /**
     * Returns true if direct children of the given token can be claimed by the given claimant.
     * Children of land tokens can never be claimed (the plot must be subdivided).
     * Children of system/planet/moon tokens can only be claimed if the claimer owns them or the owner allows homesteading.
     */
    function childrenClaimable(uint256 token, address claimant) public view returns (bool) {
        require(backend.exists(token), "Token not extant");
        return !token.tokenIsLand() && (claimant == backend.ownerOf(token) || tokenConfigs[token].homesteading);
    }

    /**
     * Get the min deposit that will be required to create a claim on a token.
     *
     * Tokens can only exist with deposits smaller than this if they were
     * created before the minimum deposit was raised, or if they are the result
     * of merging other tokens whose deposits were too small.
     */
    function getMinDepositToCreate(uint256 token) public view returns (uint256) {
        // Get the token's type
        uint256 token_type = token.getTokenType();

        if (token_type == TOKEN_TYPE_SECTOR) {
            // Sectors cannot be owned.
            return 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
        } else if (token_type == TOKEN_TYPE_SYSTEM) {
            // For systems, the deposit is set
            return minSystemDepositInAtomicUnits;
        } else if (token_type == TOKEN_TYPE_PLANET) {
            // For planets, the deposit is a fraction of the system
            return minSystemDepositInAtomicUnits.div(10);
        } else if (token_type == TOKEN_TYPE_MOON) {
            // For moons, the deposit is a smaller fraction
            return minSystemDepositInAtomicUnits.div(40);
        } else {
            // It must be land
            
            // For land, the deposit is smaller and cuts in half with each level of subdivision (starting at 1).

            // Base on the cost of the whole body
            // For moons we pay this fraction of the star system cost
            // For planets we pay more (divide less)
            uint256 whole_cost = minSystemDepositInAtomicUnits.div((token.getTokenMoon() == MOON_NONE) ? 10 : 40);

            // So all the small claims is twice as expensive as the big claim.
            uint256 subdivisions = token.getTokenTrixelCount();
            // Divide by an extra 2 at first because the first level has 8 trixels and not 4.
            uint256 wanted_cost = whole_cost >> (subdivisions + 1);
            
            // But then don't let the land derposit be less than 1/1000 of the
            // system cost, and round to ticks of that size so that we aren't
            // heckling users for uselessly small amounts of the token.
            uint256 tick_size = minSystemDepositInAtomicUnits.div(1000);
            uint256 overness = wanted_cost.mod(tick_size);
            
            if (overness == wanted_cost || wanted_cost == tick_size) {
                return tick_size;
            } else {
                return wanted_cost.sub(overness);
            }
        }
    }

    /**
     * Return true if the given token exists and the corresponding world object is claimed, and false otherwise.
     * Does not account for owners of parents.
     */
    function exists(uint256 token) public view returns (bool) {
        // Just wrap the private exists function
        return backend.exists(token);
    }


    //
    // Minting and destruction logic: commit/reveal/cancel and release
    //
    
    /**
     * Make a new commitment by debiting msg.sender's account for the given deposit.
     * Returns the numerical ID of the commitment, which must be passed to
     * reveal() together with the actual bit-packed keypath of the thing being
     * claimed in order to finalize the claim.
     */
    function commit(bytes32 hash, uint256 deposit) external {
        // Deposit size will not be checked until reveal!

        // We use the 0 hash as an indication that a commitment isn't present
        // in the mapping, so we prohibit it here as a real commitment hash.
        require(hash != bytes32(0), "Zero hash prohibited");

        // Record we have the deposit value
        expectedDepositBalance = expectedDepositBalance.add(deposit);

        // Make sure we can take the deposit
        require(depositTokenContract.transferFrom(msg.sender, address(this), deposit), "Deposit not approved");

        // Compute the commitment key
        bytes32 commitment_key = keccak256(abi.encodePacked(hash, msg.sender));

        // Find the record for it
        Commitment storage commitment = commitments[commitment_key];

        // Make sure it is free
        require(commitment.hash == bytes32(0), "Duplicate commitment prohibited");

        // Fill it in
        commitment.hash = hash;
        commitment.deposit = deposit;
        commitment.creationTime = now;

        // Do an event for tracking.  Nothing needs to come out of this for the
        // reveal; you just need to know that you succeeded and about when.
        emit Commit(hash, msg.sender);
    }

    /**
     * Cancel a commitment that has not yet been revealed.
     * Returns the associated deposit.
     * ID the commitment by the committing hash passed to commit(), *not* the
     * internal key.
     * Must be sent from the same address that created the commitment, or the
     * commitment cannot be addressed.
     */
    function cancel(bytes32 hash) external {
        // We use the 0 hash as an indication that a commitment isn't present
        // in the mapping, so we prohibit it here as a real commitment hash.
        require(hash != bytes32(0), "Zero hash prohibited");

        // Look up the right commitment for this hash and owner.
        bytes32 commitment_key = keccak256(abi.encodePacked(hash, msg.sender));
        Commitment storage commitment = commitments[commitment_key];

        // Make sure it is present with the right nonzero hash.
        // If it seems to have a zero hash, the commitment is gone/never existed.
        require(commitment.hash == hash, "Commitment not found");

        // Work out how much to refund
        uint256 refund = commitment.deposit;

        // Destroy the commitment
        delete commitments[commitment_key];

        // Record we sent the deposit value
        expectedDepositBalance = expectedDepositBalance.sub(refund);

        // Return the deposit
        require(depositTokenContract.transfer(msg.sender, refund));

        // Emit a Cancel event
        emit Cancel(hash, msg.sender);
    }

    /**
     * Finish a commitment by revealing the token we want to claim and the
     * nonce to make the commitment hash. Creates the token. Fails and reverts
     * if the preimage is incorrect, the commitment is expired, the commitment
     * is too new, the commitment is missing, the deposit is insufficient for
     * whatever is being claimed, the Macroverse generators cannot be accessed
     * to prove the existence of the thing being claimed or its parents, or the
     * thing or a child or parent is already claimed by a conflicting
     * commitment. Otherwise issues the token for the bit-packed keypath given
     * in preimage.
     *
     * Doesn't need the commitment hash: it is computed from the provided
     * preimage.  Commitment lookup also depends on the originating address, so
     * the function must be called by the original committer.
     */
    function reveal(uint256 token, uint256 nonce) external {
        // Compute the committing hash that this is the preimage for
        bytes32 hash = keccak256(abi.encodePacked(token, nonce));
        
        // Look up the right commitment for this hash and owner._setBaseURI
        bytes32 commitment_key = keccak256(abi.encodePacked(hash, msg.sender));
        Commitment storage commitment = commitments[commitment_key];

        // Make sure it is present with the right nonzero hash.
        // If it seems to have a zero hash, the commitment is gone/never existed.
        require(commitment.hash == hash, "Commitment not found");
        
        // Make sure the commitment is not expired (max wait is in the future)
        require(commitment.creationTime + (commitmentMinWait * COMMITMENT_MAX_WAIT_FACTOR) > now, "Commitment expired");

        // Make sure the commitment is not too new (min wait is in the past)
        require(commitment.creationTime + commitmentMinWait < now, "Commitment too new");

        // Make sure the token doesn't already exists
        require(!backend.exists(token), "Token already exists");

        // Validate the token
        require(token.tokenIsCanonical(), "Token data mis-packed");
        // Make sure it refers to something real
        require(existenceChecker.exists(token), "Cannot claim non-existent thing");

        // Make sure that sufficient tokens have been deposited for this thing to be claimed
        require(commitment.deposit >= getMinDepositToCreate(token), "Deposit too small");

        // Do checks on the parent
        uint256 extant_parent = lowestExistingParent(token);
        if (extant_parent != 0) {
            // A parent exists. Can this person claim its children?
            require(childrenClaimable(extant_parent, msg.sender), "Cannot claim children here");
        }

        // If it's land, no children can be claimed already
        require(!token.tokenIsLand() || childTree[token] == 0, "Cannot claim land with claimed subplots");

        // OK, now we know the claim is valid. Execute it.

        // Create the token state, with homesteading off, carrying over the deposit
        tokenConfigs[token] = TokenConfig({
            deposit: commitment.deposit,
            homesteading: false
        });

        // Record it in the child tree. This informs all parent land tokens
        // that could be created that there are child claims, and blocks them.
        addChildToTree(token);

        // Destroy the commitment
        delete commitments[commitment_key];

        // Emit a reveal event, before actually making the token
        emit Reveal(hash, token, msg.sender);

        // If we pass everything, mint the token
        backend.mint(msg.sender, token);
    }

    /**
     * Destroy a token that you own, allowing it to be claimed by someone else.
     * Retruns the associated deposit to you.
     */
    function release(uint256 token) external {
        // Make sure nobody can release things that aren't claimed.
        require(backend.exists(token), "Token not extant");
        
        // Make sure only we can release our tokens.
        require(backend.ownerOf(token) == msg.sender, "Token owner mismatch");
        
        // Burn the token 
        backend.burn(token);

        // Say the token was released
        emit Release(token, msg.sender);

        // Remove it from the tree so it no longer blocks parent claims if it is land
        removeChildFromTree(token);
        
        // Work out what the deposit was
        uint256 deposit = tokenConfigs[token].deposit;

        // Clean up its config
        delete tokenConfigs[token];

        // Record we sent the deposit back
        expectedDepositBalance = expectedDepositBalance.sub(deposit);

        // Return the deposit
        require(depositTokenContract.transfer(msg.sender, deposit));
    }

    //
    // Token owner functions
    //

    /**
     * Set whether homesteading is allowed under a token. The token must be owned by you, and must not be land.
     */
    function setHomesteading(uint256 token, bool value) external {
        require(backend.ownerOf(token) == msg.sender, "Token owner mismatch");
        require(!token.tokenIsLand());
        
        // Find the token's config
        TokenConfig storage config = tokenConfigs[token];

        if (config.homesteading != value) {
            // The value is actually changing

            // Set the homesteading flag
            config.homesteading = value;

            // Make an event so clients can find homesteading areas
            emit Homesteading(token, value);
        }
    }

    /**
     * Get whether homesteading is allowed under a token.
     * Returns false for nonexistent or invalid tokens.
     */
    function getHomesteading(uint256 token) external view returns (bool) {
        // Only existing non-land tokens with homesteading on can be homesteaded.
        return (backend.exists(token) && !token.tokenIsLand() && tokenConfigs[token].homesteading); 
    }

    /**
     * Get the deposit tied up in a token, in MRV atomic units.
     * Returns 0 for nonexistent or invalid tokens.
     * Deposits associated with claims need to be gotten by looking at the claim mapping directly.
     */
    function getDeposit(uint256 token) external view returns (uint256) {
        // Only existing non-land tokens with homesteading on can be homesteaded.
        if (!backend.exists(token)) {
            return 0;
        }
        return tokenConfigs[token].deposit;
    }

    /**
     * Split a trixel of land into 4 sub-trixel tokens.
     * The new tokens will be owned by the same owner.
     * The old token will be destroyed.
     * Additional deposit may be required so that all subdivided tokens have at least the minimum deposit.
     * The deposit from the original token will be re-used if possible.
     * If the deposit available is not divisible by 4, the extra will be assigned to the first child token.
     */
    function subdivideLand(uint256 parent, uint256 additional_deposit) external {
        // Make sure the parent is land owned by the caller.
        // If a token is owned, it must be canonical.
        require(backend.ownerOf(parent) == msg.sender, "Token owner mismatch");

        // Make sure the parent isn't maximally subdivided
        require(parent.getTokenType() != TOKEN_TYPE_LAND_MAX, "Land maximally subdivided");

        // Get the deposit from it
        uint256 deposit = tokenConfigs[parent].deposit;

        // Take the new deposit from the caller
        // Record we have the deposit value
        expectedDepositBalance = expectedDepositBalance.add(additional_deposit);

        // Make sure we can take the deposit
        require(depositTokenContract.transferFrom(msg.sender, address(this), additional_deposit), "Deposit not approved");

        // Add in the new deposit
        deposit = deposit.add(additional_deposit);

        // Compute the token numbers for the new child tokens
        uint256[] memory children = new uint256[](CHILDREN_PER_TRIXEL);
        // And their deposits. In theory they might vary by token identity.
        uint256[] memory child_deposits = new uint256[](CHILDREN_PER_TRIXEL);
        // And the total required
        uint256 required_deposit = 0;
        for (uint256 i = 0; i < CHILDREN_PER_TRIXEL; i++) {
            uint256 child = parent.childTokenAtIndex(i);
            children[i] = child;
            uint256 child_deposit = getMinDepositToCreate(child);
            child_deposits[i] = child_deposit;
            required_deposit = required_deposit.add(child_deposit);
        }

        require(required_deposit <= deposit, "Deposit not sufficient");

        // Burn the parent
        backend.burn(parent);

        // Clean up its config
        delete tokenConfigs[parent];

        // Apportion deposit and create the children

        // Now deposit will be is the remaining deposit to try and distribute evenly among the children
        deposit = deposit.sub(required_deposit);
        uint256 split_evenly = deposit.div(CHILDREN_PER_TRIXEL);
        uint256 extra = deposit.mod(CHILDREN_PER_TRIXEL);
        child_deposits[0] = child_deposits[0].add(extra);
        for (uint256 i = 0; i < CHILDREN_PER_TRIXEL; i++) {
            child_deposits[i] = child_deposits[i].add(split_evenly);

            // Now we can make the child token config
            tokenConfigs[children[i]] = TokenConfig({
                deposit: child_deposits[i],
                homesteading: false
            });

            // Say land is being split
            emit LandSplit(parent, children[i]);

            // And mint the child
            backend.mint(msg.sender, children[i]);
        }

        // Set the parent's entry in the child tree to having all 4 children.
        // Its parent will still record its presence.
        childTree[parent] = 0xf;
    }

    /**
     * Combine 4 land tokens with the same parent trixel into one token for the parent trixel.
     * Tokens must all be owned by the message sender.
     * Allows withdrawing some of the deposit of the original child tokens, as long as sufficient deposit is left to back the new parent land claim.
     */
    function combineLand(uint256 child1, uint256 child2, uint256 child3, uint256 child4, uint256 withdraw_deposit) external {
        // Make a child array
        uint256[CHILDREN_PER_TRIXEL] memory children = [child1, child2, child3, child4];

        // And count up the deposit they represent
        uint256 available_deposit = 0;
        
        for (uint256 i = 0; i < CHILDREN_PER_TRIXEL; i++) {
            // Make sure all the children are owned by the caller
            require(backend.ownerOf(children[i]) == msg.sender, "Token owner mismatch");
            // If a token is owned, it must be canonical.

            // Collect the deposit
            available_deposit = available_deposit.add(tokenConfigs[children[i]].deposit);
        }
        
        // Make sure all the children are distinct
        require(children[0] != children[1], "Children not distinct");
        require(children[0] != children[2], "Children not distinct");
        require(children[0] != children[3], "Children not distinct");

        require(children[1] != children[2], "Children not distinct");
        require(children[1] != children[3], "Children not distinct");

        require(children[2] != children[3], "Children not distinct");
        
        // Make sure they are all children of the same parent
        uint256 parent = children[0].parentOfToken();
        for (uint256 i = 1; i < CHILDREN_PER_TRIXEL; i++) {
            require(children[i].parentOfToken() == parent, "Parent not shared");
        }
        
        // Make sure that that parent is land
        require(parent.tokenIsLand());

        // Compute the parent deposit
        uint256 parent_deposit = available_deposit.sub(withdraw_deposit);

        // Edge case: min deposit scale was adjusted and now the deposits for
        // the children aren't enough for the parent.
        // In that case, we allow the merge, but withdraw_deposit must be 0.
        if (withdraw_deposit > 0) {
            require(parent_deposit >= getMinDepositToCreate(parent), "Deposit not sufficient");
        }

        for (uint256 i = 0; i < CHILDREN_PER_TRIXEL; i++) {
            // Burn the children
            backend.burn(children[i]);

            // Clean up the config
            delete tokenConfigs[children[i]];

            // Say land is being merged
            emit LandSplit(children[i], parent);
        }

        // Make a parent config
        tokenConfigs[parent] = TokenConfig({
            deposit: parent_deposit,
            homesteading: false
        });

        // Create the parent
        backend.mint(msg.sender, parent);

        // Set the parent's entry in the child tree to having no children.
        // Its parent will still record its presence as an internal node.
        childTree[parent] = 0;

        // Return the requested amount of returned deposit.

        // Record we sent the deposit back
        expectedDepositBalance = expectedDepositBalance.sub(withdraw_deposit);

        // Return the deposit
        require(depositTokenContract.transfer(msg.sender, withdraw_deposit));
    }

    //
    // Admin functions
    //

    /**
     * Allow the contract owner to set the minimum deposit amount for granting new
     * system ownership claims.
     */
    function setMinimumSystemDeposit(uint256 new_minimum_deposit_in_atomic_units) external onlyOwner {
        minSystemDepositInAtomicUnits = new_minimum_deposit_in_atomic_units;
        emit DepositScaleChange(minSystemDepositInAtomicUnits);
    }

    /**
     * Set the minimum wait time in seconds for waiting for commitments to
     * mature and become revealable. The maximum time commitments have before
     * they expire is also adjusted, as it is a multiple of this value.
     */
    function setCommitmentMinWait(uint256 new_commitment_min_wait_in_seconds) external onlyOwner {
        commitmentMinWait = new_commitment_min_wait_in_seconds;
        emit CommitmentMinWaitChange(commitmentMinWait);
    }

    /**
     * Allow the owner to collect any non-MRV tokens, or any excess MRV, that ends up in this contract.
     */
    function reclaimToken(address otherToken) external onlyOwner {
        IERC20 other = IERC20(otherToken);
        
        // We will send our whole balance
        uint excessBalance = other.balanceOf(address(this));
        
        // Unless we're talking about the MRV token
        if (address(other) == address(depositTokenContract)) {
            // In which case we send only any balance that we shouldn't have
            excessBalance = excessBalance.sub(expectedDepositBalance);
        }
        
        // Make the transfer. If it doesn't work, we can try again later.
        other.transfer(owner(), excessBalance);
    }
    
    /**
     * Allow owner to change the ERC721 metadata URI domain used by the owned MacroverseRealEstate contract.
     */
    function setTokenMetadataDomain(string memory domain) external onlyOwner {
        backend.setTokenMetadataDomain(domain);
    }
}

// This code is part of Macroverse and is licensed: UNLICENSED