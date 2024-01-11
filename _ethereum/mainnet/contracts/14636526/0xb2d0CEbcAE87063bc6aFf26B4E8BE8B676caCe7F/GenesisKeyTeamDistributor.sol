//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./IGenesisKeyTeamDistributor.sol";
import "./IERC20.sol";
import "./MerkleProof.sol";

// From: https://github.com/Uniswap/merkle-distributor/blob/master/contracts/MerkleDistributor.sol

interface IGkTeam {
    function teamClaim(address recipient) external returns (bool);
}

contract GenesisKeyTeamDistributor is IGenesisKeyTeamDistributor {
    address public immutable override gkTeam;
    bytes32 public override merkleRoot;
    address public override owner;

    // This is a packed array of booleans.
    mapping(uint256 => uint256) private claimedBitMap;

    constructor(address gkTeam_) {
        gkTeam = gkTeam_;
        owner = msg.sender;
    }

    function transferOwnership(address _newOwner) external {
        require(msg.sender == owner, "!auth");
        owner = _newOwner;
    }

    function changeMerkleRoot(bytes32 _newRoot) external {
        require(msg.sender == owner, "!auth");
        merkleRoot = _newRoot;
    }

    function isClaimed(uint256 index) public view override returns (bool) {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        uint256 claimedWord = claimedBitMap[claimedWordIndex];
        uint256 mask = (1 << claimedBitIndex);
        return claimedWord & mask == mask;
    }

    function _setClaimed(uint256 index) private {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        claimedBitMap[claimedWordIndex] = claimedBitMap[claimedWordIndex] | (1 << claimedBitIndex);
    }

    function claim(
        uint256 index,
        address account,
        uint256 tokenId,
        bytes32[] calldata merkleProof
    ) external payable override {
        require(msg.sender == account);
        require(!isClaimed(index), "GKTeamDistributor: Drop already claimed.");

        // Verify the merkle proof.
        bytes32 node = keccak256(abi.encodePacked(index, account, tokenId));
        require(MerkleProof.verify(merkleProof, merkleRoot, node), "GKTeamDistributor: Invalid proof.");

        // Mark it claimed and send the token.
        _setClaimed(index);
        require(IGkTeam(gkTeam).teamClaim(account), "GKTeamDistributor: No team keys available");

        emit Claimed(index, account, tokenId);
    }
}
