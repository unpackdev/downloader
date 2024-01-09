// SPDX-License-Identifier: MIT
pragma solidity =0.6.11;

import "./MerkleProof.sol";
import "./IFoxDaoDistributor.sol";
import "./IFoxDaoToken.sol";

contract FoxDaoDistributor is IFoxDaoDistributor {

    address public immutable override token;
    bytes32 public immutable override merkleRoot;

    mapping(uint256 => uint256) private claimedBitMap;

    constructor(address token_, bytes32 merkleRoot_) public {
        token = token_;
        merkleRoot = merkleRoot_;
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
        require(!isClaimed(index), 'FoxDaoDistributor: Drop already claimed.');

        bytes32 node = keccak256(abi.encodePacked(index, account, amount));
        require(MerkleProof.verify(merkleProof, merkleRoot, node), 'FoxDaoDistributor: Invalid proof.');

        _setClaimed(index);
        IFoxDaoToken(token).mint(account, amount);

        emit Claimed(index, account, amount);
    }
}
