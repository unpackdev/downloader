// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./underground.sol";

contract Factory {
    event Deployed(address addr, uint salt);

    function getBytecode(
        string memory _name,
        string memory _symbol,
        string memory _uri
    ) public pure returns (bytes memory) {
        bytes memory bytecode = type(underground).creationCode;
        return abi.encodePacked(bytecode, abi.encode(_name, _symbol, _uri));
    }

    function getAddress(bytes memory bytecode, uint _salt) public view returns (address) {
        bytes32 hash = keccak256(abi.encodePacked(bytes1(0xff), address(this), _salt, keccak256(bytecode)));
        return address(uint160(uint(hash)));
    }

    function deploy(
        string memory _name,
        string memory _symbol,
        string memory _uri,
        bytes32 _salt
    ) public payable returns (address) {
        return address(new underground{salt: _salt}(_name, _symbol, _uri));
    }
}