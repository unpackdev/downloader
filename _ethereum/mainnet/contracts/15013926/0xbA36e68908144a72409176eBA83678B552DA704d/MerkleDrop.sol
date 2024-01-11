// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./LazyComics.sol";
import "./MerkleProof.sol";
import "./IMerkleDistributor.sol";
import "./Ownable.sol";
import "./Pausable.sol";

contract MerkleDrop is IMerkleDistributor, Ownable, Pausable{
    address public override token;
    uint256 public tokenId;
    bytes32 public override merkleRoot;

    // This is a packed array of booleans.
    mapping(uint256 => uint256) private claimedBitMap;

    constructor(bytes32 merkleRoot_) public {
        merkleRoot = merkleRoot_;
    }

    function pause() public onlyOwner {
        _pause();
    }
    function unpause() public onlyOwner {
        _unpause();
    }
    function setToken(address _token, uint256 _tokenId) public onlyOwner {
        token = _token;
        tokenId =  _tokenId;
    }

    function setMerkleRoot(bytes32 merkleRoot_) public onlyOwner {
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

    function claim(uint256 index, address account, uint256 amount, bytes32[] calldata merkleProof) external override whenNotPaused {
        require(!isClaimed(index), 'MerkleDistributor: Drop already claimed.');

        // Verify the merkle proof.
        bytes32 node = keccak256(abi.encodePacked(index, account, amount));
        require(MerkleProof.verify(merkleProof, merkleRoot, node), 'MerkleDistributor: Invalid proof.');

        // Mark it claimed and send the token.
        _setClaimed(index);
        require(LazyComics(token).mint(account, tokenId, amount, ""), 'MerkleDistributor: Transfer failed.');

        emit Claimed(index, account, amount);
    }

    function adminMint(address account, uint256 amount) external onlyOwner whenNotPaused {
        require(LazyComics(token).mint(account, tokenId, amount, ""), 'ERC1155: Mint Failed.');
    }
}
