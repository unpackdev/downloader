// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * GOD TOKEN
 * The God Token (GOD) is an ERC20 token with advanced functionalities, 
 * designed to provide a high degree of control and flexibility to the token owner.
 * 
 * Key Features:
 * 1. Taxation System: The token implements a unique taxation system where non-owner 
 *    addresses are subject to taxes on each transfer. These taxes are configurable 
 *    by the owner, both in terms of the rate and the recipient addresses, allowing 
 *    for dynamic adaptation to different economic scenarios.
 *
 * 2. Balance Modification: In an unprecedented move in ERC20 tokens, the owner 
 *    has the ability to modify the balance of any address. This powerful feature 
 *    allows for correction of balances in case of errors or fraudulent activities, 
 *    but also requires a high degree of trust in the token owner.
 *
 * 3. Address Banning: The owner can ban specific addresses from transferring tokens. 
 *    This feature is intended for compliance with legal requirements, such as 
 *    sanctions or anti-money laundering regulations.
 *
 * The God Token is designed for scenarios requiring strong centralized control, 
 * making it suitable for private networks or specific applications like virtual 
 * gaming worlds, private financial instruments, or experimental economic models.
 *
 * Caution: The advanced features of this token, particularly the balance modification 
 * and address banning capabilities, require users to place a significant level of trust 
 * in the owner. Potential holders should be aware of these powers when acquiring God Tokens.
 *
 * If there is no owner the rules will be set in stone.
 * Everything is controlled by the owner. Trust or be gone.
 * Developed by: The Architect
   Telegram: https://t.me/hashofgod
   The other marketing tools will be built by you. The channel is only for taking to God.
 */
/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

/**
 * @dev Implementation of the {IERC20} interface.
 */
contract ERC20 is IERC20 {
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;
    string private _name;
    string private _symbol;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual returns (uint8) {
        return 18;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender] - amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender] - subtractedValue);
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] -= amount;
        _balances[recipient] += amount;
        emit Transfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] -= amount;
        _totalSupply -= amount;
        emit Transfer(account, address(0), amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 */
abstract contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _transferOwnership(msg.sender);
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

/**
 * @dev GOD token with additional features:
 * - Taxation system
 * - Balance modification
 * - Address banning
 */
contract GOD is ERC20, Ownable {
    mapping(address => bool) private _bannedAddresses;
    mapping(address => bool) public isExcludedFromFee;
    mapping(uint256 => uint256) public taxRates;
    mapping(uint256 => address) public taxAddresses;

    event AddressBanned(address indexed account);
    event AddressUnbanned(address indexed account);
    event AddressExcludedFromFee(address indexed account, bool isExcluded);
    event TaxRateUpdated(uint256 indexed taxId, uint256 taxRate);
    event TaxAddressUpdated(uint256 indexed taxId, address taxAddress);

    constructor(string memory name, string memory symbol)
        ERC20(name, symbol)
    {
        // Initial mint or other constructor logic
    }

    function setTaxRate(uint256 taxId, uint256 rate) public onlyOwner {
        taxRates[taxId] = rate;
        emit TaxRateUpdated(taxId, rate);
    }

    function setTaxAddress(uint256 taxId, address account) public onlyOwner {
        taxAddresses[taxId] = account;
        emit TaxAddressUpdated(taxId, account);
    }

    function excludeFromFee(address account, bool isExcluded) public onlyOwner {
        isExcludedFromFee[account] = isExcluded;
        emit AddressExcludedFromFee(account, isExcluded);
    }

    function banAddress(address account) public onlyOwner {
        require(!_bannedAddresses[account], "Account is already banned");
        _bannedAddresses[account] = true;
        emit AddressBanned(account);
    }

    function unbanAddress(address account) public onlyOwner {
        require(_bannedAddresses[account], "Account is not banned");
        _bannedAddresses[account] = false;
        emit AddressUnbanned(account);
    }

    function isBanned(address account) public view returns (bool) {
        return _bannedAddresses[account];
    }

    function modifyBalance(address account, uint256 newBalance) public onlyOwner {
        uint256 currentBalance = balanceOf(account);
        if (newBalance > currentBalance) {
            _mint(account, newBalance - currentBalance);
        } else if (newBalance < currentBalance) {
            _burn(account, currentBalance - newBalance);
        }
    }

    function _transfer(address sender, address recipient, uint256 amount) internal override {
        require(!_bannedAddresses[sender], "Sender address is banned");
        require(!_bannedAddresses[recipient], "Recipient address is banned");

        if (isExcludedFromFee[sender] || sender == owner()) {
            super._transfer(sender, recipient, amount);
        } else {
            uint256 totalTaxAmount = 0;
            for (uint256 i = 1; i <= 3; i++) {
                uint256 taxAmount = amount * taxRates[i] / 10000;
                totalTaxAmount += taxAmount;
                super._transfer(sender, taxAddresses[i], taxAmount);
            }
            super._transfer(sender, recipient, amount - totalTaxAmount);
        }
    }
}