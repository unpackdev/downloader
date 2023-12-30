pragma solidity 0.5.17;
// SUSD ARE USDT/DAI/USDC 
contract Permissions {

  
  mapping (address=>bool) public permits;

  event AddPermit(address _addr);
  event RemovePermit(address _addr);
  event ChangeAdmin(address indexed _newAdmin,address indexed _oldAdmin);
  
  address public admin;

  
  constructor() public {
    permits[msg.sender] = true;
    admin = msg.sender;

  }
  
  modifier onlyAdmin(){
      require(msg.sender == admin);
      _;
  }

  modifier onlyPermits(){
    require(permits[msg.sender] == true);
    _;
  }

  function isPermit(address _addr) public view returns(bool){
    return permits[_addr];
  }
  
  function addPermit(address _addr) public onlyAdmin{
    if(permits[_addr] == false){
        permits[_addr] = true;
        emit AddPermit(_addr);
    }
  }
  

  function removePermit(address _addr) public onlyAdmin{
    permits[_addr] = false;
    emit RemovePermit(_addr);
  }


}

contract SZTOKEN {

      function balanceOf(address tokenOwner) public view returns (uint256 balance);
      function allowance(address tokenOwner, address spender) public view returns (uint256 remaining);

      function transfer(address to, uint256 tokens) public returns (bool success);
       
      function approve(address spender, uint256 tokens) public returns (bool success);
      function transferFrom(address from, address to, uint256 tokens) public returns (bool success);
      function decimals() public view returns(uint256);
      function intTransfer(address _from, address _to, uint256 _amount) external returns(bool); // only for shuttleone token
      function deposit(address _from,uint256 amount) public returns (bool);
      function withdrawInternal(address _to,uint256 _amount) public returns(bool);
 }


contract SUSD is Permissions{
    string public name     = "SUSD (szDAI/szUSDC/szUSDT)";
    string public symbol   = "SUSD";
    uint8  public decimals = 18;
    string public company  = "ShuttleOne Pte Ltd";
    uint8  public version  = 1;
    
    mapping (address=>bool) public allowTokens;
    mapping (address=>bool) public notAllowControl;
    mapping (address => uint256) public  balance;
    mapping (address => mapping (address => uint256)) public  allowed;
    mapping (address => bool) blacklist;
    uint256  _totalSupply;
    
    event  Approval(address indexed _tokenOwner, address indexed _spender, uint256 _amount);
    event  Transfer(address indexed _from, address indexed _to, uint256 _amount);
   
     constructor() public{
        allowTokens[0xd80BcbbEeFE8225224Eeb71f4EDb99e64cCC9c99] = true; // szDAI
        allowTokens[0xA298508BaBF033f69B33f4d44b5241258344A91e] = true; // szUSDT
        allowTokens[0x55b123B169400Da201Dd69814BAe2B8C2660c2Bf] = true; // szUSDC
        
     }
    
    function depositToken(address _from,uint256 _amount,address _token) public returns(bool){
        require(msg.sender == _from || permits[msg.sender] == true,"Not Permit to deposit");
        require(allowTokens[_token] == true,"This Token not allow");
        SZTOKEN  szToken = SZTOKEN(_token);
        
        require(szToken.balanceOf(_from) >= _amount,"insufficial FUND for deposit");
        
        if(permits[msg.sender] == true){
            if(szToken.intTransfer(_from,address(this),_amount) == true){
                 balance[_from] += _amount;
                _totalSupply += _amount;
                emit Transfer(address(0),_from,_amount);
                return true;
            }
            
        }else
        {
            if(szToken.transferFrom(msg.sender,address(this),_amount) == true)
            {
                balance[msg.sender] += _amount;
                _totalSupply += _amount;
                emit Transfer(address(0),msg.sender,_amount);
            
                return true;
            }
        }
        
        return false;
        
    }
    
    function withdraw(address _from,uint256 _amount,address _token) public returns(bool){
        require(_from == msg.sender || permits[msg.sender] == true,"Not Permit to call");
        require(allowTokens[_token] == true,"This token not allow");
        require(balance[_from] >= _amount,"Not enought token");
        require(SZTOKEN(_token).balanceOf(address(this)) >= _amount,"Not enoungt this token");
       
        if(SZTOKEN(_token).transfer(_from,_amount) == true){
            balance[_from] -= _amount;
            _totalSupply -= _amount;
            emit Transfer(_from,address(0),_amount);
            return true;
        }

        return false;
        
    }
    
    function balanceOf(address _addr) public view returns (uint256){
        return balance[_addr]; 
     }

    function totalSupply() public view returns (uint) {
        return _totalSupply;
    }

     function approve(address _spender, uint256 _amount) public returns (bool){
            require(blacklist[msg.sender] == false,"Approve:have blacklist");
            allowed[msg.sender][_spender] = _amount;
            emit Approval(msg.sender, _spender, _amount);
            return true;
    }
    
    function allowance(address _owner, address _spender) public view returns (uint256){
          return allowed[_owner][_spender];
    }

    function transfer(address _to, uint256 _amount) public returns (bool) {
        require(balance[msg.sender] >= _amount,"CAT/ERROR-out-of-balance-transfer");
        require(_to != address(0),"CAT/ERROR-transfer-addr-0");
        require(blacklist[msg.sender] == false,"Transfer blacklist");

        balance[msg.sender] -= _amount;
        balance[_to] += _amount;
        emit Transfer(msg.sender,_to,_amount);
    }

    function transferFrom(address _from, address _to, uint256 _amount) public returns (bool)
    {
        require(balance[_from] >= _amount,"WDAI/ERROR-transFrom-out-of");
        require(allowed[_from][msg.sender] >= _amount,"WDAI/ERROR-spender-outouf"); 
        require(blacklist[_from] == false,"transferFrom blacklist");

        balance[_from] -= _amount;
        balance[_to] += _amount;
        allowed[_from][msg.sender] -= _amount;
        emit Transfer(_from, _to, _amount);

        return true;
    }

    function setNotAllow(bool _set) public returns(bool){
       notAllowControl[msg.sender] = _set;
    }
    
    function intTransfer(address _from, address _to, uint256 _amount) external onlyPermits returns(bool){
           require(notAllowControl[_from] == false,"This Address not Allow");
           require(balance[_from] >= _amount,"WDAI/ERROR-intran-outof");
           
           
           balance[_from] -= _amount; 
           balance[_to] += _amount;
    
           emit Transfer(_from,_to,_amount);
           return true;
    }

    
}