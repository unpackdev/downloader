// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./Dead.sol";

contract Factory {
    event Deployed(address addr, uint salt);

    function getBytecode(
        address wagdieAddress
    ) public pure returns (bytes memory) {
        bytes memory bytecode = type(DEAD).creationCode;
        return abi.encodePacked(bytecode, abi.encode(wagdieAddress));
    }

    function getAddress(bytes memory bytecode, uint _salt) public view returns (address) {
        bytes32 hash = keccak256(abi.encodePacked(bytes1(0xff), address(this), _salt, keccak256(bytecode)));
        return address(uint160(uint(hash)));
    }

    function deploy(
        address wagdieAddress,
        bytes32 _salt
    ) public payable returns (address) {
        return address(new DEAD{salt: _salt}(wagdieAddress));
    }
}