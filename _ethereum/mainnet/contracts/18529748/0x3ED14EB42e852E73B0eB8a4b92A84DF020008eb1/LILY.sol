//SPDX-License-Identifier: MIT

// File: contracts/interfaces/IERC20.sol

pragma solidity ^0.8.19;

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

    function isFeeExempt(address addr) external view returns (bool);

    function getTradingInfo(address trader) external view returns (uint256, uint256, uint256);

    function getTotalTradingInfo() external view returns (uint256, uint256, uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}
// File: contracts/interfaces/IERC20Metadata.sol

pragma solidity ^0.8.19;


interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}
// File: contracts/libraries/SafeMath.sol

pragma solidity ^0.8.19;

library SafeMath {
    function tryAdd(
        uint256 a,
        uint256 b
    ) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    function trySub(
        uint256 a,
        uint256 b
    ) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    function tryMul(
        uint256 a,
        uint256 b
    ) internal pure returns (bool, uint256) {
        unchecked {
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    function tryDiv(
        uint256 a,
        uint256 b
    ) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    function tryMod(
        uint256 a,
        uint256 b
    ) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}
// File: contracts/libraries/Context.sol

pragma solidity ^0.8.19;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}
// File: contracts/libraries/Ownable.sol

pragma solidity ^0.8.19;


abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _transferOwnership(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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

interface IUniswapV2Factory {
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint256
    );

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function getPair(
        address tokenA,
        address tokenB
    ) external view returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);

    function createPair(
        address tokenA,
        address tokenB
    ) external returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;
}

interface IUniswapV2Router02 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB, uint256 liquidity);

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
        returns (uint256 amountToken, uint256 amountETH, uint256 liquidity);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

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
// File: contracts/LILY.sol

pragma solidity ^0.8.19;

contract LILY is Context, IERC20Metadata, Ownable {
    using SafeMath for uint256;

    struct TradingInfo {
        uint256 boughtAmount;
        uint256 soldAmount;
        uint256 transferredAmount;
    }

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;
    string private constant _name = "Lily";
    string private constant _symbol = "$LILY";
    uint8 private constant _decimals = 18;
    uint256 private constant _hardCap = 420_000_000_000 * (10 ** _decimals);

    address payable _liquidityWallet;
    address payable _rewardWallet;
    address payable _companyWallet;

    uint256 _buyTax = 15;
    uint256 _sellTax = 20;
    uint256 _normalTax = 5;

    uint256 _liquidityWalletTaxAllocation = 45;
    uint256 _rewardWalletTaxAllocation = 40;
    uint256 _companyWalletTaxAllocation = 15;

    uint256 _initialMintRatio = 25;
    uint256 _maxHalvings = 120;
    uint256 _halvingReduction = 25;
    uint256 _mintRate = 3000;
    uint256 _mintDenom = 100000;
    uint256 _halvingCount = 1;
    uint256 _maxHoldingAmount = _hardCap.div(400);
    uint256 _maxTxAmount = _hardCap.div(800);

    uint256 _totalBoughtAmount = 0;
    uint256 _totalSoldAmount = 0;
    uint256 _totalTransferredAmount = 0;

    IUniswapV2Router02 _uniswapRouter;
    address _uniswapPair;
    bool _tradingOpen = false;
    bool _limited = true;

    mapping(address => TradingInfo) _tradingInfo;
    mapping(address => bool) _isFeeExempt;
    mapping(address => bool) _automatedMarketMakerPairs;

    event OpenTrading(bool flag, uint256 timeStamp);
    event HalvingMint(address to, uint256 amount, uint256 halvingCount);
    event SetAutomatedMarketMakerPairs(address ammPair, bool flag);
    event SetLimitation(bool limit, uint256 maxTxAmount, uint256 maxHoldingAmount);
    event SetFeeExempt(address indexed addr, bool value);
    event SetTax(uint256 buyTax, uint256 sellTax, uint256 normalTax);
    event SetTaxWallet(address liquidityWallet, address rewardWallet, address companyWallet);
    event SetTaxAllocation(uint256 liquidityWalletTaxAllocation, uint256 rewardWalletTaxAllocation, uint256 companyWalletTaxAllocation);
    event SetMaxHalving(uint256 maxHalving);
    event SetHalvingReduction(uint256 halvingReduction);

    constructor() {
        _uniswapRouter = IUniswapV2Router02(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        );
        _uniswapPair = IUniswapV2Factory(_uniswapRouter.factory())
            .createPair(address(this), _uniswapRouter.WETH());
        _mint(msg.sender, _hardCap.mul(_initialMintRatio).div(100));
        _automatedMarketMakerPairs[_uniswapPair] = true;
        _isFeeExempt[msg.sender] = true;
        _isFeeExempt[address(this)] = true;
    }

    function name() public pure override returns (string memory) {
        return _name;
    }

    function symbol() public pure override returns (string memory) {
        return _symbol;
    }

    function decimals() public pure override returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address from, address to) public view override returns (uint256) {
        return _allowances[from][to];
    }

    function approve(address to, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), to, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(
            currentAllowance >= amount,
            "ERC20: transfer amount exceeds allowance"
        );
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    function _approve(address from, address to, uint256 amount) private {
        require(from != address(0), "ERC20: approve from the zero address");
        require(to != address(0), "ERC20: approve to the zero address");

        _allowances[from][to] = amount;
        emit Approval(from, to, amount);
    }

    function _transfer(address from, address to, uint256 amount) private {
        require(amount > 0, "ERC20: transfer amount zero");
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        
        bool excludedAccount = _isFeeExempt[from] || _isFeeExempt[to];
        require(_tradingOpen || excludedAccount, "LILYLOG:: Trading is not allowed");

        if (!_automatedMarketMakerPairs[to] && !excludedAccount && _limited) {
            require(amount <= _maxTxAmount, "LILYLOG:: Insufficient tx amount");
            require(_balances[to] + amount <= _maxHoldingAmount, "LILYLOG:: Insufficient trading amount");
        }

        uint256 taxAmount = 0;
        uint256 sendAmount;

        if (shouldTakeFee(from, to)) {
            taxAmount = calculateTax(from, to, amount);
        }

        sendAmount = amount.sub(taxAmount);
        _balances[from] = _balances[from].sub(amount);
        _balances[to] = _balances[to].add(sendAmount);
        emit Transfer(from, to, sendAmount);

        if (taxAmount > 0) {
            _balances[_liquidityWallet] = _balances[_liquidityWallet].add(taxAmount.mul(_liquidityWalletTaxAllocation).div(100));
            _balances[_rewardWallet] = _balances[_rewardWallet].add(taxAmount.mul(_rewardWalletTaxAllocation).div(100));
            _balances[_companyWallet] = _balances[_companyWallet].add(taxAmount.mul(_companyWalletTaxAllocation).div(100));
            emit Transfer(from, _liquidityWallet, taxAmount.mul(_liquidityWalletTaxAllocation).div(100));
            emit Transfer(from, _rewardWallet, taxAmount.mul(_rewardWalletTaxAllocation).div(100));
            emit Transfer(from, _companyWallet, taxAmount.mul(_companyWalletTaxAllocation).div(100));
        }

        if (_automatedMarketMakerPairs[from] && !_automatedMarketMakerPairs[to]) {
            _tradingInfo[to].boughtAmount += amount;
            _totalBoughtAmount += amount;
        } else if (!_automatedMarketMakerPairs[from] && _automatedMarketMakerPairs[to]) {
            _tradingInfo[from].soldAmount += amount;
            _totalSoldAmount += amount;
        } else {
            _tradingInfo[from].transferredAmount += amount;
            _totalTransferredAmount += amount;
        }
    }

    function _mint(address account, uint256 amount) private {
        require(account != address(0), "LILYLOG:: Mint to the zero address");
        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    function mint(address account, uint256 amount) external onlyOwner {
        _mint(account, amount);
    }

    function halvingMint() external onlyOwner() {
        uint256 mintAmount = _hardCap.mul(_mintRate).div(_mintDenom);
        if (_mintRate < 1)
            return;
        _mint(_liquidityWallet, mintAmount.mul(_liquidityWalletTaxAllocation).div(100));
        _mint(_rewardWallet, mintAmount.mul(_rewardWalletTaxAllocation).div(100));
        _mint(_companyWallet, mintAmount.mul(_companyWalletTaxAllocation).div(100));
        if (_halvingCount < _maxHalvings) {
            _mintRate = _mintRate.sub(_halvingReduction.mul(_halvingCount));
            _halvingCount++;
        }        
    }

    function shouldTakeFee(address from, address to) private view returns (bool) {
        if (_isFeeExempt[from] || _isFeeExempt[to]) {
            return false;
        } else {
            return true;
        }
    }

    function calculateTax(address from, address to, uint amount) private view returns (uint256) {
        uint256 taxAmount = 0;
        if (_automatedMarketMakerPairs[from]) {
            taxAmount = amount.mul(_buyTax).div(1000);
        } else if (_automatedMarketMakerPairs[to]) {
            taxAmount = amount.mul(_sellTax).div(1000);
        } else if (!_automatedMarketMakerPairs[from] && !_automatedMarketMakerPairs[to]) {
            taxAmount = amount.mul(_normalTax).div(1000);
        }
        return taxAmount;
    }

    function setFeeExempt(address[] calldata addressLists, bool value) external onlyOwner {
        uint256 length = addressLists.length;
        for (uint256 i = 0; i < length; i ++) {
            _isFeeExempt[addressLists[i]] = value;
            emit SetFeeExempt(addressLists[i], value);
        }
    }

    function openTrading() external onlyOwner {
        _tradingOpen = true;
        emit OpenTrading(_tradingOpen, block.timestamp);
    }

    function setAutomatedMarketMakerPairs(address ammPair, bool flag) external onlyOwner {
        _automatedMarketMakerPairs[ammPair] = flag;
        emit SetAutomatedMarketMakerPairs(ammPair, flag);
    }

    function setLimitation(bool limited, uint256 maxTxAmount, uint256 maxHoldingAmount) external onlyOwner {
        _limited = limited;
        _maxTxAmount = maxTxAmount;
        _maxHoldingAmount = maxHoldingAmount;
        emit SetLimitation(limited, maxTxAmount, maxHoldingAmount);
    }

    function setTax(uint256 buyTax, uint256 sellTax, uint256 normalTax) external onlyOwner {
        require(buyTax > 0, "LILYLOG:: Buy tax must be higher than zero");
        require(sellTax > 0, "LILYLOG:: Sell tax must be higher than zero");
        require(normalTax > 0, "LILYLOG:: Normal tax must be higher than zero");
        _buyTax = buyTax;
        _sellTax = sellTax;
        _normalTax = normalTax;
        emit SetTax(buyTax, sellTax, normalTax);
    }

    function setTaxAllocation(uint256 liquidityWalletTaxAllocation, uint256 rewardWalletTaxAllocation, uint256 companyWalletTaxAllocation) external onlyOwner {
        require(liquidityWalletTaxAllocation + rewardWalletTaxAllocation + companyWalletTaxAllocation == 100, "LILYLOG:: Tax allocation is not correct");
        _liquidityWalletTaxAllocation = liquidityWalletTaxAllocation;
        _rewardWalletTaxAllocation = rewardWalletTaxAllocation;
        _companyWalletTaxAllocation = companyWalletTaxAllocation;
        emit SetTaxAllocation(liquidityWalletTaxAllocation, rewardWalletTaxAllocation, companyWalletTaxAllocation);
    }

    function setTaxWallet(address liquidityWallet, address rewardWallet, address companyWallet) external onlyOwner {
        _liquidityWallet = payable(liquidityWallet);
        _rewardWallet = payable(rewardWallet);
        _companyWallet = payable(companyWallet);
        _isFeeExempt[_liquidityWallet] = true;
        _isFeeExempt[_rewardWallet] = true;
        _isFeeExempt[_companyWallet] = true;
        emit SetTaxWallet(liquidityWallet, rewardWallet, companyWallet);
    }

    function setMaxHalving(uint256 maxHalvings) external onlyOwner {
        require(maxHalvings > _maxHalvings, "LILYLOG:: Max halving must be higher than the prior value");
        _maxHalvings = maxHalvings;
        emit SetMaxHalving(maxHalvings);
    }

    function setHalvingReduction(uint256 halvingReduction) external onlyOwner {
        require(halvingReduction > 0, "LILYLOG:: Halving reduction must be higher than zero");
        require(halvingReduction < 100, "LILYLOG:: Halving reduction must be lower than 100");
        _halvingReduction = halvingReduction;
        emit SetHalvingReduction(halvingReduction);
    }

    function isFeeExempt(address addr) external view returns (bool) {
        return _isFeeExempt[addr];
    }

    function getTradingInfo(address trader) external view returns (uint256, uint256, uint256) {
        return (_tradingInfo[trader].boughtAmount, _tradingInfo[trader].soldAmount, _tradingInfo[trader].transferredAmount);
    }

    function getTotalTradingInfo() external view returns (uint256, uint256, uint256) {
        return (_totalBoughtAmount, _totalSoldAmount, _totalTransferredAmount);
    }

    receive() payable external {}
    
    fallback() payable external {}
}