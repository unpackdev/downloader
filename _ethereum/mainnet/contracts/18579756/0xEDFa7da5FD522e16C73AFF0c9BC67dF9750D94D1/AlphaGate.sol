//SPDX-License-Identifier: MIT

/*

 -@#*+-:.                                    .:-=*#@=  
 @@@@@@@@@@%#**+==--:::.........:::--=++*#%@@@@@@@@@@. 
*@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@* 
.:=+*#%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%*+=:. 
        :@@@@@@@@@%@@@@@@@@@@@@@@@@@%%@@@@@@@@-        
  ======+@@@@@@@@#    +@@@@@@@@%+    *@@@@@@@@*========
  @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
  @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
  *****#@@@@@@@@@@*******************@@@@@@@@@@#*******
       -@@@@@@@@@%                   #@@@@@@@@@+       
       #@@@@@@@@@%                   #@@@@@@@@@%       
      .@@@@@@@@@@%                   #@@@@@@@@@@:      
      +@@@@@@@@@@%                   #@@@@@@@@@@*      
      @@@@@@@@@@@%                   #@@@@@@@@@@@      
     -@@@@@@@@@@@%                   #@@@@@@@@@@@=     
     #@@@@@@@@@@@%                   #@@@@@@@@@@@%     
    .@@@@@@@@@@@@%                   #@@@@@@@@@@@@:    
    +@@@@@@@@@@@@%                   #@@@@@@@@@@@@#    
    @@@@@@@@@@@@@%                   #@@@@@@@@@@@@@.   
   -@@@@@@@@@@@@@%                   #@@@@@@@@@@@@@+   
   #@@@@@@@@@@@@@%                   #@@@@@@@@@@@@@@   
  .@@@@@@@@@@@@@@%                   #@@@@@@@@@@@@@@-  
  +@@@@@@@@@@@@@@%                   #@@@@@@@@@@@@@@#  
   
 A telegram tool-suite providing low latency, high quality calls
 aggregated into one single feed designed to elevate your ETH trading experience.
 
 Features include, but are not limited to, auto-buy, call channels ranked,
 filtering & integrations with popular ETH snipers such as Maestro, BananaGun & Unibot.
 
 Bring your trading experience to the next level with AlphaGate

 * Bot: https://t.me/alphagateggbot
 * Website: https://alphagate.gg/
 * Twitter: https://twitter.com/alphagategg
 * Telegram: https://t.me/alphagategg
 * Community: https://t.me/alphagateportal
   
*/
 
pragma solidity 0.8.20;
 
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
 
    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}
 
abstract contract Ownable is Context {
    address private _owner;
 
    error OwnableUnauthorizedAccount(address account);
 
    error OwnableInvalidOwner(address owner);
 
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );
 
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
        if (owner() != _msgSender()) {
            revert OwnableUnauthorizedAccount(_msgSender());
        }
    }
 
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }
 
    function transferOwnership(address newOwner) public virtual onlyOwner {
        if (newOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(newOwner);
    }
 
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}
 
interface IERC20 {
    function totalSupply() external view returns (uint256);
 
    function balanceOf(address account) external view returns (uint256);
 
    function transfer(address to, uint256 value) external returns (bool);
 
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);
 
    function approve(address spender, uint256 value) external returns (bool);
 
    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);
 
    event Transfer(address indexed from, address indexed to, uint256 value);
 
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}
 
interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
 
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
 
    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}
 
interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);
 
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}
 
contract AlphaGate is IERC20, Ownable {

    event TradingStarted();

    bool public tradingOpen;
 
    address private constant DEAD_ADDRESS = address(0xdead);
    address public uniswapV2PairAddress;
    address payable public taxAddress;
    IUniswapV2Router02 immutable router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
 
    string private constant _name = "AlphaGate";
    string private constant _symbol = "AGATE";
 
    uint8 private constant _decimals = 9;
    uint256 private _totalSupply = 100_000_000 * (10**_decimals);
 
    uint256 private _swapCount = 0;
    uint256 private constant totalBuyTax = 4;
    uint256 private constant totalSellTax = 4;
    uint256 private constant initialMaxTxLimitPercent = 1;
    uint256 private constant preventSwapBefore = 15;
    uint256 private finalMaxTxLimitPercent = 15;
    uint256 private lowerLimitsAndTaxesAfter = 20;
    uint256 private swapThresholdPercent = 5; //0.5%
    bool private inSwap = false;
 
    mapping(address => bool) public isFeeExempt;
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
 
    modifier onlyTaxAddress() {
        require(msg.sender == taxAddress, "Not TaxAddress");
        _;
    }

    constructor(address _taxAddress) {
        require(_taxAddress != address(0), "ZeroAddress not allowed");
        taxAddress = payable(_taxAddress);
 
        isFeeExempt[msg.sender] = true;
        isFeeExempt[taxAddress] = true;
        isFeeExempt[address(this)] = true;
        isFeeExempt[address(0)] = true;
        isFeeExempt[DEAD_ADDRESS] = true;
 
        _balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    receive() external payable { }
 
    function setSwapThresholdPercent(uint256 _newSwapThresholdPercent) external onlyTaxAddress {
        swapThresholdPercent = _newSwapThresholdPercent;
    }

    function removeLimits() external onlyOwner {
        require(lowerLimitsAndTaxesAfter != 0, "Limits have already been removed");
        lowerLimitsAndTaxesAfter = 0;
    }

    function setTxLimit(uint256 _newMaxTxLimitPercent) external onlyOwner {
        require(_newMaxTxLimitPercent > 10 && _newMaxTxLimitPercent < 30, "Transaction limit must be higher than 10% and lower than 30%");
        finalMaxTxLimitPercent = _newMaxTxLimitPercent;
    }
 
    function setFeeExempt(address addressToExempt, bool isExempt) external onlyOwner {
        require(isFeeExempt[addressToExempt] != isExempt, "Value has to be different than the current value");
        isFeeExempt[addressToExempt] = isExempt;
    }
 
    function setUniswapV2Pair(address pairAddress) external onlyOwner {
        require(pairAddress != address(0), "ZeroAddress not allowed");
        require(!tradingOpen, "Trading is already open");
        uniswapV2PairAddress = pairAddress;
    }
 
    function startTrading() external onlyOwner {
        require(
            uniswapV2PairAddress != address(0),
            "uniswapV2PairAddress can't be ZeroAddress"
        );
        require(!tradingOpen, "Trading is already open");
        
        tradingOpen = true;
        emit TradingStarted();
    }
 
    function name() public view virtual returns (string memory) {
        return _name;
    }
 
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }
 
    function decimals() public view virtual returns (uint8) {
        return _decimals;
    }
 
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }
 
    function balanceOf(address account)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _balances[account];
    }
 
    function transfer(address recipient, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
 
    function allowance(address from, address to)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _allowances[from][to];
    }
 
    function approve(address to, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        _approve(_msgSender(), to, amount);
        return true;
    }
 
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
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
 
    function increaseAllowance(address to, uint256 addedValue)
        public
        virtual
        returns (bool)
    {
        _approve(_msgSender(), to, _allowances[_msgSender()][to] + addedValue);
        return true;
    }
 
    function decreaseAllowance(address to, uint256 subtractedValue)
        public
        virtual
        returns (bool)
    {
        uint256 currentAllowance = _allowances[_msgSender()][to];
        require(
            currentAllowance >= subtractedValue,
            "ERC20: decreased allowance below zero"
        );
        unchecked {
            _approve(_msgSender(), to, currentAllowance - subtractedValue);
        }
 
        return true;
    }
 
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(amount > 0, "ERC20: transfer amount zero");
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
 
        uint256 senderBalance = _balances[sender];
        require(
            senderBalance >= amount,
            "ERC20: transfer amount exceeds balance"
        );
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
 
        if(!tradingOpen) {
            require(isFeeExempt[sender] || isFeeExempt[recipient], "Trading is disabled");
        }

        uint256 taxTokens = 0;
        uint256 maxTxTokens = 0;

        uint256 taxSwapThreshold = (_totalSupply * swapThresholdPercent) / 1000;
 
        if(_balances[address(this)] >= taxSwapThreshold && !inSwap && recipient == uniswapV2PairAddress && !(isFeeExempt[sender] || isFeeExempt[recipient]) && _swapCount >= preventSwapBefore) {
            inSwap = true;
            uint256 swapBackAmount = taxSwapThreshold;
            swapTokensForEth(swapBackAmount);
 
            uint256 contractBalance = address(this).balance;

            if(contractBalance > 0) {
                _withdraw(contractBalance);
            }
            inSwap = false;
        }
 
        if (sender == uniswapV2PairAddress || recipient == uniswapV2PairAddress) {
            if (_swapCount < lowerLimitsAndTaxesAfter) {
                maxTxTokens = (_totalSupply * initialMaxTxLimitPercent) / 100;
            } else {
                maxTxTokens = (_totalSupply * finalMaxTxLimitPercent) / 100;
            }
            _swapCount++;
            taxTokens = _calculateTax(sender, recipient, amount);
        }
 
        if (taxTokens > 0) {
            amount -= taxTokens;
            _balances[address(this)] += taxTokens;
            emit Transfer(sender, address(this), taxTokens);
        }
 
        if (maxTxTokens > 0 && sender == uniswapV2PairAddress && recipient != address(router) && !(isFeeExempt[sender] || isFeeExempt[recipient])) {
            require(
                amount <= maxTxTokens,
                "Transaction exceeds transaction limit"
            );
        }
 
        _balances[recipient] += amount;
        emit Transfer(sender, recipient, amount);
    }
 
    function _calculateTax(
        address from,
        address to,
        uint256 amount
    ) internal view returns (uint256) {
        if (isFeeExempt[from] || isFeeExempt[to] || from == address(router) || to == address(router)) {
            return (0);
        }
 
        uint256 currentBuyTax = totalBuyTax;
        uint256 currentSellTax = totalSellTax;
 
        if (_swapCount < lowerLimitsAndTaxesAfter) {
            currentBuyTax = 30;
            currentSellTax = 30;
        }
 
        uint256 totalTaxTokens = 0;
 
        if (from == uniswapV2PairAddress) {
            totalTaxTokens = (amount * currentBuyTax) / 100;
        } else if (to == uniswapV2PairAddress) {
            totalTaxTokens = (amount * currentSellTax) / 100;
        }
 
        return (totalTaxTokens);
    }
 
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");
 
        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;
 
        emit Transfer(account, DEAD_ADDRESS, amount);
    }
 
    function burn(uint256 amount) external {
        _burn(_msgSender(), amount);
    }
 
    function swapTokensForEth(uint256 _tokenAmount) internal {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();
        _approve(address(this), address(router), _tokenAmount);
 
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            _tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }
 
    function _withdraw(uint256 _amount) internal {
        taxAddress.transfer(_amount);
    }
 
    function manualSwap(uint256 _tokenAmount) external onlyTaxAddress {
        swapTokensForEth(_tokenAmount);
        _withdraw(address(this).balance);
    }
 
    function _approve(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: approve from the zero address");
        require(to != address(0), "ERC20: approve to the zero address");
 
        _allowances[from][to] = amount;
        emit Approval(from, to, amount);
    }
}