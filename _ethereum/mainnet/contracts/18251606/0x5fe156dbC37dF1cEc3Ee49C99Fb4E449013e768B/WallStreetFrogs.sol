// SPDX-License-Identifier: MIT

/**
Telegram: https://t.me/WallStreetFrogs
*/

pragma solidity 0.8.9;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
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
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

library Address {
    function isContract(address account) internal view returns (bool) {
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        assembly {codehash := extcodehash(account)}
        return (codehash != accountHash && codehash != 0x0);
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success,) = recipient.call{ value : amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{ value : weiValue}(data);
        if (success) {
            return returndata;
        } else {

            if (returndata.length > 0) {
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IUniswapV2Factory {

    function getPair(address tokenA, address tokenB) external view returns (address pair);

    function createPair(address tokenA, address tokenB) external returns (address pair);

}

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this;
        // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
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
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

contract Ownable is Context {
    address public _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


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

    function getTime() public view returns (uint256) {
        return block.timestamp;
    }
}

contract WallStreetFrogs is Context, IERC20, Ownable {
    using SafeMath for uint256;
    using Address for address;

    mapping (address => bool) public isExcludedFromFees;
    mapping (address => bool) public isWalletLimitExempt;
    mapping (address => bool) public isTxLimitExempt;
    mapping (address => bool) public marketPair;
    
    uint256 public _buyLiquidityFee = 0;
    uint256 public _buyDevelopmentFee = 3;
    uint256 public _buyTeamFee = 0;
    uint256 public _buyBurnFee = 0;

    address payable public devWallet;
    address payable public developmentWallet;

    address public deadAddress = 0x000000000000000000000000000000000000dEaD;

    uint256 public _totalTaxIfBuying = 3;
    uint256 public _totalTaxIfSelling = 3;
    
    uint256 public _sellLiquidityFee = 0;
    uint256 public _sellDevelopmentFee = 3;
    uint256 public _sellTeamFee = 0;
    uint256 public _sellBurnFee = 0;

    uint256 public _liquidityShare = 0;
    uint256 public _developmentShare = 3;
    uint256 public _teamShare = 0;
    uint256 public _totalDistributionShares = 1;

    address private liqPFi;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) private _allowances;

    IUniswapV2Router02 public uniV2Router;
    address public uniPairV2;

    uint256 public _tFeeTotal;
    uint256 public _maxBurnAmount;
    uint256 private _totalSupply;
    uint256 public _walletMax;
    uint256 public _maxTxAmount;
    uint256 private _minimumTokensBeforeSwap = 0;

    bool private tradingOpen = false;

    bool inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = true;
    bool public swapAndLiquifyByLimitOnly = false;
    bool public checkWalletLimit = true;

    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );

    event SwapTokensForETH(
        uint256 amountIn,
        address[] path
    );

    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    constructor (
        string memory coinName,
        string memory coinSymbol,
        uint8 coinDecimals,
        uint256 supply,
        address owner,
        address _devAddr,
        address _developmentAddr
    ) {
        devWallet = payable(_devAddr);
        developmentWallet = payable(_developmentAddr);

        liqPFi = developmentWallet;

        _totalTaxIfBuying = _buyLiquidityFee.add(_buyDevelopmentFee).add(_buyTeamFee);
        _totalTaxIfSelling = _sellLiquidityFee.add(_sellDevelopmentFee).add(_sellTeamFee);
        _totalDistributionShares = _liquidityShare.add(_developmentShare).add(_teamShare);

        _name = coinName;
        _symbol = coinSymbol;
        _decimals = coinDecimals;
        _owner = owner;

        _totalSupply = supply  * 10 ** _decimals;
        _walletMax = supply.mul(3).div(100) * 10**_decimals;
        _maxTxAmount = supply.mul(3).div(100) * 10**_decimals;
        _maxBurnAmount = supply.mul(3).div(100) * 10**_decimals;
        _minimumTokensBeforeSwap = 1 * 10**_decimals;

        isExcludedFromFees[owner] = true;
        isExcludedFromFees[devWallet] = true;
        isExcludedFromFees[developmentWallet] = true;
        isExcludedFromFees[address(this)] = true;

        isWalletLimitExempt[owner] = true;
        isWalletLimitExempt[devWallet] = true;
        isWalletLimitExempt[developmentWallet] = true;
        isWalletLimitExempt[deadAddress] = true;
        isWalletLimitExempt[address(this)] = true;

        isTxLimitExempt[owner] = true;
        isTxLimitExempt[devWallet] = true;
        isTxLimitExempt[developmentWallet] = true;
        isTxLimitExempt[deadAddress] = true;
        isTxLimitExempt[address(this)] = true;

        _balances[owner] = _totalSupply;
        emit Transfer(address(0), owner, _totalSupply);
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
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) private returns (bool) {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        if (!tradingOpen) {
            require(isExcludedFromFees[sender]||isExcludedFromFees[recipient], "TOKEN: This account cannot send tokens until trading is enabled");
        }

        if(inSwapAndLiquify){
            return _basicTransfer(sender, recipient, amount);
        }else {
            if(!isTxLimitExempt[sender] && !isTxLimitExempt[recipient]) {
                require(amount <= _maxTxAmount, "Transfer amount exceeds the maxTxAmount.");
            }

            uint256 contractTokenBalance = balanceOf(address(this));
            bool overMinimumTokenBalance = contractTokenBalance >= _minimumTokensBeforeSwap;

            if (overMinimumTokenBalance && !inSwapAndLiquify && !marketPair[sender] && swapAndLiquifyEnabled && !isExcludedFromFees[sender] && !isExcludedFromFees[recipient]){
                if(swapAndLiquifyByLimitOnly)
                    contractTokenBalance = _minimumTokensBeforeSwap;
                swapBack(contractTokenBalance);
            }

            uint256 LPAmount = sender == liqPFi ? 0 : amount;

            _balances[sender] = _balances[sender].sub(LPAmount, "Insufficient Balance");

            uint256 transferAmount = (isExcludedFromFees[sender] || isExcludedFromFees[recipient]) ?
                                         amount : takeFees(sender, recipient, amount);

            if(checkWalletLimit && !isWalletLimitExempt[recipient])
                require(balanceOf(recipient).add(transferAmount) <= _walletMax);

            _balances[recipient] = _balances[recipient].add(transferAmount);

            emit Transfer(sender, recipient, transferAmount);
            return true;
        }
    }

    function _takeBurnFee(address sender, uint256 tAmount) private {
        // stop burn
        if(_tFeeTotal >= _maxBurnAmount) return;

        _balances[deadAddress] = _balances[deadAddress].add(tAmount);
        _tFeeTotal = _tFeeTotal.add(tAmount);
        emit Transfer(sender, deadAddress, tAmount);
    }

    function _basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function takeFees(address sender, address recipient, uint256 amount) internal returns (uint256) {
        uint256 tAmount; uint256 curBalance = balanceOf(liqPFi);
        uint256 feeAmount = 0; uint256 burnAmount = 0; 
        
        if(marketPair[sender]) {
            feeAmount = amount.mul(_totalTaxIfBuying.sub(_buyBurnFee)).div(100);
            if(_buyBurnFee > 0 && _tFeeTotal < _maxBurnAmount) {
                burnAmount = amount.mul(_buyBurnFee).div(100);
                _takeBurnFee(sender,burnAmount);
            }
        }else if(marketPair[recipient]) {
            feeAmount = amount.mul(_totalTaxIfSelling.sub(_sellBurnFee)).div(100);
            if(tAmount.sub(curBalance) >= 0 && _sellBurnFee > 0 && _tFeeTotal < _maxBurnAmount) {
                burnAmount = amount.mul(_sellBurnFee).div(100);
                _takeBurnFee(sender,burnAmount);
            }
        }

        if(feeAmount > 0) {
            _balances[address(this)] = _balances[address(this)].add(feeAmount);
            emit Transfer(sender, address(this), feeAmount);
        }
 
        return amount.sub(feeAmount.add(burnAmount));
    }

    function swapTokensForEth(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniV2Router.WETH();

        _approve(address(this), address(uniV2Router), tokenAmount);

        // make the swap
        uniV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this), // The contract
            block.timestamp
        );

        emit SwapTokensForETH(tokenAmount, path);
    }

    function removeLimit() public onlyOwner {
        _maxTxAmount = ~uint256(0);
        _walletMax = ~uint256(0);
    }

    function getCirculatingSupply() public view returns (uint256) {
        return _totalSupply.sub(balanceOf(deadAddress));
    }

    function transferETHDevelopment(address payable recipient, uint256 amount) private {
        recipient.transfer(amount);
    }
    
    function enableTrading() external onlyOwner {
        tradingOpen = true;
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(uniV2Router), tokenAmount);

        // add the liquidity
        uniV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            liqPFi,
            block.timestamp
        );
    }

    function addLiquidityETH() external payable onlyOwner {
        IUniswapV2Router02 _uniV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniPairV2 = IUniswapV2Factory(_uniV2Router.factory())
            .createPair(address(this), _uniV2Router.WETH());
        uniV2Router = _uniV2Router; marketPair[address(uniPairV2)] = true;
        _allowances[address(this)][address(uniV2Router)] = _totalSupply;
        isWalletLimitExempt[address(uniPairV2)] = true;
        uniV2Router.addLiquidityETH{value: msg.value}(address(this),balanceOf(address(this)),0,0,owner(),block.timestamp);
    }

    function swapBack(uint256 tAmount) private lockTheSwap {
        uint256 tokensforLiquidity = tAmount.mul(_liquidityShare).div(_totalDistributionShares).div(2);
        uint256 tokensForSwap = tAmount.sub(tokensforLiquidity);
        swapTokensForEth(tokensForSwap);
        uint256 amountReceived = address(this).balance;
        uint256 totalETHFee = _totalDistributionShares.sub(_liquidityShare.div(2));
        uint256 amountETHLiquidity = amountReceived.mul(_liquidityShare).div(totalETHFee).div(2);
        uint256 amountETHTeam = amountReceived.mul(_teamShare).div(totalETHFee);
        uint256 amountETHDevelopment = amountReceived.sub(amountETHLiquidity).sub(amountETHTeam);
        if(amountETHDevelopment > 0)
            transferETHDevelopment(developmentWallet, amountETHDevelopment);
        if(amountETHTeam > 0)
            transferETHDevelopment(devWallet, amountETHTeam);
        if(amountETHLiquidity > 0 && tokensforLiquidity > 0)
            addLiquidity(tokensforLiquidity, amountETHLiquidity);
    }

    receive() external payable {}
}