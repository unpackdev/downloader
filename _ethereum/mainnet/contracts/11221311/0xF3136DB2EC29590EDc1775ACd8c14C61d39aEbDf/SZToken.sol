pragma solidity 0.5.17;

contract Permissions {

  mapping (address=>bool) public permits;

// all events will be saved as log files
  event AddPermit(address _addr);
  event RemovePermit(address _addr);

  constructor() public {
    permits[msg.sender] = true;
  }

  
  modifier onlyPermits(){
    require(permits[msg.sender] == true);
    _;
  }

  function isPermit(address _addr) public view returns(bool){
    return permits[_addr];
  }

  function addPermit(address _addr) public onlyPermits{
    require(permits[_addr] == false);
    permits[_addr] = true;
    emit AddPermit(_addr);
  }



  function removePermit(address _addr) public onlyPermits{
    require(_addr != msg.sender);
    permits[_addr] = false;
    emit RemovePermit(_addr);
  }
  


}


contract ERC20 {

      function totalSupply() public view returns(uint256);
      function balanceOf(address tokenOwner) public view returns (uint256 balance);
      function transfer(address to, uint256 tokens) public returns (bool success);
      function transferFrom(address from, address to, uint256 tokens) public returns (bool success);
      function decimals() public view returns(uint256);
      function intTransfer(address _from, address _to, uint256 _amount) public returns(bool);
 }
 
// ERC20 TOOLS For send all SZxxxToken

 contract SZToken is Permissions{
    uint256 public version = 1;
    string public name     = "szTokenHelpTransfer";
    string public symbol   = "szTokens";
    uint8  public decimals = 18;
    string public company  = "ShuttleOne Pte Ltd";
    
    address public coldWallet = 0x186509E7959dda993Cd25fa4bde171b430F66748;

    mapping(address=>bool) disToken;
    address[] public allowTokens;
     
    mapping(address=>bool) disPools;
    address[] public allowPools;
    
    event  Approval(address indexed _tokenOwner, address indexed _spender, uint256 _amount);
    event  Transfer(address indexed _from, address indexed _to, uint256 _amount);
     
     constructor() public{
        allowTokens.push(0xA298508BaBF033f69B33f4d44b5241258344A91e); // szUSDT
        allowTokens.push(0xd80BcbbEeFE8225224Eeb71f4EDb99e64cCC9c99); // szDAI
        allowTokens.push(0x55b123B169400Da201Dd69814BAe2B8C2660c2Bf); // szUSDC
     }
     
     
     
     function addAllowToken(address _addr) public onlyPermits returns(bool){
         allowTokens.push(_addr);
         return true;
     }
     
     function setDisableToken(address _addr,bool _set) public onlyPermits returns(bool){
         disToken[_addr] = _set;
         return true;
     }

    function setColdWallet(address _addr) public onlyPermits{
        coldWallet = _addr;
    }

    function totalSupply() public view returns (uint) {
          uint256 _totalSupply;  
         for(uint256 i=0;i<allowTokens.length;i++){
             if(disToken[allowTokens[i]] == false){
                 _totalSupply += ERC20(allowTokens[i]).totalSupply();
             }
         }
         return _totalSupply;
    }

     function balanceOf(address _addr) public view returns(uint256){
         uint256 sumBalance;  
         for(uint256 i=0;i<allowTokens.length;i++){
             if(disToken[allowTokens[i]] == false){
                 sumBalance += ERC20(allowTokens[i]).balanceOf(_addr);
             }
         }
         return sumBalance;
     }
     
     function _transfer(address _from,address _to,uint256 _amount) internal returns (bool){
         
         uint256 sumAmount = _amount;
         ERC20 _szToken;
         
         for(uint256 i=0;i<allowTokens.length;i++){
             if(disToken[allowTokens[i]] == false){
                 _szToken = ERC20(allowTokens[i]);
                 if(_szToken.balanceOf(_from) >= sumAmount){
                    _szToken.intTransfer(_from,_to,sumAmount);
                    return true;
                 }
                 else
                 {
                     uint256 _tranAmount = _szToken.balanceOf(_from);
                     _szToken.intTransfer(_from,_to,_tranAmount);
                     sumAmount -= _tranAmount;
                 }
             }
         }
         
         return false; 

     }
         
    function transfer(address _to, uint256 _amount) public returns (bool) {
        require(_to != address(0),"ERROR-transfer-addr-0");
        require(_transfer(msg.sender,_to,_amount) == true,"ERROR-out-of-balance-transfer");
        emit Transfer(msg.sender,_to,_amount);
        
        return true;
    }
    

    
    function intTransfer(address _from, address _to, uint256 _amount) public onlyPermits returns(bool){
           require(_to != address(0),"ERROR-intran-addr0");
           require(_transfer(_from,_to,_amount) == true,"ERROR-out-of-balance-transfer");
           
           emit Transfer(_from,_to,_amount);
           return true;
    }
    
    function intTransferWithFee(address _from, address _to, uint256 _value,uint256 _fee) public onlyPermits returns(bool){
             require(_to != address(0),"ERROR _to = ADDRESS 0");
             require(_value > _fee,"ERROR _value > _fee");    
             require(coldWallet != address(0),"ERROR NO COLD WALLET");
             require(balanceOf(_from) >= _value,"ERROR Out of fund");
             
             
             require(_transfer(_from,_to,_value - _fee) == true,"ERROR-out-of-balance-transfer");
             require(_transfer(_from,coldWallet,_fee) == true,"ERROR-out-of-fee-transfer");
             
    
            emit Transfer(_from,_to,_value);
            emit Transfer(_to,msg.sender,_fee);
    
            return true;
    }
    
     
 }