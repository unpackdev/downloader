// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.6.11;

import "./IERC20.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";
import "./IMerkleDistributor.sol";

contract MerkleDistributor is Ownable, IMerkleDistributor {
    address public override token;
    bytes32 public override merkleRoot;

    uint256 private mappingVersion;
    mapping(bytes32 => bool) private claimedMap;

    // This is a packed array of booleans.
    mapping(uint256 => uint256) private claimedBitMap;

    function setToken(address token_) external onlyOwner {
        token = token_;
    }

    function setMerkleRoot(bytes32 merkleRoot_) external onlyOwner {
        merkleRoot = merkleRoot_;
        mappingVersion++;
    }

    function isClaimed(uint256 index) public view override returns (bool) {
        bytes32 key = keccak256(abi.encodePacked(mappingVersion, index));
        return claimedMap[key];
    }

    function _setClaimed(uint256 index) private {
        bytes32 key = keccak256(abi.encodePacked(mappingVersion, index));
        claimedMap[key] = true;
    }

    function claim(
        uint256 index,
        address account,
        uint256 amount,
        bytes32[] calldata merkleProof
    ) external override {
        require(!isClaimed(index), 'MerkleDistributor: Drop already claimed.');

        // Verify the merkle proof.
        bytes32 node = keccak256(abi.encodePacked(index, account, amount));
        require(MerkleProof.verify(merkleProof, merkleRoot, node), 'MerkleDistributor: Invalid proof.');

        // Mark it claimed and send the token.
        _setClaimed(index);
        require(IERC20(token).transfer(account, amount), 'MerkleDistributor: Transfer failed.');

        emit Claimed(index, account, amount);
    }

    function recoverToken(address token_, address receiver_) external onlyOwner {
        require(
            IERC20(token).transfer(receiver_, IERC20(token_).balanceOf(address(this))),
            'MerkleDistributor: Transfer failed.'
        );
    }
}
