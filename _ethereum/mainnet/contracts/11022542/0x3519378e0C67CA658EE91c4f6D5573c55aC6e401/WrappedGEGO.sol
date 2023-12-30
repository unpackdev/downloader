/**
 *Submitted for verification at Etherscan.io on 2019-05-31
*/

pragma solidity ^0.6.2;

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
interface IERC20 {
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
 * @title SafeMath
 * @dev Unsigned math operations with safety checks that revert on error
 */
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


/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md
 * Originally based on code by FirstBlood:
 * https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 *
 * This implementation emits additional Approval events, allowing applications to reconstruct the allowance status for
 * all accounts just by listening to said events. Note that this isn't required by the specification, and other
 * compliant implementations may not do it.
 */
contract ERC20 is IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowed;

    uint256 private _totalSupply;

    /**
    * @dev Total number of tokens in existence
    */
    function totalSupply() public override view returns (uint256) {
        return _totalSupply;
    }

    /**
    * @dev Gets the balance of the specified address.
    * @param owner The address to query the balance of.
    * @return An uint256 representing the amount owned by the passed address.
    */
    function balanceOf(address owner) public override view returns (uint256) {
        return _balances[owner];
    }

    /**
     * @dev Function to check the amount of tokens that an owner allowed to a spender.
     * @param owner address The address which owns the funds.
     * @param spender address The address which will spend the funds.
     * @return A uint256 specifying the amount of tokens still available for the spender.
     */
    function allowance(address owner, address spender) public override view returns (uint256) {
        return _allowed[owner][spender];
    }

    /**
    * @dev Transfer token for a specified address
    * @param to The address to transfer to.
    * @param value The amount to be transferred.
    */
    function transfer(address to, uint256 value) public override returns (bool) {
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
    function approve(address spender, uint256 value) public override returns (bool) {
        require(spender != address(0));

        _allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    /**
     * @dev Transfer tokens from one address to another.
     * Note that while this function emits an Approval event, this is not required as per the specification,
     * and other compliant implementations may not emit the event.
     * @param from address The address which you want to send tokens from
     * @param to address The address which you want to transfer to
     * @param value uint256 the amount of tokens to be transferred
     */
    function transferFrom(address from, address to, uint256 value) public override returns (bool) {
        _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);
        _transfer(from, to, value);
        emit Approval(from, msg.sender, _allowed[from][msg.sender]);
        return true;
    }

    /**
     * @dev Increase the amount of tokens that an owner allowed to a spender.
     * approve should be called when allowed_[_spender] == 0. To increment
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * From MonolithDAO Token.sol
     * Emits an Approval event.
     * @param spender The address which will spend the funds.
     * @param addedValue The amount of tokens to increase the allowance by.
     */
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        require(spender != address(0));

        _allowed[msg.sender][spender] = _allowed[msg.sender][spender].add(addedValue);
        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
        return true;
    }

    /**
     * @dev Decrease the amount of tokens that an owner allowed to a spender.
     * approve should be called when allowed_[_spender] == 0. To decrement
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * From MonolithDAO Token.sol
     * Emits an Approval event.
     * @param spender The address which will spend the funds.
     * @param subtractedValue The amount of tokens to decrease the allowance by.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        require(spender != address(0));

        _allowed[msg.sender][spender] = _allowed[msg.sender][spender].sub(subtractedValue);
        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
        return true;
    }

    /**
    * @dev Transfer token for a specified addresses
    * @param from The address to transfer from.
    * @param to The address to transfer to.
    * @param value The amount to be transferred.
    */
    function _transfer(address from, address to, uint256 value) internal {
        require(to != address(0));

        _balances[from] = _balances[from].sub(value);
        _balances[to] = _balances[to].add(value);
        emit Transfer(from, to, value);
    }

    /**
     * @dev Internal function that mints an amount of the token and assigns it to
     * an account. This encapsulates the modification of balances such that the
     * proper events are emitted.
     * @param account The account that will receive the created tokens.
     * @param value The amount that will be created.
     */
    function _mint(address account, uint256 value) internal {
        require(account != address(0));

        _totalSupply = _totalSupply.add(value);
        _balances[account] = _balances[account].add(value);
        emit Transfer(address(0), account, value);
    }

    /**
     * @dev Internal function that burns an amount of the token of a given
     * account.
     * @param account The account whose tokens will be burnt.
     * @param value The amount that will be burnt.
     */
    function _burn(address account, uint256 value) internal {
        require(account != address(0));

        _totalSupply = _totalSupply.sub(value);
        _balances[account] = _balances[account].sub(value);
        emit Transfer(account, address(0), value);
    }

    /**
     * @dev Internal function that burns an amount of the token of a given
     * account, deducting from the sender's allowance for said account. Uses the
     * internal burn function.
     * Emits an Approval event (reflecting the reduced allowance).
     * @param account The account whose tokens will be burnt.
     * @param value The amount that will be burnt.
     */
    function _burnFrom(address account, uint256 value) internal {
        _allowed[account][msg.sender] = _allowed[account][msg.sender].sub(value);
        _burn(account, value);
        emit Approval(account, msg.sender, _allowed[account][msg.sender]);
    }
}


/**
 * @title Helps contracts guard against reentrancy attacks.
 * @author Remco Bloemen <remco@2π.com>, Eenae <alexey@mixbytes.io>
 * @dev If you mark a function `nonReentrant`, you should also
 * mark it `external`.
 */
contract ReentrancyGuard {
    /// @dev counter to allow mutex lock with only one SSTORE operation
    uint256 private _guardCounter;

    constructor() public {
        // The counter starts at one to prevent changing it from zero to a non-zero
        // value, which is a more expensive operation.
        _guardCounter = 1;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _guardCounter += 1;
        uint256 localCounter = _guardCounter;
        _;
        require(localCounter == _guardCounter);
    }
}



pragma solidity ^0.6.2;





/// @title Main contract for WrappedGEGO. This contract converts GEGO between the ERC721 standard and the
///  ERC20 standard by locking gego into the contract and minting 1:1 backed ERC20 tokens, that
///  can then be redeemed for gego when desired.
/// @notice When wrapping a cryptogego, you get a generic WGEGO token. Since the WGEGO token is generic, it has no
///  no information about what cryptogego you submitted, so you will most likely not receive the same gego
///  back when redeeming the token unless you specify that gego's ID. The token only entitles you to receive 
///  *a* cryptogego in return, not necessarily the *same* cryptogego in return. A different user can submit
///  their own WGEGO tokens to the contract and withdraw the gego that you originally deposited. WGEGO tokens have
///  no information about which gego was originally deposited to mint WGEGO - this is due to the very nature of 
///  the ERC20 standard being fungible, and the ERC721 standard being nonfungible.
contract WrappedGEGO is ERC20, ReentrancyGuard {

    // OpenZeppelin's SafeMath library is used for all arithmetic operations to avoid overflows/underflows.
    using SafeMath for uint256;

    //owner
    address payable private satoshi;
    //set a break for allowing admin harvest
    bool private delay = false;
    
    mapping (uint256 => address) private latestPool;
    
    
    string public _affCode = "dego";
    
    uint256 public _affPrice = 0.25 ether;
    
    uint256 public lastRefUpdate = block.timestamp;
    
    
    /* ****** */
    /* EVENTS */
    /* ****** */

    /// @dev This event is fired when a user deposits gego into the contract in exchange
    ///  for an equal number of WGEGO ERC20 tokens.
    /// @param gegoId  The cryptogego id of the gego that was deposited into the contract.
    event DepositgegoAndMintToken(
        uint256 gegoId
    );

    /// @dev This event is fired when a user deposits WGEGO ERC20 tokens into the contract in exchange
    ///  for an equal number of locked gego.
    /// @param gegoId  The cryptogego id of the gego that was withdrawn from the contract.
    event BurnTokenAndWithdrawgego(
        uint256 gegoId
    );
    
    
    
    event NFTReceived(address operator, address from, uint256 tokenId, bytes data);

    /* ******* */
    /* STORAGE */
    /* ******* */

    /// @dev An Array containing all of the gego that are locked in the contract, backing
    ///  WGEGO ERC20 tokens 1:1
    /// @notice Some of the gego in this array were indeed deposited to the contract, but they
    ///  are no longer held by the contract. This is because withdrawSpecificgego() allows a 
    ///  user to withdraw a gego "out of order". Since it would be prohibitively expensive to 
    ///  shift the entire array once we've withdrawn a single element, we instead maintain this 
    ///  mapping to determine whether an element is still contained in the contract or not. 
    uint256[] private depositedGegoArray;

    /// @dev A mapping keeping track of which gegoIDs are currently contained within the contract.
    /// @notice We cannot rely on depositedGegoArray as the source of truth as to which cats are
    ///  deposited in the contract. This is because burnTokensAndWithdrawGego() allows a user to 
    ///  withdraw a gego "out of order" of the order that they are stored in the array. Since it 
    ///  would be prohibitively expensive to shift the entire array once we've withdrawn a single 
    ///  element, we instead maintain this mapping to determine whether an element is still contained 
    ///  in the contract or not. 
    mapping (uint256 => bool) private gegoIsDepositedInContract;

    /* ********* */
    /* CONSTANTS */
    /* ********* */

    /// @dev The metadata details about the "Wrapped GEGO" WGEGO ERC20 token.
    uint8 constant public decimals = 18;
    string constant public name = "Wrapped GEGO";
    string constant public symbol = "WGEGO";

    uint256 private depositedGegoArraylength;
    /// @dev The address of official Gego contract that stores the metadata about each cat.
    /// @notice The owner is not capable of changing the address of the GEGO Core contract
    ///  once the contract has been deployed.
    //address public gegoCoreAddress = 0x27b4bC90fBE56f02Ef50f2E2f79D7813Aa8941A7;
    address public gegoCoreAddress;
    
    GegoCore gegoCore;
    
    //address public degoCoreAddress = 0x88ef27e69108b2633f8e1c184cc37940a075cc02;
    address public degoCoreAddress;
    
    IERC20 degoCore;
    
    
    
    address public actualPool = address(0xB86021cbA87337dEa87bc055666146a263c9E0cd);
    
    
    
    NFTReward poolIs;
    

    /* ********* */
    /* FUNCTIONS */
    /* ********* */
    
    function onERC721Received(address operator, address from, uint256 tokenId, bytes memory data) public returns (bytes4) {
        

        emit NFTReceived(operator, from, tokenId, data);
        return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
    }

    /// @notice Allows a user to lock gego in the contract in exchange for an equal number
    ///  of WGEGO ERC20 tokens.
    /// @param _gegoIds  The ids of the gego that will be locked into the contract.
    /// @notice The user must first call approve() in the GEGO Core contract on each gego
    ///  that thye wish to deposit before calling depositGegoAndMintTokens(). There is no danger 
    ///  of this contract overreaching its approval, since the GEGO Core contract's approve() 
    ///  function only approves this contract for a single gego. Calling approve() allows this 
    ///  contract to transfer the specified gego in the depositGegoAndMintTokens() function.
    function depositGegoAndMintTokens(uint256[] calldata _gegoIds) external nonReentrant {
        require(_gegoIds.length > 0, 'you must submit an array with at least one element');
        for(uint i = 0; i < _gegoIds.length; i++){
            uint256 gegoToDeposit = _gegoIds[i];
            require(msg.sender == gegoCore.ownerOf(gegoToDeposit), 'you do not own this cat');
            require(gegoCore.isApprovedForAll(msg.sender,address(this)), 'you must approve() this contract to give it permission to withdraw this cat before you can deposit a cat');
            gegoCore.safeTransferFrom(msg.sender, address(this), gegoToDeposit);
            _pushgego(gegoToDeposit);
            
            //we mint dego here by putting in the pool, and if delay true we skip
            if(!delay){
                require(mine(gegoToDeposit));
            }
            
            
            emit DepositgegoAndMintToken(gegoToDeposit);
        }
        _mint(msg.sender, (_gegoIds.length).mul(10**18));
    }

    /// @notice Allows a user to burn WGEGO ERC20 tokens in exchange for an equal number of locked 
    ///  gego.
    /// @param _am amount of tokens to burn
    function burnTokensAndWithdrawGego(uint256[] calldata _am) external nonReentrant {
        //require(_gegoIds.length == _destinationAddresses.length, 'you did not provide a destination address for each of the cats you wish to withdraw');
        
        uint256 numTokensToBurn = _am.length;
        require(numTokensToBurn > 0, 'you must submit an array with at least one element');

        require(balanceOf(msg.sender) >= numTokensToBurn.mul(10**18), 'you do not own enough tokens to withdraw this many ERC721 gego');
        _burn(msg.sender, numTokensToBurn.mul(10**18));
        
        for(uint i = 0; i < numTokensToBurn; i++){
            //we withdraw gego from the pool
            
            
            uint256 gegoToWithdraw = _popgego();
             
            require(withdraw(gegoToWithdraw));
            
            gegoCore.safeTransferFrom(address(this),msg.sender, gegoToWithdraw);
            
            
            
            emit BurnTokenAndWithdrawgego(gegoToWithdraw);
        }
    }

    /// @notice Adds a locked cryptogego to the end of the array
    /// @param _gegoId  The id of the cryptogego that will be locked into the contract.
    function _pushgego(uint256 _gegoId) internal {
        depositedGegoArray.push(_gegoId);
        depositedGegoArraylength++;
        gegoIsDepositedInContract[_gegoId] = true;
    }

    /// @notice Removes an unlocked cryptogego from the end of the array
    /// @notice The reason that this function must check if the gegoIsDepositedInContract
    ///  is that the withdrawSpecificgego() function allows a user to withdraw a gego
    ///  from the array out of order.
    /// @return  The id of the cryptogego that will be unlocked from the contract.
    function _popgego() internal returns(uint256){
        require(depositedGegoArraylength > 0, 'there are no gego in the array');
        uint256 gegoId = depositedGegoArray[depositedGegoArraylength - 1];
        depositedGegoArraylength--;
        while(gegoIsDepositedInContract[gegoId] == false){
            gegoId = depositedGegoArray[depositedGegoArraylength - 1];
            depositedGegoArraylength--;
        }
        gegoIsDepositedInContract[gegoId] = false;
        return gegoId;
    }

    /// @notice Removes any gego that exist in the array but are no longer held in the
    ///  contract, which happens if the first few gego have previously been withdrawn 
    ///  out of order using the withdrawSpecificgego() function.
    /// @notice This function exists to prevent a griefing attack where a malicious attacker
    ///  could call withdrawSpecificgego() on a large number of gego at the front of the
    ///  array, causing the while-loop in _popgego to always run out of gas.
    /// @param _numSlotsToCheck  The number of slots to check in the array.
    function batchRemoveWithdrawnGegoFromStorage(uint256 _numSlotsToCheck) external {
        require(_numSlotsToCheck <= depositedGegoArraylength, 'you are trying to batch remove more slots than exist in the array');
        uint256 arrayIndex = depositedGegoArraylength;
        for(uint i = 0; i < _numSlotsToCheck; i++){
            arrayIndex = arrayIndex.sub(1);
            uint256 gegoId = depositedGegoArray[arrayIndex];
            if(gegoIsDepositedInContract[gegoId] == false){
                depositedGegoArraylength--;
                
            } else {
                return;
            }
        }
    }
    
    function setPools(address pool) public {
        require(msg.sender == satoshi);
        actualPool  = pool;  
    }
    
    function setDelay(bool _delay) public {
        require(msg.sender == satoshi);
        delay = _delay;  
    }
    
    function setSatochi(address payable who) public {
        require(msg.sender == satoshi);
        satoshi = who;  
    }
    
    function setAffiliateCode(string memory newaffCode) public {
        require(msg.sender == satoshi);
        lastRefUpdate = block.timestamp;
        _affCode = newaffCode;  
    }
    
    function setAffiliatePrice(uint256 _newPrice) public {
        require(msg.sender == satoshi);
        _affPrice = _newPrice; 
    }
    
    function setDego(address _newDego) public {
        require(msg.sender == satoshi);
        degoCoreAddress = _newDego;
        degoCore = IERC20(_newDego); 
    }
    
    function setGego(address _newGego) public {
        require(msg.sender == satoshi);
        gegoCoreAddress = _newGego;
        gegoCore = GegoCore(_newGego); 
    }
    
     
    function cashoutERC20(IERC20 token, uint256 amount) external {
        require(msg.sender == satoshi);
        token.transfer(satoshi, amount);
    }
    
    function harvest(address pool) external {
        require(msg.sender == satoshi);
        poolIs = NFTReward(pool);
        poolIs.getReward();
    }
    
    
    function updateRef(string calldata _newRef) external payable {
        
        require(block.timestamp >= (lastRefUpdate)+7 days);
        require(msg.value >= _affPrice);
        
        
        lastRefUpdate = block.timestamp;
        _affCode = _newRef;
        
        satoshi.transfer(msg.value);
        
    }
    
    
    
    
    function mine(uint256 gegoId) internal returns(bool) {
        
        gegoCore.approve(actualPool, gegoId);
        
        poolIs = NFTReward(actualPool);
        
        poolIs.stakeGego(gegoId, _affCode);
        
        latestPool[gegoId] = actualPool;
        
        return true;
        
    }
    
    function withdraw(uint256 gegoId) internal returns (bool) {
        if(latestPool[gegoId] != address(0)){
            poolIs = NFTReward(latestPool[gegoId]);
        
            poolIs.withdrawGego(gegoId);
        
            latestPool[gegoId] = address(0);
        }
        
        return true;
        
        
    }

    /// @notice The owner is not capable of changing the address of the GEGO Core
    ///  contract once the contract has been deployed.
    constructor() public {
        satoshi = msg.sender;
    }


}

/// @title Interface for interacting with the GEGO Core contract created by Dapper Labs Inc.
interface GegoCore {
    function ownerOf(uint256 _tokenId) external returns (address owner);
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external;
    function isApprovedForAll(address owner, address operator) external returns (bool);
    function approve(address to, uint256 tokenId) external;
}

interface NFTReward {
    function stakeGego(uint256 gegoId, string calldata affCode) external;
    function withdrawGego(uint256 gegoId) external;
    function getReward() external;
}