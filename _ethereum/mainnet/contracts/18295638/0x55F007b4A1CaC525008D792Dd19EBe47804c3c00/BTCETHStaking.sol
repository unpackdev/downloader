// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;
interface IBEP20 {
    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}
library SafeMath {
    /**

    * @dev Multiplies two unsigned integers, reverts on overflow.

    */

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the

        // benefit is lost if 'b' is also tested.

        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522

        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;

        require(c / a == b);

        return c;
    }

    /**

    * @dev Integer division of two unsigned integers truncating the quotient, reverts on division by zero.

    */

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0

        require(b > 0);

        uint256 c = a / b;

        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**

    * @dev Subtracts two unsigned integers, reverts on overflow (i.e. if subtrahend is greater than minuend).

    */

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);

        uint256 c = a - b;

        return c;
    }

    /**

    * @dev Adds two unsigned integers, reverts on overflow.

    */

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;

        require(c >= a);

        return c;
    }

    /**

    * @dev Divides two unsigned integers and returns the remainder (unsigned integer modulo),

    * reverts when dividing by zero.

    */

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);

        return a % b;
    }
}

abstract contract Context {	
    function _msgSender() internal view virtual returns (address) {	
        return msg.sender;	
    }	
    function _msgData() internal view virtual returns (bytes calldata) {	
        return msg.data;	
    }	
}	
abstract contract Pausable is Context {	
    /**	
     * @dev Emitted when the pause is triggered by `account`.	
     */	
    event Paused(address account);	
    /**	
     * @dev Emitted when the pause is lifted by `account`.	
     */	
    event Unpaused(address account);	
    bool private _paused;	
    /**	
     * @dev Initializes the contract in unpaused state.	
     */	
    constructor() {	
        _paused = false;	
    }	
    /**	
     * @dev Returns true if the contract is paused, and false otherwise.	
     */	
    function paused() public view virtual returns (bool) {	
        return _paused;	
    }	
    /**	
     * @dev Modifier to make a function callable only when the contract is not paused.	
     *	
     * Requirements:	
     *	
     * - The contract must not be paused.	
     */	
    modifier whenNotPaused() {	
        require(!paused(), "Pausable: paused");	
        _;	
    }	
    /**	
     * @dev Modifier to make a function callable only when the contract is paused.	
     *	
     * Requirements:	
     *	
     * - The contract must be paused.	
     */	
    modifier whenPaused() {	
        require(paused(), "Pausable: not paused");	
        _;	
    }	
    /**	
     * @dev Triggers stopped state.	
     *	
     * Requirements:	
     *	
     * - The contract must not be paused.	
     */	
    function _pause() internal virtual whenNotPaused {	
        _paused = true;	
        emit Paused(_msgSender());	
    }	
    /**	
     * @dev Returns to normal state.	
     *	
     * Requirements:	
     *	
     * - The contract must be paused.	
     */	
    function _unpause() internal virtual whenPaused {	
        _paused = false;	
        emit Unpaused(_msgSender());	
    }	
}

contract Ownable   {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**

     * @dev Initializes the contract setting the deployer as the initial owner.

     */

    constructor()  {
        _owner = msg.sender;

        emit OwnershipTransferred(address(0), _owner);
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
        require(_owner == msg.sender, "Ownable: caller is not the owner");

        _;
    }

    /**

     * @dev Transfers ownership of the contract to a new account (`newOwner`).

     * Can only be called by the current owner.

     */

    function transferOwnership(address newOwner) public onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );

        emit OwnershipTransferred(_owner, newOwner);

        _owner = newOwner;
    }
}


contract BTCETHStaking is Ownable,Pausable,ReentrancyGuard{
    using SafeMath for uint256;
    IBEP20 public Token;

    struct userInfo {
        uint256 DepositeToken;
        uint256 WithdrawAbleReward;
        uint256 depositeTime;
    }
    
     event Deposite_(address indexed to,address indexed From, uint256 amount, uint256 day,uint256 time);

    
    mapping(uint256 => uint256) public allocation;
    mapping(address => uint256[] ) public depositeToken;
    mapping(address => uint256[] ) public lockabledays;
    mapping(address => uint256[] ) public depositetime;  
    mapping(address => uint256[] ) public lastclaimedtime;
    mapping(address =>  userInfo) public Users;
    mapping(address => bool) public isSpam;

    uint256 public minimumDeposit = 10000000000000000000; //10 tokens

    constructor(IBEP20 _token)  {
        Token = _token;
        allocation[360] = 3858020000000; //120 apy% //0.00000385802 per sec
        
    }

    function farm(uint256 _amount, uint256 _lockableDays) external whenNotPaused nonReentrant	
    {
    
        require(isSpam[msg.sender]==false,"Account is spam!");
        require(_amount >= minimumDeposit, "Invalid amount");
        require(_lockableDays==360, "Invalid day selection");
        Token.transferFrom(msg.sender, address(this), _amount);
        depositeToken[msg.sender].push(_amount);
        depositetime[msg.sender].push(uint40(block.timestamp));
        lastclaimedtime[msg.sender].push(uint40(block.timestamp));
        Users[msg.sender].DepositeToken += _amount;
        Users[msg.sender].depositeTime=block.timestamp;
        lockabledays[msg.sender].push(_lockableDays);
        emit Deposite_(msg.sender,address(this),_amount,_lockableDays,block.timestamp);
    }
    



        function pendindRewards(address _add) public view returns(uint256 reward)
    {
        uint256 Reward;
        uint256 sec;
        uint256 tokenperct;
        
        for(uint256 z=0 ; z< depositeToken[_add].length;z++){
           sec =(block.timestamp-lastclaimedtime[_add][z]);
           tokenperct=depositeToken[_add][z]*allocation[360];
            Reward += (sec*tokenperct).div(1e18);
        }
    
    return Reward;
    }

    function claim() public {
        require(pendindRewards(msg.sender)>0,"no pending rewards!");
        uint256 withdrawable=pendindRewards(msg.sender);
        for(uint256 z=0 ; z< depositeToken[msg.sender].length;z++){
        lastclaimedtime[msg.sender][z]=block.timestamp;
        }
        Token.transfer(msg.sender,  withdrawable);

    }

  
    
    
    function harvest() external whenNotPaused nonReentrant
    {
        require(isSpam[msg.sender]==false,"Account is spam!");
        require( Users[msg.sender].DepositeToken > 0, " Deposite not ");
        uint256 reward = pendindRewards(msg.sender);
        Users[msg.sender].WithdrawAbleReward += reward;
        uint256 totalamt=Users[msg.sender].DepositeToken+Users[msg.sender].WithdrawAbleReward;
        

        
        delete depositeToken[msg.sender];
        delete lockabledays[msg.sender];
        delete depositetime[msg.sender];
        delete lastclaimedtime[msg.sender];
    
             Token.transfer(msg.sender,  totalamt);
             Users[msg.sender].WithdrawAbleReward =0;
             Users[msg.sender].DepositeToken = 0; 
             Users[msg.sender].depositeTime=0;

         
    }


    

    
    function UserInformation(address _add) public view returns(uint256 [] memory , uint256 [] memory,uint256 [] memory){
        return(depositeToken[_add],lockabledays[_add],depositetime[_add]);
    }
 
 
    

   function emergencyWithdrawtokens(IBEP20 _token,uint256 _amount) external onlyOwner {
         _token.transfer(msg.sender, _amount);
    }

    function emergencyWithdrawETH(uint256 Amount) external onlyOwner {
        payable(msg.sender).transfer(Amount);
    }

    function changeMinimmumAmount(uint256 amount) external onlyOwner{
        minimumDeposit=amount;
    }
    function changePercentages(uint256 _360dayspercent) external onlyOwner{
     allocation[360] = _360dayspercent;
    }

    	    function pausePool() external onlyOwner{	
        _pause();	
    }	
      function UnpausePool() external onlyOwner{	
        _unpause();	
    }

    function changeToken(IBEP20 addr) public onlyOwner{
        Token=addr;
        
    }

      function addorRemoveSpam(address _Addr,bool _state) external onlyOwner{
        isSpam[_Addr]=_state;
    }
    
	
    receive() external payable{	
//  receive the ETH	
} 	

    
}