
pragma solidity 0.6.12;
// SPDX-License-Identifier: MIT
import "./Ownable.sol";
import "./IERC20.sol";
import "./Context.sol";
import "./SafeMath.sol";
import "./Address.sol";
import "./ReentrancyGuard.sol";

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

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
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

interface IWETH {
    function withdraw(uint wad) external;
    function balanceOf(address owner) external view returns (uint);
}

contract OpenExhibitionToken is Context, IERC20, Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using Address for address;

    mapping (address => uint256) private _rOwned;
    mapping (address => uint256) private _tOwned;
    mapping (address => mapping (address => uint256)) private _allowances;

    mapping (address => bool) private _isExcludedFromFee;

    mapping (address => bool) private _isExcluded;
    address[] private _excluded;
   
    address public constant BURN_ADDRESS = 0x0000000000000000000000000000000000000001;
	
    uint256 private constant MAX = ~uint256(0);
    uint256 private constant _tTotal = 1000000000 * 10**6 * 10**9;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;

    string private _name = "OpenExhibitionCoin";
    string private _symbol = "OEC";
    uint8 private _decimals = 9;
    
    ///////////////////////////////////
    //  TAX Distribution             //
    ///////////////////////////////////
    // 5% to all holders
    // 1% to uniswap liquidity
    // 2% reserve for NFT buyers cashback
    // 1% burn
    // 1% to dev wallet
    //////////////////////////////////
    uint256 public _taxFee = 5;
    uint256 private _previousTaxFee = _taxFee;
    
    uint256 public _liquidityFee = 1;
    uint256 private _previousLiquidityFee = _liquidityFee;

    uint256 public _cashbackFee = 2;
    uint256 private _previousCashbackFee = _cashbackFee;

    uint256 public _burnFee = 1;
	uint256 private _previousBurnFee = _burnFee;

    uint256 public _devFee = 1;
    uint256 private _previousDevFee = _devFee;

    IUniswapV2Router02 public immutable uniswapV2Router;
    address public immutable uniswapV2Pair;
    IWETH public immutable WETH;
    
    bool public _liquify;
    bool public _liquifyEnabled = true;
    
    uint256 public _maxTxAmount = 5000000 * 10**6 * 10**9;
    uint256 private _minTokensToAddLiquidity = 500000 * 10**6 * 10**9;
    
    uint256 public _cashbackPercentage = 10;

    // dev fees will be collected in _devAccount.
    // Dev tokens will be used for NFT Marketplace development and maintenance
    address private _devAccount;

    // NFT Exchange contract address
    address private _nftExchangeAddress;

    // liquidity balance variable
    uint256 private _tTotalForLiquidity;
    uint256 private _rTotalForLiquidity;

    event LiquifyEnabledUpdated(bool enabled);
    event Liquify(uint256 tokensAdded, uint256 ethAdded);
    event BurnFeeChanged(uint256 percentage);
    event CashBackFeeChanged(uint256 percentage);
    event NFTCashBackChanged(uint256 percentage);
    event LiquidityFeeChanged(uint256 percentage);
    event DevFeeChanged(uint256 percentage);
    event DevAccountChanged(address account);
    event MaxTxAmountChanged(uint256 amount);
    event MinTokenForLiquifyChanged(uint256 amount);
    event NFTExchangeAddressChanged(address exchange);
    event TaxFeeChanged(uint256 percentage);
    
    modifier refundGas {
        _liquify = true;
        uint256 gasAtStart = gasleft();
        _;
        uint256 gasSpent = gasAtStart - gasleft() + 21000; // added gas used by transfer
        uint256 refundETH = gasSpent * tx.gasprice;
        if (address(this).balance >= refundETH)
            tx.origin.transfer(refundETH);
        _liquify = false;
    }

    modifier checkPercentageRange(uint256 value) {
        require(value >= 0 && value <= 100, "Invalid Percentage Value");
        _;
    }

    

    constructor (address devAccount) public {
        require(devAccount != address(0), "devAccount is the zero address");
        _devAccount = devAccount;
        
        _rOwned[_msgSender()] = _rTotal;
        
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
         // Create a uniswap pair for this new token
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        // set the rest of the contract variables
        uniswapV2Router = _uniswapV2Router;
        WETH = IWETH(_uniswapV2Router.WETH());        
        _isExcludedFromFee[_msgSender()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[_devAccount] = true;
        _isExcludedFromFee[BURN_ADDRESS] = true;

        _isExcluded[address(this)] = true;
        _isExcluded[BURN_ADDRESS] = true;
        
        emit Transfer(address(0), _msgSender(), _tTotal);
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

    function totalSupply() public view override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        if (_isExcluded[account]) return _tOwned[account];
        return tokenFromReflection(_rOwned[account]);
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    function isExcludedFromReward(address account) public view returns (bool) {
        return _isExcluded[account];
    }

    function totalFees() public view returns (uint256) {
        return _tFeeTotal;
    }

    function totalBurned() public view returns (uint256) {
		return balanceOf(BURN_ADDRESS);
	}

    function deliver(uint256 tAmount) external {
        address sender = _msgSender();
        require(!_isExcluded[sender], "Excluded addresses cannot call this function");
        (uint256 rAmount,,,) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rTotal = _rTotal.sub(rAmount);
        _tFeeTotal = _tFeeTotal.add(tAmount);
    }

    function reflectionFromToken(uint256 tAmount, bool deductTransferFee) external view returns(uint256) {
        require(tAmount <= _tTotal, "Amount must be less than supply");
        if (!deductTransferFee) {
            (uint256 rAmount,,,) = _getValues(tAmount);
            return rAmount;
        } else {
            (,uint256 rTransferAmount,,) = _getValues(tAmount);
            return rTransferAmount;
        }
    }

    function tokenFromReflection(uint256 rAmount) public view returns(uint256) {
        require(rAmount <= _rTotal, "Amount must be less than total reflections");
        uint256 currentRate =  _getRate();
        return rAmount.div(currentRate);
    }

    function excludeFromReward(address account) public onlyOwner {
        require(!_isExcluded[account], "Account is already excluded");
        if(_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isExcluded[account] = true;
        _excluded.push(account);
    }

    function includeInReward(address account) external onlyOwner {
        require(_isExcluded[account], "Account is already included");
        uint256 excludedLength = _excluded.length;
        for (uint256 i = 0; i < excludedLength; i++) {
            if (_excluded[i] == account) {
                _excluded[i] = _excluded[excludedLength - 1];
                _tOwned[account] = 0;
                _isExcluded[account] = false;
                _excluded.pop();
                break;
            }
        }
    }

    function setDevAccount(address devAccount) external onlyOwner {
        require(devAccount != address(0), "devAccount is the zero address");
        _devAccount = devAccount;
        _isExcludedFromFee[_devAccount] = true;
    }
    
    function setNFTExchangeAddress(address nftExchangeAddr) external onlyOwner {
        require( nftExchangeAddr != address(0), "nftExchangeAddr is the zero address");
        _nftExchangeAddress = nftExchangeAddr;
        _isExcludedFromFee[_nftExchangeAddress] = true;
    }

    function excludeFromFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = true;
    }

    function excludeFromFeeAndRewards(address account) external onlyOwner {
        excludeFromFee(account);
        excludeFromReward(account);
    }
    
    function includeInFee(address account) external onlyOwner {
        _isExcludedFromFee[account] = false;
    }
    
    function setTaxFeePercent(uint256 taxFee) external onlyOwner checkPercentageRange(taxFee) {
        _taxFee = taxFee;
        emit TaxFeeChanged(taxFee);
    }
    
    function setLiquidityFeePercent(uint256 liquidityFee) external onlyOwner checkPercentageRange(liquidityFee) {
        _liquidityFee = liquidityFee;
        emit LiquidityFeeChanged(liquidityFee);
    }

    function setDevFeePercent(uint256 devFee) external onlyOwner checkPercentageRange(devFee) {
        _devFee = devFee;
        emit DevFeeChanged(devFee);
    }
   
   function setCashbackFeePercent(uint256 cashbackFee) external onlyOwner checkPercentageRange(cashbackFee) {
        _cashbackFee = cashbackFee;
        emit CashBackFeeChanged(cashbackFee);
    }

    function setBurnPercent(uint256 burnFee) external onlyOwner checkPercentageRange(burnFee) {
        _burnFee = burnFee;
        emit BurnFeeChanged(burnFee);
    }

    function setNFTCashbackPercent(uint256 cashbackPercent) external onlyOwner checkPercentageRange(cashbackPercent) {
        _cashbackPercentage = cashbackPercent;
        emit NFTCashBackChanged(cashbackPercent);
    }

    function setMaxTxPercent(uint256 maxTxPercent) external onlyOwner checkPercentageRange(maxTxPercent) {
        _maxTxAmount = _tTotal.mul(maxTxPercent).div(10**2);
        emit MaxTxAmountChanged(_maxTxAmount);
    }

    function setLiquifyEnabled(bool enabled) external onlyOwner {
        _liquifyEnabled = enabled;
        emit LiquifyEnabledUpdated(enabled);
    }
    
    function setMinTokenForLiquify(uint256 amount) external onlyOwner {
        _minTokensToAddLiquidity = amount;
        emit MinTokenForLiquifyChanged(amount);
    }

    function getCashbackBalance() public view returns(uint256) {
        return balanceOf(address(this)).sub(_tTotalForLiquidity); // contract address will be always excluded
    }

    function getLiquidityBalance() public view returns(uint256) {
        return _tTotalForLiquidity;
    }

    function withdrawXToken(address tokenAddress, address destination, uint256 value) external onlyOwner {
        require(tokenAddress != address(this), "OEC isn't withdrawable");
        require(IERC20(tokenAddress).transfer(destination, value), "failed to transfer the tokens");
    }

    receive() external payable {}

    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal.sub(rFee);
        _tFeeTotal = _tFeeTotal.add(tFee);
    }

    function _getValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256) {
        uint256 tTotalFees;
        uint256 rTotalFees;
        uint256 rFee;
        
        uint256 currentRate = _getRate();
        uint256 rAmount = tAmount.mul(currentRate);
        
        // scope to avoid stack too deep error
        {
            uint256 taxFee = calculateTaxFee(tAmount); 
            tTotalFees = tTotalFees.add(taxFee);

            uint256 liquidityFee = calculateLiquidityFee(tAmount);
            tTotalFees = tTotalFees.add(liquidityFee);

            uint256 devFee = calculateDevFee(tAmount);
            tTotalFees = tTotalFees.add(devFee);

            uint256 cashbackFee = calculateCashbackFee(tAmount);
            tTotalFees = tTotalFees.add(cashbackFee);

            uint256 burnFee = calculateBurnFee(tAmount);
            tTotalFees = tTotalFees.add(burnFee);

            // rfees
            rFee = taxFee.mul(currentRate);
            rTotalFees = rTotalFees.add(rFee);

            liquidityFee = liquidityFee.mul(currentRate);
            rTotalFees = rTotalFees.add(liquidityFee);

            devFee = devFee.mul(currentRate);
            rTotalFees = rTotalFees.add(devFee);

            cashbackFee = cashbackFee.mul(currentRate);
            rTotalFees = rTotalFees.add(cashbackFee);

            burnFee = burnFee.mul(currentRate);
            rTotalFees = rTotalFees.add(burnFee);
        }

        uint256 tTransferAmount = tAmount.sub(tTotalFees);
        uint256 rTransferAmount = rAmount.sub(rTotalFees);
        return (rAmount, rTransferAmount, rFee, tTransferAmount);
    }

    function _getRate() private view returns(uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }

    function _getCurrentSupply() private view returns(uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;
        uint256 excludedLength = _excluded.length;  
        for (uint256 i = 0; i < excludedLength; i++) {
            if (_rOwned[_excluded[i]] > rSupply || _tOwned[_excluded[i]] > tSupply) return (_rTotal, _tTotal);
            rSupply = rSupply.sub(_rOwned[_excluded[i]]);
            tSupply = tSupply.sub(_tOwned[_excluded[i]]);
        }
        if (rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }
    
    function _takeLiquidity(uint256 tLiquidity) private {
        if (tLiquidity == 0) return;

        uint256 currentRate =  _getRate();
        uint256 rLiquidity = tLiquidity.mul(currentRate);
        _rOwned[address(this)] = _rOwned[address(this)].add(rLiquidity);
        _rTotalForLiquidity = _rTotalForLiquidity.add(rLiquidity);
        if(_isExcluded[address(this)]) {
            _tOwned[address(this)] = _tOwned[address(this)].add(tLiquidity);
            _tTotalForLiquidity = _tTotalForLiquidity.add(tLiquidity);
        }
    }
    
    function _takeDevFee(uint256 tDevFee) private {
        if (tDevFee == 0) return;

        uint256 currentRate =  _getRate();
        uint256 rDev = tDevFee.mul(currentRate);
        _rOwned[_devAccount] = _rOwned[_devAccount].add(rDev);
        if(_isExcluded[_devAccount])
            _tOwned[_devAccount] = _tOwned[_devAccount].add(tDevFee);
    }

    function _takeCashbackFee(uint256 tCashbackFee) private {
        if (tCashbackFee == 0) return;

        uint256 currentRate =  _getRate();
        uint256 rCashback = tCashbackFee.mul(currentRate);
        _rOwned[address(this)] = _rOwned[address(this)].add(rCashback);
        if(_isExcluded[address(this)])
            _tOwned[address(this)] = _tOwned[address(this)].add(tCashbackFee);
    }

    function _transferBurn(uint256 tBurn) private {
        if (tBurn == 0) return;

		uint256 currentRate = _getRate();
		uint256 rBurn = tBurn.mul(currentRate);		
		_rOwned[BURN_ADDRESS] = _rOwned[BURN_ADDRESS].add(rBurn);
		if(_isExcluded[BURN_ADDRESS])
			_tOwned[BURN_ADDRESS] = _tOwned[BURN_ADDRESS].add(tBurn);
	}

    function calculateTaxFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_taxFee).div(10**2);
    }

    function calculateLiquidityFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_liquidityFee).div(10**2);
    }
    
    function calculateDevFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_devFee).div(10**2);
    }

    function calculateCashbackFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_cashbackFee).div(10**2);
    }

    function calculateBurnFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_burnFee).div(10**2);
    }

    function calculateNFTCashback(uint256 amount) private view returns (uint256) {
        return amount.mul(_cashbackPercentage).div(10**2);
    }

    function removeAllFee() private {
        if(_taxFee == 0 && _liquidityFee == 0 && _devFee == 0 && _cashbackFee == 0 && _burnFee == 0) return;
        
        _previousTaxFee = _taxFee;
        _previousLiquidityFee = _liquidityFee;
        _previousCashbackFee = _cashbackFee;
        _previousDevFee = _devFee;
        _previousBurnFee = _burnFee;
        
        delete _taxFee;
        delete _liquidityFee;
        delete _devFee;
        delete _cashbackFee;
        delete _burnFee;
    }
    
    function restoreAllFee() private {
        _taxFee = _previousTaxFee;
        _liquidityFee = _previousLiquidityFee;
        _devFee = _previousDevFee;
        _cashbackFee = _previousCashbackFee;
        _burnFee = _previousBurnFee;
    }
    
    function isExcludedFromFee(address account) public view returns(bool) {
        return _isExcludedFromFee[account];
    }

    function getEstimatedETHforOEC(uint256 erc20Amount) public view returns (uint256[] memory)
    {
        return uniswapV2Router.getAmountsIn(erc20Amount, getPathForETHToOEC());
    }

    function getPathForETHToOEC() internal view returns (address[] memory)
    {
        address[] memory path = new address[](2);
        path[0] = uniswapV2Router.WETH();
        path[1] = address(this);
        return path;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        if(from != owner() && to != owner())
            require(amount <= _maxTxAmount, "Transfer amount exceeds the maxTxAmount.");

        uint256 liquidityBalance = _tTotalForLiquidity;

        if (liquidityBalance >= _maxTxAmount)
        {
            liquidityBalance = _maxTxAmount;
        }
        
        bool overMinTokenBalance = liquidityBalance >= _minTokensToAddLiquidity;
        if (
            overMinTokenBalance &&
            !_liquify &&
            from != uniswapV2Pair &&
            _liquifyEnabled
        ) {
            liquidityBalance = _minTokensToAddLiquidity;
            uint256 eth = getEstimatedETHforOEC(liquidityBalance)[0];
            uint256 wethBalance = WETH.balanceOf(address(this));
            
            if (wethBalance > 0)
                WETH.withdraw(wethBalance);

            if (address(this).balance > eth)
                addLiquidity(liquidityBalance, eth);
        }
        
        //indicates if fee should be deducted from transfer
        bool takeFee = true;
        
        //if any account belongs to _isExcludedFromFee account then remove the fee
        if(_isExcludedFromFee[from] || _isExcludedFromFee[to] || _isExcludedFromFee[_msgSender()]){
            takeFee = false;
        }
        
        //transfer amount, it will take tax, burn, liquidity fee
        _tokenTransfer(from,to,amount,takeFee);
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private refundGas {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // add the liquidity
        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            owner(),
            block.timestamp
        );

        uint256 rTokenAmount = tokenAmount.mul(_getRate());
        _rTotalForLiquidity = _rTotalForLiquidity.sub(rTokenAmount);
        _tTotalForLiquidity = _tTotalForLiquidity.sub(tokenAmount);
        emit Liquify(tokenAmount, ethAmount);
    }

    //this method is responsible for taking all fee, if takeFee is true
    function _tokenTransfer(address sender, address recipient, uint256 amount,bool takeFee) private {
        if(!takeFee)
            removeAllFee();
        
        if (_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferFromExcluded(sender, recipient, amount);
        } else if (!_isExcluded[sender] && _isExcluded[recipient]) {
            _transferToExcluded(sender, recipient, amount);
        } else if (!_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferStandard(sender, recipient, amount);
        } else if (_isExcluded[sender] && _isExcluded[recipient]) {
            _transferBothExcluded(sender, recipient, amount);
        } else {
            _transferStandard(sender, recipient, amount);
        }
        
        if(!takeFee)
            restoreAllFee();
    }

    function _cashback(uint256 tAmount, uint256 rAmount, address sender) private {
        if (_msgSender() == _nftExchangeAddress) {
            // 10% cashback to buyers
            uint256 cbRAmount = calculateNFTCashback(rAmount);

            if (_rOwned[address(this)].sub(_rTotalForLiquidity) >= cbRAmount) {
                _rOwned[sender] = _rOwned[sender].add(cbRAmount);
                _rOwned[address(this)] = _rOwned[address(this)].sub(cbRAmount);

                uint256 cbTAmount = calculateNFTCashback(tAmount);

                if (_isExcluded[sender])
                    _tOwned[sender] = _tOwned[sender].add(cbTAmount);
                if (_isExcluded[address(this)])
                    _tOwned[address(this)] = _tOwned[address(this)].sub(cbTAmount);
            }
        }
    }

    function _transferStandard(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _cashback(tAmount, rAmount, sender);
        _takeLiquidity(calculateLiquidityFee(tAmount));
        _takeDevFee(calculateDevFee(tAmount));
        _takeCashbackFee(calculateCashbackFee(tAmount));
        _transferBurn(calculateBurnFee(tAmount));
        _reflectFee(rFee, calculateTaxFee(tAmount));
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferToExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _cashback(tAmount, rAmount, sender);           
        _takeLiquidity(calculateLiquidityFee(tAmount));
        _takeDevFee(calculateDevFee(tAmount));
        _takeCashbackFee(calculateCashbackFee(tAmount));
        _transferBurn(calculateBurnFee(tAmount));
        _reflectFee(rFee, calculateTaxFee(tAmount));
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferBothExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _cashback(tAmount, rAmount, sender);
        _takeLiquidity(calculateLiquidityFee(tAmount));
        _takeDevFee(calculateDevFee(tAmount));
        _takeCashbackFee(calculateCashbackFee(tAmount));
        _transferBurn(calculateBurnFee(tAmount));
        _reflectFee(rFee, calculateTaxFee(tAmount));
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferFromExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _cashback(tAmount, rAmount, sender);
        _takeLiquidity(calculateLiquidityFee(tAmount));
        _takeDevFee(calculateDevFee(tAmount));
        _takeCashbackFee(calculateCashbackFee(tAmount));
        _transferBurn(calculateBurnFee(tAmount));
        _reflectFee(rFee, calculateTaxFee(tAmount));
        emit Transfer(sender, recipient, tTransferAmount);
    }
}
