// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./IERC721Receiver.sol";
import "./ERC721.sol";
import "./SafeMath.sol";
import "./AlphaToken.sol";
import "./AlphaWolves.sol";
import "./AlphaWolvesVerifier.sol";

/*  
    Contract by Selema
    Disc: Selema#0880
    Twitter: @ImpurefulArt
*/

contract AlphaVault is Ownable, IERC721Receiver {

    uint256 public totalStaked;
    uint256 public score = 10;
    uint256 public alphaSupply = 333;
    bool public emergencyActive = false;
  
  // struct to store a stake's token, owner, and earning values
  struct Stake {
    uint24 tokenId;
    uint48 timestamp;
    address owner;
  }

  event AlphaStaked(address owner, uint256 tokenId, uint256 value);
  event AlphaUnstaked(address owner, uint256 tokenId, uint256 value);
  event Claimed(address owner, uint256 amount);


  AlphaToken token;
  AlphaWolves alphaWolves;
  AlphaWolvesVerifier verifier;

  // maps tokenId to stake
  mapping(uint256 => Stake) public vault; 

  // tracks staked nfts to calculate bonus
  mapping(address => uint256) private _staked;

  constructor(AlphaWolves _nft, AlphaToken _token, AlphaWolvesVerifier _verifier) { 
    token = _token;
    alphaWolves = _nft;
    verifier = _verifier;
  }


// enter 0 if you have not ever staked

  function stake(uint256[] calldata tokenIds, uint256[] calldata alreadyStakedIds) external {
    if(_staked[msg.sender] >= 1){
    _claim(msg.sender, alreadyStakedIds, false);
    }
    uint256 tokenId;

    for (uint i = 0; i < tokenIds.length; i++) {
      tokenId = tokenIds[i];
      require(alphaWolves.ownerOf(tokenId) == msg.sender, "not your token");
      require(vault[tokenId].tokenId == 0, 'already staked');
      

      alphaWolves.transferFrom(msg.sender, address(this), tokenId);
      emit AlphaStaked(msg.sender, tokenId, block.timestamp);

      vault[tokenId] = Stake({
        owner: msg.sender,
        tokenId: uint24(tokenId),
        timestamp: uint48(block.timestamp)
      });
      verifier.mint(msg.sender, 1 * 10 ** 18);
    }
      totalStaked += tokenIds.length;
      _staked[msg.sender] += tokenIds.length;

  }


  function _unstakeMany(address account, uint256[] calldata tokenIds) internal {
    uint256 tokenId;
    totalStaked -= tokenIds.length;
    for (uint i = 0; i < tokenIds.length; i++) {
      tokenId = tokenIds[i];
      Stake memory staked = vault[tokenId];
      require(staked.owner == msg.sender, "not an owner");
      
      verifier.burnFrom(account, 1 * 10 ** 18);

// need to add minus tokenid length from future mapping addres to uint256
      delete vault[tokenId];
      emit AlphaUnstaked(account, tokenId, block.timestamp);
      alphaWolves.transferFrom(address(this), account, tokenId);
    }
    _staked[msg.sender] -= tokenIds.length;
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
  // functions to adjust the reward rates
  // to negate a bonus just set it to 1

mapping(uint256 => uint256) private _bonus;

function setScoreAfterYears(uint256 _score) external onlyOwner{
  score = _score;
}  

 function setBonusForTwo(uint256 _bonusForTwo) external onlyOwner {
     _bonus[2] = _bonusForTwo;
  }

  function setBonusForThree(uint256 _bonusForThree) external onlyOwner{
    _bonus[3] = _bonusForThree;
  }

  function setBonusForFour(uint256 _bonusForFour) external onlyOwner{
    _bonus[4] = _bonusForFour;
  }

  function setBonusForFive(uint256 _bonusForFive) external onlyOwner{
   _bonus[5] = _bonusForFive;
  } 

  function setBonusForSix(uint256 _bonusForSix) external onlyOwner{
    _bonus[6] = _bonusForSix;
  }

function _claim(address account, uint256[] calldata tokenIds, bool _unstake) internal {
    uint256 tokenId;
    uint256 earned = 0;
    
  if(_staked[account] > 1){
        if (_staked[account] >= 6) {
        score = _bonus[6];
        } 
      else {
        score = _bonus[_staked[account]];
      }
  }
    for (uint i = 0; i < tokenIds.length; i++) {
      tokenId = tokenIds[i];

      Stake memory staked = vault[tokenId];
      require(staked.owner == account, "not an owner");

      uint256 stakedAt = staked.timestamp;
      earned += 1 ether * score * (block.timestamp - stakedAt) / 1 days; 

      vault[tokenId] = Stake({
        owner: account,
        tokenId: uint24(tokenId),
        timestamp: uint48(block.timestamp)
      });
    }
    if (earned > 0) {
      token.mint(account, earned);
    }
    if (_unstake) {
      _unstakeMany(account, tokenIds);
    }
    emit Claimed(account, earned);
  }
  // Emergency
  function emergencyUnstake(uint256[] calldata tokenIds) external {
    require(emergencyActive, "only in emergencies");
    _unstakeMany(msg.sender, tokenIds);
  }


  function earningInfo(uint256[] calldata tokenIds) external view returns (uint256[2] memory info) {
     uint256 totalScore = 0;
     uint256 earned = 0;

     for (uint i = 0; i < tokenIds.length; i++) {
      uint256 tokenId = tokenIds[i];
      totalScore += score;

      Stake memory staked = vault[tokenId];

      uint256 stakedAt = staked.timestamp;

      earned += 1 ether * score * (block.timestamp - stakedAt) / 1 days;
    }

    uint256 earnRatePerSecond = totalScore * 1 ether / 1 days;

    // earned, earnRatePerSecond
    return [earned, earnRatePerSecond];
    }

  function setAlphaSupply(uint256 _supply) external onlyOwner{
      alphaSupply = _supply;
    }

  // should never be used inside of transaction because of gas fee
  function balanceOf(address account) public view returns (uint256) {
    uint256 balance = 0;
    for(uint i = 0; i < alphaSupply; i++) {
      if (vault[i].owner == account) {
        balance += 1;
      }
    }
    return balance;
  }
  function activateEmergency(bool _active) external onlyOwner {
    emergencyActive = _active;
  }

  // should never be used inside of transaction because of gas fee
  function tokensOfOwner(address account) public view returns (uint256[] memory ownerTokens) {

    uint256[] memory tmp = new uint256[](alphaSupply);

    uint256 index = 0;
    for(uint tokenId = 0; tokenId < alphaSupply; tokenId++) {
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
      require(from == address(0x0), "Cannot send nfts to Vault directly");
      return IERC721Receiver.onERC721Received.selector;
    }
}
