// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

contract Create2Deployer {
    constructor() payable {}

    function deploy(uint256 salt, bytes memory code)
        public
        payable
        returns (address deployed)
    {
        assembly ("memory-safe") {
            deployed := create2(callvalue(), add(code, 0x20), mload(code), salt)
        }
    }

    receive() external payable {}

    fallback() external payable {}
}