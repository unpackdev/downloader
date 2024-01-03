pragma solidity >=0.4.22 <0.7.0;


/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
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
     *
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
     *
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
     *
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
     *
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
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
     *
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
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}


contract mini_lottery{
    using SafeMath for uint256; 
    
    struct Commit {
        uint256 commit;
        uint256 bet_value;
        uint256 reward;
        uint64 block;
        bool revealed;
    }
  
  event Log_withdraw(address indexed _from, uint256 _value);
  event Log_commit(address sender, uint256 seed, uint64 block, uint256 value);
  event Log_reveal(address sender, uint256 random, uint256 reward);
  event Log_debug(address a, address b);


  mapping (address => Commit) public _commits;
  address private _owner = msg.sender;
  bool internal _lock = false; //mutex
  uint256 private _remain_reward = 0; //total remained reward to paid
  uint256 private _total_prize = 0; //total prize
  uint256 private _randNonce = 0;
  uint256 private _commision = 0; 

  constructor() public {
      _owner = msg.sender;
  }
  
  function commit() public payable {
    require(msg.value >= 0.01 ether, "Shall >= 0.01 ether");
    require(msg.value <= 0.1 ether, "Shall <= 0.1 ether");
    require(_commits[msg.sender].bet_value==0, "Your previous draw is still under processing!");
    
    _commits[msg.sender].commit = random();
    _commits[msg.sender].bet_value = msg.value;
    _commits[msg.sender].block = uint64(block.number);
    _commits[msg.sender].revealed = false;
    _commision += msg.value.div(10);
    
    emit Log_commit(msg.sender, _commits[msg.sender].commit, _commits[msg.sender].block, msg.value);
  }
  
  function reveal() public {
    //ensure commit first
    require(_commits[msg.sender].bet_value>0,"CommitReveal::reveal: not commited");
    //make sure it hasn't been revealed yet and set it to revealed
    require(_commits[msg.sender].revealed==false,"CommitReveal::reveal: Already revealed");
    _commits[msg.sender].revealed=true;
    //require that the block number is greater than the original block
    require(uint64(block.number)>_commits[msg.sender].block,"CommitReveal::reveal: Reveal and commit happened on the same block");
    //require that no more than 250 blocks have passed
    require(uint64(block.number)<=_commits[msg.sender].block+250,"CommitReveal::reveal: Revealed too late");
    
    //get the hash of the block that happened after they committed
    bytes32 blockHash = blockhash(_commits[msg.sender].block);
    //hash that with their reveal that so miner shouldn't know 
    uint256 random = get_random(blockHash, _commits[msg.sender].commit);
    
    uint256[2] memory reward_times = get_reward_times(random);
    uint256 reward = reward_times[0].mul(_commits[msg.sender].bet_value).div(reward_times[1]);
    _commits[msg.sender].reward = _commits[msg.sender].reward.add(reward);
    _commits[msg.sender].bet_value = 0;
    _commits[msg.sender].commit = 0;
    _commits[msg.sender].block = 0;
    _remain_reward = _remain_reward.add(reward);
    _total_prize = _total_prize.add(reward);
    
    emit Log_reveal(msg.sender, random, reward);
  }

  function check_commitable(address addr) public view returns(bool){
      if (_commits[addr].bet_value == 0) return true;//msg.sender not working??
      else return false;
  }

   function check_revealable(address addr) public view returns(bool){
      if (_commits[addr].bet_value > 0) return true; //msg.sender not working??
      else return false;
  }
  
  function get_random(bytes32 block_hash, uint256 commit_hash) private pure returns (uint256) {
    return uint256(keccak256(abi.encodePacked(block_hash, commit_hash)));
  }
  
  function get_reward_times(uint256 rand_number) internal pure returns(uint256[2] memory){
    uint256 rn = rand_number.mod(1000000);
    uint256 reward_times = 0;
    uint256 den = 1;
    if (rn.mod(888888) == 0) reward_times = 10000;
    else if (rn.mod(88888) == 0) reward_times = 1000;
    else if(rn.mod(8888) == 0) reward_times = 100;
    else if(rn.mod(888) == 0) reward_times = 10;
    else if(rn.mod(88) == 0) reward_times = 5;
    else if(rn.mod(8) == 0) reward_times = 1;
    else { //100% you will be lucky
        reward_times = 1;
        den = 10;
    }

    return [reward_times, den];
  }
  
  function check_withdraw(address addr) public view returns(bool){
      uint256 pool_fund = address(this).balance.sub(_commision);
      if (_commits[addr].reward > 0 && pool_fund >= _commits[addr].reward) return true;
      else return false;
  }
  
  function withdraw() public{      
      require(!_lock, "busy!");
      _lock = true;
      if (check_withdraw(msg.sender)){
            uint256 rv = _commits[msg.sender].reward;
            _commits[msg.sender].reward = 0;
            msg.sender.transfer(rv);
            _remain_reward = _remain_reward.sub(rv);
            emit Log_withdraw(msg.sender, rv);
      }
      _lock = false;
  }
  
  function withdraw_commision_fee() public {
    require(msg.sender == _owner, "you are not owner.");
    require(_commision > 0, "no commision!");

    require(!_lock, "busy!");
    _lock = true;
    if (address(this).balance > _commision){
        (msg.sender).transfer(_commision); 
        _commision = 0;
        emit Log_withdraw(msg.sender, _commision);
    }
    _lock = false;
  }

  function get_commision() public view returns(uint256){
    //require(_owner == msg.sender, "you are not owner."); //not working???
    //emit Log_debug(_owner, msg.sender);

    return _commision;
  }
  
    // the left reward to paid to the users 
  function get_remain_reward() public view returns(uint256){
      return _remain_reward;
  }

  function get_total_reward() public view returns(uint256){
      return _total_prize;
  }
  
  function get_draw_result() public view returns(uint256){
      return  _commits[msg.sender].reward;
  }

  function random() private returns (uint256) {
    _randNonce = _randNonce.add(1);
    return uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp, msg.sender, _randNonce)));
  }

  function get_balance() public view returns(uint256){
    return address(this).balance;
  }

  function getOwner() public view returns(address){
      return _owner;
  }

  function changeOwner(address new_owner) public{
      require(msg.sender == _owner, "you are not owner.");
      emit Log_debug(_owner, new_owner);

      _owner = new_owner;
  }





    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
}