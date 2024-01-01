// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/*
  __  __     ____   _   _      _      _   _     ____  U _____ u
  \ \/"/  U /"___| |'| |'| U  /"\  u | \ |"| U /"___|u\| ___"|/
  /\  /\  \| | u  /| |_| |\ \/ _ \/ <|  \| |>\| |  _ / |  _|"
 U /  \ u  | |/__ U|  _  |u / ___ \ U| |\  |u | |_| |  | |___
  /_/\_\    \____| |_| |_| /_/   \_\ |_| \_|   \____|  |_____|
,-,>> \\_  _// \\  //   \\  \\    >> ||   \\,-._)(|_   <<   >>
 \_)  (__)(__)(__)(_") ("_)(__)  (__)(_")  (_/(__)__) (__) (__)
           ____      _      __  __  U _____ u ____
        U /"___|uU  /"\  uU|' \/ '|u\| ___"|// __"| u
        \| |  _ / \/ _ \/ \| |\/| |/ |  _|" <\___ \/
         | |_| |  / ___ \  | |  | |  | |___  u___) |
          \____| /_/   \_\ |_|  |_|  |_____| |____/>>
          _)(|_   \\    >><<,-,,-.   <<   >>  )(  (__)
         (__)__) (__)  (__)(./  \.) (__) (__)(__)

 Contract: X7G token
 Created by: https://t.me/smart_bart
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

contract X7G is ERC20, Ownable {
    modifier lockTheSwap() {
        processingFees = true;
        _;
        processingFees = false;
    }

    bool private processingFees = false;

    IRouter public router;
    address public automatedMarketMakerAddress;
    mapping(address => bool) public automatedMarketMakerPair;

    uint256 private _maxFee = 7000;
    uint256 public fee;
    uint256 public burnAndLiquidityShare;
    uint256 public treasuryShare;
    uint256 public operationsShare;

    uint256 public maxWallet;
    uint256 public thresholdToProcessFees;

    address public treasury;
    address public operations;
    address public x7rContract;

    mapping(address => bool) excludedAddresses;

    bool public tradingEnabled = false;

    event AMMSet(address indexed pairAddress, bool isAMM);
    event TradingEnabled();
    event NewTreasurySet(address newTreasury);
    event NewOperationsWalletSet(address newOperationsWallet);
    event ThresholdToProcessFeesSet(uint256 oldThreshold, uint256 newThreshold);
    event MaxWalletSet(uint256 oldMaxWallet, uint256 newMaxWallet);
    event FeeSet(uint256 oldFee, uint256 newFee);
    event FeeSharesSet(
        uint256 newBurnAndLiquidityShare,
        uint256 newTreasuryShare,
        uint256 newOpsShare
    );
    event FeesProcessed();
    event ExcludedAddressSet(address indexed excludedAddress, bool isExcluded);
    event Launched();

    constructor()
    ERC20("Xchange Games", "X7G")
    {
        _mint(_msgSender(), 100000000 * 1e18);

        excludedAddresses[address(_msgSender())] = true;
        excludedAddresses[address(0x740015c39da5D148fcA25A467399D00bcE10c001)] = true;
        x7rContract = address(0x70008F18Fc58928dcE982b0A69C2c21ff80Dca54);
    }

    receive() external payable {}

    function launch() public onlyOwner {
        // Create Xchange pair and set AMM in contract
        router = IRouter(0x7DE8063E9fB43321d2100e8Ddae5167F56A50060);
        address _pair = IFactory(router.factory()).createPair(address(this), router.WETH());
        setAMM(address(_pair), true);

        // Set wallet addresses
        treasury = address(0x47689fbAE45816Ea67c3C29BC46D2ff0961cb513);
        operations = address(0x87b49D6A6910547493f841A95b4Ed94d2A5942DD);

        // exclude router, lending pool, treasury and operations addresses
        excludedAddresses[address(router)] = true;
        excludedAddresses[address(treasury)] = true;
        excludedAddresses[address(operations)] = true;

        // set fee and fee shares
        fee = 3000;
        burnAndLiquidityShare = 33333;
        treasuryShare = 33333;
        operationsShare = 33334;

        // set maxWallet and thresholdToProcessFees
        maxWallet = 1000000 * 1e18;
        thresholdToProcessFees = 50000 * 1e18;

        emit Launched();
    }

    function setExcludedAddress(address excludedAddress, bool isExcluded) public onlyOwner {
        require(excludedAddress != address(0), "X7G: (New) excluded address can not be address 0x");
        excludedAddresses[excludedAddress] = isExcluded;
        emit ExcludedAddressSet(excludedAddress, isExcluded);
    }

    function setAMM(address ammAddress, bool isAMM) public onlyOwner {
        require(ammAddress != address(0), "X7G: (New) AMM address can not be address 0x");
        automatedMarketMakerPair[ammAddress] = isAMM;
        automatedMarketMakerAddress = ammAddress;
        emit AMMSet(ammAddress, isAMM);
    }

    function setThresholdToProcessFees(uint256 newThreshold) external onlyOwner {
        require(newThreshold >= 1000 * 1e18, "X7G: 1000 X7G is the minmum");
        uint256 _oldThreshold = thresholdToProcessFees;
        thresholdToProcessFees = newThreshold;
        emit ThresholdToProcessFeesSet(_oldThreshold, newThreshold);
    }

    function setMaxWallet(uint256 _newMaxWallet) external onlyOwner {
        require(_newMaxWallet >= 500000 * 1e18, "X7G: Max wallet is less the minimum then 0,5% of totalSupply");
        require(_newMaxWallet <= 25000000 * 1e18, "X7G: Max wallet is more the maximum than 25% of totalSupply");

        uint256 oldMaxWallet = maxWallet;
        maxWallet = _newMaxWallet;
        emit MaxWalletSet(oldMaxWallet, _newMaxWallet);
    }

    function setFee(uint256 newFee) external onlyOwner {
        require(newFee <= _maxFee, "X7G: Fee can not be set higher then the maximum of 7%");
        require(newFee >= 0, "X7G: Fee is less than 0");
        require(newFee != fee, "X7G: Fee is already that percentage");

        uint256 _oldFee = fee;
        fee = newFee;
        emit FeeSet(_oldFee, fee);
    }

    function setFeeShares(uint256 _newBurnAndLiquidityShare, uint256 _newTreasuryShare, uint256 _newOperationsShare) external onlyOwner {
        require(_newBurnAndLiquidityShare + _newTreasuryShare + _newOperationsShare == 100000,
            "X7G: Summed fee shares are not 100% (100000)!"
        );

        burnAndLiquidityShare = _newBurnAndLiquidityShare;
        treasuryShare = _newTreasuryShare;
        operationsShare = _newOperationsShare;

        emit FeeSharesSet(
            _newBurnAndLiquidityShare,
            _newTreasuryShare,
            _newOperationsShare
        );
    }

    function setTreasuryWallet(address _newTreasury) public onlyOwner {
        require(_newTreasury != address(0), "X7G: New treasury can not be address 0x");
        excludedAddresses[address(treasury)] = false;
        treasury = _newTreasury;
        excludedAddresses[address(_newTreasury)] = true;
        emit NewTreasurySet(_newTreasury);
    }

    function setOperationsWallet(address _newOperationsWallet) public onlyOwner {
        require(_newOperationsWallet != address(0), "X7G: New operations wallet can not be address 0x");
        excludedAddresses[address(treasury)] = false;
        operations = _newOperationsWallet;
        excludedAddresses[address(_newOperationsWallet)] = true;
        emit NewOperationsWalletSet(_newOperationsWallet);
    }

    function enableTrading() external onlyOwner {
        require(!tradingEnabled, "X7G: Trading is already enabled");
        tradingEnabled = true;
        emit TradingEnabled();
    }

    function _transfer(address from, address to, uint256 amount) internal override {
        require(tradingEnabled || from == owner(), "X7G: Trading will be enabled when the amm pair is set.");

        if (excludedAddresses[from] || excludedAddresses[to]) {
            super._transfer(from, to, amount);
            return;
        }

        uint256 _transferAmount = amount;

        if (automatedMarketMakerPair[from] || automatedMarketMakerPair[to]) {
            uint256 txnFee = (_transferAmount * fee) / 100000;

            _transferAmount = _transferAmount - txnFee;

            if (automatedMarketMakerPair[from]) {
                require(balanceOf(automatedMarketMakerPair[from] ? to : from) + _transferAmount <= maxWallet,
                    "X7G: transaction exceeds max wallet");
            }

            super._transfer(from, address(this), txnFee);
        }

        if (automatedMarketMakerPair[to] && !processingFees && balanceOf(address(this)) >= thresholdToProcessFees) {
            processFees();
        }

        super._transfer(from, to, _transferAmount);
    }

    function processFees() public lockTheSwap {
        uint256 _contractBalance = balanceOf(address(this));

        require(_contractBalance != 0, "X7G: cannot process fees if X7G balance is 0");

        // Calculate number of tokens
        uint256 _X7GLiquidityTokens = (_contractBalance * (((burnAndLiquidityShare / 2) / 2))) / 100000;

        // Swap for ETH
        _swapTokensForEth(_contractBalance - _X7GLiquidityTokens);

        // Calculate ETH balances
        uint256 _balance = address(this).balance;

        require(_balance != 0, "X7G: cannot process fees if ETH balance is 0");

        uint256 _ethForTreasury = (_balance * (treasuryShare / 4)) / 100000;
        uint256 _ethForOperations = (_balance * operationsShare) / 100000;
        uint256 _ethForX7GLiquidity = (_balance * (burnAndLiquidityShare / 2)) / 100000;
        uint256 _ethForX7RBurn = (_balance * (burnAndLiquidityShare / 2)) / 100000;
        uint256 _ethForX7RBuy = (_balance * (treasuryShare / 4) * 3) / 100000;

        // Add liquidity
        _addLiquidityETH(
            address(this),
            _X7GLiquidityTokens,
            _ethForX7GLiquidity
        );

        // Swap ETH for X7R and burn some and send some to the treasury
        _swapEthForTokens(
            _ethForX7RBurn + _ethForX7RBuy,
            address(x7rContract)
        );

        uint256 _x7rBalance = IERC20(x7rContract).balanceOf(address(this));
        uint256 _total = _ethForX7RBurn + _ethForX7RBuy;
        uint256 _burnRatio;
        uint256 _treasuryRatio;

        if (_total > 0) {
            _burnRatio = (_ethForX7RBurn * 1e18 / _total);
            _treasuryRatio = (_ethForX7RBuy * 1e18 / _total);
        }

        uint256 _x7rForBurn = (_x7rBalance * _burnRatio) / 1e18;
        uint256 _x7rForTreasury = (_x7rBalance * _treasuryRatio) / 1e18;

        IERC20(x7rContract).transfer(address(0x000000000000000000000000000000000000dEaD), _x7rForBurn);
        IERC20(x7rContract).transfer(address(treasury), _x7rForTreasury);

        // Send ETH to treasury, dev and marketing
        (bool treasurySendSuccess,) = treasury.call{value : _ethForTreasury}("");
        require(treasurySendSuccess, "X7G: Transfer to treasury wallet failed.");
        (bool operationsWalletSendSuccess,) = operations.call{value : _ethForOperations}("");
        require(operationsWalletSendSuccess, "X7G: Transfer to dev wallet failed.");

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

    function _swapEthForTokens(uint256 ethAmount, address tokenAddress) internal {
        address[] memory path = new address[](2);
        path[0] = router.WETH();
        path[1] = tokenAddress;
        router.swapExactETHForTokensSupportingFeeOnTransferTokens{value : ethAmount}(
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
            address(0),
            block.timestamp
        );
    }

    function rescueWETH() external {
        address _weth = router.WETH();
        IWETH(_weth).withdraw(
            IERC20(_weth).balanceOf(address(this))
        );
    }

    function rescueETH() external {
        uint256 _balance = address(this).balance;
        require(_balance > 0, "X7G: No ETH to withdraw");

        (bool success,) = msg.sender.call{value : _balance}("");
        require(success, "X7G: ETH transfer failed");
    }

}
