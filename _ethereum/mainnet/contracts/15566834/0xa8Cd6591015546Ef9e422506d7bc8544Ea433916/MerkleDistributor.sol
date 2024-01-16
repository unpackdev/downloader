// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.9;

import "./IERC20.sol";
import "./MerkleProof.sol";
import "./Ownable.sol";

contract MerkleDistributor is Ownable {
    address public token;
    bytes32 public merkleRoot;

    // This is a packed array of booleans.
    mapping(address => bool) private claimedMap;

    // This event is triggered whenever a call to #claim succeeds.
    event Claimed(uint256 index, address account, uint256 amount);

    constructor() { }

    function setDistributeInfo(address token_, bytes32 merkleRoot_) public onlyOwner {
        token = token_;
        merkleRoot = merkleRoot_;
    }

    function isClaimed(address account) public view returns (bool) {
        return claimedMap[account];
    }

    function _setClaimed(address account) private {
        claimedMap[account] = true;
    }

    function claim(uint256 index, address account, uint256 amount, bytes32[] calldata merkleProof) external {
        require(!isClaimed(account), 'MerkleDistributor: Drop already claimed.');

        // Verify the merkle proof.
        bytes32 node = keccak256(abi.encodePacked(index, account, amount));
        require(MerkleProof.verify(merkleProof, merkleRoot, node), 'MerkleDistributor: Invalid proof.');

        // Mark it claimed and send the token.
        _setClaimed(account);
        require(IERC20(token).transfer(account, amount), 'MerkleDistributor: Transfer failed.');

        emit Claimed(index, account, amount);
    }
}
