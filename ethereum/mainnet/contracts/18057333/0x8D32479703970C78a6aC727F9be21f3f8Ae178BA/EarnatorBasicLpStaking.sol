//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

library SafeMath {
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _transferOwnership(_msgSender());
    }
    modifier onlyOwner() {
        _checkOwner();
        _;
    }
    function owner() public view virtual returns (address) {
        return _owner;
    }
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

abstract contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        _status = _NOT_ENTERED;
    }
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == _ENTERED;
    }
}

contract EarnatorBasicLpStaking is Ownable, ReentrancyGuard {
    
    using SafeMath for uint256;

    IERC20 public lpToken;
    uint256 public lockPeriod = 20160 minutes;  // 20160 minutes
    uint256 public lock_var = 20160; // 14
    uint256 public rewardPerBlock = 1e18;
    uint256 public blockPerMinutes = 4;  // 4
    uint256 public AverageBlockTime = 13; // 13
    bool public EmergencyFeeWaive = false;
    bool public Deposit_enabled = false; // false 

    struct Stake {
        uint256 stakedAmount;
        uint256 stakeTime;
        uint256 unstakeTime;
        uint256 startBlock;
        uint256 lastClaimedBlock;
        uint256 claimedRewards;
    }

    struct UserInfo {
        Stake[] stakes;
    }

    mapping(address => UserInfo) private userInfo;

    event Staked(address indexed user, uint256 amount,uint256 startTime, uint256 endTime);
    event RewardWithdrawn(address indexed user, uint256 reward);
    event Unstaked(address indexed user, uint256 reward,uint256 unstakeAmount );

    constructor(IERC20 _rewardToken) {
        lpToken = _rewardToken;
    }

    function SetAverageBlockTimeAndTimeVar(uint256 _newTime, uint256 _time) external onlyOwner {
        AverageBlockTime = _newTime;
        lock_var = _time;
    }
    function enableDeposits(bool state) public onlyOwner {
        Deposit_enabled = state;
    }

    function stake(uint256 _tokenAmount) external nonReentrant {
        require(Deposit_enabled == true, "Deposits need to be enabled");
        require(_tokenAmount > 0, "Staking amount must be greater than 0!");

        uint256 _stakeTime = block.timestamp;
        uint256 _unstakeTime = _stakeTime.add(lockPeriod);

        userInfo[msg.sender].stakes.push(Stake({
            stakedAmount: _tokenAmount,
            stakeTime: _stakeTime,
            unstakeTime : _unstakeTime,
            startBlock : block.number,
            lastClaimedBlock: block.number,
            claimedRewards: 0
        }));
        require(lpToken.transferFrom(msg.sender, address(this), _tokenAmount), "Token transfer failed!");

        emit Staked(msg.sender, _tokenAmount, _stakeTime, _unstakeTime);
    }

    function unstake() external {
        UserInfo storage user = userInfo[msg.sender];

        uint256 totalUnstakeAmount = 0;
        uint256 totalReward = 0;

        // Store indexes of stakes that need to be removed
        uint256[] memory toRemoveIndexes = new uint256[](user.stakes.length);
        uint256 removeCount = 0;

        for (uint256 i = 0; i < user.stakes.length; i++) {
            if (block.timestamp >= user.stakes[i].stakeTime.add(lockPeriod)) {
                uint256 stakeReward = calculateRewardForStake(msg.sender, i);
                totalReward = totalReward.add(stakeReward);
                totalUnstakeAmount = totalUnstakeAmount.add(user.stakes[i].stakedAmount);

                if (stakeReward > 0 && !EmergencyFeeWaive) {
                    withdrawReward();
                }
                toRemoveIndexes[removeCount] = i;
                removeCount++;
            }
        }

        require(removeCount > 0, "Lock time not completed yet.");

        for (uint256 j = removeCount; j > 0; j--) {
            if (toRemoveIndexes[j - 1] != user.stakes.length - 1) {
                user.stakes[toRemoveIndexes[j - 1]] = user.stakes[user.stakes.length - 1];
            }
            user.stakes.pop();
        }

        require(lpToken.transfer(msg.sender, totalUnstakeAmount), "Failed to transfer LP tokens.");

        emit Unstaked(msg.sender, totalReward, totalUnstakeAmount);
    }

    function calculatePercentage(address user) public view returns(uint256) {
        UserInfo storage userInformation = userInfo[user];
        uint256 userTotalStake = 0;
        for (uint256 i = 0; i < userInformation.stakes.length; i++) {
            userTotalStake = userTotalStake.add(userInformation.stakes[i].stakedAmount);
        }

        uint256 totalPoolBalance = lpToken.balanceOf(address(this));
        if (totalPoolBalance == 0) {
            return 0;
        }

        uint256 percentage = userTotalStake.mul(10000).div(totalPoolBalance); 
        return percentage;
    }
 
    function getUserRewardForBlock(address user) public view returns (uint256) {
        uint256 userPercentage = calculatePercentage(user);
        uint256 userReward = rewardPerBlock.mul(userPercentage).div(10000); 
        return userReward;
    }

    function withdrawReward() public  {
        require(msg.sender == tx.origin, "invalid caller!");
        UserInfo storage user = userInfo[msg.sender];
        uint256 totalRewards = 0;

        for (uint256 i = 0; i < user.stakes.length; i++) {
            Stake storage stakeInfo = user.stakes[i];
            uint256 reward = calculateRewardForStake(msg.sender, i); 
            
            totalRewards = totalRewards.add(reward);

            if (reward > 0) {
            stakeInfo.lastClaimedBlock = block.number;
            stakeInfo.claimedRewards = stakeInfo.claimedRewards.add(reward);
            }
        }

        require(totalRewards > 0, "No rewards to withdraw");
        require(address(this).balance >= totalRewards, "insufficient ETH Balance!");
        payable(msg.sender).transfer(totalRewards);

        emit RewardWithdrawn(msg.sender, totalRewards);
    }

    function calculateRewardForStake(address user, uint256 stakeIndex) public view returns (uint256) {
        Stake storage stakeInfo = userInfo[user].stakes[stakeIndex];

        uint256 endBlock = stakeInfo.startBlock.add(blockPerMinutes.mul(lock_var));
        uint256 blockToCalculateUntil = (block.number < endBlock) ? block.number : endBlock;

        if (stakeInfo.lastClaimedBlock >= blockToCalculateUntil) {
            return 0;
        }

        uint256 blocksSinceLastClaim = blockToCalculateUntil.sub(stakeInfo.lastClaimedBlock);
        return getUserRewardForBlock(user).mul(blocksSinceLastClaim);
    }

    function calculateRewardSinceLastClaim(address user) public view returns (uint256) {
        uint256 totalReward = 0;
        for (uint256 i = 0; i < userInfo[user].stakes.length; i++) {
            totalReward = totalReward.add(calculateRewardForStake(user, i));
        }
        return totalReward;
    }

    function checkRemainingTimeAndBlocks(address user) public view returns(uint256[] memory remainingTimes, uint256[] memory remainingBlocks){
        UserInfo storage userInformation = userInfo[user];
        
        uint256[] memory _remainingTimes = new uint256[](userInformation.stakes.length);
        uint256[] memory _remainingBlocks = new uint256[](userInformation.stakes.length);

        for(uint256 i = 0; i < userInformation.stakes.length; i++) {
            Stake storage stakeInfo = userInformation.stakes[i];
            
            uint256 endBlock = stakeInfo.startBlock.add(blockPerMinutes.mul(lock_var));
            _remainingBlocks[i] = (block.number >= endBlock) ? 0 : endBlock.sub(block.number);
            _remainingTimes[i] = _remainingBlocks[i].mul(AverageBlockTime); // Assuming an average block time of 13 seconds for Ethereum // was 3 
            
            if(block.timestamp >= stakeInfo.unstakeTime) {
                _remainingTimes[i] = 0; 
            }
        }
        return (_remainingTimes, _remainingBlocks);
    }

    function checkRemainingTime(address user) external view returns(uint256[] memory){
        UserInfo storage userInformation = userInfo[user];
        uint256[] memory remainingTimes = new uint256[](userInformation.stakes.length);

        for(uint256 i = 0; i < userInformation.stakes.length; i++) {
            Stake storage stakeInfo = userInformation.stakes[i];
            if(block.timestamp < stakeInfo.unstakeTime) {
                remainingTimes[i] = stakeInfo.unstakeTime.sub(block.timestamp);
            } else {
                remainingTimes[i] = 0; 
            }
        }
        return remainingTimes;
    }

    function getAllStakeDetails(address _user) external view returns (uint256[] memory stakeIndices, Stake[] memory stakes) {
        UserInfo storage user = userInfo[_user];
        stakeIndices = new uint256[](user.stakes.length);
        stakes = user.stakes;

        for (uint256 i = 0; i < user.stakes.length; i++) {
            stakeIndices[i] = i;
        }

        return (stakeIndices, stakes);
    }

    function getCurrentBlock() public view returns(uint256) {
        return block.number;
    }



    function getLpDepositsForUser(address account)
        public
        view
        returns (uint256)
    {
        UserInfo storage user = userInfo[account];
        uint256 totalStaked; // Initialize the total staked variable

        for (uint256 i = 0; i < user.stakes.length; i++) {
            totalStaked += user.stakes[i].stakedAmount; // Accumulate the staked amounts
        }

        return totalStaked;
    }

    function EmergencyMeasures(bool state) public onlyOwner {
        EmergencyFeeWaive = state;
    }

    function updateRewards(uint256 _rewardperBlock) external onlyOwner {
        rewardPerBlock = _rewardperBlock;
    }

    function updatelockPeriod(uint256 newLockPeriodInMinutes)
        external
        onlyOwner
    {
        lockPeriod = newLockPeriodInMinutes * 1 minutes;
    }
    function updateBlockPerMinutes(uint256 _blockPerMinute) external onlyOwner  {
    blockPerMinutes=_blockPerMinute;

    }
    function emergencyWithdrawLpTokens() external onlyOwner {
        uint256 balanceOfContract = lpToken.balanceOf(address(this));
        lpToken.transfer(owner(), balanceOfContract);
    }

    function CheckBalance() public view returns(uint256){
        return lpToken.balanceOf(address(this));
    }

    function emergencyMigration() external  onlyOwner {
        lpToken.transfer(owner(), lpToken.balanceOf(address(this)));
    }

    function withdrawETH() external onlyOwner {
        payable (owner()).transfer(address(this).balance);
    }
    receive() external payable {}
}