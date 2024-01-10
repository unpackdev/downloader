/*
██╗  ██╗██████╗ 
╚██╗██╔╝██╔══██╗
 ╚███╔╝ ██████╔╝
 ██╔██╗ ██╔═══╝ 
██╔╝ ██╗██║     
╚═╝  ╚═╝╚═╝           
*/
//SPDX-License-Identifier: CC0
pragma solidity ^0.8.0;

import "./MerkleProof.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";

interface IRiftData {
    function addXP(uint256 xp, uint256 bagId) external;
}

contract HistoricalXP is Ownable, ReentrancyGuard {
    bytes32 public root;
    mapping(uint256 => uint256) public claimedXP;
    IRiftData iriftData;

    constructor(bytes32 _root, address rd) {
        root = _root;
        iriftData = IRiftData(rd);
    }

    function claimXP(uint256 lootId, uint256 xp, bytes32[] calldata proof) 
    external 
    {
        require(_verify(_leaf(lootId, xp), proof), "Invalid merkle proof");
        _awardXP(lootId, xp);
    }

    function claimXPMultiple(uint256[] calldata lootIds, uint256[] calldata xps, bytes32[][] calldata proofs)
    external
    {
        for (uint i=0; i < lootIds.length; i++) {
            require(_verify(_leaf(lootIds[i], xps[i]), proofs[i]), "Invalid merkle proof");
            _awardXP(lootIds[i], xps[i]);
        }
    }

    function _awardXP(uint256 lootId, uint256 xp) 
    internal 
    nonReentrant
    {
        uint256 xpAward = xp - claimedXP[lootId];
        require(xpAward > 0, "No XP to claim");
        claimedXP[lootId] = xp;
        iriftData.addXP(xpAward, lootId);
    }

    function _leaf(uint256 lootId, uint256 xp)
    internal pure returns (bytes32)
    {
        return keccak256(abi.encodePacked(lootId, xp));
    }

    function _verify(bytes32 leaf, bytes32[] memory proof)
    internal view returns (bool)
    {
        return MerkleProof.verify(proof, root, leaf);
    }

    function ownerUpdateRoot(bytes32 newRoot) 
    external onlyOwner 
    {
        root = newRoot;
    }
}