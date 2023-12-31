// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./AccessControlUpgradeable.sol";
import "./Initializable.sol";
import "./IMuonNodeStaking.sol";
import "./IMuonNodeManager.sol";

contract Helper is Initializable, AccessControlUpgradeable {
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    IMuonNodeStaking public nodeStaking;

    IMuonNodeManager public nodeManager;

    struct NodeData {
        uint64 nodeId;
        address nodeAddress;
        address stakerAddress;
        string peerId;
        bool active;
        uint8 tier;
        uint64[] roles;
        uint256 startTime;
        uint256 endTime;
        uint256 lastEditTime;
        uint256 balance;
        uint256 paidReward;
        uint256 paidRewardPerToken;
        uint256 pendingRewards;
        uint256 tokenId;
        uint256 earned;
        uint256 rewardPerToken;
    }

    function __MuonNodeStakingUpgradeable_init(
        address muonNodeStakingAddress,
        address muonNodeManagerAddress
    ) internal initializer {
        __AccessControl_init();

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(ADMIN_ROLE, msg.sender);

        nodeStaking = IMuonNodeStaking(muonNodeStakingAddress);
        nodeManager = IMuonNodeManager(muonNodeManagerAddress);
    }

    /**
     * @dev Initializes the contract.
     * @param muonNodeStakingAddress The address of the Muon node staking contract.
     * @param muonNodeManagerAddress The address of the Muon node manager contract.
     */
    function initialize(
        address muonNodeStakingAddress,
        address muonNodeManagerAddress
    ) external initializer {
        __MuonNodeStakingUpgradeable_init(
            muonNodeStakingAddress,
            muonNodeManagerAddress
        );
    }

    function __MuonNodeStakingUpgradeable_init_unchained()
        internal
        initializer
    {}

    /**
     * @dev get all data needed to calculate user reward.
     * @param stakerAddress The address of the staker.
     */
    function getData(address stakerAddress) external view returns (NodeData memory nodeData) {
        IMuonNodeManager.Node memory node = nodeManager.stakerAddressInfo(
            stakerAddress
        );

        IMuonNodeStaking.User memory user = nodeStaking.users(stakerAddress);

        nodeData = NodeData({
            nodeId: node.id,
            nodeAddress: node.nodeAddress,
            stakerAddress: node.stakerAddress,
            peerId: node.peerId,
            active: node.active,
            tier: node.tier,
            roles: node.roles,
            startTime: node.startTime,
            endTime: node.endTime,
            lastEditTime: node.lastEditTime,
            balance: user.balance,
            paidReward: user.paidReward,
            paidRewardPerToken: user.paidRewardPerToken,
            pendingRewards: user.pendingRewards,
            tokenId: user.tokenId,
            earned: nodeStaking.earned(stakerAddress),
            rewardPerToken: nodeStaking.rewardPerToken()
        });
    }

    function setNodeStaking(address muonNodeStakingAddress)
        external
        onlyRole(ADMIN_ROLE)
    {
        nodeStaking = IMuonNodeStaking(muonNodeStakingAddress);
    }

    function setNodeManager(address muonNodeManagerAddress)
        external
        onlyRole(ADMIN_ROLE)
    {
        nodeManager = IMuonNodeManager(muonNodeManagerAddress);
    }
}
