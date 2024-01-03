// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "./IERC721.sol";
import "./IERC20.sol";
import "./MerkleProof.sol";
import "./Ownable.sol";
import "./SafeERC20.sol";

contract ErcClaimWithNft is Ownable {
    using SafeERC20 for IERC20;

    bytes32 public merkleRoot;
    IERC721 public immutable nft;
    IERC20 public immutable token;

    mapping(uint256 => uint256) public totalClaimed;

    event Claimed(address indexed account, uint256 amount);
    event MerkleRootUpdated(bytes32 merkleRoot);

    error Unauthorised();
    error InvalidProof();
    error InvalidAmount();
    error InvalidArrayLength();

    constructor(IERC721 nft_, IERC20 token_) {
        nft = nft_;
        token = token_;
    }

    function claim(
        uint256 tokenId,
        uint256 amount,
        bytes32[] calldata merkleProof
    ) private view returns (uint256) {
        bytes32 node = keccak256(abi.encodePacked(tokenId, amount));

        if (!MerkleProof.verify(merkleProof, merkleRoot, node)) {
            revert InvalidProof();
        }

        if (nft.ownerOf(tokenId) != msg.sender) {
            revert Unauthorised();
        }

        // you can submit same proof multiple times, but you can only claim once as it will
        // be zero for subsequent claims
        uint256 amountToClaim = amount - totalClaimed[tokenId];

        if (amountToClaim == 0) {
            revert InvalidAmount();
        }

        return amountToClaim;
    }

    /// @notice Claim tokens for a multiple NFTs
    /// @param tokenIds The token IDs to claim for
    /// @param amounts The total cumualtive amounts for each token ID
    /// @param merkleProofs The merkle proofs for each token ID / amount pair
    function claimMultiple(
        uint256[] calldata tokenIds,
        uint256[] calldata amounts,
        bytes32[][] calldata merkleProofs
    ) external {
        if (
            tokenIds.length != amounts.length ||
            tokenIds.length != merkleProofs.length
        ) {
            revert InvalidArrayLength();
        }

        uint256 amount;

        for (uint256 i; i < tokenIds.length; i++) {
            amount += claim(tokenIds[i], amounts[i], merkleProofs[i]);
            totalClaimed[tokenIds[i]] = amounts[i];
        }

        token.safeTransfer(msg.sender, amount);

        emit Claimed(msg.sender, amount);
    }

    function setMerkleRoot(bytes32 merkleRoot_) external onlyOwner {
        merkleRoot = merkleRoot_;
        emit MerkleRootUpdated(merkleRoot_);
    }

    function withdraw(IERC20 _token, uint256 _amount) external onlyOwner {
        _token.safeTransfer(msg.sender, _amount);
    }
}
