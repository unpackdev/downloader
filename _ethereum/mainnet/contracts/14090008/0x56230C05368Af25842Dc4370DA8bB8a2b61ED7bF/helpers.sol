// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";


contract Helpers {
    using SafeERC20 for IERC20;

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

    function _submitActionERC20(
        Position memory position,
        string memory actionId,
        uint64 targetDsaId,
        uint256 targetChainId,
        bytes memory metadata
    ) internal {
        for (uint256 i = 0; i < position.supply.length; i++) {
            IERC20 token = IERC20(position.supply[i].sourceToken);
            uint256 amt = position.supply[i].amount;
            token.safeApprove(address(interopContract), amt);
        }

        interopContract.submitActionERC20(position, msg.sender, actionId, targetDsaId, targetChainId, metadata);
    }
}
