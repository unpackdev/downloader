// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

import "./Context.sol";
import "./IERC20.sol";
import "./SafeMath.sol";
import "./Ownable2Step.sol";

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IUniswapV2Router02 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

    function factory() external pure returns (address);

    /* solhint-disable-next-line func-name-mixedcase */
    function WETH() external pure returns (address);

    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
}

interface ILiqPair {
    function getReserves() external view returns (uint112 _reserve0, uint112 _reserve1, uint32 _blockTimestampLast);
}

contract MorseERC is Context, IERC20, Ownable2Step {
    using SafeMath for uint256;

    address DEAD = 0x000000000000000000000000000000000000dEaD;
    address ZERO = 0x0000000000000000000000000000000000000000;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 public _rewardTax = 1;
    uint256 public _treasuryTax = 3;
    uint256 public _buyTax = 4;
    uint256 public _sellTax = 20;

    address payable public _devWallet; //dev
    address payable public _rewardWallet = payable(0x8b5c9C2566da0A05f473EC39c1C375FC543c51D8);
    
    uint8 private constant _DECIMALS = 9;
    uint256 private constant _SUPPLY = 1000000 * 10 ** _DECIMALS;
    string private constant _NAME = "--/---/.-./.../."; //"-- --- .-. ... .";//"MORSE";
    string private constant _SYMBOL = "$MORSE"; //MRS
    uint256 public _maxTxAmount = _SUPPLY.div(100); //1%
    uint256 public _maxWalletSize = _SUPPLY.div(50); //2%
    uint256 public _taxSwapThresholdDenom = 200;//_SUPPLY.div(200); //0.5%
    uint256 public _maxTaxSwapDenom = 100;//_SUPPLY.div(100); //1%
    bool public limitsEnabled = true;
    mapping(address => bool) public _exemptLimitsTaxes;

    IUniswapV2Router02 private uniswapV2Router;    
    address private uniswapV2RouterAdr = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address private uniswapV2Pair;
    bool private tradingOpen;
    bool private inSwap = false;
    bool private swapEnabled = false;

    modifier lockTheSwap() {
        inSwap = true;
        _;
        inSwap = false;
    }

    constructor() {
        _devWallet = payable(_msgSender());
        _balances[_msgSender()] = _SUPPLY;
        _exemptLimitsTaxes[_msgSender()] = true;
        _exemptLimitsTaxes[_devWallet] = true;
        _exemptLimitsTaxes[_rewardWallet] = true;
        _exemptLimitsTaxes[address(this)] = true;
        _approve(address(this), uniswapV2RouterAdr, type(uint256).max);

        uniswapV2Router = IUniswapV2Router02(uniswapV2RouterAdr);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());

        emit Transfer(address(0), _devWallet, _SUPPLY);
    }

    function name() public pure returns (string memory) {
        return _NAME;
    }

    function symbol() public pure returns (string memory) {
        return _SYMBOL;
    }

    function decimals() public pure returns (uint8) {
        return _DECIMALS;
    }

    function totalSupply() public pure override returns (uint256) {
        return _SUPPLY;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
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
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance")
        );
        return true;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        uint256 taxAmount = 0;
        if(!_exemptLimitsTaxes[to] && !_exemptLimitsTaxes[from]) {
            // Tx limit, wallet limit //
            if (limitsEnabled) {
                if (to != uniswapV2Pair) {
                    uint256 heldTokens = balanceOf(to);
                    require(
                        (heldTokens + amount) <= _maxWalletSize,
                        "Total Holding is currently limited, you can not buy that much."
                    );
                    require(amount <= _maxTxAmount, "TX Limit Exceeded");
                }
            }

            // Buy tax //
            if(from == uniswapV2Pair) {
                taxAmount = amount.mul(_buyTax).div(100);
            }

            // Sell tax //
            if (to == uniswapV2Pair) {
                taxAmount = amount.mul(_sellTax).div(100);
            }

            // Swap and send fee //
            (uint256 taxSwapThreshold, uint256 maxTaxSwap) = getSwapSettings();
            uint256 contractTokenBalance = balanceOf(address(this));
            if (!inSwap && to == uniswapV2Pair && swapEnabled && contractTokenBalance > taxSwapThreshold) {
                swapTokensForEth(min(contractTokenBalance, maxTaxSwap));
                uint256 contractETHBalance = address(this).balance;
                if (contractETHBalance > 0) {
                    sendETHToFee(address(this).balance);
                }
            }

            // Apply tax //
            if (taxAmount > 0) {
                _balances[address(this)] = _balances[address(this)].add(taxAmount);
                emit Transfer(from, address(this), taxAmount);
            }
        }

        _balances[from] = _balances[from].sub(amount);
        _balances[to] = _balances[to].add(amount.sub(taxAmount));
        emit Transfer(from, to, amount.sub(taxAmount));
    }

    function getSwapSettings() public view returns(uint256, uint256) {
        uint256 liqPairBalance = balanceOf(uniswapV2Pair);
        return(liqPairBalance.div(_taxSwapThresholdDenom), liqPairBalance.div(_maxTaxSwapDenom));
    }

    function min(uint256 a, uint256 b) private pure returns (uint256) {
        return (a > b) ? b : a;
    }

    function swapTokensForEth(uint256 tokenAmount) private lockTheSwap {
        if(tokenAmount == 0) return;
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();     
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    /** 
     *@notice Send eth to tax wallets 
     */ 
    function sendETHToFee(uint256 amount) private returns(bool) {
        uint256 _totalTax = _treasuryTax.add(_rewardTax);
        bool result = _devWallet.send(amount.mul(_treasuryTax).div(_totalTax));
        result = _rewardWallet.send(amount.mul(_rewardTax).div(_totalTax));
        return result;
    }

    // #region ADMIN

    function openTrading() external payable onlyOwner {
        require(!tradingOpen, "trading is already open");
        uniswapV2Router.addLiquidityETH{value: msg.value}(
            address(this),
            balanceOf(address(this)),
            0,
            0,
            owner(),
            block.timestamp
        );
        IERC20(uniswapV2Pair).approve(address(uniswapV2Router), type(uint).max);
        swapEnabled = true;
        tradingOpen = true;
    }

    function AddWalletExemptLimitsTaxes(address _wallet, bool exempt) external onlyOwner {
        _exemptLimitsTaxes[_wallet] = exempt;
    }

    function enableLimits(bool enable) external onlyOwner {
        limitsEnabled = enable;
    }

    function unstuckETH() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function unstuckToken(address _token) external onlyOwner {  
        require(_token != address(this), "You can unstuck the own token");   
        IERC20(_token).transfer(msg.sender, IERC20(_token).balanceOf(address(this)));
    }

    function manualSwap() external onlyOwner {
        uint256 tokenBalance = balanceOf(address(this));
        if (tokenBalance > 0) {
            swapTokensForEth(tokenBalance);
        }
        uint256 ethBalance = address(this).balance;
        if (ethBalance > 0) {
            sendETHToFee(ethBalance);
        }
    }

    function reduceFee(uint256 newbuyFee, uint256 newSellFee) external onlyOwner {
        require(newbuyFee <= _buyTax, "Buy tax only can be reduced");
        require(newSellFee <= _sellTax, "Sell tax only can be reduced");
        require(newbuyFee >= 1, "Buy tax can not be lower than 1%");
        require(newSellFee >= 1, "Sell tax can not be lower than 1%");
        _buyTax = newbuyFee;
        _sellTax = newSellFee;        
    }

    // #endregion

    /* solhint-disable-next-line no-empty-blocks */
    receive() external payable {}
}