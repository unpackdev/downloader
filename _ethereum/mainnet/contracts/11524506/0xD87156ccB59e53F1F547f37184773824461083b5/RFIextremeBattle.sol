pragma solidity ^0.6.12;




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



abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}


/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}



contract Ownable is Context {
    address private _owner;
    address private _previousOwner;


    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

     /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

   
}



contract RFIextremeBattle is Context, Ownable {
        
    using SafeMath for uint256;
    
    uint256 public _taxFee = 10;
    
    uint256 public _burnFee = 2;
    
    //bet limit
    uint256 public _minBetAmount = 1 ether;
    
    
    IERC20 public _rfiextremetoken;
    
    
    
    uint256 public gameNo = 1;
    
    //users balances and redeem
    
    mapping (address =>  uint256) public balances;
    
    mapping (address =>  mapping (uint256 => mapping (uint8 => uint256))) public betBalances;


    uint256 public totalUserBalance;
    
    
    //actual balances of the 2 pool and amount accumulated
    
    mapping (uint8 => uint256) public pool;
    
    
    
   
    
    //DAO address set to zero by default
    
    address public daoAddress;
    
    
    
    //last game
    
    uint256 public lastGameTime;
    
    mapping (uint8 => uint256) public lastPool;
    
    
    //last winner
    uint8 public winner;
    uint8 public looser;
    
    uint256 public timeGame;
    
    
    //modifier that process the end of the game
    
    
    modifier finalGame(){
        
      
        
        if (block.timestamp.sub(lastGameTime) >= timeGame){
        
        
        lastGameTime = block.timestamp;
        
        gameNo++;


        //prev pools
        lastPool[0] = pool[0];
        lastPool[1] = pool[1];

        



        //determine looser

        if(pool[0] > pool[1]){
            winner = 0;
            looser = 1;
        }else if(pool[1] > pool[0]){
            
            winner = 1;
            looser = 0;
            
        }else{
            //empty prev pool since eguality
            lastPool[0] = 0;
            lastPool[1] = 0;

            winner = 2;
            looser = 2;


            }//eguality everyone loose for the profit of dao :D
        
        pool[0] = 0;
        pool[1] = 0;
        
        //switch to next game
        
        
        
        
        
        
        //send the accumulated balance to daoAddress
        
        //should send everything except previous 
        
        


        uint256 rfibalance = _rfiextremetoken.balanceOf(address(this));

        //of course omit last pool if any and the user balances

        

        if(daoAddress != address(0) &&  rfibalance > 0){
            
            uint256 realAm = (rfibalance).sub((lastPool[0].add(lastPool[1])).add(totalUserBalance));
            
            _rfiextremetoken.transfer(address(daoAddress),realAm);
            
            
            
        }
        
        
        
    
        
        }
        
        _;
        
    }
    
    
    constructor () public {
        
        _rfiextremetoken = IERC20(address(0x1Fd13b3508802aDDE7D3389337EBEB950FF358C4));
        
        
        lastGameTime = block.timestamp;
        
        
        timeGame = 24 hours;
        
    }
    
    
    
    
    function calculateTaxFee(uint256 _amount) public view returns (uint256) {
        return _amount.mul(_taxFee).div(
            10**2
        );
    }
    
    function calculateBurnFee(uint256 _amount) public view returns (uint256) {
        return _amount.mul(_burnFee).div(
            10**2
        );
    }
    
    
    
    
    function setMinBet(uint256 minBet) external onlyOwner() {
        _minBetAmount = minBet;
    }
    
    function setTaxFee(uint256 taxFee) external onlyOwner() {
        _taxFee = taxFee;
    }
    
    function setBurnFee(uint256 burnFee) external onlyOwner() {
        _burnFee = burnFee;
    }
    
     function setTimeGame(uint256 _timeGame) external onlyOwner() {
        timeGame = _timeGame;
    }


    function setDao(address _dao) external onlyOwner() {

        daoAddress = _dao;
    }
    
    
    //deposit
    
    function deposit(uint256 amount) external  {
        
        
        require(_rfiextremetoken.transferFrom(_msgSender(), address(this), amount) );
        
        uint256 realAm = amount.sub(calculateTaxFee(amount).add(calculateBurnFee(amount)));
        
        
        balances[_msgSender()] = balances[_msgSender()].add(realAm);

        totalUserBalance = totalUserBalance.add(realAm);
        
        
    }
    
    //withdraw
    function withdraw(uint256 amount) external  {
        
        
        
        require(_rfiextremetoken.transfer(_msgSender(),amount));
        
        balances[_msgSender()] = balances[_msgSender()].sub(amount);

        totalUserBalance = totalUserBalance.sub(amount);
        
        



        
        
    }
    
    
    
    
    
    

        
    
    
    //bet function
    
    function bet(uint8 _pool, uint256 amount) external finalGame() {
        
        
        require(amount >= _minBetAmount);
        require(_pool == 0 || _pool == 1);
        require(balances[_msgSender()] >= amount);
        
        
        
        if(_pool == 0){
            //pool 1
            pool[0] = pool[0].add(amount);
            
            betBalances[_msgSender()][gameNo][_pool] = betBalances[_msgSender()][gameNo][_pool].add(amount);
            
            
        }
        
        else if(_pool == 1){
            //pool 2   
            
            pool[1] = pool[1].add(amount);
            
            betBalances[_msgSender()][gameNo][_pool] = betBalances[_msgSender()][gameNo][_pool].add(amount);
            
        }
        
        totalUserBalance = totalUserBalance.sub(amount);
        balances[_msgSender()] = balances[_msgSender()].sub(amount);
        
    }
    
    
    //redeem winning
    
    function redeem() external  {
        
        require(block.timestamp.sub(lastGameTime) < timeGame);
        
        require(lastPool[looser] > 0 && betBalances[_msgSender()][gameNo.sub(1)][winner] > 0);
       
        uint256 amountOnWinning = (betBalances[_msgSender()][gameNo.sub(1)][winner].mul(100)).div(lastPool[winner]);
        
        uint256 realAm = betBalances[_msgSender()][gameNo.sub(1)][winner].add(lastPool[looser].mul(amountOnWinning).div(100)); 
        
        
        
        balances[_msgSender()] = balances[_msgSender()].add(realAm);
        
        totalUserBalance = totalUserBalance.add(realAm);
        betBalances[_msgSender()][gameNo.sub(1)][winner] = 0;
        
        
        
        
        
    }
    
    
    
    
    
    
}