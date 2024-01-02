// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.10;

interface Initializable {
    function initialize(address poolAddressesProvider) external;
}

contract Create2Spark {

    address public immutable poolAddressesProvider;

    constructor(address _poolAddressesProvider) {
        poolAddressesProvider = _poolAddressesProvider;
    }

    function deploy(bytes32 salt, bytes memory creationCode) public payable returns (address addr) {
        require(creationCode.length != 0, "empty code");

        assembly {
            addr := create2(callvalue(), add(creationCode, 0x20), mload(creationCode), salt)
        }

        require(addr != address(0), "failed deployment");
    }

    function deployPool(bytes32 salt, bytes memory creationCode) external payable returns (address addr) {
        addr = deploy(salt, creationCode);
        Initializable(addr).initialize(poolAddressesProvider);
    }

    function computeAddress(bytes32 salt, bytes32 creationCodeHash) external view returns (address addr) {
        address contractAddress = address(this);
        
        assembly {
            let ptr := mload(0x40)

            mstore(add(ptr, 0x40), creationCodeHash)
            mstore(add(ptr, 0x20), salt)
            mstore(ptr, contractAddress)
            let start := add(ptr, 0x0b)
            mstore8(start, 0xff)
            addr := keccak256(start, 85)
        }
    }

}