/*
 * Earn Passive Rewards On Cyliq Network
 *
 * https://www.Cycliq.Network
 */


pragma solidity ^0.5.5;



interface IERC20 
{
    function totalSupply() external view returns (uint256);
    function balanceOf(address who) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
    function approve(address spender, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface ApproveAndCallFallBack 
{
    function receiveApproval(address from, uint256 tokens, address token, bytes calldata data) external;
}


library SafeMath 
{
    function mul(uint256 a, uint256 b) internal pure returns (uint256) 
    {
        if (a == 0) 
        {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }
    
    function div(uint256 a, uint256 b) internal pure returns (uint256) 
    {
        uint256 c = a / b;
        return c;
    }
    
    function sub(uint256 a, uint256 b) internal pure returns (uint256) 
    {
        assert(b <= a);
        return a - b;
    }
    
    function add(uint256 a, uint256 b) internal pure returns (uint256) 
    {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
    
    function ceil(uint256 a, uint256 m) internal pure returns (uint256) 
    {
        uint256 c = add(a,m);
        uint256 d = sub(c,1);
        return mul(div(d,m),m);
    }
}


contract ERC20Detailed is IERC20 
{
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

contract CycliqNetwork is ERC20Detailed 
{
    using SafeMath for uint256;
    
    mapping (address => uint256) private balances;
    mapping (address => mapping (address => uint256)) private allowed;
    
    string constant tokenName = "Cycliq Network";
    string constant tokenSymbol = "CYQ"; 
    uint8  constant tokenDecimals = 18;
    uint256 _totalSupply = 0;
  
    address public contractOwner;

    uint256 public totalCycled = 0;
    mapping (address => bool) public isCycling;

    uint256 _totalRewardsPerUnit = 0;
    mapping (address => uint256) private _totalRewardsPerUnit_positions;
    mapping (address => uint256) private _savedRewards;
    
    
    constructor() public payable ERC20Detailed(tokenName, tokenSymbol, tokenDecimals) 
    {
        contractOwner = msg.sender;
        _cycliqSupply(msg.sender, 100000*(10**uint256(tokenDecimals)));
    }
    
    modifier onlyOwner() {
        require(msg.sender == contractOwner, "only owner");
        _;
    }
    
    function totalSupply() public view returns (uint256) 
    {
        return _totalSupply;
    }
    
    function balanceOf(address owner) public view returns (uint256) 
    {
        return balances[owner];
    }
    
    function amountCycled(address owner) external view returns (uint256) 
    {
        return isCycling[owner] ? convertToFullUnits(balances[owner]) : 0;
    }
    
    function convertToFullUnits(uint256 valueWithDecimals) public pure returns (uint256) 
    {
        return valueWithDecimals.div(10**uint256(tokenDecimals));
    }
    
    function allowance(address owner, address spender) public view returns (uint256) 
    {
        return allowed[owner][spender];
    }
    
    function transfer(address to, uint256 value) public returns (bool) 
    {
        _executeTransfer(msg.sender, to, value);
        return true;
    }
    
    function multiTransfer(address[] memory receivers, uint256[] memory values) public
    {
        require(receivers.length == values.length);
        for(uint256 i = 0; i < receivers.length; i++)
            _executeTransfer(msg.sender, receivers[i], values[i]);
    }
    
    function transferFrom(address from, address to, uint256 value) public returns (bool) 
    {
        require(value <= allowed[from][msg.sender]);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(value);
        _executeTransfer(from, to, value);
        return true;
    }
    
    function approve(address spender, uint256 value) public returns (bool) 
    {
        require(spender != address(0));
        allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }
    
    
    function approveAndCall(address spender, uint256 tokens, bytes calldata data) external returns (bool) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, address(this), data);
        return true;
    }
    
    
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) 
    {
        require(spender != address(0));
        allowed[msg.sender][spender] = (allowed[msg.sender][spender].add(addedValue));
        emit Approval(msg.sender, spender, allowed[msg.sender][spender]);
        return true;
    }
    
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) 
    {
        require(spender != address(0));
        allowed[msg.sender][spender] = (allowed[msg.sender][spender].sub(subtractedValue));
        emit Approval(msg.sender, spender, allowed[msg.sender][spender]);
        return true;
    }
    
    
     function _cycliqSupply(address account, uint256 value) internal onlyOwner
    {
        require(value != 0);
        
        uint256 initalBalance = balances[account];
        uint256 newBalance = initalBalance.add(value);
        
        balances[account] = newBalance;
        _totalSupply = _totalSupply.add(value);
        
        emit Transfer(address(0), account, value);
    }
    
    
    function burn(uint256 value) external 
    {
        _burn(msg.sender, value);
    }
    
    function burnFrom(address account, uint256 value) external 
    {
        require(value <= allowed[account][msg.sender]);
        allowed[account][msg.sender] = allowed[account][msg.sender].sub(value);
        _burn(account, value);
    }
    
    function _burn(address account, uint256 value) internal 
    {
        require(value != 0);
        require(value <= balances[account]);
        
        uint256 initalBalance = balances[account];
        uint256 newBalance = initalBalance.sub(value);
        
        balances[account] = newBalance;
        _totalSupply = _totalSupply.sub(value);
        
        //update full units cycled
        if(isCycling[account])
        {
            uint256 fus_total = totalCycled;
            fus_total = fus_total.sub(convertToFullUnits(initalBalance));
            fus_total = fus_total.add(convertToFullUnits(newBalance));
            totalCycled = fus_total;
        }
        
        emit Transfer(account, address(0), value);
    }
    
    
    /*
    *   transfer operation incures a feee of 2%.
    *   the receiver gets 98% of the sent value while 2% is sent to Cycliq staking pool.
    */
    
    function _executeTransfer(address from, address to, uint256 value) private
    {
        require(value <= balances[from]);
        require(to != address(0) && to != from);
        require(to != address(this));
        
        
        //Update senders Cycliq rewards .
        if(isCycling[from])
        {
          updateRewardsFor(from);
        }
        
        //Update receivers Cycliq rewards
        if(isCycling[to])
        {
        updateRewardsFor(to);
        }
        
        uint256 twoPercent = 0;
        twoPercent = value.mul(2).div(100);
            
        //set a minimum Cycliq fee to prevent no-fee-txs due to precision loss
        if(twoPercent == 0 && value > 0)
          twoPercent = 1;
            
        uint256 initalBalance_from = balances[from];
        balances[from] = initalBalance_from.sub(value);
        
        value = value.sub(twoPercent);
        
        uint256 initalBalance_to = balances[to];
        balances[to] = initalBalance_to.add(value);
        
        emit Transfer(from, to, value);
         
        //update full units Cycled
        uint256 fus_total = totalCycled;
        if(isCycling[from])
        {
            fus_total = fus_total.sub(convertToFullUnits(initalBalance_from));
            fus_total = fus_total.add(convertToFullUnits(balances[from]));
        }
        if(isCycling[to])
        {
            fus_total = fus_total.sub(convertToFullUnits(initalBalance_to));
            fus_total = fus_total.add(convertToFullUnits(balances[to]));
        }
        totalCycled = fus_total;
        
        
        if(fus_total > 0)
        {
            uint256 cycliqRewards = twoPercent;
            //split up Cycliq rewards per unit
            uint256 rewardsPerUnit = cycliqRewards.div(fus_total);
            //apply Cycliq rewards
            _totalRewardsPerUnit = _totalRewardsPerUnit.add(rewardsPerUnit);
            balances[address(this)] = balances[address(this)].add(cycliqRewards);
            if(cycliqRewards > 0)
                emit Transfer(msg.sender, address(this), cycliqRewards);
        }
        
    }
    
    //Refreshes Cyclers rewards before balance change
    function updateRewardsFor(address cycler) private
    {
        _savedRewards[cycler] = viewUnpaidRewards(cycler);
        _totalRewardsPerUnit_positions[cycler] = _totalRewardsPerUnit;
    }
    
    //Fetches Cyclers rewards
    function viewUnpaidRewards(address cycler) public view returns (uint256)
    {
        if(!isCycling[cycler])
            return _savedRewards[cycler];
            
        uint256 newRewardsPerUnit = _totalRewardsPerUnit.sub(_totalRewardsPerUnit_positions[cycler]);
        
        uint256 newRewards = newRewardsPerUnit.mul(convertToFullUnits(balances[cycler]));
        return _savedRewards[cycler].add(newRewards);
    }
    
    //pay out unclaimed Cycliq rewards
    function payoutRewards() public
    {
        updateRewardsFor(msg.sender);
        uint256 rewards = _savedRewards[msg.sender];
        require(rewards > 0 && rewards <= balances[address(this)]);
        
        _savedRewards[msg.sender] = 0;
        
        uint256 initalBalance_cycler = balances[msg.sender];
        uint256 newBalance_cycler = initalBalance_cycler.add(rewards);
        
        //update full units cycled
        if(isCycling[msg.sender])
        {
            uint256 fus_total = totalCycled;
            fus_total = fus_total.sub(convertToFullUnits(initalBalance_cycler));
            fus_total = fus_total.add(convertToFullUnits(newBalance_cycler));
            totalCycled = fus_total;
        }
        
        //transfer
        balances[address(this)] = balances[address(this)].sub(rewards);
        balances[msg.sender] = newBalance_cycler;
        emit Transfer(address(this), msg.sender, rewards);
    }
    
    function cycle() public { _cycle(msg.sender);  }
    
    function uncycle() public { _uncycle(msg.sender); }
    
    function cycleFor(address cycler) public onlyOwner { _cycle(cycler); }
    
    function uncycleFor(address cycler) public onlyOwner { _uncycle(cycler); }
    
    //Cycle for a target address
    function _cycle(address cycler) private
    {
        require(!isCycling[cycler]);
        updateRewardsFor(cycler);
        isCycling[cycler] = true;
        totalCycled = totalCycled.add(convertToFullUnits(balances[cycler]));
    }
    
    //Uncycle for a target address
    function _uncycle(address cycler) private
    {
        require(isCycling[cycler]);
        updateRewardsFor(cycler);
        isCycling[cycler] = false;
        totalCycled = totalCycled.sub(convertToFullUnits(balances[cycler]));
    }
    
    //withdraw tokens sent to this contract by accident
    function withdrawERC20Tokens(address tokenAddress, uint256 amount) public onlyOwner
    {
        require(tokenAddress != address(this));
        IERC20(tokenAddress).transfer(msg.sender, amount);
    }
    
    
    
}