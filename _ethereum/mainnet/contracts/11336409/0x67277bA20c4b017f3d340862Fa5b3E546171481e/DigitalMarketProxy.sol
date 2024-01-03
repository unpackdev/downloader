pragma solidity ^0.5.11;
pragma experimental ABIEncoderV2;

interface Token {
    function totalSupply() external returns (uint256 supply);
    function balanceOf(address owner) external returns (uint balance);
    function balanceOfUsers(address token, address user) external returns (uint balance);
    function transfer(address _to, uint256 _value) external returns (bool success);
    function transferFrom(address _from, address _to, uint _value) external returns (bool success);
    function approve(address _spender, uint256 _value) external returns (bool success);
    function allowance(address _owner, address _spender) external returns (uint256 remaining);
    function receiveApproval(address _spender, uint256 _amount, address _reciver) external returns (bool success);
    function approveAndCall(address _spender, uint256 _amount) external  returns (bool success);
    
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

library SafeMath {
    function safeAdd(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a, "Safe Math Error-Add!");
    }
    function safeSub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a, "Safe Math Error-Sub!");
        c = a - b;
    }
    function safeMul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b, "Safe Math Error-Mul!");
    }
    function safeDiv(uint a, uint b) internal pure returns (uint c) {
        require(b > 0, "Safe Math Error-Div!");
        c = a / b;
    }
}

contract Ownabling { 
    address public owner;
    address public newOwner;
    event OwnershipTransferred(address indexed _from, address indexed _to);
    constructor() public {
        owner = msg.sender;
    }
    modifier onlyOwner {
        require(msg.sender == owner, "Only Admin can call this");
        _;
    }
    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }
    function acceptOwnership() public {
        require(msg.sender == newOwner, "Sender isn't the new Owner");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}

interface TradeTrackerInterface { 
    function tradeComplete(address _tokenGet, uint _amountGet, address _tokenGive, uint _amountGive, address _get, address _give, uint _takerFee, uint _makerRebate) external;
}

contract DigitalMarketStorage is Ownabling{
    //------------------------------------------------------------------------
    // 0. Logic Contracts 
    //------------------------------------------------------------------------
    uint public funcN;
    mapping(bytes4 => address) public funDelegates;
    
    //------------------------------------------------------------------------
    // 1. Dex interface 
    //------------------------------------------------------------------------
    address public accountModifiers; 
	address public tradeTracker;
	uint public fee = 1; 
	uint public feeRate = 5; // Net Fees percentage is [0.2%] 1/5
	
	mapping (address => bool)	public blacklist;
	mapping (address => mapping (address => uint))	public tokens; 
	
	mapping(address=>uint) public platformVolume;
	mapping(address=>uint) public platformFees;
	mapping(address=>uint) public distributedFees;
	
	mapping(address=>mapping(address=>uint)) public tradersVolume;
	mapping(address=>mapping(address=>uint)) public tradersDistributed;
	mapping (address => mapping (bytes32 => uint)) public orderFills;
	
	mapping(address=>uint) public platformVolumeRatd;
	mapping(address=>mapping(address=>uint)) public tradersVolumeRated;
	
	address public successor;
	address public predecessor;
	bool public deprecated;
	bool public paused;
	uint public version;

	// Logging events
	event Cancel(address indexed tokenGet, uint256 amountGet, address indexed tokenGive, uint256 amountGive, uint256 expires, uint256 nonce, address indexed user); 
	event Trade(address tokenGet, uint amountGet, address tokenGive, uint amountGive, address indexed get, address indexed give, uint nonce);
	event Deposit(address indexed token, address indexed user, uint256 amount, uint256 balance);
	event Withdraw(address indexed token, address indexed user, uint256 amount, uint256 balance);
	event FunctionUpdate(bytes4 indexed functionId, address indexed oldDelegate, address indexed newDelegate, string functionSignature);
	
	modifier deprecable() {
        require(!deprecated, "Contract is deprecated");
        _;
    }
    // for security purpose we may use this to stop somefunctions for a short period of time 
    modifier pausable() {
        require(!paused, "Platform is temporary paused!");
        _;
    }
	//------------------------------------------------------------------------
	// 2. Protocol interface 
	//------------------------------------------------------------------------
	address public protocolAddress;
    bool public protocolConnected = false; 
    
    event ChangeProtocol(address indexed oldProtocol, address indexed newProtocol); 
    event Distribuation(address indexed token, uint total, uint indexed level, uint indexed round); 
    
    modifier onlyProtocol() {
        require(msg.sender == protocolAddress, "Only Protocol can call this");
        _;
    }
    modifier protocolConnection() {
        require(protocolConnected == true, "connected protocol is needed"); 
        _;
    }
    
	
}

contract DigitalMarketProxy is DigitalMarketStorage{
    // every called functions of premissoned delegates must be added first
    function addFunctions(address _delegate, bytes4 _function, string memory _signiture) public onlyOwner{
        require(funDelegates[_function] == address(0), "Function is already exist!" );
        funDelegates[_function]= _delegate; 
        funcN++;
        emit FunctionUpdate(_function, address(0), _delegate, string(_signiture));
    }
    
    function updateFunctions(address _delegate, bytes4 _function) public onlyOwner{
        require(funDelegates[_function] != address(0), "Function Not found!" );
        require(funDelegates[_function] == _delegate, "Function doesn't match delegate!" );
        funDelegates[_function]= address(0); 
        funcN--;
        emit FunctionUpdate(_function, _delegate, address(0), string('Function disabled'));
    }
    
    function  () external payable {
        address delegate = funDelegates[msg.sig];
        require(delegate != address(0), "Delegate does not exist.");
        
        assembly {
          let ptr := mload(0x40)
          // (1) copy incoming call data
          calldatacopy(ptr, 0, calldatasize)
          
          // (2) forward call to logic contract
          let result := delegatecall(gas, delegate, ptr, calldatasize, 0, 0)
          let size := returndatasize
          
          // (3) retrieve return data
          returndatacopy(ptr, 0, size)
          
          // (4) forward return data back to caller
          switch result
          case 0 {revert(ptr, size)}
          default {return (ptr, size)}
        } 
    }
    
    function balanceOfUsers(address token, address user) public view returns (uint balance) {
        return tokens[token][user];
    }
      
    function balanceOfFillOrders(address userAdd, bytes32 msgHash) public view returns (uint balance) {
        return orderFills[userAdd][msgHash];
    }
    
    
}

contract DigitalMarketDexSetupLogic is DigitalMarketStorage{
    function DigitalTrading(uint _fee, uint _feeRate, address _predecessor) public onlyOwner {
        require(_fee>0, "fee must be greater than 0");
        require(_feeRate>0, "fee rate must be greater than 0");
        fee = _fee;
        feeRate= _feeRate;
        predecessor = _predecessor;
        deprecated = false;
        paused = false;
        if (predecessor != address(0)) {
          version = DigitalMarketStorage(predecessor).version() + 1; 
        } else {
          version = 1;
        }
    }
    
    function deprecate(bool _deprecated, address _successor) public onlyOwner  { 
        deprecated = _deprecated;
        successor = _successor;
    }
    
    function pause(bool _paused) public onlyOwner  { 
        paused = _paused;
    }
    
    function addToBlacklist(address _wallet) public onlyOwner  { 
        require(blacklist[_wallet] != true, "wallet is already blacklisted");
        blacklist[_wallet] = true;
    }
    
    function removeFromBlacklist(address _wallet) public onlyOwner  { 
        require(blacklist[_wallet] == true, "wallet is not blacklisted");
        blacklist[_wallet] = false; 
    }
    
    function changeAccountModifiers(address _accountModifiers) public onlyOwner {
        accountModifiers = _accountModifiers;
    }
    
    function changeTradeTracker(address _tradeTracker)  public onlyOwner{
        tradeTracker = _tradeTracker;
    }
    
}

contract DigitalMarketDexLogic is DigitalMarketStorage{
    
    function deposit() public payable deprecable {
        require(!paused, "Platform is temporary paused!");
        require(msg.value>0, "amount must be greater than zero!");
        require(blacklist[msg.sender] != true, "address is blacklisted!");
        
        tokens[address(0)][msg.sender] = SafeMath.safeAdd(tokens[address(0)][msg.sender], msg.value);
        emit Deposit(address(0), msg.sender, msg.value, tokens[address(0)][msg.sender]); 
    }

    function withdraw(uint256 _amount) public pausable{
        require(tokens[address(0)][msg.sender] >= _amount, "insufecint balance");
        require(blacklist[msg.sender] != true, "address is blacklisted!");
        require(_amount>0, "amount must be greater than zero!");
        
        tokens[address(0)][msg.sender] = SafeMath.safeSub(tokens[address(0)][msg.sender], _amount);
        if (!msg.sender.send(_amount)) {
            revert("Transfer has failed");
        }
        emit Withdraw(address(0), msg.sender, _amount, tokens[address(0)][msg.sender]);
    }
  
    function receiveApproval(address _spender, uint _amount, address _reciver) public payable deprecable {
        address spender = _spender;
        address tokenAdd = msg.sender;
        require(_reciver == address(this), "approve is not recieved!");
        require(!paused, "Platform is temporary paused!");
        require(blacklist[_spender] != true, "address is blacklisted!");
        require(_amount>0, "amount must be greater than zero!");
        
        if (!Token(tokenAdd).transferFrom(spender, address(this), _amount)) {
          revert("Transfer has failed");
        }
        
        tokens[tokenAdd][spender] = SafeMath.safeAdd(tokens[tokenAdd][spender], _amount);
        emit Deposit(tokenAdd, spender, _amount, tokens[tokenAdd][spender]);
    }

    function withdrawToken(address _token, uint256 _amount) public pausable{
        require(_token != address(0), "Can't withdraw ETH by this Function");
        require(tokens[_token][msg.sender] >= _amount, "insuficient balance!");
        require(blacklist[msg.sender] != true, "address is blacklisted!");
        require(_amount>0, "amount must be greater than zero!");
        
        tokens[_token][msg.sender] = SafeMath.safeSub(tokens[_token][msg.sender], _amount);
        if (!Token(_token).transfer(msg.sender, _amount)) {
          revert("Transfer has failed");
        }
        emit Withdraw(_token, msg.sender, _amount, tokens[_token][msg.sender]);
    }
    
    function checkGiver(address _giver, bytes32 _h, bytes memory signature) private pure returns (bool){
        address signer = recoverSigner(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", _h)), signature);
        if(signer == _giver){ return true;} else {return false;}
        
    }
    
    function tradeMultiTransaction(address[] memory _giver, uint[] memory _gAmount, address[] memory _gToken, uint[] memory _tAmount, address[] memory _tToken,  uint[] memory _expires, uint[] memory _nonce, uint[] memory _amount, bytes memory signature, bytes memory signature2, bytes memory signature3) public protocolConnection {
      require(!paused, "Platform is temporary paused!");
      for(uint i = 0; i<_giver.length; i++){
            if(i==0){
               tradeMulti(_giver[i], msg.sender, _gAmount[i], _gToken[i], _tAmount[i], _tToken[i], _expires[i], _nonce[i], _amount[i], signature);
            } else if(i==1){
                tradeMulti(_giver[i], msg.sender, _gAmount[i], _gToken[i], _tAmount[i], _tToken[i], _expires[i], _nonce[i], _amount[i], signature2);
            } else if(i==2){
                tradeMulti(_giver[i], msg.sender, _gAmount[i], _gToken[i], _tAmount[i], _tToken[i], _expires[i], _nonce[i], _amount[i], signature3);
            } 
       }
    }
    
    function tradeMulti
	        (address _giver, address _taker, uint _gAmount, address _gToken,
	        uint _tAmount, address _tToken,  uint _expires, uint _nonce, uint _amount,
	        bytes memory signature) 
	        private
            {
      
      bytes32 h = keccak256(abi.encodePacked(this, _gToken, _gAmount, _tToken, _tAmount, _expires, _nonce)); 
     
      require(checkGiver(_giver, h, signature)==true, "correct giver not found!"); 
      require(tokens[_gToken][_giver] >= (_gAmount - orderFills[_giver][h]), "Giver insuficient balance!"); 
      require(SafeMath.safeAdd(orderFills[_giver][h], _amount) <= _gAmount, "order amount isn't enough!");
	  require(tokens[_tToken][_taker] >=  (SafeMath.safeMul(_tAmount, _amount) / _gAmount), "Takeer insuficient balance"); 
	  require(block.number < _expires, "Open order has expired!"); 
	  
	  // call and do the exchange  
      tradeBalances(_tToken, (SafeMath.safeMul(_tAmount, _amount) / _gAmount), _gToken, _amount, _giver, _taker);
	  orderFills[_giver][h] = SafeMath.safeAdd(orderFills[_giver][h], _amount);
	  
	  // update volume information [for protocol purpose]
	  platformVolume[_gToken] = SafeMath.safeAdd(platformVolume[_gToken], _amount);
	  tradersVolume[_gToken][_giver] = SafeMath.safeAdd(tradersVolume[_gToken][_giver], _amount);
	  tradersVolume[_tToken][msg.sender] = SafeMath.safeAdd(tradersVolume[_tToken][msg.sender], (SafeMath.safeMul(_tAmount, _amount) / _gAmount));
	  platformVolume[_tToken] = SafeMath.safeAdd(platformVolume[_tToken], (SafeMath.safeMul(_tAmount, _amount) / _gAmount));
	  
	  if(_gToken == address(0)){ // for converting rate purpose 
	      tradersVolumeRated[_tToken][msg.sender] = SafeMath.safeAdd(tradersVolumeRated[_tToken][msg.sender], _amount);
	      platformVolumeRatd[_tToken] = SafeMath.safeAdd(platformVolumeRatd[_tToken], _amount); // _gAmount
	  } else {
	      tradersVolumeRated[_gToken][_giver] = SafeMath.safeAdd(tradersVolumeRated[_gToken][_giver], (SafeMath.safeMul(_tAmount, _amount) / _gAmount));
	      platformVolumeRatd[_gToken] = SafeMath.safeAdd(platformVolumeRatd[_gToken], (SafeMath.safeMul(_tAmount, _amount) / _gAmount)); 
	  }
	  
	  emit Trade(_gToken, _gAmount, _tToken, _tAmount, _giver, _taker, _nonce);
	  
    }
    
	
	function trade
	        (address _giver, uint _gAmount, address _gToken,
	        uint _tAmount, address _tToken,  uint _expires, uint _nonce, uint _amount,
	        bytes memory signature) 
	        public protocolConnection
            {
      require(!paused, "Platform is temporary paused!"); 
      bytes32 h = keccak256(abi.encodePacked(this, _gToken, _gAmount, _tToken, _tAmount, _expires, _nonce)); 
      address signer = recoverSigner(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", h)), signature);
      
      require (signer == _giver, "Order signiture Error");
      require(tokens[_gToken][_giver] >= (_gAmount - orderFills[_giver][h]), "Giver insuficient balance!"); 
      require(SafeMath.safeAdd(orderFills[_giver][h], _amount) <= _gAmount, "order amount isn't enough!");
	  require(tokens[_tToken][msg.sender] >=  (SafeMath.safeMul(_tAmount, _amount) / _gAmount), "Taker insuficient balance"); 
	  require(block.number < _expires, "Open order has expired!"); 
	  
	  // call and do the exchange  
      tradeBalances(_tToken, (SafeMath.safeMul(_tAmount, _amount) / _gAmount), _gToken, _amount, _giver, msg.sender);
	  orderFills[_giver][h] = SafeMath.safeAdd(orderFills[_giver][h], _amount);
	  
	  // update volume information [for protocol purpose]
	  platformVolume[_gToken] = SafeMath.safeAdd(platformVolume[_gToken], _amount);
	  tradersVolume[_gToken][_giver] = SafeMath.safeAdd(tradersVolume[_gToken][_giver], _amount);
	  tradersVolume[_tToken][msg.sender] = SafeMath.safeAdd(tradersVolume[_tToken][msg.sender], (SafeMath.safeMul(_tAmount, _amount) / _gAmount));
	  platformVolume[_tToken] = SafeMath.safeAdd(platformVolume[_tToken], (SafeMath.safeMul(_tAmount, _amount) / _gAmount)); 
	  
	  if(_gToken == address(0)){ // for converting rate purpose 
	      tradersVolumeRated[_tToken][msg.sender] = SafeMath.safeAdd(tradersVolumeRated[_tToken][msg.sender], _amount);
	      platformVolumeRatd[_tToken] = SafeMath.safeAdd(platformVolumeRatd[_tToken], _amount); 
	  } else {
	      tradersVolumeRated[_gToken][_giver] = SafeMath.safeAdd(tradersVolumeRated[_gToken][_giver], (SafeMath.safeMul(_tAmount, _amount) / _gAmount));
	      platformVolumeRatd[_gToken] = SafeMath.safeAdd(platformVolumeRatd[_gToken], (SafeMath.safeMul(_tAmount, _amount) / _gAmount)); 
	  }
	  
	  emit Trade(_gToken, _gAmount, _tToken, _tAmount, _giver, msg.sender, _nonce);
	}
    
    function tradeBalances(address _tToken, uint _tAmount, address _gToken, uint _gAmount,
            address _giver, address _caller
            ) private {
     // Calucate the amount for each one
	  uint gNet = SafeMath.safeSub(_gAmount, SafeMath.safeDiv(_gAmount, (100/fee)) / feeRate);
	  uint tNet = SafeMath.safeSub(_tAmount, SafeMath.safeDiv(_tAmount, (100/fee)) / feeRate);// (100/(fee/1)))) / feeRate; 
	  // Transfering the amount Between users
	  //Giver
	  tokens[_gToken][_giver] = SafeMath.safeSub(tokens[_gToken][_giver], _gAmount); // All amount
	  tokens[_tToken][_giver] = SafeMath.safeAdd(tokens[_tToken][_giver], tNet); // Net amount of tNet
	  // Taker
	  tokens[_tToken][_caller] = SafeMath.safeSub(tokens[_tToken][_caller], _tAmount); // All amount
	  tokens[_gToken][_caller] = SafeMath.safeAdd(tokens[_gToken][_caller], gNet); // Net amount of gAmount
	  // Fee
	  tokens[_gToken][protocolAddress] = SafeMath.safeAdd(tokens[_gToken][protocolAddress], SafeMath.safeDiv(_gAmount, (100/fee))/ feeRate); // feeAccount
	  tokens[_tToken][protocolAddress] = SafeMath.safeAdd(tokens[_tToken][protocolAddress], SafeMath.safeDiv(_tAmount, (100/fee))/ feeRate); // feeAccount
	  
	  platformFees[_gToken] = SafeMath.safeAdd(platformFees[_gToken], SafeMath.safeDiv(_gAmount, (100/fee))/ feeRate);
	  platformFees[_tToken] = SafeMath.safeAdd(platformFees[_tToken], SafeMath.safeDiv(_tAmount, (100/fee))/ feeRate);
	  
	  if (tradeTracker != address(0)) {
        TradeTrackerInterface(tradeTracker).tradeComplete(_tToken, _tAmount, _gToken, _gAmount, _giver, _caller, SafeMath.safeDiv(_tAmount, 100), 0); 
      }
	}
	
	function cancelOrder
	        (address _giver, uint _gAmount, address _gToken, uint _tAmount, address _tToken,  
	        uint _expires, uint _nonce, uint _amount,  bytes memory signature)  public  
	        {
         require(!paused, "Platform is temporary paused!");
         bytes32 h = keccak256(abi.encodePacked(this, _gToken, _gAmount, _tToken, _tAmount, _expires, _nonce)); 
         address signer = recoverSigner(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", h)), signature);
         
         require (signer == _giver, "Order signiture Error!");
         require (_giver == msg.sender, "user not premissoned!");
         uint FilledBefore = orderFills[_giver][h];
         //orderFills[_giver][h] = SafeMath.safeAdd(orderFills[_giver][h], (_amount - FilledBefore));
         orderFills[_giver][h] = _gAmount; // 100% of amount and prevent Java Bignumbers Errors 
         emit Cancel(_gToken, _gAmount, _tToken, _tAmount, _expires, _nonce, msg.sender);
    }
    
    // Signitures 
    function splitSignature(bytes memory sig) internal pure returns (uint8 v, bytes32 r, bytes32 s) {
        require(sig.length == 65, "Signiture Error!");
        assembly {
            // first 32 bytes, after the length prefix.
            r := mload(add(sig, 32))
            // second 32 bytes.
            s := mload(add(sig, 64))
            // final byte (first byte of the next 32 bytes).
            v := byte(0, mload(add(sig, 96)))
        }
        return (v, r, s);
    }
    
    function recoverSigner(bytes32 message, bytes memory sig) internal pure returns (address) {
        (uint8 v, bytes32 r, bytes32 s) = splitSignature(sig);
        return ecrecover(message, v, r, s);
    }
    
}

contract DigitalMarketProtocolLogic is DigitalMarketStorage{
    
    function setUpProtocol(address _protocol) public onlyOwner{
        require(protocolAddress == address(0), "Protocol is already set"); 
        protocolAddress = _protocol;
        protocolConnected = true; 
    }
    
    function changeProtocol(address _newProtocol, address[] memory _tokens) public onlyOwner{
        require(protocolAddress != address(0),"protocol is not set yet");
        //require(protocolAddress == msg.sender,"Only protocol!");
        // Moving Fees balance to the new Protcol 
        uint ETHamount = tokens[address(0)][protocolAddress];
        uint tokenAmount;
        
        tokens[address(0)][_newProtocol] = SafeMath.safeAdd(tokens[address(0)][_newProtocol], ETHamount);
        tokens[address(0)][protocolAddress] = SafeMath.safeSub(tokens[address(0)][protocolAddress], ETHamount);
          
        for(uint i=0; i<_tokens.length; i++){
            tokenAmount = tokens[_tokens[i]][protocolAddress];
            tokens[_tokens[i]][_newProtocol] = SafeMath.safeAdd(tokens[_tokens[i]][_newProtocol], tokenAmount);
            tokens[_tokens[i]][protocolAddress] = SafeMath.safeSub(tokens[_tokens[i]][protocolAddress], tokenAmount);
        }
        address oldProtocol = protocolAddress; 
        protocolAddress = _newProtocol; 
        emit ChangeProtocol(oldProtocol, _newProtocol); 
    }
    
    function distributeFeesPool(address[] memory _tokens, address[] memory _benficiaries, 
        uint[] memory _amounts
    ) public onlyProtocol{
        //require(!paused, "Platform is temporary paused!");
        require(_benficiaries.length == _tokens.length, "inputs not matched!");
        require(_benficiaries.length == _amounts.length, "inputs not matched2!");
        
        // Do Distribuation 
        for(uint i=0; i<_benficiaries.length; i++){
            tokens[_tokens[i]][_benficiaries[i]] = SafeMath.safeAdd(tokens[_tokens[i]][_benficiaries[i]], _amounts[i]);
            tokens[_tokens[i]][protocolAddress] = SafeMath.safeSub(tokens[_tokens[i]][protocolAddress], _amounts[i]);
            tradersDistributed[_tokens[i]][_benficiaries[i]] = SafeMath.safeAdd(tradersDistributed[_tokens[i]][_benficiaries[i]], _amounts[i]);
            
            distributedFees[_tokens[i]] = SafeMath.safeAdd(distributedFees[_tokens[i]], _amounts[i]);
            emit Distribuation(_tokens[i], _amounts[i], 1, 1); 
        }
    }
    
    
}