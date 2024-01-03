/**
 *Submitted for verification at Etherscan.io on 2020-03-07
*/

/**
 *Submitted for verification at Etherscan.io on 2019-09-09
 * BEB dapp for www.betbeb.com
*/
pragma solidity^0.4.24;  
interface tokenTransfer {
    function transfer(address receiver, uint amount);
    function transferFrom(address _from, address _to, uint256 _value);
    function balanceOf(address receiver) returns(uint256);
}
interface tokenTransferUSDT {
    function transfer(address receiver, uint amount);
    function transferFrom(address _from, address _to, uint256 _value);
    function balanceOf(address receiver) returns(uint256);
}
interface tokenTransfereth {
    function getWorld() returns(uint256);
}

contract Ownable {
  address public owner;
 
    function Ownable () public {
        owner = msg.sender;
    }
 
    modifier onlyOwner {
        require (msg.sender == owner);
        _;
    }
 
    /**
     * @param  newOwner address
     */
    function transferOwnership(address newOwner) onlyOwner public {
        if (newOwner != address(0)) {
        owner = newOwner;
      }
    }
}

contract BEBchain is Ownable{
     tokenTransfer public bebTokenTransfer; //代币BET
     tokenTransferUSDT public bebTokenTransferUSDT; //代币USDT
    address oneaddress;//第一个管理员
     address twoaddress;//第一个管理员
     uint256 ethpoint;//ETH价格 
     uint256 bebpoint;//ETH价格 
      uint256 BuyAmount;
      uint256 yuetime;
      uint256 public usdt;
      uint256 public etime;//减少时间
     struct bebuser{
         uint256 amount;
         uint256 _time;
     }
    mapping(address=>bool)public looks;
    mapping(address=>bebuser)public bebusers;
     function BEBchain(address _tokenAddress,address _tokenAddressUSDT){
         bebTokenTransfer = tokenTransfer(_tokenAddress);
         bebTokenTransferUSDT=tokenTransferUSDT(_tokenAddressUSDT);
         yuetime=86400*30;//86400*30;
         usdt=10**12;
         etime=86400*5;
     }
     function setTime(uint _t)onlyOwner{
         etime=_t;
     }
     function setBET(uint _bet)public{
         bebuser storage _user=bebusers[msg.sender];
         bebTokenTransfer.transferFrom(msg.sender,address(this),_bet);
             _user.amount+=_bet;
             _user._time=now-etime;
     }
     //收益分红
     function setSHOUyi()public{
         bebuser storage _user=bebusers[msg.sender];
         uint256 _t=0;
         if(now>_user._time){
             _t=now-_user._time;
         }else{
             return;
         }
        require(_t>yuetime);//大于1个月
        //开始分红
        uint _value=_user.amount*1188;
        uint value =_value/usdt;
        _user._time=now;
        bebTokenTransferUSDT.transfer(msg.sender,value);
     }
     //取款
     function setqukuan(uint _bet)public{
         bebuser storage _user=bebusers[msg.sender];
         require(_user.amount>0 && _user.amount>=_bet);
         bebTokenTransfer.transfer(msg.sender,_bet);
            _user.amount-=_bet;
            _user._time=now;
     }
     function withdrawToEth(address _addr,uint256 _value)onlyOwner{
         _addr.transfer(_value);
     }
     function withdrawToUsdt(address _addr,uint256 _value)onlyOwner{
         bebTokenTransferUSDT.transfer(_addr,_value);
     }
     function withdrawToBet(address _addr,uint256 _value)onlyOwner{
         bebTokenTransfer.transfer(_addr,_value);
     }
    function getwater(address addr) public view returns(uint256 A,uint256 _t,uint256 value){
         bebuser storage _user=bebusers[addr];
         uint _value=_user.amount*1188;
          value =_value/usdt;//本月分红
          A=_user.amount;
         //uint256 _t=0;
         if(now>_user._time){
             _t=now-_user._time;
             if(yuetime>_t){
                 _t=yuetime-_t;   
             }else{
                 _t=0;
             }
         }else{
             _t=0;
         }
    }
     function getadmin() public view returns(address,address,address){
         return (oneaddress,twoaddress,owner);
    }
    //查询BET余额
    function getBET() public view returns(uint256){
         return bebTokenTransfer.balanceOf(this);
    }
    //查询BET余额
    function getUSDT() public view returns(uint256){
         return bebTokenTransferUSDT.balanceOf(this);
    }
    function ()payable{
        
    }
}