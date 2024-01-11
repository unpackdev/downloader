// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "./IERC721.sol";
import "./IERC20.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";

contract AAYCStakingContract is Ownable, ReentrancyGuard {

    address public rtoken;
    address public nftAddress;
        
    uint256 public RewardTokenPerBlock;

    struct UserInfo {
        uint256 tokenId;
        uint256 startBlock;
    }

    mapping(address => UserInfo[]) public userInfo;
    uint256 public totalStakingAmount = 0;

    event Stake(address indexed user, uint256 amount);
    event UnStake(address indexed user, uint256 amount);

    constructor(address _rTokenAddress, address _nftTokenAddress) {
        RewardTokenPerBlock = 0.1 ether;
        rtoken = _rTokenAddress;
        nftAddress = _nftTokenAddress;
    }

    function changeRewardTokenAddress(address _rewardTokenAddress) public onlyOwner {
        rtoken = _rewardTokenAddress;
    }

    function changeNftTokenAddress(address _nftTokenAddress) public onlyOwner {
        nftAddress = _nftTokenAddress;
    }

    function changeRewardTokenPerBlock(uint256 _RewardTokenPerBlock) public onlyOwner {
        RewardTokenPerBlock = _RewardTokenPerBlock;
    }

    function approve(address tokenAddress, address spender, uint256 amount) public onlyOwner returns (bool) {
      IERC20(tokenAddress).approve(spender, amount);
      return true;
    }

    function pendingReward(address _user, uint256 _tokenId) public view returns (uint256) {

        (bool _isStaked, uint256 _startBlock) = getStakingItemInfo(_user, _tokenId);
        if(!_isStaked) return 0;
        uint256 currentBlock = block.number;

        uint256 rewardAmount = (currentBlock - _startBlock) * RewardTokenPerBlock;
        if(userInfo[_user].length >= 10) rewardAmount = rewardAmount * 125 / 100;
        if(userInfo[_user].length >= 25) rewardAmount = rewardAmount * 150 / 100;
        if(userInfo[_user].length >= 50) rewardAmount = rewardAmount * 175 / 100;
        if(userInfo[_user].length >= 100) rewardAmount = rewardAmount * 200 / 100;
        return rewardAmount;
    }

    function pendingTotalReward(address _user) public view returns(uint256) {
        uint256 pending = 0;
        for (uint256 i = 0; i < userInfo[_user].length; i++) {
            uint256 temp = pendingReward(_user, userInfo[_user][i].tokenId);
            pending = pending + temp;
        }
        return pending;
    }

    function stake(uint256[] memory tokenIds) public {
        for(uint256 i = 0; i < tokenIds.length; i++) {
            (bool _isStaked,) = getStakingItemInfo(msg.sender, tokenIds[i]);
            if(_isStaked) continue;
            if(IERC721(nftAddress).ownerOf(tokenIds[i]) != msg.sender) continue;

            IERC721(nftAddress).transferFrom(address(msg.sender), address(this), tokenIds[i]);

            UserInfo memory info;
            info.tokenId = tokenIds[i];
            info.startBlock = block.number;

            userInfo[msg.sender].push(info);
            totalStakingAmount = totalStakingAmount + 1;
            emit Stake(msg.sender, 1);
        }
    }

    function unstake(uint256[] memory tokenIds) public nonReentrant {
        uint256 pending = 0;
        for(uint256 i = 0; i < tokenIds.length; i++) {
            (bool _isStaked,) = getStakingItemInfo(msg.sender, tokenIds[i]);
            if(!_isStaked) continue;
            if(IERC721(nftAddress).ownerOf(tokenIds[i]) != address(this)) continue;

            uint256 temp = pendingReward(msg.sender, tokenIds[i]);
            pending = pending + temp;
            
            removeFromUserInfo(tokenIds[i]);
            if(totalStakingAmount > 0)
                totalStakingAmount = totalStakingAmount - 1;
            IERC721(nftAddress).transferFrom(address(this), msg.sender, tokenIds[i]);
            emit UnStake(msg.sender, 1);
        }
        if(pending > 0) {
            IERC20(rtoken).transfer(msg.sender, pending);
        }
    }

    function getStakingItemInfo(address _user, uint256 _tokenId) public view returns(bool _isStaked, uint256 _startBlock) {
        for(uint256 i = 0; i < userInfo[_user].length; i++) {
            if(userInfo[_user][i].tokenId == _tokenId) {
                _isStaked = true;
                _startBlock = userInfo[_user][i].startBlock;
                break;
            }
        }
    }

    function removeFromUserInfo(uint256 tokenId) private {        
        for (uint256 i = 0; i < userInfo[msg.sender].length; i++) {
            if (userInfo[msg.sender][i].tokenId == tokenId) {
                userInfo[msg.sender][i] = userInfo[msg.sender][userInfo[msg.sender].length - 1];
                userInfo[msg.sender].pop();
                break;
            }
        }        
    }

    function claim() public {

        uint256 reward = pendingTotalReward(msg.sender);

        for (uint256 i = 0; i < userInfo[msg.sender].length; i++)
            userInfo[msg.sender][i].startBlock = block.number;

        IERC20(rtoken).transfer(msg.sender, reward);
    }
    
    function getStakingAmount(address _add) public view returns(uint256) {
        return userInfo[_add].length;
    }
}