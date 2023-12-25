// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.20;

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB)
    external
    returns (address pair);
}

interface IUniswapV2Router02 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external
    returns (
        uint256 amountA,
        uint256 amountB,
        uint256 liquidity
    );
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

contract UmToken is Ownable {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    uint8 public decimals = 18;
    string public name = "UMI";
    string public symbol = "UMI";
    uint256 public totalSupply = 100000000 * 10 ** 18;
    uint256 public constant NOT_BOT_IDENTIFY_BLOCK = 6;
    mapping(address => bool) public ammPairs;
    mapping(address => bool) public isExcludedFromFee;
    bool public inSwapAndLiquify = false;
    uint256 public exStartBlock = 0;
    uint public mkTxAmount = 5 * 10 ** 18;
    address public uniswapV2Router;

    address public lpFeeAddr;
    address public burnFeeAddr;
    address public minerFeeAddr;
    address public uniswapV2Pair;
    uint256 public lpFeeRate = 5;
    uint256 public burnFeeRate = 5;
    uint256 public minerFeeRate = 40;
    uint256 public constant FEE_RATE = 1000;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) private _allowances;

    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) private {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        address spender = _msgSender();
        _spendAllowance(sender, spender, amount);
        _transfer(sender, recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(_msgSender(), spender, amount);
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

    constructor (address router_, address lpFeeAddr_, address burnFeeAddr_, address minerFeeAddr_) Ownable(_msgSender()) {
        lpFeeAddr = lpFeeAddr_;
        burnFeeAddr = burnFeeAddr_;
        minerFeeAddr = minerFeeAddr_;
        uniswapV2Router = router_;
        uniswapV2Pair = IUniswapV2Factory(IUniswapV2Router02(router_).factory())
            .createPair(address(this), IUniswapV2Router02(router_).WETH());
        ammPairs[uniswapV2Pair] = true;

        isExcludedFromFee[_msgSender()] = true;
        isExcludedFromFee[address(this)] = true;
        balanceOf[_msgSender()] = totalSupply;
        emit Transfer(address(0), _msgSender(), totalSupply);
    }

    function _tokenTransfer(address sender, address recipient, uint256 tAmount) private {
        balanceOf[sender] = balanceOf[sender] - tAmount;
        balanceOf[recipient] = balanceOf[recipient] + tAmount;
        emit Transfer(sender, recipient, tAmount);
    }

    function _transferWithFee(address from, address to, uint256 amount, bool takeFee, bool botFee) private {
        uint256 _lpFeeRate = lpFeeRate;
        uint256 _burnFeeRate = burnFeeRate;
        uint256 _minerFeeRate = minerFeeRate;
        if (botFee) {
            _lpFeeRate = _lpFeeRate * 6;
            _burnFeeRate = _burnFeeRate * 6;
            _minerFeeRate = _minerFeeRate * 6;
        }
        if (takeFee) {
            uint256 lpFee = amount * _lpFeeRate / FEE_RATE;
            _tokenTransfer(from, address(this), lpFee);
            uint256 burnFee = amount * _burnFeeRate / FEE_RATE;
            _tokenTransfer(from, address(this), burnFee);
            uint256 minerFee = amount * _minerFeeRate / FEE_RATE;
            _tokenTransfer(from, address(this), minerFee);
            amount = amount - lpFee - burnFee - minerFee;
        }
        _tokenTransfer(from, to, amount);
    }

    function _swapTokensToMarket(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = IUniswapV2Router02(uniswapV2Router).WETH();
        _approve(address(this), uniswapV2Router, tokenAmount);
        IUniswapV2Router02(uniswapV2Router).swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
        // transfer eth
        uint256 amount = address(this).balance;
        uint256 totalFeeRate = lpFeeRate + burnFeeRate + minerFeeRate;
        payable(lpFeeAddr).transfer(amount * lpFeeRate / totalFeeRate);
        payable(burnFeeAddr).transfer(amount * burnFeeRate / totalFeeRate);
        payable(minerFeeAddr).transfer(amount * minerFeeRate / totalFeeRate);
    }

    receive() external payable {
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        bool botFee = false;
        bool takeFee = false;

        if (ammPairs[from] || ammPairs[to]) {
            if (!isExcludedFromFee[from] && !isExcludedFromFee[to]) {
                require(exStartBlock > 0 && exStartBlock < block.number, "Exchange not allow");
                if (block.number - exStartBlock < NOT_BOT_IDENTIFY_BLOCK) {
                    botFee = true;
                }
            }
        }
        if (from != address(this)
            && !inSwapAndLiquify
            && !ammPairs[from]
            && !isExcludedFromFee[from]
            && !isExcludedFromFee[to]
        ) {
            inSwapAndLiquify = true;
            if (balanceOf[address(this)] >= mkTxAmount) {
                uint v = balanceOf[address(this)];
                _swapTokensToMarket(v);
            }
            inSwapAndLiquify = false;
        }
        if (ammPairs[from] && !isExcludedFromFee[to]) {
            takeFee = true;
        }
        if (ammPairs[to] && !isExcludedFromFee[from]) {
            takeFee = true;
        }
        _transferWithFee(from, to, amount, takeFee, botFee);
    }

    function setExchangeBlock(uint256 exStartBlock_) public onlyOwner {
        exStartBlock = exStartBlock_;
    }

    function setExcludedFromFee(address account, bool status) public onlyOwner {
        isExcludedFromFee[account] = status;
    }

    function setAmmPair(address pair, bool status) public onlyOwner {
        ammPairs[pair] = status;
    }

    function setAddrs(
        address lpFeeAddr_,
        address burnFeeAddr_,
        address minerFeeAddr_
    ) public onlyOwner {
        lpFeeAddr = lpFeeAddr_;
        burnFeeAddr = burnFeeAddr_;
        minerFeeAddr = minerFeeAddr_;
    }
}
