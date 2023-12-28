pragma solidity ^0.5.14;

contract ERC20 {
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  function transfer(address to, uint256 value) public returns(bool);
  function balanceOf(address who) public view returns (uint256);
  function allowance(address owner, address spender) public view returns (uint256);
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}


library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        return c;
    }
    
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}


contract Noda {
    
    using SafeMath for uint256;
    
    event Deposit(address indexed user, address indexed tokenAddress, uint256 amount );
    event Withdraw(address indexed user, address indexed tokenAddress, uint256 amount );
    event Trade(uint256 indexed makerOrderID, address indexed  userAddress,
    address tokenAddress, address requestTokenAddress, address feeAddress,
    uint256 tradeAmount, uint256 feeAmount);
    event OwnerProfit(address indexed tokenAddress, uint256 feeAmount);
    
    
    address  payable public owner;
    address public feeAddress;
    bool public dexStatus;
    
    mapping( address => TokenDetails) public token;
    
    mapping( address => mapping(address => uint256)) public balance;
    
    mapping( address => uint256 ) public ownerFee;
    
    mapping( uint128 => OrderDetails ) public orders;
    
    mapping (bytes32 => bool) private hashComfirmation;
    
    struct TokenDetails {
        address tokenAddress;
        string symbol;
        uint128 decimals_;
        bool status;
    }
    
    struct OrderDetails {
        uint128 orderID;
        address user;
        uint8 status;
    }
   
    constructor(address _feeaddress) public {
        owner = msg.sender;  
        feeAddress = _feeaddress;
        dexStatus = true; 
    }
    
    modifier onlyFeeAddress() {
        require(msg.sender == feeAddress, "Call should be from fee address");
        _;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Call should be from owner");
        _;
    }
    
    modifier dexstatuscheck() { 
        require(dexStatus == true, "Contract Inactive");
        _;
    }
    
    function setDexStatus(bool _status) public onlyOwner returns(bool) { 
        dexStatus = _status; 
        return true;
    }   
    
    function changeFeeAddress(address _feeAddress) public onlyOwner returns(bool) {
        feeAddress = _feeAddress;
        return true;
    }
    
    function changeOwner(address payable _owner) public onlyOwner returns(bool) {
        owner = _owner;
        return true;
    }
    
    function addToken(address _tokenAddress,string memory _symbol, uint128 _decimals) public onlyFeeAddress returns(bool) {
        require(token[_tokenAddress].status != true, "Token already exist");
        token[_tokenAddress].tokenAddress = _tokenAddress;
        token[_tokenAddress].symbol = _symbol;
        token[_tokenAddress].decimals_ = _decimals;
        token[_tokenAddress].status = true;
        return true;
    }
    
    function removeToken(address _tokenAddress) public onlyFeeAddress returns(bool) {
        require(token[_tokenAddress].status == true, "Token does not exist");
        token[_tokenAddress].status = false;
        return true;
    }
           
    function ownerDeposit(address _tokenAddress, uint256 _amount) public dexstatuscheck onlyOwner payable returns(bool) {
        require(token[_tokenAddress].status,"token does not exist");
       
        if (_tokenAddress == address(0)) {
            require(msg.value > 0, "Invalid eth amount");
            _amount = msg.value;
        }else {
            require(msg.value == 0, "Invalid amount");
            require(_amount > 0, "Invalid token amount");
            require(ERC20(_tokenAddress).balanceOf(msg.sender) >=  _amount, "Insufficient Token balance");
            require(ERC20(_tokenAddress).allowance(msg.sender,address(this)) >= _amount, "Insufficient allowance");
            ERC20(_tokenAddress).transferFrom(msg.sender, address(this), _amount);
        }
        balance[msg.sender][_tokenAddress] = balance[msg.sender][_tokenAddress].add(_amount);
        emit Deposit(msg.sender, _tokenAddress, _amount);
        return true;
    }
    
    
    function ownerWithdraw(address _tokenAddress, uint256 _amount)public dexstatuscheck onlyOwner returns(bool){
          require(token[_tokenAddress].status,"token does not exist");
          require(_amount > 0, "Invalid amount");
          require(balance[msg.sender][_tokenAddress] >= _amount, "Insufficient balance");
          
          if (_tokenAddress == address(0)) {
              msg.sender.transfer(_amount);
          }else {
              ERC20(_tokenAddress).transfer(msg.sender, _amount);
          }
          
          balance[msg.sender][_tokenAddress] =  balance[msg.sender][_tokenAddress].sub(_amount);
          emit Withdraw(msg.sender, _tokenAddress, _amount);
          return true;
    }
    
     function ownerProfitWithdraw(address _tokenAddr, uint256 _amount) public onlyOwner returns(bool){ 
         require(token[_tokenAddr].status,"token does not exist");
         require(ownerFee[_tokenAddr] >=_amount, "Insufficient balance");
         if (_tokenAddr == address(0)) { 
            owner.transfer(_amount);        
        }else { 
            require(_tokenAddr != address(0), "Invalid address");
            ERC20(_tokenAddr).transfer(owner, _amount); 
        }
        
        ownerFee[_tokenAddr] = ownerFee[_tokenAddr].sub(_amount); 
        emit Withdraw (owner, _tokenAddr, _amount);
        return true;
    }
    
    
    function exchange(uint128 _orderID,uint256 _quantity,
    uint128 _price,uint128 _fee,address _tokenAddress,
    address _requestTokenAddress,address _feeAddress,uint8 v,bytes32 m,bytes32 r, bytes32 s) payable public returns(bool)
    {
      require(token[_tokenAddress].status && token[_requestTokenAddress].status, "Maker token invalid");
      require(orders[_orderID].status != 2,"order completed");
      require(!hashComfirmation[m],"hash already used");
      require(ecrecover(m,v,r,s) == feeAddress, "sign mismatch");
      hashComfirmation[m]=true;
      address _user = msg.sender;
        uint128 OrdId = _orderID;
      if(_tokenAddress==address(0) && _feeAddress==address(0))
      {
          uint256 t_price = _quantity.mul(_price);
          uint256 tt_price = addcalc(t_price,_requestTokenAddress).add(_fee);
          require(tt_price==msg.value,"Insufficient ether");
          
          require(balance[owner][_requestTokenAddress] >= _quantity,"Insufficient owner token balance");
          
          balance[owner][_requestTokenAddress] = balance[owner][_requestTokenAddress].sub(_quantity);
          balance[owner][_tokenAddress]=  balance[owner][_tokenAddress].add(tt_price);
          ownerFee[_feeAddress]= ownerFee[_feeAddress].add(_fee);
          uint256 qty=uint256(_quantity);
          ERC20(_requestTokenAddress).transfer(_user,qty);
      }
      else
      { 
         
          if(_feeAddress==address(0))
          {
              require(_fee==msg.value,"Insufficient Fee");
              ownerFee[_feeAddress]= ownerFee[_feeAddress].add(_fee);
          }
          else
          {
             require(ERC20(_feeAddress).balanceOf(_user) >=  _fee, "Insufficient Token Fee balance");
             require(ERC20(_feeAddress).allowance(_user,address(this)) >= _fee, "Insufficient Fee allowance");
             ERC20(_feeAddress).transferFrom(_user,address(this),_fee);
             ownerFee[_feeAddress]= ownerFee[_feeAddress].add(_fee);
          }
           require(ERC20(_tokenAddress).balanceOf(_user) >=  _quantity, "Insufficient Token balance");
          require(ERC20(_tokenAddress).allowance(_user,address(this)) >= _quantity, "Insufficient allowance");
          uint256 qty=uint256(_quantity);
          ERC20(_tokenAddress).transferFrom(_user,address(this),qty);
          balance[owner][_tokenAddress]=  balance[owner][_tokenAddress].add(_quantity);
          
          uint256 t_price = qty.mul(_price);
          t_price = t_price.div(token[_tokenAddress].decimals_);
         
          if(_requestTokenAddress==address(0))
          {
             require(balance[owner][_requestTokenAddress] >= t_price,"Insufficient owner balance");
             address(uint160(_user)).transfer(t_price);
          }
          else
          {
              require(ERC20(_requestTokenAddress).balanceOf(owner) >=  t_price, "Insufficient receiving Token balance");
              ERC20(_requestTokenAddress).transfer(_user,t_price);
          }
           balance[owner][_requestTokenAddress]=  balance[owner][_requestTokenAddress].sub(t_price);
      }
      
      
        emit OwnerProfit (_feeAddress, _fee);
        
         uint128 _feeev = _fee;
         uint128 pprice = _price;
         emit Trade(OrdId, _user, _tokenAddress, _requestTokenAddress,_feeAddress, pprice, _feeev);
          
          orders[OrdId].orderID = OrdId;
          orders[OrdId].user = _user;
          orders[OrdId].status = 2;
        
         return true;
    }
    
    
    function addcalc(uint256 a, address b)internal view returns(uint256)
    {
        uint256 c = a / token[b].decimals_;
        return c;
    }

}