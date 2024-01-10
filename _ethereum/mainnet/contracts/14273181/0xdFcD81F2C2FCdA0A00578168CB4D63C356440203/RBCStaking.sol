// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./Ownable.sol";
import "./Pausable.sol";
import "./ReentrancyGuard.sol";
import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./SafeMath.sol";
import "./ERC20.sol";

  //___    _   ___ ___ ___ _   _ _  _ _  _ ___ ___ _   _   _ ___ 
 //| _ \  /_\ | _ \ __| _ ) | | | \| | \| |_ _/ __| | | | | | _ )
 //|   / / _ \|   / _|| _ \ |_| | .` | .` || | (__| |_| |_| | _ \
 //|_|_\/_/ \_\_|_\___|___/\___/|_|\_|_|\_|___\___|____\___/|___/                                                               

//Written by BunniZero, if you copy pls give credit and link RareBunniClub.com
//Web rarebunniclub.com
//Twitter @rarebunniclub
//Linktree https://linktr.ee/RareBunniClub

interface IRBCUtility {
    function getReward(address _to, uint256 totalPayout) external payable;
}

contract RBCStaking is Ownable, IERC721Receiver, ReentrancyGuard, Pausable {
    using SafeMath for uint256;    

  //RBC and $CARROT Token addresses
  address public UtilityAddress;
  
  //Deposit Staking  
  mapping (address => uint256) public RewardRate; //Contract / Reward Rate
  mapping (address => mapping (address => uint80)) private lastClaim; //Contract / Wallet / LastClaim
  mapping (address => mapping (address => uint256[])) private TokensOfOwner; //Contract / Wallet / Tokens  

  constructor(address _contractAddress, address _UtilityAddress, uint16 _rewardRate) 
  {
    UtilityAddress = _UtilityAddress;     
    RewardRate[_contractAddress] = _rewardRate;                
  }	

  // Claim rewards for Bunnies
  function claimRewards(address _contractAddress) public 
  {    
    uint256 numStaked = TokensOfOwner[_contractAddress][msg.sender].length;

    if (numStaked > 0)
    {
      uint256 rRate = RewardRate[_contractAddress] * numStaked;
      uint256 reward = rRate * ((block.timestamp - lastClaim[_contractAddress][msg.sender]) / 86400);

      if (reward > 0)
      {
          lastClaim[_contractAddress][msg.sender] = uint80(block.timestamp);    
          IRBCUtility(UtilityAddress).getReward(msg.sender, reward);
      }
    }
  }  

  // Stake Bunni (deposit ERC721)
  function deposit(address _contractAddress, uint256[] calldata tokenIds) external whenNotPaused 
  {    
    require(RewardRate[_contractAddress] > 0, "invalid address for staking");
        
    claimRewards(_contractAddress); //Claims All Rewards

    uint256 length = tokenIds.length; 
    for (uint256 i; i < length; i++) 
    {
      IERC721(_contractAddress).transferFrom(msg.sender, address(this), tokenIds[i]);            
      TokensOfOwner[_contractAddress][msg.sender].push(tokenIds[i]);            
    }

    lastClaim[_contractAddress][msg.sender] = uint80(block.timestamp);    
  }

  // Unstake Bunni (withdrawal ERC721)
  function withdraw(address _contractAddress, uint256[] calldata tokenIds, bool _doClaim) external nonReentrant() 
  {      
    if (_doClaim) //You can Withdraw without Claiming if needs be
    {
      claimRewards(_contractAddress); //Claims All Rewards
    }
            
    uint256 length = tokenIds.length; 
    for (uint256 i; i < length; i++)
    {
      require(amOwnerOf(_contractAddress, tokenIds[i]), "Bunni not yours");            
      IERC721(_contractAddress).transferFrom(address(this), msg.sender, tokenIds[i]);

      TokensOfOwner[_contractAddress][msg.sender] = _moveTokenInTheList(TokensOfOwner[_contractAddress][msg.sender], tokenIds[i]);
      TokensOfOwner[_contractAddress][msg.sender].pop();

      if (TokensOfOwner[_contractAddress][msg.sender].length < 1) //<= 0
      {
        delete(lastClaim[_contractAddress][msg.sender]);
      }
    }
  }

  function _moveTokenInTheList(uint256[] memory list, uint256 tokenId) internal pure returns (uint256[] memory) {
      uint256 tokenIndex = 0;
      uint256 lastTokenIndex = list.length - 1;
      uint256 length = list.length;

      for(uint256 i = 0; i < length; i++) {
        if (list[i] == tokenId) {
          tokenIndex = i + 1;
          break;
        }
      }
      require(tokenIndex != 0, "msg.sender is not the owner");

      tokenIndex -= 1;

      if (tokenIndex != lastTokenIndex) {
        list[tokenIndex] = list[lastTokenIndex];
        list[lastTokenIndex] = tokenId;
      }

      return list;
    }

    function amOwnerOf(address _contractAddress, uint256 _tokenId) internal view returns (bool) {
      uint256[] memory tokens = TokensOfOwner[_contractAddress][msg.sender];

      uint256 length = tokens.length;
      for(uint256 i = 0; i < length; i++) 
      {
        if (tokens[i] == _tokenId) {
          return true;
        }
      }

      return false;
    }
  
    //Set the Utility Token Address ($CARROT)
  function setUtilityAddress(address _UtilityAddress) external onlyOwner {
		UtilityAddress = _UtilityAddress;
	}

  function enableStaking(address _contractAddress, uint16 _rewardRate) external onlyOwner() 
  {    
    RewardRate[_contractAddress] = _rewardRate;                
  }

  function calculateRewards(address _contractAddress, address _walletAddress) external view returns (uint256 reward) 
  {    
    uint256 numStaked = TokensOfOwner[_contractAddress][_walletAddress].length;

    if (numStaked > 0)
    {
      uint256 rRate = RewardRate[_contractAddress] * numStaked;
      return rRate * ((block.timestamp - lastClaim[_contractAddress][_walletAddress]) / 86400);      
    }

    return 0;
  }

  function getLastClaimTime(address _contractAddress, address _walletAddress) external view returns (uint80 lastClaimTime) 
  {    
    return lastClaim[_contractAddress][_walletAddress];
  }

  function depositsOf(address _contractAddress, address _walletAddress) external view returns (uint256[] memory) 
  {
    return TokensOfOwner[_contractAddress][_walletAddress];    
  }

  // (Owner) Public accessor methods for pausing
  function pause() public onlyOwner { _pause(); }
  function unpause() public onlyOwner { _unpause(); }

  // Support ERC721 transfer
  function onERC721Received(address, address, uint256, bytes calldata) external pure override returns (bytes4) {    
    return IERC721Receiver.onERC721Received.selector;
  }
}