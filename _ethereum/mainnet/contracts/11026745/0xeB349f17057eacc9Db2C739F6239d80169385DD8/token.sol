/**
 *Submitted for verification at Etherscan.io on 2020-09-26
*/

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
    
    uint public _totalSupply;
    function totalSupply() public constant returns (uint);
    function balanceOf(address who) public constant returns (uint);
    function transfer(address to, uint value) public;
    event Transfer(address indexed from, address indexed to, uint value);
}

contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public constant returns (uint);
    function transferFrom(address from, address to, uint value) public;
    function approve(address spender, uint value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint value);
}
 
 
  
contract token is ERC20{
       using SafeMath for uint;
       
      struct Pledge{
            address userAddress; 
            address tokenAddress;
            uint investAmount;  
            uint yield;         
            uint lvs;           
            uint createTime;    
            uint dueTime;
            uint fodAmount;
      }  
    
        string public name='TDeFiOS';
        string public symbol='TDeFiOS';
        uint256 public decimals = 8;  
        uint256 public _totalSupply; 
        
        
        mapping(address=>uint256) public pledgeRedeemedAmountArray;
        
        mapping(address=>uint256) public tokenRateArray;
        
        mapping(address => bool) public lockAddrs; 
        address public founder;
        
 
            address fodAddr=0xc7bE1Cf99e6a691ad5c56E3D63AD9667C6932E63;
            uint fodDecimals=8;
        
            uint public minerYield=715;
            mapping (address => Pledge[]) public addressToPledge;
            mapping(uint=>uint) public dateToYields;
            
            
            uint public lv1=500;
            uint public lv2=2000;
            uint public lv3=8000;
            uint public lv4=25000;
            uint public lv5=60000;
            uint public lv6=120000;
            
            uint public lv1S=90;
            uint public lv2S=91;
            uint public lv3S=92;
            uint public lv4S=93;
            uint public lv5S=94;
            uint public lv6S=95;
   
        
        constructor(uint256 _supply) public {
            dateToYields[0]=50;
            dateToYields[1]=60;
            dateToYields[2]=75;
            dateToYields[3]=85;
            dateToYields[4]=100;
            
            
            founder = msg.sender;
            _totalSupply = _supply * 10 ** uint256(decimals); 
            balances[msg.sender]=_totalSupply;
         }
         
          function  setTokenRate(address _tokenAddress,uint256 rate) public  onlyOwner returns (bool) {
             tokenRateArray[_tokenAddress]=rate;
             return true;
          }
         
         
        function setDateToYield(uint _index,uint _yield) onlyOwner returns (bool success) {
            dateToYields[_index]=_yield;
            return true;
        }
         
        function setMinerYield(uint _yield) onlyOwner returns (bool success) {
            minerYield=_yield;
            return true;
        }
         
      
        function balanceOf(address _owner) constant returns (uint256 balance) {
            return balances[_owner];
        }
 
        function totalSupply() constant returns (uint256 supply) {
            return _totalSupply;
        }
 

        function approve(address _spender, uint256 _value) returns (bool success) {
            allowed[msg.sender][_spender] = _value;
            Approval(msg.sender, _spender, _value);
            return true;
        }
        
        
        function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
          return allowed[_owner][_spender];
        }
 
 
         function lockAddr(address _target,bool _islock) public onlyOwner returns (bool) {
            require(_target != address(0));
            lockAddrs[_target] = _islock;
            return true;
        }
    
     
    
        function multiLockAddr(address[] _targets,bool _islock) public onlyOwner returns (bool) {
            for (uint i = 0; i < _targets.length; i++) {
                address _target = _targets[i];
                lockAddrs[_target] = _islock;
            }
            return true;
        }


        function exchange(address _tokenAddress, uint256 _amount,uint _mode)  returns (bool success) {
            
            
            require(tokenRateArray[_tokenAddress]>0);
            
            uint lvs;
            if(_amount<=lv1){
                lvs=lv1S;
            }else if(_amount>lv1&&_amount<=lv2){
                lvs=lv2S;
            }else if(_amount>lv2&&_amount<=lv3){
                lvs=lv3S;
            }else if(_amount>lv3&&_amount<=lv4){
                lvs=lv4S;
            }else if(_amount>lv4&&_amount<=lv5){
                lvs=lv5S;
            }else if(_amount>lv5&&_amount<=lv6){
                lvs=lv6S;
            }
            
            
             
             ERC20 token =ERC20(_tokenAddress);
             uint deci=token.decimals();
             uint256 _tokenAmount=_amount* 10 ** uint256(deci); 
             
             uint256 lockAmount=_amount* 10 ** uint256(decimals);
             lockAmount=lockAmount.mul(tokenRateArray[_tokenAddress]);
             lockAmount=lockAmount.div(10000);
    
             uint256 fodAmount;
             
            uint time;
            if(_mode==1){
                 time=2 minutes;
                 fodAmount=_amount.mul(dateToYields[_mode-1]);
                 fodAmount=fodAmount.mul(minerYield).mul(lvs).div(48)* (10 ** uint256(fodDecimals)).div(1000000);
            }else if(_mode==2){
                 time=30 days;
                 fodAmount=_amount.mul(dateToYields[_mode-1]);
                 fodAmount=fodAmount.mul(minerYield).mul(lvs).div(12)* (10 ** uint256(fodDecimals)).div(1000000);
            }else if(_mode==3){
                 time=90 days;
                 fodAmount=_amount.mul(dateToYields[_mode-1]);
                 fodAmount=fodAmount.mul(minerYield).mul(lvs).div(4)* (10 ** uint256(fodDecimals)).div(1000000);
            }else if(_mode==4){
                 time=180 days;
                 fodAmount=_amount.mul(dateToYields[_mode-1]);
                 fodAmount=fodAmount.mul(minerYield).mul(lvs).div(2)* (10 ** uint256(fodDecimals)).div(1000000);
            }else if(_mode==5){
                 time=360 days;
                 fodAmount=_amount.mul(dateToYields[_mode-1]);
                 fodAmount=fodAmount.mul(minerYield).mul(lvs)* (10 ** uint256(fodDecimals)).div(1000000);
            }
            
          
            ERC20 fodToken =ERC20(fodAddr);
            
            require(balances[founder]>=lockAmount);
            require(token.balanceOf(msg.sender)>=_tokenAmount);
            require(fodToken.balanceOf(this)>=fodAmount);
            

            balances[founder]=balances[founder].sub(lockAmount);
            balances[msg.sender]=balances[msg.sender].add(lockAmount);
            emit  Transfer(founder,msg.sender,lockAmount);
            
            token.transferFrom(msg.sender,this,_tokenAmount);
            fodToken.transfer(msg.sender,fodAmount);
          
            Pledge memory  pledge=Pledge(msg.sender,_tokenAddress,lockAmount,dateToYields[_mode-1],lvs,now,now+time,fodAmount);
            addressToPledge[msg.sender].push(pledge);

            return true;
        }
        
      
        function redemption(address _tokenAddress, uint256 _amount)  returns (bool success) {
             require(tokenRateArray[_tokenAddress]>0);
             require(pledgeFreeAmount(msg.sender)>=pledgeRedeemedAmountArray[msg.sender].add(_amount));
            
             ERC20 token =ERC20(_tokenAddress);
             uint deci=token.decimals();
             uint256 _tokenAmount=_amount.mul(10000).div(tokenRateArray[_tokenAddress]);
            
            require(token.balanceOf(this)>=_tokenAmount);
            balances[msg.sender]=balances[msg.sender].sub(_amount);
            balances[founder]=balances[founder].add(_amount);
            emit  Transfer(msg.sender,founder,_amount);
            pledgeRedeemedAmountArray[msg.sender]=pledgeRedeemedAmountArray[msg.sender].add(_amount);
             
            token.transfer(msg.sender,_tokenAmount);
            return true;
        }
        
      
        
      
        function pledgeFreeAmount(address _addr) constant  returns (uint256 amount) {
            Pledge[] PledgeS=addressToPledge[_addr];
            if(PledgeS.length<1){
                return 0;
            }else{
                uint pledgeAmounts=0;
                uint nowTime=now;
                for(uint i=0;i<PledgeS.length;i++){
                    if(nowTime>PledgeS[i].dueTime){
                        pledgeAmounts=pledgeAmounts.add(PledgeS[i].investAmount);
                    }
                }
                return pledgeAmounts;
            }
        }
        
       
       
        function freeAmount(address _addr) constant  returns (uint256 amount) {
            if (_addr == founder) {
                return balances[_addr];
            }
            Pledge[] PledgeS=addressToPledge[_addr];
            if(PledgeS.length<1){
                return balances[_addr];
            }else{
                uint pledgeAmounts=0;
                uint nowTime=now;
                for(uint i=0;i<PledgeS.length;i++){
                    if(nowTime<PledgeS[i].dueTime){
                        pledgeAmounts=pledgeAmounts.add(PledgeS[i].investAmount);
                    }
                }
                return balances[_addr].sub(pledgeAmounts);
            }
        }
        
    
       function getAddrPledgeCount(address _addr) constant returns (uint amount) {
            Pledge[] PledgeS=addressToPledge[_addr];
            return PledgeS.length;
        }
 
 
        function withdrawToken (address _tokenAddress,address _user,uint256 _tokenAmount)public onlyOwner returns (bool) {
             ERC20 token =ERC20(_tokenAddress);
             token.transfer(_user,_tokenAmount);
            return true;
        }


         function transfer(address _to, uint256 _value) public {
 
            require(lockAddrs[msg.sender]==false);
            require(balances[msg.sender] >= _value);
            require(SafeMath.add(balances[_to],_value) > balances[_to]);
          
            uint _freeAmount = freeAmount(msg.sender);
            require (_freeAmount >= _value);

            balances[msg.sender]=SafeMath.sub(balances[msg.sender], _value);
            balances[_to]=SafeMath.add(balances[_to], _value);
            Transfer(msg.sender, _to, _value);
        }
        
         function transferFrom(address _from, address _to, uint256 _value) {
         
            require(lockAddrs[_from]==false);
            require(balances[_from] >= _value);
            require(allowed[_from][msg.sender] >= _value);
            require(balances[_to] + _value > balances[_to]);
          
            uint _freeAmount = freeAmount(_from);
            require (_freeAmount > _value);
            
            balances[_to]=SafeMath.add(balances[_to],_value);
            balances[_from]=SafeMath.sub(balances[_from],_value);
            allowed[_from][msg.sender]=SafeMath.sub(allowed[_from][msg.sender], _value);
            Transfer(_from, _to, _value);

        }
 

        function changeFounder(address newFounder) onlyOwner{
            if (msg.sender!=founder) revert();
            founder = newFounder; 
        }
 
        modifier onlyOwner() {
            require(msg.sender == founder);
            _;
        }
   
}