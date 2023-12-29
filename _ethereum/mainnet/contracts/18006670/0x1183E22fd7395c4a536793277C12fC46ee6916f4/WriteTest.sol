// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

contract WriteTest
{
    bytes[] public data;

    function writeBytesToArray(bytes calldata content) public {
        data.push(content);
    }
}
