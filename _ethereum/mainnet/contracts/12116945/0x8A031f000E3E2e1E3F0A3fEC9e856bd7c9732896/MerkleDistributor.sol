// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.3;

import "./MerkleProof.sol";
import "./IMerkleDistributor.sol";
import "./IERC1155.sol";
import "./IERC1155TokenReceiver.sol";

contract MerkleDistributor is IMerkleDistributor, IERC1155TokenReceiver {
    address public immutable override nftAddress;
    bytes32 public immutable override merkleRoot;
    address public immutable owner;
    mapping(uint256 => uint256) private claimedBitMap;

    constructor(address nftAddress_, bytes32 merkleRoot_) {
        nftAddress = nftAddress_;
        merkleRoot = merkleRoot_;
        owner = msg.sender;
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
        bytes32 node = keccak256(abi.encodePacked(index, account, amount));
        require(MerkleProof.verify(merkleProof, merkleRoot, node), 'MerkleDistributor: Invalid proof.');
        _setClaimed(index);
        IERC1155(nftAddress).safeTransferFrom(address(this), account, 1, 1, "");
        emit Claimed(index, account, amount);
    }

    function collectDustTo(uint256 _amount, address _to) public {
        require(msg.sender == owner, "not allowed");
        IERC1155(nftAddress).safeTransferFrom(address(this), _to, 1, _amount, "");
    }

    function onERC1155Received(address, address, uint256, uint256, bytes calldata) external pure override returns(bytes4) {
        return 0xf23a6e61;
    }

    function onERC1155BatchReceived(address, address, uint256[] calldata, uint256[] calldata, bytes calldata) external pure override returns(bytes4) {
        return 0xbc197c81;
    }
}
