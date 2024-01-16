// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

import "./ApproveLogic.sol";

contract HumanboundApproveLogic is ApproveLogic {
    function approve(address to, uint256 tokenId) public pure override {
        revert("HumanboundApproveLogic: approvals disallowed");
    }

    function setApprovalForAll(address operator, bool approved) public pure override {
        revert("HumanboundApproveLogic: approvals disallowed");
    }
}
