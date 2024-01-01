// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import "./Ownable.sol";
import "./Create3.sol";

contract Create3Deployer is Ownable {
    constructor(address owner_) Ownable(owner_) {} // solhint-disable-line no-empty-blocks

    function deploy(bytes32 salt, bytes calldata code) external onlyOwner returns (address) {
        return Create3.create3(salt, code);
    }

    function addressOf(bytes32 salt) external view returns (address) {
        return Create3.addressOf(salt);
    }
}
