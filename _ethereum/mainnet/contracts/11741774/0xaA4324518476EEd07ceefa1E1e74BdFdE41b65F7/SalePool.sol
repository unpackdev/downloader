pragma solidity 0.6.12;

import "./ERC1155.sol";
import "./Ownable.sol";
import "./SafeERC20.sol";
import "./IERC20.sol";
import "./SafeMath.sol";
import "./Math.sol";
// import "./console.sol";

interface IYouBet is IERC20 {
  function burnFromPool (uint amount) external;
}

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}

/**
 * The RumPool is ERC1155 contract does this and that...
 */
contract SalePoolV1 is Ownable {
  using SafeMath for uint;
  using SafeERC20 for IERC20;
  using SafeERC20 for IYouBet;

  IYouBet public YouBetToken;
  address public WETH;
  uint public minPoolCost = 100 ether;

  uint64 public perOrderCommissionRate=1e3; // over1e5
  uint64 public contestRewardRate=1e3; // over1e5

  address private feeTo;

  struct PoolInfo {
    IERC20 token;
    address currencyToken;
    address owner;
    address winnerCandidate;
    uint pid;
    uint112 balance;
    uint112 reward;
    uint112 weight;
    uint112 exchangeRate; // exchangeRate*amountInToken/1e18 = amountInCurrency
    uint112 winnerCandidateSales;
    uint64 expiry;
    PoolStatus status;
  }

  enum PoolStatus {
    CANCELED,
    OPEN,
    CLOSED
  }

  modifier tokenLock(address _token) {
    uint16 state = tokenLocks[_token];
    require(state != 2, 'TOKEN LOCKED');
    if(state==0) tokenLocks[_token] = 2;
    _;
    if(state==0) tokenLocks[_token] = 0;
  }

  // pid => poolInfo
  mapping (uint => PoolInfo) public pools;
  mapping (address => uint16) tokenLocks; // 0=open, 1=whitelisted, 2=locked, 
  
  uint public poolLength=0;

  // pid => referrer => sales
  mapping (uint => mapping(address => uint)) public poolReferrerSales;

  // EVENTS
  event Purchase(uint indexed poolId, address indexed user,  
        uint amount, address indexed token, address currencyToken, uint cost);

  event PoolNameChange(uint indexed poolId, bytes32 name);

  event PoolProfileImageChange(uint indexed poolId, bytes32 imageUrl);

  event WinnerAnnounced(uint indexed poolId, address indexed winner, 
        uint salesAmount, address token, 
        address currencyToken, uint rewardAmount);

  event PoolCreated(uint indexed poolId, address indexed token, 
    address indexed currencyToken, uint exchangeRate, 
    uint amount,
    uint weight, uint64 expiry);  

  event PoolOwnershipChange(uint indexed poolId, address indexed from, address indexed to);

  event Commission(address indexed referrer, address indexed customer, 
    address indexed currency, uint commission);

  constructor(IYouBet _YouBetToken, address _weth) public {
    YouBetToken = _YouBetToken;
    WETH = _weth;
  }

  receive() external payable {
    require(msg.sender == WETH); // only accept ETH via fallback from the WETH contract
  }

  function setFeeTo (address _feeTo) onlyOwner external {
    feeTo = _feeTo;
  }  

  function setMinPoolCost (uint _minPoolCost) onlyOwner external {
    minPoolCost = _minPoolCost;
  } 

  function setPerOrderCommissionRate (uint64 _r) onlyOwner external {
    perOrderCommissionRate = _r;
  } 

  function setContestRewardRate (uint64 _r) onlyOwner external {
    contestRewardRate = _r;
  } 
  
  
  function setTokenLock (address _token, uint16 state) onlyOwner external {
    tokenLocks[_token] = state;
  }

  function _newPool (address _poolOwner, IERC20 _token, 
    address _currencyToken, uint112 _exchangeRate, 
    uint _reward, 
    uint _weight, uint64 _expiry) internal returns (uint _pid){
    require(_reward <= uint112(-1) && _weight <= uint112(-1), 'OVERFLOW');
    _pid = poolLength;
    pools[_pid] = PoolInfo({
      token: _token,
      currencyToken: _currencyToken,
      exchangeRate: _exchangeRate,
      pid: _pid,
      balance: 0,
      reward: uint112(_reward),
      weight: uint112(_weight),
      owner: _poolOwner,
      expiry: _expiry,
      status: PoolStatus.OPEN,
      winnerCandidate: _poolOwner,
      winnerCandidateSales: 0
    });

    emit PoolCreated(_pid, address(_token), 
      address(_currencyToken), _exchangeRate, _reward, _weight, _expiry); 

    emit PoolOwnershipChange(_pid, address(0), _poolOwner);

    // just in case
    poolLength = poolLength.add(1);
  } 

  function _openNewPool (address _poolOwner, IERC20 _token, 
    address _currencyToken, uint112 _exchangeRate,
    uint _reward, uint _weight, uint64 _expiry) internal returns (uint pid){

    _expiry = uint64(_expiry>now?Math.min(_expiry, now + 4 weeks):now + 4 weeks);
    pid = _newPool(_poolOwner, _token, 
      _currencyToken, _exchangeRate,
      _reward, _weight, _expiry);
  }

  function renewPool (uint _pid, uint _weight, uint64 _expiry) external returns(uint64) {

    require (pools[_pid].status == PoolStatus.OPEN, "lottery pool not open");
    require (msg.sender == pools[_pid].owner || msg.sender == owner(), 
      "only pool owner and contract owner are allowed");
    
    require (now < pools[_pid].expiry + 4 weeks, "lottery pool expired more than 4 weeks ago");
    require (_weight >= minPoolCost, "Need more YouBetToken");
    _expiry = uint64(_expiry>now?Math.min(_expiry, now + 4 weeks):now + 4 weeks);
    pools[_pid].expiry = _expiry;

    YouBetToken.safeTransferFrom(msg.sender, address(this), _weight); 
    YouBetToken.safeTransfer(feeTo, _weight); 
    require(_weight <= uint112(-1), 'OVERFLOW');
    pools[_pid].weight = uint112(_weight);
    return _expiry;
  }
  

  function openNewPoolByOwner (IERC20 _token, address _currencyToken, uint112 _exchangeRate,
    uint _reward, uint _weight, uint64 _expiry) onlyOwner external returns (uint pid){
    pid = _openNewPool(owner(), _token, _currencyToken, _exchangeRate,
      _reward, _weight, _expiry);

  }

  function transferPoolOwnership (uint _pid, address to) external {
    PoolInfo memory pool = pools[_pid];
    require (pool.status == PoolStatus.OPEN, "Only open pool can have ownership change");    

    address from = msg.sender;
    require (from == pool.owner, "Forbidden");
    pools[_pid].owner = to;

    emit PoolOwnershipChange(_pid, from, to);    
  }

  function _renamePool (uint _pid, bytes32 name) internal returns(bool res) {
    emit PoolNameChange(_pid, name);
    res = true;
  }
  
  function renamePoolByOwner (uint _pid, bytes32 name) onlyOwner external returns(bool res) {
    res = _renamePool(_pid, name);
  }

  function _setPoolProfileImage (uint _pid, bytes32 imageUrl)  internal returns(bool res) {
    emit PoolProfileImageChange(_pid, imageUrl);
    res = true;
  }
  
  function setPoolProfileImage (uint _pid, bytes32 imageUrl) external returns(bool res) {
    PoolInfo memory pool = pools[_pid];
    require (pool.status==PoolStatus.OPEN, "pool is not open");
    require (msg.sender == pools[_pid].owner || msg.sender == owner(), 
      "only pool owner and contract owner are allowed");
    uint weight = pool.weight;
    YouBetToken.safeTransferFrom(msg.sender, address(this), weight);    
    YouBetToken.safeTransfer(feeTo, weight/2);
    YouBetToken.burnFromPool(weight-weight/2);
    res = _setPoolProfileImage(_pid, imageUrl);
  }

  function withdrawBalanceFromExpiredPool (uint _pid) onlyOwner external returns(bool res) {
    require (now > pools[_pid].expiry + 4 weeks, "lottery pool not dead yet");
    IERC20 _token = pools[_pid].token;
    IERC20 _currencyToken = IERC20(pools[_pid].currencyToken);
    uint _balance = pools[_pid].balance;
    uint _reward = pools[_pid].reward;
    _currencyToken.safeTransfer(owner(), _balance);
    _token.safeTransfer(owner(), _reward);
    pools[_pid].balance = 0;
    res = true;
  }
  

  function setPoolProfileImageByOwner (uint _pid, bytes32 imageUrl) onlyOwner external returns(bool res) {
    res = _setPoolProfileImage(_pid, imageUrl);
  } 
  

  /**
    * @dev users can invoke this function to open a new pool.
    * @param _token the ERC20 token of the reward.
    * @param _reward the amount of reward.
    * @param _weight determines how the pool ranks in frontend.
    * @param _expiry the timestamp the pool expires. when a pool expires
    * the owner will have to pay to renew it or it won't accept new entries.
    **/

  function openNewPool (IERC20 _token, address _currencyToken, uint112 _exchangeRate,
    uint _reward, uint _weight, uint64 _expiry, bytes32 name) external returns (uint pid){

    // require (_weight >= minPoolCost, "Need more YouBetToken");

    address poolOwner = msg.sender;

    _reward = _safeTokenTransfer(poolOwner, address(_token), _reward, address(0));

    if(_weight>0) {
      YouBetToken.safeTransferFrom(poolOwner, address(this), _weight);
      YouBetToken.safeTransfer(feeTo, _weight);
    }    
    
    pid = _openNewPool(poolOwner, _token, _currencyToken, _exchangeRate,
      _reward, _weight, _expiry);
    if(name != ''){
      _renamePool(pid, name);
    }
  }

  function _safeTokenTransfer (address _from, 
    address _tokenAddress, 
    uint cost, address referrer) tokenLock(_tokenAddress) internal returns(uint balanceDelta) {

    IERC20 _token = IERC20(_tokenAddress);
    if(tokenLocks[_tokenAddress]==1){
      _token.safeTransferFrom(_from, address(this), cost);
      if(referrer != address(0)){
        uint commission = cost.mul(perOrderCommissionRate)/1e5;
        _token.safeTransfer(referrer, commission);
        balanceDelta = cost - commission;
      }else{
        balanceDelta = cost;
      }      
    }else{
      uint balance0 = _token.balanceOf(address(this));
      _token.safeTransferFrom(_from, address(this), cost);
      if(referrer != address(0)){
        uint commission = cost.mul(perOrderCommissionRate)/1e5;
        _token.safeTransfer(referrer, commission);
        emit Commission(referrer, _from, _tokenAddress, commission);
      }
      uint balance1 = _token.balanceOf(address(this));
      balanceDelta = balance1.sub(balance0);
    }
  }

  /**
    * @dev users can invoke this function to purchase tokens.
    * @param _pid the pool id where the user is purchasing
    * @param _purchaseAmount amount in token to purchase
    **/
  function buyTokenWithETH (uint _pid, uint _purchaseAmount, 
    address referrer) external payable {
    address _customer = msg.sender;
    require (pools[_pid].status == PoolStatus.OPEN, "lottery pool not open");
    require (now < pools[_pid].expiry, "lottery pool expired");

    IERC20 _pooltoken = IERC20(pools[_pid].token);
    address _poolCurrencyToken = pools[_pid].currencyToken;

    require (_poolCurrencyToken==WETH);    

    uint cost = _purchaseAmount.mul(pools[_pid].exchangeRate)/1e18;

    IWETH(WETH).deposit{value: cost}();

    if(referrer != address(0)){
      uint commission = cost.mul(perOrderCommissionRate)/1e5;
      IERC20(WETH).safeTransfer(referrer, commission);
      // will not undeflow
      cost -= commission;
      emit Commission(referrer, _customer, WETH, commission);
    }

    uint _balance = cost.add(pools[_pid].balance);
    uint _rewardBalance = _pooltoken.balanceOf(address(this));
    require(_balance <= uint112(-1) && _rewardBalance <= uint112(-1), 'OVERFLOW');
    pools[_pid].balance = uint112(_balance);

    _pooltoken.safeTransfer(_customer, _purchaseAmount);

    // will not overflow
    uint112 _newReward = uint112(uint(pools[_pid].reward).sub(_purchaseAmount));
    uint112 _rewardRealBalance = uint112(_rewardBalance);
    pools[_pid].reward = _newReward<_rewardRealBalance?_newReward:_rewardRealBalance;

    if(referrer != address(0)) {
      uint newReferrarSales = _purchaseAmount.add(poolReferrerSales[_pid][referrer]);
      require(newReferrarSales <= uint112(-1), 'OVERFLOW');
      poolReferrerSales[_pid][referrer] = newReferrarSales;
      if(newReferrarSales > pools[_pid].winnerCandidateSales){
        pools[_pid].winnerCandidateSales = uint112(newReferrarSales);
        pools[_pid].winnerCandidate = referrer;
      }

    }

    emit Purchase(_pid, _customer, _purchaseAmount, 
      address(_pooltoken), _poolCurrencyToken, cost);
  }
  
  
  /**
    * @dev users can invoke this function to purchase tokens.
    * @param _pid the pool id where the user is purchasing
    * @param _purchaseAmount amount in token to purchase
    **/
  function buyToken (uint _pid, uint _purchaseAmount, address referrer) external {
    address _customer = msg.sender;
    require (pools[_pid].status == PoolStatus.OPEN, "lottery pool not open");
    require (now < pools[_pid].expiry, "lottery pool expired");

    IERC20 _pooltoken = IERC20(pools[_pid].token);
    address _poolCurrencyToken = pools[_pid].currencyToken;

    uint cost = _purchaseAmount.mul(pools[_pid].exchangeRate)/1e18;
    uint balanceDelta = _safeTokenTransfer(_customer, _poolCurrencyToken, cost, referrer);

    uint _balance = balanceDelta.add(pools[_pid].balance);
    uint _rewardBalance = _pooltoken.balanceOf(address(this));
    require(_balance <= uint112(-1) && _rewardBalance <= uint112(-1), 'OVERFLOW');
    pools[_pid].balance = uint112(_balance);

    _pooltoken.safeTransfer(_customer, _purchaseAmount);

    // will not overflow
    uint112 _newReward = uint112(uint(pools[_pid].reward).sub(_purchaseAmount));
    uint112 _rewardRealBalance = uint112(_rewardBalance);
    pools[_pid].reward = _newReward<_rewardRealBalance?_newReward:_rewardRealBalance;

    if(referrer != address(0)) {
      uint newReferrarSales = _purchaseAmount.add(poolReferrerSales[_pid][referrer]);
      require(newReferrarSales <= uint112(-1), 'OVERFLOW');
      poolReferrerSales[_pid][referrer] = newReferrarSales;
      if(newReferrarSales > pools[_pid].winnerCandidateSales){
        pools[_pid].winnerCandidateSales = uint112(newReferrarSales);
        pools[_pid].winnerCandidate = referrer;
      }
      
    }

    emit Purchase(_pid, _customer, _purchaseAmount, 
      address(_pooltoken), _poolCurrencyToken, cost);
  }


  function processContestWinner (uint _pid, uint _contestReward) internal {

    address winner = pools[_pid].winnerCandidate;

    IERC20 _poolCurrencyToken = IERC20(pools[_pid].currencyToken);

    _poolCurrencyToken.safeTransfer(winner, _contestReward);

    pools[_pid].status = PoolStatus.CLOSED;

    emit WinnerAnnounced(_pid, winner, 
      pools[_pid].winnerCandidateSales, address(pools[_pid].token),
      address(_poolCurrencyToken), _contestReward);

  }
  
  /**
    * @dev allows anyone to draw the winning ticket for an eligible pool.
    * @param _pid the pool id where user is drawing.
    **/
  function closePool (uint _pid) external {
    address _poolOwner = pools[_pid].owner;

    require (pools[_pid].status==PoolStatus.OPEN, "Pool must be open");

    require (_poolOwner==msg.sender||msg.sender==owner(), "unauthorized");

    IERC20 _pooltoken = IERC20(pools[_pid].token);
    IERC20 _poolCurrencyToken = IERC20(pools[_pid].currencyToken);
    uint _poolReward = pools[_pid].reward;
    uint _poolExchangeRate = pools[_pid].exchangeRate;
    uint _poolBalance = pools[_pid].balance;

    uint _fees = _poolBalance/100;
    uint _contestReward = _poolBalance.mul(contestRewardRate)/1e5;
    uint _poolOwnerRevenue = _poolBalance - _fees - _contestReward;

    _poolCurrencyToken.safeTransfer(_poolOwner, _poolOwnerRevenue);
    _pooltoken.safeTransfer(_poolOwner, _poolReward);

    _poolCurrencyToken.safeTransfer(feeTo, _fees);

    processContestWinner(_pid, _contestReward);

  }
  
}
