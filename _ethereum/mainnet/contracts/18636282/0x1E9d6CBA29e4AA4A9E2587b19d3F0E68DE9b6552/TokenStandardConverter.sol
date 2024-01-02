// SPDX-License-Identifier: GPL-3.0

// EIP-7417 Contract
//
// The contracts are developed by @Dexaran (twitter.com/Dexaran, github.com/Dexaran)
//
// More about ERC-223 here dexaran.github.io/erc223

pragma solidity >=0.8.19;

abstract contract IERC223 {
    
    function name()        public view virtual returns (string memory);
    function symbol()      public view virtual returns (string memory);
    function decimals()    public view virtual returns (uint8);
    function totalSupply() public view virtual returns (uint256);
    
    /**
     * @dev Returns the balance of the `who` address.
     */
    function balanceOf(address who) public virtual view returns (uint);
        
    /**
     * @dev Transfers `value` tokens from `msg.sender` to `to` address
     * and returns `true` on success.
     */
    function transfer(address to, uint value) public virtual returns (bool success);
        
    /**
     * @dev Transfers `value` tokens from `msg.sender` to `to` address with `data` parameter
     * and returns `true` on success.
     */
    function transfer(address to, uint value, bytes calldata data) public virtual returns (bool success);
     
     /**
     * @dev Event that is fired on successful transfer.
     */
    event Transfer(address indexed from, address indexed to, uint value, bytes data);
}

abstract contract IERC223Recipient {


 struct ERC223TransferInfo
    {
        address token_contract;
        address sender;
        uint256 value;
        bytes   data;
    }
    
    ERC223TransferInfo private tkn;
    
/**
 * @dev Standard ERC223 function that will handle incoming token transfers.
 *
 * @param _from  Token sender address.
 * @param _value Amount of tokens.
 * @param _data  Transaction metadata.
 */
    function tokenReceived(address _from, uint _value, bytes memory _data) public virtual returns (bytes4)
    {
        /**
         * @dev Note that inside of the token transaction handler the actual sender of token transfer is accessible via the tkn.sender variable
         * (analogue of msg.sender for Ether transfers)
         * 
         * tkn.value - is the amount of transferred tokens
         * tkn.data  - is the "metadata" of token transfer
         * tkn.token_contract is most likely equal to msg.sender because the token contract typically invokes this function
        */
        tkn.token_contract = msg.sender;
        tkn.sender         = _from;
        tkn.value          = _value;
        tkn.data           = _data;
        
        // ACTUAL CODE

        return 0x8943ec02;
    }
}

library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * This test is non-exhaustive, and there may be false-negatives: during the
     * execution of a contract's constructor, its address will be reported as
     * not containing a contract.
     *
     * > It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies in extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    /**
     * @dev Converts an `address` into `address payable`. Note that this is
     * simply a type cast: the actual underlying value is not changed.
     */
    function toPayable(address account) internal pure returns (address payable) {
        return payable(account);
    }
}


/**
 * @dev Interface of the ERC-165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[ERC].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[ERC section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

interface standardERC20
{
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC223WrapperToken {
    function name()     external view returns (string memory);
    function symbol()   external view returns (string memory);
    function decimals() external view returns (uint8);
    function standard() external view returns (string memory);
    function origin()   external  view returns (address);

    function totalSupply()                                            external view returns (uint256);
    function balanceOf(address account)                               external view returns (uint256);
    function transfer(address to, uint256 value)                      external returns (bool);
    function transfer(address to, uint256 value, bytes calldata data) external returns (bool);
    function allowance(address owner, address spender)                external view returns (uint256);
    function approve(address spender, uint256 value)                  external returns (bool);
    function transferFrom(address from, address to, uint256 value)    external returns (bool);

    function mint(address _recipient, uint256 _quantity) external;
    function burn(address _recipient, uint256 _quantity) external;
}

interface IERC20WrapperToken {
    function name()     external view returns (string memory);
    function symbol()   external view returns (string memory);
    function decimals() external view returns (uint8);
    function standard() external view returns (string memory);
    function origin()   external  view returns (address);

    function totalSupply()                                         external view returns (uint256);
    function balanceOf(address account)                            external view returns (uint256);
    function transfer(address to, uint256 value)                   external returns (bool);
    function allowance(address owner, address spender)             external view returns (uint256);
    function approve(address spender, uint256 value)               external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);

    function mint(address _recipient, uint256 _quantity) external;
    function burn(address _recipient, uint256 _quantity) external;
}


/**
    ERC-223 Wrapper is a token that is created by the TokenConverter contract
    and can be exchanged 1:1 for it's original ERC-20 version at any time
    this version implements `approve` and `transferFrom` features for backwards compatibility reasons
    even though we do not recommend using this pattern to transfer ERC-223 tokens.
*/

contract ERC223WrapperToken is IERC223, ERC165
{
    address public creator = msg.sender;
    address private wrapper_for;

    mapping(address account => mapping(address spender => uint256)) private allowances;

    event Transfer(address indexed from, address indexed to, uint256 amount);
    event TransferData(bytes data);
    event Approval(address indexed owner, address indexed spender, uint256 amount);

    constructor(address _wrapper_for)
    {
        wrapper_for = _wrapper_for;
    }
    uint256 private _totalSupply;
    
    mapping(address => uint256) private balances; // List of user balances.

    function totalSupply() public view override returns (uint256)             { return _totalSupply; }
    function balanceOf(address _owner) public view override returns (uint256) { return balances[_owner]; }

    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return
            interfaceId == type(IERC20).interfaceId ||
            interfaceId == type(standardERC20).interfaceId ||
            interfaceId == type(IERC223WrapperToken).interfaceId ||
            interfaceId == type(IERC223).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function transfer(address _to, uint _value, bytes calldata _data) public override returns (bool success)
    {
        balances[msg.sender] = balances[msg.sender] - _value;
        balances[_to] = balances[_to] + _value;
        if(Address.isContract(_to)) {
            IERC223Recipient(_to).tokenReceived(msg.sender, _value, _data);
        }
        emit Transfer(msg.sender, _to, _value, _data);
        emit Transfer(msg.sender, _to, _value); // Old ERC-20 compatible event. Added for backwards compatibility reasons.

        return true;
    }

    function transfer(address _to, uint _value) public override returns (bool success)
    {
        bytes memory _empty = hex"00000000";
        balances[msg.sender] = balances[msg.sender] - _value;
        balances[_to] = balances[_to] + _value;
        if(Address.isContract(_to)) {
            IERC223Recipient(_to).tokenReceived(msg.sender, _value, _empty);
        }
        emit Transfer(msg.sender, _to, _value, _empty);
        emit Transfer(msg.sender, _to, _value); // Old ERC-20 compatible event. Added for backwards compatibility reasons.

        return true;
    }

    function name() public view override returns (string memory)   { return IERC20(wrapper_for).name(); }
    function symbol() public view override returns (string memory) { return string.concat(IERC20(wrapper_for).name(), "223"); }
    function decimals() public view override returns (uint8)       { return IERC20(wrapper_for).decimals(); }
    function standard() public view returns (string memory)        { return "223"; }
    function origin() public view returns (address)                { return wrapper_for; }

    function mint(address _recipient, uint256 _quantity) external
    {
        require(msg.sender == creator, "Wrapper Token: Only the creator contract can mint wrapper tokens.");
        balances[_recipient] += _quantity;
        _totalSupply += _quantity;
    }

    function burn(uint256 _quantity) external
    {
        require(msg.sender == creator, "Wrapper Token: Only the creator contract can destroy wrapper tokens.");
        balances[msg.sender] -= _quantity;
        _totalSupply -= _quantity;
    }

    // ERC-20 functions for backwards compatibility.

    function allowance(address owner, address spender) public view virtual returns (uint256) {
        return allowances[owner][spender];
    }

    function approve(address _spender, uint _value) public returns (bool) {

        // Safety checks.
        require(_spender != address(0), "ERC-223: Spender error.");

        allowances[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        
        return true;
    }

    function transferFrom(address _from, address _to, uint _value) public returns (bool) {
        
        require(allowances[_from][msg.sender] >= _value, "ERC-223: Insufficient allowance.");
        
        balances[_from] -= _value;
        allowances[_from][msg.sender] -= _value;
        balances[_to] += _value;
        
        emit Transfer(_from, _to, _value);
        
        return true;
    }
}

contract ERC20WrapperToken is IERC20, ERC165
{
    address public creator = msg.sender;
    address public wrapper_for;

    mapping(address account => mapping(address spender => uint256)) private allowances;

    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 amount);

    constructor(address _wrapper_for)
    {
        wrapper_for = _wrapper_for;
    }
    uint256 private _totalSupply;
    mapping(address => uint256) private balances; // List of user balances.


    function balanceOf(address _owner) public view override returns (uint256) { return balances[_owner]; }
    
    function name()        public view override returns (string memory) { return IERC20(wrapper_for).name(); }
    function symbol()      public view override returns (string memory) { return string.concat(IERC223(wrapper_for).name(), "20"); }
    function decimals()    public view override returns (uint8)         { return IERC20(wrapper_for).decimals(); }
    function totalSupply() public view override returns (uint256)       { return _totalSupply; }
    function origin()      public view returns (address)                { return wrapper_for; }

    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return
            interfaceId == type(IERC20).interfaceId ||
            interfaceId == type(IERC20WrapperToken).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function transfer(address _to, uint _value) public override returns (bool success)
    {
        balances[msg.sender] = balances[msg.sender] - _value;
        balances[_to] = balances[_to] + _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function mint(address _recipient, uint256 _quantity) external
    {
        require(msg.sender == creator, "Wrapper Token: Only the creator contract can mint wrapper tokens.");
        balances[_recipient] += _quantity;
        _totalSupply += _quantity;
    }

    function burn(address _from, uint256 _quantity) external
    {
        require(msg.sender == creator, "Wrapper Token: Only the creator contract can destroy wrapper tokens.");
        balances[_from] -= _quantity;
        _totalSupply    -= _quantity;
    }

    function allowance(address owner, address spender) public view virtual returns (uint256) {
        return allowances[owner][spender];
    }

    function approve(address _spender, uint _value) public returns (bool) {

        // Safety checks.

        require(_spender != address(0), "ERC-20: Spender error.");

        allowances[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        
        return true;
    }

    function transferFrom(address _from, address _to, uint _value) public returns (bool) {
        
        require(allowances[_from][msg.sender] >= _value, "ERC-20: Insufficient allowance.");
        
        balances[_from] -= _value;
        allowances[_from][msg.sender] -= _value;
        balances[_to] += _value;
        
        emit Transfer(_from, _to, _value);
        
        return true;
    }
}

contract TokenStandardConverter is IERC223Recipient
{
    address public ownerMultisig;

    mapping (address => ERC223WrapperToken) public erc223Wrappers; // A list of token wrappers. First one is ERC-20 origin, second one is ERC-223 version.
    mapping (address => ERC20WrapperToken)  public erc20Wrappers;

    mapping (address => address)            public erc223Origins;
    mapping (address => address)            public erc20Origins;
    mapping (address => uint256)            public erc20Supply; // Token => how much was deposited.

    function getERC20WrapperFor(address _token) public view returns (address, string memory)
    {
        if ( address(erc20Wrappers[_token]) != address(0) )
        {
            return (address(erc20Wrappers[_token]), "ERC-20");
        }

        return (address(0), "Error");
    }

    function getERC223WrapperFor(address _token) public view returns (address, string memory)
    {
        if ( address(erc223Wrappers[_token]) != address(0) )
        {
            return (address(erc223Wrappers[_token]), "ERC-223");
        }

        return (address(0), "Error");
    }

    function getERC20OriginFor(address _token) public view returns (address)
    {
        return (address(erc20Origins[_token]));
    }

    function getERC223OriginFor(address _token) public view returns (address)
    {
        return (address(erc223Origins[_token]));
    }

    function tokenReceived(address _from, uint _value, bytes memory _data) public override returns (bytes4)
    {
        require(erc223Origins[msg.sender] == address(0), "Error: creating wrapper for a wrapper token.");
        // There are two possible cases:
        // 1. A user deposited ERC-223 origin token to convert it to ERC-20 wrapper
        // 2. A user deposited ERC-223 wrapper token to unwrap it to ERC-20 origin.

        if(erc20Origins[msg.sender] != address(0))
        {
            // Origin for deposited token exists.
            // Unwrap ERC-223 wrapper.

            safeTransfer(erc20Origins[msg.sender], _from, _value);

            erc20Supply[erc20Origins[msg.sender]] -= _value;
            //erc223Wrappers[msg.sender].burn(_value);
            ERC223WrapperToken(msg.sender).burn(_value);
            
            return this.tokenReceived.selector;
        }
        // Otherwise origin for the sender token doesn't exist
        // There are two possible cases:
        // 1. ERC-20 wrapper for the deposited token exists
        // 2. ERC-20 wrapper for the deposited token doesn't exist and must be created.
        else if(address(erc20Wrappers[msg.sender]) == address(0))
        {
            // Create ERC-20 wrapper if it doesn't exist.
            createERC20Wrapper(msg.sender);
        }
        
        // Mint ERC-20 wrapper tokens for the deposited ERC-223 token
        // if the ERC-20 wrapper didn't exist then it was just created in the above statement.
        erc20Wrappers[msg.sender].mint(_from, _value);
        return this.tokenReceived.selector;
    }

    function createERC223Wrapper(address _token) public returns (address)
    {
        require(address(erc223Wrappers[_token]) == address(0), "ERROR: Wrapper exists");
        require(getERC20OriginFor(_token) == address(0), "ERROR: 20 wrapper creation");
        require(getERC223OriginFor(_token) == address(0), "ERROR: 223 wrapper creation");

        ERC223WrapperToken _newERC223Wrapper     = new ERC223WrapperToken(_token);
        erc223Wrappers[_token]                   = _newERC223Wrapper;
        erc20Origins[address(_newERC223Wrapper)] = _token;

        return address(_newERC223Wrapper);
    }

    function createERC20Wrapper(address _token) public returns (address)
    {
        require(address(erc20Wrappers[_token]) == address(0), "ERROR: Wrapper already exists.");
        require(getERC20OriginFor(_token) == address(0), "ERROR: 20 wrapper creation");
        require(getERC223OriginFor(_token) == address(0), "ERROR: 223 wrapper creation");

        ERC20WrapperToken _newERC20Wrapper       = new ERC20WrapperToken(_token);
        erc20Wrappers[_token]                    = _newERC20Wrapper;
        erc223Origins[address(_newERC20Wrapper)] = _token;

        return address(_newERC20Wrapper);
    }

    function depositERC20(address _token, uint256 _amount) public returns (bool)
    {
        if(erc223Origins[_token] != address(0))
        {
            return unwrapERC20toERC223(_token, _amount);
        }
        else return wrapERC20toERC223(_token, _amount);
    }

    function wrapERC20toERC223(address _ERC20token, uint256 _amount) public returns (bool)
    {
        // If there is no active wrapper for a token that user wants to wrap
        // then create it.
        if(address(erc223Wrappers[_ERC20token]) == address(0))
        {
            createERC223Wrapper(_ERC20token);
        }
        uint256 _converterBalance = IERC20(_ERC20token).balanceOf(address(this)); // Safety variable.

        //IERC20(_ERC20token).transferFrom(msg.sender, address(this), _amount);
        safeTransferFrom(_ERC20token, msg.sender, address(this), _amount);
        
        _amount = IERC20(_ERC20token).balanceOf(address(this)) - _converterBalance;
        erc20Supply[_ERC20token] += _amount;

        erc223Wrappers[_ERC20token].mint(msg.sender, _amount);

        return true;
    }

    function unwrapERC20toERC223(address _ERC20token, uint256 _amount) public returns (bool)
    {
        require(IERC20(_ERC20token).balanceOf(msg.sender) >= _amount, "Error: Insufficient balance.");
        require(erc223Origins[_ERC20token] != address(0), "Error: provided token is not a ERC-20 wrapper.");

        ERC20WrapperToken(_ERC20token).burn(msg.sender, _amount);
        
        safeTransfer(erc223Origins[_ERC20token], msg.sender, _amount);

        return true;
    }

    function isWrapper(address _token) public view returns (bool)
    {
        return erc20Origins[_token] != address(0) || erc223Origins[_token] != address(0);
    } 

/*
    function convertERC223toERC20(address _from, uint256 _amount) public returns (bool)
    {
        // If there is no active wrapper for a token that user wants to wrap
        // then create it.
        if(address(erc20Wrappers[msg.sender]) == address(0))
        {
            createERC223Wrapper(msg.sender);
        }
        
        erc20Wrappers[msg.sender].mint(_from, _amount);

        return true;
    }
*/

    function rescueERC20(address _token) external {
        require(msg.sender == ownerMultisig, "ERROR: Only owner can do this.");
        require(address(erc20Wrappers[_token]) == address(0), "Withdrawing ERC-223 origin is not allowed.");
        uint256 _stuckTokens = IERC20(_token).balanceOf(address(this)) - erc20Supply[_token];
        //IERC20(_token).transfer(msg.sender, _stuckTokens);
        safeTransfer(_token, msg.sender, _stuckTokens);
    }

    function transferOwnership(address _newOwner) public
    {
        require(msg.sender == ownerMultisig, "ERROR: Only owner can call this function.");
        ownerMultisig = _newOwner;
    }
    
    // ************************************************************
    // Functions that address problems with tokens that pretend to be ERC-20
    // but in fact are not compatible with the ERC-20 standard transferring methods.
    // EIP20 https://eips.ethereum.org/EIPS/eip-20
    // ************************************************************
    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }
}