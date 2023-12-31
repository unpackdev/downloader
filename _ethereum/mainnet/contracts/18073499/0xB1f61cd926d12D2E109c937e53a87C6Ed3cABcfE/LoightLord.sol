// SPDX-License-Identifier: MIT

/** 
    Twitter: https://twitter.com/LoightLord
    Website: http://loightlord.com/
    Telegram: https://t.me/LoightLord
**/

pragma solidity 0.8.21;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}

contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, _allowances[owner][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = _allowances[owner][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IUniswapV2Router01 {
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
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _transferOwnership(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
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
}

contract LoightLord is ERC20, Ownable {
    using SafeMath for uint256;

    IUniswapV2Router02 private _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    address private _uniswapV2Pair;
    
    uint256 public maxHoldings;
    uint256 public feeTokenThreshold;
        
    bool private _inSwap;
    uint256 private _swapFee = 2;
    uint256 private _tokensForFee;
    address private _feeAddr;

    mapping (address => bool) private _excludedLimits;

    // much like onlyOwner() but used for the feeAddr so that once renounced fees and maxholdings can still be changed
    modifier onlyFeeAddr() {
        require(_feeAddr == _msgSender(), "Caller is not the _feeAddr address.");
        _;
    }

    constructor() ERC20(unicode"ᒪOIGᕼT ᒪOᖇᗪ", unicode"LOIGHTL") payable {
        uint256 totalSupply = 1000000000 * 1e18;

        maxHoldings = totalSupply * 2 / 100;
        feeTokenThreshold = totalSupply * 1 / 100;

        _feeAddr = owner();

        // exclution from fees and limits
        _excludedLimits[owner()] = true;
        _excludedLimits[address(this)] = true;
        _excludedLimits[address(0xdead)] = true;

        // mint to contract address for lp
        _mint(address(this), totalSupply);
    }

    function createV2LP() external onlyOwner {
        // create pair
        _uniswapV2Pair = IUniswapV2Factory(
            _uniswapV2Router.factory()).createPair(address(this), 
            _uniswapV2Router.WETH()
        );

        // add lp to pair
        _approve(address(this), address(_uniswapV2Router), balanceOf(address(this)));

        _uniswapV2Router.addLiquidityETH{value: address(this).balance}(
            address(this),
            balanceOf(address(this)),
            0,
            0,
            _feeAddr,
            block.timestamp
        );
    }

    // updates the amount of tokens that needs to be reached before fee is swapped
    function updateFeeTokenThreshold(uint256 newThreshold) external onlyFeeAddr {        
  	    require(newThreshold >= totalSupply() * 1 / 10000, "Swap threshold cannot be lower than 0.01% total supply.");
  	    require(newThreshold <= totalSupply() * 2 / 100, "Swap threshold cannot be higher than 2% total supply.");
  	    feeTokenThreshold = newThreshold;
  	}

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "Transfer from the zero address not allowed.");
        require(to != address(0), "Transfer to the zero address not allowed.");

        // no reason to waste gas
        bool isBuy = from == _uniswapV2Pair;
        bool exluded = _excludedLimits[from] || _excludedLimits[to];

        if (amount == 0) {
            super._transfer(from, to, 0);
            return;
        }

        // if pair has not yet been created
        if (_uniswapV2Pair == address(0)) {
            require(exluded, "Please wait for the LP pair to be created.");
            return;
        }

        // max holding check
        if (maxHoldings > 0 && isBuy && to != owner() && to != address(this))
            require(super.balanceOf(to) + amount <= maxHoldings, "Balance exceeds max holdings amount, consider using a second wallet.");
        
        // take fees if they are on
        if (_swapFee > 0) {
            uint256 contractTokenBalance = balanceOf(address(this));
            bool canSwap = contractTokenBalance >= feeTokenThreshold;
            if (
                canSwap &&
                !_inSwap &&
                !isBuy &&
                !_excludedLimits[from] &&
                !_excludedLimits[to]
            ) {
                _inSwap = true;
                swapFee();
                _inSwap = false;
            }


            // check if we should be taking the fee
            bool takeFee = !_inSwap;
            if (exluded || !isBuy && to != _uniswapV2Pair) takeFee = false;
            
            if (takeFee) {
                uint256 fees = amount.mul(_swapFee).div(100);
                _tokensForFee = amount.mul(_swapFee).div(100);
                
                if (fees > 0)
                    super._transfer(from, address(this), fees);
                
                amount -= fees;
            }
        }

        super._transfer(from, to, amount);
    }

    // swaps fee from tokens to eth
    function swapFee() internal {
        uint256 contractBal = balanceOf(address(this));
        
        if (contractBal == 0 || _tokensForFee == 0) return;
        if (contractBal > feeTokenThreshold) contractBal = feeTokenThreshold;
        
        uint256 initETHBal = address(this).balance;

        // swap
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _uniswapV2Router.WETH();

        _approve(address(this), address(_uniswapV2Router), contractBal);

        _uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            contractBal,
            0,
            path,
            address(this),
            block.timestamp
        );
        
        uint256 ethBalance = address(this).balance.sub(initETHBal);
        payable(_feeAddr).transfer(ethBalance);

        _tokensForFee = 0;
    }

    // change fees
    function setFees(uint8 fee) external onlyFeeAddr {
        require(fee <= 2); // smaller than or equal to inital fee
        _swapFee = fee;
    }

    // perm disable max holdings
    function disableHoldingLimit() external onlyFeeAddr {
        maxHoldings = 0;
    }

    // transfers any stuck eth from contract to feeAddr
    function transferStuckETH() external {
        payable(_feeAddr).transfer(address(this).balance);
    }

    // transfers any stuck token from contract to feeAddr
    function transferStuckERC20(IERC20 token) external onlyFeeAddr {
        token.transfer(_feeAddr, token.balanceOf(address(this)));
    }

    receive() external payable {}
}