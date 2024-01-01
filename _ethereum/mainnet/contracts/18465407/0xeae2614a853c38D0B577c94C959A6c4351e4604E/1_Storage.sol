// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;

contract Test {
    bytes public data;

    function addData(bytes calldata _data) public {
        data = _data;
    }
}
