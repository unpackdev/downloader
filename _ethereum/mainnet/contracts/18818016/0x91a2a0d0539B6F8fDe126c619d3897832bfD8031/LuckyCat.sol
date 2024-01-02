/**

.____     ____ ____________  ____  __._____.___.
|    |   |    |   \_   ___ \|    |/ _|\__  |   |
|    |   |    |   /    \  \/|      <   /   |   |
|    |___|    |  /\     \___|    |  \  \____   |
|_______ \______/  \______  /____|__ \ / ______|
        \/                \/        \/ \/       
_________     ________________                  
\_   ___ \   /  _  \__    ___/                  
/    \  \/  /  /_\  \|    |                     
\     \____/    |    \    |                     
 \______  /\____|__  /____|                     
        \/         \/                           

 /\_/\  
( o.o )
 > ^ <
  ♥ LUCKY CAT Token ♥
  
╰(◕ᴥ◕)╯

https://twitter.com/LuckyCatOnEth
https://zhunihaoyun.vip
https://t.me/LuckyCatEth


/*
 * Disclaimer: Not an investment vehicle, not a security. DYOR. Not financial advice.
 */

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.4;

import "./ERC20.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./IUniswapV2Pair.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Router.sol";

contract LuckyCatToken is ERC20, Ownable {
    using SafeMath for uint256;
    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;
    uint256 public _totalSupply = 100e9 * 1e18; // 100B tokens
    uint256 public swapTokensAtAmount = 100e6 * 1e18; // 100m = Threshold for swap (0.1%)

    uint256 public sniperBlock = 20;
    bool public antiMev = true;

    address public taxAddr;
    uint256 public sellTax = 15;
    uint256 public buyTax = 15;

    bool public _hasLiqBeenAdded = false;
    uint256 public launchedAt = 0;
    uint256 public swapAndLiquifycount = 0;
    uint256 public snipersCaught = 0;

    mapping(address => bool) private whitelisted;
    mapping(address => bool) public blacklisted;
    
    mapping(address => uint256) public lastPurchaseBlock;
    
    bool private swapping;
    mapping(address => bool) public automatedMarketMakerPairs;

    event CaughtSniper(address sniper);

    receive() external payable {}

    constructor(
        address _uniswapAddress,
        address[] memory lps
    ) ERC20("Lucky Cat", "LUCKY") {
        // Set Uniswap Address
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(
            address(_uniswapAddress)
        );

        address _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = _uniswapV2Pair;

        _setAutomatedMarketMakerPair(_uniswapV2Pair, true);

        // Whitelist LP provider address(s)
        for (uint i = 0; i < lps.length; i++) {
            whitelisted[lps[i]] = true;
        }
        whitelisted[address(this)] = true;
        whitelisted[owner()] = true;

        taxAddr = owner();
        super._mint(owner(), _totalSupply);
    }

    /**
     * ADMIN SETTINGS
     */

    function updateSettings(
        uint256 _sellTax,
        uint256 _buyTax,
        uint256 _sniperBlock,
        bool _antiMev,
        address _taxAddr
    ) public onlyOwner {
        sellTax = _sellTax;
        buyTax = _buyTax;
        sniperBlock = _sniperBlock;
        antiMev = _antiMev;
        taxAddr = _taxAddr;
    }

    function updateUniswapV2Router(address newAddress) public onlyOwner {
        require(
            newAddress != address(uniswapV2Router),
            "LuckyCat: The router already has that address"
        );
        uniswapV2Router = IUniswapV2Router02(newAddress);
    }

    function manualSwapandLiquify(uint256 _balance) external onlyOwner {
        swapAndSendDividends(_balance);
    }

    function setAutomatedMarketMakerPair(
        address pair,
        bool value
    ) public onlyOwner {
        require(
            pair != uniswapV2Pair,
            "LuckyCat: The Uniswap pair cannot be removed from automatedMarketMakerPairs"
        );

        _setAutomatedMarketMakerPair(pair, value);
    }

    /**
     * Private functions
     */

    function swapAndSendDividends(uint256 tokens) private {
        swapTokensForEth(tokens);
        uint256 dividends = address(this).balance;
        (bool success, ) = address(taxAddr).call{value: address(this).balance}(
            ""
        );
    }

    // Main override transfer function
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "LuckyCat: 0 transfers not acceptable");
        // Sniper Protection
        if (!_hasLiqBeenAdded) {
            // If no liquidity yet, allow owner to add liquidity
            _checkLiquidityAdd(from, to);
        } else {
            // if liquidity has already been added.
            if (
                launchedAt > 0 &&
                from == uniswapV2Pair &&
                owner() != from &&
                owner() != to
            ) {
                if (block.number - launchedAt < sniperBlock) {
                    _blacklist(to, true);
                    emit CaughtSniper(to);
                    snipersCaught++;
                }
            }
        }
        if (!whitelisted[from] && !whitelisted[to]) {
            require(!blacklisted[from], "LuckyCat: Blocked Transfer");

            // anti mev
            if (antiMev && (lastPurchaseBlock[from] == block.number)){
                _blacklist(from, true);
            }

            uint256 contractTokenBalance = balanceOf(address(this));
            bool canSwap = contractTokenBalance >= swapTokensAtAmount;
            if (
                canSwap &&
                !swapping &&
                !automatedMarketMakerPairs[from] &&
                from != taxAddr &&
                to != taxAddr
            ) {
                swapping = true;
                swapAndSendDividends(swapTokensAtAmount);
                swapping = false;
            }
            bool takeFee = !swapping;

            if (takeFee) {
                uint256 fees = 0;
                if (automatedMarketMakerPairs[from]) {
                    fees = fees.add(amount.mul(buyTax).div(100));
                    lastPurchaseBlock[to] = block.number;
                } else {
                    fees = fees.add(amount.mul(sellTax).div(100));
                }
                amount = amount.sub(fees);
                super._transfer(from, address(this), fees);
            }
        }
        super._transfer(from, to, amount);
    }

    function _checkLiquidityAdd(address from, address to) private {
        // if liquidity is added by the _liquidityholders set
        // trading enables to true and start the anti sniper timer
        require(!_hasLiqBeenAdded, "Liquidity already added and marked.");
        // require liquidity has been added == false (not added).
        // This is basically only called when owner is adding liquidity.

        if (from == owner() && to == uniswapV2Pair) {
            _hasLiqBeenAdded = true;
            launchedAt = block.number;
        }
    }

    /**********/
    /* PRIVATE FUNCTIONS */
    /**********/

    // this is only called by the sniper protection.
    function _blacklist(address account, bool isBlacklisted) private {
        blacklisted[account] = isBlacklisted;
        (account, isBlacklisted);
    }

    function swapTokensForEth(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        // make the swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }

    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        require(
            automatedMarketMakerPairs[pair] != value,
            "LuckyCat: Automated market maker pair is already set to that value"
        );
        automatedMarketMakerPairs[pair] = value;
    }
}
