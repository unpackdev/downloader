//
//  __   __      _____    ______
// /__/\/__/\   /_____/\ /_____/\
// \  \ \: \ \__\:::_:\ \\:::_ \ \
//  \::\_\::\/_/\   _\:\| \:\ \ \ \
//   \_:::   __\/  /::_/__ \:\ \ \ \
//        \::\ \   \:\____/\\:\_\ \ \
//         \__\/    \_____\/ \_____\/
//
// 420.game Reveal Buds
//
// by LOOK LABS
//
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./Pausable.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ILL420BudStaking.sol";
import "./MerkleMultiProof.sol";
import "./ArraySort.sol";

/**
 * @title LL420BudReveal
 * @dev Store the revealed timestamp to the staking contract, and also set the THC of a bud to the staking contract,
 * based on the verification of merkle proof
 *
 */
contract LL420BudReveal is Ownable, Pausable, ReentrancyGuard {
    uint16 public constant TOTAL_SUPPLY = 20000;
    uint256 public revealPeriod = 7 days;
    bytes32 public merkleRoot;

    address public immutable stakingContractAddress;
    mapping(uint256 => bool) public requested;

    event RequestReveal(uint256 indexed _budId, address indexed _user, uint256 indexed _timestamp);

    constructor(address _stakingAddress) {
        require(_stakingAddress != address(0), "Zero address");

        stakingContractAddress = _stakingAddress;
    }

    /* ==================== External METHODS ==================== */

    /**
     * @dev Reveal the buds
     *
     * @param _id Id of game key
     * @param _ids Id array of buds
     */
    function reveal(uint256 _id, uint256[] memory _ids) external nonReentrant whenNotPaused {
        require(_ids.length <= TOTAL_SUPPLY, "Incorrect bud ids");

        uint256 _revealPeriod = revealPeriod;
        ILL420BudStaking BUD_STAKING = ILL420BudStaking(stakingContractAddress);

        uint256[] memory budIds = BUD_STAKING.getGKBuds(_id, _msgSender());
        /// Check if the ids belong to correct owner
        /// Check if the id is in pending of reveal
        for (uint256 i = 0; i < _ids.length; i++) {
            require(!requested[_ids[i]], "Bud is already requested to reveal");

            bool belong = false;
            for (uint256 j = 0; j < budIds.length; j++) {
                if (_ids[i] == budIds[j]) {
                    belong = true;
                    break;
                }
            }
            require(belong, "Bud not belong to the sender");
        }

        /// Check if Buds can be revealed
        (uint256[] memory periods, ) = BUD_STAKING.getBudInfo(_ids);
        for (uint256 i = 0; i < periods.length; i++) {
            require(periods[i] >= _revealPeriod, "Staked more than limit");

            requested[_ids[i]] = true;

            emit RequestReveal(_ids[i], _msgSender(), block.timestamp);
        }

        BUD_STAKING.setRevealTimestamps(block.timestamp, _msgSender());
    }

    /**
     * @dev Set THCs of revealed buds
     *
     * @param _ids bud id array
     * @param _thcs THC array
     * @param _proofs Multi-merkle proofs
     * @param _proofFlags Proof flags
     */
    function setBudTHCs(
        uint256[] calldata _ids,
        uint256[] calldata _thcs,
        bytes32[] calldata _proofs,
        bool[] calldata _proofFlags
    ) external whenNotPaused nonReentrant {
        require(_ids.length == _thcs.length && _ids.length > 0, "Unmatched thc count");
        require(merkleRoot != 0, "Merklet root not set");

        bytes32[] memory nodes = new bytes32[](_ids.length);
        uint256 factor = 10**18;
        for (uint256 i = 0; i < _ids.length; i++) {
            nodes[i] = keccak256(abi.encodePacked(_ids[i] * factor, _thcs[i] * factor));
        }

        nodes = ArraySort.sort(nodes);

        bool isValid = MerkleMultiProof.verifyMultiProof(merkleRoot, nodes, _proofs, _proofFlags);
        require(isValid, "Invalid proof");

        ILL420BudStaking(stakingContractAddress).setRevealedTHC(_ids, _thcs);
    }

    /* ==================== OWNER METHODS ==================== */

    /**
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * @dev this set the reveal lock period for test from owner side.
     * @param _seconds reveal period in seconds
     */
    function setRevealPeriod(uint256 _seconds) external onlyOwner {
        revealPeriod = _seconds;
    }

    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }
}
