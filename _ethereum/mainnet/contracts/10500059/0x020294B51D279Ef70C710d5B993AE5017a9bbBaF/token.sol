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
            uint investAmount;  
            uint yield;         
            uint lvs;           
            uint createTime;    
            uint dueTime;
            uint mdacxAmount;
      }  
    
        string public name='MDPOX';
        string public symbol='MDPOX';
        uint256 public decimals = 8;  
        uint256 public _totalSupply; 
        
        
        
        mapping(address => bool) public lockAddrs; 
        address public founder;
        
            address mdacAddr=0xa2031e2ce434e7d0dd5841021b734f1e8c8d58ab;
            uint mdacDecimals=18;
            
            address mdacxAddr=0x82899d7968a3051305890f4963a288fec6075ef3;
            uint mdacxDecimals=18;
        
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
   
        
        constructor() public {
            dateToYields[0]=50;
            dateToYields[1]=60;
            dateToYields[2]=75;
            dateToYields[3]=85;
            dateToYields[4]=100;
                
            founder = msg.sender;
            _totalSupply = 30000000 * 10 ** uint256(decimals); 
            name = 'MDPOX';
            symbol = 'MDPOX';
            balances[msg.sender]=_totalSupply;
         }
         
         
        function setDateToYield(uint _index,uint _yield) onlyOwner returns (bool success) {
            dateToYields[_index]=_yield;
            return true;
        }
         
        function setMinerYield(uint _yield) onlyOwner returns (bool success) {
            minerYield=_yield;
            return true;
        }
         
        function setLV(uint _index,uint  _lv) onlyOwner returns (bool success) {
            if(_index==1){
                lv1=_lv;
            }else if(_index==2){
                lv2=_lv;
            }else if(_index==3){
                lv3=_lv;
            }else if(_index==4){
                lv4=_lv;
            }else if(_index==5){
                lv5=_lv;
            }else if(_index==6){
                lv6=_lv;
            }
            return true;
        }
 
        function setLVS(uint _index,uint  _lvs) onlyOwner returns (bool success) {
            if(_index==1){
               lv1S=_lvs;
            }else if(_index==2){
               lv2S=_lvs;
            }else if(_index==3){
               lv3S=_lvs;
            }else if(_index==4){
               lv4S=_lvs;
            }else if(_index==5){
               lv5S=_lvs;
            }else if(_index==6){
               lv6S=_lvs;
            }
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


        function exchange(uint256 _amount,uint _mode)  returns (bool success) {
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
            
             uint time;
             uint yield;
             uint256 mdpoxAmount=_amount* 10 ** uint256(decimals);    
             uint256 mdacAmount=_amount* 10 ** uint256(mdacDecimals);
             uint256 mdacxAmount;
            if(_mode==1){
                 time=604800;
                 yield=dateToYields[0];
                 mdacxAmount=_amount.mul(minerYield);
                 mdacxAmount=mdacxAmount.mul(yield).mul(lvs);
                 mdacxAmount=mdacxAmount.div(48)* (10 ** uint256(mdacxDecimals)).div(10000000);
            }else if(_mode==2){
                 time=2592000;
                 yield=dateToYields[1];
                 mdacxAmount=_amount.mul(minerYield);
                 mdacxAmount=mdacxAmount.mul(yield).mul(lvs);
                 mdacxAmount=mdacxAmount.div(12)* (10 ** uint256(mdacxDecimals)).div(10000000);
            }else if(_mode==3){
                 time=7776000;
                 yield=dateToYields[2];
                 mdacxAmount=_amount.mul(minerYield);
                 mdacxAmount=mdacxAmount.mul(yield).mul(lvs);
                 mdacxAmount=mdacxAmount.div(4)* (10 ** uint256(mdacxDecimals)).div(10000000);
            }else if(_mode==4){
                 time=15552000;
                 yield=dateToYields[3];
                 mdacxAmount=_amount.mul(minerYield);
                 mdacxAmount=mdacxAmount.mul(yield).mul(lvs);
                 mdacxAmount=mdacxAmount.div(2)* (10 ** uint256(mdacxDecimals)).div(10000000);
            }else if(_mode==5){
                 time=31104000;
                 yield=dateToYields[4];
                 mdacxAmount=_amount.mul(minerYield);
                 mdacxAmount=mdacxAmount.mul(yield).mul(lvs);
                 mdacxAmount=mdacxAmount* (10 ** uint256(mdacxDecimals)).div(10000000);
            }
            
            ERC20 mdacToken =ERC20(mdacAddr);
            ERC20 mdacxToken =ERC20(mdacxAddr);
            
            require(balances[founder]>=mdpoxAmount);
            require(mdacToken.balanceOf(msg.sender)>=mdacAmount);
            require(mdacxToken.balanceOf(this)>=mdacxAmount);
            
            
            mdacToken.transferFrom(msg.sender,this,mdacAmount);
            mdacxToken.transfer(msg.sender,mdacxAmount);

            balances[founder]=balances[founder].sub(mdpoxAmount);
            balances[msg.sender]=balances[msg.sender].add(mdpoxAmount);
            Transfer(founder,msg.sender,mdpoxAmount);
          

            Pledge memory  pledge=Pledge(msg.sender,mdpoxAmount,yield,lvs,now,now+time,mdacxAmount);
            addressToPledge[msg.sender].push(pledge);

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
 

        function changeFounder(address newFounder) onlyOwner{
            if (msg.sender!=founder) revert();
            founder = newFounder; 
        }
 
        modifier onlyOwner() {
            require(msg.sender == founder);
            _;
        }
   
}