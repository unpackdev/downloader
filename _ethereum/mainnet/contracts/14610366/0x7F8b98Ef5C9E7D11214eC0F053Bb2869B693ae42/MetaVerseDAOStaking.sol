// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./SafeMath.sol";
import "./Math.sol";
import "./SafeERC20.sol";
import "./IERC1155.sol";
import "./ERC1155Receiver.sol";
import "./ERC1155.sol";

contract MetaVerseDAOStaking is Ownable,ERC1155Receiver {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    event ChangeExpiration(uint256 oldExpirationTime,uint256 newExpirationTime);
    event ChangeRewardAddress(IERC20 oldRewardAddress, IERC20 newOldAddress);
    event ChangeMetaverseDAOAddress(IERC1155 oldmetaverseDAOAddress, IERC1155 newmetaverseDAOAddress);
    event ChangeRoyaltyClaimer(address oldRoyaltyClaimer, address newRoyaltyClaimer);
    event Deposited(address depositer,uint256 collectionId,uint256 amount,uint depositedTime);
    event WithDraw(uint256[] collectionIds,uint256[] amounts,uint256 rewardAmount);
    
    
    IERC20 rewardToken;
    IERC1155 metaverseDAOAddress;

    // expiration time of reward providing
    uint256 public expiration;

    uint256 public royaltyPercentage = 25;

    address royaltyClaimer = 0x89cC8F045033CF767BbB93A01e55F83288E061BA;

    struct UserInfo
    {
        uint256 amount;
        uint256 depositTime;
        uint256 previousUnClaimedRewardAmount;
    }

    mapping(uint256=>uint256) public rates;

    mapping(address=> mapping(uint256=>UserInfo)) public _userInfo;

    
    constructor(IERC1155 _metaverseDAOAddress,IERC20 _rewardToken) {
        metaverseDAOAddress = _metaverseDAOAddress;
        rewardToken = _rewardToken;
    }

    function setExpiration(uint256 _expiration) public onlyOwner {
        uint256 oldExpirationTime = expiration;
        expiration = _expiration;
        emit ChangeExpiration(oldExpirationTime,expiration);
    }

    function setNewRoyaltyPercentage(uint256 newRoyaltyPercentage) public onlyOwner {
        royaltyPercentage = newRoyaltyPercentage;
    }

    function changeRewardToken(IERC20 _rewardToken) public onlyOwner {
        IERC20 oldRewardAddress = rewardToken;
        rewardToken = _rewardToken;
        emit ChangeRewardAddress(oldRewardAddress,rewardToken);
    }

    function changemetaverseDAOAddress(IERC1155 _metaverseDAOAddress) public onlyOwner {
        IERC1155 oldmetaverseDAOAddress = metaverseDAOAddress;
        metaverseDAOAddress = _metaverseDAOAddress;
        emit ChangeMetaverseDAOAddress(oldmetaverseDAOAddress,metaverseDAOAddress);
    }

    function changeRate(uint256 collectionId, uint256 newRate) public onlyOwner
    {
      rates[collectionId] = newRate;
    }

    function changeRoyaltyClaimer(address newRoyaltyClaimer) public
    {
        address oldRoyaltyClaimer = royaltyClaimer;
        royaltyClaimer = newRoyaltyClaimer;
        emit ChangeRoyaltyClaimer(oldRoyaltyClaimer,royaltyClaimer);
    }


    function deposit(uint256 _amount,uint256 collectionId) external {

        require(
            expiration>block.timestamp,
            "Invalid time stamp"
        );

      metaverseDAOAddress.safeTransferFrom(msg.sender,address(this),collectionId,_amount,"");
      uint256 previousDeposit = _userInfo[msg.sender][collectionId].amount;

      uint256 rewardAmount = calculateReward(collectionId,msg.sender);
      if(previousDeposit>0)
      {
         _userInfo[msg.sender][collectionId].previousUnClaimedRewardAmount =  rewardAmount;
         _userInfo[msg.sender][collectionId].depositTime = block.timestamp;
         _userInfo[msg.sender][collectionId].amount = previousDeposit + _amount;
      }
      else
      {  
        _userInfo[msg.sender][collectionId] = UserInfo(_amount,block.timestamp,0);
      }
     emit Deposited(msg.sender,collectionId,_amount,block.timestamp);
    }

    function calculateReward(uint256 collectionId,address account)
        public
        view
        returns (uint256)
    {
        return _userInfo[account][collectionId].previousUnClaimedRewardAmount+
            rates[collectionId] *
            (Math.min(block.timestamp, expiration) -
                _userInfo[account][collectionId].depositTime)*_userInfo[account][collectionId].amount;
    }

    function claimRewards(uint256[] memory collectionIds) public
    {
        uint256 totalClaimableAmount;
        uint256[] memory amounts =  new uint[](collectionIds.length);
        for(uint256 i =0;i<collectionIds.length;i++)
        {
           amounts[i] = _userInfo[msg.sender][collectionIds[i]].amount;
           require(amounts[i]>0,"Amount must be more than or equal to 1");
           totalClaimableAmount = totalClaimableAmount + calculateReward(collectionIds[i],msg.sender);
           _userInfo[msg.sender][collectionIds[i]].previousUnClaimedRewardAmount = 0;
           _userInfo[msg.sender][collectionIds[i]].depositTime = block.timestamp;

        }
        uint256 rewardAmount = totalClaimableAmount.mul(80).div(100);
        uint256 royaltyAmount = totalClaimableAmount.mul(20).div(100);
        rewardToken.transfer(msg.sender,rewardAmount);
        rewardToken.transfer(royaltyClaimer,royaltyAmount);

    }


     function checkclaimRewards(uint256[] memory collectionIds,address account) public view returns (uint256[] memory amounts,uint256 rewardAmount,uint256 royaltyAmount)
    {
        uint256 totalClaimableAmount;
        uint256[] memory amounts =  new uint[](collectionIds.length);
        for(uint256 i =0;i<collectionIds.length;i++)
        {
           amounts[i] = _userInfo[account][collectionIds[i]].amount;
           require(amounts[i]>0,"Amount must be more than or equal to 1");
           totalClaimableAmount = totalClaimableAmount + calculateReward(collectionIds[i],account);

        }
        uint256 rewardAmount = totalClaimableAmount.mul(100-royaltyPercentage).div(100);
        uint256 royaltyAmount = totalClaimableAmount.mul(royaltyPercentage).div(100);
        return (amounts,rewardAmount,royaltyAmount);
    }

    function withdraw(uint256[] memory collectionIds) public 
    {
        uint256 totalClaimableAmount;
        uint256[] memory amounts =  new uint[](collectionIds.length);
        for(uint256 i =0;i<collectionIds.length;i++)
        {        
           amounts[i] = _userInfo[msg.sender][collectionIds[i]].amount;
           require(amounts[i]>0,"Amount must be more than or equal to 1");
           totalClaimableAmount = totalClaimableAmount + calculateReward(collectionIds[i],msg.sender);
           delete _userInfo[msg.sender][collectionIds[i]];
        }
        uint256 rewardAmount = totalClaimableAmount.mul(100-royaltyPercentage).div(100);
        uint256 royaltyAmount = totalClaimableAmount.mul(royaltyPercentage).div(100);
        rewardToken.transfer(msg.sender,rewardAmount);
        rewardToken.transfer(royaltyClaimer,royaltyAmount);
        metaverseDAOAddress.safeBatchTransferFrom(address(this),msg.sender,collectionIds,amounts,"");
        
        emit WithDraw(collectionIds,amounts,rewardAmount);
    }

    function onERC1155Received(
    address operator,
    address from,
    uint256 id,
    uint256 value,
    bytes calldata data
    )
    external
    override
    returns(bytes4)
    {
        return IERC1155Receiver.onERC1155Received.selector;
    }

function onERC1155BatchReceived(
    address operator,
    address from,
    uint256[] calldata ids,
    uint256[] calldata values,
    bytes calldata data
    )
    external
    override
    returns(bytes4)
    {
        return IERC1155Receiver.onERC1155BatchReceived.selector;
    }

     function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155Receiver) returns (bool) {
        return interfaceId == type(IERC1155).interfaceId
            || interfaceId == type(IERC1155Receiver).interfaceId;
    }

    function emergencyExit() public onlyOwner
    {
        rewardToken.transfer(msg.sender,rewardToken.balanceOf(address(this)));
    }
}