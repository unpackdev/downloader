//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./MerkleProof.sol";



contract MerkleWhitelist is Ownable {
  bytes32 public wlWhitelistMerkleRoot = 0xf85e4584ed6da3738a4ebdbd6de0739017f7541bb542fd89001446b4dc4918f2;
  bytes32 public mainWhitelistMerkleRoot = 0xcb499407d1fa69180f307797805245af5297f81839192fa6b0778f4addea845e;
  bytes32 public extraWhitelistMerkleRoot = 0xa717fa7d8c6aa469bca7d8497aaaadecabb7cce80978283d69f258791e9269c7;
  bytes32 public teamWhitelistMerkleRoot = 0xcdb8b74c1803bc2846fb114c807ec110f853d1e256cefa9bae4292ddbde722c8;


  function _verifyWlSender(bytes32[] memory proof) internal view returns (bool) {
    return _verify(proof, _hash(msg.sender), wlWhitelistMerkleRoot);
  }

  function _verifyMainSender(bytes32[] memory proof) internal view returns (bool) {
    return _verify(proof, _hash(msg.sender), mainWhitelistMerkleRoot);
  }

  function _verifyExtraSender(bytes32[] memory proof) internal view returns (bool) {
    return _verify(proof, _hash(msg.sender), extraWhitelistMerkleRoot);
  }

   function _verifyTeamSender(bytes32[] memory proof) internal view returns (bool) {
    return _verify(proof, _hash(msg.sender), teamWhitelistMerkleRoot);
  }

  function _verify(bytes32[] memory proof, bytes32 addressHash, bytes32 whitelistMerkleRoot)
    internal
    pure
    returns (bool)
  {
    return MerkleProof.verify(proof, whitelistMerkleRoot, addressHash);
  }

  function _hash(address _address) internal pure returns (bytes32) {
    return keccak256(abi.encodePacked(_address));
  }


  function setWlWhitelistMerkleRoot(bytes32 merkleRoot) external onlyOwner {
    wlWhitelistMerkleRoot = merkleRoot;
  }

  function setMainWhitelistMerkleRoot(bytes32 merkleRoot) external onlyOwner {
    mainWhitelistMerkleRoot = merkleRoot;
  }

  function setExtraWhitelistMerkleRoot(bytes32 merkleRoot) external onlyOwner {
    extraWhitelistMerkleRoot = merkleRoot;
  }

  function setTeamWhitelistMerkleRoot(bytes32 merkleRoot) external onlyOwner {
    teamWhitelistMerkleRoot = merkleRoot;
  }

  /*
  MODIFIER
  */
 modifier onlyWlWhitelist(bytes32[] memory proof) {
    require(_verifyWlSender(proof), "MerkleWhitelist: Caller is not whitelisted");
    _;
  }

  modifier onlyMainWhitelist(bytes32[] memory proof) {
    require(_verifyMainSender(proof), "MerkleWhitelist: Caller is not whitelisted");
    _;
  }
  
  modifier onlyExtraWhitelist(bytes32[] memory proof) {
    require(_verifyExtraSender(proof), "MerkleWhitelist: Caller is not whitelisted");
    _;
  }

  modifier onlyTeamWhitelist(bytes32[] memory proof) {
    require(_verifyTeamSender(proof), "MerkleWhitelist: Caller is not whitelisted");
    _;
  }
}