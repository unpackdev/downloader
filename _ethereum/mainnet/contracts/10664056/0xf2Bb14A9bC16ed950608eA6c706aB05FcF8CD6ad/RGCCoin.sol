pragma solidity >=0.6.0 < 0.8.0;

contract Owned { 
    address public owner; 

    event OwnershipTransferred(address indexed _from, address indexed _to);
 
    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner { 
        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner; 
    } 
}


contract RGCCoin is Owned { // ERC-20 
    
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed tokenOwner, address indexed spender, uint value);
    event FrozenFunds(address indexed, bool frozen);
    
    string public constant name = "RGC Coin";   
    string public constant symbol = "RGC"; 
    uint8 public constant decimals = 18;
    
    mapping (address => uint) balances;
    mapping (address => bool) freezed;
    mapping (address => mapping (address => uint)) allowed; 
    
    uint256 private totalSupply = 10000;
 
   constructor() public { 
        balances[owner] = totalSupply; 
    }
    
    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(!freezed[msg.sender]);
        require(!freezed[_to]);
        if (balances[msg.sender] >= _value && _value > 0) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            emit Transfer(msg.sender, _to, _value);
            return true;
        } else { 
            return false;  
        }
    }
    
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
            //same as above. Replace this line with the following if you want to protect against wrapping uints. 
        require(!freezed[_from]);
        require(!freezed[_to]);
        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0) {
            balances[_to] += _value; 
            balances[_from] -= _value;
            allowed[_from][msg.sender] -= _value;
            emit Transfer(_from, _to, _value);
            return true;
        } else { 
            return false;
        }
    }  
    
    function balanceOf(address _address)public view returns (uint256 balance) { 
        return balances[_address];
    }
    
    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
    
    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
      return allowed[_owner][_spender];
    } 
       
    function getTotalSupply() public view returns (uint256) {
        require(msg.sender == owner);
        return totalSupply;   
    }
    
    function addTotalSupply(uint256 _value) public returns (bool success) {
         if(owner == msg.sender){ 
            totalSupply += _value;
            balances[owner] += _value; 
            emit Transfer(address(0), owner, _value);
            return true;
         }else{
            return false;
         } 
    }  
    
    function freezeAccount(address _address, bool _freeze) public onlyOwner returns (bool success) {
        freezed[_address] = _freeze;
        emit FrozenFunds(_address, _freeze);
        return true;
    }
    
    function freezedOf(address _address)public view returns (bool isFreezed) { 
        return freezed[_address];
    } 
   
}