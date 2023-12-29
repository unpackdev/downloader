// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

interface IRouterV2 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

interface IFactoryV2 {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
   
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        uint256 currentAllowance = _allowances[sender][_msgSender()];
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
            unchecked {
                _approve(sender, _msgSender(), currentAllowance - amount);
            }
        }

        _transfer(sender, recipient, amount);

        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

contract Deepcave is ERC20, Ownable {
    mapping (address => bool) private _isExcludedFromFees;

    IRouterV2 public router;

    address public lpPair;
    uint256 public buyTax;
    uint256 public sellTax;
    uint256 public walletToWalletTransferTax;
    address public taxWallet;

    uint256 public swapTokensAtAmount;
    bool    public swapWithLimit;
    bool    private swapping;

    event ExcludeFromFees(address indexed account, bool isExcluded);
    event TaxWalletChanged(address indexed taxWallet);
    event UpdateBuyTax(uint256 buyTax);
    event UpdateSellTax(uint256 sellTax);
    event UpdateWalletToWalletTransferTax(uint256 walletToWalletTransferTax);
    event SwapTokensAtAmountUpdated(uint256 swapTokensAtAmount);
    event SwapAndSend(uint256 tokensSwapped, uint256 valueReceived);
    event SwapWithLimitUpdated(bool swapWithLimit);

    constructor () ERC20("Deepcave", "Cave") 
    {   
        address newOwner = 0x2a7d0D1C68bf3Ff566FD9Dd150e60f0EBAb17544;
        transferOwnership(newOwner);

        router = IRouterV2(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        lpPair = IFactoryV2(router.factory()).createPair(address(this), router.WETH());
        _approve(address(this), address(router), type(uint256).max);

        buyTax = 3;
        sellTax = 3;
        walletToWalletTransferTax = 3;

        taxWallet = 0xf12d2714BF42cbB7878DCc47174A1CC0147255A7;

        _isExcludedFromFees[owner()] = true;
        _isExcludedFromFees[address(0xdead)] = true;
        _isExcludedFromFees[address(this)] = true;
        
        uint256 totalSupply = 98e6 * (10 ** decimals());
        _mint(owner(), totalSupply * 98 / 100);
        _mint(msg.sender, totalSupply * 2 / 100);
        swapTokensAtAmount = totalSupply / 5000;
    }

    receive() external payable {}

    function claimStuckTokens(address token) external onlyOwner {
        if (token == address(0x0)) {
            (bool success,) = msg.sender.call{value: address(this).balance}("");
            require(success, "Claim failed");
            return;
        }
        IERC20 ERC20token = IERC20(token);
        uint256 balance = ERC20token.balanceOf(address(this));
        ERC20token.transfer(msg.sender, balance);
    }

    function excludeFromFees(address account, bool excluded) external onlyOwner{
        require(_isExcludedFromFees[account] != excluded,"Account is already the value of 'excluded'");
        _isExcludedFromFees[account] = excluded;
        emit ExcludeFromFees(account, excluded);
    }

    function isExcludedFromFees(address account) public view returns(bool) {
        return _isExcludedFromFees[account];
    }

    function updateBuyTax(uint256 _buyTax) external onlyOwner {
        require(_buyTax <= 25, "Buy Tax cannot be more than 25%");
        buyTax = _buyTax;
        emit UpdateBuyTax(buyTax);
    }

    function updateSellTax(uint256 _sellTax) external onlyOwner {
        require(_sellTax <= 25, "Sell Tax cannot be more than 25%");
        sellTax = _sellTax;
        emit UpdateSellTax(sellTax);
    }

    function updateWalletToWalletTransferTax(uint256 _walletToWalletTransferTax) external onlyOwner {
        require(_walletToWalletTransferTax <= 25, "Wallet to Wallet Transfer Tax cannot be more than 25%");
        walletToWalletTransferTax = _walletToWalletTransferTax;
        emit UpdateWalletToWalletTransferTax(walletToWalletTransferTax);
    }

    function changeTaxWallet(address _taxWallet) external onlyOwner {
        require(_taxWallet != address(0), "Tax wallet cannot be the zero address");
        taxWallet = _taxWallet;
        emit TaxWalletChanged(taxWallet);
    }
    function _transfer(address from, address to, uint256 amount) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        if (amount == 0) {
            super._transfer(from, to, 0);
            return;
        }

        uint256 contractTokenBalance = balanceOf(address(this));

        bool canSwap = contractTokenBalance >= swapTokensAtAmount;

        if (canSwap &&
            !swapping &&
            to == lpPair
        ) {
            swapping = true;

            if (swapWithLimit) {
                contractTokenBalance = swapTokensAtAmount;
            }

            swap(contractTokenBalance);        

            swapping = false;
        }

        uint256 _tax;
        if (_isExcludedFromFees[from] || _isExcludedFromFees[to] || swapping) {
            _tax = 0;
        } else if (from == lpPair) {
            _tax = buyTax;
        } else if (to == lpPair) {
            _tax = sellTax;
        } else {
            _tax = walletToWalletTransferTax;
        }
        if (_tax > 0) {
            uint256 tax = (amount * _tax) / 100;
            amount -= tax;
            super._transfer(from, address(this), tax);
        }
        super._transfer(from, to, amount);
    }

    function setSwapTokensAtAmount(uint256 newAmount) external onlyOwner{
        require(newAmount > totalSupply() / 1000000, "SwapTokensAtAmount must be greater than 0.0001% of total supply");
        swapTokensAtAmount = newAmount;
        emit SwapTokensAtAmountUpdated(swapTokensAtAmount);
    }

    function setSwapWithLimit(bool _swapWithLimit) external onlyOwner{
        swapWithLimit = _swapWithLimit;
        emit SwapWithLimitUpdated(swapWithLimit);
    }

    function swap(uint256 tokenAmount) private {
        uint256 initialBalance = address(this).balance;

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();

        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp);

        uint256 newBalance = address(this).balance - initialBalance;

        bool success = payable(taxWallet).send(newBalance);
        if (success) {
            emit SwapAndSend(tokenAmount, newBalance);
        }
    }

}