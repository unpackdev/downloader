// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;



// Part: IRaider

interface IRaider {
    struct Raider {
        uint256 dna;
        uint256 active_weapon;
    }

    struct RaiderTraits {
        bool isFemale;
        uint256 skin;
        uint256 hair;
        uint256 boots;
        uint256 pants;
        uint256 outfit;
        uint256 headwear;
        uint256 accessory;
        uint256 active_weapon;
    }

    function getTokenRaider(uint256 _tokenId) external view returns (Raider memory);

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
}

// Part: IRaiderArmory

interface IRaiderArmory {
    function addWeaponToToken(uint256 _tokenId, uint256 _weaponId) external;

    function hasWeapon(uint256 _tokenId, uint256 _weaponId)
        external
        returns (bool);

    function getMaxWeaponScore(uint256 _tokenId) external view returns (uint8);
}

// Part: IRaiderRender

interface IRaiderRender {
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// Part: OpenZeppelin/openzeppelin-contracts@4.4.0/Context

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

// Part: OpenZeppelin/openzeppelin-contracts@4.4.0/Strings

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
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
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// Part: OpenZeppelin/openzeppelin-contracts@4.4.0/Ownable

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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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

// File: RaiderRender.sol

contract RaiderRender is IRaiderRender, Ownable {
    using Strings for uint256;

    // mapping from trait (index) to its name
    string[9] traitTypes = [
        "Skin",
        "Hair",
        "Boots",
        "Pants",
        "Outfit",
        "Headwear",
        "Accessory",
        "Active weapon"
    ];

    // struct to store a trait's data for metadata and rendering
    struct Trait {
        string name;
        string png;
    }

    // mapping trait type (see traitTypes) to a mapping of an id to a trait expression
    mapping(uint256 => mapping(uint256 => Trait)) public traitData;

    // reference to raider
    IRaider private raider;
    // reference to armory
    IRaiderArmory private armory;

    constructor() {}

    /**********/
    /** ADMIN */
    /**********/

    function addDelegates(address _raidersContract, address _armoryContract) external onlyOwner {
        raider = IRaider(_raidersContract);
        armory = IRaiderArmory(_armoryContract);
    }

    /**
     * @notice uploads names and images associated with each trait
     * @param _traitType - the trait type to upload the traits for (see traitTypes)
     * @param _traitIds - ids for each trait expression
     * @param _traits - the names and base64 encoded PNGs for each trait expression
     */
    function uploadTraits(
        uint256 _traitType,
        uint256[] calldata _traitIds,
        Trait[] calldata _traits
    ) external onlyOwner {
        require(_traitIds.length == _traits.length, "Mismatched inputs");
        for (uint256 i = 0; i < _traits.length; i++) {
            traitData[_traitType][_traitIds[i]] = Trait(
                _traits[i].name,
                _traits[i].png
            );
        }
    }

    /**
     * @notice generates an <image> element using a base64 encoded PNG
     * @param _trait - the trait expression name and base 64 encoded PNG
     * @return the <image> element
     */
    function generateImgTrait(Trait memory _trait)
        private
        pure
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    '<image x="4" y="4" height="50" image-rendering="pixelated" preserveAspectRatio="xMidYMid" xlink:href="data:image/png;base64,',
                    _trait.png,
                    '"/>'
                )
            );
    }

    /*************/
    /** EXTERNAL */
    /*************/

    /**
     * @notice generates Raider struct for a tokenId
     * @param _tokenId - the tokenId to generate the struct for
     * @return struct of a specific Raider
     */
    function generateTokenTraits(uint256 _tokenId) public view returns (IRaider.RaiderTraits memory) {
        IRaider.Raider memory r = raider.getTokenRaider(_tokenId);
        IRaider.RaiderTraits memory traits;

        uint256 dna = r.dna;
        // gender
        traits.isFemale = ((dna % 100) % 2 == 0);
        dna = dna / 100;
        // skin
        traits.skin = traits.isFemale
            ? ((dna % 100) % 5)
            : (((dna % 100) % 5) + 5);
        dna = dna / 100;
        // hair
        traits.hair = traits.isFemale
            ? ((dna % 100) % 4)
            : (((dna % 100) % 4) + 4);
        dna = dna / 100;
        // boots
        traits.boots = ((dna % 100) % 4);
        dna = dna / 100;
        // pants
        traits.pants = ((dna % 100) % 7);
        dna = dna / 100;
        // outfit
        traits.outfit = traits.isFemale
            ? ((dna % 100) % 10)
            : (((dna % 100) % 10) + 10);
        dna = dna / 100;
        // headwear
        traits.headwear = ((dna % 100) % 8);
        dna = dna / 100;
        // accessory
        traits.accessory = ((dna % 100) % 7);
        // weapon
        traits.active_weapon = (r.active_weapon);

        return traits;
    }

    /**
     * @notice generates a full SVG from a token's tokenTraits by adding multiple <image> elements in order
     * @param _tokenId - the tokenId to generate the  SVG for
     * @param _traits - the Raider struct containing the traits
     * @return SVG of a raider
     */
    function compileSVG(uint256 _tokenId, IRaider.RaiderTraits memory _traits) public view returns (string memory) {

        string memory svg = string(
            abi.encodePacked(
                generateImgTrait(traitData[0][_traits.skin]),
                generateImgTrait(traitData[1][_traits.hair]),
                generateImgTrait(traitData[2][_traits.boots]),
                generateImgTrait(traitData[3][_traits.pants]),
                generateImgTrait(traitData[4][_traits.outfit]),
                generateImgTrait(traitData[5][_traits.headwear]),
                generateImgTrait(traitData[6][_traits.accessory]),
                generateImgTrait(traitData[7][_traits.active_weapon])
            )
        );

        return
            string(
                abi.encodePacked(
                    '<svg id="raiderversegen1" width="100%" height="100%" version="1.1" viewBox="0 0 58 58" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">',
                    svg,
                    "</svg>"
                )
            );
    }

    /**
     * @notice generates an attribute for the attribute array
     * @param _traitType - the string value of a trait (see traitTypes)
     * @param _value - the expression of that trait type
     * @return a JSON dictionary of a single attribute
     */
    function generateAttribute(string memory _traitType, string memory _value)
        private
        pure
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    '{"trait_type":"',
                    _traitType,
                    '","value":"',
                    _value,
                    '"}'
                )
            );
    }

    /**
     * @notice generates the attribute array for a given tokenId
     * @param _tokenId the tokenId
     * @param _traits - the Raider struct containing the traits
     * @return a JSON dictionary of a tokenIds attributes
     */
    function compileAttributes(uint256 _tokenId, IRaider.RaiderTraits memory _traits)
        public
        view
        returns (string memory)
    {
               
        string memory attributes = string(
            abi.encodePacked(
                generateAttribute(traitTypes[0], traitData[0][_traits.skin].name),
                ",",
                generateAttribute(traitTypes[1], traitData[1][_traits.hair].name),
                ",",
                generateAttribute(traitTypes[2], traitData[2][_traits.boots].name),
                ",",
                generateAttribute(traitTypes[3], traitData[3][_traits.pants].name),
                ",",
                generateAttribute(traitTypes[4], traitData[4][_traits.outfit].name),
                ",",
                generateAttribute(traitTypes[5], traitData[5][_traits.headwear].name),
                ",",
                generateAttribute(
                    traitTypes[6],
                    traitData[6][_traits.accessory].name
                ),
                ",",
                generateAttribute(
                    traitTypes[7],
                    traitData[7][_traits.active_weapon].name
                ),
                ","
            )
        );

        return
            string(
                abi.encodePacked(
                    "[",
                    attributes,
                    '{"trait_type":"Gender","value":',
                    _traits.isFemale ? '"Female"},' : '"Male"},',
                    '{"trait_type":"Max weapon score","value":',
                    uint2str(armory.getMaxWeaponScore(_tokenId)),
                    ',"max_value":10},',
                    '{"display_type":"number","trait_type":"Generation","value":1}',
                    "]"
                )
            );
    }

    /**
     * @notice generates a base64 encoded metadata response without referencing off-chain content
     * @param tokenId the id of the token to generate the metadata for
     * @return a base64 encoded JSON dictionary of the token's metadata and SVG
     */
    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        IRaider.RaiderTraits memory traits = generateTokenTraits(tokenId);

        string memory metadata = string(
            abi.encodePacked(
                '{"name":"Raider #',
                tokenId.toString(),
                '","description":"Thousands of unique tomb raiders and enemies hunting for $RGO. 100% on chain and public domain.","image":"data:image/svg+xml;base64,',
                base64(bytes(compileSVG(tokenId, traits))),
                '","attributes":',
                compileAttributes(tokenId, traits),
                "}"
            )
        );

        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    base64(bytes(metadata))
                )
            );
    }

    /***************/
    /* UINT2STRING */
    /***************/

    function uint2str(uint256 _i)
        internal
        pure
        returns (string memory _uintAsString)
    {
        if (_i == 0) {
            return "0";
        }
        uint256 j = _i;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint256 k = len;
        while (_i != 0) {
            k = k - 1;
            uint8 temp = (48 + uint8(_i - (_i / 10) * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }

    /************************************/
    /* BASE 64 - Written by Brech Devos */
    /************************************/

    string internal constant TABLE =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    function base64(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return "";

        // load the table into memory
        string memory table = TABLE;

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((data.length + 2) / 3);

        // add some extra buffer at the end required for the writing
        string memory result = new string(encodedLen + 32);

        assembly {
            // set the actual output length
            mstore(result, encodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 3 bytes at a time
            for {

            } lt(dataPtr, endPtr) {

            } {
                dataPtr := add(dataPtr, 3)

                // read 3 bytes
                let input := mload(dataPtr)

                // write 4 characters
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(shr(6, input), 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(input, 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
            }

            // padding with '='
            switch mod(mload(data), 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }
        }

        return result;
    }
}
