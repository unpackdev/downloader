// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

library Utils {
  bytes internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /// @notice Encodes some bytes to the base64 representation
    function b64encode(bytes memory data) internal pure returns (string memory) {
        uint256 len = data.length;
        if (len == 0) return "";

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((len + 2) / 3);

        // Add some extra buffer at the end
        bytes memory result = new bytes(encodedLen + 32);

        bytes memory table = TABLE;

        assembly {
            let tablePtr := add(table, 1)
            let resultPtr := add(result, 32)

            for {
                let i := 0
            } lt(i, len) {

            } {
                i := add(i, 3)
                let input := and(mload(add(data, i)), 0xffffff)

                let out := mload(add(tablePtr, and(shr(18, input), 0x3F)))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(input, 0x3F))), 0xFF))
                out := shl(224, out)

                mstore(resultPtr, out)

                resultPtr := add(resultPtr, 4)
            }

            switch mod(len, 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }

            mstore(result, encodedLen)
        }

        return string(result);
    }


    function uint2str(uint256 value) internal pure returns (string memory) {
    // Inspired by OraclizeAPI's implementation - MIT license
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
    function addr2str(address x) internal pure returns (string memory) {
      bytes memory s = new bytes(40);
      for (uint i = 0; i < 20; i++) {
          bytes1 b = bytes1(uint8(uint(uint160(x)) / (2**(8*(19 - i)))));
          bytes1 hi = bytes1(uint8(b) / 16);
          bytes1 lo = bytes1(uint8(b) - 16 * uint8(hi));
          s[2*i] = char(hi);
          s[2*i+1] = char(lo);            
      }
      return string(s);
    }

    function char(bytes1 b) internal pure returns (bytes1 c) {
        if (uint8(b) < 10) return bytes1(uint8(b) + 0x30);
        else return bytes1(uint8(b) + 0x57);
    }

    function trim(string memory str) internal pure returns (string memory) {
        bytes memory bStr = bytes(str);
        uint nStart = 0;
        uint nEnd = bStr.length-1;
        while (uint8(bStr[nStart]) == 32 && nStart <= bStr.length-1) {
            nStart++;
        }
        while (uint8(bStr[nEnd]) == 32 && nEnd >= nStart) {
            nEnd--;
        }
        if (nStart > nEnd) {
            return "";
        }
        bytes memory newBytes = new bytes(nEnd - nStart + 1);
        //copy
        uint j=0;
        for(uint i = nStart; i<= nEnd; i++) {
            newBytes[j] = bStr[i];
            j++;
        } 
        return string(newBytes);
    }

    function lowercase(string memory str) internal pure returns (string memory) {
        bytes memory bStr = bytes(str);
        bytes memory bLower = new bytes(bStr.length);
        for (uint i = 0; i < bStr.length; i++) {
            // A-Z... --> a-z
            if ((uint8(bStr[i]) >= 65) && (uint8(bStr[i]) <= 90)) {
                bLower[i] = bytes1(uint8(bStr[i]) + 32);
            } else {
                bLower[i] = bStr[i];
            }
        }
        return string(bLower);
    }

    function getChainId() internal view returns (uint256 chainId) {
        assembly {
            chainId := chainid()
        }
    }

    function getNetwork() internal view returns (string memory) {
        string[6] memory networks; 
        networks[1] = "mainnet";
        networks[3] = "ropsten";
        networks[4] = "rinkeby";
        networks[5] = "goerli";
        uint256 cid = getChainId();
        return networks[cid];
    }

}
