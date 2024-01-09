// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

import "./Accessable.sol";
import "./IInblockGuard.sol";


contract InblockGuard is IInblockGuard, Accessable {
    // actor => block.number
    mapping (address => uint256) private _lastWrite;

    constructor() {}

    function updateInblockGuard() external override onlyAdmin {
        _lastWrite[tx.origin] = block.number;
    }

    modifier inblockGuard (address actor) {
        require(isAdmin(msg.sender) || _lastWrite[actor] < block.number, "InblockRestriction: Cannot interact in the current block");
        _;
    }
}