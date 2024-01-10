pragma solidity 0.8.13;

/***
 *@title DegenesisAirdrop
 *@author InsureDAO
 * SPDX-License-Identifier: MIT
 * 
 *@notice modified from https://github.com/Uniswap/merkle-distributor
 *
 *@dev added features
 * - ownership to salvage the unclaimed token
 * - claimable duration
 */

import "./IERC20.sol";
import "./MerkleProof.sol";
import "./IMerkleDistributor.sol";
import "./IOwnership.sol";


contract DegenesisAirdrop is IMerkleDistributor {
    address public immutable override token;
    bytes32 public immutable override merkleRoot;

    IOwnership public immutable ownership;
    uint256 public constant START = 1648684800; //2022-03-31 00:00:00 UTC
    uint256 public constant CLAIM_DURATION = 86400 * 365 / 2;


    // This is a packed array of booleans.
    mapping(uint256 => uint256) private claimedBitMap;

    modifier onlyOwner() {
        require(
            ownership.owner() == msg.sender,
            "Caller is not allowed to operate"
        );
        _;
    }

    constructor(address token_, bytes32 merkleRoot_, address ownership_){
        token = token_;
        merkleRoot = merkleRoot_;
        ownership = IOwnership(ownership_);
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

    function claim(uint256 index, address account, uint256 amount, bytes32[] calldata merkleProof) external override {
        require(!isClaimed(index), 'MerkleDistributor: Drop already claimed.');
        require(block.timestamp <= START + CLAIM_DURATION, "TOO LATE");

        // Verify the merkle proof.
        bytes32 node = keccak256(abi.encodePacked(index, account, amount));
        require(MerkleProof.verify(merkleProof, merkleRoot, node), 'MerkleDistributor: Invalid proof.');

        // Mark it claimed and send the token.
        _setClaimed(index);
        require(IERC20(token).transfer(account, amount), 'MerkleDistributor: Transfer failed.');

        emit Claimed(index, account, amount);
    }

    function salvage() external onlyOwner{
        /**
        *@notice owner can rug-pull the unclaimed airdrop and pooled tax
        *@dev transfer to the community treasure at the end.
        */
        require(block.timestamp > START + CLAIM_DURATION, "Still in Claimable Period");

        uint256 _amount = IERC20(token).balanceOf(address(this));
        IERC20(token).transfer(msg.sender, _amount);
    }
}