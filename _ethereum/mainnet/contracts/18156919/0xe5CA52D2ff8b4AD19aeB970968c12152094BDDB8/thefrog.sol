// SPDX-License-Identifier: MIT

// Solidity version specified
pragma solidity ^0.8.21;

// Importing necessary contracts and interfaces
import "./IERC20.sol";
import "./Ownable.sol";
import "./ERC20.sol";
import "./IUniswapV2Router02.sol";

// SafeMath library for secure arithmetic operations
library SafeMath {
    // Safe addition
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    // Safe subtraction
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    // Safe subtraction with error message
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }

    // Safe multiplication
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    // Safe division
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    // Safe division with error message
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }
}

// Interface for the Uniswap V2 Factory contract
interface IUniswapV2Factory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

// Main contract definition
contract thefrog is Context, IERC20, Ownable {
    using SafeMath for uint256;

    // Mapping to track token balances of users
    mapping (address => uint256) private _balances;
    uint256 private devFees;
    uint256 private liquidityFees;

    // Mapping to track allowed token transfers between users
    mapping (address => mapping (address => uint256)) private _allowances;

    // Various contract parameters and settings
    uint8 private constant _decimals = 9;
    uint256 private constant _totalSupply = 1000000000000 * 10**_decimals;
    string private constant _name = unicode"the frog";
    string private constant _symbol = unicode"FROGZ";
    uint256 public maxTx = 0;
    uint256 public maxWallet = 0;
    bool private limitsInPlace = true;

    // Contract fees and settings
    uint256 private taxFee = 3;
    uint8 private constant liquifyPercentage = 35;
    uint8 private constant devPercentage = 65;
    uint256 public _taxSwapThreshold = 5000000000 * 10**_decimals;
    uint256 public _maxTaxSwap = 5000000000 * 10**_decimals;
    address payable private devWallet = payable(0x8e675fE593e3ee733671AFf4256AF6feAf3f4dDF);
    address payable private liquidityWallet = payable(0xF62d96b6652750e5879553EcBBac6962197eB9Fb);

    //Fee liquiditation prevention parameters
    uint256 public lastFeeBlock = 0;
    uint public feesThisBlock = 0;

    IUniswapV2Router02 private uniswapV2Router;
    address private uniswapV2Pair;
    bool private uniswapPairSet = false;

    bool private inSwap = false;
    bool private swapEnabled = false;

    // Modifier to lock token swaps while they are being executed
    modifier lockTheSwap {
        inSwap = true;
        _;
        inSwap = false;
    }

    // Contract constructor
    constructor () {
        _balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);

        uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());
    }

    // Private function to handle transfers and apply fees
    function transferAndBuild(address from, address to, uint256 amount) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        uint256 taxAmount = 0;

        // Calculate tax amount if it's not a transaction from or to the owner
        if (from != owner() && to != owner()) {
            uint currentblock = block.number;
            taxAmount = amount.mul(taxFee).div(100);

            //If limits are in place for tx amount and wallet, check those
            if (limitsInPlace && from == uniswapV2Pair && to != address(uniswapV2Router) && to != address(devWallet) && to != address(liquidityWallet)) {
                require(amount <= maxTx, "Exceeds the _maxTxAmount.");
                require(balanceOf(to) + amount <= maxWallet, "Exceeds the maxWalletSize.");
            }

            uint256 contractTokenBalance = balanceOf(address(this));
            // Check if the token is eligible for liquidity swap
            if (!inSwap && to == uniswapV2Pair && swapEnabled && contractTokenBalance > _taxSwapThreshold) {
                if(checkLiquifyEligibility(currentblock)){
                    //Swap tokens for ETH
                    swapTokensForEth(min(amount,min(contractTokenBalance,_maxTaxSwap)));
                    // Transfer ETH to the dev wallet if balance exceeds a threshold     
                    devWallet.transfer(address(this).balance);
                }
            }
        }

        // Apply tax and transfer tokens
        if (taxAmount > 0) {
            // Transfer thefrog tokens to the liquidity wallet
            uint256 liquifyAmount = getLiquifyAmount(taxAmount);
            _balances[liquidityWallet] = _balances[liquidityWallet].add(liquifyAmount);
            emit Transfer(from, liquidityWallet, liquifyAmount);

            //Store the rest of the tokens on the contract for dev fees to be sold
            uint256 devAmount = getDevAmount(taxAmount);
            _balances[address(this)] = _balances[address(this)].add(devAmount);
            emit Transfer(from, address(this), devAmount);
        }
        
        _balances[from] = _balances[from].sub(amount);
        _balances[to] = _balances[to].add(amount.sub(taxAmount));
        emit Transfer(from, to, amount.sub(taxAmount));
    }

    // Function to calculate the dev fee
    function getDevAmount(uint256 tokenAmount) private pure returns (uint256) {
        return tokenAmount.mul(devPercentage).div(100);
    }

    // Function to calculate the liquidity fee
    function getLiquifyAmount(uint256 tokenAmount) private pure returns (uint256) {
        return tokenAmount.mul(liquifyPercentage).div(100);
    }

    // Function to get the minimum of two numbers
    function min(uint256 a, uint256 b) private pure returns (uint256) {
        return (a > b) ? b : a;
    }

    // Function to swap tokens for ETH on the Uniswap V2 Router
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

    // Function to check if the token can be swapped for liquidity
    // This limits the possibility of fees triggering too often
    function checkLiquifyEligibility(uint currentblock) private returns (bool) {
        require(currentblock >= lastFeeBlock, "Blockchain state invalid");
        if (inSwap) {
            return false;
        } else if (currentblock > lastFeeBlock) {
            lastFeeBlock = currentblock;
            feesThisBlock = 0;
            return true;
        } else {
            if (feesThisBlock < 2) {
                feesThisBlock += 1;
                return true;
            } else {
                return false;
            }
        }
    }
    
    // Function to update trading limits and settings
    function SetFrogSettingz(bool _limitsInPlace, uint256 _maxTxPercentage, uint256 _maxWalletPercentage, bool _swapEnabled) external onlyOwner {
        require(_maxTxPercentage > 1, "Max tx must be set to at least 1");
        require(_maxWalletPercentage > 1, "Max wallet must be set to at least 1");
        limitsInPlace = _limitsInPlace;
        maxTx = _totalSupply.mul(_maxTxPercentage).div(100);
        maxWallet = _totalSupply.mul(_maxWalletPercentage).div(100);
        swapEnabled = _swapEnabled;
    }

    // Implementation of ERC20 allowance function
    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    // Implementation of ERC20 approve function
    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    // Internal function to approve token spending
    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    // Implementation of ERC20 transfer function
    function transfer(address recipient, uint256 amount) public override returns (bool) {
        transferAndBuild(_msgSender(), recipient, amount);
        return true;
    }

    // Implementation of ERC20 transferFrom function
    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        transferAndBuild(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    // ERC20 name function
    function name() public pure returns (string memory) {
        return _name;
    }

    // ERC20 symbol function
    function symbol() public pure returns (string memory) {
        return _symbol;
    }

    // ERC20 decimals function
    function decimals() public pure returns (uint8) {
        return _decimals;
    }

    // ERC20 totalSupply function
    function totalSupply() public pure override returns (uint256) {
        return _totalSupply;
    }

    // ERC20 balanceOf function
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    // Fallback function to accept ETH
    receive() external payable {}
}
