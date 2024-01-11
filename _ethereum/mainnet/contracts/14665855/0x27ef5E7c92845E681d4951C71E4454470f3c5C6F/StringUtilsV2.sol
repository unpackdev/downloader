// SPDX-License-Identifier: MIT
/// Deployed by CyberPnk <cyberpnk@stringutilsv2.cyberpnk.win>

pragma solidity ^0.8.13;

import "./NumberToString.sol";
import "./AddressToString.sol";
import "./Base64.sol";

contract StringUtilsV2 {
    function base64Encode(bytes memory data) external pure returns (string memory) {
        return Base64.encode(data);
    }

    function base64EncodeJson(bytes memory data) external pure returns (string memory) {
        return string(abi.encodePacked('data:application/json;base64,', Base64.encode(data)));
    }

    function base64EncodeSvg(bytes memory data) external pure returns (string memory) {
        return string(abi.encodePacked("data:image/svg+xml;base64,", Base64.encode(data)));
    }

    function numberToString(uint256 value) external pure returns (string memory) {
        return NumberToString.numberToString(value);
    }

    function addressToString(address account) external pure returns(string memory) {
        return AddressToString.addressToString(account);
    }

    // This is quite inefficient, should be used only in read functions
    function split(string calldata str, string calldata delim) external pure returns(string[] memory) {
        uint numStrings = 1;
        for (uint i=0; i < bytes(str).length; i++) {            
            if (bytes(str)[i] == bytes(delim)[0]) {
                numStrings += 1;
            }
        }

        string[] memory strs = new string[](numStrings);

        string memory current = "";
        uint strIndex = 0;
        for (uint i=0; i < bytes(str).length; i++) {            
            if (bytes(str)[i] == bytes(delim)[0]) {
                strs[strIndex++] = current;
                current = "";
            } else {
                current = string(abi.encodePacked(current, bytes(str)[i]));
            }
        }
        strs[strIndex] = current;
        return strs;
    }

    function substr(bytes calldata str, uint startIndexInclusive, uint endIndexExclusive) external pure returns(string memory) {
        bytes memory result = new bytes(endIndexExclusive - startIndexInclusive);
        for (uint j = startIndexInclusive; j < endIndexExclusive; j++) {
            result[j - startIndexInclusive] = str[j];
        }
        return string(result);
    }

    function substrStart(bytes calldata str, uint endIndexExclusive) external pure returns(string memory) {
        bytes memory result = new bytes(endIndexExclusive);
        for (uint j = 0; j < endIndexExclusive; j++) {
            result[j] = str[j];
        }
        return string(result);
    }

}
