// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;
import "./BytesLib.sol";

library UniV3PathEncoding {
    
    function _decodePath(bytes memory data) internal pure returns (address[] memory) {
        // the pattern of the data is "0x [token address (40 hex characters)] - [fee (6 hex characters)] - [token]"
        uint256 numberOfTokens = ((data.length - 20) / 23) + 1;
        address[] memory path = new address[](numberOfTokens);

        uint i = 0;
        do {
            uint256 offset = 20 + (i * 23);
            address tokenAddress;
            assembly {
                tokenAddress := mload(add(data, offset))
            }
            path[i] = tokenAddress;
            unchecked {
                i++;
            }
        } while (i < numberOfTokens);
        

        return path;

    }

    function _replaceFirstAddress(bytes memory data, address newAddress) internal pure returns (bytes memory) {
        bytes memory sliced = BytesLib.slice(data, 20, data.length - 20);
        bytes memory newData = abi.encodePacked(newAddress, sliced);
        return newData;
    }

    function _replaceLastAddress(bytes memory data, address newAddress) internal pure returns (bytes memory) {
        bytes memory sliced = BytesLib.slice(data, 0, data.length - 20);
        bytes memory newData = abi.encodePacked(sliced, newAddress);
        return newData;
    }

}  