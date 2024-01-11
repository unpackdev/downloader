// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./IERC20Metadata.sol";
import "./MerkleProof.sol";
import "./IMerkleProofUnoClaim.sol";
import "./TransferHelper.sol";

contract MerkleProofUnoClaim is IMerkleProofUnoClaim, Ownable, ReentrancyGuard {
    address public immutable claimToken;
    uint128 public constant cohortStartTime = 1633046401;
    bytes32 public merkleRoot;

    mapping(address => UserInfo) public userInfo;

    constructor(address _token) {
        claimToken = _token;
    }

    function airdropUNO(
        uint128 _index,
        address _account,
        uint128 _amount,
        bytes32[] calldata _merkleProof
    ) external override nonReentrant {
        require(msg.sender == _account, "UnoRe: No msg sender.");
        // Verify the merkle proof.
        bytes32 node = keccak256(abi.encodePacked(uint256(_index), _account, uint256(_amount)));
        require(MerkleProof.verify(_merkleProof, merkleRoot, node), "UnoRe: Invalid proof.");
        uint128 lastClaimTime = userInfo[_account].lastClaimTime;
        require(lastClaimTime < cohortStartTime + 365 days, "UnoRe: Last claim time over");
        require(block.timestamp >= cohortStartTime, "UnoRe: Cohort not started yet");
        require(block.timestamp > lastClaimTime, "UnoRe: Too short time diff ");
        uint128 diffTime = lastClaimTime > 0
            ? uint128(block.timestamp) - lastClaimTime
            : uint128(block.timestamp) - cohortStartTime;
        if (diffTime > 365 days) {
            diffTime = 365 days;
        }
        uint128 amountForClaim = (_amount * diffTime) / 365 days;
        require(userInfo[_account].claimedAmount + amountForClaim <= _amount, "UnoRe: Claimed amount overflow");
        TransferHelper.safeTransfer(claimToken, _account, amountForClaim);

        // Update claimed amount.
        userInfo[_account].claimedAmount += amountForClaim;
        userInfo[_account].lastClaimTime = uint128(block.timestamp);

        emit LogAirdropUNO(_index, _account, _amount, amountForClaim);
    }

    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner nonReentrant {
        require(_merkleRoot != bytes32(0), "UnoRe: Zero merkleRoot bytes.");
        merkleRoot = _merkleRoot;
        emit LogSetMerkleRoot(address(this), _merkleRoot);
    }

    function emergencyWithdraw(
        address _currency,
        address _to,
        uint256 _amount
    ) external onlyOwner {
        require(_to != address(0), "UnoRe: zero address reward");
        if (_currency == address(0)) {
            if (address(this).balance >= _amount) {
                TransferHelper.safeTransferETH(_to, _amount);
                emit LogEmergencyWithdraw(address(this), _currency, _to, _amount);
            } else {
                if (address(this).balance > 0) {
                    uint256 withdrawAmount = address(this).balance;
                    TransferHelper.safeTransferETH(_to, withdrawAmount);
                    emit LogEmergencyWithdraw(address(this), _currency, _to, withdrawAmount);
                }
            }
        } else {
            if (IERC20Metadata(_currency).balanceOf(address(this)) >= _amount) {
                TransferHelper.safeTransfer(_currency, _to, _amount);
                emit LogEmergencyWithdraw(address(this), _currency, _to, _amount);
            } else {
                if (IERC20Metadata(_currency).balanceOf(address(this)) > 0) {
                    uint256 withdrawAmount = IERC20Metadata(_currency).balanceOf(address(this));
                    TransferHelper.safeTransfer(_currency, _to, withdrawAmount);
                    emit LogEmergencyWithdraw(address(this), _currency, _to, withdrawAmount);
                }
            }
        }
    }
}
