// SPDX-License-Identifier: MIT
pragma solidity >= 0.5.1;

import "./Ownable.sol";
import "./TransferHelper.sol";
import "./ITomiPair.sol";
import "./ITomiFactory.sol";
import "./ITomiGovernance.sol";
import "./SafeMath.sol";
import "./ConfigNames.sol";
import "./ITomiConfig.sol";
import "./IERC20.sol";
import "./ITomiStaking.sol";

interface ITomiPlatform {
    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts) ;
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);
}

contract TomiPool is Ownable {

    using SafeMath for uint;
    address public TOMI;
    address public FACTORY;
    address public PLATFORM;
    address public WETH;
    address public CONFIG;
    address public GOVERNANCE;
    address public FUNDING;
    address public LOTTERY;
    address public STAKING;
    uint public totalReward;
    
    struct UserInfo {
        uint rewardDebt; // Reward debt. 
        uint rewardEarn; // Reward earn and not minted
    }
    
    event ClaimReward(address indexed user, address indexed pair, address indexed rewardToken, uint amountTOMI);
    event AddReward(address indexed pair, uint amount);

    mapping(address => mapping (address => UserInfo)) public users;
    
    mapping (address => uint) public pairAmountPerShare;
    mapping (address => uint) public pairReward;
    
     function initialize(address _TOMI, address _WETH, address _FACTORY, address _PLATFORM, address _CONFIG, address _GOVERNANCE, address _FUNDING, address _LOTTERY, address _STAKING) external onlyOwner {
        TOMI = _TOMI;
        WETH = _WETH;
        FACTORY = _FACTORY;
        PLATFORM = _PLATFORM;
        CONFIG = _CONFIG;
        GOVERNANCE = _GOVERNANCE;
        FUNDING = _FUNDING;
        LOTTERY = _LOTTERY;
        STAKING = _STAKING;
    }
    
    function upgrade(address _newPool, address[] calldata _pairs) external onlyOwner {
        IERC20(TOMI).approve(_newPool, totalReward);
        for(uint i = 0;i < _pairs.length;i++) {
            if(pairReward[_pairs[i]] > 0) {
                TomiPool(_newPool).addReward(_pairs[i], pairReward[_pairs[i]]);
                totalReward = totalReward.sub(pairReward[_pairs[i]]);
                pairReward[_pairs[i]] = 0;
            }
        }
    }

    function newStakingSettle(address _STAKING) external onlyOwner {
        require(_STAKING != STAKING, "STAKING ADDRESS IS THE SAME");
        require(_STAKING != address(0), "STAKING ADDRESS IS DEFAULT ADDRESS");
        STAKING = _STAKING;
    }
    
    function addRewardFromPlatform(address _pair, uint _amount) external {
       require(msg.sender == PLATFORM, "TOMI POOL: FORBIDDEN");
        uint balanceOf = IERC20(TOMI).balanceOf(address(this));
        require(balanceOf.sub(totalReward) >= _amount, 'TOMI POOL: ADD_REWARD_EXCEED');

        uint rewardAmount = ITomiConfig(CONFIG).getConfigValue(ConfigNames.FEE_LP_REWARD_PERCENT).mul(_amount).div(10000);
        _addReward(_pair, rewardAmount);

        uint remainAmount = _amount.sub(rewardAmount);        
        uint fundingAmount = ITomiConfig(CONFIG).getConfigValue(ConfigNames.FEE_FUNDME_REWARD_PERCENT).mul(remainAmount).div(10000);
      
        if(fundingAmount > 0) {
            TransferHelper.safeTransfer(TOMI, FUNDING, fundingAmount);
        }

        remainAmount = remainAmount.sub(fundingAmount);      
        uint lotteryAmount = ITomiConfig(CONFIG).getConfigValue(ConfigNames.FEE_LOTTERY_REWARD_PERCENT).mul(remainAmount).div(10000);

        if(lotteryAmount > 0) {
            TransferHelper.safeTransfer(TOMI, LOTTERY, lotteryAmount);
        }  

        remainAmount = remainAmount.sub(lotteryAmount);
        // uint governanceAmount = ITomiConfig(CONFIG).getConfigValue(ConfigNames.FEE_GOVERNANCE_REWARD_PERCENT).mul(remainAmount).div(10000);
        if(remainAmount > 0) {
            TransferHelper.safeTransfer(TOMI, STAKING, remainAmount);
            ITomiStaking(STAKING).updateRevenueShare(remainAmount);
            // ITomiGovernance(GOVERNANCE).addReward(remainAmount);
        }

        emit AddReward(_pair, rewardAmount);
    }
    
    function addReward(address _pair, uint _amount) external {
        TransferHelper.safeTransferFrom(TOMI, msg.sender, address(this), _amount);
        
        require(ITomiFactory(FACTORY).isPair(_pair), "TOMI POOL: INVALID PAIR");
        _addReward(_pair, _amount);
        
        emit AddReward(_pair, _amount);
    }
    
    function preProductivityChanged(address _pair, address _user) external {
        require(msg.sender == PLATFORM, "TOMI POOL: FORBIDDEN");
        _auditUser(_pair, _user);
    }
    
    function postProductivityChanged(address _pair, address _user) external {
        require(msg.sender == PLATFORM, "TOMI POOL: FORBIDDEN");
        require(ITomiFactory(FACTORY).isPair(_pair), "TOMI POOL: INVALID PAIR");
        
        _updateDebt(_pair, _user);
    }
    
    function _addReward(address _pair, uint _amount) internal {
        pairReward[_pair] = pairReward[_pair].add(_amount);
        uint totalProdutivity = ITomiPair(_pair).totalSupply();
        if(totalProdutivity > 0) {
            pairAmountPerShare[_pair] = pairAmountPerShare[_pair].add(_amount.mul(1e12).div(totalProdutivity));
            totalReward = totalReward.add(_amount);
        }
    }
    
    function _auditUser(address _pair, address _user) internal {
        require(ITomiFactory(FACTORY).isPair(_pair), "TOMI POOL: INVALID PAIR");
    
        uint balance = ITomiPair(_pair).balanceOf(_user);
        uint accAmountPerShare = pairAmountPerShare[_pair];
        UserInfo storage userInfo = users[_user][_pair];
        uint pending = balance.mul(accAmountPerShare).div(1e12).sub(userInfo.rewardDebt);
        userInfo.rewardEarn = userInfo.rewardEarn.add(pending);
        userInfo.rewardDebt = balance.mul(accAmountPerShare).div(1e12);
    }
    
    function _updateDebt(address _pair, address _user) internal {
        uint balance = ITomiPair(_pair).balanceOf(_user);
        uint accAmountPerShare = pairAmountPerShare[_pair];
        users[_user][_pair].rewardDebt = balance.mul(accAmountPerShare).div(1e12);
    }
    
    function claimReward(address _pair, address _rewardToken) external {
        _auditUser(_pair, msg.sender);
        UserInfo storage userInfo = users[msg.sender][_pair];
        
        uint amount = userInfo.rewardEarn;
        pairReward[_pair] = pairReward[_pair].sub(amount);
        totalReward = totalReward.sub(amount);
        require(amount > 0, "NOTHING TO MINT");
        
        if(_rewardToken == TOMI) {
            TransferHelper.safeTransfer(TOMI, msg.sender, amount);
        } else if(_rewardToken == WETH) {
            require(ITomiFactory(FACTORY).isPair(_pair), "TOMI POOL: INVALID PAIR");
            IERC20(TOMI).approve(PLATFORM, amount);
            address[] memory path = new address[](2);
            path[0] = TOMI;
            path[1] = WETH; 
            ITomiPlatform(PLATFORM).swapExactTokensForETH(amount, 0, path, msg.sender, block.timestamp + 1);
        } else {
            require(ITomiFactory(FACTORY).isPair(_pair), "TOMI POOL: INVALID PAIR");
            IERC20(TOMI).approve(PLATFORM, amount);
            address[] memory path = new address[](2);
            path[0] = TOMI;
            path[1] = _rewardToken;
            ITomiPlatform(PLATFORM).swapExactTokensForTokens(amount, 0, path, msg.sender, block.timestamp + 1);
        }
        
        userInfo.rewardEarn = 0;
        emit ClaimReward(msg.sender, _pair, _rewardToken, amount);
    }
    
    function queryReward(address _pair, address _user) external view returns(uint) {
        require(ITomiFactory(FACTORY).isPair(_pair), "TOMI POOL: INVALID PAIR");
        
        UserInfo memory userInfo = users[msg.sender][_pair];
        uint balance = ITomiPair(_pair).balanceOf(_user);
        return balance.mul(pairAmountPerShare[_pair]).div(1e12).add(userInfo.rewardEarn).sub(userInfo.rewardDebt);
    }
}