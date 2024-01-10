// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./VirtueToken.sol";
import "./Address.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";
import "./Strings.sol";

/**
  @notice MarketplaceRefundContract is an airdrop contract which allows authenticated users to claim a
    portion of the contract's Ethereum and/or VIRTUE balance based on how much they were owed before
    we had to tear down the original marketplace contract.
*/
contract MarketplaceRefundContract is Ownable {
  // merkleRoot is the value of the root of the Merkle Tree used for authenticating airdrop claims.
  bytes32 public merkleRootEth;
  bytes32 public merkleRootVirtue;
  VirtueToken virtueToken;

  // alreadyClaimed stores whether an address has already claimed its eligible refund.
  mapping(address => bool) public alreadyClaimedEth;
  mapping(address => bool) public alreadyClaimedVirtue;

  constructor(bytes32 _merkleRootEth, bytes32 _merkleRootVirtue, address _virtueTokenAddress) {
    merkleRootEth = _merkleRootEth;
    merkleRootVirtue = _merkleRootVirtue;
    virtueToken = VirtueToken(_virtueTokenAddress);
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
    @notice withdrawVirtue allows the owner to withdraw VIRTUE from the contract.
  */
  function withdrawVirtue(uint _amount) external onlyOwner {
    virtueToken.transfer(msg.sender, _amount);
  }

  /**
    @notice setMerkleRootEth is used to set the root of the Merkle Tree that we will use to
      authenticate which users are eligible to withdraw refunds from this contract.
  */
  function setMerkleRootEth(bytes32 _merkleRootEth) external onlyOwner {
    merkleRootEth = _merkleRootEth;
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
