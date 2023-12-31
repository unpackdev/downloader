// // SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// 0xaf3e5bc5c91b6fe24253e07bfe315783ca1777906e90af0559933cf050d48b3d
// "foo abr" => 666f6f20616272 => as int 28832970699793010

contract Foobars {
    event foobie(uint256 asInteger, bytes32 asHex);

    function encode(
        bytes32 txn,
        string memory data
    ) public returns (uint256 info) {
        info |= uint256(txn) << 224;
        info |= uint(uint160(msg.sender)) << 64;
        info |= uint(bytes32(abi.encodePacked(data)));

        emit foobie(info, bytes32(info));

        return info;
    }
}
