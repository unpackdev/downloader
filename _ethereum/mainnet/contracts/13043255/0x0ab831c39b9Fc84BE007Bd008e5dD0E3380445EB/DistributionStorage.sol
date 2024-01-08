// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

import "./IENS.sol";
import "./IDistributionStorage.sol";

/**
 * @title DistributionStorage
 * @author MirrorXYZ
 */
contract DistributionStorage is IDistributionStorage {
    // ============ Immutable Storage ============

    // The node of the root name (e.g. namehash(mirror.xyz))
    bytes32 public immutable rootNode;
    /**
     * The address of the public ENS registry.
     * @dev Dependency-injectable for testing purposes, but otherwise this is the
     * canonical ENS registry at 0x00000000000C2E074eC69A0dFb2997BA6C7d2e1e.
     */
    IENS public immutable ensRegistry;

    // ============ Mutable Storage ============

    // The address for Mirror team and investors.
    address team;
    // The address of the governance token that this contract is allowed to mint.
    address token;
    // The address that is allowed to distribute.
    address treasury;
    // The amount that has been contributed to the treasury.
    mapping(address => uint256) public contributions;
    mapping(address => uint256) public awards;
    // The number of rewards that are created per 1 ETH contribution to the treasury.
    uint256 contributionsFactor = 1000;
    // The amount that has been claimed per address.
    mapping(address => uint256) public claimed;
    // The block number that an address last claimed
    mapping(address => uint256) public lastClaimed;
    // The block number that an address registered
    mapping(address => uint256) public override registered;
    // Banned accounts
    mapping(address => bool) public banned;
    // The percentage of tokens issued that are taken by the Mirror team.
    uint256 teamRatio = 40;
    uint256 public registrationReward = 100 * 1e18;
    uint256 public registeredMembers;

    struct DistributionEpoch {
        uint256 startBlock;
        uint256 claimablePerBlock;
    }

    DistributionEpoch[] public epochs;
    uint256 numEpochs = 0;

    constructor(bytes32 rootNode_, address ensRegistry_) {
        rootNode = rootNode_;
        ensRegistry = IENS(ensRegistry_);
    }
}
