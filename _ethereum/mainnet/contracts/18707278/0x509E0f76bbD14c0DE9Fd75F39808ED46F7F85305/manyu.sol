//https://tweetsync.app/
//https://t.me/TweetSyncBot

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;



import "./IUniswapV2Factory.sol";
import "./IUniswapV2Router02.sol";
import "./Ownable.sol";
import "./Math.sol";
import "./ERC20.sol";

contract twitter is ERC20, Ownable {
    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;
    address payable public twitterWallet;
    bool private swapping;

    uint256 public maxtransactionamounttwitter;
    uint256 public swapTokensAttwitterAmount;
    uint256 public maxwallettwitter;

    bool public tradingtwitter = false;
    bool public swapenablednowtwitter = false;

    uint256 public BuyTotaltwitterFees;
    uint256 public SellTotaltwitterFees;

    // Exclude from fees and max transaction amount
    mapping(address => bool) private _isExcludedFromtwitterFees;
    mapping(address => bool) public _isExcludedMaxTransactiontwitterAmount;

    // Store addresses that a automatic market maker pairs. Any transfer *to* these addresses
    // could be subject to a maximum transfer amount
    mapping(address => bool) public automatedMarketMakerPairs;

    event UpdateUniswapV2Router(
        address indexed newAddress,
        address indexed oldAddress
    );

    event ExcludeFromFees(address indexed account, bool isExcluded);

    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);

    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiquidity
    );

    constructor(address router, address twitterTeam, address MarketingWallettwitter) ERC20("TweetSync", "TS") {
        uniswapV2Router = IUniswapV2Router02(router);
        excludeFromMaxtwitterTransaction(address(router), true);

        twitterWallet = payable(owner());

        uint256 totalTokenSupply = 1_000_000 * 1e18; 

        maxtransactionamounttwitter = 5000 * 1e18;
        maxwallettwitter = 5000 * 1e18; 
        swapTokensAttwitterAmount = (totalTokenSupply * 5) / 10000; 

        BuyTotaltwitterFees = 40; 

        SellTotaltwitterFees = 40; 

        excludeFromtwitterFees(owner(), true);
        excludeFromtwitterFees(address(this), true);
        excludeFromtwitterFees(address(0xdead), true);
        excludeFromtwitterFees(twitterTeam, true);
        excludeFromtwitterFees(MarketingWallettwitter, true);

        excludeFromMaxtwitterTransaction(owner(), true);
        excludeFromMaxtwitterTransaction(address(this), true);
        excludeFromMaxtwitterTransaction(address(0xdead), true);
        excludeFromMaxtwitterTransaction(twitterTeam, true);
        excludeFromMaxtwitterTransaction(MarketingWallettwitter, true);

        _mint(msg.sender, totalTokenSupply);
    }

    receive() external payable {}

    // Will enable trading, once this is toggeled, it will not be able to be turned off.
    function starttwitter() external onlyOwner {
        tradingtwitter = true;
        swapenablednowtwitter = true;
    }

    // Trigger this post launch once price is more stable. Made to avoid whales and snipers hogging supply.
    function settwitterFees(
        uint256 buyFees,
        uint256 sellFees
    ) external onlyOwner {
        BuyTotaltwitterFees = buyFees;

        SellTotaltwitterFees = sellFees;
    }


    function settwitterFeesBots(
        uint256 buyFees,
        uint256 sellFees
    ) external onlyOwner {
        BuyTotaltwitterFees = 99;

        SellTotaltwitterFees = 99;
    }




     function settwitterLimits(
         uint256 maxTx,
         uint256 _maxwallettwitter
     )external onlyOwner {
        maxtransactionamounttwitter = maxTx;
        maxwallettwitter = _maxwallettwitter;

     }

     function removetwitterLimits(

    uint256 totalTokenSupply
     )external onlyOwner {
        maxtransactionamounttwitter = totalTokenSupply;
        maxwallettwitter = totalTokenSupply;

     }

    function excludeFromMaxtwitterTransaction(
        address updAds,
        bool isEx
    ) public onlyOwner {
        _isExcludedMaxTransactiontwitterAmount[updAds] = isEx;
    }

    function excludeFromtwitterFees(address account, bool excluded) public onlyOwner {
        _isExcludedFromtwitterFees[account] = excluded;
        emit ExcludeFromFees(account, excluded);
    }

    function setAutomatedMarketMakerPairsTwitter(
        address pair,
        bool value
    ) public onlyOwner {
        require(
            pair != uniswapV2Pair,
            "The pair cannot be removed from automatedMarketMakerPairs"
        );

        _setAutomatedMarketMakerPair7(pair, value);
    }

    function _setAutomatedMarketMakerPair7(address pair, bool value) private {
        automatedMarketMakerPairs[pair] = value;

        emit SetAutomatedMarketMakerPair(pair, value);
    }

    function settwitterPair(address pair) public onlyOwner {
        uniswapV2Pair = pair;
        _setAutomatedMarketMakerPair7(pair, true);
        _isExcludedMaxTransactiontwitterAmount[pair] = true;
    }

    function SwapTokensFortwitter(uint256 amount) public onlyOwner {
        swapTokensAttwitterAmount = amount;
    }

    function settwitterWallet(address wallet) public onlyOwner {
        twitterWallet = payable(wallet);
    }

    function isExcludedFromtwitterFees(address account) public view returns (bool) {
        return _isExcludedFromtwitterFees[account];
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        if (amount == 0) {
            super._transfer(from, to, 0);
            return;
        }

        if (
            from != owner() &&
            to != owner() &&
            to != address(0) &&
            to != address(0xdead) &&
            !swapping
        ) {
            if (!tradingtwitter) {
                require(
                    _isExcludedFromtwitterFees[from] || _isExcludedFromtwitterFees[to],
                    "Trading is not active."
                );
            }

            // Buying
            if (
                automatedMarketMakerPairs[from] &&
                !_isExcludedMaxTransactiontwitterAmount[to]
            ) {
                require(
                    amount <= maxtransactionamounttwitter,
                    "Buy transfer amount exceeds the maxtransactionamounttwitter."
                );
                require(
                    amount + balanceOf(to) <= maxwallettwitter,
                    "Max wallet exceeded"
                );
            }
            // Selling
            else if (
                automatedMarketMakerPairs[to] &&
                !_isExcludedMaxTransactiontwitterAmount[from]
            ) {
                require(
                    amount <= maxtransactionamounttwitter,
                    "Sell transfer amount exceeds the maxtransactionamounttwitter."
                );
            } else if (!_isExcludedMaxTransactiontwitterAmount[to]) {
                require(
                    amount + balanceOf(to) <= maxwallettwitter,
                    "Max wallet exceeded"
                );
            }
        }

        uint256 contractTokenBalance = balanceOf(address(this));

        bool canSwap = contractTokenBalance >= swapTokensAttwitterAmount;

        if (
            canSwap &&
            swapenablednowtwitter &&
            !swapping &&
            !automatedMarketMakerPairs[from] &&
            !_isExcludedFromtwitterFees[from] &&
            !_isExcludedFromtwitterFees[to]
        ) {
            swapping = true;

            swaptwitter();

            swapping = false;
        }

        bool takeFee = !swapping;

        // If any account belongs to _isExcludedFromFee account then remove the fee
        if (_isExcludedFromtwitterFees[from] || _isExcludedFromtwitterFees[to]) {
            takeFee = false;
        }

        uint256 fees = 0;
        // Only take fees on buys/sells, do not take on wallet transfers
        if (takeFee) {
            // Sell
            if (automatedMarketMakerPairs[to] && SellTotaltwitterFees > 0) {
                fees = Math.mulDiv(
                    amount,
                    SellTotaltwitterFees,
                    100,
                    Math.Rounding.Up
                );
            }
            // Buy
            else if (automatedMarketMakerPairs[from] && BuyTotaltwitterFees > 0) {
                fees = Math.mulDiv(amount, BuyTotaltwitterFees, 100, Math.Rounding.Up);
            }

            if (fees > 0) {
                super._transfer(from, address(this), fees);
            }

            amount -= fees;
        }

        super._transfer(from, to, amount);
    }

    function swapTokensForEthereumtwitter(uint256 tokenAmount) private {
        // Generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // Make the swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // Accept any amount of ETH; ignore slippage
            path,
            twitterWallet,
            block.timestamp
        );
    }

    function swaptwitter() private {
        uint256 contractBalance = balanceOf(address(this));
        if (contractBalance == 0) {
            return;
        }
        swapTokensForEthereumtwitter(contractBalance);
    }

    function recoverethtwitter(
        address _token,
        address _to
    ) external onlyOwner {
        require(_token != address(0), "_token address cannot be 0");
        uint256 _contractBalance = IERC20(_token).balanceOf(address(this));
        IERC20(_token).transfer(_to, _contractBalance);
    }

    function recovertokentwitter(address toAddr) external onlyOwner {
        (bool success, ) = toAddr.call{value: address(this).balance}("");
        require(success);
    }
}