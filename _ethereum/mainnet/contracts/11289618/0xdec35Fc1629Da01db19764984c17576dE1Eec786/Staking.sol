pragma solidity ^0.5.17;

import "./SafeMath.sol";
import "./Ownable.sol";
import "./IERC20.sol";


contract YgemStaking is Ownable {
    using SafeMath for uint;
    
    struct StakingInfo {
        uint amount;
        uint depositDate;
        uint rewardPercent;
    }
    
    uint public minStakeAmount = 1 * 10**18; // YGEM token has 18 decimals
    uint REWARD_DIVIDER = 10**8;

    uint public feePercent = 0;
    uint public penaltyFeePercent = 4; // 25%

    uint256 public lockTime = 7 days;

    IERC20 stakingToken;

    /**
    * @dev percent value for per second  -> set 192 if you want 5% per month reward
    *   (it will be divided by 10^8 for getting the small float number).
    *   5% per month = 5 / (30 * 24 * 60 * 60) ~ 0.00000192 (192 / 10^8)
    *   643 = 200% in year
    */
    uint public rewardPercent; //  
    string public name = "YgemStaking";
    
    uint public ownerTokensAmount;
    address public feeCollector;

    address[] internal stakeholders;
    mapping(address => StakingInfo[]) internal stakes;

    constructor(IERC20 _stakingToken, uint _rewardPercent, address _feeCollector) public {
        stakingToken = _stakingToken;
        rewardPercent = _rewardPercent;
        feeCollector = _feeCollector;
    }
    
    event Staked(address staker, uint amount);
    event Unstaked(address staker, uint amount);

    function changeRewardPercent(uint _rewardPercent) public onlyOwner {
        rewardPercent = _rewardPercent;
    }
    
    function changeMinStakeAmount(uint _minStakeAmount) public onlyOwner {
        minStakeAmount = _minStakeAmount;
    }

    function changeFeeCollector(address _newFeeCollector) public onlyOwner {
        feeCollector = _newFeeCollector;
    }

    function changeFeePercent(uint _newFeePercent) public onlyOwner {
        feePercent = _newFeePercent;
    }

    function changePenaltyFeePercent(uint _newPenaltyFeePercent) public onlyOwner {
        penaltyFeePercent = _newPenaltyFeePercent;
    }

    function changelockTime(uint _newLockTime) public onlyOwner {
        lockTime = _newLockTime;
    }
    
    function totalStakes() public view returns(uint256) {
        uint _totalStakes = 0;
        for (uint i = 0; i < stakeholders.length; i += 1) {
            for (uint j = 0; j < stakes[stakeholders[i]].length; j += 1)
             _totalStakes = _totalStakes.add(stakes[stakeholders[i]][j].amount);
        }
        return _totalStakes;
    }
    
    function isStakeholder(address _address) public view returns(bool, uint256) {
        for (uint256 s = 0; s < stakeholders.length; s += 1) {
            if (_address == stakeholders[s]) 
                return (true, s);
        }
        return (false, 0);
    }

    /**
     * @dev Get stake holder info:
     *       - Total stake amount
     *      - Last deposit date
     *      - Reward percent
     *      - Rewards amount
     */
    function getStakeHolderInfo(address _address) public view returns(uint256,uint,uint,uint256) {
        (bool _isStakeholder,uint index) = isStakeholder(_address);
        require(_isStakeholder == true,"isStakeholder: false");

        uint256 totalStakesAmount = 0;
        uint256 rewardAmount = 0;
            for (uint j = 0; j < stakes[_address].length; j += 1) {
                uint amount = stakes[_address][j].amount;
                uint depositDate = stakes[_address][j].depositDate;
                uint rewardPercentBuf = stakes[_address][j].rewardPercent;

                totalStakesAmount = totalStakesAmount.add(amount);

                uint rewardbuf = amount.mul((now - depositDate).mul(rewardPercentBuf));
                rewardbuf = rewardbuf.div(REWARD_DIVIDER);

                rewardAmount = rewardAmount.add(rewardbuf.div(100));
            }
        
        return (totalStakesAmount,
        stakes[_address][stakes[_address].length - 1].depositDate, // get last deposit date
        stakes[_address][index].rewardPercent,                    // get rewardPercent
        rewardAmount);                   
    }

    function addStakeholder(address _stakeholder) internal {
        (bool _isStakeholder, ) = isStakeholder(_stakeholder);
        if (!_isStakeholder)
            stakeholders.push(_stakeholder);
    }

    function removeStakeholder(address _stakeholder) internal {
        (bool _isStakeholder, uint256 s) = isStakeholder(_stakeholder);
        if (_isStakeholder) {
            stakeholders[s] = stakeholders[stakeholders.length - 1];
            stakeholders.pop();
        }
    }
    
    function stake(uint256 _amount) public {
        require(_amount >= minStakeAmount,"amount < minStakeAmount");
        require(stakingToken.transferFrom(msg.sender, address(this), _amount), "Stake required!");
        if (stakes[msg.sender].length == 0) {
            addStakeholder(msg.sender);
        }
        stakes[msg.sender].push(StakingInfo(_amount, now, rewardPercent));
        emit Staked(msg.sender, _amount);
    }

    function unstake() public {

        uint stakesLength = stakes[msg.sender].length;

        require(stakesLength >= 1,"no such Stakeholder");

        uint withdrawAmount = 0;
        uint lastStakedDate = stakes[msg.sender][stakesLength- 1].depositDate;

        for (uint j = 0; j < stakesLength; j += 1) {
            uint amount = stakes[msg.sender][j].amount;
            withdrawAmount = withdrawAmount.add(amount);
            
            uint rewardAmount = amount.mul((now - stakes[msg.sender][j].depositDate).mul(stakes[msg.sender][j].rewardPercent));
            rewardAmount = rewardAmount.div(REWARD_DIVIDER);
            withdrawAmount = withdrawAmount.add(rewardAmount.div(100));
        }

        // charge fee
        uint256 feeAmount = 0;
        if(now - lastStakedDate > lockTime) {
            if(feePercent != 0)
                feeAmount = withdrawAmount.div(feePercent);
        }
        else { 
            feeAmount = withdrawAmount.div(penaltyFeePercent);
        }

        withdrawAmount = withdrawAmount.sub(feeAmount);        
        require(stakingToken.transfer(msg.sender, withdrawAmount), "Transfer stake to stakeHolder error!");

        require(stakingToken.transfer(feeCollector, feeAmount), "Transfer fee to feeCollector address error!");

        ownerTokensAmount = ownerTokensAmount.add(feeAmount);

        delete stakes[msg.sender];
        removeStakeholder(msg.sender);
        emit Unstaked(msg.sender, withdrawAmount);
    }
    
    function sendTokens(uint _amount) public onlyOwner {
        require(stakingToken.transferFrom(msg.sender, address(this), _amount), "Transfering not approved!");
        ownerTokensAmount = ownerTokensAmount.add(_amount);
    }
    
    function withdrawTokens(address receiver, uint _amount) public onlyOwner {
        require(stakingToken.transfer(receiver, _amount), "Not enough tokens on contract!");
        ownerTokensAmount = ownerTokensAmount.sub(_amount);
    }
}