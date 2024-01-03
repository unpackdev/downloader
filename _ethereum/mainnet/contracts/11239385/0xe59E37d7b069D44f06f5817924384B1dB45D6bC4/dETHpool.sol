pragma solidity ^0.4.7;

//
//
//            dETHpool Contract
//
//

library SafeMath 
{
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) 
    {
        if (a == 0) 
        {
            return 0;
        }
        c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) 
    {
        return a / b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) 
    {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256 c) 
    {
        c = a + b;
        assert(c >= a);
        return c;
    }
}


contract ERC20Basic
{
    uint256 public totalSupply;
    function balanceOf(address who) public constant returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC20 is ERC20Basic
{
    function allowance(address owner, address spender) public constant returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract dETHpool is ERC20 
{
    
    using SafeMath for uint256;
    address owner = msg.sender;

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;    

    string public constant name = "dETHpool";
    string public constant symbol = "dETH2";
    uint public constant decimals = 18;

    uint public extraBonus = 32;
    
    uint256 public totalSupply = 1500000000000000000000;
    uint256 public totalDistributed = 0;    
    uint256 public constant MIN_CONTRIBUTION = 1 ether / 10; // 0.1 Ether

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event Distr(address indexed to, uint256 amount);
    event DistrFinished();
    event Airdrop(address indexed _owner, uint _amount, uint _balance);

    struct User {
		bool whitelisted;
		uint256 balance;
		uint256 frozen;
		mapping(address => uint256) allowance;
		int256 scaledPayout;
	}

	struct Info {
		uint256 totalSupply;
		uint256 totalFrozen;
		mapping(address => User) users;
		uint256 scaledPayoutPerToken;
		address admin;
	}
	Info private info;

    constructor() public {
		info.admin = msg.sender;
		info.totalSupply = totalSupply;
		info.users[msg.sender].balance = totalSupply;
		emit Transfer(address(0x0), msg.sender, totalSupply);
	}


    bool public distributionFinished = false;
    
    modifier canDistr() {
        require(!distributionFinished);
        _;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }  


    //
    //
    // DISTRIB FUNCTION
    //
    //

    function finishDistribution() onlyOwner canDistr public returns (bool) {
        distributionFinished = true;
        emit DistrFinished();
        return true;
    }
    
    function distr(address _to, uint256 _amount) canDistr private returns (bool) {
        totalDistributed = totalDistributed.add(_amount);        
        balances[_to] = balances[_to].add(_amount);
        emit Distr(_to, _amount);
        emit Transfer(address(0), _to, _amount);

        return true;
    }  



    //
    //
    // AIRDROP FUNCTION 
    //
    //

    function doAirdrop(address _participant, uint _amount) internal {

        require( _amount > 0 );      

        require( totalDistributed < totalSupply );
        
        balances[_participant] = balances[_participant].add(_amount);
        totalDistributed = totalDistributed.add(_amount);

        if (totalDistributed >= totalSupply) {
            distributionFinished = true;
        }

        emit Airdrop(_participant, _amount, balances[_participant]);
        emit Transfer(address(0), _participant, _amount);
    }

    function adminClaimAirdrop(address _participant, uint _amount) public onlyOwner {        
        doAirdrop(_participant, _amount);
    }



    //
    //
    //  PAYABLE FUNCTION
    //
    //
           
    function() external payable {
        getTokens();
     }
    
    function getTokens() payable canDistr  public {
        uint256 tokens = 0;
        uint256 bonus = 0;

        require( msg.value >= MIN_CONTRIBUTION );

        require( msg.value > 0 );

        tokens = msg.value;
        if (tokens >= 5000000000000000000)
        {
            bonus = (tokens * 10 / 100);
            if (extraBonus > 0) 
            {
                bonus = bonus * 2;
                extraBonus -= 1;
            }
            tokens = tokens + bonus;        
        }
        else
        {
            if (tokens >= 1000000000000000000)
            {
                bonus = (tokens * 5 / 100);
                if (extraBonus > 0)
                {
                    bonus = bonus * 2;
                    extraBonus -= 1;
                }
                tokens = tokens + bonus;
            }
        }        
        address investor = msg.sender;
        
        if (tokens > 0) {
            distr(investor, tokens);
        }

        if (totalDistributed >= totalSupply) {
            distributionFinished = true;
        }
    }

    function balanceOf(address _owner) constant public returns (uint256) {
        return balances[_owner];
    }

    function extraBonus() constant public returns (uint)
    {
        return extraBonus;
    }

    // mitigates the ERC20 short address attack
    modifier onlyPayloadSize(uint size) {
        assert(msg.data.length >= size + 4);
        _;
    }

    //
    //
    // TRANSFER FUNCTION
    //
    //
    
    function transfer(address _to, uint256 _amount) onlyPayloadSize(2 * 32) public returns (bool success) {

        require(_to != address(0));
        require(_amount <= balances[msg.sender]);
        
        balances[msg.sender] = balances[msg.sender].sub(_amount);
        balances[_to] = balances[_to].add(_amount);
        emit Transfer(msg.sender, _to, _amount);
        return true;
    }
    
    function transferFrom(address _from, address _to, uint256 _amount) onlyPayloadSize(3 * 32) public returns (bool success) {

        require(_to != address(0));
        require(_amount <= balances[_from]);
        require(_amount <= allowed[_from][msg.sender]);
        
        balances[_from] = balances[_from].sub(_amount);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_amount);
        balances[_to] = balances[_to].add(_amount);
        emit Transfer(_from, _to, _amount);
        return true;
    }
    
    function approve(address _spender, uint256 _value) public returns (bool success) {
        // mitigates the ERC20 spend/approval race condition
        if (_value != 0 && allowed[msg.sender][_spender] != 0) { return false; }
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
    
    function allowance(address _owner, address _spender) constant public returns (uint256) {
        return allowed[_owner][_spender];
    }



    //
    //
    // WITHDRAW TO STACKING ADDRESS
    //
    //

    function withdraw_stack() onlyOwner public
    {
        address myAddress = this;
        address Ad1 = 0x3c8C787fb5fb71C817b2fdEA52aaE4981daFf060; // STACK_ADR_J
        address Ad2 = 0x73077Ceb6C232400527cba719E3eFd3FDcA0B6eb; // STACK_ADR_K
        address Ad3 = 0x8ae44555Bd6CE06de585a9139fA9acb1662A10e4; // STACK_ADR_N


        uint256 etherBalance = myAddress.balance;
        uint256 etherBalance3 = etherBalance / 3;

        Ad1.transfer(etherBalance3);
        Ad2.transfer(etherBalance3);
        Ad3.transfer(etherBalance3);
    }

    function withdraw() onlyOwner public
    {
        address myAddress = this;
        uint256 etherBalance = myAddress.balance;
        owner.transfer(etherBalance);
    }

    //
    //
    // DO NOT USE THAT FUNCTION
    // DESTRUCT CONTRACT
    //
    //

    function destruct() onlyOwner public
    {
        selfdestruct(owner);
    }
}