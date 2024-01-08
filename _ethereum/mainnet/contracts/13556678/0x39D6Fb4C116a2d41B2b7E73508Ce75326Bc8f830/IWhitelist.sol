// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;


interface IWhitelist {

  event SetWhitelistedMerkleRoot(bytes32 whitelistedMerkelRoot);
  
  function setWhitelistedMerkleRoot(bytes32 _whitelistedRoot, uint32 _totalWhitelisted) external;

  function isWhitelistedAddress(address buyer, uint32 privateCap, uint32 freeMintCap , bytes32[] memory proofs) external view returns (bool);

}