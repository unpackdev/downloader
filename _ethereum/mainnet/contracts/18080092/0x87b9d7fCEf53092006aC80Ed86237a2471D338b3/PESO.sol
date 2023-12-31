// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

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

library SafeMath {
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }
    
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
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

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

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

contract ERC20 is Context, IERC20Metadata {
    mapping(address => uint256) internal _balances;

    mapping(address => mapping(address => uint256)) internal _allowances;

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

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(address indexed sender, uint amount0In, uint amount1In, uint amount0Out, uint amount1Out, address indexed to);
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
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

contract PESO is Ownable, ERC20 {
    using SafeMath for uint256;

    uint256 public swapTokensAtAmount;
    uint256 public swapableTokens;

    uint256 public maxWalletLimit;
    uint256 public maxTxLimit;
    uint256 public maxTxLimitForAirDrop;
    address private constant DEAD = 0x000000000000000000000000000000000000dEaD;

    uint256 public sellFee;
    uint256 public buyFee;
    uint256 private encroachmentFee;

    address payable public developmentWallet;
    address payable public marketingWallet;
    address payable public controlledBurnWallet;

    bool    public tradingActive;
    uint256 public tradingActiveBlock;

    IUniswapV2Router02 public dexRouter;
    address public lpPair;

    mapping(address => bool) public lpPairs;
    mapping(address => bool) public isExcludedFromFee;
    mapping(address => bool) public airDropAddresses;

    mapping(address => bool) public isGuiltyOfEncroachment;

    constructor(string memory name_, string memory symbol_) ERC20(name_, symbol_) {
        uint256 tSupply        =  100_000_000 * 10 ** 18;
        uint256 contractToken  = (tSupply.mul(90)).div(100); //90% of total supply
        uint256 marketingToken = (tSupply.mul(5)).div(100); //5% of total supply
        uint256 deployerToken  = (tSupply.mul(5)).div(100); //5% of total supply

        developmentWallet    = payable(0x8f438103F71700025310FB1B35d4D5cd3C49E081);
        marketingWallet      = payable(0xCD4AD8dCC0f32F53D348AfA6d53C7b003647bd17);
        controlledBurnWallet = payable(0xB2645E19361336A31390308c1A79a94C759CC877);  

        _mint(_msgSender(), deployerToken);
        _mint(address(this), contractToken);
        _mint(marketingWallet, marketingToken);
        
        maxWalletLimit = (totalSupply().mul(2)).div(100); //2% of the total supply
        maxTxLimit     = (totalSupply().mul(2)).div(100); //2% of the total supply
        maxTxLimitForAirDrop = (totalSupply().mul(2)).div(1000); //1% of the total supply

        swapTokensAtAmount = (totalSupply().mul(2)).div(1000); //0.2% of the total supply

        buyFee  = 15;
        sellFee = 15;
        encroachmentFee = 30;

        dexRouter = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        lpPair    = IUniswapV2Factory(dexRouter.factory()).createPair(address(this), dexRouter.WETH());
        lpPairs[lpPair] = true;

        isExcludedFromFee[owner()] = true;
        isExcludedFromFee[address(this)] = true;
    }

    receive() external payable {}

    function _transfer(address from, address to, uint256 amount) internal override {
        require(from != DEAD, "PESO: transfer from the dead address");
        require(to   != DEAD, "PESO: transfer from the dead address");
        require(from != address(0), "PESO: Null address");
        require(to   != address(0), "PESO: Null address");
        require(_balances[from] >= 0, "PESO: Transfer amount is low");

        if(airDropAddresses[from]) {
            require(amount <= maxTxLimitForAirDrop, "PESO: Max Tx limit reached");
        }

        if (from == owner() || from == address(this) && lpPairs[to]) {
            _transferBothExcluded(from, to, amount);
        }

        else if(lpPairs[from] || lpPairs[to]) {
            require(tradingActive == true, "PESO: Trading is not active yet");

            if (lpPairs[from]){//buy
                if (_checkMaxWalletLimit(to, amount) && _checkMaxTxLimit(amount)) {
                    if(block.number < tradingActiveBlock + 3) {
                        isGuiltyOfEncroachment[to] = true;
                    } 
                    if(isExcludedFromFee[to]){
                        _transferBothExcluded(from, to, amount);
                    } else {
                        _transferFromExcluded(from, to, amount);
                    }
                } 
            }
            else if (lpPairs[to]){//sell
                if(swapableTokens >= swapTokensAtAmount) {
                    _swapTokenForEth(swapableTokens);
                    swapableTokens = 0;
                }

                if (_checkMaxTxLimit(amount)) {
                    if(isExcludedFromFee[from]) {
                        _transferBothExcluded(from, to, amount);
                    } else {
                        _transferToExcluded(from, to, amount);
                    }
                }
            }
        }

        else {
            if (from == owner() || to == owner() || from == address(this) || to == address(this)) {
                _transferBothExcluded(from, to, amount);
            } else if(_checkMaxWalletLimit(to, amount) && _checkMaxTxLimit(amount)){
                _transferBothExcluded(from, to, amount);
            }
        }
    }

    function _transferFromExcluded(address from, address to, uint256 amount) private { //Buy Function
        (uint256 totalBuy,,) = calculateFee(amount);
        uint256 amountToSend = amount.sub(totalBuy);

        if(isGuiltyOfEncroachment[to]) {
            _encroachmentTransfer(from, to, amount);
        } else {
            super._transfer(from, to, amountToSend);
            super._transfer(from, address(this), totalBuy);

            swapableTokens = swapableTokens.add(totalBuy);
        }
    }

    function _transferToExcluded(address from, address to, uint256 amount) private { //Sell Function
        (,uint256 totalSell,) = calculateFee(amount);
        uint256 amountToRecieve = amount.sub(totalSell);

        if(isGuiltyOfEncroachment[from]) {
            _encroachmentTransfer(from, to, amount);
        } else {
            super._transfer(from, to, amountToRecieve);
            super._transfer(from, address(this), totalSell);

            swapableTokens = swapableTokens.add(totalSell);
        }
    }

    function _transferBothExcluded(address from, address to, uint256 amount) private {
        if(isGuiltyOfEncroachment[from]){
            _encroachmentTransfer(from, to, amount);
        } else {
            super._transfer(from, to, amount);
        }
    }

    function _encroachmentTransfer(address from, address to, uint256 amount) private {
        (,,uint256 encroachFee) = calculateFee(amount);
        uint256 sentAmount = amount.sub(encroachFee);

        super._transfer(from, to, sentAmount);
        super._transfer(from, address(this), encroachFee);

        swapableTokens = swapableTokens.add(encroachFee);
    }

    function burn(uint256 amount) public returns (bool) {
        _burn(_msgSender(), amount);
        return true;
    }

    function airDrop(address[] memory receivers, uint256[] memory amounts) external onlyOwner returns (bool) {
        require(receivers.length == amounts.length, "ERC20: Invalid arguments");
        for(uint i = 0; i < receivers.length; i++) {
            super._transfer(_msgSender(), receivers[i], amounts[i]);
            airDropAddresses[receivers[i]] = true;
        }
        return true;
    }

    ///@notice PESO Functions
    function setSwapTokensAtAmount(uint256 amount) public onlyOwner returns (bool) {
        require(amount != swapTokensAtAmount, "PESO: Given amount is already equal to already set amount");
        swapTokensAtAmount = amount;
        return true;
    }

    function setMaxWalletLimit(uint256 amount) public onlyOwner returns (bool) {
        require(amount != maxWalletLimit, "PESO: Given amount is already equal to already set amount");
        maxWalletLimit = amount;
        return true;
    }

    function setMaxTxLimit(uint256 amount) public onlyOwner returns (bool) {
        require(amount != maxTxLimit, "PESO: Given amount is already equal to already set amount");
        maxTxLimit = amount;
        return true;
    }

    function setMaxTxForAirdropLimit(uint256 amount) public onlyOwner returns (bool) {
        require(amount != maxTxLimitForAirDrop, "PESO: Given amount is already equal to already set amount");
        maxTxLimitForAirDrop = amount;
        return true;
    }

    function setSellFee(uint256 _sellFee) public onlyOwner returns (bool) {
        require(_sellFee <= 15, "PESO: Sell fee cant be more then 15%");
        sellFee = _sellFee;
        return true;
    }

    function setBuyFee(uint256 _buyFee) public onlyOwner returns (bool) {
        require(_buyFee <= 15, "PESO: Buy fee cant be more then 15%");
        buyFee = _buyFee;
        return true;
    }

    function setEncroachmentFee(uint256 _fee) public onlyOwner returns (bool) {
        encroachmentFee = _fee;
        return true;
    }

    /// @notice Remove wallet and TX limits and set taxes
    function liftLimits() public onlyOwner returns (bool) {
        sellFee = 15;
        buyFee  = 5;

        maxWalletLimit = totalSupply();
        maxTxLimit     = totalSupply();

        return true;
    }

    function setDevelopmentWallet(address payable account) public onlyOwner returns (bool) {
        require(account != developmentWallet, "PESO: Account can't be the previously set address");
        developmentWallet = account;
        return true;
    }

    function setMarketingWallet(address payable account) public onlyOwner returns (bool) {
        require(account != marketingWallet, "PESO: Account can't be the previously set address");
        marketingWallet = account;
        return true;
    }

    function setControlledBurnWallet(address payable account) public onlyOwner returns (bool) {
        require(account != controlledBurnWallet, "PESO: Account can't be the previously set address");
        controlledBurnWallet = account;
        return true;
    }

    function addLpPair(address pairAddress) public onlyOwner returns (bool) {
        require(!lpPairs[pairAddress], "PESO: Lp Pair address already exist");
        lpPairs[pairAddress] = true;
        isExcludedFromFee[pairAddress] = true; 
        return true;
    }

    function excludeFromFee(address account) public onlyOwner returns (bool) {
        require(!isExcludedFromFee[account], "PESO: Address is already excluded from fee");
        isExcludedFromFee[account] = true;
        return true;
    }

    function excludeFromFeeInBulk(address[] memory accounts) public onlyOwner returns (bool) {
        for(uint i = 0; i < accounts.length; i++) {
            isExcludedFromFee[accounts[i]] = true;
        }
        return true;
    }

    function includeInFee(address account) public onlyOwner returns (bool) {
        require(isExcludedFromFee[account], "PESO: Address is already included in fee");
        isExcludedFromFee[account] = false;
        return true;
    }

    function enableTrading() public onlyOwner returns (bool) {
        require(!tradingActive, "PESO: Trading is already Active");
        tradingActive = true;
        tradingActiveBlock = block.number;
        return true;
    }

    function unflagEncroachment(address account) public onlyOwner returns (bool) {
        require(isGuiltyOfEncroachment[account], "PESO: Account is not Guilty");
        isGuiltyOfEncroachment[account] = false;
        return true;
    }

    function recoverAllEth(address to) public onlyOwner returns (bool) {
        payable(to).transfer(address(this).balance);
        return true;
    }

    function recoverAllPESO() public onlyOwner returns (bool) {
        transfer(owner(), balanceOf(address(this)));
        swapableTokens = 0; 
        return true;
    }

    ///@notice view functions
    function _checkMaxWalletLimit(address recipient, uint256 amount) private view returns (bool) {
        require(maxWalletLimit >= balanceOf(recipient).add(amount), "ERC20: Wallet limit exceeds");
        return true;
    }

    function _checkMaxTxLimit(uint256 amount) private view returns (bool) {
        require(amount <= maxTxLimit, "ERC20: Transaction limit exceeds");
        return true;
    }

    function calculateFee(uint256 amount) private view returns (uint256 _totalBuyFee, uint256 _totalSellFee, uint256 _encroachmentFee) {
        uint256 totalBuyFee_      = (amount * buyFee) / (100);
        uint256 totalSellFee_     = (amount * sellFee) / (100);
        uint256 encroachmentFee_  = (amount * encroachmentFee) / (100); 

        return (totalBuyFee_, totalSellFee_, encroachmentFee_);
    } 

    function _isContract(address _addr) private view returns (bool){
        uint32 size;
        assembly {
            size := extcodesize(_addr)
        }
        return (size > 0);
    }

    ///@notice DEX functions
    function _swapTokenForEth(uint256 amount) private {
        uint256 initialETHBalance = address(this).balance;

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = dexRouter.WETH();

        _approve(address(this), address(dexRouter), amount);

        dexRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amount,
            0,
            path,
            address(this), 
            block.timestamp
        );

        uint256 ethBalance = (address(this).balance).sub(initialETHBalance);
        uint256 ethForControlledBurnWallet = (ethBalance.mul(40)).div(100); //40% of the swapped amount
        uint256 ethForDevelopmentWallet    = (ethBalance.mul(40)).div(100); //40% of the swapped amount
        uint256 ethForMarketingWallet      = (ethBalance.mul(20)).div(100); //20% of the swapped amount

        payable(controlledBurnWallet).transfer(ethForControlledBurnWallet);
        payable(developmentWallet).transfer(ethForDevelopmentWallet);
        payable(marketingWallet).transfer(ethForMarketingWallet);
    }

    ///@notice Caller must send tokens to the contract first in order to execute the function
    function addInitialLiquidity(uint256 tokenAmount) external payable onlyOwner returns (bool) {
        _approve(address(this), address(dexRouter), tokenAmount);
        require(tokenAmount > 0 && msg.value > 0, "Amounts must be greater than zero");

        dexRouter.addLiquidityETH{value: msg.value}(
            address(this),
            tokenAmount,
            0,
            0,
            owner(),
            block.timestamp + 3600
        );
        return true;
    } 
}