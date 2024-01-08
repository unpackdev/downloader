// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./Counters.sol";
import "./Token.sol";


contract LawlessLemmings is Token {
   using Counters for Counters.Counter;
   Token public parentToken;
   Counters.Counter private _tokenIds;
   uint256 public maxNumberOfUpgradeTokens = 3000;
   uint256 public maxNumberOfUpgradeTokensPerCall = 10;
   address public burnAddress = address(1);
   uint256 private _totalSupply = 0;
   bool public isUpgradePaused = true;
   constructor(string memory name_, string memory symbol_, string memory baseUri_, Token parentToken_) Token(name_, symbol_, baseUri_){
     parentToken = parentToken_;
   }
   function setMaxNumberOfUpgradeTokens(uint256 number_) external onlyOwner {
     maxNumberOfUpgradeTokens = number_;
   }
   function setMaxNumberOfUpgradeTokensPerCall(uint256 number_) external onlyOwner{
     maxNumberOfUpgradeTokensPerCall = number_;
   }
   function setUpgradePaused(bool status_) external onlyOwner {
     isUpgradePaused = status_;
   }
   function setBurnAddress(address address_) external onlyOwner {
     burnAddress = address_;
   }
   function mint() external override view onlyOwner returns(uint256){
     revert("Can not mint new tokens");
   }
   function upgradeOne(uint256 previousTokenId) internal returns(uint256){
     _tokenIds.increment();
     uint256 createdTokenId = _tokenIds.current();

     require(createdTokenId <= maxNumberOfUpgradeTokens, "Maximum number of tokens exceeded");
     
     require(parentToken.ownerOf(previousTokenId) == msg.sender, "Sender is not owner of token");
     require(parentToken.getApproved(previousTokenId) == address(this)
             || parentToken.isApprovedForAll(msg.sender, address(this)),
             "Contract is not approved to handle the provided token id");

     parentToken.transferFrom(msg.sender, burnAddress, previousTokenId);

     _mint(msg.sender, createdTokenId);
     _totalSupply = _totalSupply + 1;
     return createdTokenId;
   }

   function upgrade(uint256[] calldata previousTokenIds) external returns(uint256[] memory){
     require(!isUpgradePaused, "Upgrade is paused");
     require(previousTokenIds.length <= maxNumberOfUpgradeTokensPerCall, "Too many tokens per call");
     uint256[] memory tokenIds = new uint256[](previousTokenIds.length);
     for(uint256 tokenIdx = 0; tokenIdx < previousTokenIds.length; tokenIdx++){
       tokenIds[tokenIdx] = upgradeOne(previousTokenIds[tokenIdx]);
     }
     return tokenIds;
   }
   
   function totalSupply() external view returns(uint256){
     return _totalSupply;
   }
   function burn(uint256 tokenId) external override {
     require(_exists(tokenId), "Token does not exist");
     require(_isApprovedOrOwner(msg.sender, tokenId), "Not approved to handle token id");
     _burn(tokenId);
     _totalSupply = _totalSupply - 1;
   }
}
