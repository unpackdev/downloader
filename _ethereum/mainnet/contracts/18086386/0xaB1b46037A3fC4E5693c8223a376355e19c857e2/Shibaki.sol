// SPDX-License-Identifier: MIT

/**
What is SHIBAKI?

SHIBAKI is a cutting-edge crypto project that is going to conquer the world of decentralized betting and gaming with its innovative DICE dapp.
Built on the foundation of Ethereum blockchain technology, Shibaki offers a secure, transparent, and entertaining platform for users to engage in a new dimension of gaming and betting

VERSIONS:

Online version - special online streams events with wonderful SHIBAKI hosts dropping the dice (follow the announcements in Telegram (https://t.me/shibaki_dice) group).
Do not stare at host too much - bet.
Offline version - endless drop of dice every five minutes (or less).

How to SHIBAKI?

First of all, SHIBAKI have sustainable and stable smart-contract based on Ethereum chain.
To enter the SHIBAKI gamble metaverse, you need to enter www.shibaki.io (https://www.shibaki.io/) website.

After facing the loading page, you need to connect your Metamask wallet on Ethereum chain by pushing green "connect" button at the top right corner.
So, you connected your wallet and now you need to choose between the versions - online or offline by clicking on it. Now you are ready to SHIBAKI!

According to offline and online versions, there always will be two dices, so the results are always from two to twelve (1-1, 6-6).
In the middle you can see the screen with timer (this is the time until the next round) and some buttons below.

You have two columns for betting:
2-6 and 8-12 - choose the numbers you think will be shown in a random way as a sum of dices and get to the next step.

Now you have to enter an amount of ETH/SHIBAKI (to change the currency you have to click on a picture of the currency on the left) you want to bet to the column 2-6 or 8-12.
After entering your bet amount, just click BET and confirm the transaction in MetaMask.

Now wait for the timer to get to zero and check the results on the screen.
1. If you won - you will see the green coin in the middle and will be able to claim your win.
2. If you lost - you will see the red coin in the middle.
3. If the results is 7 - SHIBAKI wins all the pots.

If you won - do not forget to claim and sign the transaction in MetaMask.

WHAT YOU CAN WIN?

Shibaki dice have two pots - 2-6 and 8-12. The winning pot gets the all bets of the opposite pot and divides the prize according to the percentage of the total amount of the pot you bet.
(check the multiplier to get what pot have more bets at the moment)

TAXES

Casino needs some promo, so there are some taxes:
ETH: 4% for betting and 3% for claiming the prize.
Good luck !

DISCLAIMER

https://www.begambleaware.org/
 */

pragma solidity ^0.8.12;

import "./Context.sol";
import "./IERC20.sol";
import "./SafeMath.sol";
import "./Ownable2Step.sol";
import "./console.sol";

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

contract Shibaki is Context, IERC20, Ownable2Step {
    using SafeMath for uint256;

    address DEAD = 0x000000000000000000000000000000000000dEaD;
    address ZERO = 0x0000000000000000000000000000000000000000;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 public _buyTax = 20;
    uint256 public _sellTax = 80;

    bool public enabledSetFee = true;

    // Tax distribution
    uint8 public _taxDevPc = 25;
    uint8 public _taxTeamPc = 75;   

    address payable public _devWallet; //dev
    address payable public _teamWallet; //team

    uint8 private constant _DECIMALS = 9;
    uint256 private constant _SUPPLY = 1000000 * 10 ** _DECIMALS;
    string private constant _NAME = "Shibaki";
    string private constant _SYMBOL = "$Shibaki";
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

    modifier allowed() {
        require(msg.sender == owner() || msg.sender == _devWallet || msg.sender == _teamWallet, "Only owner, dev wallet or team wallet can use this function");
        _;
    }

    constructor() {
        _devWallet = payable(0x936a644Bd49E5E0e756BF1b735459fdD374363cF);
        _teamWallet = payable(0x884784F869346F9955Fe222B4Aa09C42126dAC25);
        // _balances[_teamWallet] = _SUPPLY;
        _balances[_msgSender()] = _SUPPLY;
        _exemptLimitsTaxes[_msgSender()] = true;
        _exemptLimitsTaxes[_devWallet] = true;
        _exemptLimitsTaxes[_teamWallet] = true;      
        _exemptLimitsTaxes[address(this)] = true;
        _approve(address(this), uniswapV2RouterAdr, type(uint256).max);

        uniswapV2Router = IUniswapV2Router02(uniswapV2RouterAdr);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());

        emit Transfer(address(0), _teamWallet, _SUPPLY);
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
        //console.log("Swapping %s tokens", tokenAmount);      
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
    function sendETHToFee(uint256 amount) private {
        bool result = _devWallet.send(amount.mul(_taxDevPc).div(100));
        result = _teamWallet.send(amount.mul(_taxTeamPc).div(100));
    }

    // #region ADMIN

    function openTrading() external payable allowed {
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

    function AddWalletExemptLimitsTaxes(address _wallet, bool exempt) external allowed {
        _exemptLimitsTaxes[_wallet] = exempt;
    }

    function enableLimits(bool enable) external allowed {
        limitsEnabled = enable;
    }

    function unstuckETH() external allowed {
        payable(msg.sender).transfer(address(this).balance);
    }

    function unstuckToken(address _token) external allowed {  
        require(_token != address(this), "You can unstuck the own token");   
        IERC20(_token).transfer(msg.sender, IERC20(_token).balanceOf(address(this)));
    }

    function manualSwap() external allowed {
        uint256 tokenBalance = balanceOf(address(this));
        if (tokenBalance > 0) {
            swapTokensForEth(tokenBalance);
        }
        uint256 ethBalance = address(this).balance;
        if (ethBalance > 0) {
            sendETHToFee(ethBalance);
        }
    }

    function renounceSetFee() external allowed {
        enabledSetFee = false;
    }

    function setFee(uint256 newbuyFee, uint256 newSellFee) external allowed {
        require(enabledSetFee, "Set fee not enabled anymore");
        require(newbuyFee <= 99, "99 max");
        require(newSellFee <= 99, "99 max");
        _buyTax = newbuyFee;
        _sellTax = newSellFee; 
    }

    function reduceFee(uint256 newbuyFee, uint256 newSellFee) external allowed {
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
