// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;

import "./IERC20.sol";
import "./MerkleProof.sol";
import "./Ownable.sol";

import "./IMerkleDistributor.sol";

contract AirdropMerkleDistributor is IMerkleDistributor, Ownable {
    address public immutable override token;
    address public immutable treasury;
    bytes32 public immutable override merkleRoot;

    // change to desired date
    uint256 public immutable claimPeriodEnds;

    // This is a packed array of booleans.
    mapping(uint256 => uint256) private claimedBitMap;

    constructor(
        address token_,
        bytes32 merkleRoot_,
        uint256 claimPeriodEnds_,
        address treasury_
    ) {
        token = token_;
        merkleRoot = merkleRoot_;
        claimPeriodEnds = claimPeriodEnds_;
        treasury = treasury_;
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
        claimedBitMap[claimedWordIndex] =
            claimedBitMap[claimedWordIndex] |
            (1 << claimedBitIndex);
    }

    function claim(
        uint256 index,
        address account,
        uint256 amount,
        bytes32[] calldata merkleProof
    ) external override {
        require(!isClaimed(index), "Already claimed.");

        // Verify the merkle proof.
        bytes32 node = keccak256(abi.encodePacked(index, account, amount));
        require(
            MerkleProof.verify(merkleProof, merkleRoot, node),
            "Invalid proof."
        );

        // Mark it claimed and send the token.
        _setClaimed(index);
        require(
            IERC20(token).transfer(account, amount * (10**18)),
            "Transfer failed."
        );

        emit Claimed(index, account, amount);
    }

    function sweep() public override onlyOwner {
        require(
            block.timestamp > claimPeriodEnds,
            "Claim period not yet ended"
        );
        require(
            IERC20(token).transfer(
                treasury,
                IERC20(token).balanceOf(address(this))
            ),
            "Transfer failed."
        );
    }
}
