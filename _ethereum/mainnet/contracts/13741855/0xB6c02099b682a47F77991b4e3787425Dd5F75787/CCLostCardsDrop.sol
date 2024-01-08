// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC1155.sol";
import "./MerkleProof.sol";
import "./Ownable.sol";
import "./ERC1155Holder.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";

contract CCLostCardsDrop is ERC1155Holder, Ownable, ReentrancyGuard {
    bytes32 public merkleRoot;
    address public token;
    uint256 public price;


    // starts turned off to prepare the drawings before going public
    bool isExecutionAllowed = false;

    // This event is triggered whenever a call to #claim succeeds.
    event Claimed(uint256 indexed index, address account, uint256 tokenId, uint256 amount);
    
    mapping(uint256 => uint256) public claimedBitMap;
    
    constructor(address token_, bytes32 merkleRoot_, uint256 price_) {
        require(price_ > 0, "Price must be greater than 0");
        token = token_;
        merkleRoot = merkleRoot_;
        price = price_;
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
        claimedBitMap[claimedWordIndex] = claimedBitMap[claimedWordIndex] | (1 << claimedBitIndex);
    }
    
    function claim(uint256 index, address account, uint256 tokenId, uint256 amount, bytes32[] calldata merkleProof) external payable nonReentrant {
        require(isExecutionAllowed);
        require(!isClaimed(index), "MerkleDrop: Token already claimed");
        require(msg.sender == account, "Only owner can claim");
        require(msg.value >= price); // ensure enough money paid for token

        // Verify the merkle proof.
        bytes32 node = keccak256(abi.encodePacked(index, account, tokenId, amount));
        require(
            MerkleProof.verify(merkleProof, merkleRoot, node),
            "MerkleDistributor: Invalid proof."
        );

        // Mark it claimed and send the token.
        _setClaimed(index);
        
        IERC1155(token).safeTransferFrom(address(this), account, tokenId, amount, new bytes(0));

        emit Claimed(index, account, tokenId, amount);
    }


    // Specify a merkle root hash to reuse the contract for multiple rounds
    function setMerkleRoot(bytes32 root) external onlyOwner {
        merkleRoot = root;
    }

    function setPrice(uint256 price_) external onlyOwner {
        price = price_;
    }

      // For owner to withdraw the remaining tokens
    function withdrawRemaining(uint256 tokenId) public onlyOwner {
        IERC1155(token).safeTransferFrom(
			address(this),
			msg.sender,
			tokenId,
			IERC1155(token).balanceOf(address(this), tokenId),
			new bytes(0)
		);
    }

    function withdraw() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function flipSwitchTo(bool state) public onlyOwner {
        isExecutionAllowed = state;
    }
}