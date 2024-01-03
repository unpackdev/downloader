pragma solidity ^0.5.11;

interface Token {
  function transfer(address _to, uint256 _value) external returns (bool success);
  function transferFrom(address _from, address _to, uint _value) external returns (bool success);
  
  event Transfer(address indexed _from, address indexed _to, uint256 _value);
  event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

library SafeMath {
    function safeAdd(uint a, uint b) public pure returns (uint c) {
        c = a + b;
        require(c >= a, "Safe Math Error-Add!");
    }
    function safeSub(uint a, uint b) public pure returns (uint c) {
        require(b <= a, "Safe Math Error-Sub!");
        c = a - b;
    }
    function safeMul(uint a, uint b) public pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b, "Safe Math Error-Mul!");
    }
    function safeDiv(uint a, uint b) public pure returns (uint c) {
        require(b > 0, "Safe Math Error-Div!");
        c = a / b;
    }
}

interface DEXplatform { 
  function changeProtocol(address _newProtocol, address[] calldata _tokens) external; 
  function distributeFeesPool(address[] calldata _tokens, address[] calldata _benficiaries, uint[] calldata _amounts) external;
  function getProtocol() external view returns (address prtocol);
}

contract Owned {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner, "only admin");
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}

contract feesProtocolStorage is Owned{
    /* Groups default Array
        1 Founders    2 Team    3 investors
        4 community    5 development & Expenses    6 insurance
    */
    
    //------------------------------------------------------------------------
    // 0. Logic Contracts Storages
    //------------------------------------------------------------------------
    uint public funcN;
    mapping(bytes4 => address) public funDelegates;
    
    //------------------------------------------------------------------------
    // 1. Protocol Storages  
    //------------------------------------------------------------------------
    
    address public admin; // will be set by the address that send the Token
    address public projectToken;
    address public dex;
    uint public propertyAmount; // Total Token to be Locked
    uint public propertyAmountETH;
    bool public tokenIsRecieved =  false; // Protocol Will not work unless he recieve the token
    
    mapping(uint=>address) public groupsAdmin;
    
    uint public upcomingLevel = 1;
    uint public upcomingRound = 1;
    uint public usedVolume = 0; // To store used volume 
    
    address[] public founders;
    address[] public team;
    address[] public investors;
    
    mapping(address=>uint) public platformVolumeUsed;
    mapping(address=>uint) public platformVolumeUsedInETH;
    
    mapping(address=>mapping(address=>uint)) public tradersVolumeUsed;
    mapping(address=>mapping(address=>uint)) public tradersVolumeUsedInETH;
    
    //-----------------------------------------------------
    // Rounds Mapping 
    //-----------------------------------------------------
    mapping(uint=>mapping(uint=>uint)) public roundsTargetedFees;
    mapping(uint=>mapping(uint=>uint)) public roundsTargetedVolume;
    
    //-----------------------------------------------------
    // Locked Token mapping and owndership of the token
    //-----------------------------------------------------
    // Groups - address - balance
    uint public OwnershipTotalAllocation;
    uint public OwnershipTotalAllocated;
    uint public unloackedTokenBalance;
    uint public withdrewTokenBalance;
    
    mapping(uint=>uint) public tokenGroupsOwnershipAllocation;
    mapping(uint=>uint) public tokenGroupsOwnershipAlloced;
    
    mapping(uint=>mapping(address=>uint)) public tokenOwnersBalance;
    
    mapping(address=>uint) public unlockedBalance;
    mapping(address=>uint) public withdrawBalance;
    
    // level-round-ownergroups-ownerAddress-balance
    mapping(uint=>mapping(uint=>mapping(uint=>
            mapping(address=>uint)))
            ) public unlockedRoundsBalance;
    
    //-----------------------------------------------------
    // Fees management Mappings
    //-----------------------------------------------------
    mapping(address=>uint) public platformFeesDeserved;
    mapping(address=>uint) public platformFeesDeservedInEth;
    mapping(address=>mapping(address=>uint)) public tradersFeesDeserved;
    mapping(address=>mapping(address=>uint)) public tradersFeesDeservedInEth;
   
    //-----------------------------------------------------
    // Events 
    event Deposit(address token, address user, uint256 amount, uint256 balance);
    event Withdraw(address indexed token, address indexed user, uint256 amount, uint256 balance);
    event ChangeProtocol(address oldProtocol, address newProtocol); 
    event FunctionUpdate(bytes4 indexed functionId, address indexed oldDelegate, address indexed newDelegate, string functionSignature);
    
}

contract feesProtocolProxy is feesProtocolStorage{
    // every called functions of premissoned delegates must be added 
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
    
    function () external payable {
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
    
    function getFounders() public view onlyOwner returns(address[] memory foundersA){
        return founders;
    }
    
    function getTeam() public view onlyOwner returns(address[] memory foundersA){
        return team;
    }
    
    function getInvestors() public view onlyOwner returns(address[] memory foundersA){
        return investors;
    }
    
    
}

contract feesProtocolSetup is feesProtocolStorage{
    
    function changeProtocolOnDex(address _newAddress, address[] memory _tokens) public onlyOwner{
        address old = address(this); 
        require(dex != address(0), "DEX address not found!"); 
        require(old == address(this), "Old Protocol Error!"); 
        
        DEXplatform(dex).changeProtocol(_newAddress, _tokens);
        emit ChangeProtocol(old, _newAddress); 
    }
    
    function setTokenDetails(address _token, uint _amount, uint _ether) public onlyOwner{
        require(tokenIsRecieved==false, "token is already unlocked and cant changed");
        require(_amount>0, "Invalid Token Amount");
        require(_ether>0, "Invalid Ether Amount");
        projectToken = _token;
        propertyAmount = _amount;
        propertyAmountETH = _ether;
    }
    
    function setDex(address _dex) public onlyOwner{
        dex = _dex; 
    }
    
    // Deposit and Lock => Must be called receiveApproval not lockToken
    function receiveApproval(address _spender, uint _amount, address _reciver) public payable {
        require(tokenIsRecieved==false, "Token is already recieved!"); 
        require(projectToken != address(0), "Token Address hasn't set yet!");
        require(projectToken == msg.sender, "Deposting incorrect Token!");
        require(dex != address(0), "DEX is not set!"); 
        require(propertyAmount>0, "Locked amount is not set!"); 
        require(propertyAmountETH>0, "ETH amount is not set!");
        require(propertyAmount==_amount, "Recieved amount Error!");
        require(_reciver == address(this), "Approved failed!");
        require(_spender == owner, "only owner!");
        
        if (!Token(projectToken).transferFrom(_spender, address(this), _amount)) { revert("Amoount not recieved!"); }
        
        admin = _spender;
        tokenIsRecieved=true;
        
        groupsAdmin[1]=_spender;
        groupsAdmin[2]=_spender;
        groupsAdmin[3]=_spender;
        groupsAdmin[4]=_spender;
        groupsAdmin[5]=_spender;
        groupsAdmin[6]=_spender;
        
        OwnershipTotalAllocation= _amount; 
        tokenGroupsOwnershipAllocation[1]= _amount; 
        
        emit Deposit(projectToken, _spender, _amount, tokenOwnersBalance[1][_spender]);
        
    }
    
    //-----------------------------------------------------
    // Token Owndership Management 
    //-----------------------------------------------------
    
    function setGroupsAllocation(uint _amount, uint _group)public onlyOwner{
        uint freeAllocation = propertyAmount-OwnershipTotalAllocation;
        require(freeAllocation >= _amount, "Insufficient amount!"); 
        tokenGroupsOwnershipAllocation[_group]= SafeMath.safeAdd(tokenGroupsOwnershipAllocation[_group], _amount);
        OwnershipTotalAllocation = SafeMath.safeAdd(OwnershipTotalAllocation, _amount);
    }
    
    function setGroupsReAllocation(uint _amount, uint _group, uint _groupSpender)public onlyOwner{
        uint freeAllocated = tokenGroupsOwnershipAllocation[_groupSpender] - tokenGroupsOwnershipAlloced[_groupSpender]; // for re-allocating free amount not allocated
        require(groupsAdmin[_groupSpender] == msg.sender, "group admin Error!");
        require(freeAllocated >= _amount, "amount exceeding!");
        tokenGroupsOwnershipAllocation[_groupSpender]= SafeMath.safeSub(tokenGroupsOwnershipAllocation[_groupSpender], _amount);
        tokenGroupsOwnershipAllocation[_group]= SafeMath.safeAdd(tokenGroupsOwnershipAllocation[_group], _amount);
    }
    
    function allocateOwnershipToAddress(uint _amount, uint _group, address _reciver)public onlyOwner{
        // Get the amount that hasnot allocted to address [free to re-allocate]
        uint freeAllocation = tokenGroupsOwnershipAllocation[_group] - tokenGroupsOwnershipAlloced[_group];
        // Revert allocated from passing Total amount that set to be allocating
        require(SafeMath.safeAdd(OwnershipTotalAllocated, _amount) <= OwnershipTotalAllocation, "Insufficient amount!"); 
        require(groupsAdmin[_group] == msg.sender, "permission error!");
        require(freeAllocation >= _amount, "Insufficient free balance!");
        
        tokenOwnersBalance[_group][_reciver] = SafeMath.safeAdd(tokenOwnersBalance[_group][_reciver], _amount);
        tokenGroupsOwnershipAlloced[_group]= SafeMath.safeAdd(tokenGroupsOwnershipAlloced[_group], _amount);
        OwnershipTotalAllocated= SafeMath.safeAdd(OwnershipTotalAllocated, _amount);
        
        if(_group == 1){
            founders.push(_reciver);
        } else if(_group == 2){
            team.push(_reciver);
        } else if(_group == 3){
            investors.push(_reciver);
        }
    }
    
    
}

contract feesProtocolOwnershipProcesses is feesProtocolStorage{
    //-----------------------------------------------------
    // Ownership processes 
    //-----------------------------------------------------
    function cancelOwnership(uint _amount, uint _group, address _sender)public { // for re-allocation purpose
        require(_sender == msg.sender, "not allowed!");
        // since allocating is require sufficient balance for 
        // tokenGroupsOwnershipAlloced & OwnershipTotalAllocated
        // so no need to re-check their sufficent balance 
        require(tokenOwnersBalance[_group][_sender] >= _amount, "Insufficient balance!");
        
        tokenOwnersBalance[_group][_sender] = SafeMath.safeSub(tokenOwnersBalance[_group][_sender], _amount);
        tokenGroupsOwnershipAlloced[_group]= SafeMath.safeSub(tokenGroupsOwnershipAlloced[_group], _amount);
        OwnershipTotalAllocated= SafeMath.safeSub(OwnershipTotalAllocated, _amount);
    }
    
    function sendOwnershipInsideTheGroup(uint _amount, uint _group, address _reciver, address _sender)public {
        require(_sender == msg.sender, "not Allowed!");
        require(tokenOwnersBalance[_group][_sender] >= _amount, "Insufficient balance!");
        
        tokenOwnersBalance[_group][_reciver] = SafeMath.safeAdd(tokenOwnersBalance[_group][_reciver], _amount);
        tokenOwnersBalance[_group][_sender] = SafeMath.safeSub(tokenOwnersBalance[_group][_sender], _amount);
    }
    
    function sendOwnershipOutTheGroup(uint _amount, uint _groupSender, uint _groupReciver, address _reciver, address _sender)public {
        require(_sender == msg.sender, "not allowed!");
        
        require(tokenOwnersBalance[_groupSender][_sender] >= _amount, "Insufficient balance!");
        
        tokenOwnersBalance[_groupReciver][_reciver] = SafeMath.safeAdd(tokenOwnersBalance[_groupReciver][_reciver], _amount);
        tokenOwnersBalance[_groupSender][_sender] = SafeMath.safeSub(tokenOwnersBalance[_groupSender][_sender], _amount);
        
        tokenGroupsOwnershipAlloced[_groupReciver] = SafeMath.safeAdd(tokenGroupsOwnershipAlloced[_groupReciver], _amount);
        tokenGroupsOwnershipAlloced[_groupSender] = SafeMath.safeSub(tokenGroupsOwnershipAlloced[_groupSender], _amount);
        
        tokenGroupsOwnershipAllocation[_groupReciver] = SafeMath.safeAdd(tokenGroupsOwnershipAllocation[_groupReciver], _amount);
        tokenGroupsOwnershipAllocation[_groupSender] = SafeMath.safeSub(tokenGroupsOwnershipAllocation[_groupSender], _amount);
        
    }
    
    
    
}

contract feesProtocolProcesses is feesProtocolStorage{
    function withdrawUnlockedToken(uint _amount, address _benficiary) public{
        require(_benficiary == msg.sender, "Sender Approval Error!"); 
        require(SafeMath.safeAdd(withdrewTokenBalance, _amount) <= unloackedTokenBalance, "Insufficient Total Unlocked Balance!");
        require(SafeMath.safeAdd(withdrawBalance[_benficiary], _amount) <= unlockedBalance[_benficiary], "Insufficient User Unlocked Balance!");
        
        if (!Token(projectToken).transfer(msg.sender, _amount)) { revert("withdraw failed!"); }
        
        emit Withdraw(projectToken, msg.sender, _amount, withdrawBalance[msg.sender]); // _benficiary
        withdrawBalance[_benficiary] = SafeMath.safeAdd(withdrawBalance[_benficiary], _amount);
        withdrewTokenBalance = SafeMath.safeAdd(withdrewTokenBalance, _amount);
    }
    
    function distributingPrepration(address[] memory _tokens, address[] memory _traders, 
        address[] memory _tradersToken, uint[] memory _tokensV, uint[] memory _tokensVeth, 
        uint[] memory _tradersV, uint[] memory _tradersVeth,
        address[] memory _tradersF, address[] memory _tradersTokenF,
        uint[] memory _tradersFees, uint[] memory _tradersFeth
    ) public onlyOwner{
        
        // _tokens _traders  _tradersToken  _tokensV  _tokensVeth  _tradersV  _tradersVeth
        require(usedVolume == 0, "distribution is already done!");
        require(_tokens.length == _tokensV.length, "inputs not matched 1!");
        require(_tokens.length == _tokensVeth.length, "inputs not matched 2!");
        require(_traders.length == _tradersV.length, "inputs not matched 3!");
        require(_traders.length == _tradersVeth.length, "inputs not matched 4!"); 
        require(_traders.length == _tradersToken.length, "inputs not matched 5!");
        require(_tradersF.length == _tradersTokenF.length, "inputs not matched 6!");
        require(_tradersF.length == _tradersFees.length, "inputs not matched 7!"); 
        require(_tradersF.length == _tradersFeth.length, "inputs not matched 8!");
        
        // first for tokens 
        for(uint i=0; i<_tokens.length; i++){
            platformVolumeUsed[_tokens[i]] = SafeMath.safeAdd(platformVolumeUsed[_tokens[i]], _tokensV[i]);
            platformVolumeUsedInETH[_tokens[i]] = SafeMath.safeAdd(platformVolumeUsedInETH[_tokens[i]], _tokensVeth[i]);
            if(_tokens[i] != address(0)){
                platformVolumeUsedInETH[address(0)] = SafeMath.safeAdd(platformVolumeUsedInETH[address(0)], _tokensVeth[i]);
            }
        }
        
        // Second for traders 
        for(uint i=0; i<_traders.length; i++){
            tradersVolumeUsed[_tradersToken[i]][_traders[i]] = SafeMath.safeAdd(tradersVolumeUsed[_tradersToken[i]][_traders[i]] , _tradersV[i]);
            tradersVolumeUsedInETH[_tradersToken[i]][_traders[i]] = SafeMath.safeAdd(tradersVolumeUsedInETH[_tradersToken[i]][_traders[i]], _tradersVeth[i]);
            if(_tradersToken[i] != address(0)){
                tradersVolumeUsedInETH[address(0)][_traders[i]] = SafeMath.safeAdd(tradersVolumeUsedInETH[address(0)][_traders[i]], _tradersVeth[i]);
            }
            
            // I think there is no need to save this data since it can be get off-chain 
            //traderTotalVolume[upcomingLevel][upcomingRound][_tradersToken[i]][_traders[i]] = SafeMath.safeAdd( traderTotalVolume[upcomingLevel][upcomingRound][_tradersToken[i]][_traders[i]] , _tradersV[i]);
            //traderTotalVolumeInEth[upcomingLevel][upcomingRound][_tradersToken[i]][_traders[i]] = SafeMath.safeAdd(traderTotalVolumeInEth[upcomingLevel][upcomingRound][_tradersToken[i]][_traders[i]], _tradersVeth[i]);
            
        }
        
        // third for fees 
        for(uint i=0; i<_tradersF.length; i++){
            // fees for Eth is saved inside tradersFeesDeserved for address(0)
            // fees for Tokens are save indside tradersFeesDeservedInEth all under one address(0) 
            platformFeesDeserved[_tradersTokenF[i]] = SafeMath.safeAdd(platformFeesDeserved[_tradersTokenF[i]], _tradersFees[i]);
            platformFeesDeservedInEth[_tradersTokenF[i]] = SafeMath.safeAdd(platformFeesDeservedInEth[_tradersTokenF[i]], _tradersFeth[i]);
            
            tradersFeesDeserved[_tradersTokenF[i]][_tradersF[i]] = SafeMath.safeAdd(tradersFeesDeserved[_tradersTokenF[i]][_tradersF[i]] , _tradersFees[i]);
            tradersFeesDeservedInEth[_tradersTokenF[i]][_tradersF[i]] = SafeMath.safeAdd(tradersFeesDeservedInEth[_tradersTokenF[i]][_tradersF[i]], _tradersFeth[i]);
            
            // safe fees valued in ETH for all traded token using one Token only for each user 
            if(_tradersTokenF[i] != address(0)){
                platformFeesDeservedInEth[address(0)] = SafeMath.safeAdd(platformFeesDeservedInEth[address(0)], _tradersFeth[i]);
                tradersFeesDeservedInEth[address(0)][_tradersF[i]] = SafeMath.safeAdd(tradersFeesDeservedInEth[address(0)][_tradersF[i]], _tradersFeth[i]);
            }
            
        }
        
        usedVolume = 1;  
        
    }
    
    // benficiaries (1) for distributing  || benficiaries2 for unlocking 
    function distributingAndUnlocking(address[] memory _tokens, address[] memory _benficiaries, 
        uint[] memory _groups, uint[] memory _amounts, 
        address[] memory _benficiaries2, uint[] memory _groups2, uint[] memory _amounts2, 
        uint _nextLevel, uint _nextRound
    ) public payable onlyOwner{ // payable
        
        require(usedVolume == 1, "do prepration first!");
        require(_tokens.length == _benficiaries.length, "inputs not matched 1!");
        require(_tokens.length == _groups.length, "inputs not matched 2!");
        require(_tokens.length == _amounts.length, "inputs not matched 3!");
        require(_benficiaries2.length == _groups2.length, "inputs not matched 4!");
        require(_benficiaries2.length == _amounts2.length, "inputs not matched 5!");
        
        // first we unlock Project token 
        for(uint i=0; i<_benficiaries2.length; i++){
            require(SafeMath.safeAdd(unloackedTokenBalance, _amounts2[i])  <= propertyAmount, "there isn't enough balance to unlock!");
            
            unloackedTokenBalance = SafeMath.safeAdd(unloackedTokenBalance, _amounts2[i]);
            unlockedBalance[_benficiaries2[i]] = SafeMath.safeAdd(unlockedBalance[_benficiaries2[i]], _amounts2[i]);
            unlockedRoundsBalance[upcomingLevel][upcomingRound][_groups2[i]][_benficiaries2[i]] = SafeMath.safeAdd(unlockedRoundsBalance[upcomingLevel][upcomingRound][_groups2[i]][_benficiaries2[i]], _amounts2[i]);
            
            if(_groups2[i] == 4){
                OwnershipTotalAllocated = SafeMath.safeAdd(OwnershipTotalAllocated, _amounts2[i]);
                tokenGroupsOwnershipAlloced[4] = SafeMath.safeAdd(tokenGroupsOwnershipAlloced[4], _amounts2[i]);
                tokenOwnersBalance[4][_benficiaries2[i]] = SafeMath.safeAdd(tokenOwnersBalance[4][_benficiaries2[i]], _amounts2[i]);
            }
        }
        
        // Second we distribute fees 
        DEXplatform(dex).distributeFeesPool(_tokens, _benficiaries, _amounts);
        
        // Third we update basic virables 
        upcomingLevel = _nextLevel;
        upcomingRound = _nextRound; 
        usedVolume = 0;
    }
    
}