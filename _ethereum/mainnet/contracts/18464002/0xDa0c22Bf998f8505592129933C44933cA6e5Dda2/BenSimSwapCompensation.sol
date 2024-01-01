// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./MerkleProof.sol";
import "./Ownable.sol";

import "./BenCoinV2.sol";

/**
 * @title BenSimSwapCompensation
 * @author Ben Coin Collective
 * @notice This contract handles compensation for the simswap takeover of Ben Armstrong's Twitter (X) account.
 */
contract BenSimSwapCompensation is Ownable {
  using SafeERC20 for IERC20;

  event PreClaim(address user, uint256 amount, uint unlockTimestamp);
  event Claimed(address user, uint256 amount);

  error NotInMerkleTree();
  error AlreadyPreClaimed();
  error AlreadyClaimed();
  error HasNotPreClaimed();
  error UnlockTimeNotReached();
  error PreClaimDeadlineOver();
  error CannotRecoverBEN();
  error PreClaimWindowNotPassed();
  error ClaimWindowDeadlinePassed();
  error ClaimWindowNotPassed();

  struct ClaimInfo {
    uint preClaimUnlockTimestamp; // When the pre-claim locking period is over
    uint256 unlockAmount; // How much they can claim
    bool hasFullyClaimed; // Whether they have fully claimed
  }

  IERC20 public ben;
  uint40 public claimLockingPeriod;
  mapping(address => ClaimInfo) public claimInfo;
  uint public amountPreClaimed;
  bytes32 public merkleRoot;

  uint public immutable CLAIM_LOCKING_PERIOD;
  uint public immutable PRE_CLAIM_DEADLINE;
  uint public immutable CLAIMING_WINDOW_EXPIRY;

  /**
   * @notice Constructor to initialize the contract.
   * @param _ben The BEN token contract address.
   * @param _preClaimWindow The timespan for pre-claims (in seconds).
   * @param _claimLockingPeriod The time to wait before unlocking (in seconds).
   * @param _claimingWindow The timespan for which claiming can be done after the pre-claim deadline is finished (in seconds).
   * @param _merkleRoot The Merkle root of the claimable tree.
   */
  constructor(IERC20 _ben, uint _preClaimWindow, uint _claimLockingPeriod, uint _claimingWindow, bytes32 _merkleRoot) {
    ben = _ben;
    PRE_CLAIM_DEADLINE = block.timestamp + _preClaimWindow;
    CLAIM_LOCKING_PERIOD = _claimLockingPeriod;
    CLAIMING_WINDOW_EXPIRY = _claimingWindow;
    merkleRoot = _merkleRoot;
  }

  /**
   * @notice Checks if a user is in the claimable Merkle tree.
   * @param _proof The Merkle proof.
   * @param _user The user's address.
   * @param _amount The claimable amount.
   * @return canClaim True if the user can claim the specified amount.
   */
  function isInMerkleTree(
    bytes32[] calldata _proof,
    address _user,
    uint256 _amount
  ) public view returns (bool canClaim) {
    bytes32 leaf = keccak256(abi.encodePacked(_user, _amount));
    return MerkleProof.verify(_proof, merkleRoot, leaf);
  }

  /**
   * @notice Checks if a user has preclaimed.
   * @param _user The user's address.
   * @return True if the user has preclaimed.
   */
  function hasPreclaimed(address _user) public view returns (bool) {
    return claimInfo[_user].unlockAmount > 0;
  }

  /**
   * @notice Checks if a user has fully claimed their compensation.
   * @param _user The user's address.
   * @return True if the user has fully claimed.
   */
  function hasFullyClaimed(address _user) public view returns (bool) {
    return claimInfo[_user].hasFullyClaimed;
  }

  /**
   * @notice Allows users to preclaim their compensation.
   * @param _proof The Merkle proof.
   * @param _amount The preclaim amount.
   */
  function preClaim(bytes32[] calldata _proof, uint256 _amount) external {
    if (!isInMerkleTree(_proof, msg.sender, _amount)) {
      revert NotInMerkleTree();
    }

    if (PRE_CLAIM_DEADLINE <= block.timestamp) {
      revert PreClaimDeadlineOver();
    }

    if (hasPreclaimed(msg.sender)) {
      revert AlreadyPreClaimed();
    }

    claimInfo[msg.sender].unlockAmount = _amount;
    claimInfo[msg.sender].preClaimUnlockTimestamp = block.timestamp + CLAIM_LOCKING_PERIOD;

    amountPreClaimed += _amount;
    emit PreClaim(msg.sender, _amount, block.timestamp + CLAIM_LOCKING_PERIOD);
  }

  /**
   * @notice Allows users to claim their compensation.
   */
  function claim() external {
    if (!hasPreclaimed(msg.sender)) {
      revert HasNotPreClaimed();
    }

    if (hasFullyClaimed(msg.sender)) {
      revert AlreadyClaimed();
    }

    if (claimInfo[msg.sender].preClaimUnlockTimestamp > block.timestamp) {
      revert UnlockTimeNotReached();
    }

    if (claimInfo[msg.sender].preClaimUnlockTimestamp + CLAIMING_WINDOW_EXPIRY < block.timestamp) {
      revert ClaimWindowDeadlinePassed();
    }

    claimInfo[msg.sender].hasFullyClaimed = true;
    uint unlockedAmount = claimInfo[msg.sender].unlockAmount;
    ben.safeTransfer(msg.sender, unlockedAmount);
    emit Claimed(msg.sender, unlockedAmount);
  }

  /**
   * @notice Allows anyone to call this to recover unclaimed funds after the preclaim deadline has passed, sent to the owner
   */
  function recoverUnclaimedPreClaimWindowExpiredFunds() external {
    if (PRE_CLAIM_DEADLINE > block.timestamp) {
      revert PreClaimWindowNotPassed();
    }

    uint recoverAmount = ben.balanceOf(address(this)) - amountPreClaimed;
    ben.safeTransfer(owner(), recoverAmount);
  }

  /**
   * @notice Allows anyone to call this to recover unclaimed funds which weren't claimed during the claim window deadline, sent to the owner
   */
  function recoverUnclaimedClaimWindowExpiredFunds() external {
    if (PRE_CLAIM_DEADLINE + CLAIM_LOCKING_PERIOD + CLAIMING_WINDOW_EXPIRY > block.timestamp) {
      revert ClaimWindowNotPassed();
    }

    // Send it all back
    ben.safeTransfer(owner(), ben.balanceOf(address(this)));
  }

  /**
   * @notice Allows the owner to recover tokens sent to this contract (except BEN).
   * @param _token The token to recover.
   * @dev Only callable by the owner.
   */
  function recoverTokens(IERC20 _token) external onlyOwner {
    if (_token == ben) {
      revert CannotRecoverBEN();
    }
    _token.safeTransfer(msg.sender, _token.balanceOf(address(this)));
  }
}
