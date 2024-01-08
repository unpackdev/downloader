// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./SafeMath.sol";

/**
 * @title MarsStorage contract
 */
contract MarsStorage is Ownable {
    using SafeMath for uint256;
    
    // hash code: 0x12 (SHA-2) and digest length: 0x20 (32 bytes / 256 bits)
    bytes2 public constant MULTIHASH_PREFIX = 0x1220;
    // IPFS CID Version: v0
    uint256 public constant CID_VERSION = 0;

    // IPFS v0 CIDs in hexadecimal without multihash prefix ordered by initial sequence
    bytes32[] private _intitialSequenceTokenHashes;

    uint256 internal _maxSupply;

    bytes internal constant _ALPHABET = "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz";

    /**
     * @dev Sets immutable values of contract.
     */
    constructor (uint256 maxSupply_) {
        _maxSupply = maxSupply_;
    }

    /**
     * @dev Returns the IPFS v0 CID of {initialSequenceIndex}.
     * 
     * The returned values can be concatenated and hashed using SHA2-256 to verify the
     * provenance hash.
     */
    function initialSequenceTokenCID(uint256 initialSequenceIndex) public view returns (string memory) {
        bytes memory tokenCIDHex = abi.encodePacked(
            MULTIHASH_PREFIX,
            _intitialSequenceTokenHashes[initialSequenceIndex]
         );
        string memory tokenCID = _toBase58(tokenCIDHex);
        return tokenCID;
    }

    /**
     * @dev Sets token hashes in the initially set order as verifiable through
     * {_provenanceHash}.
     * 
     * Provided {tokenHashes} are IPFS v0 CIDs in hexadecimal without the prefix 0x1220
     * and ordered in the initial sequence.
     */
    function setInitialSequenceTokenHashes(bytes32[] memory tokenHashes) onlyOwner public {
        setInitialSequenceTokenHashesAtIndex(_intitialSequenceTokenHashes.length, tokenHashes);
    }

    /**
     * @dev Sets token hashes in the initially set order starting at {startIndex}.
     */
    function setInitialSequenceTokenHashesAtIndex(
        uint256 startIndex,
        bytes32[] memory tokenHashes
    ) public onlyOwner {
        require(startIndex <= _intitialSequenceTokenHashes.length);

        for (uint256 i = 0; i < tokenHashes.length; i++) {
            if ((i + startIndex) >= _intitialSequenceTokenHashes.length) {
                _intitialSequenceTokenHashes.push(tokenHashes[i]);
            } else {
                _intitialSequenceTokenHashes[i + startIndex] = tokenHashes[i];
            }
        }

        require(_intitialSequenceTokenHashes.length <= _maxSupply);
    }

    // Source: verifyIPFS (https://github.com/MrChico/verifyIPFS/blob/master/contracts/verifyIPFS.sol)
    // @author Martin Lundfall (martin.lundfall@consensys.net)
    // @dev Converts hex string to base 58
    function _toBase58(bytes memory source)
        internal
        pure
        returns (string memory)
    {
        if (source.length == 0) return new string(0);
        uint8[] memory digits = new uint8[](46);
        digits[0] = 0;
        uint8 digitlength = 1;
        for (uint256 i = 0; i < source.length; ++i) {
            uint256 carry = uint8(source[i]);
            for (uint256 j = 0; j < digitlength; ++j) {
                carry += uint256(digits[j]) * 256;
                digits[j] = uint8(carry % 58);
                carry = carry / 58;
            }

            while (carry > 0) {
                digits[digitlength] = uint8(carry % 58);
                digitlength++;
                carry = carry / 58;
            }
        }
        return string(_toAlphabet(_reverse(_truncate(digits, digitlength))));
    }

    function _truncate(uint8[] memory array, uint8 length)
        internal
        pure
        returns (uint8[] memory)
    {
        uint8[] memory output = new uint8[](length);
        for (uint256 i = 0; i < length; i++) {
            output[i] = array[i];
        }
        return output;
    }

    function _reverse(uint8[] memory input)
        internal
        pure
        returns (uint8[] memory)
    {
        uint8[] memory output = new uint8[](input.length);
        for (uint256 i = 0; i < input.length; i++) {
            output[i] = input[input.length - 1 - i];
        }
        return output;
    }

    function _toAlphabet(uint8[] memory indices)
        internal
        pure
        returns (bytes memory)
    {
        bytes memory output = new bytes(indices.length);
        for (uint256 i = 0; i < indices.length; i++) {
            output[i] = _ALPHABET[indices[i]];
        }
        return output;
    }
}