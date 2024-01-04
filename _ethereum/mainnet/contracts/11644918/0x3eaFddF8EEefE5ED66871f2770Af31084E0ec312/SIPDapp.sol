pragma solidity ^0.7.2;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a,uint256 b,string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
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
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}


library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}


interface IUniswapV2Factory {

    function getPair(address tokenA, address tokenB) external view returns (address pair);
}

interface Chi {

    function freeFromUpTo(address from, uint256 value) external returns (uint256);
    function freeUpTo(uint256 value) external returns (uint256);
    
}

interface Uniswap {
    
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
}

abstract contract Token {
    
    function transfer(address to, uint256 value) public virtual returns (bool);
    
    function transferFrom(address from, address to, uint256 value) public virtual returns (bool);
    
    function approve(address _spender, uint256 _value) public virtual returns (bool);
    
}

contract SIP {
    using SafeMath for uint256;

    event SubscribeToSpp(uint256 indexed sppID,address indexed customerAddress,uint256 value,uint256 period,address indexed tokenGet,address tokenGive);
    event ChargeSpp(uint256 sppID);
    event CloseSpp(uint256 sppID);
    event Deposit(address indexed token,address indexed user,uint256 amount,uint256 balance);
    event Withdraw(address indexed token,address indexed user,uint256 amount,uint256 balance);

    modifier _ownerOnly() {
        require(msg.sender == owner);
        _;
    }

    modifier _ifNotLocked() {
        require(scLock == false);
        _;
    }
    
    modifier discountCHI {
        uint256 gasStart = gasleft();
        _;
        uint256 gasSpent = 21000 +  gasStart -  gasleft() +  (16 * msg.data.length);
        uint256 _feeTokenAmt = Math.min(((gasSpent + 14154) / 41947), tokens[chiToken][msg.sender]);
        if(_feeTokenAmt > 0){
           tokens[chiToken][msg.sender] = tokens[chiToken][msg.sender].sub(_feeTokenAmt);
           Chi(chiToken).freeUpTo(_feeTokenAmt); 
        }
    }

    function setLock() external _ownerOnly {
        scLock = !scLock;
    }

    function changeOwner(address owner_) external _ownerOnly {
        potentialAdmin = owner_;
    }

    function becomeOwner() external {
        if (potentialAdmin == msg.sender) owner = msg.sender;
    }

    function depositToken(address token, uint256 amount) external {
        require(token != address(0), "IT");
        require(Token(token).transferFrom(msg.sender, address(this), amount), "TF");
        tokens[token][msg.sender] = SafeMath.add(
            tokens[token][msg.sender],
            amount
        );
        emit Deposit(token, msg.sender, amount, tokens[token][msg.sender]);
    }

    function withdrawToken(address token, uint256 amount) external {
        require(token != address(0), "IT");
        require(tokens[token][msg.sender] >= amount, "IB");
        tokens[token][msg.sender] = SafeMath.sub(
            tokens[token][msg.sender],
            amount
        );
        require(Token(token).transfer(msg.sender, amount), "WF");
        emit Withdraw(token, msg.sender, amount, tokens[token][msg.sender]);
    }

    function tokenBalanceOf(address token, address user) public view returns (uint256 balance) {
        return tokens[token][user];
    }
    
    function _storePairDetails(address _token0, address _token1, address _pair) internal {
         if(pairDetails[_token0][_token1]==address(0)){ // NOT SET YET
             pairDetails[_token0][_token1] = _pair;
         }
    }    
    

    function subscribeToSpp(uint256 value, uint256 period, address tokenGet, address tokenGive) external _ifNotLocked returns (uint256 sID) {
        address customerAddress = msg.sender;
        require(period >= minPeriod, "MIN_FREQUENCY");
        require(period.mod(3600) == 0, "INTEGRAL_MULTIPLE_OF_HOUR_NEEDED");
        require(tokenBalanceOf(tokenGive,customerAddress) >= value, "INSUFFICENT_BALANCE");
            _deductFee(customerAddress, WETH, initFee);
            sppID += 1;
            
            require(tokenGet != tokenGive, 'IDENTICAL_ADDRESSES');
            (address token0, address token1) = tokenGet < tokenGive ? (tokenGet, tokenGive) : (tokenGive, tokenGet);
            require(token0 != address(0), 'ZERO_ADDRESS');
            address pair = IUniswapV2Factory(factory).getPair(tokenGet, tokenGive); //reverse this and try
            
            require(pair != address(0), 'NO_SUCH_PAIR');
            
            if(token0==tokenGet){
                if(map1[pair].exists== false){
                    map1[pair].token.push(tokenGive);
                    map1[pair].token.push(tokenGet);
                    map1[pair].exists = true;
                    map1[pair].position = 0;
                    _storePairDetails(token0, token1, pair);
                }
                map1[pair].sppList.push(sppID);
            }
            else{
                if(map2[pair].exists== false){
                    map2[pair].token.push(tokenGive);
                    map2[pair].token.push(tokenGet);
                    map2[pair].exists = true;
                    map2[pair].position = 0;
                    _storePairDetails(token0, token1, pair);
                }
                map2[pair].sppList.push(sppID);
            }
            
            sppSubscriptionStats[sppID] = sppSubscribers({
                exists: true,
                customerAddress: customerAddress,
                value: value,
                period: period,
                lastPaidAt: (block.timestamp).sub(period)
            });
            tokenStats[sppID] = currentTokenStats({
                TokenToGet: tokenGet,
                TokenToGive: tokenGive,
                amountGotten: 0,
                amountGiven: 0
            });
            sppSubList[customerAddress].arr.push(sppID);
            emit SubscribeToSpp(sppID,customerAddress,value,period,tokenGet,tokenGive);
            return sppID;
    }
    
    
    function possibleToCharge(uint256 _sppID) public view returns (bool) {
        
        sppSubscribers storage _subscriptionData = sppSubscriptionStats[_sppID];
        currentTokenStats storage _tokenStats = tokenStats[_sppID];
        address tokenGive = _tokenStats.TokenToGive;
        if(_subscriptionData.exists==false){
            return false; // SIP is not active
        }
        else if(tokens[WETH][_subscriptionData.customerAddress] < minWETH){
            return false; // No WETH to pay for fee
        }
        else if(_subscriptionData.value > tokens[tokenGive][_subscriptionData.customerAddress]){
            return false; // Insufficient Balance
        }
        
        return true;
    }


    function chargeWithSPPIndexes(address pair, uint256[] calldata _indexes, bool _upwards) external _ownerOnly _ifNotLocked discountCHI {
        
        uint256 gasStart = 21000 + gasleft() + 3000 +  (16 * msg.data.length);

        uint256[] memory result;
        pairStats storage _pairData = map1[pair]; 
        
        if(!_upwards){
           _pairData = map2[pair]; 
        }
        
        uint256[] storage sppList = _pairData.sppList;
        
        require(sppList.length!=0, "No SIP to charge");
        
        address[] storage pathSwap = _pairData.token;
        
        uint256 finalAmountGive = 0;
        uint256 finalAmountGotten = 0;
        
        chargeSppStruct[] memory sppCharged = new chargeSppStruct[]((_indexes.length + 1));
        
        uint successIndex = 0;
        
        for(uint256 i=0; i< _indexes.length; i++){
            if(_indexes[i] > (sppList.length-1)){
                continue; // No such SIP index. Invalid input. Return and save GAS
            }
            uint256 _sppID = sppList[_indexes[i]];
            sppSubscribers storage _subscriptionData = sppSubscriptionStats[_sppID];
            if(_subscriptionData.exists==false){
                continue; // SIP is not active
            }
            else if(tokens[WETH][_subscriptionData.customerAddress] < minWETH){
                continue; // No WETH to pay for fee
            }
            else if(_subscriptionData.lastPaidAt + _subscriptionData.period > block.timestamp){
                continue; // Charging too early
            }
            else if(_subscriptionData.value > tokens[pathSwap[0]][_subscriptionData.customerAddress]){
                continue; // Insufficient Balance
            }
            else {
                finalAmountGive += _subscriptionData.value;
                _deductTokens(_subscriptionData.value, _subscriptionData.customerAddress, pathSwap[0]);
                sppCharged[successIndex] = chargeSppStruct({
                    sppId: _sppID,
                    amt: _subscriptionData.value,
                    custAdd: _subscriptionData.customerAddress
                });
                successIndex++;
            }
        }
        
        require(finalAmountGive > 0 , "Nothing to charge");
        
        uint256[] memory amounts = Uniswap(uniswapContractAddress).getAmountsOut(finalAmountGive, pathSwap);
        
        require(Token(pathSwap[0]).approve(uniswapContractAddress,finalAmountGive),"approve failed");
        result = Uniswap(uniswapContractAddress).swapExactTokensForTokens(finalAmountGive, amounts[1], pathSwap, address(this), block.timestamp+1000);
        
        // take some fee here first
        finalAmountGotten = result[1];
        finalAmountGotten = finalAmountGotten.sub(_deductSppFee(finalAmountGotten, pathSwap[1]));

        uint256 txFee = (gasStart - gasleft() +  (successIndex * 50000)) * tx.gasprice;
        uint256 _feeDed = txFee;
        
        for(uint256 k=0; k<successIndex; k++){
            uint256 _credAmt = ((sppCharged[k].amt).mul(finalAmountGotten)).div(finalAmountGive);
            uint256 _feeWETH = ((sppCharged[k].amt).mul(txFee)).div(finalAmountGive);
            _creditTokens( _credAmt, sppCharged[k].custAdd, pathSwap[1]);
            _deductTokens(Math.min(_feeWETH, tokens[WETH][sppCharged[k].custAdd]), sppCharged[k].custAdd, WETH);
            _feeDed = _feeDed - Math.min(_feeWETH, tokens[WETH][sppCharged[k].custAdd]);
            require(setcurrentTokenStats(sppCharged[k].sppId, _credAmt, sppCharged[k].amt),"setcurrentTokenStats failed");
            require(setLastPaidAt(sppCharged[k].sppId),"setLastPaidAt failed");
        }
        _creditTokens((txFee - _feeDed), feeAccount, WETH);
    }

    function chargeSppByID(uint256 _sppId) external _ifNotLocked discountCHI {
        
        uint256[] memory result;
        currentTokenStats storage _tokenStats = tokenStats[_sppId];
        
        address tokenGive = _tokenStats.TokenToGive;
        address tokenGet = _tokenStats.TokenToGet;
        
        uint256 finalAmountGive = 0;
        uint256 finalAmountGotten = 0;
        
        address[] memory paths = new address[](2);
        paths[0] = tokenGive;
        paths[1] = tokenGet;
        

        sppSubscribers storage _subscriptionData = sppSubscriptionStats[_sppId];
        require(_subscriptionData.exists==true, "NVS");
        require(_subscriptionData.lastPaidAt + _subscriptionData.period <= block.timestamp, "CTE");
        require(_subscriptionData.value <= tokens[tokenGive][_subscriptionData.customerAddress], "IB");

        finalAmountGive = _subscriptionData.value;
        require(finalAmountGive > 0 , "Nothing to charge");
        
        
        _deductTokens(_subscriptionData.value, _subscriptionData.customerAddress, tokenGive);
        
        
        uint256[] memory amounts = Uniswap(uniswapContractAddress).getAmountsOut(finalAmountGive, paths);
        
        require(Token(tokenGive).approve(uniswapContractAddress,finalAmountGive),"approve failed");
        result = Uniswap(uniswapContractAddress).swapExactTokensForTokens(finalAmountGive, amounts[1], paths, address(this), block.timestamp+1000);
        
        // take some fee here first
        finalAmountGotten = result[1];
        finalAmountGotten = finalAmountGotten.sub(_deductSppFee(finalAmountGotten, tokenGet));

        _creditTokens( finalAmountGotten, _subscriptionData.customerAddress, tokenGet);
        require(setcurrentTokenStats(_sppId, finalAmountGotten, _subscriptionData.value),"setcurrentTokenStats failed");
        require(setLastPaidAt(_sppId),"setLastPaidAt failed");

    }
    
 
    function _deductSppFee(uint256 _amt, address _token) internal returns (uint256) {
        uint256 _feeAmt = ((_amt).mul(fee)).div(10000);
        _creditTokens(_feeAmt, feeAccount, _token);
        return _feeAmt;
    }
    
    function _deductTokens(uint256 _amt, address _custAdd, address _token) internal {
        tokens[_token][_custAdd] = SafeMath.sub(tokens[_token][_custAdd],_amt);
    }
    
    function _creditTokens(uint256 _amt, address _custAdd, address _token) internal {
        tokens[_token][_custAdd] = SafeMath.add(tokens[_token][_custAdd],_amt);
    }
    

    function closeSpp(uint256 _sppId) external returns (bool success) {
        require(msg.sender == sppSubscriptionStats[_sppId].customerAddress, "NA");
        sppSubscriptionStats[_sppId].exists = false;
        inactiveSIP[_sppId] = true;
        emit CloseSpp(_sppId);
        return true;
    }
    
    function _deductFee(address customerAddress, address token, uint256 amount) internal {
        tokens[token][customerAddress] = tokens[token][customerAddress].sub(amount);
        tokens[token][feeAccount] = tokens[token][feeAccount].add(amount);
    }
    

    function setAddresses(address feeAccount1, address uniswapContractAddress1, address factory1, address _chi, address _weth) external _ownerOnly {
        feeAccount = feeAccount1;
        uniswapContractAddress = uniswapContractAddress1;
        factory = factory1;
        chiToken = _chi;
        WETH = _weth;
    }

    function setMinPeriod(uint256 p) external _ownerOnly {
        minPeriod = p;
    }

    function setLastPaidAt(uint256 _sppID) internal returns (bool success) {
        sppSubscribers storage _subscriptionData = sppSubscriptionStats[_sppID];
        _subscriptionData.lastPaidAt = getNearestHour(block.timestamp);
        return true;
    }

    function setcurrentTokenStats(uint256 _sppID, uint256 amountGotten, uint256 amountGiven) internal returns (bool success) {
        currentTokenStats storage _tokenStats = tokenStats[_sppID];
        _tokenStats.amountGotten = _tokenStats.amountGotten.add(amountGotten);
        _tokenStats.amountGiven = _tokenStats.amountGiven.add(amountGiven);
        return true;
    }

    function isActiveSpp(uint256 _sppID) public view returns (bool res) {
        return sppSubscriptionStats[_sppID].exists;
    }
    
     function getLatestSppId() public view returns (uint256 sppId) {
        return sppID;
    }

    function getlistOfSppSubscriptions(address _from) public view returns (uint256[] memory arr) {
        return sppSubList[_from].arr;
    }

    function getcurrentTokenAmounts(uint256 _sppID) public view returns (uint256[2] memory arr) {
        arr[0] = tokenStats[_sppID].amountGotten;
        arr[1] = tokenStats[_sppID].amountGiven;
        return arr;
    }

    function getTokenStats(uint256 _sppID) public view returns (address[2] memory arr) {
        arr[0] = tokenStats[_sppID].TokenToGet;
        arr[1] = tokenStats[_sppID].TokenToGive;
        return arr;
    }
    
    function fetchPairAndDirection(uint256 _sppID) public view returns (bool direction, address pair) {
        currentTokenStats storage _tokenStats = tokenStats[_sppID];
        
        address tokenGive = _tokenStats.TokenToGive;
        address tokenGet = _tokenStats.TokenToGet;

        (address token0, address token1) = tokenGet < tokenGive ? (tokenGet, tokenGive) : (tokenGive, tokenGet);

        address _pair = pairDetails[token0][token1];
        bool _direction = false;

        if(token0==tokenGet){
            _direction = true;
        }
        return (_direction, _pair);
    }
    
    function fetchPathDetailsAdd(address _pair, bool _upwards) public view returns (address[] memory arr) {
        if (_upwards){
           return map1[_pair].token; 
        }
        else {
            return map2[_pair].token;
        }
    }
    
    function fetchPathDetailsSPP(address _pair, bool _upwards) public view returns (uint256[] memory arr) {
        if (_upwards){
           return map1[_pair].sppList; 
        }
        else {
            return map2[_pair].sppList;
        }
    }

    function getTimeRemainingToCharge(uint256 _sppID) public view returns (uint256 time) {
        if((sppSubscriptionStats[_sppID].lastPaidAt).add(sppSubscriptionStats[_sppID].period) < block.timestamp){
            return 0;
        }
        else {
          return ((sppSubscriptionStats[_sppID].lastPaidAt).add(sppSubscriptionStats[_sppID].period).sub(block.timestamp));  
        }
    }
    
    // Update dev address by initiating with the previous dev.
    function changeFee(uint8 _fee) external _ownerOnly{
        require(_fee <= 25, "Cannot increase fee beyond 25");
        fee = _fee;
    }

    // Update min WETH needed for cgarge SIP to run.
    function changeMinWETH(uint256 _minWETH) external _ownerOnly{
        minWETH = _minWETH;
    }

    // Update min WETH needed for cgarge SIP to run.
    function setInitFee(uint256 _initFee) external _ownerOnly{
        initFee = _initFee;
    }
    
    // Change starting position of a pair.
    function changePosition(address pair, uint256 _index, bool _upwards) external _ownerOnly{
        if(_upwards){
            map1[pair].position = _index;
        }
        else {
            map2[pair].position = _index;
        }
    }
    
    // This function is to optimise batching process
    function getNearestHour(uint256 _time) public pure returns (uint256) {
        uint256 _secondsExtra = _time.mod(3600);
        if(_secondsExtra > 1800){
            return ((_time).add(3600)).sub(_secondsExtra);
        }
        else {
            return (_time).sub(_secondsExtra);
        }
    }

    struct sppSubscribers {
        bool exists;
        address customerAddress;
        uint256 value; 
        uint256 period;
        uint256 lastPaidAt;
    }

    struct currentTokenStats {
        address TokenToGet;
        uint256 amountGotten;
        address TokenToGive;
        uint256 amountGiven;
    }

    struct listOfSppByAddress {
        uint256[] arr;
    }
    
    struct pairStats{
        address[] token;
        uint256[] sppList;
        bool exists;
        uint256 position;
    }
    
    struct chargeSppStruct {
        uint256 sppId;
        uint256 amt;
        address custAdd;
    }
    
    mapping(uint256 => uint256) public sppAmounts;
    mapping(address => pairStats) private map1;
    mapping(address => pairStats) private map2;
    mapping(uint256 => currentTokenStats) tokenStats;
    mapping(address => listOfSppByAddress) sppSubList;
    mapping(uint256 => sppSubscribers) public sppSubscriptionStats;
    mapping(address => mapping(address => uint256)) public tokens;

    mapping(uint256 => bool) public inactiveSIP; // contains a SIP ID only if it existed and now has been deactivated
    
    // TOKEN0 -> TOKEN1 -> PAIRADD
    mapping(address => mapping(address => address)) public pairDetails;

    
    address public uniswapContractAddress;
    address public factory;
    address public owner;
    address public chiToken;
    address public WETH;
    address private potentialAdmin;
    uint256 public sppID;
    address public feeAccount;
    bool public scLock = false;
    uint8 public fee = 25;
    uint256 public minPeriod = 3600;
    uint256 public minWETH;
    uint256 public initFee;
    
}

contract SIPDapp is SIP {
    receive() external payable {
        revert();
    }

    string public name;

    constructor() {
        owner = msg.sender;
        name = "BNS SIP Dapp";
    }
}