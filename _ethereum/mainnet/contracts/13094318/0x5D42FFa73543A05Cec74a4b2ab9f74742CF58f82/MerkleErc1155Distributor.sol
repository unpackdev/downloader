// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.6.11;

import "./IERC20.sol";
import "./IERC1155.sol";
import "./ERC1155Holder.sol";
import "./MerkleProof.sol";
import "./Ownable.sol";
import "./IMerkleErc1155Distributor.sol";

contract MerkleErc1155Distributor is IMerkleErc1155Distributor, Ownable, ERC1155Holder {
    uint256 private constant TIMELOCK_DURATION = 30 days;
    uint256 public timelock;
    uint256 public creationTime;

    modifier notLocked() {
        require(timelock <= block.timestamp, "Function is timelocked");
        _;
    }

    address public immutable override token;
    bytes32 public immutable override merkleRoot;

    // This is a packed array of booleans.
    mapping(uint256 => uint256) private claimedBitMap;

    constructor(address token_, bytes32 merkleRoot_) public {
        token = token_;
        merkleRoot = merkleRoot_;
        creationTime = block.timestamp;
        timelock = creationTime + TIMELOCK_DURATION;
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

    function claim(
        uint256 index,
        address account,
        uint256 tokenId,
        uint256 amount,
        bytes32[] calldata merkleProof
    ) external override {
        require(!isClaimed(index), "MerkleDistributor: Drop already claimed.");
        require(account == msg.sender, "MerkleDistributor: sender is not claimant.");

        // Verify the merkle proof.
        bytes32 node = keccak256(abi.encodePacked(index, account, tokenId, amount));
        require(MerkleProof.verify(merkleProof, merkleRoot, node), "MerkleDistributor: Invalid proof.");

        // Mark it claimed and send the token.
        _setClaimed(index);
        IERC1155(token).safeTransferFrom(address(this), account, tokenId, amount, "");        

        emit Claimed(index, account, tokenId);
    }

    function remainingClaimTime() public view returns (uint256) {
        return timelock >= block.timestamp ? timelock - block.timestamp : 0;
    }

    function timelockDuration() public view returns (uint256) {
        return timelock;
    }

    function rescueTokens(address tokenAddress) public onlyOwner {
        require(tokenAddress != token, "No cheating");

        uint256 balance = IERC20(tokenAddress).balanceOf(address(this));
        require(IERC20(tokenAddress).transfer(msg.sender, balance), "MerkleDistributor: Transfer failed.");
    }
  
    function rescueErc1155Tokens(uint256 tokenId, uint256 amount) public onlyOwner notLocked {
        IERC1155(token).safeTransferFrom(address(this), msg.sender, tokenId, amount, "");
    }

    function selfDestruct() public onlyOwner notLocked {
        selfdestruct(msg.sender);
    }
}
