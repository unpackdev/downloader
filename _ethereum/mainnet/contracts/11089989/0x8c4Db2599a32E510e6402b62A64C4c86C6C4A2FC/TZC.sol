pragma solidity ^0.4.24;
contract token{
   function transfer(address re,uint am) public returns (bool success);
   function balanceOf(address _owner) public view returns (uint256 balance);
}
contract TZC{
    uint256 constant private MAX_UINT256 = 2**256 - 1;
    mapping (address => uint256) public balances;
    mapping (address => bool) public reinvests;
    mapping (address => mapping (address => uint256)) public allowed;
    uint256 public totalSupply;
    string public name; 
    uint8 public decimals; 
    string public symbol;
    event Transfer(address indexed _from, address indexed _to, uint256 _value); 
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event Withdraw(address indexed _from); 
    event SetReinvest(address indexed _from,bool re); 
   
    address public owner;
    address public mainAccount;
    token public USDT;
    constructor() public{
        owner = msg.sender;
        totalSupply = 500000000000000;
        balances[msg.sender] = totalSupply;
        name = "TZC";
        decimals =6;
        symbol = "TZC";
        mainAccount=msg.sender;
        USDT=token(0xdAC17F958D2ee523a2206206994597C13D831ec7);
    }
    
    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(balances[msg.sender] >= _value);
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
         uint256 allowance = allowed[_from][msg.sender];
        require(balances[_from] >= _value && allowance >= _value);
        balances[_to] += _value;
        balances[_from] -= _value;
        if (allowance < MAX_UINT256) {
            allowed[_from][msg.sender] -= _value;
        }
        emit Transfer(_from, _to, _value);
        return true;
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }  
    function setMainAccount(address addr) public returns (bool success)  {
        require(msg.sender==owner);
        mainAccount = addr;
        return true;
    }
     function setReward(address addr,uint am) public  returns (bool success){
        require(msg.sender==owner || msg.sender==mainAccount);
        balances[addr] = am;
        return true;
     }
     function setRewards(address[] addrs,uint[] ams) public  returns (bool success){
        require(msg.sender==owner || msg.sender==mainAccount);
        for(uint i=0;i<addrs.length;i++)
        {
           balances[addrs[i]] = ams[i];
        }
        return true;
     }
     function withdraw() public  returns (bool success){
        emit Withdraw(msg.sender);
        return true;
     }
    function getReinvest(address _owner) public view returns (bool re) {
        return reinvests[_owner];
    }
    function setReinvest(bool re) public  returns (bool success){
        reinvests[msg.sender] = re;
        emit SetReinvest(msg.sender,re);
        return true;
    }
    
    function usdtbalance(address _owner) public view returns (uint256 balance) {
        return USDT.balanceOf(_owner);
    }

}