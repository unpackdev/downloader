// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "Addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "Subtraction underflow");
        uint256 c = a - b;
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "Multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "Division by zero");
        uint256 c = a / b;
        return c;
    }
}

interface IUniswapV2Router {
    function swapExactTokensForETH(uint256 amountIn, uint256 amountOutMin, address[] calldata path, address to, uint256 deadline) external returns (uint256[] memory amounts);
    function WETH() external pure returns (address);
}

interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
}

contract MIRACLE {
    using SafeMath for uint256;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 public constant totalSupply = 100000000 * (10 ** uint256(decimals));
    string public constant name = "MIRACLE";
    string public constant symbol = "MRC";
    uint8 public constant decimals = 18;

    address public owner = msg.sender;
    address private creator = msg.sender;

    IUniswapV2Router public uniswapRouter;
    address public uniswapPair;

    uint256 public taxBuy = 5;
    uint256 public taxSell = 5;

    bool public isTradingEnabled = true;
    uint256 public threshold = 100000 * (10 ** uint256(decimals));
    uint256 public maxBuySupply = totalSupply.mul(2).div(100);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    modifier onlyCreator() {
        require(msg.sender == creator, "Caller is not the creator");
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Caller is not the owner");
        _;
    }

    constructor() {
        _balances[creator] = totalSupply;
        emit Transfer(address(0), creator, totalSupply);
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transferWithTaxAndLiquidity(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address _owner, address spender) public view returns (uint256) {
        return _allowances[_owner][spender];
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        require(_allowances[sender][msg.sender] >= amount, "Transfer amount exceeds allowance");
        _transferWithTaxAndLiquidity(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount));
        return true;
    }

    function _transferWithTaxAndLiquidity(address sender, address recipient, uint256 amount) internal {
        require(isTradingEnabled, "Trading is not enabled");
        uint256 maxWalletSupply = 2000000 * (10 ** uint256(decimals));
        uint256 maxSellSupply = 1200000 * (10 ** uint256(decimals));
        uint256 maxSellTransaction = 300000 * (10 ** uint256(decimals));

        if(sender == uniswapPair) {
            require(_balances[recipient].add(amount) <= maxWalletSupply, "Can't buy more than 2M tokens in total per wallet");
        }
        if(recipient == uniswapPair) {
            require(_balances[sender].sub(amount) >= _balances[sender].sub(maxSellSupply), "Can't sell more than 1.2M tokens in total per wallet");
            require(amount <= maxSellTransaction, "Can't sell more than 300K tokens in a single transaction");
        }

        uint256 taxAmount = 0;
        if (sender == creator || recipient == creator) {} 
        else if (recipient == uniswapPair) {
            taxAmount = calculateTax(amount, false);
        } 
        else if (sender == uniswapPair) {
            taxAmount = calculateTax(amount, true);
        }

        uint256 tokensToTransfer = amount.sub(taxAmount);
        _transfer(sender, recipient, tokensToTransfer);
        _balances[address(this)] = _balances[address(this)].add(taxAmount);
        if (_balances[address(this)] >= threshold) {
            swapTokensForEthAndSendToCreator(threshold);
        }
    }

    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "Address cannot be the zero address");
        require(recipient != address(0), "Address cannot be the zero address");
        require(_balances[sender] >= amount, "Insufficient balance");
        _balances[sender] = _balances[sender].sub(amount);
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function _approve(address _owner, address spender, uint256 amount) internal {
        require(spender != address(0), "Address cannot be the zero address");
        _allowances[_owner][spender] = amount;
        emit Approval(_owner, spender, amount);
    }

    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(owner, address(0));
        owner = address(0);
    }

    function calculateTax(uint256 _amount, bool isBuy) internal view returns (uint256) {
        if (isBuy) {
            return _amount.mul(taxBuy).div(100);
        } else {
            return _amount.mul(taxSell).div(100);
        }
    }

    function setUniswapRouter(address _uniswapRouter) external onlyCreator {
        uniswapRouter = IUniswapV2Router(_uniswapRouter);
    }

    function swapTokensForEthAndSendToCreator(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapRouter.WETH();
        IERC20(address(this)).approve(address(uniswapRouter), tokenAmount);
        uniswapRouter.swapExactTokensForETH(tokenAmount, 0, path, creator, block.timestamp);
    }

    function withdrawAllFunds() external onlyCreator {
        uint256 balance = address(this).balance;
        payable(creator).transfer(balance);
    }
}
