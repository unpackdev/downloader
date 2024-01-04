// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.0;

contract Ownable {
    address public owner;

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        if (msg.sender == owner) _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        if (newOwner != address(0)) owner = newOwner;
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
library SafeMath {
    function add(uint256 a, uint256 b) public pure returns (uint256 c) {
        c = a + b;
        require(c >= a);
    }

    function sub(uint256 a, uint256 b) public pure returns (uint256 c) {
        require(b <= a);
        c = a - b;
    }

    function mul(uint256 a, uint256 b) public pure returns (uint256 c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }

    function div(uint256 a, uint256 b) public pure returns (uint256 c) {
        require(b > 0);
        c = a / b;
    }
}

contract STAKE_B2U is Ownable {
    using SafeMath for uint256;

    struct StakingInfo {
        uint256 amount;
        uint256 depositDate;
        uint256 rewardPercent;
    }

    uint256 minStakeAmount = 10 * 10**18; 
    uint256 REWARD_DIVIDER = 10**8;
    uint256 UNSTAKE_FEE = 2 * 10**18; 
    uint256 CHANGE_REWARD = 1500000 * 10**18;

    IERC20 stakingToken;
    uint256 rewardPercent; 
    string name = "Staking B2U";

    uint256 ownerTokensAmount;
    address[] internal stakeholders;
    mapping(address => StakingInfo[]) internal stakes;

    //  percent value for per second
    //  set 192 if you want 2% per month reward (because it will be divided by 10^8 for getting the small float number)
    //  2% per month = 2 / (30 * 24 * 60 * 60) ~ 0.00000077 (77 / 10^8)
    constructor(IERC20 _stakingToken, uint256 _rewardPercent) public {
        stakingToken = _stakingToken;
        rewardPercent = _rewardPercent;
    }

    event Staked(address staker, uint256 amount);
    event Unstaked(address staker, uint256 amount);

    function changeRewardPercent(uint256 _rewardPercent) public onlyOwner {
        rewardPercent = _rewardPercent;
    }

    function changeMinStakeAmount(uint256 _minStakeAmount) public onlyOwner {
        minStakeAmount = _minStakeAmount;
    }

    function totalStakes() public view returns (uint256) {
        uint256 _totalStakes = 0;
        for (uint256 i = 0; i < stakeholders.length; i += 1) {
            for (uint256 j = 0; j < stakes[stakeholders[i]].length; j += 1)
                _totalStakes = _totalStakes.add(
                    stakes[stakeholders[i]][j].amount
                );
        }
        return _totalStakes;
    }

    function isStakeholder(address _address)
        public
        view
        returns (bool, uint256)
    {
        for (uint256 s = 0; s < stakeholders.length; s += 1) {
            if (_address == stakeholders[s]) return (true, s);
        }
        return (false, 0);
    }

    function addStakeholder(address _stakeholder) internal {
        (bool _isStakeholder, ) = isStakeholder(_stakeholder);
        if (!_isStakeholder) stakeholders.push(_stakeholder);
    }

    function removeStakeholder(address _stakeholder) internal {
        (bool _isStakeholder, uint256 s) = isStakeholder(_stakeholder);
        if (_isStakeholder) {
            stakeholders[s] = stakeholders[stakeholders.length - 1];
            stakeholders.pop();
        }
    }

    function stake(uint256 _amount) public {
        require(_amount >= minStakeAmount);
        require(
            stakingToken.transferFrom(msg.sender, address(this), _amount),
            "Stake required!"
        );
        if (stakes[msg.sender].length == 0) {
            addStakeholder(msg.sender);
        }
        
        uint256 tvl = totalStakes();
        if(tvl < CHANGE_REWARD) {
            stakes[msg.sender].push(StakingInfo(_amount, now, rewardPercent));
            emit Staked(msg.sender, _amount);
        } else {
            stakes[msg.sender].push(StakingInfo(_amount, now, 38));
            emit Staked(msg.sender, _amount);
        }
    }

    function unstake() public {
        uint256 withdrawAmount = 0;
        for (uint256 j = 0; j < stakes[msg.sender].length; j += 1) {
            uint256 amount = stakes[msg.sender][j].amount;
            withdrawAmount = withdrawAmount.add(amount);

            uint256 rewardAmount = amount.mul(
                (now - stakes[msg.sender][j].depositDate).mul(
                    stakes[msg.sender][j].rewardPercent
                )
            );
            rewardAmount = rewardAmount.div(REWARD_DIVIDER);
            withdrawAmount = withdrawAmount.add(rewardAmount.div(100));
        }
        
        uint256 withAmount = withdrawAmount.sub(UNSTAKE_FEE);
        
        require(stakingToken.transfer(owner, UNSTAKE_FEE),  "Not enough tokens in contract!");
        
        require(
            stakingToken.transfer(msg.sender, withAmount),
            "Not enough tokens in contract!"
        );
        delete stakes[msg.sender];
        removeStakeholder(msg.sender);
        emit Unstaked(msg.sender, withdrawAmount);
    }

    function sendTokens(uint256 _amount) public onlyOwner {
        require(
            stakingToken.transferFrom(msg.sender, address(this), _amount),
            "Transfering not approved!"
        );
        ownerTokensAmount = ownerTokensAmount.add(_amount);
    }

    function withdrawTokens(address receiver, uint256 _amount)
        public
        onlyOwner
    {
        ownerTokensAmount = ownerTokensAmount.sub(_amount);
        require(
            stakingToken.transfer(receiver, _amount),
            "Not enough tokens on contract!"
        );
    }
   
       
        function dailyStakeRewards() public view returns (uint256) {
        uint256 _amount = 0;
        uint256 _rewardPercent = 0;
        uint256 _depositeDate = 0 ;
        uint256 _rewardAmount = 0;
        for (uint256 i = 0; i < stakeholders.length; i += 1) {
            for (uint256 j = 0; j < stakes[stakeholders[i]].length; j += 1)
                _amount = _amount.add(
                    stakes[stakeholders[i]][j].amount
                );
            for (uint256 j = 0; j < stakes[stakeholders[i]].length; j += 1)
                _rewardPercent = _rewardPercent.add(
                    stakes[stakeholders[i]][j].rewardPercent
                );
            for (uint256 j = 0; j < stakes[stakeholders[i]].length; j += 1)
                _depositeDate = _depositeDate.add(
                    stakes[stakeholders[i]][j].depositDate
                );   
            uint256 _rewardcalculation = _amount.mul((now - _depositeDate).mul(
                _rewardPercent));
                _rewardAmount =_rewardcalculation.div(REWARD_DIVIDER); 
                 
        }   
    
        return _rewardAmount;
    }
}