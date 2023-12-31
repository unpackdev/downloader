pragma solidity ^0.4.21;

// ----------------------------------------------------------------------------
//
// Für dich!
//
// Symbol        : 3mm4
// Name          : 3mm4-G-Runner
// Total supply  : 18
// Decimals      : 0
//
// ----------------------------------------------------------------------------


library SafeMath {

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
      }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;}
    }
    


contract emma{
    // Track how many tokens are owned by each address.
    mapping (address => uint256) public balanceOf;
    //Name of Token
    string public name = "3mm4-G-Runner";
    //Symbol of Token
    string public symbol = "3mm4";
    //Decimals of Token
    uint8 public decimals = 0;
    //Unix Timestamp of Birthday
    uint256 public bday = 1602512400;
    //Address of birthday child
    address public recipient = 0x6add2220ed8a0163a0e7cc26521c896debccdc7f;
    //Unix Time for a year
    uint256 public year = 31536000;
    
   
    //Total Supply 
    uint256 public totalSupply = 18;
    using SafeMath for uint256;
    //Default Transfer Option ERC20
    event Transfer(address indexed from, address indexed to, uint256 value);
    //Happy Birthday Congratulate Event
    event HappyBirthday (address recipient);

    function emma() public {
        // Initially assign all tokens to the contract's creator.
        balanceOf[msg.sender] = totalSupply;
        emit Transfer(address(0), msg.sender, totalSupply);
    }

    function transfer(address to, uint256 value) public returns (bool success) {
        require(balanceOf[msg.sender] >= value);

        balanceOf[msg.sender] -= value;  // deduct from sender's balance
        balanceOf[to] += value;          // add to recipient's balance
        emit Transfer(msg.sender, to, value);
        return true;
    }

    event Approval(address indexed owner, address indexed spender, uint256 value);

    mapping(address => mapping(address => uint256)) public allowance;

    function approve(address spender, uint256 value)
        public
        returns (bool success)
    {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value)
        public
        returns (bool success)
    {
        require(value <= balanceOf[from]);
        require(value <= allowance[from][msg.sender]);

        balanceOf[from] -= value;
        balanceOf[to] += value;
        allowance[from][msg.sender] -= value;
        emit Transfer(from, to, value);
        return true;
    }
    
    function _transferFrom(address from, address to, uint256 value)
        private
        returns (bool success)
    {
        require(value <= balanceOf[from]);

        balanceOf[from] -= value;
        balanceOf[to] += value;
        emit Transfer(from, to, value);
        return true;
    }
      
      
    // Happy Birthday 3mm4
    // TEAM CRYPTOS 2020
    function _HappyBirthday() returns (uint256){
        
        //Nur für Emma!
        if (msg.sender != recipient) throw;
        //Nur am Geburtstag (Zwinker Emoij)
        if (block.timestamp < bday) throw;
        //nur wen Guthaben
        if (balanceOf[0x94414d6059fbeb998AA595DAE7eAC0D817C37aa0] <= 0) throw;
        // Let's congratulate our recipient
        HappyBirthday (recipient);
        // Transfer the BirthdayToken (Contract Owner Address)
        _transferFrom(0x94414d6059fbeb998AA595DAE7eAC0D817C37aa0, recipient, 1);
        //New Year New Token
       bday = bday + year;
    
    }

}