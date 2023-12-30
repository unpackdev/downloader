pragma solidity >=0.5.12 <0.7.0;

library SafeMath {
  /**
   * @dev Returns the addition of two unsigned integers, reverting on
   * overflow.
   *
   * Counterpart to Solidity's `+` operator.
   *
   * Requirements:
   * - Addition cannot overflow.
   */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, "SafeMath: addition overflow");

    return c;
  }

  /**
   * @dev Returns the subtraction of two unsigned integers, reverting on
   * overflow (when the result is negative).
   *
   * Counterpart to Solidity's `-` operator.
   *
   * Requirements:
   * - Subtraction cannot overflow.
   */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    return sub(a, b, "SafeMath: subtraction overflow");
  }

  /**
   * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
   * overflow (when the result is negative).
   *
   * Counterpart to Solidity's `-` operator.
   *
   * Requirements:
   * - Subtraction cannot overflow.
   */
  function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    require(b <= a, errorMessage);
    uint256 c = a - b;

    return c;
  }

  /**
   * @dev Returns the multiplication of two unsigned integers, reverting on
   * overflow.
   *
   * Counterpart to Solidity's `*` operator.
   *
   * Requirements:
   * - Multiplication cannot overflow.
   */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b, "SafeMath: multiplication overflow");

    return c;
  }

  /**
   * @dev Returns the integer division of two unsigned integers. Reverts on
   * division by zero. The result is rounded towards zero.
   *
   * Counterpart to Solidity's `/` operator. Note: this function uses a
   * `revert` opcode (which leaves remaining gas untouched) while Solidity
   * uses an invalid opcode to revert (consuming all remaining gas).
   *
   * Requirements:
   * - The divisor cannot be zero.
   */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    return div(a, b, "SafeMath: division by zero");
  }

  /**
   * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
   * division by zero. The result is rounded towards zero.
   *
   * Counterpart to Solidity's `/` operator. Note: this function uses a
   * `revert` opcode (which leaves remaining gas untouched) while Solidity
   * uses an invalid opcode to revert (consuming all remaining gas).
   *
   * Requirements:
   * - The divisor cannot be zero.
   */
  function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    // Solidity only automatically asserts when dividing by 0
    require(b > 0, errorMessage);
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold

    return c;
  }

  /**
   * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
   * Reverts when dividing by zero.
   *
   * Counterpart to Solidity's `%` operator. This function uses a `revert`
   * opcode (which leaves remaining gas untouched) while Solidity uses an
   * invalid opcode to revert (consuming all remaining gas).
   *
   * Requirements:
   * - The divisor cannot be zero.
   */
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    return mod(a, b, "SafeMath: modulo by zero");
  }

  /**
   * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
   * Reverts with custom message when dividing by zero.
   *
   * Counterpart to Solidity's `%` operator. This function uses a `revert`
   * opcode (which leaves remaining gas untouched) while Solidity uses an
   * invalid opcode to revert (consuming all remaining gas).
   *
   * Requirements:
   * - The divisor cannot be zero.
   */
  function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    require(b != 0, errorMessage);
    return a % b;
  }
}

contract Matrix {
  using SafeMath for uint256;

  struct User {
    address wallet;
    uint referrerCount;
    address parent;
    uint256 earnedFromPool;
    uint256 earnedFromRef;
    uint256 earnedFromPoolRef;
    address[] referrals;
  }

  struct PoolMember{
    address userAddress;
    uint8 paymentsCount;
    bool done;
  }

  struct Pool{
    uint256 number;
    uint256 cost;
    uint256 membersCount;
    uint256 pendingIndex;
  }

  struct PendingSlot{
    uint8 pool;
    address addr;
    uint256 entryTime;
  }

  PendingSlot[] public pendingSlots;
  uint256 public pendingSlotIndex = 0;

  mapping(uint8 => Pool) public pools;
  mapping(uint8 => PoolMember[]) public PoolMembers;


  // 27 june 3 PM GM
  uint256 public startTime = 1593270000;


  event Register(address indexed _addr, address indexed _parent, uint256 _time);
  event PoolRegister(address indexed _addr, uint8 _pool, uint256 _time);
  event PoolReward(address indexed _addr, uint8 _pool, uint256 _amount, uint256 _time);

  event RefReward(address indexed _addr, address indexed _sender, uint8 _pool, uint8 _level, uint256 _amount, uint256 _time);

  event Reinvest(address indexed _addr, uint8 _pool, uint256 _time);

  event AddPendingSolt(address indexed _addr, uint8 _pool, uint256 _time);

  uint256[] public poolCosts = [
    0.05 ether,
    0.1 ether,
    0.25 ether,
    0.5 ether,
    1 ether,
    2 ether
  ];
  
  address payable public admin;
  address payable public operator;

  mapping (address => address payable) public parents;
  mapping (address => User) public users;

  mapping(uint8 => uint256) registerRewards;


  modifier isAdmin(){
    require(msg.sender == admin);
    _;
  }

  modifier isOperator(){
    require(msg.sender == admin || msg.sender==operator);
    _;
  }

  constructor() public {
    admin = 0x3314F3918573a408e331c7fbCa2a9E697d1B87f6;
    operator = 0x1551DDaAb0cf575D1a252554a8615C49FD521241;

    registerRewards[1] = 0.015 ether;
    registerRewards[2] = 0.005 ether;
    registerRewards[3] = 0.0025 ether;
    registerRewards[4] = 0.0025 ether;
    registerRewards[5] = 0.0025 ether;
    registerRewards[6] = 0.0025 ether;
    registerRewards[7] = 0.0025 ether;
    registerRewards[8] = 0.0025 ether;
    registerRewards[9] = 0.0025 ether;
    registerRewards[10] = 0.0025 ether;

    for(uint8 i = 0; i < poolCosts.length; i++){
      pools[i+1] = Pool({
        number: i+1,
        cost: poolCosts[i],
        membersCount: 1,
        pendingIndex: 0
      });
      
      PoolMembers[i+1].push(PoolMember({
         userAddress: msg.sender,
         paymentsCount: 2,
         done: false
      }));
    }
  }
  
  function register(address _parent, address _forAddress) public payable {
    address forAddress = _forAddress==address(0) ? msg.sender : _forAddress;

    require(msg.value == 0.05 ether, "the fee is 0.05");

    users[forAddress] = User({
      wallet: forAddress,
      referrerCount: 0,
      parent: _parent,
      earnedFromPool: 0,
      earnedFromRef: 0,
      earnedFromPoolRef: 0,
      referrals: new address[](0)
    });
    
    if(_parent != address(0) && users[_parent].wallet != address(0)){
      users[_parent].referrals.push(forAddress);
      users[_parent].referrerCount+=1;

      parents[forAddress] = payable(_parent);
    }
    
    // distribute funds
    uint256 operatorAmount = 0.01 ether;

    address refer = forAddress;


    for(uint8 i=1; i <=10; i++){
      if(refer != address(0) && parents[refer] != address(0)){

        parents[refer].transfer(registerRewards[i]);

        emit RefReward(parents[refer], forAddress, 0, i, registerRewards[i], now);

        users[parents[refer]].earnedFromRef += registerRewards[i];
        refer = parents[refer];
      }else{
        refer = address(0);
        operatorAmount = operatorAmount.add(registerRewards[i]);
      }
    }
    operator.transfer(operatorAmount);

    emit Register(forAddress, _parent, now);
  }

  function participatePool(uint8 _pool, address _forAddress) public payable {
    require(now > startTime, "Not started yet.");
    address forAddress = (_forAddress==address(0)) ? msg.sender : _forAddress;

    require(users[forAddress].wallet != address(0), "Not registered");
    require(_pool > 0 && _pool <= poolCosts.length);
    require(poolCosts[_pool-1].mul(4).add(0.01 ether) == msg.value, "Cost mismatch");

    operator.transfer(0.01 ether);

    PoolRegister(forAddress, _pool, now);
    _addToPool(_pool, forAddress);

    enterPendingSlots();

    uint256 t = now;
    pendingSlots.push(PendingSlot({
      pool: _pool,
      addr: forAddress,
      entryTime: t.add(24*3600)
    }));

    AddPendingSolt(forAddress, _pool, t.add(24*3600));

    pendingSlots.push(PendingSlot({
      pool: _pool,
      addr: forAddress,
      entryTime: t.add(2*24*3600)
    }));

    AddPendingSolt(forAddress, _pool, t.add(2*24*3600));

    pendingSlots.push(PendingSlot({
      pool: _pool,
      addr: forAddress,
      entryTime: t.add(3*24*3600)
    }));

    AddPendingSolt(forAddress, _pool, t.add(3*24*3600));
  }

  function _addToPool(uint8 _pool, address _addr) internal{
    PoolMembers[_pool].push(PoolMember({
      userAddress: _addr,
      paymentsCount: 0,
      done: false
    }));
    pools[_pool].membersCount += 1;
    _poolPay(_pool);
  }

  function _poolPay(uint8 _pool) internal{
    uint256 indx = pools[_pool].pendingIndex;
    PoolMembers[_pool][indx].paymentsCount += 1;
    
    if(PoolMembers[_pool][indx].paymentsCount >= 3){
      PoolMembers[_pool][indx].done = true;

      payable(PoolMembers[_pool][indx].userAddress).transfer(
        poolCosts[_pool-1]
      );
      emit PoolReward(
        PoolMembers[_pool][indx].userAddress, 
        _pool, poolCosts[_pool-1], 
        now);

      users[PoolMembers[_pool][indx].userAddress].earnedFromPool += poolCosts[_pool-1];
      if(parents[PoolMembers[_pool][indx].userAddress] == address(0)){
        payable(parents[PoolMembers[_pool][indx].userAddress]).transfer(
          poolCosts[_pool-1]
        );
        users[parents[PoolMembers[_pool][indx].userAddress]].earnedFromPoolRef += poolCosts[_pool-1];

        emit RefReward(
          parents[PoolMembers[_pool][indx].userAddress],
          PoolMembers[_pool][indx].userAddress,
          _pool,
          0,
          poolCosts[_pool-1],
          now
        );

      }else{
        operator.transfer(
          poolCosts[_pool-1]
        );
      }
      pools[_pool].pendingIndex += 1;

      // re-invest
      _addToPool(_pool, PoolMembers[_pool][indx].userAddress);
      Reinvest(PoolMembers[_pool][indx].userAddress, _pool, now);
    }
  }

  function enterPendingSlots() public{
    for(uint256 i = pendingSlotIndex; i < pendingSlots.length; i++){
      if(pendingSlots[i].entryTime <= now){
        _addToPool(pendingSlots[i].pool, pendingSlots[i].addr);
        pendingSlotIndex += 1;
      }
    }
  }

  function pendingSlotsCount() view public returns(uint256){
    uint256 ret = 0;
    for(uint256 i = pendingSlotIndex; i < pendingSlots.length; i++){
      if(pendingSlots[i].entryTime <= now){
        ret += 1;
      }
    }
    return ret;
  }

  function adminWithdraw(uint256 _amount) isAdmin public{
    msg.sender.transfer(_amount);
  }

  function adminUpdateStartTime(uint256 _time) isAdmin public{
    startTime = _time;
  }

  receive() payable external isAdmin{
    // admin can send ETH to contract
  }
}