// SPDX-License-Identifier: MIT
pragma solidity =0.6.11;

import "./IERC20.sol";
import "./MerkleProof.sol";
import "./IMerkleDistributor.sol";

contract MerkleDistributor is IMerkleDistributor {

    address public immutable override token;
    bytes32 public override merkleRoot;

    address public owner;
    address public treasury;
    uint256 public claimRestTimeFrom;

    // This is a packed array of booleans.
    mapping(uint256 => uint256) private claimedBitMap;

    constructor(address token_, bytes32 merkleRoot_, address treasury_) public {
        token = token_;
        merkleRoot = merkleRoot_;
        owner = msg.sender;
        treasury = treasury_;
        claimRestTimeFrom = block.timestamp + 3 weeks;
    }

    function setOwner (address newOwner) public {
        require (owner == msg.sender, "only owner can set root");
        owner = newOwner;
    }

    function setroot (bytes32 newroot) public {
        require (owner == msg.sender, "only owner can set root");
        merkleRoot = newroot;
    }

    function contractTokenBalance() public view returns (uint) {
        return IERC20(token).balanceOf(address(this));
    }

    function claimRestOfTokensToTreasury() public returns (bool) {
        require(msg.sender == owner, "Only owner");
        require(block.timestamp >= claimRestTimeFrom, "Not yet claimable");
        require(IERC20(token).balanceOf(address(this)) >= 0, "No balance");
        require(IERC20(token).transfer(treasury, IERC20(token).balanceOf(address(this))));
        return true;
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

        // Verify the merkle proof.
        bytes32 node = keccak256(abi.encodePacked(index, account, amount));
        require(MerkleProof.verify(merkleProof, merkleRoot, node), 'MerkleDistributor: Invalid proof.');

        // Mark it claimed and send the token.
        _setClaimed(index);
        require(IERC20(token).transfer(account, amount), 'MerkleDistributor: Transfer failed.');

        emit Claimed(index, account, amount);
    }
}