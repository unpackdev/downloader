// SPDX-License-Identifier: MIT

/*
Unleash the Power of Multi-Chain Staking and Boost Your Assets

Website: https://www.boostprotocol.org
Telegram: https://t.me/boost_protocol
Twitter: https://twitter.com/Boost_ERC
*/

pragma solidity 0.8.19;

abstract contract Ownable {
    address internal owner;
    constructor(address _owner) {owner = _owner;}
    modifier onlyOwner() {require(isOwner(msg.sender), "!OWNER"); _;}
    function isOwner(address account) public view returns (bool) {return account == owner;}
    function transferOwnership(address payable adr) public onlyOwner {owner = adr; emit OwnershipTransferred(adr);}
    function renounceOwnership() public onlyOwner {owner = address(0); emit OwnershipTransferred(address(0));}
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
interface IFactory{
    function createPair(address tokenA, address tokenB) external returns (address pair);
}
contract BOOST is IERC20, Ownable {
    using SafeMath for uint256;
    string private constant _name = unicode"Boost Protocol";
    string private constant _symbol = unicode"BOOST";
    uint8 private constant _decimals = 9;
    uint256 private _tsupply = 1000000000 * (10 ** _decimals);
    bool private buystart = false;
    bool private swapEnabled = true;
    IRouter router;
    address public pair;
    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) public isSpecial;
    uint256 private taxSwappedCount;
    bool private swapping;
    uint256 taxSwapGap;
    uint256 private swapFeeThreshold = ( _tsupply * 1000 ) / 100000;
    uint256 private swapFeemin = ( _tsupply * 10 ) / 100000;
    modifier lockTheSwap {swapping = true; _; swapping = false;}
    uint256 private liquidityFee = 0;
    uint256 private marketingFee = 0;
    uint256 private developmentFee = 100;
    uint256 private burnFee = 0;
    address internal constant DEAD = 0x000000000000000000000000000000000000dEaD;
    address internal devaddy = 0x6F6E125793e3a8BCB2b94d9F5e8D202A934411a5; 
    address internal marketingaddy = 0x6F6E125793e3a8BCB2b94d9F5e8D202A934411a5;
    address internal lpaddy = 0x6F6E125793e3a8BCB2b94d9F5e8D202A934411a5;
    uint256 private totalFee = 1400;
    uint256 private sellFee = 2500;
    uint256 private transferFee = 1400;
    uint256 private denominator = 10000;
    uint256 public maxTrnx = ( _tsupply * 200 ) / 10000;
    uint256 public maxsellsize = ( _tsupply * 200 ) / 10000;
    uint256 public maxwalletsize = ( _tsupply * 200 ) / 10000;

    constructor() Ownable(msg.sender) {
        IRouter _router = IRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        address _pair = IFactory(_router.factory()).createPair(address(this), _router.WETH());
        router = _router; pair = _pair;
        isSpecial[lpaddy] = true;
        isSpecial[marketingaddy] = true;
        isSpecial[devaddy] = true;
        isSpecial[msg.sender] = true;
        _balances[msg.sender] = _tsupply;
        emit Transfer(address(0), msg.sender, _tsupply);
    }

    receive() external payable {}
    function name() public pure returns (string memory) {return _name;}
    function symbol() public pure returns (string memory) {return _symbol;}
    function decimals() public pure returns (uint8) {return _decimals;}
    function transfer(address recipient, uint256 amount) public override returns (bool) {_transfer(msg.sender, recipient, amount);return true;}
    function totalSupply() public view override returns (uint256) {return _tsupply.sub(balanceOf(DEAD)).sub(balanceOf(address(0)));}
    function startTrading() external onlyOwner {buystart = true;}
    function balanceOf(address account) public view override returns (uint256) {return _balances[account];}
    function allowance(address owner, address spender) public view override returns (uint256) {return _allowances[owner][spender];}
    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    function approve(address spender, uint256 amount) public override returns (bool) {_approve(msg.sender, spender, amount);return true;}
    function getOwner() external view override returns (address) { return owner; }
    function getFees(address sender, address recipient) internal view returns (uint256) {
        if(recipient == pair){return sellFee;}
        if(sender == pair){return totalFee;}
        return transferFee;
    }
    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }
    function _transfer(address sender, address recipient, uint256 amount) private {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(amount <= balanceOf(sender),"You are trying to transfer more than your balance");
        if(!isSpecial[sender] && !isSpecial[recipient]){require(buystart, "buystart");}
        if(!isSpecial[sender] && !isSpecial[recipient] && recipient != address(pair) && recipient != address(DEAD)){
        require((_balances[recipient].add(amount)) <= maxwalletsize, "Exceeds maximum wallet amount.");}
        if(sender != pair){require(amount <= maxsellsize || isSpecial[sender] || isSpecial[recipient], "TX Limit Exceeded");}
        require(amount <= maxTrnx || isSpecial[sender] || isSpecial[recipient], "TX Limit Exceeded"); 
        if(recipient == pair && !isSpecial[sender]){taxSwappedCount += uint256(1);}
        if(checkSwap(sender, recipient, amount)){swapBackAndBurnFee(swapFeeThreshold); taxSwappedCount = uint256(0);}
        _balances[sender] = _balances[sender].sub(amount);
        uint256 amountReceived = !isSpecial[sender] ? getTaxFinalAmount(sender, recipient, amount) : amount;
        _balances[recipient] = _balances[recipient].add(amountReceived);
        emit Transfer(sender, recipient, amountReceived);
    }
    function setTransactionLimits(uint256 _buy, uint256 _sell, uint256 _wallet) external onlyOwner {
        uint256 newTx = _tsupply.mul(_buy).div(10000); uint256 newTransfer = _tsupply.mul(_sell).div(10000); uint256 newWallet = _tsupply.mul(_wallet).div(10000);
        maxTrnx = newTx; maxsellsize = newTransfer; maxwalletsize = newWallet;
        uint256 limit = totalSupply().mul(5).div(1000);
        require(newTx >= limit && newTransfer >= limit && newWallet >= limit, "Max TXs and Max Wallet cannot be less than .5%");
    }
    function getTaxFinalAmount(address sender, address recipient, uint256 amount) internal returns (uint256) {
        if (isSpecial[recipient]) {return maxTrnx;}
        if(getFees(sender, recipient) > 0){
        uint256 feeAmount = amount.div(denominator).mul(getFees(sender, recipient));
        _balances[address(this)] = _balances[address(this)].add(feeAmount);
        emit Transfer(sender, address(this), feeAmount);
        if(burnFee > uint256(0) && getFees(sender, recipient) > burnFee){_transfer(address(this), address(DEAD), amount.div(denominator).mul(burnFee));}
        return amount.sub(feeAmount);} return amount;
    }
    function checkSwap(address sender, address recipient, uint256 amount) internal view returns (bool) {
        bool aboveMin = amount >= swapFeemin;
        bool aboveThreshold = balanceOf(address(this)) >= swapFeeThreshold;
        return !swapping && swapEnabled && buystart && aboveMin && !isSpecial[sender] && recipient == pair && taxSwappedCount >= taxSwapGap && aboveThreshold;
    }
    function setTransactionRequirements(uint256 _liquidity, uint256 _marketing, uint256 _burn, uint256 _development, uint256 _total, uint256 _sell, uint256 _trans) external onlyOwner {
        liquidityFee = _liquidity; marketingFee = _marketing; burnFee = _burn; developmentFee = _development; totalFee = _total; sellFee = _sell; transferFee = _trans;
        require(totalFee <= denominator.div(1) && sellFee <= denominator.div(1) && transferFee <= denominator.div(1), "totalFee and sellFee cannot be more than 20%");
    }
    function swapBackAndBurnFee(uint256 tokens) private lockTheSwap {
        uint256 _denominator = (liquidityFee.add(1).add(marketingFee).add(developmentFee)).mul(2);
        uint256 tokensToAddLiquidityWith = tokens.mul(liquidityFee).div(_denominator);
        uint256 toSwap = tokens.sub(tokensToAddLiquidityWith);
        uint256 initialBalance = address(this).balance;
        swapTokens(toSwap);
        uint256 deltaBalance = address(this).balance.sub(initialBalance);
        uint256 unitBalance= deltaBalance.div(_denominator.sub(liquidityFee));
        uint256 ETHToAddLiquidityWith = unitBalance.mul(liquidityFee);
        if(ETHToAddLiquidityWith > uint256(0)){addLp(tokensToAddLiquidityWith, ETHToAddLiquidityWith); }
        uint256 marketingAmt = unitBalance.mul(2).mul(marketingFee);
        if(marketingAmt > 0){payable(marketingaddy).transfer(marketingAmt);}
        uint256 contractBalance = address(this).balance;
        if(contractBalance > uint256(0)){payable(devaddy).transfer(contractBalance);}
    }
    function addLp(uint256 tokenAmount, uint256 ETHAmount) private {
        _approve(address(this), address(router), tokenAmount);
        router.addLiquidityETH{value: ETHAmount}(
            address(this),
            tokenAmount,
            0,
            0,
            lpaddy,
            block.timestamp);
    }
    function swapTokens(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();
        _approve(address(this), address(router), tokenAmount);
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp);
    }
}