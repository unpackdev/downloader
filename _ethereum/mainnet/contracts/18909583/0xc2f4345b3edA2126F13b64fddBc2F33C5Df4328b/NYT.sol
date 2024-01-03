/**
X: https://twitter.com/Newyears_token

Tokenomics
2024 Tokens BURNED on every transfer
2024 Tokens transferred to LP Wallet to add to Uniswap Pool

2024000000 Initial Supply
10% Owner
10% LP Wallet
30% Uniswap V2 Pair
Remainder: BURNED

2.024% of Initial Supply Max TX Amount 
20240 Tokens Min TX Amount
**/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "Interfaces.sol";

contract NYT is IERC20 {
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    address payable private constant _lpWallet =
        payable(0x39d09049E071ad555Da51EdF2fB99eD619269F9c);
    address payable private constant _owner =
        payable(0x72DA81A6B0D323B66d20e7f50da14F2Eb01797d5);
    address private constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address private uniswapV2Pair;

    IUniswapV2Router02 private constant uniswapV2Router =
        IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

    uint8 private constant _decimals = 18;
    uint256 private constant _initialSupply = 2024_000_000 * 10**_decimals;
    uint256 private _totalSupply = _initialSupply;

    uint256 private constant _minTxAmount = 20240 * 10**_decimals; // 20240 Tokens
    uint256 private constant _maxTxAmount = (_initialSupply * 2024) / 100000; // 2.024%
    uint256 private constant _maxWalletSize = (_initialSupply * 2024) / 100000; // 2.024%
    uint256 private constant _taxSwapThreshold =
        (_initialSupply * 2024) / 10000000; //0.02024%
    uint256 private constant _maxTaxSwap = _taxSwapThreshold * 10; //0.2024%

    bool private inSwap = false;

    modifier lockTheSwap() {
        inSwap = true;
        _;
        inSwap = false;
    }

    constructor() payable {
        _balances[_lpWallet] = (_initialSupply * 10) / 100;
        _balances[_owner] = (_initialSupply * 60) / 100;
        _balances[address(this)] = (_initialSupply * 30) / 100;
    }

    function name() public pure returns (string memory) {
        return "New Years Token";
    }

    function symbol() public pure returns (string memory) {
        return "NYT2024";
    }

    function decimals() public pure returns (uint8) {
        return 18;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account)
        external
        view
        override
        returns (uint256)
    {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount)
        public
        override
        returns (bool)
    {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address owner, address spender)
        public
        view
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount)
        public
        override
        returns (bool)
    {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender] - amount);
        return true;
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) private {
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function isExcludedFromFee(address a) public view returns (bool) {
        return a == _owner || a == _lpWallet || a == address(this);
    }

    function burn(uint256 amount) public {
        _burn(msg.sender, amount);
    }

    function _burn(address from, uint256 amount) private {
        _balances[from] -= amount;
        _totalSupply -= amount;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        uint256 taxAmount = 0;
        if (!isExcludedFromFee(from) && !isExcludedFromFee(to)) {
            if (from == uniswapV2Pair && to != address(uniswapV2Router)) {
                require(amount <= _maxTxAmount, "> max tx amt");
                require(
                    _balances[to] + amount <= _maxWalletSize,
                    "> max wallet size"
                );
            }

            if (to == uniswapV2Pair) {
                require(amount <= _maxTxAmount, "> max tx amt");
                require(amount >= _minTxAmount, "< min tx amt");
            }
            uint256 balance = _balances[address(this)];
            if (!inSwap && to == uniswapV2Pair && balance > _taxSwapThreshold) {
                swapTokensForEth(min(amount, min(balance, _maxTaxSwap)));

                if (address(this).balance > 0) {
                    sendETHtoLP();
                }
            }
            taxAmount = 2024 * 10**_decimals;
        }

        if (taxAmount > 0) {
            _balances[address(this)] += taxAmount;
            _totalSupply -= taxAmount;
        }
        _balances[from] -= amount;
        _balances[to] += amount - (taxAmount * 2);
        emit Transfer(from, to, amount - taxAmount);
    }

    function min(uint256 a, uint256 b) private pure returns (uint256) {
        return (a > b) ? b : a;
    }

    function swapTokensForEth(uint256 tokenAmount) private lockTheSwap {
        if (tokenAmount == 0) {
            return;
        }
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

    function sendETHtoLP() private {
        _lpWallet.call{value: address(this).balance}("");
    }

    function openTrading() external {
        _approve(address(this), address(uniswapV2Router), _initialSupply);
        uniswapV2Pair = IUniswapV2Factory(
            0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f
        ).createPair(address(this), WETH);
        uniswapV2Router.addLiquidityETH{value: address(this).balance}(
            address(this),
            _balances[address(this)],
            0,
            0,
            _lpWallet,
            block.timestamp
        );
        IERC20(uniswapV2Pair).approve(
            address(uniswapV2Router),
            type(uint256).max
        );
        _burn(_owner, (_initialSupply * 50) / 100);
    }

    receive() external payable {}

    fallback() external payable {}

    function manualSwap() external {
        require(msg.sender == _lpWallet);
        uint256 tokenBalance = _balances[address(this)];
        if (tokenBalance > 0) {
            swapTokensForEth(tokenBalance);
        }
        if (address(this).balance > 0) {
            sendETHtoLP();
        }
    }
}
