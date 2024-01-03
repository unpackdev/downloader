// SPDX-License-Identifier: UNLICENSED;
pragma solidity 0.6.12;

import "./SafeMath.sol";

library Bytes {
    using SafeMath for uint256;

    function toUint256(bytes memory _bytes)
        internal
        pure
        returns (uint256 value)
    {
        assembly {
            value := mload(add(_bytes, 0x20))
        }
    }
}
