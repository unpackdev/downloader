// SPDX-License-Identifier: GPL-3.0

// Contracts are written by @Dexaran (twitter.com/Dexaran github.com/Dexaran)
// Read more about ERC-223 standard here: dexaran.github.io/erc223

// D223 is a token of Dex223.io exchange.

pragma solidity >=0.8.2;

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
}

/**
 * @title Reference implementation of the ERC223 standard token.
 */
contract D223Token {

     /**
     * @dev Event that is fired on successful transfer.
     */
    event Transfer(address indexed from, address indexed to, uint value, bytes data);
    event Approval(address indexed owner, address indexed spender, uint256 amount);

    string  private _name;
    string  private _symbol;
    uint8   private _decimals;
    uint256 private _totalSupply;
    address public  owner = msg.sender;
    mapping(address account => mapping(address spender => uint256)) private allowances;
    
    mapping(address => uint256) private balances; // List of user balances.

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
     
    constructor()
    {
        _name     = "Dex223 token";
        _symbol   = "D223";
        _decimals = 18;
        balances[msg.sender] = 8000000000 * 1e18;
        emit Transfer(address(0), msg.sender, balances[msg.sender], hex"000000");
        _totalSupply = balances[msg.sender];
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view returns (string memory)
    {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view returns (string memory)
    {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC223} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC223-balanceOf} and {IERC223-transfer}.
     */
    function decimals() public view returns (uint8)
    {
        return _decimals;
    }

    /**
     * @dev See {IERC223-totalSupply}.
     */
    function totalSupply() public view returns (uint256)
    {
        return _totalSupply;
    }

    /**
     * @dev See {IERC223-standard}.
     */
    function standard() public view returns (string memory)
    {
        return "223";
    }

    
    /**
     * @dev Returns balance of the `_owner`.
     *
     * @param _owner   The address whose balance will be returned.
     * @return balance Balance of the `_owner`.
     */
    function balanceOf(address _owner) public view returns (uint256)
    {
        return balances[_owner];
    }
    
    /**
     * @dev Transfer the specified amount of tokens to the specified address.
     *      Invokes the `tokenFallback` function if the recipient is a contract.
     *      The token transfer fails if the recipient is a contract
     *      but does not implement the `tokenFallback` function
     *      or the fallback function to receive funds.
     *
     * @param _to    Receiver address.
     * @param _value Amount of tokens that will be transferred.
     * @param _data  Transaction metadata.
     */
    function transfer(address _to, uint _value, bytes calldata _data) public returns (bool success)
    {
        // Standard function transfer similar to ERC20 transfer with no _data .
        // Added due to backwards compatibility reasons .
        balances[msg.sender] = balances[msg.sender] - _value;
        balances[_to] = balances[_to] + _value;
        if(Address.isContract(_to)) {
            IERC223Recipient(_to).tokenReceived(msg.sender, _value, _data);
        }
        emit Transfer(msg.sender, _to, _value, _data);
        return true;
    }
    
    /**
     * @dev Transfer the specified amount of tokens to the specified address.
     *      This function works the same with the previous one
     *      but doesn't contain `_data` param.
     *      Added due to backwards compatibility reasons.
     *
     * @param _to    Receiver address.
     * @param _value Amount of tokens that will be transferred.
     */
    function transfer(address _to, uint _value) public returns (bool success)
    {
        bytes memory _empty = hex"00000000";
        balances[msg.sender] = balances[msg.sender] - _value;
        balances[_to] = balances[_to] + _value;
        if(Address.isContract(_to)) {
            IERC223Recipient(_to).tokenReceived(msg.sender, _value, _empty);
        }
        emit Transfer(msg.sender, _to, _value, _empty);
        return true;
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
        
        emit Transfer(_from, _to, _value, hex"00000000");
        
        return true;
    }

    function rescueERC20(address _token, uint256 _value) external
    {
        require(msg.sender == owner);
        (bool success, bytes memory data) = _token.call(abi.encodeWithSelector(0xa9059cbb, msg.sender, _value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "Transfer failed");
    }

    function newOwner(address _owner) external
    {
        require(msg.sender == owner);
        owner = _owner;
    }
}

abstract contract LinkOracle
{
   function latestAnswer() external view virtual returns (int256);
}

contract D223ICO {

    address public owner = msg.sender;

    uint256 public price_rate_USD = 1538; // Target price $0.00065 per D223 token.

    address public USDT_contract  = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address public USDC_contract  = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address public DAI_contract   = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address public ICO_token      = 0x7008D42622a8B4eF73e946833EA90E608de9e96B;

    LinkOracle public ETH_price_oracle = LinkOracle(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419);

    bool public active = true;

    modifier requireActive
    {
        require(active == true);
        _;
    }

    function setActive(bool _active) external
    {
        require(msg.sender == owner);
        active = _active;
    }

    receive() external payable requireActive
    {
        IERC20(ICO_token).transfer(msg.sender, price_rate_USD * msg.value * uint256(ETH_price_oracle.latestAnswer())/1e8);
    }

    function tokenReceived(address _from, uint _value, bytes memory _data) public returns (bytes4)
    {
        require(msg.sender == ICO_token);
        return this.tokenReceived.selector; //return 0x8943ec02;
    }

    function purchaseTokens(address _payment_token, uint256 _payment_amount) public requireActive
    {
        require(_payment_token == USDT_contract || _payment_token == USDC_contract || _payment_token == DAI_contract, "Wrong token");
        safeTransferFrom(_payment_token, msg.sender, address(this), _payment_amount);
        if(_payment_token == USDT_contract || _payment_token == USDC_contract)
        {
            _payment_amount = _payment_amount * 1e12; // USDT and USDC have 6 decimals.
        }
        IERC20(ICO_token).transfer(msg.sender, _payment_amount * price_rate_USD);
    }

    function getRewardAmount(address _payment_token, uint256 _deposit) public view returns (uint256)
    {
        if(_payment_token == USDT_contract || _payment_token == USDC_contract)
        {
            return _deposit * price_rate_USD * 1e12;
        } 
        if (_payment_token == DAI_contract) 
        {
            return _deposit * price_rate_USD;
        }
        if(_payment_token == address(0))     
        {
            return _deposit * price_rate_USD * uint256(ETH_price_oracle.latestAnswer())/1e8;
        }
        return 0;
    }

    function set(uint256 _price_USD, address _ICO_token, address _USDT, address _USDC, address _DAI) public
    {
        require(msg.sender == owner);
        price_rate_USD     = _price_USD;
        USDT_contract      = _USDT;
        USDC_contract      = _USDC;
        DAI_contract       = _DAI;
        ICO_token          = _ICO_token;
    }

    function extractTokens(address _token, uint256 _amount) public
    {
        require(msg.sender == owner);
        //IERC20(_token).transfer(msg.sender, _amount);
        safeTransfer(_token, msg.sender, _amount);
        if(_token == address(0))
        {
            payable(msg.sender).transfer(address(this).balance);
        }
    }
    
    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "Transfer failed");
    }
    
    function safeTransfer(address token, address to, uint value) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "Transfer failed");
    }
}