// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.6.11;

import "./IERC20.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";
import "./IMerkleDistributor.sol";

contract MerkleDistributor is IMerkleDistributor{
    address public immutable override token;
    bytes32 public immutable override merkleRoot;
    address public immutable treasury;
    uint256 public immutable expiry; // >0 if enabled

    // This is a packed array of booleans.
    mapping(uint256 => uint256) private claimedBitMap;

    constructor(address token_, bytes32 merkleRoot_, address treasury_, uint256 expiry_) public {
        token = token_;
        merkleRoot = merkleRoot_;
        treasury = treasury_;
        expiry = expiry_;
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
        require(!isClaimed(index), 'MerkleDistributor: Already claimed.');
        require(expiry == 0 || block.timestamp < expiry,'MerkleDistributor: Expired.');
        // Verify the merkle proof.
        bytes32 node = keccak256(abi.encodePacked(index, account, amount));
        require(MerkleProof.verify(merkleProof, merkleRoot, node), 'MerkleDistributor: Invalid proof.');

        // Mark it claimed and send the token.
        _setClaimed(index);
        require(IERC20(token).transfer(account, amount), 'MerkleDistributor: Transfer failed.');

        emit Claimed(index, account, amount);
    }

    function salvage() external {
        require(expiry > 0 && block.timestamp >= expiry,'MerkleDistributor: Not expired.');
        uint256 _remaining = IERC20(token).balanceOf(address(this));
        IERC20(token).transfer(treasury, _remaining);
    }
}
