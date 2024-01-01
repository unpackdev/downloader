/*

Twitter - https://twitter.com/Schmuck_Erc
Telegram - https://t.me/SchmuckErc

Get Schumcked! http://schmuckschmuck.com
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

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
    event Approval(address indexed owner, address indexed spender, uint256 value);
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
}

contract SchmuckToken is Context, IERC20, Ownable {
    using SafeMath for uint256;
    mapping (address => uint256) private _rOwned;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _isExcludedFromFee;
    
    uint256 private _buyMarketingFee = 20;
    uint256 private _previousBuyMarketingFee = _buyMarketingFee;
    
    uint256 private _sellMarketingFee = 20;
    uint256 private _previousSellMarketingFee = _sellMarketingFee;
    
    uint256 private tokensForMarketing;
    
    address payable private _marketingWallet;
    
    string public constant name = "Schmuck";
    string public constant symbol = "Schmuck";
    uint8 public constant decimals = 9;
    uint256 public constant totalSupply = 420_000 * 10**decimals;
    
    IUniswapV2Router02 public immutable uniswapV2Router;
    address public immutable uniswapV2Pair;

    bool public tradingOpen = false;
    bool private swapping;
    bool private inSwap = false;
    bool private swapEnabled = false;
    
    uint256 private _maxBuyAmount = totalSupply / 50;
    uint256 private _maxSellAmount = totalSupply / 50;
    uint256 private _maxWalletAmount = totalSupply / 50;
    uint256 private swapTokensAtAmount = totalSupply / 1000;
    
    modifier lockTheSwap {
        inSwap = true;
        _;
        inSwap = false;
    }
    constructor () {
        _marketingWallet = payable(0x9AAB57c7Fe02Ab0C37e9Fda8a9724a2250B9C385);

        _rOwned[_msgSender()] = totalSupply;
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[_marketingWallet] = true;
        emit Transfer(address(0), _msgSender(), totalSupply);

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapV2Router = _uniswapV2Router;

        _approve(address(this), address(uniswapV2Router), totalSupply);
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
        IERC20(uniswapV2Pair).approve(address(uniswapV2Router), type(uint).max);
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _rOwned[account];
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

    function setSwapEnabled(bool onoff) external onlyOwner(){
        swapEnabled = onoff;
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
        bool takeFee = false;
        bool shouldSwap = false;

        if(from != owner() && to != owner()){
            require(tradingOpen,"Trading not open yet");
        }

        if (from != owner() && to != owner() && to != address(0) && to != address(0xdead) && !swapping) {

            takeFee = true;
            if (from == uniswapV2Pair && to != address(uniswapV2Router) && !_isExcludedFromFee[to]) {
                require(amount <= _maxBuyAmount, "Transfer amount exceeds the maxBuyAmount.");
                require(balanceOf(to) + amount <= _maxWalletAmount, "Exceeds maximum wallet token amount.");
            }
            
            if (to == uniswapV2Pair && from != address(uniswapV2Router) && !_isExcludedFromFee[from]) {
                require(amount <= _maxSellAmount, "Transfer amount exceeds the maxSellAmount.");
                shouldSwap = true;
            }
        }

        if(_isExcludedFromFee[from] || _isExcludedFromFee[to]) {
            takeFee = false;
        }

        uint256 contractTokenBalance = balanceOf(address(this));
        bool canSwap = (contractTokenBalance > swapTokensAtAmount) && shouldSwap;

        if (canSwap && swapEnabled && !swapping && !_isExcludedFromFee[from] && !_isExcludedFromFee[to]) {
            swapping = true;
            swapBack();
            swapping = false;
        }

        _tokenTransfer(from,to,amount,takeFee, shouldSwap);
    }

    function swapBack() private {
        uint256 contractBalance = balanceOf(address(this));
        bool success;
        
        if(contractBalance == 0) {return;}

        if(contractBalance > swapTokensAtAmount * 5) {
            contractBalance = swapTokensAtAmount * 2;
        }
        
        swapTokensForEth(contractBalance); 
        
        tokensForMarketing = 0;

        (success,) = address(_marketingWallet).call{value: address(this).balance}("");
    }

    function swapTokensForEth(uint256 tokenAmount) private lockTheSwap {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }
 
    function openTrading() external onlyOwner() {
        require(!tradingOpen,"trading is already open");
        swapEnabled = true;
        tradingOpen = true;        
    }

    function removeLimits() external onlyOwner {
        _maxBuyAmount = totalSupply;
        _maxSellAmount = totalSupply;
        _maxWalletAmount = totalSupply;
    }
    
    function setSwapTokensAtAmount(uint256 newAmount, bool _enabled) external onlyOwner {
        swapEnabled = _enabled;
        swapTokensAtAmount = newAmount;
    }

    function setMarketingWallet(address MarketingWallet) external onlyOwner() {
        _marketingWallet = payable(MarketingWallet);
    }

    function excludeFromFee(address account) external onlyOwner {
        _isExcludedFromFee[account] = true;
    }
    
    function includeInFee(address account) external onlyOwner {
        _isExcludedFromFee[account] = false;
    }

    function setBuyFee(uint256 buyMarketingFee) external onlyOwner {
        require(buyMarketingFee <= 20, "Must keep buy taxes below 20%");
        _buyMarketingFee = buyMarketingFee;
    }

    function setSellFee(uint256 sellMarketingFee) external onlyOwner {
        require(sellMarketingFee <= 20, "Must keep sell taxes below 20%");
        _sellMarketingFee = sellMarketingFee;
    }

    function removeAllFee() private {
        if(_buyMarketingFee == 0 && _sellMarketingFee == 0) return;
        
        _previousBuyMarketingFee = _buyMarketingFee;
        _previousSellMarketingFee = _sellMarketingFee;
        
        _buyMarketingFee = 0;
        _sellMarketingFee = 0;
    }
    
    function restoreAllFee() private {
        _buyMarketingFee = _previousBuyMarketingFee;
        _sellMarketingFee = _previousSellMarketingFee;
    }

        
    function _tokenTransfer(address sender, address recipient, uint256 amount, bool takeFee, bool isSell) private {
        if(!takeFee) {
            removeAllFee();
        } else {
            amount = _takeFees(sender, amount, isSell);
        }

        _transferStandard(sender, recipient, amount);
        
        if(!takeFee) {
            restoreAllFee();
        }
    }

    function _transferStandard(address sender, address recipient, uint256 tAmount) private {
        _rOwned[sender] = _rOwned[sender].sub(tAmount);
        _rOwned[recipient] = _rOwned[recipient].add(tAmount);
        emit Transfer(sender, recipient, tAmount);
    }

    function _takeFees(address sender, uint256 amount, bool isSell) private returns (uint256) {
        uint256 _totalFees;
        
        _totalFees = _getTotalFees(isSell);

        uint256 fees = amount.mul(_totalFees).div(100);
            
        if(fees > 0) {
            _transferStandard(sender, address(this), fees);
        }
            
        return amount -= fees;
    }

    receive() external payable {}
    
    function manualswap() external onlyOwner() {
        uint256 contractBalance = balanceOf(address(this));
        swapTokensForEth(contractBalance);
    }
    
    function manualSend() external onlyOwner() {
        uint256 contractETHBalance = address(this).balance;
        _marketingWallet.transfer(contractETHBalance);
    }

    function _getTotalFees(bool isSell) private view returns(uint256) {
        if (isSell) {
            return _sellMarketingFee;
        }
        return _buyMarketingFee;
    }
}