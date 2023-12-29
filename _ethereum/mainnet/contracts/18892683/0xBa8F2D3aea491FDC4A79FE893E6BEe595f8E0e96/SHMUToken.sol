// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "./Address.sol";
import "./SafeMath.sol";
import "./Ownable.sol";
import "./IERC20.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Router.sol";
import "./IUniswapV2Pair.sol";

// https://shibamemu.com/
// https://twitter.com/shibamemu
// https://t.me/ShibaMemu
// https://discord.gg/uar6GcWTtj
// https://www.reddit.com/r/ShibaMemu/

contract SHMUToken is IERC20, Ownable {
    using Address for address;
    using SafeMath for uint256;
    string private _name = "Shiba Memu";
    string private _symbol = "SHMU";
    uint8 private _decimals = 18;
    uint256 private _totalSupply = 100000000000 * (10 ** _decimals);
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _isExcludedFromFee;
    address private _marketingWallet;
    IUniswapV2Router private _dexRouter = IUniswapV2Router(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    IUniswapV2Pair private _dexPair;
    uint256 private _buyFee = 20;
    uint256 private _sellFee = 25;
    uint private _nextSwapTS;
    bool private _swapping = false;

    receive() external payable {}

    constructor() {
        _marketingWallet = owner();
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[0x000000000000000000000000000000000000dEaD] = true;
        _balances[owner()] = _totalSupply;
        _nextSwapTS = block.timestamp + 1 hours;
        emit Transfer(address(0), owner(), _totalSupply);
    }

    function name() external view override returns (string memory) {
        return _name;
    }

    function symbol() external view override returns (string memory) {
        return _symbol;
    }

    function decimals() external view override returns (uint8) {
        return _decimals;
    }

    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    function buyFee() external view returns (uint256) {
        return _buyFee;
    }

    function sellFee() external view returns (uint256) {
        return _sellFee;
    }

    function dexPair() external view returns (address) {
        return address(_dexPair);
    }

    function taxWallet() external view returns (address) {
        return _marketingWallet;
    }

    function balanceOf(address account) external view override returns (uint256) {
        return _balances[account];
    }

    function isExcludedFromTax(address account) external view returns (bool) {
        return _isExcludedFromFee[account];
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) external view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) external override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        if (_allowances[sender][_msgSender()] != type(uint256).max) {
            _allowances[sender][_msgSender()] = _allowances[sender][msg.sender]
                .sub(amount, "Token: transfer amount exceeds allowance");
        }
        _transfer(sender, recipient, amount);
        return true;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "Token: approve from the zero address");
        require(spender != address(0), "Token: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _swapTokensForETH(uint256 tokenAmount) private returns (bool) {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _dexRouter.WETH();
        _approve(address(this), address(_dexRouter), tokenAmount);
        _dexRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
        _nextSwapTS = block.timestamp + 4 hours;
        if (_sellFee > 5) {
            _sellFee = _sellFee.sub(1);
        }
        return true;
    }

    function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0), "Token: Transfer from the zero address");
        require(to != address(0), "Token: Transfer to the zero address");
        require(amount > 0, "Token: Transfer amount must be greater than zero");
        bool takeFee = true;
        if (_isExcludedFromFee[from] || _isExcludedFromFee[to]) {
            takeFee = false;
        }
        if (!_swapping && takeFee) {
            uint256 fee = (to == address(_dexPair)) ? _sellFee : _buyFee;
            bool canSwap = (block.timestamp > _nextSwapTS) && (_balances[address(this)] > _balances[address(_dexPair)].div(200));
            if (canSwap && from != address(_dexPair)) {
                _swapping = true;
                _swapTokensForETH(_balances[address(_dexPair)].div(200));
                _swapping = false;
            } else {
                if ((_buyFee > 5) && (from == address(_dexPair))) {
                    _buyFee = _buyFee.sub(1);
                }
            }
            uint256 txFee = amount.div(100).mul(fee);
            amount = amount.sub(txFee);
            _balances[from] = _balances[from].sub(txFee, "Token: Transfer amount exceeds balance");
            _balances[address(this)] = _balances[address(this)].add(txFee);
            emit Transfer(from, address(this), txFee);
        }
        _balances[from] = _balances[from].sub(amount, "Token: Transfer amount exceeds balance");
        _balances[to] = _balances[to].add(amount);
        emit Transfer(from, to, amount);
    }

    function addLiquidity() external payable onlyOwner returns (bool) {
        require(address(_dexPair) == address(0), "Token: LP created");
        require(msg.value > 0, "Token: No ETH");
        _allowances[address(this)][address(_dexRouter)] = type(uint256).max;
        _dexPair = IUniswapV2Pair(IUniswapV2Factory(_dexRouter.factory()).createPair(address(this), _dexRouter.WETH()));
        _dexRouter.addLiquidityETH{value: msg.value}(
            address(this),
            _balances[address(this)],
            0,
            0,
            _msgSender(),
            block.timestamp
        );
        _dexPair.sync();
        return true;
    }

    function withdrawETH() external returns (bool) {
        require(_msgSender() == _marketingWallet, "Token: only marketing wallet");
        bool success = _marketingWallet.transfer(address(this).balance);
        return success;
    }

    function updateMarketingWallet(address wallet) external returns (bool) {
        require(_msgSender() == _marketingWallet, "Token: only marketing wallet");
        _marketingWallet = wallet;
        return true;
    }
}