// SPDX-License-Identifier: GPL-3.0-only

pragma solidity ^0.8.9;

import "./ERC721EnumerableUpgradeable.sol";
import "./MerkleProofUpgradeable.sol";
import "./IAllowListClaim.sol";
import "./AllowListClaimStorage.sol";

/*
 * Based on Nuclear Nerds
 */

/**
 * @dev Allows a list of addresses to claim a specific number of tokens. Uses Merkle Tree to verify the list.
 */
abstract contract AllowListClaim is IAllowListClaim, ERC721EnumerableUpgradeable {
  /**
   * @dev See {IERC165-supportsInterface}.
   */
  function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(ERC721EnumerableUpgradeable)
    returns (bool)
  {
    return interfaceId == type(IAllowListClaim).interfaceId || super.supportsInterface(interfaceId);
  }

  /**
   * @inheritdoc IAllowListClaim
   */
  function claimPeriod() public view virtual override returns (uint256, uint256) {
    return AllowListClaimStorage.claimPeriod();
  }

  /**
   * @dev sets the claim period start and end with block timestamps
   */
  function _setClaimPeriod(uint256 start, uint256 end) internal virtual {
    require(start < end, 'AllowListClaim: start must be before end');
    AllowListClaimStorage.setClaimPeriod(start, end);
    emit ClaimPeriodChanged(start, end);
  }

  /**
   * @inheritdoc IAllowListClaim
   */
  function merkleRoot() public view virtual override returns (bytes32) {
    return AllowListClaimStorage.merkleRoot();
  }

  /**
   * @dev Sets the merkle root for the allow list claim
   */
  function _setMerkleRoot(bytes32 _merkleRoot) internal virtual {
    AllowListClaimStorage.setMerkleRoot(_merkleRoot);
    emit MerkleRootChanged(_merkleRoot);
  }

  /**
   * @inheritdoc IAllowListClaim
   */
  function alreadyClaimed(address account) public view virtual override returns (uint256) {
    return AllowListClaimStorage.alreadyClaimed(account);
  }

  /**
   * @dev Attempts to mint the given amount of tokens to the given account.
   */
  function _allowListMint(
    address account,
    uint256 amount,
    uint256 allowance,
    bytes32[] calldata proof
  ) internal virtual {
    _verifyClaimPeriod();
    _verifyMerkleProof(account, allowance, proof);

    uint256 _alreadyClaimed = AllowListClaimStorage.alreadyClaimed(account);
    require(_alreadyClaimed + amount <= allowance, 'AllowListClaim: exceeds claim allowance');

    AllowListClaimStorage.setAlreadyClaimed(account, _alreadyClaimed + amount);
    uint256 nextToken = totalSupply() + 1;
    for (uint256 i; i < amount; i++) {
      _safeMint(account, nextToken + i);
    }
  }

  /**
   * @dev Verifies that we are in the claim period
   */
  function _verifyClaimPeriod() internal view virtual {
    require(
      // solhint-disable-next-line not-rely-on-time
      block.timestamp >= AllowListClaimStorage.claimPeriodStart(),
      'AllowListClaim: mint claim period has not yet started'
    );
    require(
      // solhint-disable-next-line not-rely-on-time
      block.timestamp <= AllowListClaimStorage.claimPeriodEnd(),
      'AllowListClaim: mint claim period has already ended'
    );
  }

  /**
   * @dev Verifies that the given account and allowance are in the Merkle Proof
   */
  function _verifyMerkleProof(
    address account,
    uint256 allowance,
    bytes32[] memory proof
  ) internal view virtual {
    require(
      MerkleProofUpgradeable.verify(proof, AllowListClaimStorage.merkleRoot(), _buildMerkleLeaf(account, allowance)),
      'AllowListClaim: invalid Merkle Tree proof supplied.'
    );
  }

  function _buildMerkleLeaf(address account, uint256 allowance) internal pure virtual returns (bytes32) {
    return keccak256(abi.encodePacked(account, allowance));
  }
}
