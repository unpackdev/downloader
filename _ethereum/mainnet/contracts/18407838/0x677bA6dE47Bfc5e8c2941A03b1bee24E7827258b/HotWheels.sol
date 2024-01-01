// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.8.18;
pragma abicoder v2;

// Base contracts
import "./Owned.sol";
import "./ERC20.sol";
import "./SafeTransferLib.sol";
import "./console2.sol";

import "./IUniswapV2Factory.sol";
import "./IUniswapV2Pair.sol";
import "./IUniswapV2Router.sol";

import "./Presale.sol";

contract HotWheels is ERC20, Owned {
    uint256 constant TOTAL_SUPPLY = 10_000_000 ether;
    uint256 constant PRESALE_AMOUNT = 1_230_000 ether;

    uint256 public constant maxTransactionAmount = (TOTAL_SUPPLY * 10) / 1000; // 1% from total supply maxTransactionAmountTxn;
    uint256 public constant maxWallet = (TOTAL_SUPPLY * 10) / 1000; // 1% from total supply maxWallet
    address public constant DEAD_ADDRESS = address(0xdead);

    bool public limitsInEffect = true;
    bool public tradingActive = false;
    bool public swapEnabled = false;

    IUniswapV2Router02 public uniswapV2Router;
    HotWheelsPresale public presale;
    address public uniswapV2Pair = address(0);

    // exlcude from fees and max transaction amount
    mapping(address => bool) public _isExcludedMaxTransactionAmount;
    mapping(address => bool) public automatedMarketMakerPairs;

    constructor(bool isTest) ERC20("HotWheels", "SKRTT", 18) Owned(msg.sender) {
        // PRODUCTION CODE
        uint256 TEST_AMOUNT = isTest ? 1_000_000 ether : 0;
        _mint(address(this), (TOTAL_SUPPLY - PRESALE_AMOUNT) - TEST_AMOUNT);
        _mint(msg.sender, TEST_AMOUNT);

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapV2Router = _uniswapV2Router;

        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
        _setAutomatedMarketMakerPair(address(uniswapV2Pair), true);

        presale = new HotWheelsPresale(msg.sender, address(this));
        _mint(address(presale), PRESALE_AMOUNT);
    }

    receive() external payable {}

    // once enabled, can never be turned off
    function enableTrading() external onlyOwner {
        tradingActive = true;
        swapEnabled = true;
    }

    function removeLimits() external onlyOwner returns (bool) {
        limitsInEffect = false;
        return true;
    }

    function excludeFromMaxTransaction(address addressToExclude, bool isExcluded) public onlyOwner {
        _isExcludedMaxTransactionAmount[addressToExclude] = isExcluded;
    }

    // only use to disable contract sales if absolutely necessary (emergency use only)
    function updateSwapEnabled(bool enabled) external onlyOwner {
        swapEnabled = enabled;
    }

    function setAutomatedMarketMakerPair(address pair, bool value) public onlyOwner {
        require(pair != uniswapV2Pair, "The pair cannot be removed from automatedMarketMakerPairs");
        _setAutomatedMarketMakerPair(pair, value);
    }

    function addLiquidity(uint256 amount) external payable onlyOwner {
        // we set this directly as using approve() will result in approving the router for the EOA, not the contract
        allowance[address(this)][address(uniswapV2Router)] = amount;

        // Add liquidity
        uniswapV2Router.addLiquidityETH{value: msg.value}(
            address(this), //token address
            amount, // liquidity amount
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            owner, // LP tokens are sent to the owner
            block.timestamp
        );
    }

    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        automatedMarketMakerPairs[pair] = value;
    }

    // Without this, slither reports locked-ether
    function sweep() external onlyOwner {
        SafeTransferLib.safeTransferETH(owner, address(this).balance);
    }

    function transfer(address to, uint256 amount) public override returns (bool) {
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        address from = msg.sender;

        if (!limitsInEffect) {
            return super.transfer(to, amount);
        }

        if (from == owner || to == owner || to == DEAD_ADDRESS) {
            return super.transfer(to, amount);
        }

        if (from == address(presale)) {
            return super.transfer(to, amount);
        }

        if (from == address(this) && (to == address(uniswapV2Pair) || to == address(uniswapV2Router))) {
            return super.transfer(to, amount);
        }

        if (!tradingActive) {
            require(
                _isExcludedMaxTransactionAmount[from] || _isExcludedMaxTransactionAmount[to],
                "Trading is not enabled yet."
            );
        }

        //when buy
        if (automatedMarketMakerPairs[from] && !_isExcludedMaxTransactionAmount[to]) {
            require(amount <= maxTransactionAmount, "Buy transfer amount exceeds the maxTransactionAmount.");
            require(amount + balanceOf[to] <= maxWallet, "Max wallet exceeded");
        }
        //when sell
        else if (automatedMarketMakerPairs[to] && !_isExcludedMaxTransactionAmount[from]) {
            require(amount <= maxTransactionAmount, "Sell transfer amount exceeds the maxTransactionAmount.");
        } else if (!_isExcludedMaxTransactionAmount[to]) {
            require(amount + balanceOf[to] <= maxWallet, "Max wallet exceeded");
        }

        return super.transfer(to, amount);
    }

    function transferFrom(address from, address to, uint256 amount) public override returns (bool) {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        if (!limitsInEffect) {
            return super.transferFrom(from, to, amount);
        }

        if (from == owner || to == owner || to == DEAD_ADDRESS) {
            return super.transferFrom(from, to, amount);
        }

        if (from == address(presale)) {
            return super.transferFrom(from, to, amount);
        }

        if (from == address(this) && (to == address(uniswapV2Pair) || to == address(uniswapV2Router))) {
            return super.transferFrom(from, to, amount);
        }

        if (!tradingActive) {
            require(
                _isExcludedMaxTransactionAmount[from] || _isExcludedMaxTransactionAmount[to],
                "Trading is not enabled yet."
            );
        }

        //when buy
        if (automatedMarketMakerPairs[from] && !_isExcludedMaxTransactionAmount[to]) {
            require(amount <= maxTransactionAmount, "Buy transfer amount exceeds the maxTransactionAmount.");
            require(amount + balanceOf[to] <= maxWallet, "Max wallet exceeded");
        }
        //when sell
        else if (automatedMarketMakerPairs[to] && !_isExcludedMaxTransactionAmount[from]) {
            require(amount <= maxTransactionAmount, "Sell transfer amount exceeds the maxTransactionAmount.");
        } else if (!_isExcludedMaxTransactionAmount[to]) {
            require(amount + balanceOf[to] <= maxWallet, "Max wallet exceeded");
        }

        return super.transferFrom(from, to, amount);
    }
}
