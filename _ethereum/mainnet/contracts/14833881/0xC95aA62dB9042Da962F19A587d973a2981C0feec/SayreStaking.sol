// SPDX-License-Identifier: MIT LICENSE

pragma solidity 0.8.4;

import "./Ownable.sol";
import "./ERC721Enumerable.sol";
import "./IERC721Receiver.sol";
import "./VTC.sol";


//██╗░░░██╗████████╗░█████╗░
//██║░░░██║╚══██╔══╝██╔══██╗
//╚██╗░██╔╝░░░██║░░░██║░░╚═╝
//░╚████╔╝░░░░██║░░░██║░░██╗
//░░╚██╔╝░░░░░██║░░░╚█████╔╝
//░░░╚═╝░░░░░░╚═╝░░░░╚════╝░


  interface IVCBoost {
    function boostOwner(address owner) external view returns (uint256[] memory);
  }
  
  contract SayreStaking is Ownable, IERC721Receiver {
  address VTCBoostContract =  0x2EAeED88124702A35aDaAc39051448F7c046D844;

  uint256 public totalStaked;
  struct Stake {
    uint48 timestamp;
    uint24 tokenId;
    address owner;
  }
  ERC721Enumerable SayreNFT;
  VTC token;
  
  
  event ClaimReward(address owner, uint256 amount);
  event SayreStaked(address owner, uint256 tokenId, uint256 value);
  event SayreUnstaked(address owner, uint256 tokenId, uint256 value);
  
  mapping(uint256 => Stake) public vault; 
  constructor(ERC721Enumerable _SayreContract, VTC _token) { 
    SayreNFT = _SayreContract;
    token = _token;
  }

//███████╗██╗░░░██╗███╗░░██╗░█████╗░████████╗██╗░█████╗░███╗░░██╗░██████╗
//██╔════╝██║░░░██║████╗░██║██╔══██╗╚══██╔══╝██║██╔══██╗████╗░██║██╔════╝
//█████╗░░██║░░░██║██╔██╗██║██║░░╚═╝░░░██║░░░██║██║░░██║██╔██╗██║╚█████╗░
//██╔══╝░░██║░░░██║██║╚████║██║░░██╗░░░██║░░░██║██║░░██║██║╚████║░╚═══██╗
//██║░░░░░╚██████╔╝██║░╚███║╚█████╔╝░░░██║░░░██║╚█████╔╝██║░╚███║██████╔╝
//╚═╝░░░░░░╚═════╝░╚═╝░░╚══╝░╚════╝░░░░╚═╝░░░╚═╝░╚════╝░╚═╝░░╚══╝╚═════╝░

  function stake(uint256[] calldata tokenIds) external {
    uint256 tokenId;
    totalStaked += tokenIds.length;
    for (uint i = 0; i < tokenIds.length; i++) {
      tokenId = tokenIds[i];
      require(SayreNFT.ownerOf(tokenId) == msg.sender, "You do not own this Sayre.");
      require(vault[tokenId].tokenId == 0, 'already staked');

      SayreNFT.transferFrom(msg.sender, address(this), tokenId);
      emit SayreStaked(msg.sender, tokenId, block.timestamp);

      vault[tokenId] = Stake({
        owner: msg.sender,
        tokenId: uint24(tokenId),
        timestamp: uint48(block.timestamp)
      });
    }
  }
  function _batchUnstake(address account, uint256[] calldata tokenIds) internal {
    uint256 tokenId;
    totalStaked -= tokenIds.length;
    for (uint i = 0; i < tokenIds.length; i++) {
      tokenId = tokenIds[i];
      Stake memory staked = vault[tokenId];
      require(staked.owner == msg.sender, "You do not own this Sayre");

      delete vault[tokenId];
      emit SayreUnstaked(account, tokenId, block.timestamp);
      SayreNFT.transferFrom(address(this), account, tokenId);
    }
  }

  function claim(uint256[] calldata tokenIds) external {
      _claim(msg.sender, tokenIds, false);
  }

  function claimForAddress(address account, uint256[] calldata tokenIds) external {
      _claim(account, tokenIds, false);
  }

  function unstake(uint256[] calldata tokenIds) external {
      _claim(msg.sender, tokenIds, true);
  }

  function _claim(address account, uint256[] calldata tokenIds, bool _unstake) internal {
    uint256 tokenId;
    uint256 earned = 0;
    uint256 calculateReward = 0;
    uint256[] memory vtArray;

    for (uint i = 0; i < tokenIds.length; i++) {
      tokenId = tokenIds[i];
      Stake memory staked = vault[tokenId];
      require(staked.owner == account, "not an owner");
      uint256 stakedAt = staked.timestamp;
      calculateReward += 1000 ether * (block.timestamp - stakedAt) / 86400 ;
      vtArray = IVCBoost(VTCBoostContract).boostOwner(account);
      if (vtArray.length >= 1){
        earned = 2 * (calculateReward / 1000);
      }else{
        earned = calculateReward / 1000;
      }
      vault[tokenId] = Stake({
        owner: account,
        tokenId: uint24(tokenId),
        timestamp: uint48(block.timestamp)
      });
    }
    if (earned > 0) {
      token.generate(account, earned);
    }
    if (_unstake) {
      _batchUnstake(account, tokenIds);
    }
    emit ClaimReward(account, earned);
  }

  function rewardInfo(address account, uint256[] calldata tokenIds) external view returns (uint256[1] memory info) {
     uint256 tokenId;
     uint256 earned = 0;
     uint256 calculateReward = 0;
     uint256[] memory vtArray;

    for (uint i = 0; i < tokenIds.length; i++) {
      tokenId = tokenIds[i];
      Stake memory staked = vault[tokenId];
      require(staked.owner == account, "not an owner");
      uint256 stakedAt = staked.timestamp;
      calculateReward += 1000 ether * (block.timestamp - stakedAt) / 86400;
      vtArray = IVCBoost(VTCBoostContract).boostOwner(account);
      if (vtArray.length >= 1){
        earned = 2 * (calculateReward / 1000);
      }else{
        earned = calculateReward / 1000;
      }
    }
    if (earned > 0) {
      return [earned];
    }
}
  function balanceOf(address account) public view returns (uint256) {
    uint256 balance = 0;
    uint256 supply = SayreNFT.totalSupply();
    for(uint i = 1; i <= supply; i++) {
      if (vault[i].owner == account) {
        balance += 1;
      }
    }
    return balance;
  }
  function tokensOfOwner(address account) public view returns (uint256[] memory ownerTokens) {

    uint256 supply = SayreNFT.totalSupply();
    uint256[] memory tmp = new uint256[](supply);

    uint256 index = 0;
    for(uint tokenId = 1; tokenId <= supply; tokenId++) {
      if (vault[tokenId].owner == account) {
        tmp[index] = vault[tokenId].tokenId;
        index +=1;
      }
    }

    uint256[] memory tokens = new uint256[](index);
    for(uint i = 0; i < index; i++) {
      tokens[i] = tmp[i];
    }

    return tokens;
  }

  function onERC721Received(
        address,
        address from,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
      require(from == address(0x0), "Send failed.");
      return IERC721Receiver.onERC721Received.selector;
    }
  
}