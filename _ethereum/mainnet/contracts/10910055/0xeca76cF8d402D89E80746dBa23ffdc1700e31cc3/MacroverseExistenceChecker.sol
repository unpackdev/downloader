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