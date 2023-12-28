pragma solidity ^0.4.26;
    
library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b);
        return c;
    }
 
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0);
        uint256 c = a / b;
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;
        return c;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);
        return c;
    }
 
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

contract ERC20Basic {
    uint public decimals;
    string public    name;
    string public   symbol;
    mapping(address => uint) public balances;
    mapping (address => mapping (address => uint)) public allowed;
    
    address[] users;
    
    uint public _totalSupply;
    function totalSupply() public constant returns (uint);
    function balanceOf(address who) public constant returns (uint);
    function transfer(address to, uint value) public;
    event Transfer(address indexed from, address indexed to, uint value);
}

contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public constant returns (uint);
    function transferFrom(address from, address to, uint value) public;
    function approve(address spender, uint value) public;
    event Approval(address indexed owner, address indexed spender, uint value);
}
 


contract MDPOXToken is ERC20{
    using SafeMath for uint;
    

    address public platformAdmin;
    string public name='MDPOX';
    string public symbol='MDPOX';
    uint256 public decimals=8;
    uint256 public _initialSupply=30000000;
    
    mapping(address=>uint256) public tokenRateArray;
    mapping(address=>uint256) public tokenRateSignArray;
    
 
    bool public tokenExchangeLock=true;
    bool public tokenRedemptionLock=true;
    
    mapping (address => bool) public frozenAccount; 
    
    
    modifier onlyOwner() {
        require(msg.sender == platformAdmin);
        _;
    }

    constructor() public {
        platformAdmin = msg.sender;
        _totalSupply = _initialSupply * 10 ** decimals;
        balances[msg.sender]=_totalSupply;
    }
    

    function  setTokenArrRate(address[] _tokenArrs,uint256[] rates,uint256[] signs) public  onlyOwner returns (bool) {
        for(uint i=0;i<_tokenArrs.length;i++){
            tokenRateArray[_tokenArrs[i]]=rates[i];
            tokenRateSignArray[_tokenArrs[i]]=signs[i];
        }
         return true;
    }
    
    
    function  setTokenRate(address _tokenAddress,uint256 rate,uint256 sign) public  onlyOwner returns (bool) {
         require(rate>=1);
         tokenRateSignArray[_tokenAddress]=sign;
         tokenRateArray[_tokenAddress]=rate;
         return true;
    }
    
    
    function  setTokenExchangeLock(bool _flag) public  onlyOwner returns (bool) {
         tokenExchangeLock=_flag;
         return true;
    }


    function  setTokenRedemptionLock(bool _flag) public  onlyOwner returns (bool) {
         tokenRedemptionLock=_flag;
         return true;
    }

    
     function totalSupply() public constant returns (uint){
         return _totalSupply;
     }
     
      function balanceOf(address _owner) constant returns (uint256 balance) {
            return balances[_owner];
          }
  
        function approve(address _spender, uint _value) {
            allowed[msg.sender][_spender] = _value;
            Approval(msg.sender, _spender, _value);
        }
        
        function approveErc(address _tokenAddress,address _spender, uint _value) onlyOwner{
            ERC20 token =ERC20(_tokenAddress);
            token.approve(_spender,_value);
        }
 
        function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
          return allowed[_owner][_spender];
        }
        
        
       function transfer(address _to, uint _value) public {
            require(!frozenAccount[msg.sender]);
            require(balances[msg.sender] >= _value);
            require(balances[_to].add(_value) > balances[_to]);
            
            balances[msg.sender]=balances[msg.sender].sub(_value);
            balances[_to]=balances[_to].add(_value);
            Transfer(msg.sender, _to, _value);
        }
   
        function transferFrom(address _from, address _to, uint256 _value) public  {
            require(!frozenAccount[_from]);
            require(balances[_from] >= _value);
            require(allowed[_from][msg.sender] >= _value);
            require(balances[_to] + _value > balances[_to]);
          
            balances[_to]=balances[_to].add(_value);
            balances[_from]=balances[_from].sub(_value);
            allowed[_from][msg.sender]=allowed[_from][msg.sender].sub(_value);
            Transfer(_from, _to, _value);
        }
        
    
    function changeAdmin(address _newAdmin) public onlyOwner returns (bool)  {
        require(_newAdmin != address(0));
        
        emit Transfer(platformAdmin,_newAdmin,balances[platformAdmin]);
        
        balances[_newAdmin] = balances[_newAdmin].add(balances[platformAdmin]);
        balances[platformAdmin] = 0;
        platformAdmin = _newAdmin;
        return true;
    }


    function multiWithdraw (address[] users,uint256[] _amount)public onlyOwner returns (bool) {
        for (uint256 i = 0; i < users.length; i++) {
            users[i].transfer(_amount[i]);
        }
        return true;
    }
    
    function multiWithdrawToken (address _tokenAddress,address[] users,uint256[] _tokenAmount)public onlyOwner returns (bool) {
         ERC20 token =ERC20(_tokenAddress);
         for (uint256 i = 0; i < users.length; i++) {
             token.transfer(users[i],_tokenAmount[i]);
         }
        return true;
    }
   

    function freeze(address _target,bool _freeze) public onlyOwner returns (bool) {
        require(_target != address(0));
        frozenAccount[_target] = _freeze;
        return true;
    }



    function multiFreeze(address[] _targets,bool[] _freezes) public onlyOwner returns (bool) {
        require(_targets.length == _freezes.length);
        uint256 len = _targets.length;
        require(len > 0);
        for (uint256 i = 0; i < len; i++) {
            address _target = _targets[i];
            require(_target != address(0));
            bool _freeze = _freezes[i];
            frozenAccount[_target] = _freeze;
        }
        return true;
    }



    function multiTransfer( address[] _tos, uint256[] _values)public returns (bool) {
        require(!frozenAccount[msg.sender]);
        require(_tos.length == _values.length);
        uint256 len = _tos.length;
        require(len > 0);
        uint256 amount = 0;
        for (uint256 i = 0; i < len; i++) {
            amount = amount.add(_values[i]);
        }
        require(amount <= balances[msg.sender]);
        for (uint256 j = 0; j < len; j++) {
            address _to = _tos[j];
            require(_to != address(0));
            balances[_to] = balances[_to].add(_values[j]);
            balances[msg.sender] = balances[msg.sender].sub(_values[j]);
            emit Transfer(msg.sender, _to, _values[j]);
        }
        return true;
    }
    
    
 
    function getFrozenAccount(address _target)public view returns (bool) {
        require(_target != address(0));
        return frozenAccount[_target];
    }
 
   
    function exChangeToken(address _tokenAddress,uint256 _tokenAmount) public{
        require(tokenRateArray[_tokenAddress]>0);
        require(!frozenAccount[msg.sender]);
        require (tokenExchangeLock) ;
      

        uint256 amount;
         ERC20 token =ERC20(_tokenAddress);
         uint deci=token.decimals();
         if(tokenRateSignArray[_tokenAddress]==1){
             if(decimals>deci){
                 amount=_tokenAmount.div(tokenRateArray[_tokenAddress]).mul(10 ** (decimals.sub(deci)));
             }else if(decimals<deci){
                 amount=_tokenAmount.div(tokenRateArray[_tokenAddress]).div(10 ** (deci.sub(decimals)));
             }else{
                 amount=_tokenAmount.div(tokenRateArray[_tokenAddress]);
             }
         }else  if(tokenRateSignArray[_tokenAddress]==2){
             if(decimals>deci){
                 amount=_tokenAmount.mul(tokenRateArray[_tokenAddress]).mul(10 ** (decimals.sub(deci)));
             }else if(decimals<deci){
                 amount=_tokenAmount.mul(tokenRateArray[_tokenAddress]).div(10 ** (deci.sub(decimals)));
             }else{
                 amount=_tokenAmount.mul(tokenRateArray[_tokenAddress]);
             }
         }else{
             throw;
         }

        token.transferFrom(msg.sender,this,_tokenAmount);
        balances[platformAdmin] = balances[platformAdmin].sub(amount);
        balances[msg.sender] = balances[msg.sender].add(amount);
 
        emit Transfer(platformAdmin, msg.sender, amount);
    }
    
    function redemptionToken(address _tokenAddress,uint256 amount) public{
        require(tokenRateArray[_tokenAddress]>0);
        require(!frozenAccount[msg.sender]);
        require (tokenRedemptionLock) ;
       

        uint256 tokenAmount;
         ERC20 token =ERC20(_tokenAddress);
         uint deci=token.decimals();
         if(tokenRateSignArray[_tokenAddress]==1){
             if(decimals>deci){
                 tokenAmount=amount.mul(tokenRateArray[_tokenAddress]).div(10 ** (decimals.sub(deci)));
             }else if(decimals<deci){
                 tokenAmount=amount.mul(tokenRateArray[_tokenAddress]).mul(10 ** (deci.sub(decimals)));
             }else{
                 tokenAmount=amount.mul(tokenRateArray[_tokenAddress]);
             }
         }else  if(tokenRateSignArray[_tokenAddress]==2){
             if(decimals>deci){
                 tokenAmount=amount.div(tokenRateArray[_tokenAddress]).div(10 ** (decimals.sub(deci)));
             }else if(decimals<deci){
                 tokenAmount=amount.div(tokenRateArray[_tokenAddress]).mul(10 ** (deci.sub(decimals)));
             }else{
                 tokenAmount=amount.div(tokenRateArray[_tokenAddress]);
             }
         }else{
             throw;
         }
         
     
        token.transfer(msg.sender,tokenAmount);
        balances[platformAdmin] = balances[platformAdmin].add(amount);
        balances[msg.sender] = balances[msg.sender].sub(amount);
 
        emit Transfer(msg.sender,platformAdmin,amount);
    }
}