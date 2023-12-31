// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./Ownable.sol";
import "./IUniswapV2Factory.sol";
import "./ERC20.sol";
import "./SafeMath.sol";
import "./IUniswapV2Router02.sol";

contract Babylicious is ERC20, Ownable {
    using SafeMath for uint256;

    IUniswapV2Router02 public router;
    address public pair;

    bool private swapping;

    uint256 public swapTokensAtAmount;
    uint256 public maxWalletLimit;
    uint256 public maxTxAmount;

    uint8 public marketingFee = 15;
    uint16 internal totalFees = marketingFee;

    bool public isTradingEnabled;

    address payable public _marketingWallet = payable(address(0x7ba428B74b08c1358052248a4ca5E00BAAe82a29));

    mapping(address => bool) private _isExcludedFromFees;
    mapping(address => bool) public automatedMarketMakerPairs;

    event UpdateRouter(address indexed newAddress, address indexed oldAddress);
    event ExcludeFromFees(address indexed account, bool isExcluded);
    event ExcludeMultipleAccountsFromFees(address[] accounts, bool isExcluded);
    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);
    event SwapAndLiquify(uint256 tokensSwapped, uint256 ethReceived, uint256 tokensIntoLiqudity);

    constructor() ERC20("Babylicious", "Belicious") {
        IUniswapV2Router02 _router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

        address _pair = IUniswapV2Factory(_router.factory()).createPair(address(this), _router.WETH());

        router = _router;
        pair = _pair;

        _setAutomatedMarketMakerPair(_pair, true);

        // exclude from paying fees or having max transaction amount
        excludeFromFees(owner(), true);
        excludeFromFees(address(this), true);

        /*
            _mint is an internal function in ERC20.sol that is only called here,
            and CANNOT be called ever again
        */
        _mint(owner(), 1 * 10 ** 12 * (10 ** 18));
        maxWalletLimit = totalSupply().mul(2).div(100);
        maxTxAmount = totalSupply().mul(2).div(100);
        swapTokensAtAmount = totalSupply().mul(1).div(10000);
    }

    receive() external payable {
        this;
    }

    function updateRouter(address newAddress) public onlyOwner {
        require(newAddress != address(router), "TOKEN: The router already has that address");
        emit UpdateRouter(newAddress, address(router));
        router = IUniswapV2Router02(newAddress);
        address _pair = IUniswapV2Factory(router.factory()).createPair(address(this), router.WETH());
        pair = _pair;
    }

    function enableTrading() external onlyOwner {
        isTradingEnabled = true;
    }

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        require(_isExcludedFromFees[account] != excluded, "TOKEN: Account is already excluded");
        _isExcludedFromFees[account] = excluded;

        emit ExcludeFromFees(account, excluded);
    }

    function excludeMultipleAccountsFromFees(address[] calldata accounts, bool excluded) public onlyOwner {
        for (uint256 i = 0; i < accounts.length; i++) {
            _isExcludedFromFees[accounts[i]] = excluded;
        }

        emit ExcludeMultipleAccountsFromFees(accounts, excluded);
    }

    function setMarketingWallet(address payable wallet) external onlyOwner {
        _marketingWallet = wallet;
    }

    function setSwapAtAmount(uint256 value) external onlyOwner {
        swapTokensAtAmount = value;
    }

    function setMaxWalletAmount(uint256 value) external onlyOwner {
        maxWalletLimit = value;
    }

    function setMaxTxAmount(uint256 value) external onlyOwner {
        maxTxAmount = value;
    }

    function setmarketingFee(uint8 value) external onlyOwner {
        marketingFee = value;
        totalFees = marketingFee;
    }

    function setAutomatedMarketMakerPair(address _pair, bool value) public onlyOwner {
        _setAutomatedMarketMakerPair(_pair, value);
    }

    function _setAutomatedMarketMakerPair(address _pair, bool value) private {
        automatedMarketMakerPairs[_pair] = value;

        emit SetAutomatedMarketMakerPair(_pair, value);
    }

    function isExcludedFromFees(address account) public view returns (bool) {
        return _isExcludedFromFees[account];
    }

    function _transfer(address from, address to, uint256 amount) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        if (amount == 0) {
            super._transfer(from, to, 0);
            return;
        }

        uint256 contractTokenBalance = balanceOf(address(this));

        bool canSwap = contractTokenBalance >= swapTokensAtAmount;

        if (canSwap && !swapping && !automatedMarketMakerPairs[from] && from != owner() && to != owner()) {
            swapping = true;
            contractTokenBalance = swapTokensAtAmount;
            swapAndSendToFee(contractTokenBalance);
            swapping = false;
        }

        bool takeFee = !swapping;

        // if any account belongs to _isExcludedFromFee account then remove the fee
        if (_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
            takeFee = false;
        }

        if (takeFee) {
            require(isTradingEnabled, "Trading not enabled yet");
            require(amount <= maxTxAmount, "Transfer amount exceeds limit");
            
            if (!automatedMarketMakerPairs[to]) {
                require(amount + balanceOf(to) <= maxWalletLimit, "Wallet limit reached");
            }
            uint256 fees = amount.mul(totalFees).div(1000);

            amount = amount.sub(fees);

            super._transfer(from, address(this), fees);
        }

        super._transfer(from, to, amount);
    }

    function claimStuckTokens(address _token) external onlyOwner {
        require(_token != address(this), "No rug pulls");

        if (_token == address(0x0)) {
            payable(owner()).transfer(address(this).balance);
            return;
        }
        IERC20 token = IERC20(_token);
        uint256 balance = token.balanceOf(address(this));
        token.transfer(owner(), balance);
    }

    function swapAndSendToFee(uint256 tokens) private {
        uint256 initialBalance = address(this).balance;
        swapTokensForETH(tokens);
        uint256 newBalance = address(this).balance.sub(initialBalance);

        _marketingWallet.transfer(newBalance);
    }

    function swapTokensForETH(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();

        _approve(address(this), address(router), tokenAmount);

        // make the swap
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(tokenAmount, 0, path, address(this), block.timestamp);
    }
}
