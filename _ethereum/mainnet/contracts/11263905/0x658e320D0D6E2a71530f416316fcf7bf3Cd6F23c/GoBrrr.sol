pragma solidity ^0.5.2;

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

pragma solidity ^0.5.2;

library Roles {
    struct Role {
        mapping (address => bool) bearer;
    }

    /**
     * @dev Give an account access to this role.
     */
    function add(Role storage role, address account) internal {
        require(account != address(0));
        require(!has(role, account));

        role.bearer[account] = true;
    }

    /**
     * @dev Remove an account's access to this role.
     */
    function remove(Role storage role, address account) internal {
        require(account != address(0));
        require(has(role, account));

        role.bearer[account] = false;
    }

    /**
     * @dev Check if an account has this role.
     * @return bool
     */
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0));
        return role.bearer[account];
    }
}

pragma solidity ^0.5.2;

contract Ownable {
    address public _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () public {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

pragma solidity ^0.5.2;


contract MinterRole {
    using Roles for Roles.Role;

    event MinterAdded(address indexed account);
    event MinterRemoved(address indexed account);

    Roles.Role private _minters;

    constructor () internal {
        _addMinter(msg.sender);
    }

    modifier onlyMinter() {
        require(isMinter(msg.sender));
        _;
    }

    function isMinter(address account) public view returns (bool) {
        return _minters.has(account);
    }

    function addMinter(address account) public onlyMinter {
        _addMinter(account);
    }
    
    function removeMinter(address account) public onlyMinter {
       _removeMinter(account);
    }

    function renounceMinter() public {
        _removeMinter(msg.sender);
    }

    function _addMinter(address account) internal {
        _minters.add(account);
        emit MinterAdded(account);
    }

    function _removeMinter(address account) internal {
        _minters.remove(account);
        emit MinterRemoved(account);
    }
}


pragma solidity ^0.5.2;

contract GoBrrr is Ownable, MinterRole  {

    using SafeMath for uint256;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event withdrawhistory(address withdrawer, uint256 tokensPerBlock, uint256 timelog);

    modifier validRecipient(address to) {
        require(to != address(0x0));
        require(to != address(this));
        _;
    }
    
    mapping (address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    string public constant name = "Go BRRR";
    string public constant symbol = "BRRR";
    uint256 public constant decimals = 18;

    uint256 public totalSupply = 108 * (uint256(10) ** decimals);
   
    
    uint256 public lastMintedtime;
    uint256 public totalParticipants = 0;
    uint256 public tokensPerBlock = (5*10**decimals).div(1000);
    address public tokencontractAddress = address(this);
    
    constructor() public {
        _owner = msg.sender;
        
        // Initially assign all tokens to the contract's creator.
        balanceOf[msg.sender] = totalSupply;
        emit Transfer(address(0x0), msg.sender, totalSupply);
       
        lastMintedtime = now;
    }
    

    function transfer(address to, uint256 value) public  validRecipient(to) returns (bool)
    {
        require(balanceOf[msg.sender] >= value);
        
        uint256 leftvalue = value.mul(9997); //99.97%->99.97/10000
        leftvalue = leftvalue.sub(leftvalue.mod(10000));
        leftvalue = leftvalue.div(10000);

        balanceOf[msg.sender] -= value;  // deduct from sender's balance
        balanceOf[to] += leftvalue;          // add to recipient's balance
        
        uint256 decayvalue = value.sub(leftvalue); //3%->3/100->value-leftvalue
        totalSupply = totalSupply.sub(decayvalue);
        
        emit Transfer(msg.sender, to, value);
        
        return true;
    }
    
    function transferFrom(address from, address to, uint256 value) public returns (bool success)
    {
        require(value <= balanceOf[from]);
        require(value <= allowance[from][msg.sender]);
        
        uint256 leftvalue = value.mul(9997); //99.97%->99.97/100
        leftvalue = leftvalue.sub(leftvalue.mod(10000));
        leftvalue = leftvalue.div(10000);

        balanceOf[from] -= value;
        balanceOf[to] += leftvalue;
        allowance[from][msg.sender] -= value;
        
        uint256 decayvalue = value.sub(leftvalue); //0.03%->3/10000->value-leftvalue
        totalSupply = totalSupply.sub(decayvalue);
        
        emit Transfer(from, to, value);
        return true;
    }

    function approve(address spender, uint256 value) public returns (bool success)
    {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public returns (bool)
    {
        allowance[msg.sender][spender] = allowance[msg.sender][spender].add(addedValue);
        emit Approval(msg.sender, spender, allowance[msg.sender][spender]);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool)
    {
        uint256 oldValue = allowance[msg.sender][spender];
        if (subtractedValue >= oldValue) {
            allowance[msg.sender][spender] = 0;
        } else {
            allowance[msg.sender][spender] = oldValue.sub(subtractedValue);
        }
        emit Approval(msg.sender, spender, allowance[msg.sender][spender]);
        return true;
    }
    
    function changetokensPerBlock(uint256 _newtokensPerBlock) external returns (bool) {
        tokensPerBlock = _newtokensPerBlock*10**decimals;
        return true;
    }
    
    function addMinters(address _minter) external returns (bool) {
        addMinter(_minter);
        totalParticipants = totalParticipants.add(1);
        return true;
    }


    function removeMinters(address _minter) external returns (bool) {
        totalParticipants = totalParticipants.sub(1);
        removeMinter(_minter); 
        return true;
    }

    
    function trigger() external onlyMinter returns (bool) {
        bool res = readyToMint();
        if(res == true && msg.sender != _owner) {
            mintTokens();
            return true;
        } else {
            return false;
        }
    }
    
    function withdraw() external onlyMinter returns (bool) {
        GoBrrr(tokencontractAddress).transfer(msg.sender, tokensPerBlock);
        emit withdrawhistory(msg.sender, tokensPerBlock, now);
        return true;
    }

    
    function readyToMint() public view returns (bool) {
        uint256 currentBlocktime = now;
        uint256 limittime = lastMintedtime + 86400;
        if(currentBlocktime > limittime) { 
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Function to mint new tokens into the economy. 
     * @return A boolean that indicates if the operation was successful.
     */
    function mintTokens() private returns (bool) {
        uint256 tokenReleaseAmount = totalParticipants.mul(tokensPerBlock);
        lastMintedtime = now;
        mint(tokencontractAddress, tokenReleaseAmount);
        return true;
    }
   

    function mint(address account, uint256 value) public onlyMinter {
        require(account != address(0));
        require(account != _owner);
       
        totalSupply = totalSupply.add(value);
        balanceOf[account] = balanceOf[account].add(value);
        emit Transfer(address(0), account, value);
    }
}