// SPDX-License-Identifier: MIT

/// @title RaidParty Fighter Claim Contract

/**
 *   ___      _    _ ___          _
 *  | _ \__ _(_)__| | _ \__ _ _ _| |_ _  _
 *  |   / _` | / _` |  _/ _` | '_|  _| || |
 *  |_|_\__,_|_\__,_|_| \__,_|_|  \__|\_, |
 *                                    |__/
 */

pragma solidity ^0.8.0;

import "./Fighter.sol";
import "./MerkleProof.sol";
import "./AccessControlEnumerable.sol";

contract FighterClaim is AccessControlEnumerable {
    bool public isActive;
    uint32 public claimedAmount;
    uint32 public constant MAX_CLAIM = 1585;
    uint64 public expiresAt;

    Fighter public immutable fighter;

    bytes32 public merkleRoot;
    bytes32 public constant SALE_ADMIN_ROLE = keccak256("SALE_ADMIN_ROLE");

    mapping(address => bool) private _claimed;

    constructor(
        address admin,
        address saleAdmin,
        Fighter _fighter
    ) {
        _setupRole(DEFAULT_ADMIN_ROLE, admin);
        _setupRole(SALE_ADMIN_ROLE, saleAdmin);

        fighter = _fighter;
    }

    function setActive(bool _isActive) external onlyRole(SALE_ADMIN_ROLE) {
        isActive = _isActive;

        if (_isActive) {
            expiresAt = uint64(block.timestamp + 24 hours);
        }
    }

    function setMerkleRoot(bytes32 _merkleRoot)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(
            merkleRoot == bytes32(0),
            "FighterClaim::setMerkleRoot: MERKLE_ALREADY_SET"
        );

        merkleRoot = _merkleRoot;
    }

    function claimed(address user) external view returns (bool) {
        return _claimed[user];
    }

    function claim(bytes32[] calldata proof) external {
        unchecked {
            require(isActive, "FighterClaim::claim: INACTIVE");
            require(
                claimedAmount + 1 <= MAX_CLAIM,
                "FighterClaim::claim: MAX_REACHED"
            );

            _verifyMerkle(proof);

            claimedAmount += 1;
            _claimed[msg.sender] = true;

            fighter.mint(msg.sender, 1);
        }
    }

    /** INTERNAL */

    function _leaf() internal view returns (bytes32) {
        return keccak256(abi.encodePacked(msg.sender));
    }

    function _verifyMerkle(bytes32[] calldata proof) internal view {
        bytes32 leaf = _leaf();
        require(
            merkleRoot != bytes32(0),
            "FighterClaim::_verifyMerkle: MISSING_MERKLE"
        );
        require(
            !_claimed[msg.sender],
            "FighterClaim::_verifyMerkle: ALREADY_CLAIMED"
        );
        require(
            MerkleProof.verify(proof, merkleRoot, leaf),
            "FighterClaim::_verifyMerkle: PROOF_INVALID"
        );
    }
}
