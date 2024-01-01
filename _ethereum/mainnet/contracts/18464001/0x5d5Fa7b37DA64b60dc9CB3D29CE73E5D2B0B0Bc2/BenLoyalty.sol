// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./MerkleProof.sol";
import "./Ownable.sol";

import "./BenCoinV2.sol";

/**
 * @title BenLoyalty
 * @author Ben Coin Collective
 * @dev This contract handles loyalty from BEN holders, gives BEN rewards
 */
contract BenLoyalty is Ownable {
  using SafeERC20 for IERC20;

  event Claimed(address user, uint256 amount);

  error NotInMerkleTree();
  error AlreadyClaimed();
  error UnlockTimeNotReached();
  error CannotRecoverBEN();

  bytes32 public merkleRoot;

  IERC20 public ben;
  mapping(address => bool) private claimed;

  uint public immutable CLAIM_WAIT_TIMESPAN;
  uint public immutable PRE_CLAIM_DEADLINE;

  /**
   * @dev Constructor to initialize the contract.
   * @param _ben The BEN token contract address.
   * @param _merkleRoot The Merkle root of the claimable tree.
   */
  constructor(IERC20 _ben, bytes32 _merkleRoot) {
    ben = _ben;
    merkleRoot = _merkleRoot;
  }

  /**
   * @dev Checks if a user is in the claimable Merkle tree.
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
   * @dev Checks if a user has fully claimed their loyalty reward.
   * @param _user The user's address.
   * @return True if the user has fully claimed.
   */
  function hasFullyClaimed(address _user) public view returns (bool) {
    return claimed[_user];
  }

  /**
   * @dev Allows users to claim their loyalty reward.
   * @param _proof The Merkle proof.
   * @param _amount The reward amount.
   */
  function claim(bytes32[] calldata _proof, uint256 _amount) external {
    if (!isInMerkleTree(_proof, msg.sender, _amount)) {
      revert NotInMerkleTree();
    }

    if (hasFullyClaimed(msg.sender)) {
      revert AlreadyClaimed();
    }

    claimed[msg.sender] = true;
    ben.safeTransfer(msg.sender, _amount);
    emit Claimed(msg.sender, _amount);
  }

  /**
   * @notice Recovers any tokens sent to this contract (except BEN).
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
