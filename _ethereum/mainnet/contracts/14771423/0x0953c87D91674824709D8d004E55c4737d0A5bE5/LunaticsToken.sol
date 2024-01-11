/**
    IMPORTANT NOTICE:
    This smart contract was written and deployed by the software engineers at 
    https://highstack.co in a contractor capacity.

    Highstack is not responsible for any malicious use or losses arising from using 
    or interacting with this smart contract.

    THIS CONTRACT IS PROVIDED ON AN “AS IS” BASIS. USE THIS SOFTWARE AT YOUR OWN RISK.
    THERE IS NO WARRANTY, EXPRESSED OR IMPLIED, THAT DESCRIBED FUNCTIONALITY WILL 
    FUNCTION AS EXPECTED OR INTENDED. PRODUCT MAY CEASE TO EXIST. NOT AN INVESTMENT, 
    SECURITY OR A SWAP. TOKENS HAVE NO RIGHTS, USES, PURPOSE, ATTRIBUTES, 
    FUNCTIONALITIES OR FEATURES, EXPRESS OR IMPLIED, INCLUDING, WITHOUT LIMITATION, ANY
    USES, PURPOSE OR ATTRIBUTES. TOKENS MAY HAVE NO VALUE. PRODUCT MAY CONTAIN BUGS AND
    SERIOUS BREACHES IN THE SECURITY THAT MAY RESULT IN LOSS OF YOUR ASSETS OR THEIR 
    IMPLIED VALUE. ALL THE CRYPTOCURRENCY TRANSFERRED TO THIS SMART CONTRACT MAY BE LOST.
    THE CONTRACT DEVLOPERS ARE NOT RESPONSIBLE FOR ANY MONETARY LOSS, PROFIT LOSS OR ANY
    OTHER LOSSES DUE TO USE OF DESCRIBED PRODUCT. CHANGES COULD BE MADE BEFORE AND AFTER
    THE RELEASE OF THE PRODUCT. NO PRIOR NOTICE MAY BE GIVEN. ALL TRANSACTION ON THE 
    BLOCKCHAIN ARE FINAL, NO REFUND, COMPENSATION OR REIMBURSEMENT POSSIBLE. YOU MAY 
    LOOSE ALL THE CRYPTOCURRENCY USED TO INTERACT WITH THIS CONTRACT. IT IS YOUR 
    RESPONSIBILITY TO REVIEW THE PROJECT, TEAM, TERMS & CONDITIONS BEFORE USING THE 
    PRODUCT.

**/

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.4;

import "./ERC20Upgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./IUniswapV2Pair.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Router.sol";

contract LUNATICS is ERC20Upgradeable, OwnableUpgradeable {
    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;
    uint256 public _totalSupply;
    uint256 public swapTokensAtAmount;
    uint256 public maxWalletHoldings;

    address public marketingAddress;
    uint256 public marketingFee;

    address public charityAddress;
    uint256 public charityFee;

    uint256 public liquidityFee;

    address private lpAddress;

    bool public _hasLiqBeenAdded;

    uint256 public launchedAt;
    uint256 public swapAndLiquifycount;
    uint256 public snipersCaught;

    mapping(address => bool) private whitelisted;
    mapping(address => bool) public blacklisted;

    bool private swapping;
    mapping(address => bool) public automatedMarketMakerPairs;

    event UpdateUniswapV2Router(
        address indexed newAddress,
        address indexed oldAddress
    );
    event SendDividends(uint256 tokensSwapped, uint256 amount);
    event AddToWhitelist(address indexed account, bool isWhitelisted);
    event AddToBlacklist(address indexed account, bool isBlacklisted);
    event MarketingAddressUpdated(
        address indexed newMarketingWallet,
        address indexed oldMarketingWallet
    );
    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);

    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );

    receive() external payable {}

    function initialize(
        address _marketingAddress,
        address _lpAddress,
        address _charityAddress,
        address _uniswapAddress
    ) public initializer {
        __ERC20_init("Lunatics", "LUNATICS");
        __Ownable_init();

        marketingAddress = _marketingAddress;
        lpAddress = _lpAddress;
        charityAddress = _charityAddress;

        _totalSupply = 1e6 * 1e18; // 1M tokens
        swapTokensAtAmount = 1e3 * 1e18; // 1k = Threshold for swap (0.1%)
        maxWalletHoldings = 5e3 * 1e18; // 0.5% max wallet holdings (mutable)

        charityFee = 400; // Basis points
        marketingFee = 300; // Basis points
        liquidityFee = 200; // Basis points

        launchedAt = 0;
        swapAndLiquifycount = 0;
        snipersCaught = 0;

        _hasLiqBeenAdded = false;

        // Set Uniswap Address
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(
            address(_uniswapAddress)
        );

        address _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = _uniswapV2Pair;

        _setAutomatedMarketMakerPair(_uniswapV2Pair, true);
        whitelist(address(this), true);
        whitelist(owner(), true);
        whitelist(marketingAddress, true);
        super._mint(owner(), _totalSupply);
    }

    /**
     * ADMIN SETTINGS
     */

    function updateAddresses(address newmarketingAddress, address newLpAddress)
        public
        onlyOwner
    {
        whitelist(newmarketingAddress, true);
        whitelist(newLpAddress, true);
        emit MarketingAddressUpdated(newmarketingAddress, marketingAddress);
        marketingAddress = newmarketingAddress;
        lpAddress = newLpAddress;
    }

    function updateMarketingVariables(
        uint256 _marketingFee,
        uint256 _charityFee,
        uint256 _swapTokensAtAmount,
        uint256 _liquidityFee,
        uint256 _maxWalletHoldings
    ) public onlyOwner {
        marketingFee = _marketingFee;
        charityFee = _charityFee;
        swapTokensAtAmount = _swapTokensAtAmount;
        liquidityFee = _liquidityFee;
        maxWalletHoldings = _maxWalletHoldings;
    }

    function updateUniswapV2Router(address newAddress) public onlyOwner {
        require(
            newAddress != address(uniswapV2Router),
            "LUNATICS: The router already has that address"
        );
        emit UpdateUniswapV2Router(newAddress, address(uniswapV2Router));
        uniswapV2Router = IUniswapV2Router02(newAddress);
    }

    function swapAndSendDividendsAndLiquidity(uint256 tokens) private {
        uint256 totalFee = marketingFee + charityFee;
        uint256 tokensToSend = (tokens * (totalFee)) / 10000;

        uint256 tokensForLiquify = tokens - tokensToSend;

        swapTokensForEth(tokensToSend);
        uint256 ethToSend = address(this).balance;

        (bool successMarketing, ) = address(marketingAddress).call{
            value: ethToSend * marketingFee / totalFee
        }("");

        (bool successCharity, ) = address(charityAddress).call{
            value: address(this).balance
        }("");

        require(successMarketing, "Error Sending tokens to marketing");
        require(successCharity, "Error Sending tokens to charity");
        
        emit SendDividends(tokens, ethToSend);

        swapAndLiquify(tokensForLiquify);
        swapAndLiquifycount = swapAndLiquifycount + (1);
    }

    function manualSwapandLiquify(uint256 _amount) external onlyOwner {
        swapAndSendDividendsAndLiquidity(_amount);
    }

    function swapAndLiquify(uint256 _amount) internal {
        // split the contract balance into halves
        uint256 half = _amount / (2);
        uint256 otherHalf = _amount - (half); // in event of odd numbers

        uint256 initialBalance = address(this).balance;

        // swap tokens for ETH
        swapTokensForEth(half);

        // how much ETH did we just swap into?
        uint256 newBalance = address(this).balance - (initialBalance);

        // add liquidity
        addLiquidity(otherHalf, newBalance);
        emit SwapAndLiquify(half, newBalance, otherHalf);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(!blacklisted[from], "LUNATICS: Blocked Transfer");

        // prevents premature launch exploit
        require(amount > 0, "LUNATICS: Amount Must be greater than zero");

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
                if (block.number - launchedAt < 10) {
                    _blacklist(to, true);
                    snipersCaught++;
                }
            }
        }

        uint256 contractTokenBalance = balanceOf(address(this));
        bool canSwap = contractTokenBalance >= swapTokensAtAmount;
        if (
            canSwap &&
            !swapping &&
            !automatedMarketMakerPairs[from] &&
            from != marketingAddress &&
            to != marketingAddress
        ) {
            swapping = true;
            swapAndSendDividendsAndLiquidity(swapTokensAtAmount);
            swapping = false;
        }
        bool takeFee = !swapping;
        // if any account is whitelisted account then remove the fee

        if (whitelisted[from] || whitelisted[to]) {
            takeFee = false;
        }

        // To disable tradingEnabled, set max wallet holdings to something super low.
        if (takeFee) {
            if (!automatedMarketMakerPairs[to]) {
                require(
                    balanceOf(address(to)) + (amount) < maxWalletHoldings,
                    "Max Wallet Limit"
                );
            }
            uint256 fees = (amount * (marketingFee + liquidityFee + charityFee)) / (10000);
            amount = amount - (fees);
            super._transfer(from, address(this), fees);
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

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // Approve token transfer to cover all possible scenarios
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // Add the liquidity
        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // Slippage is unavoidable
            0, // Slippage is unavoidable
            lpAddress,
            block.timestamp
        );
    }

    function whitelist(address account, bool isWhitelisted) public onlyOwner {
        whitelisted[account] = isWhitelisted;
        emit AddToWhitelist(account, isWhitelisted);
        (account, isWhitelisted);
    }

    function blacklist(address account, bool isBlacklisted) public onlyOwner {
        _blacklist(account, isBlacklisted);
    }

    function launched() internal view returns (bool) {
        return launchedAt != 0;
    }

    function launch() public onlyOwner {
        launchedAt = block.number;
        _hasLiqBeenAdded = true;
    }

    /**********/
    /* PRIVATE FUNCTIONS */
    /**********/

    function _blacklist(address account, bool isBlacklisted) private {
        blacklisted[account] = isBlacklisted;
        emit AddToBlacklist(account, isBlacklisted);
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

    function setAutomatedMarketMakerPair(address pair, bool value)
        public
        onlyOwner
    {
        require(
            pair != uniswapV2Pair,
            "LUNATICS: The Uniswap pair cannot be removed from automatedMarketMakerPairs"
        );

        _setAutomatedMarketMakerPair(pair, value);
    }

    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        require(
            automatedMarketMakerPairs[pair] != value,
            "LUNATICS: Automated market maker pair is already set to that value"
        );
        automatedMarketMakerPairs[pair] = value;
        emit SetAutomatedMarketMakerPair(pair, value);
    }
}
