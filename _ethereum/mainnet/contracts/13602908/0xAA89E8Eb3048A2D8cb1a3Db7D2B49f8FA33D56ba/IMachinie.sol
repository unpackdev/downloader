// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./IERC721Enumerable.sol";


interface IMachinie  is IERC721Enumerable{

    function mintMachinie( address to_,uint256 tokenId_) external; 

    function stakeMachinie(uint256[] memory machinieIds_,uint256[] memory hamachIds_) external;  

    function unStakeMachinie(uint256[] memory machinieIds_) external returns(uint256) ; 

    function claimFloppy(uint256[] memory machinieIds_) external returns(uint256) ;

    function getStakeReward(uint256 machinieId_) external view returns(uint256) ;

    function updateTokenName (uint256 tokenId_ ,string memory name_ ) external ;

    function updateTokenDescription (uint256 tokenId_  ,string memory description_ ) external ;

    function burnMachinie(uint256 tokenId_) external;
    
    function updateStakStatus(uint256 tokenId_,bool status_) external ; 

    function updateStakeTime (uint256 tokenId_ ,uint256 stakeTime_) external; 

    function walletOfOwner(address _owner) external view returns(uint256[] memory) ;

    function isLevel (uint256 tokenId_) external view returns(uint256);
    
    function isStaking (uint256 tokenId_) external view returns(bool);
    
    function getStakeTime (uint256 tokenId_) external view returns (uint256);
    
    function getTokenIdName(uint256 tokenId_) external view returns(string memory, string memory);
    
    function getStakeRate(uint256 level_) external view returns(uint256) ;

    function getHumachTokenId(uint256 machinieId_) external view returns(uint256);
}