// SPDX-License-Identifier: MIT 

pragma solidity 0.8.9;

import "./Context.sol";
import "./SafeMath.sol";
import "./Ownable.sol";
import "./IERC20.sol";

contract OwlToken is Context, IERC20, Ownable {
    using SafeMath for uint256;
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _isExcludedFromFee;
    mapping (address => bool) private _isExcludedFromMaxWalletSize;
    address payable private _taxWallet;

    // 1% transfer tax
    uint256 private constant TRANSFER_TAX = 1;
    // 50% of tax is burned
    uint256 private constant BURN_FEE = 50;
    // max 2% of total supply per wallet
    uint256 private constant MAX_WALLET_SIZE_RATE = 2;

    uint8 private constant DECIMALS = 18;
    string private constant NAME = unicode"Owlracle";
    string private constant SYMBOL = unicode"OWL";

    // 1M total supply
    uint256 private _totalSupply = 10**6 * 10**DECIMALS;
    uint256 private _burnedTokens = 0;
    uint256 private _maxWalletSize;
    bool private _isTransfersRestricted = true;

    constructor () {
        _taxWallet = payable(_msgSender());
        _balances[_msgSender()] = _totalSupply;
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[_taxWallet] = true;

        // maxWalletSize is restricted to 2% of total supply at first
        _maxWalletSize = _totalSupply.mul(MAX_WALLET_SIZE_RATE).div(100);

        emit Transfer(address(0), _msgSender(), _totalSupply);
    }

    function name() external pure returns (string memory) {
        return NAME;
    }

    function symbol() external pure returns (string memory) {
        return SYMBOL;
    }

    function decimals() external pure returns (uint8) {
        return DECIMALS;
    }

    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address ownerAddress, address spender) external view override returns (uint256) {
        return _allowances[ownerAddress][spender];
    }

    function approve(address spender, uint256 amount) external override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function burnedTokens() external view returns (uint256) {
        return _burnedTokens;
    }

    function taxWallet() external view returns (address) {
        return _taxWallet;
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function excludeFromFee(address account) external onlyOwner {
        _isExcludedFromFee[account] = true;
    }

    // this needs to be called for the liquidity pool
    function excludeFromMaxWalletSize(address account) external onlyOwner {
        _isExcludedFromMaxWalletSize[account] = true;
    }

    // only the owner or the current tax wallet can call this
    function setTaxWallet(address payable account) external {
        require(_msgSender() == owner() || _msgSender() == _taxWallet, "OwlToken: Not owner or tax wallet");
        require(account != address(0), "OwlToken: Zero address");
        
        _isExcludedFromFee[_taxWallet] = false;
        _taxWallet = account;
        _isExcludedFromFee[_taxWallet] = true;
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(_msgSender()).transfer(balance);
    }

    function removeRestrictions() external onlyOwner {
        require(_isTransfersRestricted, "OwlToken: Transfers are already unrestricted");
        _isTransfersRestricted = false;
        _maxWalletSize = _totalSupply;
    }

    function _approve(address ownerAddress, address spender, uint256 amount) private {
        require(ownerAddress != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[ownerAddress][spender] = amount;
        emit Approval(ownerAddress, spender, amount);
    }

    function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(balanceOf(from) >= amount, "OwlToken: Insufficient balance");
        
        uint256 feeAmount=0;
        if (!_isExcludedFromFee[from] && !_isExcludedFromFee[to]) {
            // calculate tax amount
            feeAmount = amount.mul(TRANSFER_TAX).div(100);

            // a single wallet cannot hold more than _maxWalletSize
            if (_isTransfersRestricted && !_isExcludedFromMaxWalletSize[to]) {
                require(balanceOf(to) + amount <= _maxWalletSize, "OwlToken: Exceeds the maxWalletSize");
            }
        }

        if(feeAmount > 0){
            _payFee(feeAmount);
        }

        _balances[from]=_balances[from].sub(amount);
        _balances[to]=_balances[to].add(amount.sub(feeAmount));
        emit Transfer(from, to, amount.sub(feeAmount));
    }

    function _payFee(uint256 amount) private {
        // burn designated amount
        uint256 burnAmount = amount.mul(BURN_FEE).div(100);
        _totalSupply = _totalSupply.sub(burnAmount);
        _burnedTokens = _burnedTokens.add(burnAmount);

        // send the rest to tax wallet
        _balances[_taxWallet] = _balances[_taxWallet].add(amount.sub(burnAmount));
        emit Transfer(_msgSender(), _taxWallet, amount.sub(burnAmount));
    }

    receive() external payable {}
}