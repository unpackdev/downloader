// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract BITSCOIN {




    string public name = "BITSCOIN";

    string public symbol = "BTS";



  /** Development 👍 by YAKSHARAT GLOBAL PVT LTD✔

    /**
 *Submitted for verification at BscScan.com on waiting for few time?
 */
/**
 * @notice Contract is a inheritable smart contract that will add a
 * New modifier called onlyOwner available in the smart contract inherting it
 *
 * onlyOwner makes a function only callable from the Token owner
 *
 */ 


    /**
     * @notice decimals will return the number of decimal precision the Token is deployed with
     */ 
    uint8 public decimals = 18;
   // _owner is the owner of the Token
    address private _owner;

    uint256 private _totalSupply = 21000000000000000000000000; // 21 million

    mapping(address => uint256) public balanceOf;

    /**
     * @notice _allowances is used to manage and control allownace
     * An allowance is the right to use another accounts balance, or part of it
     */


    mapping(address => mapping(address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);
     /**
     * @notice Approval is emitted when a new Spender is approved to spend Tokens on
     * the Owners account
     */

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
       

   
    event Burn(address indexed from, uint256 value);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);



 /**
     * Modifier
     * We create our own function modifier called onlyOwner, it will Require the current owner to be
     * the same as msg.sender
     */


    modifier onlyOwner() {
           // This _; is not a TYPO, It is important for the compiler;
        require(msg.sender == _owner, "Only the owner can call this function");
        _;
    }


 /**
     * @notice constructor will be triggered when we create the Smart contract
     * _name = BITSCOIN of the token
     * _short_symbol = Short Symbol BTS for the token
     * token_decimals = The decimal precision of the Token, defaults 18
     * _totalSupply is how much Tokens there are totally = 2 cr  10 lakh .
     */
    constructor() {

// Add all the tokens created to the creator of the token
        balanceOf[msg.sender] = _totalSupply;
     
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
         // Emit an Transfer event to notify the blockchain that an Transfer has occured
    }



 

    /**
     * @notice owner() returns the currently assigned owner of the Token
     *
     */

     function owner() public view returns (address) {
        return _owner;
    }

 /**
     * @notice transferOwnership will assign the {newOwner} as owner
     *
     */


    function transfer(address to, uint256 value) public returns (bool) {
        require(to != address(0), " BITSCOIN: transfer from zero address");
        require(balanceOf[msg.sender] >= value, "BITSCOIN : Insufficient balance");

        balanceOf[msg.sender] -= value;
        balanceOf[to] += value;

        emit Transfer(msg.sender, to, value);

        return true;
    }

    function approve(address spender, uint256 value) public returns (bool) {

        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) public returns (bool) {
        require(from != address(0),  "BITSCOIN: transfer from zero address");
        require(to != address(0), "");
        require(balanceOf[from] >= value,  "BITSCOIN: transfer to zero address");
        require(allowance[from][msg.sender] >= value, "BITSCOIN : cant transfer more than your account holds //Allowance exceeded");

        balanceOf[from] -= value;
        balanceOf[to] += value;
        allowance[from][msg.sender] -= value;

        emit Transfer(from, to, value);
        return true;
    }

   

      /**
     * @notice _burn will destroy BITSCOIN  from an address inputted and then decrease total supply
     * An Transfer event will emit with receiever set to zero address
     *
     * Requires
     * - Account cannot be zero
     * - Account balance has to be bigger or equal to amount
     */


    function burn(address account, uint256 value)
        public
        onlyOwner
        returns (bool)
    {
        require(balanceOf[account] >= value, " BITSCOIN: pls check your funds Insufficient ");

        balanceOf[account] -= value;
        _totalSupply -= value;

        emit Transfer(account, address(0), value);
        return true;
    }

    function increaseAllowance(address spender, uint256 amount)
        internal 
        returns (bool)
    {
        allowance[msg.sender][spender] += amount;
        emit Approval(msg.sender, spender, allowance[msg.sender][spender]);
        return true;
    }



    function decreaseAllowance(address spender, uint256 amount)
        internal 
        returns (bool)
    {
        uint256 currentAllowance = allowance[msg.sender][spender];
        require(currentAllowance >= amount, "Decreased allowance below zero");
        allowance[msg.sender][spender] = currentAllowance - amount;
        emit Approval(msg.sender, spender, allowance[msg.sender][spender]);
        return true;
    }

     /**
     * @notice getOwner just calls Ownables owner function.
     * returns owner of the token
     *
     */


    function getOwner() external view returns (address) {
        return _owner;
    }

      /**
     * @notice transferOwnership will assign the {newOwner} as owner
     *
     */
   function _transferOwnership(address newOwner) internal  onlyOwner {
        require(newOwner != address(0), " Bitscoin: Invalid address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }


      /**
     * @notice totalSupply will return the tokens total supply of tokens
     */
    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    
}