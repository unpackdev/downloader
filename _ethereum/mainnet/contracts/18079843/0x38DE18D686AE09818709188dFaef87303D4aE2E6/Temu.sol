/**
 *Submitted for verification at Etherscan.io on 2023-09-06
*/

// SPDX-License-Identifier: MIT

// CONTRACT WILL BE OPEN SOURCE & RENOUNCED
// PAIR WILL BE LIQUIDITY LOCKED FOR 999 DAYS (TEMU.com/WETH PAIR) on UNCX, 0 OWNER TOKENS, ANTI-RUG BY DEFAULT

// Website: https://www.temu.com/
// Twitter/X: https://twitter.com/shoptemu?ref_src=uniswap%5Etokenization%5Erollout
// Docs: https://en.wikipedia.org/wiki/Temu_(marketplace)

// Temu.com - Anniversary extravaganza! Temu (tee-moo) is an online marketplace that connects consumers with millions 
// of sellers, manufacturers and brands around the world with the mission to empower them to live their best lives. 
// Temu is committed to offering the most affordable quality products to enable consumers and sellers to fulfill their  
// dreams in an inclusive environment. Temu was founded in Boston, Massachusetts in 2022.

// 🚀 Introducing TEMU Token: The Future of the TEMU Ecosystem
// We are thrilled to announce that TEMU, a brand synonymous with innovation and quality, is taking a monumental leap into 
// the world of cryptocurrency with the launch of our very own TEMU Token! As we venture into this exciting new frontier, we
// invite you to be a part of this transformative journey that promises to redefine the way you interact with the TEMU brand.

// 🌟 Why TEMU Token?
// The TEMU Token isn't just another cryptocurrency; it's an extension of our commitment to delivering unparalleled value to 
// our community. By integrating blockchain technology into our existing services, we aim to create a seamless, secure, and 
// transparent platform that enhances user experience and engagement.

// 🔒 Security & Trust
// In a world where data breaches and security threats are rampant, the TEMU Token brings an unprecedented level of security 
// and trust to our ecosystem. Our blockchain-based solutions are designed to protect user data and ensure transactional 
// integrity, giving you peace of mind as you engage with our brand.

// 💡 Innovation & Utility
// The TEMU Token will serve as the cornerstone of a range of innovative features and services that we will be rolling out. 
// From exclusive access to premium content, special discounts on TEMU products, to participation in community-driven projects, 
// the utility of this token goes beyond mere transactions; it's a passport to a more enriching experience with TEMU.

// 🌐 Global Community & Inclusivity
// With the launch of the TEMU Token, we are not just expanding our product offerings but also our community. The token allows 
// us to transcend geographical barriers and welcome a global audience into the TEMU family. It's not just a token; it's a 
// symbol of the inclusive and diverse community that TEMU stands for.

// 📈 Investment & Growth
// As a holder of the TEMU Token, you're not just a customer; you're a stakeholder in the TEMU brand. The token gives you a unique 
// opportunity to participate in the growth and success of TEMU. With various staking and reward programs, we aim to create a 
// mutually beneficial relationship that allows both the brand and the community to thrive.

// 🎉 Join Us on This Exciting Journey!
// As we embark on this groundbreaking venture, we invite you to be a part of the TEMU revolution. Together, let's build a future 
// where technology meets lifestyle, where community meets growth, and where TEMU meets you. Get ready to #TokenizeYourPassion 
// with TEMU Token! For more information, visit our https://www.temu.com/ and stay tuned for more exciting updates!

pragma solidity 0.8.21;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
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
    event Approval (address indexed owner, address indexed spender, uint256 value);
}

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
        return c;
    }

}

contract Ownable is Context {
    address private _owner;
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

}

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

contract Temu is Context, IERC20, Ownable {
    using SafeMath for uint256;

    address payable private _taxWallet;
    mapping (address => bool) private _isExcludedFromFee;
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    uint8 private constant _decimals = 18;
    uint256 private constant _tTotal = 1_200_000_000 * 10**_decimals;
    string private constant _name = unicode"Temu.com";
    string private constant _symbol = unicode"TEMU";

    uint256 public _initialBuyTax=25;
    uint256 public _initialSellTax=30;
    uint256 public _finalBuyTax=5;
    uint256 public _finalSellTax=5;
    uint256 private _reduceBuyTaxAt=20;
    uint256 private _reduceSellTaxAt=40;
    uint256 private _buyCount=0;

    uint256 private _maxWalletSize = _tTotal * 2 / 100;
    uint256 private _taxSwapThreshold= _tTotal / 250;
    uint256 private _maxTaxSwap= _tTotal / 250;

    IUniswapV2Router02 private uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    address private uniswapV2Pair;
    bool private tradingOpen;
    bool private inSwap;
    bool private swapEnabled;

    modifier lockTheSwap {
        inSwap = true;
        _;
        inSwap = false;
    }

    constructor () {
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());
        _taxWallet = payable(_msgSender());
        _balances[_msgSender()] = _tTotal;
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[_taxWallet] = true;
        _isExcludedFromFee[address(uniswapV2Router)] = true;
        _approve(msg.sender, address(this), type(uint256).max);
        _approve(address(this), address(uniswapV2Router), type(uint256).max);
        emit Transfer(address(0), _msgSender(), _tTotal);
    }

    function name() public pure returns (string memory) {
        return _name;
    }

    function symbol() public pure returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint8) {
        return _decimals;
    }

    function totalSupply() public pure override returns (uint256) {
        return _tTotal;
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
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(address from, address to, uint256 amount) private {
        require(amount > 0, "Transfer amount must be greater than zero");
        uint256 taxAmount=0;
        if (!_isExcludedFromFee[from] && !_isExcludedFromFee[to]) {
            require(tradingOpen, "trading not active");
            taxAmount = amount.mul((_buyCount>_reduceBuyTaxAt)?_finalBuyTax:_initialBuyTax).div(100);

            if (from == uniswapV2Pair && to != address(uniswapV2Router) && ! _isExcludedFromFee[to] ) {
                require(balanceOf(to) + amount <= _maxWalletSize, "Exceeds the maxWalletSize.");
                _buyCount++;
            }

            if (to != uniswapV2Pair && ! _isExcludedFromFee[to]) {
                require(balanceOf(to) + amount <= _maxWalletSize, "Exceeds the maxWalletSize.");
            }

            if(to == uniswapV2Pair && from!= address(this) ){
                taxAmount = amount.mul((_buyCount>_reduceSellTaxAt)?_finalSellTax:_initialSellTax).div(100);
            }

            uint256 contractTokenBalance = balanceOf(address(this));
            if (!inSwap && to   == uniswapV2Pair && swapEnabled && contractTokenBalance>_taxSwapThreshold) {
                swapTokensForEth(min(amount,min(contractTokenBalance,_maxTaxSwap)));
                uint256 contractETHBalance = address(this).balance;
                if(contractETHBalance > 0) {
                    sendETHToFee(address(this).balance);
                }
            }
        }

        if(taxAmount>0){
          _balances[address(this)]=_balances[address(this)].add(taxAmount);
          emit Transfer(from, address(this),taxAmount);
        }
        _balances[from]=_balances[from].sub(amount);
        _balances[to]=_balances[to].add(amount.sub(taxAmount));
        emit Transfer(from, to, amount.sub(taxAmount));
    }


    function min(uint256 a, uint256 b) private pure returns (uint256){
      return (a>b)?b:a;
    }

    function swapTokensForEth(uint256 tokenAmount) private lockTheSwap {
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

    function sendETHToFee(uint256 amount) private {
        _taxWallet.transfer(amount);
    }

    function setTaxWallet(address newAddress) external onlyOwner {
        _taxWallet = payable(newAddress);
    }

    function openTrading() external onlyOwner() {
        require(!tradingOpen);
        swapEnabled = true;
        tradingOpen = true;
    }

    function removeLimits() external onlyOwner{
        _maxWalletSize=_tTotal;
    }

    receive() external payable {}

}