// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "MerkleProof.sol";
import "IERC20.sol";
import "Ownable.sol";

contract MerkleDistributor is Ownable {
    address public FRZtoken;
    bytes32 public immutable merkleRoot;
    bool private isInitialized = false;
    uint256 public immutable selfDestructDate;

    // This is a packed array of booleans.
    mapping(uint256 => uint256) private claimedBitMap;

    event Claimed(uint256 index, address indexed account, uint256 amount);

    constructor(bytes32 merkleRoot_) {
        merkleRoot = merkleRoot_;
        selfDestructDate = block.timestamp + (183 * 86400);
    }

    function initialize(address _token) external onlyOwner {
        require(isInitialized == false, "Contract already initialize");
        isInitialized = true;
        FRZtoken = _token;
    }

    function isClaimed(uint256 index) public view returns (bool) {
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
    ) external {
        require(isInitialized == true);
        require(!isClaimed(index), "MerkleDistributor: Drop already claimed.");

        // Verify the merkle proof.
        bytes32 node = keccak256(abi.encodePacked(index, account, amount));
        require(
            MerkleProof.verify(merkleProof, merkleRoot, node),
            "MerkleDistributor: Invalid proof."
        );

        // Mark it claimed and send the token.
        _setClaimed(index);
        require(
            IERC20(FRZtoken).transfer(account, amount),
            "MerkleDistributor: Transfer failed."
        );

        emit Claimed(index, account, amount);
    }

    /// @dev after 6 months owner can transfer remaining token and destruct the contract
    function transferAndDestruct() external onlyOwner {
        require(block.timestamp > selfDestructDate, "Too soon to do that");
        address _owner = owner();
        uint256 remainingToken = IERC20(FRZtoken).balanceOf(address(this));
        IERC20(FRZtoken).transfer(_owner, remainingToken);
        selfdestruct(payable(_owner));
    }
}
