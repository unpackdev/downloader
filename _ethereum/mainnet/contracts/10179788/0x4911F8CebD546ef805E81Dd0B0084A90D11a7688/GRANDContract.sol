
// File: @openzeppelin/upgrades/contracts/Initializable.sol

pragma solidity >=0.4.24 <0.7.0;


/**
 * @title Initializable
 *
 * @dev Helper contract to support initializer functions. To use it, replace
 * the constructor with a function that has the `initializer` modifier.
 * WARNING: Unlike constructors, initializer functions must be manually
 * invoked. This applies both to deploying an Initializable contract, as well
 * as extending an Initializable contract via inheritance.
 * WARNING: When used with inheritance, manual care must be taken to not invoke
 * a parent initializer twice, or ensure that all initializers are idempotent,
 * because this is not dealt with automatically as with constructors.
 */
contract Initializable {

  /**
   * @dev Indicates that the contract has been initialized.
   */
  bool private initialized;

  /**
   * @dev Indicates that the contract is in the process of being initialized.
   */
  bool private initializing;

  /**
   * @dev Modifier to use in the initializer function of a contract.
   */
  modifier initializer() {
    require(initializing || isConstructor() || !initialized, "Contract instance has already been initialized");

    bool isTopLevelCall = !initializing;
    if (isTopLevelCall) {
      initializing = true;
      initialized = true;
    }

    _;

    if (isTopLevelCall) {
      initializing = false;
    }
  }

  /// @dev Returns true if and only if the function is running in the constructor
  function isConstructor() private view returns (bool) {
    // extcodesize checks the size of the code stored in an address, and
    // address returns the current address. Since the code is still not
    // deployed when running a constructor, any checks on its code size will
    // yield zero, making it an effective way to detect if a contract is
    // under construction or not.
    address self = address(this);
    uint256 cs;
    assembly { cs := extcodesize(self) }
    return cs == 0;
  }

  // Reserved storage space to allow for layout changes in the future.
  uint256[50] private ______gap;
}

// File: contracts/ERC/ERC20Interface.sol

pragma solidity >0.5.8 <0.6.0;

/** ----------------------------------------------------------------------------
* @title ERC Token Standard #20 Interface
* https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md
* ----------------------------------------------------------------------------
*/
contract ERC20Interface {
    function totalSupply() public view returns (uint);
    function balanceOf(address tokenOwner) public view returns (uint balance);
    function allowance(address tokenOwner, address spender) public view returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed tokenOwner, address indexed spender, uint value);
}

// File: contracts/libs/Ownable.sol

pragma solidity >0.5.8 <0.6.0;

/**
* @title Ownable
* @dev The Ownable contract has an owner address, and provides basic      authorization control
* functions, this simplifies the implementation of "user permissions".
*/
contract Ownable {

    address public owner;

    event OwnershipRenounced(address indexed previousOwner);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor() public {
        owner = msg.sender;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner, "Ownable: sender is not owner");
        _;
    }

    /**
     * @dev Allows the current owner to relinquish control of the contract.
     */
    function renounceOwnership() public onlyOwner {
        owner = address(0);
        emit OwnershipRenounced(owner);
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param _newOwner The address to transfer ownership to.
     */
    function transferOwnership(address _newOwner) public onlyOwner {
        _transferOwnership(_newOwner);
    }

    /**
     * @dev Transfers control of the contract to a newOwner.
     * @param _newOwner The address to transfer ownership to.
     */
    function _transferOwnership(address _newOwner) internal {
        require(_newOwner != address(0), "Ownable: transfer to zero address");
        owner = _newOwner;
        emit OwnershipTransferred(owner, _newOwner);
    }
}

// File: contracts/libs/SafeMath.sol

pragma solidity >0.5.8 <0.6.0;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that revert on error
 */
library SafeMath {

    /**
    * @dev Multiplies two numbers, reverts on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b);
        return c;
    }

    /**
    * @dev Integer division of two numbers truncating the quotient, reverts on division by zero.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0); // Solidity only automatically asserts when dividing by 0
        uint256 c = a / b;
        return c;
    }

    /**
    * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;
        return c;
    }

    /**
    * @dev Adds two numbers, reverts on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);
        return c;
    }

    /**
    * @dev Divides two numbers and returns the remainder (unsigned integer modulo),
    * reverts when dividing by zero.
    */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

// File: contracts/ERC/ERC20.sol

pragma solidity >0.5.8 <0.6.0;




/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md
 */
contract ERC20 is ERC20Interface, Ownable {

    using SafeMath for uint256;

    mapping(address => uint256) internal _balances;

    mapping(address => mapping(address => uint256)) internal _allowed;

    uint256 internal _totalSupply;

    event Burn(address indexed burner, uint256 value);

    /**
    * @dev Total number of tokens in existence
    */
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    /**
    * @dev Gets the balance of the specified address.
    * @param owner The address to query the balance of.
    * @return An uint256 representing the amount owned by the passed address.
    */
    function balanceOf(address owner) public view returns (uint256) {
        return _balances[owner];
    }

    /**
     * @dev Function to check the amount of tokens that an owner allowed to a spender.
     * @param owner address The address which owns the funds.
     * @param spender address The address which will spend the funds.
     * @return A uint256 specifying the amount of tokens still available for the spender.
     */
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowed[owner][spender];
    }

    /**
    * @dev Transfer token for a specified address
    * @param to The address to transfer to.
    * @param value The amount to be transferred.
    */
    function transfer(address to, uint256 value) public returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    /**
     * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
     * Beware that changing an allowance with this method brings the risk that someone may use both the old
     * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
     * race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     * @param spender The address which will spend the funds.
     * @param value The amount of tokens to be spent.
     */
    function approve(address spender, uint256 value) public returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    /**
     * @dev Transfer tokens from one address to another
     * @param from address The address which you want to send tokens from
     * @param to address The address which you want to transfer to
     * @param value uint256 the amount of tokens to be transferred
     */
    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        require(value <= _allowed[from][msg.sender], "ERC20: account balance is lower than amount");
        _transfer(from, to, value);
        _approve(from, msg.sender, _allowed[from][msg.sender].sub(value));
        return true;
    }

    /**
     * @dev Increase the amount of tokens that an owner allowed to a spender.
     * approve should be called when allowed_[_spender] == 0. To increment
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * @param spender The address which will spend the funds.
     * @param addedValue The amount of tokens to increase the allowance by.
     */
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        require(addedValue > 0, "ERC20: value must be bigger than zero");
        _approve(msg.sender, spender, _allowed[msg.sender][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Decrease the amount of tokens that an owner allowed to a spender.
     * approve should be called when allowed_[_spender] == 0. To decrement
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * @param spender The address which will spend the funds.
     * @param subtractedValue The amount of tokens to decrease the allowance by.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        require(subtractedValue > 0, "ERC20: value must be bigger than zero");
        _approve(msg.sender, spender, _allowed[msg.sender][spender].sub(subtractedValue));
        return true;
    }

    /**
     * @dev Internal function that burns an amount of the token of a given
     * account.
     * @param account The account whose tokens will be burnt.
     * @param amount The amount that will be burnt.
     */
    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "ERC20: value must be bigger than zero");
        require(amount <= _balances[account], "ERC20: account balance is lower than amount");

        _totalSupply = _totalSupply.sub(amount);
        _balances[account] = _balances[account].sub(amount);
        emit Transfer(account, address(0), amount);
        emit Burn(account, amount);
    }

    /**
     * @dev Internal function that burns an amount of the token of a given
     * account, deducting from the sender's allowance for said account. Uses the
     * internal burn function.
     * @param account The account whose tokens will be burnt.
     * @param amount The amount that will be burnt.
     */
    function _burnFrom(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "ERC20: value must be bigger than zero");
        require(amount <= _allowed[account][msg.sender], "ERC20: account allowed balance is lower than amount");
        _burn(account, amount);
        _approve(account, msg.sender, _allowed[account][msg.sender].sub(amount));
    }

    /**
    * @dev Internal transfer, only can be called by this contract
    */
    function _transfer(address _from, address _to, uint256 value) internal {
        require(_from != address(0), "ERC20: transfer to the zero address");
        require(_to != address(0), "ERC20: transfer to the zero address");
        require(value > 0, "ERC20: value must be bigger than zero");
        require(value <= _balances[_from], "ERC20: balances from must be bigger than transfer amount");
        require(_balances[_to] < _balances[_to] + value, "ERC20: value must be bigger than zero");

        _balances[_from] = _balances[_from].sub(value);
        _balances[_to] = _balances[_to].add(value);
        emit Transfer(_from, _to, value);
    }

    /**
    * @dev Internal function, minting new tokens
    */
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");
        require(amount > 0, "ERC20: value must be bigger than zero");

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }


    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
     *
     * This is internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowed[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

}

// File: contracts/libs/MintableToken.sol

pragma solidity >0.5.8 <0.6.0;


/**
 * @title Mintable token
 * @dev Simple ERC20 Token example, with mintable token creation
 * @dev Issue: * https://github.com/OpenZeppelin/openzeppelin-solidity/issues/120
 */
contract MintableToken is ERC20 {

    event Mint(address indexed to, uint256 amount);

    event MintFinished();

    event MintStarted();

    bool public mintingFinished = false;

    modifier canMint() {
        require(!mintingFinished, "MintableToken: minting is finished");
        _;
    }

    modifier hasMintPermission() {
        require(msg.sender == owner, "MintableToken: sender has not permissions");
        _;
    }

    /**
     * @dev Function to mint tokens
     * @param _to The address that will receive the minted tokens.
     * @param _amount The amount of tokens to mint.
     * @return A boolean this indicates if the operation was successful.
     */
    function mint(address _to, uint256 _amount) public hasMintPermission canMint returns (bool) {
        _mint(_to, _amount);
        _approve(_to, owner, _amount);
        emit Mint(_to, _amount);
        return true;
    }

    /**
     * @dev Function to stop minting new tokens.
     * @return True if the operation was successful.
     */
    function finishMinting() public onlyOwner canMint returns (bool) {
        mintingFinished = true;
        emit MintFinished();
        return true;
    }

    function startMinting() public onlyOwner returns (bool) {
        mintingFinished = false;
        emit MintStarted();
        return true;
    }
}

// File: contracts/MainContract.sol

pragma solidity >0.5.8 <0.6.0;




/**
 * @title MainContract
 * @dev Base contract which using for initializing new contract
 */
contract MainContract is Ownable, MintableToken, Initializable {

    string private _name;

    string private _symbol;

    uint private _decimals;

    uint private _decimalsMultiplier;

    constructor (string memory name, string memory symbol, uint decimals, uint totalSupply, address owner, address tokensOwner) public {
        init(name, symbol, decimals, totalSupply, owner, tokensOwner);
    }

    /**
     * @return get token name
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @return get token symbol
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @return get token decimals
     */
    function decimals() public view returns (uint) {
        return _decimals;
    }

    /**
     * @dev override base method transferFrom
     */
    function transferFrom(address _from, address _to, uint256 value) public returns (bool _success) {
        return super.transferFrom(_from, _to, value);
    }

    /**
     * @dev Override base method transfer
     */
    function transfer(address _to, uint256 value) public returns (bool _success) {
        return super.transfer(_to, value);
    }

    /**
     * @dev Override base method increaseAllowance
     */
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        return super.increaseAllowance(spender, addedValue);
    }

    /**
    * @dev Override base method decreaseAllowance
    */
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        return super.decreaseAllowance(spender, subtractedValue);
    }

    /**
    * @dev Override base method approve
    */
    function approve(address spender, uint256 value) public returns (bool) {
        return super.approve(spender, value);
    }

    /**
    * @dev Burn user tokens
    */
    function burn(uint256 _value) public {
        _burn(msg.sender, _value);
    }

    /**
    * @dev Burn users tokens with allowance
    */
    function burnFrom(address account, uint256 _value) public {
        _burnFrom(account, _value);
    }

    /**
    *  @dev Mint tokens by owner
    */
    function addTokens(uint256 _amount) public hasMintPermission canMint {
        _mint(msg.sender, _amount);
        emit Mint(msg.sender, _amount);
    }

    /**
    * @dev Function whose calling on initialize contract
    */
    function init(string memory __name, string memory __symbol, uint __decimals, uint __totalSupply, address __owner, address __tokensOwner) public initializer {
        _name = __name;
        _symbol = __symbol;
        _decimals = __decimals;
        _decimalsMultiplier = 10 ** _decimals;
        mint(__tokensOwner, __totalSupply * _decimalsMultiplier);
        _approve(__tokensOwner, __owner, balanceOf(__tokensOwner));
        transferOwnership(__owner);
    }

    function() external payable {revert();}
}

// File: contracts/GRANDContract.sol

pragma solidity >0.5.8 <0.6.0;


contract GRANDContract is MainContract {
    constructor () MainContract('GRAND', 'GRAND', 10, 10000000, 0x040cdBbb1592c65194352E30474a069b362edcb2, 0x809c2f8e552b1e86628FE43ba3c064D306a667DA) public {}
}
