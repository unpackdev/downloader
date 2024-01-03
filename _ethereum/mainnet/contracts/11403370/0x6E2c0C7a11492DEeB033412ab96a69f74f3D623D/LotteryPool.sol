pragma solidity 0.6.12;

import "./ERC1155.sol";
import "./Ownable.sol";
import "./SafeERC20.sol";
import "./IERC20.sol";
import "./SafeMath.sol";
import "./Math.sol";
import "./console.sol";

interface IYouBet is IERC20 {
  function burnFromPool (uint256 amount) external;
}

/**
 * The RumPool is ERC1155 contract does this and that...
 */
contract LotteryPoolV1 is Ownable {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;
  using SafeERC20 for IYouBet;

  IYouBet public YouBetToken;
  uint256 public minPoolCost = 100 ether;
  uint16 public minTickets = 100;
  uint64 public playerBonusRate = 1e4; // over 1e5. percentage of weight to be distributed as playerbonus. 
  uint32 public poolThreshold = 120000; // over 1e5
  uint64 public drawerBonusRate = 8e4; // over 1e5. percentage of weight to reward pool drawer

  address private feeTo;

  address public RNG;
  bool public useExternalRng=false;

  struct PoolInfo {
    IERC20 token;
    uint256 pid;
    uint256 balance;
    uint256 reward;
    uint256 weight;
    uint256 weightBalance;
    address owner;
    uint16 size;
    uint16 tickets;
    uint64 expiry;
    PoolStatus status;
  }

  enum PoolStatus {
    CANCELED,
    OPEN,
    CLOSED
  }

  modifier poolLock(uint256 pid) {
    require(poolLocks[pid] == 0, 'POOL LOCKED');
    poolLocks[pid] = 2;
    _;
    poolLocks[pid] = 0;
  }

  modifier tokenLock(address _token) {
    uint16 state = tokenLocks[_token];
    require(state != 2, 'TOKEN LOCKED');
    if(state==0) tokenLocks[_token] = 2;
    _;
    if(state==0) tokenLocks[_token] = 0;
  }

  // pid => poolInfo
  mapping (uint256 => PoolInfo) public pools;
  mapping (uint256 => uint16) poolLocks;
  mapping (address => uint16) tokenLocks; // 0=open, 1=whitelisted, 2=locked, 
  
  uint256 public poolLength=0;

  // pid => ticketId => candidate
  mapping (uint256 => mapping(uint256 => address)) private poolCandidates;

  // EVENTS
  event Purchase(uint256 indexed poolId, address indexed user,  
        uint16 tickets, address indexed token, uint256 cost);

  event PoolNameChange(uint256 indexed poolId, bytes32 name);

  event PoolProfileImageChange(uint256 indexed poolId, bytes32 imageUrl);

  event WinnerAnnounced(uint256 indexed poolId, address indexed winner, 
        address token, uint256 rewardAmount);

  event RequestRandomness(uint256 indexed poolId);

  event PoolCreated(uint256 indexed poolId, address indexed token, uint256 indexed reward,
    uint256 weight, uint16 tickets, uint256 weightBalance, uint64 expiry);  

  event PoolOwnershipChange(uint256 indexed poolId, address indexed from, address indexed to);

  event UserBonusIssued(address user, uint256 bonus);

  constructor(IYouBet _YouBetToken) public {
    YouBetToken = _YouBetToken;
  }

  function setFeeTo (address _feeTo) onlyOwner external {
    feeTo = _feeTo;
  }  

  function setRNG (address _RNG) onlyOwner external {
    RNG = _RNG;
    useExternalRng = _RNG==address(this)||_RNG==address(0)?false:true;
  }  

  function setMinPoolCost (uint256 _minPoolCost) onlyOwner external {
    minPoolCost = _minPoolCost;
  } 

  function setMinTickets (uint16 _minTickets) onlyOwner external {
    minTickets = _minTickets;
  } 

  function setPlayerBonusRate (uint64 _playerBonusRate) onlyOwner external {
    playerBonusRate = _playerBonusRate;
  }

  function setDrawerBonusRate (uint64 _drawerBonusRate) onlyOwner external {
    drawerBonusRate = _drawerBonusRate;
  }
  
  
  function setTokenLock (address _token, uint16 state) onlyOwner external {
    tokenLocks[_token] = state;
  }

  function _newPool (address _poolOwner, IERC20 _token, uint256 _reward, 
    uint256 _weight, uint16 _tickets, uint256 _weightBalance, uint64 _expiry) internal returns (uint256 _pid){
    _pid = poolLength;
    pools[_pid] = PoolInfo({
      token: _token,
      pid: _pid,
      balance: 0,
      reward: _reward,
      size: 0,
      weight: _weight,
      weightBalance: _weightBalance,
      owner: _poolOwner,
      tickets: _tickets,
      expiry: _expiry,
      status: PoolStatus.OPEN
    });

    emit PoolCreated(_pid, address(_token), _reward, _weight, _tickets, _weightBalance, _expiry);
    emit PoolOwnershipChange(_pid, address(0), _poolOwner);

    // just in case
    poolLength = poolLength.add(1);
  } 

  function _openNewPool (address _poolOwner, IERC20 _token, uint256 _reward, uint256 _weight, 
    uint16 _tickets, uint256 _weightBalance, uint64 _expiry) internal returns (uint256 pid){

    _expiry = uint64(_expiry>now?Math.min(_expiry, now + 4 weeks):now + 4 weeks);
    pid = _newPool(_poolOwner, _token, _reward, _weight, _tickets, _weightBalance, _expiry);
  }

  function renewPool (uint256 _pid, uint256 _weight, uint64 _expiry) external returns(uint64) {

    require (pools[_pid].status == PoolStatus.OPEN, "lottery pool not open");
    require (msg.sender == pools[_pid].owner || msg.sender == owner(), 
      "only pool owner and contract owner are allowed");
    
    require (now < pools[_pid].expiry + 1 weeks, "lottery pool expired more than a week ago");
    require (_weight >= minPoolCost, "Need more YouBetToken");
    _expiry = uint64(_expiry>now?Math.min(_expiry, now + 4 weeks):now + 4 weeks);
    pools[_pid].expiry = _expiry;

    YouBetToken.safeTransferFrom(msg.sender, address(this), _weight); 
    YouBetToken.safeTransfer(feeTo, _weight); 
    pools[_pid].weight = _weight;
    return _expiry;
  }
  

  function openNewPoolByOwner (IERC20 _token, uint256 _reward, uint256 _weight, 
    uint16 _tickets, uint256 _weightBalance, uint64 _expiry) onlyOwner external returns (uint256 pid){
    YouBetToken.safeTransferFrom(msg.sender, address(this), _weightBalance);
    pid = _openNewPool(owner(), _token, _reward, _weight, _tickets, _weightBalance, _expiry);

  }

  function transferPoolOwnership (uint256 _pid, address to) external {
    PoolInfo memory pool = pools[_pid];
    require (pool.status == PoolStatus.OPEN, "Only open pool can have ownership change");    

    address from = msg.sender;
    require (from == pool.owner, "Forbidden");
    pools[_pid].owner = to;

    emit PoolOwnershipChange(_pid, from, to);    
  }

  function _renamePool (uint256 _pid, bytes32 name) internal returns(bool res) {
    emit PoolNameChange(_pid, name);
    res = true;
  }
  
  function renamePoolByOwner (uint256 _pid, bytes32 name) onlyOwner external returns(bool res) {
    res = _renamePool(_pid, name);
  }

  function _setPoolProfileImage (uint256 _pid, bytes32 imageUrl)  internal returns(bool res) {
    emit PoolProfileImageChange(_pid, imageUrl);
    res = true;
  }
  
  function setPoolProfileImage (uint256 _pid, bytes32 imageUrl) external returns(bool res) {
    PoolInfo memory pool = pools[_pid];
    require (pool.status==PoolStatus.OPEN, "pool is not open");
    require (msg.sender == pools[_pid].owner || msg.sender == owner(), 
      "only pool owner and contract owner are allowed");
    uint256 weight = pool.weight;
    YouBetToken.safeTransferFrom(msg.sender, address(this), weight);    
    YouBetToken.safeTransfer(feeTo, weight/2);
    YouBetToken.burnFromPool(weight-weight/2);
    res = _setPoolProfileImage(_pid, imageUrl);
  }

  function withdrawBalanceFromExpiredPool (uint256 _pid) onlyOwner external returns(bool res) {
    PoolInfo memory pool = pools[_pid];
    require (now > pool.expiry + 1 weeks, "lottery pool not dead yet");
    IERC20 _token = pool.token;
    uint256 _balance = pool.balance;
    _token.safeTransfer(owner(), _balance);
    pools[_pid].balance = 0;
    res = true;
  }
  

  function setPoolProfileImageByOwner (uint256 _pid, bytes32 imageUrl) onlyOwner external returns(bool res) {
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

  function openNewPool (IERC20 _token, uint256 _reward, uint256 _weight, 
    uint16 _tickets, uint64 _expiry, bytes32 name) external returns (uint256 pid){

    require (_weight >= minPoolCost, "Need more YouBetToken");

    require (_tickets>=minTickets, "too few tickets");    

    address poolOwner = msg.sender;

    YouBetToken.safeTransferFrom(poolOwner, address(this), _weight);
    uint256 _weightBalance = _weight.mul(playerBonusRate)/1e5;
    YouBetToken.burnFromPool(_weight-_weightBalance);
    
    pid = _openNewPool(poolOwner, _token, _reward, _weight, _tickets, _weightBalance, _expiry);
    if(name != ''){
      _renamePool(pid, name);
    }
  }

  function _newTicket (uint256 _pid, uint256 _ticketId, address _customer) internal {
    poolCandidates[_pid][_ticketId] = _customer;
  }

  function _newTickets (uint256 _pid, address _customer, uint16 _tickets) internal returns (uint256 bonus) {
    PoolInfo memory pool = pools[_pid];
    require (pool.status == PoolStatus.OPEN, "lottery pool not open");
    require (now < pool.expiry, "lottery pool expired");
    require (_tickets > 0, "ticket number should be positive");
    
    uint16 updatedPoolSize = pool.size + _tickets;

    // check for overflow
    require (updatedPoolSize >= pool.size && updatedPoolSize >= _tickets, 
      "too many tickets in a pool");

    uint256 weightBalance = pool.weightBalance;
    bonus = 0;
    
    for (uint i=pool.size; i<updatedPoolSize; i++){
      _newTicket(_pid, i, _customer);
      if(weightBalance>0) {
        uint256 _bonus = weightBalance/pool.tickets; // safe ops

        // sum of bonus always less than weightBalance so no overflow
        bonus += _bonus;

        // safe ops. always greater than 0
        weightBalance -= _bonus;
      }
    }

    pools[_pid].weightBalance = weightBalance;
    
    pools[_pid].size = updatedPoolSize;
    
  }

  function _safeTokenTransfer (address _customer, 
    address _tokenAddress, 
    uint256 cost) tokenLock(_tokenAddress) internal returns(uint256 balanceDelta) {

    IERC20 _token = IERC20(_tokenAddress);
    if(tokenLocks[_tokenAddress]==1){
      _token.safeTransferFrom(_customer, address(this), cost);
      balanceDelta = cost;
    }else{
      uint256 balance0 = _token.balanceOf(address(this));
      _token.safeTransferFrom(_customer, address(this), cost);
      uint256 balance1 = _token.balanceOf(address(this));
      balanceDelta = balance1.sub(balance0);
    }
  }
  
  
  /**
    * @dev users can invoke this function to purchase lottery tickets.
    * @param _pid the pool id where the user is purchasing
    * @param _tickets number of tickets the user is purchasing
    **/
  function buyLottery (uint256 _pid, uint16 _tickets) poolLock(_pid) external {
    address _customer = msg.sender;
    PoolInfo memory pool = pools[_pid];
    uint256 _bonus = _newTickets(_pid, _customer, _tickets);

    IERC20 _token = IERC20(pool.token);

    // safe, since ticket >= minTickets required
    uint256 cost = pool.reward.mul(_tickets)/pool.tickets;
    uint256 balanceDelta = _safeTokenTransfer(_customer, address(_token), cost);

    pools[_pid].balance = pool.balance.add(balanceDelta);

    YouBetToken.safeTransfer(_customer, _bonus);
    emit Purchase(_pid, _customer, _tickets, address(_token), cost);
    emit UserBonusIssued(_customer, _bonus);
  }

  function _safeTransferToWinner (address _tokenAddress, address _winner, 
    uint256 _reward, uint256 _poolBalance, address _poolOwner) tokenLock(_tokenAddress) internal {
    IERC20 _token = IERC20(_tokenAddress);
    _token.safeTransfer(_winner, _reward);

    // _poolBalance is by definition greater than _reward
    uint256 profit = _poolBalance - _reward;

    if(feeTo==address(0)){
      _token.safeTransfer(_poolOwner, profit);
    }else{
      uint256 _poolOwnerShare = profit.mul(997)/1000;
      _token.safeTransfer(_poolOwner, _poolOwnerShare);
      _token.safeTransfer(feeTo, profit-_poolOwnerShare);
    }    
  }
  

  function processWinnningTicket (uint256 _pid, uint256 _ticketId) internal {
    PoolInfo memory pool = pools[_pid];

    require (pool.balance >= pool.reward.mul(poolThreshold)/1e5, "not ready to draw yet");

    require (pool.status==PoolStatus.OPEN, "pool is not open");

    address winner = poolCandidates[_pid][_ticketId];

    IERC20 _token = IERC20(pool.token);
    
    _safeTransferToWinner(address(_token), winner, pool.reward, pool.balance, pool.owner);

    pools[_pid].status = PoolStatus.CLOSED;

    emit WinnerAnnounced(_pid, winner, address(_token), pool.reward);

  }

  // can't be in the same transaction of purchasing tickets
  function _fulfillRandomness (uint256 _pid, uint256 randomness) poolLock(_pid) internal {
    require (randomness > 0, "Bad randomness");

    uint256 winnerTicketId = randomness % pools[_pid].size;

    processWinnningTicket(_pid, winnerTicketId);
  }

  /**
    * @dev allows eligible RNG contract to provide randomness.
    * @param _pid the pool id where randomness is needed.
    * @param randomness a random integer.
    **/
  function fulfillRandomness (uint256 _pid, uint256 randomness) external {
    
    require (msg.sender == RNG, "Forbidden");
    _fulfillRandomness(_pid, randomness);
  }
  
  // Gas is expensive now and anyone can draw so this should be fine today. 
  // Eventually we can move to an external RNG
  function insecurelyGeneratePseudoRandomness (uint256 _pid) internal returns(uint256 randomness) {
    randomness = uint256(keccak256(abi.encodePacked(now, block.coinbase, blockhash(block.number-1))));
    _fulfillRandomness(_pid, randomness);
  }
  
  /**
    * @dev allows anyone to draw the winning ticket for an eligible pool.
    * @param _pid the pool id where user is drawing.
    **/
  function draw (uint256 _pid) external {
    PoolInfo memory pool = pools[_pid];
    require (pool.status==PoolStatus.OPEN, "Pool must be open");
    
    if(useExternalRng){
      emit RequestRandomness(_pid);
    }else{
      insecurelyGeneratePseudoRandomness(_pid);

      // incentive for providing randomness
      uint256 _bonus = pool.weightBalance.mul(drawerBonusRate)/1e5;

      // safe ops
      YouBetToken.burnFromPool(pool.weightBalance-_bonus);
      pool.weightBalance = 0;
      YouBetToken.safeTransfer(msg.sender, _bonus);
      emit UserBonusIssued(msg.sender, _bonus);
    }

  }
  
}
