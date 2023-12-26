// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/*
 /$$$$$$$$ /$$$$$$  /$$$$$$$  /$$$$$$$$ /$$    /$$ /$$$$$$$$ /$$$$$$$
| $$_____//$$__  $$| $$__  $$| $$_____/| $$   | $$| $$_____/| $$__  $$
| $$     | $$  \ $$| $$  \ $$| $$      | $$   | $$| $$      | $$  \ $$
| $$$$$  | $$  | $$| $$$$$$$/| $$$$$   |  $$ / $$/| $$$$$   | $$$$$$$/
| $$__/  | $$  | $$| $$__  $$| $$__/    \  $$ $$/ | $$__/   | $$__  $$
| $$     | $$  | $$| $$  \ $$| $$        \  $$$/  | $$      | $$  \ $$
| $$     |  $$$$$$/| $$  | $$| $$$$$$$$   \  $/   | $$$$$$$$| $$  | $$
|__/      \______/ |__/  |__/|________/    \_/    |________/|__/  |__/

         /$$
       /$$$$$$\ /$$$$$$$$ /$$$$$$$  /$$$$$$$$ /$$   /$$ /$$$$$$$
      /$$__  $$||_  $$__/| $$__  $$| $$_____/| $$$ | $$| $$__  $$
     | $$  \__/   | $$   | $$  \ $$| $$      | $$$$| $$| $$  \ $$
     |  $$$$$$    | $$   | $$$$$$$/| $$$$$   | $$ $$ $$| $$  | $$
      \____  $$   | $$   | $$__  $$| $$__/   | $$  $$$$| $$  | $$
      /$$  \ $$   | $$   | $$  \ $$| $$      | $$\  $$$| $$  | $$
     |  $$$$$$/   | $$   | $$  | $$| $$$$$$$$| $$ \  $$| $$$$$$$/
      \_  $$_/    |__/   |__/  |__/|________/|__/  \__/|_______/
        \__/

*/

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}

interface IRouter {
    function factory() external view returns (address);

    function WETH() external view returns (address);

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
    external
    payable
    returns (
        uint256 amountToken,
        uint256 amountETH,
        uint256 liquidity
    );

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

interface IFactory {
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint
    );

    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IWETH is IERC20 {
    function withdraw(uint256) external;
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
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

    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
    unchecked {
        _approve(owner, spender, currentAllowance - subtractedValue);
    }

        return true;
    }

    function _transfer(address from, address to, uint256 amount) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
    unchecked {
        _balances[from] = fromBalance - amount;
        _balances[to] += amount;
    }

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
    unchecked {
        _balances[account] += amount;
    }
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
        _totalSupply -= amount;
    }

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _spendAllowance(address owner, address spender, uint256 amount) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
        unchecked {
            _approve(owner, spender, currentAllowance - amount);
        }
        }
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {}

    function _afterTokenTransfer(address from, address to, uint256 amount) internal virtual {}
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _transferOwnership(_msgSender());
    }

    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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

contract TREND is ERC20, Ownable {

    modifier lockTheSwap() {
        processingFees = true;
        _;
        processingFees = false;
    }

    bool private processingFees = false;

    IRouter public router;
    address public automatedMarketMakerAddress;
    mapping(address => bool) public automatedMarketMakerPair;

    uint256 public buyFee;
    uint256 public sellFee;
    uint256 public liquidityShare;
    uint256 public trendingShare;
    uint256 public devShare;

    uint256 public maxWallet;
    uint256 public thresholdToProcessFees;

    address public trending;
    address public dev;
    address public lpWallet;

    mapping(address => bool) excludedAddresses;

    bool public tradingEnabled = false;

    event AMMSet(address indexed pairAddress, bool isAMM);
    event TradingEnabled();
    event NewTrendingWalletSet(address newTreasury);
    event NewDevWalletSet(address newDevWallet);
    event NewLpWalletSet(address newLpWallet);
    event ThresholdToProcessFeesSet(uint256 oldThreshold, uint256 newThreshold);
    event MaxWalletSet(uint256 oldMaxWallet, uint256 newMaxWallet);
    event FeeSet(uint256 buyFee, uint256 sellFee);
    event FeeSharesSet(
        uint256 newBurnAndLiquidityShare,
        uint256 newTreasuryShare,
        uint256 newOpsShare
    );
    event FeesProcessed();
    event ExcludedAddressSet(address indexed excludedAddress, bool isExcluded);

    constructor()
    ERC20("FOREVER", "TREND")
    {
        _mint(address(0xE0a029E3dC9510C3A7D82b233D86A8d8D13CA9ea), 2000000 * 1e18);
        _mint(address(0x34E0539890fD0DD7e8bA86025589d4206E191D5f), 2000000 * 1e18);
        _mint(address(0xfAF0e06693284097e6E1dD0e1628374639C3d566), 2000000 * 1e18);
        _mint(address(0xD52bC5C367413028E05941b8bb44C855C60DD5B1), 2000000 * 1e18);
        _mint(address(0x601bED778E1BC4Fd78bbfA86891d58FD137a7BF1), 2000000 * 1e18);
        _mint(address(0x7DCf73bC2f3Ca8eE105053A6e8CDF2F6e48e520e), 1000000 * 1e18);

        _mint(_msgSender(), 89000000 * 1e18);

        excludedAddresses[address(_msgSender())] = true;

        router = IRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        address _pair = IFactory(router.factory()).createPair(address(this), router.WETH());
        setAMM(address(_pair), true);

        trending = address(0xB024D12eB7B7D21F50BcbEa10922b5e139257c5C);
        dev = address(0x4BE77Df0A25827B83CE2a54593b708CFc386242d);

        excludedAddresses[address(router)] = true;
        excludedAddresses[address(trending)] = true;
        excludedAddresses[address(dev)] = true;

        buyFee = 40000;
        sellFee = 40000;
        liquidityShare = 20000;
        trendingShare = 40000;
        devShare = 40000;

        lpWallet = address(dev);

        maxWallet = 1000000 * 1e18;
        thresholdToProcessFees = 100000 * 1e18;
    }

    receive() external payable {}

    function setExcludedAddress(address excludedAddress, bool isExcluded) public onlyOwner {
        require(excludedAddress != address(0), "(New) excluded address can not be address 0x");
        excludedAddresses[excludedAddress] = isExcluded;
        emit ExcludedAddressSet(excludedAddress, isExcluded);
    }

    function setAMM(address ammAddress, bool isAMM) public onlyOwner {
        require(ammAddress != address(0), "(New) AMM address can not be address 0x");
        automatedMarketMakerPair[ammAddress] = isAMM;
        automatedMarketMakerAddress = ammAddress;
        emit AMMSet(ammAddress, isAMM);
    }

    function setThresholdToProcessFees(uint256 newThreshold) external onlyOwner {
        require(newThreshold >= 1000 * 1e18, "1000 is the minmum");
        uint256 _oldThreshold = thresholdToProcessFees;
        thresholdToProcessFees = newThreshold;
        emit ThresholdToProcessFeesSet(_oldThreshold, newThreshold);
    }

    function setMaxWallet(uint256 newMaxWallet) external onlyOwner {
        require(newMaxWallet >= 500000 * 1e18, "Max wallet is less the minimum then 0,5% of totalSupply");
        require(newMaxWallet <= 25000000 * 1e18, "Max wallet is more the maximum than 25% of totalSupply");

        uint256 _oldMaxWallet = maxWallet;
        maxWallet = newMaxWallet;
        emit MaxWalletSet(_oldMaxWallet, newMaxWallet);
    }

    function setFee(uint256 newBuyFee, uint256 newSellFee) external onlyOwner {
        require(newBuyFee >= 0, "Buy fee is less than 0");
        require(newSellFee >= 0, "Sell fee is less than 0");
        require(newBuyFee != buyFee, "Buy fee is already that percentage");
        require(newSellFee != sellFee, "Sell fee is already that percentage");

        buyFee = newBuyFee;
        sellFee = newSellFee;

        emit FeeSet(buyFee, sellFee);
    }

    function setFeeShares(uint256 newLiquidityShare, uint256 newTrendingShare, uint256 newDevShare) external onlyOwner {
        require(newLiquidityShare + newTrendingShare + newDevShare == 100000,
            "Summed fee shares are not 100% (100000)!"
        );

        liquidityShare = newLiquidityShare;
        trendingShare = newTrendingShare;
        devShare = newDevShare;

        emit FeeSharesSet(
            newLiquidityShare,
            newTrendingShare,
            newDevShare
        );
    }

    function setTrendingWallet(address newTrending) public onlyOwner {
        require(newTrending != address(0), "New treasury can not be address 0x");
        excludedAddresses[address(trending)] = false;
        trending = newTrending;
        excludedAddresses[address(newTrending)] = true;
        emit NewTrendingWalletSet(newTrending);
    }

    function setDevWallet(address newDevWallet) public onlyOwner {
        require(newDevWallet != address(0), "New operations wallet can not be address 0x");
        excludedAddresses[address(dev)] = false;
        dev = newDevWallet;
        excludedAddresses[address(newDevWallet)] = true;
        emit NewDevWalletSet(newDevWallet);
    }

    function setLpWallet(address newLpWallet) public onlyOwner {
        lpWallet = newLpWallet;
        emit NewLpWalletSet(newLpWallet);
    }

    function enableTrading() external onlyOwner {
        require(!tradingEnabled, "Trading is already enabled");
        tradingEnabled = true;
        emit TradingEnabled();
    }

    function _transfer(address from, address to, uint256 amount) internal override {
        require(tradingEnabled || from == owner(), "Trading will enable when AMM is set");

        if (excludedAddresses[from] || excludedAddresses[to]) {
            super._transfer(from, to, amount);
            return;
        }

        uint256 _transferAmount = amount;

        if (automatedMarketMakerPair[from] || automatedMarketMakerPair[to]) {
            uint256 _txnFee;

            if (automatedMarketMakerPair[from]) {
                _txnFee = (_transferAmount * buyFee) / 100000;
            }

            if (automatedMarketMakerPair[to]) {
                _txnFee = (_transferAmount * sellFee) / 100000;

                if (!processingFees && balanceOf(address(this)) >= thresholdToProcessFees) {
                    processFees();
                }
            }

            _transferAmount = _transferAmount - _txnFee;

            if (automatedMarketMakerPair[from]) {
                require(balanceOf(automatedMarketMakerPair[from] ? to : from) + _transferAmount <= maxWallet,
                    "transaction exceeds max wallet");
            }

            super._transfer(from, address(this), _txnFee);
        }

        if (automatedMarketMakerPair[to] && !processingFees
        && balanceOf(address(this)) >= thresholdToProcessFees
        ) {
            processFees();
        }

        super._transfer(from, to, _transferAmount);
    }

    function processFees() public lockTheSwap {
        uint256 _contractBalance = balanceOf(address(this));

        require(_contractBalance != 0, "Token balance cannot be 0");

        uint256 _liquidityTokens = 0;
        uint256 _swapAmount = _contractBalance;

        if (liquidityShare != 0) {
            _liquidityTokens = (_contractBalance * (liquidityShare / 2)) / 100000;
            _swapAmount = _contractBalance - _liquidityTokens;
        }

        _swapTokensForEth(_swapAmount);

        uint256 _balance = address(this).balance;

        require(_balance != 0, "ETH balance cannot be 0");

        if (liquidityShare != 0) {
            uint256 _ethForLiquidity = (_balance * (liquidityShare / 2)) / 100000;

            _addLiquidityETH(
                address(this),
                _liquidityTokens,
                _ethForLiquidity
            );
        }

        if (trendingShare != 0) {
            uint256 _ethForTrending = (_balance * trendingShare) / 100000;
            (bool trendingSendSuccess,) = trending.call{value : _ethForTrending}("");
            require(trendingSendSuccess, "Transfer to trending failed.");
        }

        if (devShare != 0) {
            uint256 _ethForDev = (_balance * devShare) / 100000;
            (bool devWalletSendSuccess,) = dev.call{value : _ethForDev}("");
            require(devWalletSendSuccess, "Transfer to dev failed.");
        }

        emit FeesProcessed();
    }

    function _swapTokensForEth(uint256 tokenAmount) internal {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();

        _approve(address(this), address(router), tokenAmount);
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function _addLiquidityETH(address token, uint256 tokenAmount, uint256 ethAmount) internal {
        IERC20(token).approve(address(router), tokenAmount);
        router.addLiquidityETH{value : ethAmount}(
            token,
            tokenAmount,
            0,
            0,
            address(lpWallet),
            block.timestamp
        );
    }

    function rescueWETH() external onlyOwner {
        address wethAddress = router.WETH();
        IWETH(wethAddress).withdraw(
            IERC20(wethAddress).balanceOf(address(this))
        );
    }

    function rescueETH() external onlyOwner {
        uint256 _balance = address(this).balance;
        require(_balance > 0, "No ETH to withdraw");

        (bool success,) = dev.call{value : _balance}("");
        require(success, "ETH transfer failed");
    }

    function rescueTokens(address tokenAddress) external onlyOwner {
        IERC20 tokenContract = IERC20(tokenAddress);
        tokenContract.transfer(address(dev), tokenContract.balanceOf(address(this)));
    }

}
