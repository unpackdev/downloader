// SPDX-License-Identifier: MIT

pragma solidity >=0.4.0 <0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }


    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }
    
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}


contract StakingToken is Ownable {
    
    //initializing safe computations
    using SafeMath for uint;

    IERC20 public contractAddress;
    uint public stakingPool;
    uint public stakeholdersIndex;
    uint public totalStakes;
    uint private setTime;
    uint public minimumStakeValue;
    
    uint rewardToShare;

    struct Referrals {
        uint referralcount;
        address[] referredAddresses;    
    }
    
    struct ReferralBonus {
        uint uplineProfit;
    }
    
    struct Stakeholder {
         bool staker;
         uint id;
    }

    modifier validatStake(uint _stake, address referree) {
        require(_stake >= minimumStakeValue, "Amount is below minimum stake value.");
        require(contractAddress.balanceOf(msg.sender) >= _stake, "Must have enough balance to stake");
        require(referree != address(0), "Referee is zero address");
        require(
            contractAddress.allowance(msg.sender, address(this)) >= _stake, 
            "Must approve tokens before staking"
        );
        _;
    }
    
    mapping (address => Stakeholder) public stakeholders;
    mapping (uint => address) public stakeholdersReverseMapping;
    mapping(address => uint256) private stakes;
    mapping(address => address) public addressThatReferred;
    mapping(address => bool) private exist;
    mapping(address => uint256) private rewards;
    mapping(address => Referrals) private referral;
    mapping(address => ReferralBonus) public bonus;
    mapping(address => uint256) private time;
    mapping(address => bool) public registered;

    constructor(IERC20 _contractAddress) {
        contractAddress = _contractAddress;
        stakingPool = 0;
        stakeholdersIndex = 0;
        totalStakes = 0;
        totalStakes = 0;
        setTime = 0;
        rewardToShare = 0;
        minimumStakeValue = 1 ether;
        
       
        // Add deployer a stakeholder
        stakeholders[msg.sender].staker = true;    
        stakeholders[msg.sender].id = stakeholdersIndex;
        stakeholdersReverseMapping[stakeholdersIndex] = msg.sender;
        stakeholdersIndex = stakeholdersIndex++;
        stakes[msg.sender] = stakes[msg.sender].add(0);
        totalStakes = totalStakes.add(0);
        registered[msg.sender] = true;
    }
    
     /* referree bonus will be added to his reward automatically*/
    function addUplineProfit(address _stakeholderAddress, uint _amount) private  {
        require(_amount > 0, "Can not increment amount by zero");
        bonus[_stakeholderAddress].uplineProfit =  bonus[_stakeholderAddress].uplineProfit.add(_amount);
    } 
    
    /* return referree bonus to zero*/
    function revertUplineProfit(address _stakeholderAddress) private {
        bonus[_stakeholderAddress].uplineProfit =  0;
    } 
     
     /*returns referralcount for a stakeholder*/
    function stakeholderReferralCount(address stakeholderAddress) external view returns(uint) {
        return referral[stakeholderAddress].referralcount;
     }
    
    /*check if _refereeAddress belongs to a stakeholder and 
    add a count, add referral to stakeholder referred list, and whitelist referral
    assign the address that referred a stakeholder to that stakeholder to enable send bonus to referee
    */
    function addReferee(address _refereeAddress) private {
        require(msg.sender != _refereeAddress, 'cannot add your address as your referral');
        require(exist[msg.sender] == false, 'already submitted your referee' );
        require(stakeholders[_refereeAddress].staker == true, 'address does not belong to a stakeholders');

        referral[_refereeAddress].referralcount =  referral[_refereeAddress].referralcount.add(1);   
        referral[_refereeAddress].referredAddresses.push(msg.sender);
        addressThatReferred[msg.sender] = _refereeAddress;
        exist[msg.sender] = true;
    }
    
    /*returns stakeholders Referred List
    */
    function stakeholdersReferredList(address stakeholderAddress) view external returns(address[] memory){
      return referral[stakeholderAddress].referredAddresses;
    }
    
    function bal(address addr) public view returns(uint) {
        return contractAddress.balanceOf(addr);
    }
    
    function approvedTokenBalance(address _sender) external view returns(uint) {
        return contractAddress.allowance(_sender, address(this));
    }
    
    function newStake(uint _stake, address referree) external validatStake(_stake, referree) {
        require(
            stakes[msg.sender] == 0 && 
            !registered[msg.sender], 
            "Already a stakeholder"
        );

        addStakeholder(msg.sender); 
        uint registerCost = registrationAndFirstStakeCost(_stake);
        uint stakeToPool = _stake.sub(registerCost);
        stakingPool = stakingPool.add(stakeToPool);
        stakes[msg.sender] = stakes[msg.sender].add(registerCost);
        totalStakes = totalStakes.add(registerCost);
        registered[msg.sender] = true;

        // Aprrove tokens before calling transferFrom
        contractAddress.transferFrom(msg.sender, address(this), _stake);
        addReferee(referree);
    }
    
    function stake(uint _stake, address referree) external validatStake(_stake, referree) { 
        require(
            stakes[msg.sender] > 0 && 
            registered[msg.sender], 
            "Not a stakeholder, use the newStake method to stake"
        );
        // check previous stake balance
        uint previousStakeBalance = stakes[msg.sender];

        uint availableTostake = calculateStakingCost(_stake);
        uint stakeToPool2 = _stake.sub(availableTostake);
        stakingPool = stakingPool.add(stakeToPool2);
        stakes[msg.sender] = previousStakeBalance.add(availableTostake);
        totalStakes = totalStakes.add(availableTostake);
        contractAddress.transferFrom(msg.sender, address(this), _stake);
    }
    
     function stakeOf(address _stakeholder) external view returns(uint256) {
        return stakes[_stakeholder];
    }
    
     function removeStake(uint _stake) external {
        require(stakes[msg.sender] > 0, 'stakes must be above 0');
        stakes[msg.sender] = stakes[msg.sender].sub(_stake);
         if(stakes[msg.sender] == 0){
             removeStakeholder(msg.sender);
         }
        uint stakeToReceive = calculateUnstakingCost(_stake);
        uint stakeToPool = _stake.sub(stakeToReceive);
        stakingPool = stakingPool.add(stakeToPool);
        totalStakes = totalStakes.sub(_stake);
        rewards[msg.sender] = 0;
        contractAddress.transfer(msg.sender, stakeToReceive);
    }
    
    function addStakeholder(address _stakeholder) private {
        if(stakeholders[_stakeholder].staker == false) {
            stakeholders[_stakeholder].staker = true;    
            stakeholders[_stakeholder].id = stakeholdersIndex;
            stakeholdersReverseMapping[stakeholdersIndex] = _stakeholder;
            stakeholdersIndex = stakeholdersIndex.add(1);
        }
    }
   
    function removeStakeholder(address _stakeholder) private  {
        if (stakeholders[_stakeholder].staker == true) {
            // get id of the stakeholders to be deleted
            uint swappableId = stakeholders[_stakeholder].id;
            
            // swap the stakeholders info and update admins mapping
            // get the last stakeholdersReverseMapping address for swapping
            address swappableAddress = stakeholdersReverseMapping[stakeholdersIndex -1];
            
            // swap the stakeholdersReverseMapping and then reduce stakeholder index
            stakeholdersReverseMapping[swappableId] = stakeholdersReverseMapping[stakeholdersIndex - 1];
            
            // also remap the stakeholder id
            stakeholders[swappableAddress].id = swappableId;
            
            // delete and reduce admin index 
            delete(stakeholders[_stakeholder]);
            delete(stakeholdersReverseMapping[stakeholdersIndex - 1]);
            stakeholdersIndex = stakeholdersIndex.sub(1);
        }
    }
    
    function setRewardToShareWeekly(uint _value) external onlyOwner() {
        require(block.timestamp > setTime, 'wait 24hrs from last call');
        setTime = block.timestamp.add(_value);
        rewardToShare = stakingPool.div(2);
        stakingPool = stakingPool.sub(rewardToShare);
    }
    
    function getRewardToShareWeekly() external view returns(uint) {
        return stakingPool;
    }
    
    function getRewards() external returns(uint) {
        require(exist[msg.sender], 'address does not belong to a stakeholders');
        require(rewardToShare > 0, 'no reward to share at this time');
        require(block.timestamp > time[msg.sender], 'can only call this function once a week');
        time[msg.sender] = block.timestamp + 8 days;
        uint256 reward = calculateReward(msg.sender);
        
        uint removeFromReward = reward.mul(5).div(100);
        uint userRewardAfterUpLineBonus = reward.sub(removeFromReward);
        address addr = addressThatReferred[msg.sender];
        addUplineProfit(addr, removeFromReward);
        rewards[msg.sender] = rewards[msg.sender].add(userRewardAfterUpLineBonus);
        
        rewards[msg.sender] = rewards[msg.sender].add(reward);
        return rewards[msg.sender];
    }
    
     function getReferralBonus() external {
        require(stakeholders[msg.sender].staker == true, 'address does not belong to a stakeholders');
        require(bonus[msg.sender].uplineProfit > 0, 'you do not have any bonus');
        uint bonusToGet = bonus[msg.sender].uplineProfit;
        rewards[msg.sender] = rewards[msg.sender].add(bonusToGet);
        revertUplineProfit(msg.sender);
    }
    
    /* return will converted to ether in frontend*/
    function rewardOf(address _stakeholder) external view returns(uint256){
        return rewards[_stakeholder];
    }
    
    function calculateReward(address _stakeholder) internal view returns(uint256) {
        return ((stakes[_stakeholder].mul(rewardToShare)).div(totalStakes));
    }
    
    function registrationAndFirstStakeCost(uint256 _stake) private pure returns(uint) {
        uint cost =  (_stake).mul(20);
        uint percent = cost.div(100);
        uint availableForstake = _stake.sub(percent);
        return availableForstake;
    }
    
     /*skaing cost 10% */
    function calculateStakingCost(uint256 _stake) private pure returns(uint availableForstake) {
        uint stakingCost =  (_stake).mul(10);
        uint percent = stakingCost.div(100);

        availableForstake = _stake.sub(percent);
        return availableForstake;
    }
    
    /*unskaing cost 20% */
    function calculateUnstakingCost(uint _stake) private pure returns(uint ) {
        uint unstakingCost =  (_stake).mul(20);
        uint percent = unstakingCost.div(100);
        uint stakeReceived = _stake.sub(percent);
        return stakeReceived;
    }
    
    function withdrawReward() public {
        require(rewards[msg.sender] > 0, 'reward balance must be above 0');
        require(stakeholders[msg.sender].staker == true, 'address does not belong to a stakeholders');
        uint256 reward = rewards[msg.sender];
        contractAddress.transfer(msg.sender, reward);
        rewards[msg.sender] = 0;
    }
}