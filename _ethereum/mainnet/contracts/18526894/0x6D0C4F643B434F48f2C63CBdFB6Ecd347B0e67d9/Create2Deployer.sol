// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import "./Ownable.sol";
import "./Create2.sol";

contract Create2Deployer is Ownable {

    error CallReverted(uint256, bytes);
    event LogDeployed(address addr, uint256 salt);

    constructor() Ownable(msg.sender) {
    }

    function deployAndCalls(bytes32 salt, bytes memory creationCode, bytes[] calldata cds) onlyOwner external payable returns(address deployed) {
        deployed = Create2.deploy(msg.value, salt, creationCode);
        for (uint256 i = 0; i < cds.length; i++) {
            (bool success, bytes memory reason) = deployed.call(cds[i]);  // solhint-disable-line avoid-low-level-calls
            if (!success) revert CallReverted(i, reason);
        }
    }

    function computeAddress(bytes32 salt, bytes32 creationCodeHash) external view returns (address) {
        return Create2.computeAddress(salt, creationCodeHash);
    }
}


