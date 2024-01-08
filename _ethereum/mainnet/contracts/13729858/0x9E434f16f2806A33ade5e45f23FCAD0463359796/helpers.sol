// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces.sol";

contract Helpers {

    Interop public immutable interopContract;

    constructor(address interop) {
        interopContract = Interop(interop);
    }

    function _submitAction(
        Position memory position,
        string memory actionId,
        uint64 targetDsaId,
        uint256 targetChainId,
        bytes memory metadata
    ) internal {
        interopContract.submitAction(position, msg.sender, actionId, targetDsaId, targetChainId, metadata);
    }
}
