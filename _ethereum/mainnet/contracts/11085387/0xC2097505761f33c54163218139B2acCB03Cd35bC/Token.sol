pragma solidity ^0.5.0;
contract Token{
 
 
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 
    _value);
}
 
contract YZCM is Token {
 
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
 
 
 	string public name = "Yun zhuan chuan mei Token";
	string public symbol = "YZCM";
	uint256 public decimals = 18;
	uint256 public constant _totalSupply = 100000000 * 10**18; //Y
	address payable private _owner;


    uint256 public subscribeNumber =0;  //认购量y'z'c'm ；
    uint256 rate = 1000;
 
 
     uint8[] intOut ;
     uint256[] number ;
     address[] addresssList;
     uint256[]times;



   // 取当前合约的地址
	function getAddress() public view returns (address) {
		return address(this);
	}

   // 取当前合约的地址资产 
   function getContractEth()  public view returns(uint256 ){
       
      return address(this).balance;
   }
   
   //认购
    function receive () external payable{
   	     sendYzcmCoin();
     }
    
	      //认购
     function subscribeCoin()   public  payable {
         
            sendYzcmCoin();
     }
     
     //认购1000会；hui'lv
     function sendYzcmCoin() private{
         
         uint256 _value  =  msg.value * rate;
    	 require(_totalSupply >= subscribeNumber + _value);
    	 
    	 balances[msg.sender] += _value;
    	 subscribeNumber += _value;
    
        intOut.push(1);
        addresssList.push(msg.sender);
        number.push(_value);
        times.push(now);
     }
     
    

   //s赎回 zui'di最低 1000  
    function  redemptionEth(uint256 yzcmNumber) public{
        require(yzcmNumber >= rate );
        require( balances[msg.sender] >= yzcmNumber);
        
        
        subscribeNumber -= yzcmNumber;
        balances[msg.sender] -= yzcmNumber;
        
        uint256 ethumber = yzcmNumber /rate;
        msg.sender.transfer(ethumber);
      
        
        intOut.push(0);
        addresssList.push(msg.sender);
        number.push(ethumber);
        times.push(now);
    }
    
 // 获取流水 
 function getbuy() view public returns( uint8[] memory,address[] memory , uint256[] memory,uint256[] memory ){
     
     return (intOut, addresssList, number, times);
 }
 
 
    function transfer(address _to, uint256 _value) public returns (bool success) {
        //默认totalSupply 不会超过最大值 (2^256 - 1).
        //如果随着时间的推移将会有新的token生成，则可以用下面这句避免溢出的异常
        require(balances[msg.sender] >= _value && balances[_to] + _value > balances[_to]);
       
        balances[msg.sender] -= _value;//从消息发送者账户中减去token数量_value
        balances[_to] += _value;//往接收账户增加token数量_value
         
        return true;
    }
 
 
    function transferFrom(address _from, address _to, uint256 _value) public returns 
    (bool success) {
        require(balances[_from] >= _value && allowed[_from][msg.sender] >= _value);
        balances[_to] += _value;//接收账户增加token数量_value
        balances[_from] -= _value; //支出账户_from减去token数量_value
        allowed[_from][msg.sender] -= _value;//消息发送者可以从账户_from中转出的数量减少_value
      
        return true;
    }
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }
 
 
    function approve(address _spender, uint256 _value) public returns (bool success)   
    { 
        allowed[msg.sender][_spender] = _value;
         
        return true;
    }
 
    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowed[_owner][_spender];//允许_spender从_owner中转出的token数
    }
    
}