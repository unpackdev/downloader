// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

abstract contract Context 
{
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}


contract Ownable is Context {
    address private _owner;
    address private _previousOwner;

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

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
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

    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }


    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }


    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }


    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }


    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }


    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}


interface IUniswapV2Factory 
{
    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function createPair(address tokenA, address tokenB) external returns (address pair);
}



interface IUniswapV2Pair {
    function factory() external view returns (address);
}


interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function addLiquidityETH(address token, uint amountTokenDesired, uint amountTokenMin, uint amountETHMin, address to, uint deadline) external payable returns (uint amountToken, uint amountETH, uint liquidity);
}


interface IUniswapV2Router02 is IUniswapV2Router01 
{
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}



contract HerosStaking is Ownable 
{
    using SafeMath for uint256;
    address public tokenAddress;
    address[] internal stakeholders;
    uint256 public rewardDistributionIndex = 0;
    bool stakingOpen = true;
    uint256 public _totalStakes = 0;
    uint256 private uintTime = 1 days;
    uint256 public totalRewardDistributed = 0;
    IERC20 token;
    mapping(address => uint256) internal stakes; // staked amount
    mapping(address => uint256) internal stakingTimestamp; //when tokens were staked. 
    mapping(address => uint256) internal stakingPackage; //staking for how much time. 
    mapping(uint256 => uint256) internal packages;

    constructor(address _tokenAddress)
    {
        packages[1*uintTime] = 1;        
        token = IERC20(tokenAddress);
        tokenAddress = _tokenAddress;
    }


    function availableTokens() public view returns(uint256)
    {
        return token.balanceOf(address(this));
    }


    function createStake(uint256 _stake, uint256 _stakingPackage) external
    {
        _stakingPackage = 0;
        bool _canStake = canStake(_stake, _stakingPackage, msg.sender);
        require(_canStake, "Cannot Stake");
        token.transferFrom(msg.sender, address(this), _stake);
        _stakingPackage = _stakingPackage * uintTime;
        addStakeholder(msg.sender, _stake, _stakingPackage);
        _totalStakes = _totalStakes.add(_stake);
    }



    function canStake(uint256 _stake, uint256 _stakingPackage, address account) 
    public view returns (bool b)
    {
        if(packages[_stakingPackage]>0 
        && _stake <= token.balanceOf(account) 
        && stakingOpen 
        && stakes[account] == 0 
        && _stake > 0)
        {
            return true;
        }
        else
        {
            return false;
        }
    }


    function setApyPercentage(uint256 _percentage) public onlyOwner
    {
        packages[0] =  _percentage;
    }


    /**
     * @notice A method for a stakeholder to remove a stake.
     * @param _stake The size of the stake to be removed.
     */

    function removeSomeStake(uint256 _stake) public
    {
        require(_stake<=stakes[msg.sender], "Exceeding stake amount");

        stakes[msg.sender] = stakes[msg.sender].sub(_stake);
        if(stakes[msg.sender] == 0) 
        { 
            removeStakeholder(msg.sender); 
        }

        uint256 period = stakingPackage[msg.sender];
        uint256 stakinTimestamp = stakingTimestamp[msg.sender];

        _totalStakes = _totalStakes.sub(_stake);

        if((stakinTimestamp+period)>block.timestamp)
        {
            uint256 unstakingFee = _stake.mul(5).div(100);
            _stake = _stake.sub(unstakingFee);
        }
        token.transfer(msg.sender, _stake);
    }

    

    function removeAllMyStakes() public    
    {
        uint256 amount = stakes[msg.sender];
        removeSomeStake(amount);
    }

    function stakeOf(address _stakeholder) public view returns(uint256) 
    {
        return stakes[_stakeholder];
    }


    function totalStakes()   public view returns(uint256)
    {
        return _totalStakes;
    }


    function isStakeholder(address _address) public view returns(bool, uint256)
    {
        for(uint256 s = 0; s < stakeholders.length; s++)
        {
            if (_address == stakeholders[s]) return (true, s);
        }
        return (false, 0);
    }


    function addStakeholder(address _stakeholder, uint256 _stake, uint256 _package) private
    {
        require(packages[_package]>0, "Unknown package selected");

        (bool _isStakeholder, ) = isStakeholder(_stakeholder);

        if(!_isStakeholder) 
        {
            stakeholders.push(_stakeholder);
        }

        stakingTimestamp[_stakeholder] = block.timestamp;
        stakingPackage[_stakeholder] = _package;
        stakes[_stakeholder] = _stake;
    }


    function removeStakeholder(address _stakeholder) private
    {
        (bool _isStakeholder, uint256 s) = isStakeholder(_stakeholder);
        if(_isStakeholder)
        {
            stakeholders[s] = stakeholders[stakeholders.length - 1];
            stakeholders.pop();
            stakingTimestamp[_stakeholder] = 0;
            stakingPackage[_stakeholder] = 0;
        } 
    }


    function rewardOf(address _stakeholder) public view returns(uint256)
    {
        (uint256 reward, ) = calculateReward(_stakeholder);
        return reward;
    }


    function calculateReward(address _stakeholder) private view returns(uint256, uint256)
    {
        uint256 stakedAmount = stakes[_stakeholder];
        if(stakedAmount==0) { return (0, 0); }
        uint256 _stakingTimestamp =  stakingTimestamp[_stakeholder];
        if(_stakingTimestamp==0) {return (0, 0); }
        uint256 _currentTimestamp =  block.timestamp;
        uint256 _span = _currentTimestamp.sub(_stakingTimestamp);
        uint256 _stakingPackage = stakingPackage[_stakeholder];
        if(_span<_stakingPackage) { return (0, 0); }
        uint256  _loops = _span/_stakingPackage;
        uint256 rewardPercentage =  packages[_stakingPackage];
        uint256 _reward = stakedAmount.mul(rewardPercentage).mul(_loops).div(100);
        return (_reward, _loops);
    }

  
    // if a holder did not received reward automatically, 
    //holder can call this function to claim reward. 
    event RewardSent(address _address, uint256 _amount, uint256 _timestamp);
    function _withdrawReward(address _stakeholder)  internal 
    {
        (uint256 reward, uint256 loops) = calculateReward(_stakeholder);
        if(reward==0) {return;}
        uint256 myPackage = stakingPackage[_stakeholder];

        stakingTimestamp[_stakeholder] = (stakingTimestamp[_stakeholder]).add(myPackage*loops);

        token.transfer(msg.sender, reward);
        totalRewardDistributed += reward;
        emit RewardSent(_stakeholder, reward, block.timestamp);
    }


    function distributeReward() public 
    {
        if(stakeholders.length==0) {return;}
        if(rewardDistributionIndex==stakeholders.length-1) 
        { 
            rewardDistributionIndex = 0; 
        }

        for(uint256 i=rewardDistributionIndex; i<stakeholders.length; i++)
        {
            address account = stakeholders[i];
            (uint256 reward,) = calculateReward(account);
            rewardDistributionIndex = i;
            if(reward==0) 
            { 
                continue; 
            }
            else 
            {
                _withdrawReward(account);
                break;
            }
        }
    }



    function claimReward() public 
    {
        (uint256 reward,) = calculateReward(msg.sender);
        if(reward>0)
        {
            _withdrawReward(msg.sender);
        }
    }

    function setAddress(address _tokenAddress) external onlyOwner{
        token = IERC20(tokenAddress);
        tokenAddress = _tokenAddress;
    }


    function getState() public view returns(uint256, uint256, uint256)     
    {
        return (stakeholders.length, token.balanceOf(address(this)), totalRewardDistributed);
    }
    

}