// Rizencoin is a both deflationary and inflationary currency, designed to reward holders & stakers , pump price, and for sound economy. 
// Rizen is a community-driven Defi project with unique staking & holding model.

pragma solidity ^0.5.17;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address who) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
    function approve(address spender, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library SafeMath {
    function add(uint a, uint b) public pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    
    function sub(uint a, uint b) public pure returns (uint c) {
        require(b <= a); 
        c = a - b; 
    } 
    
    function mul(uint a, uint b) public pure returns (uint c) {
        c = a * b; 
        require(a == 0 || c / a == b); 
    } 
    
    function div(uint a, uint b) public pure returns (uint c) { 
        require(b > 0);
        c = a / b;
    }
}

contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }
}

contract ERC20Detailed is IERC20 {

    string private _name;
    string private _symbol;
    uint8 private _decimals;
    
    constructor(string memory name, string memory symbol, uint8 decimals) public {
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
    }
    
    function name() public view returns(string memory) {
        return _name;
    }
    
    function symbol() public view returns(string memory) {
        return _symbol;
    }
    
    function decimals() public view returns(uint8) {
        return _decimals;
    }
}

contract RizenCoin is ERC20Detailed, Ownable {
    using SafeMath for uint256;
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowed;
    
    uint256 public constant ONE_WEEK = 7 days;
    
    mapping (address => uint256) private _lastWeeklyRewardDate;
    
    // bool _isStakingStarted = false;
    // address _stakingContract;
    mapping (address => uint256) private _stakes;
    mapping (address => uint256) private _stakeRewardsPaid;
    uint256 _totalStaked = 0;
    uint256 _totalStakingRewardAmount = 0;
    uint256 _totalStakingRewardPaid = 0;

    string constant tokenName = "Rizen Coin";
    string constant tokenSymbol = "RZN";
    uint8  constant tokenDecimals = 18;
    uint256 _totalSupply = 5000 * (10 ** 18); // 5000
    
    event Staked(address account, uint256 amount);
    event Unstaked(address account, uint256 amount);
    event RewardWithdrawn(address account, uint256 amount);
    
    constructor() public ERC20Detailed(tokenName, tokenSymbol, tokenDecimals) {
        _balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }
    
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }
    
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }
    
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowed[owner][spender];
    }
    
    function transfer(address to, uint256 value) public returns (bool) {
        _transfer(msg.sender, to, value);
        emit Transfer(msg.sender, to, value);
        return true;
    }
    
    function approve(address spender, uint256 value) public returns (bool) {
        require(spender != address(0));
        _allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }
    
    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        _transfer(from, to, value);
        _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);
        return true;
    }
    
    function _transfer(address from, address to, uint256 value) internal {
        require(to != address(0));
        _balances[from] = _balances[from].sub(value);
        
        uint256 tax = value.div(100); // 1%
        uint256 withoutTax = value.sub(tax);
        
        _totalStakingRewardAmount = _totalStakingRewardAmount.add(tax);
        _balances[address(this)] = _balances[address(this)].add(tax); // all the taxes will be stored on this contract
        _balances[to] = _balances[to].add(withoutTax);
        
        emit Transfer(from, address(this), tax);
        emit Transfer(from, to, withoutTax);
    }
    
    /*
        Staking logic and functions
    */
    
    function totalStaked() public view returns (uint256) {
        return _totalStaked;
    }

    function stakesOf(address account) public view returns (uint256) {
        return _stakes[account];
    }
    
    function stakingRewardAmount() public view returns (uint256) {
        return _totalStakingRewardAmount.sub(_totalStakingRewardPaid);
    }
    
    function rewardsOnPoolOf(address account) public view returns (uint256) {
        uint256 rewards = _totalStakingRewardAmount.mul(_stakes[account]).div(_totalStaked);
        if (rewards >= _stakeRewardsPaid[account]) {
            uint256 rewardsForWithdraw = rewards.sub(_stakeRewardsPaid[account]);
            return rewardsForWithdraw;
        } else {
            return 0;
        }
    }
    
    function paidRewardsOf(address account) public view returns (uint256) {
        return _stakeRewardsPaid[account];
    }
    
    function stake(uint256 amount) external {
        _balances[msg.sender] = _balances[msg.sender].sub(amount);
        _balances[address(this)] = _balances[address(this)].add(amount);
        emit Transfer(msg.sender, address(this), amount);
        
        _stakes[msg.sender] = _stakes[msg.sender].add(amount);
        _totalStaked = _totalStaked.add(amount);
        emit Staked(msg.sender, amount);
    }
    
    function unstake(uint256 amount) external {
        _stakes[msg.sender] = _stakes[msg.sender].sub(amount);
        _totalStaked = _totalStaked.sub(amount);
        _burn(address(this), amount);
        emit Unstaked(msg.sender, amount);
    }
    
    function getStakingRewards() external {
        require(_stakes[msg.sender] > 0, "You need to stake before getting rewards!");
        require(_totalStakingRewardAmount > _totalStakingRewardPaid, "All the staking rewards paid for now, come back later!");

        uint256 rewards = _totalStakingRewardAmount.mul(_stakes[msg.sender]).div(_totalStaked);
        require(rewards > _stakeRewardsPaid[msg.sender], "You earned all the rewards!");
        
        uint256 rewardsForWithdraw = rewards.sub(_stakeRewardsPaid[msg.sender]);
        _stakeRewardsPaid[msg.sender] = _stakeRewardsPaid[msg.sender].add(rewardsForWithdraw);
        _totalStakingRewardPaid = _totalStakingRewardPaid.add(rewardsForWithdraw);
        
        uint256 tax = rewardsForWithdraw.div(100);
        _balances[msg.sender] = _balances[msg.sender].add(rewardsForWithdraw.sub(tax));
        _burn(address(this), tax);
        emit RewardWithdrawn(msg.sender, rewardsForWithdraw);
    }
    
    function addRewardTokens(uint256 amount) external onlyOwner {
        _balances[msg.sender] = _balances[msg.sender].sub(amount);
        _balances[address(this)] = _balances[address(this)].add(amount);
        emit Transfer(msg.sender, address(this), amount);
        
        _totalStakingRewardAmount = _totalStakingRewardAmount.add(amount);
    }
    
    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
    }
    
    function _burn(address account, uint256 amount) internal {
        require(amount != 0);
        _balances[account] = _balances[account].sub(amount);
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }
    
    function _mint(address account, uint256 amount) internal onlyOwner {
        require(account != address(0), "ERC20: mint to the zero address");
        
        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }
    
    function getWeeklyReward() external {
        uint256 currentTime = block.timestamp;
        require(currentTime >= _lastWeeklyRewardDate[msg.sender].add(ONE_WEEK), "You can earn reward only once per week!");
        
        uint256 rewardAmount = _balances[msg.sender].div(100); // 1% from his balance
        require(rewardAmount > 0, "You do not have any tokens in your balance!");
        _mint(msg.sender, rewardAmount);
        _lastWeeklyRewardDate[msg.sender] = currentTime;
    }
}