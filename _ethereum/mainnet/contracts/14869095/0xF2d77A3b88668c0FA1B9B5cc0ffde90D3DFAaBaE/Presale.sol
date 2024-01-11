//SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./SafeERC20.sol";
import "./MerkleProof.sol";

/**
 * @dev Little 'm' mVP Presale contract
 *
 * Designed to capture the expected investor user flow (including vesting).
 */
contract Presale is Ownable {
    /// @dev Is the round open
    bool public isOpen = true;

    /// @dev Hard cap on round
    uint256 public immutable hardCap;

    /// @dev vesting cliff duration, kicks in after the token
    /// is created and set (ie, after setIssuedToken is called)
    uint256 public immutable vestingCliffDuration;

    /// @dev when the vesting starts
    uint256 public immutable vestingDuration;

    /// @dev what token are we accepting as part of the raise
    IERC20 public immutable raiseToken;

    /// @dev Where do funds raised get sent
    address public immutable daoMultisig;

    /// @dev merkle root that captures all valid invite codes
    bytes32 public immutable inviteCodesMerkleRoot;

    /// @dev Where do funds raised get sent
    /// TODO: discuss/decide if this should be a packed array bitMap for 
    ///       gas efficiency (may not matter if most presales have < 100 or
    ///       so participants). Needs some tests
    mapping(bytes => bool) public claimedInvites;

    /// @dev what token are we issueing as per vesting conditions
    /// not immutable as we expect to set this once we complete the presale
    IERC20 public issuedToken;

    /// @dev when the vesting starts
    uint256 public issuedTokenAtTimestamp;

    mapping(address => uint256) public allocation;
    uint256 public totalAllocated;

    mapping(address => uint256) public claimed;
    uint256 public totalClaimed;

    event Deposited(address account, uint256 amount);
    event Claimed(address account, uint256 amount);

    constructor(
        uint256 _hardCap,
        bytes32 _inviteCodesMerkleRoot,
        uint256 _vestingCliffDuration,
        uint256 _vestingDuration,
        IERC20 _raiseToken,
        address _daoMultisig
    ) {
        hardCap = _hardCap;
        inviteCodesMerkleRoot = _inviteCodesMerkleRoot;
        vestingCliffDuration = _vestingCliffDuration;
        vestingDuration = _vestingDuration;
        raiseToken = _raiseToken;
        daoMultisig = _daoMultisig;
    }

    function depositFor(address account, uint256 amount, bytes memory inviteCode, bytes32[] calldata merkleProof) external {
        require(account != address(0), "Presale: Address cannot be 0x0");
        require(isOpen, "Presale: Round closed");
        require(hardCap > totalAllocated, "Presale: Round closed, goal reached");
        require(!claimedInvites[inviteCode], "Presale: Invite code has been used");
        require(MerkleProof.verify(merkleProof, inviteCodesMerkleRoot, keccak256(inviteCode)), "Presale: Invalid invite code");

        uint256 remainingAllocation = hardCap - totalAllocated;
        if (remainingAllocation < amount) {
            amount = remainingAllocation;
        }

        allocation[account] += amount;
        totalAllocated += amount;
        claimedInvites[inviteCode] = true;

        SafeERC20.safeTransferFrom(raiseToken, msg.sender, daoMultisig, amount);
        emit Deposited(account, amount);
    }

    function calculateClaimable(address account) public view returns (uint256 share, uint256 amount)
    {
        if (address(issuedToken) == address(0)) {
            return (0,0);
        }

        if (totalAllocated == totalClaimed) {
            return (0,0);
        }

        uint256 vestingStartTimestamp = issuedTokenAtTimestamp + vestingCliffDuration;
        if (block.timestamp < vestingStartTimestamp) {
            return (0,0);
        }

        uint256 currentVestingDuration = block.timestamp - vestingStartTimestamp;
        if (currentVestingDuration > vestingDuration) {
            currentVestingDuration = vestingDuration;
        }

        share = ((allocation[account] * currentVestingDuration) / vestingDuration) - claimed[account];
        amount = share * issuedToken.balanceOf(address(this)) / (totalAllocated - totalClaimed);
    }

    function claimFor(address account) external {
        (uint256 share, uint256 claimable)  = calculateClaimable(account);

        claimed[account] += share;
        totalClaimed += share;
        
        SafeERC20.safeTransfer(issuedToken, account, claimable);
        emit Claimed(account, claimable);
    }

    /// @dev owner only. set issued token. Can only be called once
    /// and kicks of vesting
    function setIssuedToken(IERC20 _issuedToken) external onlyOwner {
        require(address(issuedToken) == address(0), "Presale: Issued token already sent");
        issuedToken = _issuedToken;
        issuedTokenAtTimestamp = block.timestamp;
    }

    /// @dev owner only. Close round
    function closeRound() external onlyOwner {
        isOpen = false;
    }
}