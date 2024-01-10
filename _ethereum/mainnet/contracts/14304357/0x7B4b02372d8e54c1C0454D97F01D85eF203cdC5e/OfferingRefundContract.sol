// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./VirtueToken.sol";
import "./Address.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";
import "./Strings.sol";

/**
  @notice OfferingRefundContract is an airdrop contract which allows authenticated users to claim a
    portion of the contract's Ethereum based on how much they overpaid compared to the last price
    of the dutch auction. All of the calculations on how much ETH to refund to which users are
    calculated off-chain and authenticated through the Merkle tree.
*/
contract OfferingRefundContract is Ownable {
  // merkleRoot is the value of the root of the Merkle Tree used for authenticating airdrop claims.
  bytes32 public merkleRoot;

  // alreadyClaimed stores whether an address has already claimed its eligible refund.
  mapping(address => bool) public alreadyClaimed;

  constructor() {}

  /**
    @notice receive is implemented to allow this contract to receive ETH from IdolMintContract.
      Any ETH sent to this contract can then be withdrawn by addresses eligible for refund.
  */
  receive() external payable {}

  /**
    @notice setMerkleRoot is used to set the root of the Merkle Tree that we will use to
      authenticate which users are eligible to withdraw refunds from this contract.
  */
  function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
    merkleRoot = _merkleRoot;
  }

  /**
    @notice claimRefund will claim the ETH refund that an address is eligible to claim. The caller
      must pass the exact amount of ETH that the address is eligible to claim.
    @param _to The address to claim refund for.
    @param _refundAmount The amount of ETH refund to claim.
    @param _merkleProof The merkle proof used to authenticate the transaction against the Merkle
      root.
  */
  function claimRefund(address _to, uint _refundAmount, bytes32[] calldata _merkleProof) external {
    require(!alreadyClaimed[_to], "Refund has already been claimed for this address");

    // Verify against the Merkle tree that the transaction is authenticated for the user.
    bytes32 leaf = keccak256(abi.encodePacked(_to, _refundAmount));
    require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), "Failed to authenticate with merkle tree");

    alreadyClaimed[_to] = true;

    Address.sendValue(payable(_to), _refundAmount);
  }
}
