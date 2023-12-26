// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./SafeERC20.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";

contract WrabDistributor is Ownable {
    using SafeERC20 for IERC20;

    address public tokenAddress;
    bool public isActive;
    bytes32 public merkleRoot;

    mapping(address => uint256) public userClaimedTokens;

    event Claimed(address account, uint256 amount);

    constructor(address tokenAddress_) {
        tokenAddress = tokenAddress_;
    }

    function claim(uint256 amount, bytes32[] calldata merkleProof)
        public
        virtual
    {
        require(
            MerkleProof.verify(
                merkleProof,
                merkleRoot,
                keccak256(abi.encodePacked(msg.sender, amount))
            ),
            "Invalid merkle proof."
        );
        require(isActive, "Claim is not active.");

        uint256 claimedAmount = userClaimedTokens[msg.sender];
        uint256 amountToClaim = amount - claimedAmount;
        require(amountToClaim > 0, "No tokens to claim");

        userClaimedTokens[msg.sender] = amountToClaim + claimedAmount;
        IERC20(tokenAddress).safeTransfer(msg.sender, amountToClaim * 10**18);

        emit Claimed(msg.sender, amountToClaim);
    }

    // Owner only methods
    function setMerkleRoot(bytes32 merkleRoot_) external onlyOwner {
        merkleRoot = merkleRoot_;
    }

    function setIsActive(bool isActive_) external onlyOwner {
        isActive = isActive_;
    }

    /**
     * @dev Withdraw excess tokens left in the contract
     */
    function withdraw(uint256 amount) external onlyOwner {
        IERC20(tokenAddress).safeTransfer(msg.sender, amount * 10**18);
    }
}
