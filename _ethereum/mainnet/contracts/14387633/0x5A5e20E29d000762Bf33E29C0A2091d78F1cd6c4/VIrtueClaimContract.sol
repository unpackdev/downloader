// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./Address.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";

/**
  @notice VirtueClaimContract is an airdrop contract for claiming VIRTUE.
*/
contract VirtueClaimContract is Ownable {
  // merkleRoot is the value of the root of the Merkle Tree used for authenticating airdrop claims.
  bytes32 public merkleRootVirtue;
  Transferable virtueToken;

  // alreadyClaimed stores whether an address has already claimed its eligible refund.
  mapping(address => bool) public alreadyClaimedVirtue;

  constructor(bytes32 _merkleRootVirtue, address _virtueTokenAddress) {
    merkleRootVirtue = _merkleRootVirtue;
    virtueToken = Transferable(_virtueTokenAddress);
  }

  /**
    @notice withdrawVirtue allows the owner to withdraw VIRTUE from the contract.
  */
  function withdrawVirtue(uint _amount) external onlyOwner {
    virtueToken.transfer(msg.sender, _amount);
  }

  /**
    @notice setMerkleRootVirtue is used to set the root of the Merkle Tree that we will use to
      authenticate which users are eligible to withdraw refunds from this contract.
  */
  function setMerkleRootVirtue(bytes32 _merkleRootVirtue) external onlyOwner {
    merkleRootVirtue = _merkleRootVirtue;
  }

  /**
    @notice claimVirtueRefund will claim the VIRTUE refund that an address is eligible to claim. The caller
      must pass the exact amount of VIRTUE that the address is eligible to claim.
    @param _to The address to claim refund for.
    @param _refundAmount The amount of VIRTUE refund to claim.
    @param _merkleProof The merkle proof used to authenticate the transaction against the Merkle
      root.
  */
  function claimVirtueRefund(address _to, uint _refundAmount, bytes32[] calldata _merkleProof) external {
    require(!alreadyClaimedVirtue[_to], "Refund has already been claimed for this address");

    // Verify against the Merkle tree that the transaction is authenticated for the user.
    bytes32 leaf = keccak256(abi.encodePacked(_to, _refundAmount));
    require(MerkleProof.verify(_merkleProof, merkleRootVirtue, leaf), "Failed to authenticate with merkle tree");

    alreadyClaimedVirtue[_to] = true;

    virtueToken.transfer(msg.sender, _refundAmount);
  }
}

interface Transferable {
    function transfer(address to, uint256 amount) external returns (bool);
}
