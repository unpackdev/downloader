// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "./MuteGovernance.sol";

contract Mute is MuteGovernance {
    using SafeMath for uint256;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    uint256 private _totalSupply;
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    uint16 public TAX_FRACTION;
    address public taxReceiveAddress;

    bool public isTaxEnabled;
    mapping(address => bool) public nonTaxedAddresses;

    address private _owner;
    mapping (address => bool) private _minters;

    uint256 public vaultThreshold;

    address public _dao;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    modifier onlyOwner() {
        require(msg.sender == _owner, "Mute::OnlyOwner: Not the owner");
        _;
    }

    modifier onlyMinter() {
        require(_minters[msg.sender] == true);
        _;
    }

    modifier onlyDAO() {
        require(_owner == msg.sender || _dao == msg.sender, "Mute::onlyDAO: caller is not the dao");
        _;
    }

    function initialize() public {
        require(_owner == address(0), "Mute::Initialize: Contract has already been initialized");
        _owner = msg.sender;
        _name = "Mute.io";
        _symbol = "MUTE";
        _decimals = 18;
        TAX_FRACTION = 100;
        vaultThreshold = 1000000 * 10 ** 18;
        nonTaxedAddresses[msg.sender] = true;
        taxReceiveAddress = msg.sender;
    }

    function changeOwner(address _newOwner) external onlyOwner {
        _owner = _newOwner;
    }

    function addMinter(address account) external onlyDAO {
        require(account != address(0));
        _minters[account] = true;
    }

    function removeMinter(address account) external onlyDAO {
        require(account != address(0));
        _minters[account] = false;
    }

    function setVaultThreshold(uint256 _vaultThreshold) external onlyDAO {
        vaultThreshold = _vaultThreshold;
    }

    function setTaxReceiveAddress(address _taxReceiveAddress) external onlyDAO {
        taxReceiveAddress = _taxReceiveAddress;
    }

    function setAddressTax(address _address, bool ignoreTax) external onlyDAO {
        nonTaxedAddresses[_address] = ignoreTax;
    }

    function setTaxFraction(uint16 _tax_fraction) external onlyDAO {
        TAX_FRACTION = _tax_fraction;
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function owner() public view returns (address) {
        return _owner;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function allowance(address owner_, address spender) public view returns (uint256) {
        return _allowances[owner_][spender];
    }

    function transfer(address recipient, uint256 amount) external returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount, "Mute: transfer amount exceeds allowance"));
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "Mute: transfer from the zero address");
        require(recipient != address(0), "Mute: transfer to the zero address");

        if(nonTaxedAddresses[sender] == true || TAX_FRACTION == 0){
          _balances[sender] = _balances[sender].sub(amount, "Mute: transfer amount exceeds balance");
          _balances[recipient] = _balances[recipient].add(amount);

          emit Transfer(sender, recipient, amount);
        } else {
          uint256 feeAmount = amount.mul(TAX_FRACTION).div(10000);
          uint256 newAmount = amount.sub(feeAmount);

          require(amount == feeAmount.add(newAmount), "Mute: math is broken");

          _balances[sender] = _balances[sender].sub(amount, "Mute: transfer amount exceeds balance");
          _balances[recipient] = _balances[recipient].add(newAmount);
          _balances[taxReceiveAddress] = _balances[taxReceiveAddress].add(feeAmount);

          emit Transfer(sender, recipient, newAmount);
          emit Transfer(sender, taxReceiveAddress, feeAmount);
        }
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].sub(subtractedValue, "Mute: decreased allowance below zero"));
        return true;
    }

    function _approve(address owner_, address spender, uint256 amount) internal {
        require(owner_ != address(0), "Mute: approve from the zero address");
        require(spender != address(0), "Mute: approve to the zero address");

        _allowances[owner_][spender] = amount;
        emit Approval(owner_, spender, amount);
    }

    function Burn(uint256 amount) external returns (bool) {
        require(msg.sender != address(0), "Mute: burn from the zero address");
        _balances[msg.sender] = _balances[msg.sender].sub(amount, "Mute: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(msg.sender, address(0), amount);
        return true;
    }

    function Mint(address account, uint256 amount) external onlyMinter returns (bool) {
        require(account != address(0), "Mute: mint to the zero address");
        _balances[account] = _balances[account].add(amount);
        _totalSupply = _totalSupply.add(amount);
        emit Transfer(address(0), account, amount);
        return true;
    }
}
