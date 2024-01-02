// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./SafeMath.sol";
import "./Ownable.sol";
import "./IERC20.sol";
import "./IUniswapV2Pair.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Router.sol";

contract MeMeStreet is IERC20, Ownable {
    using SafeMath for uint256;
    IUniswapV2Router public uniswapV2Router;
    IUniswapV2Pair public uniswapV2Pair;
    string private _name = "MeMe Street";
    string private _symbol = "MMS";
    uint8 private _decimals = 18;
    bool public swapEnabled = false;
    bool private _swapping = false;
    uint256 private _totalSupply = 100000000000 * (10 ** _decimals);
    uint256 private _fee = 3;
    address private _marketingWallet;
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _isExcludedFromFee;

    constructor() {
        _marketingWallet = owner();
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[0x000000000000000000000000000000000000dEaD] = true;
        _balances[owner()] = _totalSupply;
        emit Transfer(address(0), owner(), _totalSupply);
    }

    receive() external payable {}

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

    function fee() external view returns (uint256) {
        return _fee;
    }

    function marketingWallet() external view returns (address) {
        return _marketingWallet;
    }

    function balanceOf(
        address account
    ) external view override returns (uint256) {
        return _balances[account];
    }

    function isExcludedFromFee(address account) external view returns (bool) {
        return _isExcludedFromFee[account];
    }

    function transfer(
        address recipient,
        uint256 amount
    ) external override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(
        address owner,
        address spender
    ) external view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(
        address spender,
        uint256 amount
    ) external override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external override returns (bool) {
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

    function swapTokensForETH(uint256 tokenAmount) private returns (bool) {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            _marketingWallet,
            block.timestamp
        );
        return true;
    }

    function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0), "Token: Transfer from the zero address");
        require(to != address(0), "Token: Transfer to the zero address");
        require(amount > 0, "Token: Transfer amount must be greater than zero");
        require(
            swapEnabled || from == owner(),
            "Token: Public transfer has not yet been activated"
        );
        bool takeFee = true;
        if (_isExcludedFromFee[from] || _isExcludedFromFee[to]) {
            takeFee = false;
        }
        if (!_swapping && takeFee) {
            bool canSwap = _balances[address(this)] >
                _balances[address(uniswapV2Pair)].div(500);
            if (canSwap) {
                if (from != address(uniswapV2Pair)) {
                    _swapping = true;
                    swapTokensForETH(
                        _balances[address(uniswapV2Pair)].div(500)
                    );
                    _swapping = false;
                }
            }
            uint256 txFee = amount.div(100).mul(_fee);
            amount = amount.sub(txFee);
            _balances[from] = _balances[from].sub(
                txFee,
                "Token: Transfer amount exceeds balance"
            );
            _balances[address(this)] = _balances[address(this)].add(txFee);
            emit Transfer(from, address(this), txFee);
        }
        _balances[from] = _balances[from].sub(
            amount,
            "Token: Transfer amount exceeds balance"
        );
        _balances[to] = _balances[to].add(amount);
        emit Transfer(from, to, amount);
    }

    function createPair(address _router) external onlyOwner {
        uniswapV2Router = IUniswapV2Router(_router);
        _allowances[address(this)][_router] = type(uint256).max;
        uniswapV2Pair = IUniswapV2Pair(
            IUniswapV2Factory(uniswapV2Router.factory()).createPair(
                address(this),
                uniswapV2Router.WETH()
            )
        );
    }

    function enableSwap() external onlyOwner returns (bool) {
        require(!swapEnabled, "Token: PublicSwap is already enabeled");
        require(
            address(uniswapV2Router) != address(0),
            "Token: Router not set"
        );
        swapEnabled = true;
        return swapEnabled;
    }
}
