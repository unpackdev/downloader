// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "./ERC1155.sol";
import "./MerkleProof.sol";

contract QuetzalTrophies is ERC1155 {
    uint256 public constant RUBBLE = 0;
    bytes32 public RUBBLE_ROOT;
    uint256 public constant FEATHER = 1;
    bytes32 public FEATHER_ROOT;
    uint256 public constant EYE = 2;
    bytes32 public EYE_ROOT;
    uint256 public constant CLAW = 3;
    bytes32 public CLAW_ROOT;
    uint256 public constant CROWN = 4;
    bytes32 public CROWN_ROOT;

    // account => tokenId => claimed
    mapping(address => mapping(uint256 => bool)) public claimed;

    constructor(string memory uri, bytes32[5] memory merkleRoots) ERC1155(uri) {
        RUBBLE_ROOT = merkleRoots[0];
        FEATHER_ROOT = merkleRoots[1];
        EYE_ROOT = merkleRoots[2];
        CLAW_ROOT = merkleRoots[3];
        CROWN_ROOT = merkleRoots[4];
    }

    function mint(
        uint256 tokenId,
        uint256 amount,
        bytes32[] memory proof
    ) public {
        bytes32 root;
        if (tokenId == RUBBLE) {
            root = RUBBLE_ROOT;
        } else if (tokenId == FEATHER) {
            root = FEATHER_ROOT;
        } else if (tokenId == EYE) {
            root = EYE_ROOT;
        } else if (tokenId == CLAW) {
            root = CLAW_ROOT;
        } else if (tokenId == CROWN) {
            root = CROWN_ROOT;
        } else {
            revert("Invalid tokenId");
        }
        require(
            MerkleProof.verify(
                proof,
                root,
                keccak256(abi.encodePacked(msg.sender, tokenId, amount))
            ),
            "Invalid proof"
        );
        require(!claimed[msg.sender][tokenId], "Already claimed");
        _mint(msg.sender, tokenId, amount, "");
        claimed[msg.sender][tokenId] = true;
    }

    function canClaim(
        address account,
        uint256 tokenId,
        uint256 amount,
        bytes32[] memory proof
    ) public view returns (bool) {
        bytes32 root;
        if (tokenId == RUBBLE) {
            root = RUBBLE_ROOT;
        } else if (tokenId == FEATHER) {
            root = FEATHER_ROOT;
        } else if (tokenId == EYE) {
            root = EYE_ROOT;
        } else if (tokenId == CLAW) {
            root = CLAW_ROOT;
        } else if (tokenId == CROWN) {
            root = CROWN_ROOT;
        } else {
            revert("Invalid tokenId");
        }
        return
            MerkleProof.verify(
                proof,
                root,
                keccak256(abi.encodePacked(account, tokenId, amount))
            ) && !claimed[account][tokenId];
    }
}
