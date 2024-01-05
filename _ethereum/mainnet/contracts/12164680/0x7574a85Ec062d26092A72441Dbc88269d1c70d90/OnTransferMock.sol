// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IOnTransfer.sol";

contract OnTransferMock is IOnTransfer {

    event MockTransferEvent(address from, address to, uint256 tokenId);

    function onTransfer(address from, address to, uint256 tokenId) public override {
        emit MockTransferEvent(from, to, tokenId);
    }
}
