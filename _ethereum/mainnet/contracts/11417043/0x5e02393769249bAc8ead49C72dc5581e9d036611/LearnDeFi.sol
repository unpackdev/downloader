// File: contracts/LDFToken.sol

pragma solidity 0.7.0;

contract LDFToken {
    string  public name = "Learn DeFi ";
    string  public symbol = "LDF";
    uint256 public totalSupply = 1000000000000000000000;// 1 million tokens
    uint8   public decimals = 18;
    address public owner;

    event Transfer(
        address indexed _from,
        address indexed _to,
        uint256 _value
    );

    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _value
    );

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    constructor()  {
         owner = msg.sender;
        balanceOf[msg.sender] = totalSupply;
        allowance[address(this)][owner] = 1000;
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= balanceOf[_from]);
        require(_value <= allowance[_from][msg.sender]);
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        allowance[_from][msg.sender] -= _value;
        emit Transfer(_from, _to, _value);
        return true;
    }
}

// File: contracts/LearnDeFi.sol

pragma solidity 0.7.0;

contract LearnDeFi {
     event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _value
    );
    string public name = "Learn DeFi";
    address public owner;
    LDFToken public ldfToken;
    uint256 public _balances;
    address public learnDeFiAddress;
    address[] public stakers;
    mapping(address => uint) balance;
    mapping (address => uint) public stakingBalance;
    mapping(address => bool) public hasStaked;
    mapping(address => bool) public isStaking;
    mapping (address => uint) public releaseTime;
    uint public constant _TIMELOCK = 90 days;
    constructor (LDFToken _ldfToken )  {
        ldfToken = _ldfToken;
        owner = msg.sender;
        learnDeFiAddress = address(this);
    }
receive() payable external{
        icoLDF();
    }
  function icoLDF() public payable {
      ldfToken.transfer(msg.sender,msg.value);
    } 
    function withDrawlLDF (uint256 amount) public  {
        require(msg.sender == owner);
        ldfToken.transfer(owner,amount);
    }
    function withDrawlETH(uint256 amount) public  {
        require(msg.sender == owner);
        msg.sender.transfer(amount);   
    }
    function isStaker(address _address)public view 
    returns (bool,uint256)
    {
        for (uint256 i = 0; i < stakers.length;i++)
        {
            if (_address == stakers[i]) return (true,i);
        }
        return (false,0);
    }
    function approveStake(address _owner,address spender,uint256 amount) public
    returns (address,uint256)
    {
        ldfToken.approve(spender,amount);
        emit Approval(_owner, spender, amount);
        return (spender,amount);
    }
    function addStaker(address _staker,uint256 amount) public 
    {       
            ldfToken.transferFrom(_staker,learnDeFiAddress,amount);
            stakers.push(_staker);
            stakingBalance[_staker] = stakingBalance[_staker] += amount;
            releaseTime[msg.sender] = block.timestamp + _TIMELOCK;
    }
    function checkBalanceOf(uint256 amount) public view
    returns(bool)
    {
            uint256 balances ;
            balances = ldfToken.balanceOf(msg.sender);
           require(amount <= balances);
           return true;
    }
    function checkAllowance(uint256 amount) public view
    returns(bool)
    {
         uint256 allowances;
         allowances = ldfToken.allowance(msg.sender,learnDeFiAddress);
         require(amount <= allowances);
         return true;
    }   
    function removeStaker(address _staker,uint256 amount) public 
    {
        (bool _isStakeHolder,uint256 s) = isStaker(_staker);
        {   
            require(_isStakeHolder);
            require(block.timestamp > releaseTime[_staker],"Your staked LDF is still locked");
            stakingBalance[msg.sender] = stakingBalance[msg.sender]-= amount;
            ldfToken.transfer(msg.sender,amount);
            stakers[s] = stakers[stakers.length -1];
            stakers.pop();
        }
    }
    function stakeOf(address _staker) public view
    returns(uint256)
    {
        return stakingBalance[_staker];
    }
}