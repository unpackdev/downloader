// SPDX-License-Identifier: CC0
pragma solidity 0.8.17;

import "./IERC20.sol";
import "./IERC20Metadata.sol";
import "./SafeMath.sol";
import "./MaliciousRegister.sol";

contract CLPC is IERC20, IERC20Metadata, Ownable, MaliciousRegister {
    using SafeMath for uint256;

    bool private _initialized;

    mapping(address => uint256) private _balances;
    mapping(address => uint256) private _burnAmountOf;
    mapping(address => mapping(address => uint256)) private _allowances;

    string public constant currency = "CLP";

    string public symbol;
    uint8 public decimals;
    string public name;
    uint256 public totalSupply;
    uint public version;
    uint256 public burnAmount;

    event Burn(address indexed burner, uint256 amount);
    event Mint(address indexed minter, address indexed to, uint256 amount);

    function init(
        string memory _name,
        string memory _symbol,
        uint _version
    ) external {
        if(_initialized){
            return;
        }

        initOwnable();
        
        version = _version;
        symbol = _symbol;
        name = _name;
        decimals = 0;
        _initialized = true;
    }

    function _transfer(
        address from,
        address to,
        uint256 value
    ) private {
        require(from != address(0), "ERC20: Transfer from the zero address");
        require(to != address(0), "ERC20: Transfer to the zero address");
        require(from != to, "ERC20: To owner");
        require(value <= _balances[from], "ERC20: Transfer amount exceeds balance");

        _balances[from] = _balances[from].sub(value);
        _balances[to] = _balances[to].add(value);

        emit Transfer(from, to, value);
    }

    function setAllowance(
        address owner,
        address spender,
        uint256 newAllowance
    ) private {
        require(owner != address(0), "ERC20: Allowance from the zero address");
        require(spender != address(0), "ERC20: Allowance to the zero address");
        require(spender != owner, "ERC20: Spender is the owner");
        require(newAllowance >= 0, "ERC20: Allowance less than 0");

        _allowances[owner][spender] = newAllowance;

        emit Approval(owner, spender, newAllowance);
    }

    /**
     * @notice Burn tokens from the caller
     * @param amount   Amount to burn
     */
    function burn(uint256 amount) 
        external 
        whenNotPaused 
        noMalicious 
    {
        uint256 accountBalance = _balances[_msgSender()];

        require(accountBalance >= amount, "CLPC: Burn amount exceeds balance");

        totalSupply = totalSupply.sub(amount);
        _balances[_msgSender()] = accountBalance.sub(amount);

        _burnAmountOf[_msgSender()] = _burnAmountOf[_msgSender()].add(amount);
        burnAmount = burnAmount.add(amount);

        emit Transfer(_msgSender(), address(0), amount);
        emit Burn(_msgSender(), amount);
    }

    /**
     * @notice Mint tokens from the admin to clients
     * @param tos       Clients addresses
     * @param amounts   Amounts to mint
     */
    function mint(
        address[] calldata tos,
        uint256[] calldata amounts
    ) external onlyOwner whenNotPaused {
        uint256 totalAmount;

        for (uint i = 0; i < tos.length; i++) {
            address account = tos[i];
            uint256 amount = amounts[i];

            require(account != address(0), "Mint to the zero address");
            require(amount > 0, "Mint with less than 0 amount");

            _balances[account] = _balances[account].add(amount);
            totalAmount = totalAmount.add(amount); 

            emit Transfer(address(0), account, amount);
            emit Mint(msg.sender, account, amount);
        }

        totalSupply = totalSupply.add(totalAmount);
    }

    function setDecimals(uint8 newDecimals) external onlyOwner whenNotPaused {
        decimals = newDecimals;
    }

    /**
     * @notice Transfer tokens from the caller
     * @param to        Payee's address
     * @param value     Transfer amount
     * @return success  True if successful
     */
    function transfer(
        address to,
        uint256 value
    )
        external
        override(IERC20)
        whenNotPaused
        noMalicious
        noMaliciousAddress(to)
        returns (bool success)
    {
        _transfer(_msgSender(), to, value);

        return true;
    }

    /**
     * @notice Transfer tokens by spending allowance
     * @param from      Payer's address
     * @param to        Payee's address
     * @param value     Transfer amount
     * @return success  True if successful
     */
    function transferFrom(
        address from,
        address to,
        uint256 value
    )
        external
        override(IERC20)
        whenNotPaused
        noMalicious
        noMaliciousAddress(from)
        noMaliciousAddress(to)
        returns (bool success)
    {        
        require(
            value <= _allowances[from][_msgSender()],
            "ERC20: transfer amount exceeds allowance"
        );

        _transfer(from, to, value);

        _allowances[from][_msgSender()] = _allowances[from][_msgSender()].sub(value);
      
        return true;
    }

    /**
     * @notice Amount of remaining tokens spender is allowed to transfer on
     * behalf of the token owner
     * @param owner     Token owner's address
     * @param spender   Spender's address
     * @return Allowance amount
     */
    function allowance(
        address owner,
        address spender
    ) external view override(IERC20) returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @notice Get token balance of an account
     * @param account address The account
     */
    function balanceOf(
        address account
    ) external view override(IERC20) returns (uint256) {
        return _balances[account];
    }

    /**
     * @notice Set spender's allowance over the caller's tokens to be a given
     * value.
     * @param spender   Spender's address
     * @param value     Allowance amount
     * @return success  True if successful
     */
    function approve(
        address spender,
        uint256 value
    ) 
        external 
        whenNotPaused
        noMalicious
        noMaliciousAddress(spender)
        override(IERC20) 
        returns (bool success) 
    {
        setAllowance(_msgSender(), spender, value);

        return true;
    }

    /**
     * @notice Get token burn amount of a given address
     * @param owner Token burner address
     */
    function burnAmountOf(
        address owner
    ) external view returns (uint256 amount) {
        return _burnAmountOf[owner];
    }

    function setPause(bool enabled) external onlyOwner {
        if (enabled) {
            _pause();
        } else {
            _unpause();
        }
    }

    function updateVersion(uint newVersion) external onlyOwner whenNotPaused {
         version = newVersion;
    }

        /**
     * @notice Increase the allowance by a given increment
     * @param spender   Spender's address
     * @param addedValue Amount of increase in allowance
     * @return newAllowance The new amount allowed
     */
    function increaseAllowance(
        address spender,
        uint256 addedValue
    )
        external
        noMalicious
        noMaliciousAddress(spender)
        whenNotPaused
        returns (uint256 newAllowance)
    {
        newAllowance = _allowances[_msgSender()][spender].add(addedValue);

        setAllowance(_msgSender(), spender, newAllowance);
    }

  /**
     * @notice Decrease the allowance by a given decrement
     * @param spender   Spender's address
     * @param subtractedValue Amount of decrease in allowance
     * @return newAllowance The new amount allowed
     */
    function decreaseAllowance(
        address spender,
        uint256 subtractedValue
    )
        external
        noMalicious
        whenNotPaused
        noMaliciousAddress(spender)
        returns (uint256 newAllowance)
    {
        newAllowance = _allowances[_msgSender()][spender].sub(subtractedValue);

        setAllowance(_msgSender(), spender, newAllowance);
    }
}
