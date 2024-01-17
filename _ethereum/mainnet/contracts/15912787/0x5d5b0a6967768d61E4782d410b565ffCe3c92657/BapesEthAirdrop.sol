// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./Strings.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./MerkleProof.sol";

contract BapesEthAirdrop is Ownable, ReentrancyGuard {
  using Strings for uint256;

  bool public isClaimStarted = true;
  bytes32 private merkleRoot;
  uint256 public claimPerWallet = 1;
  mapping(address => uint256) private claimedWallets;

  function addressToString() internal view returns (string memory) {
    return Strings.toHexString(uint160(_msgSender()), 20);
  }

  function transferTo(address _receiver, uint256 _amount) private {
    require(_receiver != address(0), "Invalid receiver.");

    (bool success, ) = payable(_receiver).call{value: _amount}("");

    require(success, "Transfer failed.");
  }

  function claim(uint256 _amount, bytes32[] calldata _merkleProof) public nonReentrant {
    uint256 claimed = claimedWallets[_msgSender()];

    require(isClaimStarted, "Claim is paused");
    require(claimed < claimPerWallet, "This wallet has already claimed");

    bytes32 leaf = keccak256(abi.encodePacked(addressToString(), "-", _amount.toString()));

    require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), "Invalid proof, this wallet is not eligible for claim");

    claimedWallets[_msgSender()] = claimPerWallet;

    transferTo(_msgSender(), _amount);
  }

  receive() external payable {}

  function claimFor(uint256 _claimAmount, address _receiver) external onlyOwner {
    require(isClaimStarted, "Claim is paused");

    transferTo(_receiver, _claimAmount);
  }

  function toggleClaim(bool _state) external onlyOwner {
    isClaimStarted = _state;
  }

  function updateClaimPerWallet(uint256 _amount) external onlyOwner {
    claimPerWallet = _amount;
  }

  function updateMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
    merkleRoot = _merkleRoot;
  }
}
