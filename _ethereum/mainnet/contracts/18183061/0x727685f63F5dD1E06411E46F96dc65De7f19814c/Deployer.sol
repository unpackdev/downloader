/**
 * https://biubiu.tools
 */
// /\\\\\\\\   /\\\\\\\\  /\\\    /\\\  /\\\\\\\\   /\\\\\\\\  /\\\    /\\\  /\\\\\\\\\\\\  /\\\\\\\\      /\\\\\\\\    /\\\          /\\\\\\\\\\
// \/\\\   \\\ \/_/\\\_/  \/\\\   \/\\\ \/\\\   \\\ \/_/\\\_/  \/\\\   \/\\\ \/___/\\\___/ /\\\_____/\\\  /\\\_____/\\\ \/\\\        /\\\_______/
//  \/\\\   \\\   \/\\\    \/\\\   \/\\\ \/\\\   \\\   \/\\\    \/\\\   \/\\\     \/\\\    \/\\\    \/\\\ \/\\\    \/\\\ \/\\\       \/\\\
//   \/\\\\\\\     \/\\\    \/\\\   \/\\\ \/\\\\\\\     \/\\\    \/\\\   \/\\\     \/\\\    \/\\\    \/\\\ \/\\\    \/\\\ \/\\\       \/\\\\\\\\\\
//    \/\\\   \\\\  \/\\\    \/\\\   \/\\\ \/\\\   \\\\  \/\\\    \/\\\   \/\\\     \/\\\    \/\\\    \/\\\ \/\\\    \/\\\ \/\\\       \/_______/\\\
//     \/\\\    \\\  \/\\\    \/\\\   \/\\\ \/\\\    \\\  \/\\\    \/\\\   \/\\\     \/\\\    \/\\\    \/\\\ \/\\\    \/\\\ \/\\\               \/\\\
//      \/\\\\\\\\\  /\\\\\\\\ \/_/\\\\\\\\  \/\\\\\\\\\  /\\\\\\\\ \/_/\\\\\\\\      \/\\\    \/_/\\\\\\\\\  \/_/\\\\\\\\\  \/\\\\\\\\\\ /\\\\\\\\\/
//       \/______/   \/______/   \/_______/   \/______/   \/______/   \/_______/       \/_/       \/_______/     \/_______/   \/________/ \/_______/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract Deployer {
    event Deployed(address addr, uint salt);

    function getAddress(
        bytes memory bytecode,
        address sender,
        uint _salt
    ) public view returns (address) {
        bytes32 newSalt = keccak256(abi.encodePacked(_salt, sender));

        bytes32 hash = keccak256(
            abi.encodePacked(
                bytes1(0xff),
                address(this),
                newSalt,
                keccak256(bytecode)
            )
        );

        return address(uint160(uint(hash)));
    }

    function deploy(
        bytes memory bytecode,
        uint _salt
    ) public payable returns (address addr) {
        bytes32 newSalt = keccak256(abi.encodePacked(_salt, msg.sender));

        assembly {
            addr := create2(
                callvalue(),
                add(bytecode, 0x20),
                mload(bytecode),
                newSalt
            )

            if iszero(extcodesize(addr)) {
                revert(0, 0)
            }
        }

        emit Deployed(addr, _salt);
    }
}
