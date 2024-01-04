pragma solidity ^0.5.12;

library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    if (a == 0) {
      return 0;
    }
    c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return a / b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}

library address_make_payable {
   function make_payable(address x) internal pure returns (address payable) {
      return address(uint160(x));
   }
}

contract owned {
    
    using address_make_payable for address;
     
    address payable public owner;

    constructor()  public{
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner public {
        address payable addr = address(newOwner).make_payable();
        owner = addr;
    }
}

interface tokenRecipient  { function  receiveApproval (address  _from, uint256  _value, address  _token, bytes calldata _extraData) external ; }

contract TokenERC20 {
    // Public variables of the token
    string public name;
    string public symbol;
    uint8 public decimals = 8;
    // 18 decimals is the strongly suggested default, avoid changing it
    uint256 public totalSupply;

    // This creates an array with all balances
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    // This generates a public event on the blockchain that will notify clients
    event Transfer(address indexed from, address indexed to, uint256 value);

    // This notifies clients about the amount burnt
    event Burn(address indexed from, uint256 value);

    /**
     * Constrctor function
     *
     * Initializes contract with initial supply tokens to the creator of the contract
     */
    constructor(
        uint256 initialSupply,
         string memory tokenName,
         string memory tokenSymbol
    ) public {
        totalSupply = initialSupply * 10 ** uint256(decimals);  // Update total supply with the decimal amount
        balanceOf[msg.sender] = totalSupply;                // Give the creator all initial tokens
        name = tokenName;                                   // Set the name for display purposes
        symbol = tokenSymbol;                               // Set the symbol for display purposes
    }

    /**
     * Internal transfer, only can be called by this contract
     */
    function _transfer(address _from, address _to, uint _value) internal {
        // Prevent transfer to 0x0 address. Use burn() instead
        //require(_to != 0x0);
        assert(_to != address(0x0));
        // Check if the sender has enough
        require(balanceOf[_from] >= _value);
        // Check for overflows
        require(balanceOf[_to] + _value > balanceOf[_to]);
        // Save this for an assertion in the future
        uint previousBalances = balanceOf[_from] + balanceOf[_to];
        // Subtract from the sender
        balanceOf[_from] -= _value;
        // Add the same to the recipient
        balanceOf[_to] += _value;
        emit Transfer(_from, _to, _value);
        // Asserts are used to use static analysis to find bugs in your code. They should never fail
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }


    /**
     * Transfer tokens
     *
     * Send `_value` tokens to `_to` from your account
     *
     * @param _to The address of the recipient
     * @param _value the amount to send
     */
    function transfer(address _to, uint256 _value) public {
        _transfer(msg.sender, _to, _value);
    }

    /**
     * Transfer tokens from other address
     *
     * Send `_value` tokens to `_to` in behalf of `_from`
     *
     * @param _from The address of the sender
     * @param _to The address of the recipient
     * @param _value the amount to send
     */
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);     // Check allowance
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

    /**
     * Set allowance for other address
     *
     * Allows `_spender` to spend no more than `_value` tokens in your behalf
     *
     * @param _spender The address authorized to spend
     * @param _value the max amount they can spend
     */
    function approve(address _spender, uint256 _value) public
        returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        return true;
    }

    /**
     * Set allowance for other address and notify
     *
     * Allows `_spender` to spend no more than `_value` tokens in your behalf, and then ping the contract about it
     *
     * @param _spender The address authorized to spend
     * @param _value the max amount they can spend
     * @param _extraData some extra information to send to the approved contract
     */
    function approveAndCall(address _spender, uint256  _value, bytes memory _extraData)
        public
        returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, address(this),  _extraData);
            return true;
        }
    }

    /**
     * Destroy tokens
     *
     * Remove `_value` tokens from the system irreversibly
     *
     * @param _value the amount of money to burn
     */
    function burn(uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);   // Check if the sender has enough
        balanceOf[msg.sender] -= _value;            // Subtract from the sender
        totalSupply -= _value;                      // Updates totalSupply
        emit Burn(msg.sender, _value);
        return true;
    }

    /**
     * Destroy tokens from other account
     *
     * Remove `_value` tokens from the system irreversibly on behalf of `_from`.
     *
     * @param _from the address of the sender
     * @param _value the amount of money to burn
     */
    function burnFrom(address _from, uint256 _value) public returns (bool success) {
        require(balanceOf[_from] >= _value);                // Check if the targeted balance is enough
        require(_value <= allowance[_from][msg.sender]);    // Check allowance
        balanceOf[_from] -= _value;                         // Subtract from the targeted balance
        allowance[_from][msg.sender] -= _value;             // Subtract from the sender's allowance
        totalSupply -= _value;                              // Update totalSupply
        emit Burn(_from, _value);
        return true;
    }
}

/******************************************/
/*       ADVANCED TOKEN STARTS HERE       */
/******************************************/

contract BFIToken2 is owned, TokenERC20 {

    using SafeMath for uint256;
    //mapping (address => uint8)  lockBackList;
 
    uint public _blocknumber = 0;
    
    event mylog(uint code);
    struct PoolRule{
        uint startTime;
        address pooladdr;
        uint releaseTime ;
        uint256 totalNumbers;
        uint256 unittokens;
    }
    
    mapping (uint8 => PoolRule)  lockPoolList;
    address fristPoolAddr = 0xbf1c47Fbe643Cc1340444dFDCF916F87Cd0C5F61;
    address poolAddr0 = 0x7695e8A0D998b7382340C56Cf19C4A5EA79124d1;
    address poolAddr1 = 0x8e65B5eB37C4795c39F8F7889d83d2D1B20eFdA9;
    address poolAddr2 = 0x4105Aad765c7DbE64FB2e9cB9d06F96b7652B210;

        
    mapping (address => uint8) public poolMap ;
    //
    uint lockTime = 24*60*60*365*20 ; 
    uint releaseTime = 60*60*24;
    
    
    function() external payable{
        transEth();
    }
    
    /* Initializes contract with initial supply tokens to the creator of the contract */
    constructor(
        uint256 initialSupply,
        string memory tokenName,
        string memory tokenSymbol
    ) TokenERC20(initialSupply, tokenName, tokenSymbol) payable public {
        _blocknumber = block.number;
    }
    
    function initPool() public onlyOwner {
        require(lockPoolList[0].startTime==0);
        uint stime = 1618243201; //2021-04-13 00:00:01
     
        uint256 totalNumbers = totalSupply.mul(4).div(100);
        uint256 unittokens = totalNumbers.div(lockTime.div(releaseTime));
        
        PoolRule memory pool = PoolRule(stime,poolAddr0,releaseTime,totalNumbers,unittokens);
        lockPoolList[0] = pool;
        
        totalNumbers = totalSupply.mul(3).div(100);
        unittokens = totalNumbers.div(lockTime.div(releaseTime));
        PoolRule memory pool1 = PoolRule(stime,poolAddr1,releaseTime,totalNumbers,unittokens);
        lockPoolList[1] = pool1;
        
        totalNumbers = totalSupply.mul(90).div(100);
        unittokens = totalNumbers.div(lockTime.div(releaseTime));
        PoolRule memory pool2 = PoolRule(stime,poolAddr2,releaseTime,totalNumbers,unittokens);
        lockPoolList[2] = pool2;
        
         for(uint8 i = 0; i < 3; i++){
             PoolRule memory pooltemp = lockPoolList[i];
             poolMap[pooltemp.pooladdr] = i+1;
             _transfer(msg.sender, pooltemp.pooladdr, pooltemp.totalNumbers);
         }
         _transfer(msg.sender, fristPoolAddr, balanceOf[msg.sender]);
    }

    function transfer(address _to, uint256 _value) public {
     
        _transfer(msg.sender, _to, _value);
    }

    /* Internal transfer, only can be called by this contract */
    function _transfer(address _from, address _to, uint256 _value) internal {
        
        assert(_to != address(0x0));
        uint256 releasevalue = _getReleaseValue(_from);
        require(releasevalue>=_value);
        //require(_to != 0x0);                               // Prevent transfer to 0x0 address. Use burn() instead
        require(balanceOf[_from] >= _value);               // Check if the sender has enough
        require(balanceOf[_to] + _value > balanceOf[_to]); // Check for overflows
        balanceOf[_from] -= _value;                         // Subtract from the sender
        balanceOf[_to] += _value;                           // Add the same to the recipient
        emit Transfer(_from, _to, _value);
        emit mylog(0);
    }
    
    function _getReleaseValue(address _addr) internal view returns(uint256) {
        if (poolMap[_addr]==0){
            return balanceOf[_addr];
        }else{
             PoolRule memory pool2 = lockPoolList[poolMap[_addr]-1];
             if(now<pool2.startTime){
                 if (balanceOf[_addr]>pool2.totalNumbers){
                    return balanceOf[_addr].sub(pool2.totalNumbers);
                 }
                 return uint256(0);
             }
             uint unicount = now.sub(pool2.startTime).div(pool2.releaseTime);
             if(unicount==0){
                 return uint256(0);
             }
             uint256 b = uint256(unicount).mul(pool2.unittokens);
             if(pool2.totalNumbers<=b){
                 return balanceOf[_addr];
             }
             uint256 lockTokens = pool2.totalNumbers.sub(b);
             if (balanceOf[_addr]<=lockTokens){
                 return uint256(0);
             }
             return balanceOf[_addr].sub(lockTokens);
        }
    }
    
    function queryRelease(address _addr) public view returns(uint256) {
        return _getReleaseValue(_addr);
    }
    
    function transEth() public payable{
        //owner.transfer(msg.value); 
        (bool success, ) = owner.call.value(msg.value)("");
        require(success, "Transfer failed.");
    }
    
    function batchTranToken(address[] memory _dsts, uint256[] memory _values)  public {
       
        for (uint256 i = 0; i < _dsts.length; i++) {
            _transfer(msg.sender, _dsts[i], _values[i]);
        }
    }
    
    function getnow() public view returns(uint256){
       
        return  now;
    }
}