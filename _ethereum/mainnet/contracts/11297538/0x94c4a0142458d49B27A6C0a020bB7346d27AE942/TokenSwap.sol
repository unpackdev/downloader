pragma solidity ^0.4.24; 

contract ERC20Interface {

    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);

}

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;
  address public coinvest;
  mapping (address => bool) public admins;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
    owner = msg.sender;
    coinvest = msg.sender;
    admins[owner] = true;
    admins[coinvest] = true;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  modifier onlyCoinvest() {
      require(msg.sender == coinvest);
      _;
  }

  modifier onlyAdmin() {
      require(admins[msg.sender]);
      _;
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }
  
  /**
   * @dev Changes the Coinvest wallet that will receive funds from investment contract.
   * @param _newCoinvest The address of the new wallet.
  **/
  function transferCoinvest(address _newCoinvest) 
    external
    onlyCoinvest
  {
    require(_newCoinvest != address(0));
    coinvest = _newCoinvest;
  }

  /**
   * @dev Used to add admins who are allowed to add funds to the investment contract.
   * @param _user The address of the admin to add or remove.
   * @param _status True to add the user, False to remove the user.
  **/
  function alterAdmin(address _user, bool _status)
    external
    onlyCoinvest
  {
    require(_user != address(0));
    require(_user != coinvest);
    admins[_user] = _status;
  }

}

contract TokenSwap is Ownable {
    
    ERC20Interface public tokenV1;
    ERC20Interface public tokenV2;
    ERC20Interface public tokenV3;
    ERC20Interface public tokenV4;
    
    /**
     * @param _tokenV1 The original ERC223 version of the Coinvest token.
     * @param _tokenV2 The second iteration of the token using ERC865.
     * @param _tokenV3 The third iteration of the Coinvest token.
     * @param _tokenV4 The new iteration of the CoinDeFi token (the 3rd with gas savings).
    **/
    constructor(address _tokenV1, address _tokenV2, address _tokenV3, address _tokenV4) public {
        tokenV1 = ERC20Interface(_tokenV1);
        tokenV2 = ERC20Interface(_tokenV2);
        tokenV3 = ERC20Interface(_tokenV3);
        tokenV4 = ERC20Interface(_tokenV4);
    }
    /**
     * @param _from The address that has transferred this contract tokens.
     * @param _value The amount of tokens that have been transferred.
     * @param _data The extra data sent with transfer (should be nothing).
    **/
    function tokenFallback(address _from, uint _value, bytes _data)
      external
    {
        require(msg.sender == address(tokenV1));
        require(_value > 0);
        require(tokenV4.transfer(_from, _value));
        _data;
    }
    /**
     * @dev approveAndCall will be used on the old token to transfer from the user
     * to the contract, which will then return to them the new tokens.
     * @param _from The user that is making the call.
     * @param _amount The amount of tokens being transferred to this swap contract.
     * @param _token The address of the token contract (address(oldToken))--not used.
     * @param _data Extra data with the call--not used.
    **/
    function receiveApproval(address _from, uint256 _amount, address _token, bytes _data)
      public
    {
        address sender = msg.sender;
        require(sender == address(tokenV2) || sender == address(tokenV3));
        require(_amount > 0);
        require(ERC20Interface(sender).transferFrom(_from, address(this), _amount));
        require(tokenV4.transfer(_from, _amount));
        _token; _data;
    }
    
    /**
     * @dev Allow the owner to take Ether or tokens off of this contract if they are accidentally sent.
     * @param _tokenContract The address of the token to withdraw (0x0 if Ether).
     * @notice This allows Coinvest to take all valuable tokens from the TokenSwap contract.
    **/
    function tokenEscape(address _tokenContract)
      external
      onlyCoinvest
    {
        // Somewhat pointless require as Coinvest can withdraw V2 and exchange for more V3.
        require(_tokenContract != address(tokenV1) && _tokenContract != address(tokenV3));
        
        if (_tokenContract == address(0)) coinvest.transfer(address(this).balance);
        else {
            ERC20Interface lostToken = ERC20Interface(_tokenContract);
        
            uint256 stuckTokens = lostToken.balanceOf(address(this));
            lostToken.transfer(coinvest, stuckTokens);
        }    
    }

}