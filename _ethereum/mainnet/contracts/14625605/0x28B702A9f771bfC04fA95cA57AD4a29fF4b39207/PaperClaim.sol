// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./SafeMath.sol";
import "./Ownable.sol";
import "./ECDSA.sol";
import "./Counters.sol";
import "./Address.sol";
import "./IERC20.sol";
import "./IERC721.sol";

contract PaperClaim is Ownable {
  using SafeMath for uint;
  using Counters for Counters.Counter;

  event PaperClaimed(address indexed walletAddress, uint claimedAmount);

  // Total Claimed
  Counters.Counter private totalClaimed;

  // pause/unpaused state of the contract
  bool public isActive = false;

  // mapping to store all the claimed tokens
  mapping(uint => bool) public claimedTokens;

  // signer address for verification
  address public signerAddress;

  // paper token address
  address public paperTokenAddress;

  // Acrocalypse (ACROC) address
  IERC721 public nftTokenAddress;

  constructor(address _paperTokenAddress, address _nftTokenAddress) {
      signerAddress = msg.sender;
      if (address(_paperTokenAddress) != address(0)) {
        paperTokenAddress = _paperTokenAddress;
      }

      if (address(_nftTokenAddress) != address(0)) {
        nftTokenAddress = IERC721(_nftTokenAddress);
      }
  }

  fallback() external payable {}
  receive() external payable {}

  function totalClaimedTokens() external view returns (uint) {
    return totalClaimed.current();
  }

  function verifySender(bytes memory signature, uint tokenId, uint tokensEarned) internal view returns (bool) {
    bytes32 hash = ECDSA.toEthSignedMessageHash(keccak256(abi.encodePacked(msg.sender, tokenId, tokensEarned )));
    return ECDSA.recover(hash, signature) == signerAddress;
  }

  function claimTokens( bytes memory signature, uint tokensEarned, uint[] memory tokenIds ) external  {

    require (isActive, "Contract is not active");
    require (tokensEarned > 0, "Tokens earned should be > 0");
    require (tokenIds.length > 0, "Token Ids not set");

    // verifying the signature
    require(verifySender(signature, tokenIds[0], tokensEarned), "Invalid Access");

    // token validation
    for (uint256 i = 0; i < tokenIds.length; i++) {
      // validating the claimed token ids
      require(!claimedTokens[tokenIds[i]], "One of the Token ID has already been claimed!");

      // validating the token ownership
      require(nftTokenAddress.ownerOf(tokenIds[i]) == msg.sender, "Token owner mismatch");
    }
  
    // Marking tokens as claimed
    for (uint256 i = 0; i < tokenIds.length; i++) {
      totalClaimed.increment();
      claimedTokens[tokenIds[i]] = true;
    }

    emit PaperClaimed(msg.sender, tokensEarned);

    // Transfer the $PAPER Tokens
    bool success = IERC20(paperTokenAddress).transfer(msg.sender, tokensEarned);
    require(success, "claimTokens: Unable to transfer tokens");
  }

  function checkTokensStatus(uint[] memory tokenIds) external view returns (bool[] memory result) {
    
    require (tokenIds.length > 0, "Token Ids not set");

    bool[] memory unclaimedTokenIds = new bool[](tokenIds.length);
    
    for (uint256 i = 0; i < tokenIds.length; i++) {
      if (claimedTokens[tokenIds[i]]) {
        unclaimedTokenIds[i] = true; 
      }
    }

    return unclaimedTokenIds;
  }
  
  function setActive(bool newIsActive) external onlyOwner {
    if( isActive != newIsActive )
      isActive = newIsActive;
  }

  function updateTokensClaimedStatus(uint[] memory tokenIds, bool[] memory newClaimStatus) external onlyOwner {
    require (tokenIds.length > 0, "Token Ids not set");
    require (newClaimStatus.length > 0, "Claim status not set");
    require (tokenIds.length == newClaimStatus.length, "Data mismatch");

    for (uint256 i = 0; i < tokenIds.length; i++) {
      if (claimedTokens[tokenIds[i]] != newClaimStatus[i]) {
        claimedTokens[tokenIds[i]] = newClaimStatus[i]; 
      }
    }
  }

  function setSignerAddress(address newSignerAddress) external onlyOwner {
    require(address(newSignerAddress) != address(0), "Invalid token address");
    signerAddress = newSignerAddress;
  }

  function setPaperTokenAddress(address newtokenAddress) external onlyOwner {
    require(address(newtokenAddress) != address(0), "Invalid token address");
    paperTokenAddress = newtokenAddress;
  }

  function setNFTTokenAddress(address newtokenAddress) external onlyOwner {
    require(address(newtokenAddress) != address(0), "Invalid token address");
    nftTokenAddress = IERC721(newtokenAddress);
  }

  function withdraw(uint256 percentWithdrawl) external onlyOwner {
      uint balance = address(this).balance;
      require(balance > 0, "No funds available");
      require(percentWithdrawl > 0 && percentWithdrawl <= 100, "Withdrawl percent should be > 0 and <= 100");

      Address.sendValue(payable(owner()), (balance.mul(percentWithdrawl).div(100)));
  }

  function withdrawPaperTokens(uint percentWithdrawl) external onlyOwner {
      require(percentWithdrawl > 0 && percentWithdrawl <= 100, "Withdrawl percent should be > 0 and <= 100");

      uint balance = IERC20(paperTokenAddress).balanceOf(address(this));
      require(balance > 0, "$PAPER balance is low");

      // Transfer the $PAPER Tokens
      bool success = IERC20(paperTokenAddress).transfer(owner(), balance.mul(percentWithdrawl).div(100));
      require(success, "withdrawPaperTokens: Unable to transfer tokens");     
  }
}