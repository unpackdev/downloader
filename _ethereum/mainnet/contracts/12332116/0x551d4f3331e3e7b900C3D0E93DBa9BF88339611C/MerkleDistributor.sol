// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.6.11;

import "./IERC20.sol";
import "./MerkleProof.sol";
import "./IMerkleDistributor.sol";

contract MerkleDistributor is IMerkleDistributor {
    address public immutable override token;
    bytes32 public immutable override merkleRoot;
    uint256 public immutable override expirationBlock;
    address public immutable override expirationRedeemAddress;

    // This is a packed array of booleans.
    mapping(uint256 => uint256) private claimedBitMap;

    constructor(address token_, bytes32 merkleRoot_, uint256 expirationBlock_, address expirationRedeemAddress_ ) public {
        token = token_;
        merkleRoot = merkleRoot_;
        require(expirationBlock_ > block.number, "expiration block already passed");
        expirationBlock = expirationBlock_;
        expirationRedeemAddress = expirationRedeemAddress_;
    }

    function isExpired() public view override returns (bool) {
        return block.number > expirationBlock;
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
        require(!isExpired(), 'MerkleDistributor: already expired.');

        // Verify the merkle proof.
        bytes32 node = keccak256(abi.encodePacked(index, account, amount));
        require(MerkleProof.verify(merkleProof, merkleRoot, node), 'MerkleDistributor: Invalid proof.');

        // Mark it claimed and send the token.
        _setClaimed(index);
        require(IERC20(token).transfer(account, amount), 'MerkleDistributor: Transfer failed.');

        emit Claimed(index, account, amount);
    }

    function redeemExpiredTokens() external override {
        require(isExpired(), 'MerkleDistributor: can\'t redeem: not expired.');
        uint amount = IERC20(token).balanceOf(address(this));
        require(amount > 0, 'MerkleDistributor: nothing to redeem.');
        require(IERC20(token).transfer(expirationRedeemAddress, amount), 'MerkleDistributor: redeem failed.');

        emit RedeemExpiredTokens(expirationRedeemAddress, amount);
    }
}
