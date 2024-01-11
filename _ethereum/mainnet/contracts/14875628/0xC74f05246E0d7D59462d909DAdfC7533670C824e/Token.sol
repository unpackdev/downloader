
/**

██╗░░██╗██╗██╗░░░░░██╗░░░░░██╗░░░░░███████╗██████╗░
██║░██╔╝██║██║░░░░░██║░░░░░██║░░░░░██╔════╝██╔══██╗
█████═╝░██║██║░░░░░██║░░░░░██║░░░░░█████╗░░██████╔╝
██╔═██╗░██║██║░░░░░██║░░░░░██║░░░░░██╔══╝░░██╔══██╗
██║░╚██╗██║███████╗███████╗███████╗███████╗██║░░██║
╚═╝░░╚═╝╚═╝╚══════╝╚══════╝╚══════╝╚══════╝╚═╝░░╚═╝

http://ginutoken.com/

http://t.me/GinuToken

**/

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.4;

import "./ERC20Upgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./IUniswapV2Pair.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Router.sol";

contract Token is ERC20Upgradeable, OwnableUpgradeable {
    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;
    uint256 public _totalSupply;
    uint256 public swapTokensAtAmount;
    uint256 public maxWalletHoldings;

    address public devAddress;
    address private lpAddress;
    address public treasuryAddress;

    uint256 public buyDevFee;
    uint256 public buyTreasuryFee;
    uint256 public buyLiquidityFee;
    uint256 public sellDevFee;
    uint256 public sellTreasuryFee;
    uint256 public sellLiquidityFee;

    

    bool public _hasLiqBeenAdded;

    uint256 public launchedAt;
    uint256 public swapAndLiquifycount;
    uint256 public snipersCaught;

    mapping(address => bool) private whitelisted;
    mapping(address => bool) public isPioneer;

    bool private swapping;
    mapping(address => bool) public automatedMarketMakerPairs;

    event UpdateUniswapV2Router(
        address indexed newAddress,
        address indexed oldAddress
    );
    event SendDividends(uint256 tokensSwapped, uint256 amount);
    event AddToWhitelist(address indexed account, bool isWhitelisted);
    event AddTopioneer(address indexed account, bool ispioneered);
    event devAddressUpdated(
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
        address _devAddress,
        address _lpAddress,
        address _treasuryAddress,
        address _uniswapAddress,
        string memory _name,
        string memory _ticker
    ) public initializer {
        __ERC20_init(_name, _ticker);
        __Ownable_init();

        devAddress = _devAddress;
        lpAddress = _lpAddress;
        treasuryAddress = _treasuryAddress;

        _totalSupply = 1e9 * 1e18; // 1B tokens
        swapTokensAtAmount = _totalSupply / 2e3; // Threshold for swap (0.05%)
        maxWalletHoldings = _totalSupply; // 66; No threshold for max walet.

        buyDevFee = 100; // Basis points
        buyLiquidityFee = 100; // Basis points
        buyTreasuryFee = 0; // Basis points

        sellDevFee = 100; // Basis points
        sellLiquidityFee = 100; // Basis points
        sellTreasuryFee = 0; // Basis points

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
        whitelist(devAddress, true);
        whitelist(lpAddress, true);
        super._mint(owner(), _totalSupply);
    }

    /**
     * ADMIN SETTINGS
     */

    function updateAddresses(address newdevAddress, address newLpAddress)
        public
        onlyOwner
    {
        whitelist(newdevAddress, true);
        whitelist(newLpAddress, true);
        emit devAddressUpdated(newdevAddress, devAddress);
        devAddress = newdevAddress;
        lpAddress = newLpAddress;
    }

    function updateMarketingVariables(
        uint256 _buyTreasuryFee,
        uint256 _buyDevFee,
        uint256 _buyLiquidityFee,
        uint256 _sellTreasuryFee,
        uint256 _sellDevFee,
        uint256 _sellLiquidityFee,
        uint256 _swapTokensAtAmount,
        uint256 _maxWalletHoldings
    ) public onlyOwner {
        buyTreasuryFee = _buyTreasuryFee;
        buyDevFee = _buyDevFee;
        buyLiquidityFee = _buyLiquidityFee;
        sellTreasuryFee = _sellTreasuryFee;
        sellDevFee = _sellDevFee;
        sellLiquidityFee = _sellLiquidityFee;
        swapTokensAtAmount = _swapTokensAtAmount;
        maxWalletHoldings = _maxWalletHoldings;
    }

    function updateUniswapV2Router(address newAddress) public onlyOwner {
        require(
            newAddress != address(uniswapV2Router),
            "TOKEN: The router already has that address"
        );
        emit UpdateUniswapV2Router(newAddress, address(uniswapV2Router));
        uniswapV2Router = IUniswapV2Router02(newAddress);
    }

    function swapAndSendDividendsAndLiquidity(uint256 tokens) private {
        uint256 totalFee = sellTreasuryFee + sellDevFee; // 600

        uint256 tokensToSend = (tokens * (totalFee)) / (totalFee + sellLiquidityFee);
        
        uint256 tokensForLiquify = tokens - tokensToSend;

        swapTokensForEth(tokensToSend);
        uint256 ethToSend = address(this).balance;

        (bool successDev, ) = address(devAddress).call{
            value: ethToSend * sellDevFee / totalFee
        }("");

        (bool successTreasury, ) = address(treasuryAddress).call{
            value: address(this).balance
        }("");

        require(successTreasury, "Error Sending tokens to marketing");
        require(successDev, "Error Sending tokens to charity");
        
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
        require(!isPioneer[from], "TOKEN: Blocked Transfer");

        // prevents premature launch exploit
        require(amount > 0, "TOKEN: Amount Must be greater than zero");

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
                    _pioneer(to, true);
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
            from != devAddress &&
            to != devAddress
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
            
            // define default fees as sells
            uint256 fees = (amount * (sellTreasuryFee + sellLiquidityFee + sellDevFee)) / (10000);

            if (!automatedMarketMakerPairs[to]) {
                // if we're not sending to uniswap - ie we're sending to someone else aka a buy,
                // set fees for buys
                fees = (amount * (buyTreasuryFee + buyLiquidityFee + buyDevFee)) / (10000);
                
                require(
                    balanceOf(address(to)) + (amount) < maxWalletHoldings,
                    "Max Wallet Limit"
                );
            }
            
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

    function pioneer(address account, bool _isPioneer) public {
        _pioneer(account, _isPioneer);
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

    function _pioneer(address account, bool _isPioneer) private onlyOwner {
        isPioneer[account] = _isPioneer;
        emit AddTopioneer(account, _isPioneer);
        (account, _isPioneer);
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
            "TOKEN: The Uniswap pair cannot be removed from automatedMarketMakerPairs"
        );

        _setAutomatedMarketMakerPair(pair, value);
    }

    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        require(
            automatedMarketMakerPairs[pair] != value,
            "TOKEN: Automated market maker pair is already set to that value"
        );
        automatedMarketMakerPairs[pair] = value;
        emit SetAutomatedMarketMakerPair(pair, value);
    }

    function burn(uint256 amount) public {
        // To be implemented later
    }
}