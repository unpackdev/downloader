// SPDX-License-Identifier: MIT

// ERC20 adapted from: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/ERC20.sol

// Then adapted from: https://github.com/CoinbaseStablecoin/eip-3009/
// Bugfix by Thomas Rogg, Neonious GmbH: https://github.com/CoinbaseStablecoin/eip-3009/pull/1

// Then added additional methods as noted in the Neonious whitepaper at the very bottom

pragma solidity 0.6.12;

import "./SafeMath.sol";
import "./Address.sol";

import "./IERC20Internal.sol";
import "./EIP3009.sol";
import "./EIP712.sol";

abstract contract ERC20 {
    function transfer(address to, uint256 amount) virtual public returns (bool success);
}

contract Token is IERC20Internal, EIP3009 {
    using SafeMath for uint256;
    using Address for address;

    mapping(address => uint256) internal _balances;
    mapping(address => mapping(address => uint256)) internal _allowances;

    address internal _owner;
    address internal _miningContract;
    uint256 internal _totalSupply;
    string internal _name;
    string internal _version;
    string internal _symbol;
    uint8 internal _decimals;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    constructor(
        string memory tokenName,
        string memory tokenVersion,
        string memory tokenSymbol,
        uint8 tokenDecimals,
        uint256 tokenTotalSupply
    ) public {
        _owner = msg.sender;
        _miningContract = address(0);

        _name = tokenName;
        _version = tokenVersion;
        _symbol = tokenSymbol;
        _decimals = tokenDecimals;

        DOMAIN_SEPARATOR = EIP712.makeDomainSeparator(tokenName, tokenVersion);

        _mint(msg.sender, tokenTotalSupply);
    }

    /**
     * @notice Token name
     * @return Name
     */
    function name() external view returns (string memory) {
        return _name;
    }

    /**
     * @notice Token version
     * @return Version
     */
    function version() external view returns (string memory) {
        return _version;
    }

    /**
     * @notice Token symbol
     * @return Symbol
     */
    function symbol() external view returns (string memory) {
        return _symbol;
    }

    /**
     * @notice Number of decimal places
     * @return Decimals
     */
    function decimals() external view returns (uint8) {
        return _decimals;
    }

    /**
     * @notice Total amount of tokens in circulation
     * @return Total supply
     */
    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @notice Get the balance of an account
     * @param account The account
     * @return Balance
     */
    function balanceOf(address account) external view returns (uint256) {
        return _balances[account];
    }

    /**
     * @notice Amount of remaining tokens spender is allowed to transfer on
     * behalf of the token owner
     * @param owner     Token owner's address
     * @param spender   Spender's address
     * @return Allowance amount
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    /**
     * @notice Set spender's allowance over the caller's tokens to be a given
     * value
     * @param spender   Spender's address
     * @param amount    Allowance amount
     * @return True if successful
     */
    function approve(address spender, uint256 amount) external returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    /**
     * @notice Transfer tokens by spending allowance
     * @param sender    Payer's address
     * @param recipient Payee's address
     * @param amount    Transfer amount
     * @return True if successful
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            msg.sender,
            _allowances[sender][msg.sender].sub(
                amount,
                "ERC20: transfer amount exceeds allowance"
            )
        );
        return true;
    }

    /**
     * @notice Transfer tokens from the caller
     * @param recipient Payee's address
     * @param amount    Transfer amount
     * @return True if successful
     */
    function transfer(address recipient, uint256 amount)
        external
        returns (bool)
    {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    /**
     * @notice Increase the allowance by a given amount
     * @param spender       Spender's address
     * @param addedValue    Amount of increase in allowance
     * @return True if successful
     */
    function increaseAllowance(address spender, uint256 addedValue)
        external
        returns (bool)
    {
        _increaseAllowance(msg.sender, spender, addedValue);
        return true;
    }

    /**
     * @notice Decrease the allowance by a given amount
     * @param spender           Spender's address
     * @param subtractedValue   Amount of decrease in allowance
     * @return True if successful
     */
    function decreaseAllowance(address spender, uint256 subtractedValue)
        external
        returns (bool)
    {
        _decreaseAllowance(msg.sender, spender, subtractedValue);
        return true;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal override {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(
            amount,
            "ERC20: transfer amount exceeds balance"
        );
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal override {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal override {
        require(account != address(0), "ERC20: burn from the zero address");

        _balances[account] = _balances[account].sub(
            amount,
            "ERC20: burn amount exceeds balance"
        );
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal override {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _increaseAllowance(
        address owner,
        address spender,
        uint256 addedValue
    ) internal override {
        _approve(owner, spender, _allowances[owner][spender].add(addedValue));
    }

    function _decreaseAllowance(
        address owner,
        address spender,
        uint256 subtractedValue
    ) internal override {
        _approve(
            owner,
            spender,
            _allowances[owner][spender].sub(
                subtractedValue,
                "ERC20: decreased allowance below zero"
            )
        );
    }

    // From ERC20Burnable.sol, OpenZeppelin 3.3

    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual {
        _burn(msg.sender, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual {
        uint256 decreasedAllowance = _allowances[account][msg.sender].sub(amount, "ERC20: burn amount exceeds allowance");

        _approve(account, msg.sender, decreasedAllowance);
        _burn(account, amount);
    }

    /*
     * ADDITIONS BY NEONIOUS. SEE NEONIOUS TOKEN WHITEPAPER FOR DETAILS
     */

    // If we are compromised, we must be able to switch owner
    function switchOwner(address owner) public {
        require(msg.sender == _owner, "May only called by owner of smart contract");
        _owner = owner;
    }

    // So funds mistakenly sent to the smart contract are not lost
    function transferOwn(address tokenAddress, address payable to, uint256 amount) public {
        require(msg.sender == _owner, "May only called by owner of smart contract");
        if(tokenAddress == address(0))
            to.transfer(amount);
        else
            require(ERC20(tokenAddress).transfer(to, amount));
    }

    receive() external payable {}

    // Transfer many
    function transferToMany(address[] memory tos, uint256[] memory amounts) public {
        for(uint256 i = 0; i < tos.length; i++)
            _transfer(msg.sender, tos[i], amounts[i]);
    }

    // Attach mining contract
    function setMiningContract(address miningContract) public {
        require(msg.sender == _owner, "May only called by owner of smart contract");
        _miningContract = miningContract;
    }

    function rewardMining(address[] memory tos, uint256[] memory amounts) public {
        require(msg.sender == _miningContract && msg.sender != address(0), "May only called by mining contract");
        for(uint256 i = 0; i < tos.length; i++)
            _mint(tos[i], amounts[i]);
    }
}