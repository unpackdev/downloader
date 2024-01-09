// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.10;

interface IERC721MerkleDrop {
    event UpdateClaimDeadline(
        uint256 oldClaimDeadline,
        uint256 newClaimDeadline
    );

    event Withdrawal(address recipient, uint256 amount, uint256 fee);

    function initialize(
        address owner_,
        bool paused_,
        bytes32 merkleRoot_,
        uint256 claimDeadline_,
        address recipient_,
        address token_,
        address tokenOwner_,
        uint256 startTokenId_,
        uint256 endTokenId_
    ) external;

    function claim(
        address account,
        uint256 allocation,
        uint256 price,
        uint256 index,
        bytes32[] calldata merkleProof
    ) external payable;

    function setClaimDeadline(uint256 claimDeadline_) external;

    function pause() external;

    function unpause() external;

    function cancel(uint16 feePercentage_) external;

    function claimedTokens() external view returns (uint256);

    function withdraw(uint16 feePercentage_) external;
}
