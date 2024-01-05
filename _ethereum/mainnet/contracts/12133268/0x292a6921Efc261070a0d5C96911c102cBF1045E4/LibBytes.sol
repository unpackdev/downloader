/**
 *Submitted for verification at Etherscan.io on 2019-05-13
*/

/*

    Copyright 2019 dYdX Trading Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

*/

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

library LibBytes {
      /***********************************|
    |        Read Bytes Functions       |
    |__________________________________*/

    /**
    * @dev Reads a bytes32 value from a position in a byte array.
    * @param b Byte array containing a bytes32 value.
    * @param index Index in byte array of bytes32 value.
    * @return result bytes32 value from byte array.
    */
    function readBytes32(
        bytes memory b,
        uint256 index
    )
        internal
        pure
        returns (bytes32 result)
    {
        require(
        b.length >= index + 32,
        "LibBytes#readBytes32 greater or equal to 32 length required"
        );

        // Arrays are prefixed by a 256 bit length parameter
        index += 32;

        // Read the bytes32 from array memory
        assembly {
        result := mload(add(b, index))
        }
        return result;
    }
}