// SPDX-License-Identifier: MIT
pragma solidity >=0.6.12;

library BytesLib {
    function toAddress(bytes memory _bytes, uint256 _start) internal pure returns (address) {
        require(_start + 20 >= _start, 'TOKordinator: toAddress_overflow');
        require(_bytes.length >= _start + 20, 'TOKordinator: toAddress_outOfBounds');
        address tempAddress;

        assembly {
            tempAddress := div(mload(add(add(_bytes, 0x20), _start)), 0x1000000000000000000000000)
        }

        return tempAddress;
    }

    function getTokenOut(bytes memory _bytes) internal pure returns (address) {
        return toAddress(_bytes, _bytes.length - 20);
    }
}