// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./Address.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";

/**
  @notice EthClaimContract is an airdrop contract which we put ETH into and allow people to withdraw
    from, authenticating them using a merkle tree.
*/
contract EthClaimContract is Ownable {
  bytes32 public merkleRootEth;

  // alreadyClaimed stores whether an address has already claimed its eligible refund.
  mapping(address => bool) public alreadyClaimedEth;

  constructor(bytes32 _merkleRootEth) {
    merkleRootEth = _merkleRootEth;
  }

  /**
    @notice receive is implemented to allow this contract to receive ETH.
  */
  receive() external payable {}

  /**
    @notice withdrawEth allows the owner to withdraw ETH from the contract.
  */
  function withdrawEth(uint _amount) external onlyOwner {
    Address.sendValue(payable(msg.sender), _amount);
  }

  /**
    @notice setMerkleRootEth is used to set the root of the Merkle Tree that we will use to
      authenticate which users are eligible to withdraw refunds from this contract.
  */
  function setMerkleRootEth(bytes32 _merkleRootEth) external onlyOwner {
    merkleRootEth = _merkleRootEth;
  }

  /**
    @notice claimEthRefund will claim the ETH refund that an address is eligible to claim. The caller
      must pass the exact amount of ETH that the address is eligible to claim.
    @param _to The address to claim refund for.
    @param _refundAmount The amount of ETH refund to claim.
    @param _merkleProof The merkle proof used to authenticate the transaction against the Merkle
      root.
  */
  function claimEthRefund(address _to, uint _refundAmount, bytes32[] calldata _merkleProof) external {
    require(!alreadyClaimedEth[_to], "Refund has already been claimed for this address");

    // Verify against the Merkle tree that the transaction is authenticated for the user.
    bytes32 leaf = keccak256(abi.encodePacked(_to, _refundAmount));
    require(MerkleProof.verify(_merkleProof, merkleRootEth, leaf), "Failed to authenticate with merkle tree");

    alreadyClaimedEth[_to] = true;

    Address.sendValue(payable(_to), _refundAmount);
  }
}
