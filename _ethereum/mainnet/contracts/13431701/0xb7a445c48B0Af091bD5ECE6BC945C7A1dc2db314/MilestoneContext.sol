// SPDX-License-Identifier: MPL-2.0

pragma solidity >=0.8.4 <0.9.0;

import "./IERC20.sol";
import "./IEscrowDisputeManager.sol";
import "./EscrowUtilsLib.sol";

abstract contract MilestoneContext {
    struct Milestone {
        IERC20 paymentToken;
        address treasury;
        address payeeAccount;
        address refundAccount;
        IEscrowDisputeManager escrowDisputeManager;
        uint256 autoReleasedAt;
        uint256 amount;
        uint256 fundedAmount;
        uint256 refundedAmount;
        uint256 releasedAmount;
        uint256 claimedAmount;
        uint8 revision;
    }

    mapping (bytes32 => Milestone) public milestones;
    mapping (bytes32 => uint16) public lastMilestoneIndex;

    using EscrowUtilsLib for bytes32;

    event NewMilestone(
        bytes32 indexed cid,
        uint16 indexed index,
        bytes32 mid,
        address indexed paymentToken,
        address escrowDisputeManager,
        uint256 autoReleasedAt,
        uint256 amount
    );

    event ChildMilestone(
        bytes32 indexed cid,
        uint16 indexed index,
        uint16 indexed parentIndex,
        bytes32 mid
    );

    event FundedMilestone(
        bytes32 indexed mid,
        address indexed funder,
        uint256 indexed amount
    );

    event ReleasedMilestone(
        bytes32 indexed mid,
        address indexed releaser,
        uint256 indexed amount
    );

    event CanceledMilestone(
        bytes32 indexed mid,
        address indexed releaser,
        uint256 indexed amount
    );

    event WithdrawnMilestone(
        bytes32 indexed mid,
        address indexed recipient,
        uint256 indexed amount
    );

    event RefundedMilestone(
        bytes32 indexed mid,
        address indexed recipient,
        uint256 indexed amount
    );
}