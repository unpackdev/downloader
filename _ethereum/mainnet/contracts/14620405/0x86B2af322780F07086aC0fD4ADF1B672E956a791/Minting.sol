// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

library Minting {
    function getTokenId(bytes calldata blob)
    internal
    pure
    returns (
        uint256,
        uint256) {
        int256 index = indexOf(blob, ":", 0, 47);
        require(index >= 0, "Separator must exist");
        uint256 tokenID = toUint256(blob[1 : uint256(index) - 1]);
        return (tokenID, uint256(index) + 2);
    }

    function getRoyaltyFraction(bytes calldata blob, uint256 startIndex)
    internal
    pure
    returns (
        uint96,
        uint256) {
        uint96 royaltyNumerator = toUint96(
            blob[startIndex : startIndex + 5]
        );
        return (royaltyNumerator, startIndex + 5);
    }

    function getRoyaltyReceiver(bytes calldata blob, uint256 startIndex)
    internal
    pure
    returns (
        address,
        uint256) {
        address royaltyRecipient = toAddress(
            blob[startIndex : startIndex + 42]
        );
        return (royaltyRecipient, startIndex + 42);
    }

    function getURI(bytes calldata blob, uint256 startIndex)
    internal
    pure
    returns (
        string memory,
        uint256) {
        uint96 length;
        string memory uri;
        (uri, startIndex, length) = getVariableString(blob, startIndex);

        require(length > 0, "Bad format of mintingBlob");

        return (uri, startIndex);
    }

    function getDetails(bytes calldata blob, uint256 startIndex)
    internal
    pure
    returns (
        string memory) {
        uint96 length;
        string memory details;
        (details, startIndex, length) = getVariableString(blob, startIndex);

        return details;
    }

    function getVariableString(bytes calldata blob, uint256 startIndex)
    internal
    pure returns (
        string memory,
        uint256,
        uint96) {
        uint96 length;
        (length, startIndex) = getLength(blob, startIndex);
        if(length == 0){
            return ("", startIndex, length);
        }
        require(blob[startIndex] == ":", "Bad format of mintingBlob");
        startIndex = startIndex + 1;
        uint256 end = startIndex + uint256(length);
        require(end <= blob.length - 1, "Bad format of mintingBlob");
        bytes calldata variableBytes = blob[startIndex : end];
        string memory variable = string(
            variableBytes
        );
        return (variable, end, length);
    }

    function getLength(bytes calldata blob, uint256 startIndex)
    internal
    pure
    returns (
        uint96,
        uint256) {
        if (startIndex == blob.length - 1) {
            return (0, startIndex + 5);
        }
        require(startIndex + 5 <= blob.length - 1, "Bad format of mintingBlob");
        uint96 length = toUint96(
            blob[startIndex : startIndex + 5]
        );
        return (length, startIndex + 5);
    }


    function toUint256(bytes calldata b) internal pure returns (uint256) {
        uint256 result = 0;
        for (uint256 i = 0; i < b.length; i++) {
            uint256 val = uint256(uint8(b[i]));
            if (val >= 48 && val <= 57) {
                // input is 0-9
                result = result * 10 + (val - 48);
            } else {
                // invalid character, expecting integer input
                revert("invalid input, only numbers allowed");
            }
        }
        return result;
    }

    function toUint96(bytes calldata b) internal pure returns (uint96) {
        uint96 result = 0;
        for (uint256 i = 0; i < b.length; i++) {
            uint96 val = uint96(uint8(b[i]));
            if (val >= 48 && val <= 57) {
                // input is 0-9
                result = result * 10 + (val - 48);
            } else {
                // invalid character, expecting integer input
                revert("invalid input, only numbers allowed 96");
            }
        }
        return result;
    }

    function toAddress(bytes calldata b) internal pure returns (address) {
        uint256 result = 0;
        for (uint256 i = 0; i < b.length; i++) {
            uint256 c = uint256(uint8(b[i]));
            if (c >= 48 && c <= 57) {
                result = result * 16 + (c - 48);
            }
            else if (c >= 65 && c <= 90) {
                result = result * 16 + (c - 55);
            }
            else if (c >= 97 && c <= 122) {
                result = result * 16 + (c - 87);
            }
            else {
                revert("invalid input, unrecognized sign");
            }
        }
        return address(uint160(result));
    }

    /**
     * Index Of
     *
     * Locates and returns the position of a character within a string starting
     * from a defined offset
     *
     * @param _base When being used for a data type this is the extended object
     *              otherwise this is the string acting as the haystack to be
     *              searched
     * @param _value The needle to search for, at present this is currently
     *               limited to one character
     * @param _offset The starting point to start searching from which can start
     *                from 0, but must not exceed the length of the string
     * @return int The position of the needle starting from 0 and returning -1
     *             in the case of no matches found
     */
    function indexOf(
        bytes calldata _base,
        string memory _value,
        uint256 _offset,
        uint256 max
    ) internal pure returns (int256) {
        bytes memory _valueBytes = bytes(_value);

        assert(_valueBytes.length == 1);

        for (uint256 i = _offset; i < _base.length && i < max; i++) {
            if (_base[i] == _valueBytes[0]) {
                return int256(i);
            }
        }

        return - 1;
    }
}