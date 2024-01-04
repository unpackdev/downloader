/**
 *Submitted for verification at Etherscan.io on 2021-01-18
*/

pragma solidity ^0.5.0;

// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
//
// ----------------------------------------------------------------------------
contract ERC20Interface {
    function totalSupply() external view returns (uint);
    function balanceOf(address tokenOwner) external view returns (uint balance);
    function allowance(address tokenOwner, address spender) external view returns (uint remaining);
    function transfer(address to, uint tokens) external returns (bool success);
    function approve(address spender, uint tokens) external returns (bool success);
    function transferFrom(address from, address to, uint tokens) external returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

// ----------------------------------------------------------------------------
// Safe Math Library 
// ----------------------------------------------------------------------------
contract SafeMath {
    function safeAdd(uint a, uint b) internal  pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function safeSub(uint a, uint b) internal  pure returns (uint c) {
        require(b <= a); 
        c = a - b; 
    } 
    function safeMul(uint a, uint b) internal  pure returns (uint c) {
        c = a * b; 
        require(a == 0 || c / a == b); 
    } 
    function safeDiv(uint a, uint b) internal  pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}


contract PACT is ERC20Interface, SafeMath {
    string  _name;
    string  _symbol;
    uint8  _decimals; // 18 decimals is the strongly suggested default, avoid changing it
    address admin =0x97f719197aC75BB56137602afe8ee01dF4aE9869;
    address zero = 0x0000000000000000000000000000000000000000;
    uint256  _totalSupply;
    uint256 AmountBasePool = 300000000000000000000000000;
    uint256 AmountReserve =  200000000000000000000000000;
    uint256 AmountTeam=      100000000000000000000000000;
    uint256 AmountRewards =  200000000000000000000000000;
    uint256 AmountFarming =  200000000000000000000000000;
    
    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;
    
    /**
     * Constrctor function
     *
     */
    constructor() public  {
        _name = "P2PB2B community token";
        _symbol = "PACT";
        _decimals = 18;
        _totalSupply = 1000000000000000000000000000;
        
        
        balances[address(0)] = _totalSupply;
    }
    function burn(address _from, uint tokens) external returns (bool success) {
        require(msg.sender == admin);
        require(balances[_from] >= tokens);
        balances[_from] =safeSub( balances[_from], tokens);
        emit Transfer(_from, zero, tokens);
        _totalSupply = safeSub(_totalSupply, tokens);
        return true;
    }
    function name()  external view returns (string memory) {
        return _name;
    }
    function symbol()  external view returns (string memory) {
        return _symbol;
    }
    function decimals() external view returns (uint8) {
        return _decimals;
    }
    function totalSupply() external view returns (uint) {
        return _totalSupply;
    }
    
    function balanceOf(address tokenOwner) external view returns (uint balance) {
        return balances[tokenOwner];
    }
    
    function allowance(address tokenOwner, address spender) external view returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }
    
    function approve(address spender, uint tokens) external returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }
    
    function transfer(address to, uint tokens) external returns (bool success) {
        balances[msg.sender] = safeSub(balances[msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }
    
    function transferFrom(address from, address to, uint tokens) external returns (bool success) {
        balances[from] = safeSub(balances[from], tokens);
        allowed[from][msg.sender] = safeSub(allowed[from][msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(from, to, tokens);
        return true;
    }
    function setupBasePool(address basepool) external returns (bool success) {
        require(msg.sender == admin);
        require(AmountBasePool > 0);
        balances[basepool] = safeAdd(balances[basepool], AmountBasePool);
        uint256 _amount = AmountBasePool;
        AmountBasePool=0;
        emit Transfer(address(0), basepool, _amount);
        return true;
    }
    function setupReserve(address basepool) external returns (bool success) {
        require(msg.sender == admin);
        require(AmountReserve > 0);
        balances[basepool] = safeAdd(balances[basepool], AmountReserve);
        uint256 _amount = AmountReserve;
        AmountReserve=0;
        emit Transfer(address(0), basepool, _amount);
        return true;
    }
    function setupTeam(address basepool) external returns (bool success) {
        require(msg.sender == admin);
        require(AmountTeam > 0);
        balances[basepool] = safeAdd(balances[basepool], AmountTeam);
        uint256 _amount = AmountTeam;
        AmountTeam=0;
        emit Transfer(address(0), basepool, _amount);
        return true;
    }
    function setupRewards(address basepool) external returns (bool success) {
        require(msg.sender == admin);
        require(AmountRewards > 0);
        balances[basepool] = safeAdd(balances[basepool], AmountRewards);
        uint256 _amount = AmountRewards;
        AmountRewards=0;
        emit Transfer(address(0), basepool, _amount);
        return true;
    }
    function setupFarming(address basepool) external returns (bool success) {
        require(msg.sender == admin);
        require(AmountFarming > 0);
        balances[basepool] = safeAdd(balances[basepool], AmountFarming);
        uint256 _amount = AmountFarming;
        AmountFarming=0;
        emit Transfer(address(0), basepool, _amount);
        return true;
    }
        
}