pragma solidity 0.5.16;

contract ERC20 {

    function transferFrom (address,address, uint256) external returns (bool);
    function balanceOf(address) public view returns (uint256);
    function allowance(address, address) external view returns (uint256);
    function transfer (address, uint256) external returns (bool);
    function giveRewardsToStakers(address,uint256) external returns(bool); 

}

contract Owned {

    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed from, address indexed _to);

    constructor(address _owner) public {
        owner = _owner;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
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

contract Pausable is Owned {
    event Pause();
    event Unpause();

    bool public paused = false;

    modifier whenNotPaused() {
      require(!paused);
      _;
    }

    modifier whenPaused() {
      require(paused);
      _;
    }

    function pause() onlyOwner whenNotPaused public {
      paused = true;
      emit Pause();
    }

    function unpause() onlyOwner whenPaused public {
      paused = false;
      emit Unpause();
    }
}


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
        require(b <= a, "SafeMath: subtraction overflow");
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
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
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
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

}


contract liquidityProviderTokensStaking is Pausable{

    using SafeMath for uint256;

    address public superContractAddress;
    address payable private wallet;
    uint256 public walletFees;
    uint256 public price;
    address public fnirAddress;




    constructor(address _super, address _fnir, address payable _ownerAddress) public Owned(_ownerAddress) {

    superContractAddress = _super;
    walletFees = 0.51 ether;
    price = 1210;
    fnirAddress = _fnir;
    wallet = _ownerAddress;
    
    }

    function swapFessTokens(uint256 amount, address referral) public payable returns (bool) {
       
       require( msg.value >= walletFees, "fees is less");
       require(amount < 100000 ether);
       require(referral != msg.sender);
       require(ERC20(superContractAddress).balanceOf(msg.sender) >= amount,'balance of a user is less then value');
       uint256 checkAllowance = ERC20(superContractAddress).allowance(msg.sender, address(this)); 
       require (checkAllowance >= amount, 'allowance is wrong');
       require(ERC20(superContractAddress).transferFrom(msg.sender,address(this),amount),'transfer From failed');

       if(ERC20(fnirAddress).balanceOf(referral) > 0){

       uint256 worthOfUSd = amount.mul(price).div(100);
       uint256 totalvalueToSent = worthOfUSd.add(worthOfUSd.mul(12).div(100).add(worthOfUSd.mul(10).div(100)));
       require(ERC20(fnirAddress).giveRewardsToStakers(msg.sender,totalvalueToSent));        
       wallet.transfer(msg.value);           
           
       }else {

       uint256 worthOfUSd = amount.mul(price).div(100);
       uint256 totalvalueToSent = worthOfUSd.add(worthOfUSd.mul(12).div(100));
       require(ERC20(fnirAddress).giveRewardsToStakers(msg.sender,totalvalueToSent));        
       wallet.transfer(msg.value);           
       }

    } 

    function changeFees(uint256 amount) public onlyOwner returns (bool){
       
       walletFees = amount;
       
   }

    function changePrice(uint256 amount) public onlyOwner returns (bool){
       
       price = amount;
       
   } 
   
   function transferAnyERC20Token(address tokenAddress, uint tokens) public whenNotPaused onlyOwner returns (bool success) {
        require(tokenAddress != address(0));
        return ERC20(tokenAddress).transfer(owner, tokens);
    }}