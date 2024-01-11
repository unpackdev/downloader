// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./SafeMathUpgradeable.sol";
import "./ERC20Upgradeable.sol";
import "./ERC20BurnableUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./Initializable.sol";
import "./UUPSUpgradeable.sol";

// (Uni|Pancake)Swap libs are interchangeable
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Pair.sol";
import "./IUniswapV2Router01.sol";
import "./IUniswapV2Router02.sol";

contract ERC20DividendToken is Initializable, ERC20Upgradeable, ERC20BurnableUpgradeable, PausableUpgradeable, OwnableUpgradeable, UUPSUpgradeable {
    using SafeMathUpgradeable for uint256;

    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;

    bool private swapping;

    uint256 public minTokensBeforeSwap;

    mapping(address => bool) public isBlacklisted;

    uint256 public liquidityFee;
    uint256 public devFee;
    uint256 public buyBackFee;
    uint256 public treasuryFee;

    uint256 public totalBuyFees;
    uint256 public totalSellFees;

    uint256 private _devPending;
    uint256 private _buyBackPending;
    uint256 private _treasuryPending;

    address public devAddress;
    address public buyBackAddress;
    address public treasuryAddress;

    mapping(address => bool) public isExcludedFromFees;
    mapping(address => bool) public automatedMarketMakerPairs;

    uint256 public maxTxAmount;
    uint256 public maxWalletAmount;

    mapping (address => bool) public isExcludedFromLimits;

    event UpdateUniswapV2Router(address indexed newAddress);

    event ExcludeFromFees(address indexed account, bool isExcluded);

    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);

    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );

    event SendDividendsToDev(uint256 amount);
    event SendDividendsToBuyBack(uint256 amount);
    event SendDividendsToTreasury(uint256 amount);

    function __ERC20DividendToken_init(string memory name_, string memory symbol_, uint256 totalSupply_, address routerV2_, address devAddress_, address buyBackAddress_, address treasuryAddress_, address targetOwner_) internal onlyInitializing {
        __ERC20_init(name_, symbol_);
        __ERC20Burnable_init();
        __Pausable_init();
        __Ownable_init();
        __UUPSUpgradeable_init();

        setBuyFees(2, 1);
        setSellFees(2, 1);

        setDevAddress(devAddress_);
        setBuyBackAddress(buyBackAddress_);
        setTreasuryAddress(treasuryAddress_);
        
        setMinTokensBeforeSwap(5_000_000 * (10**9));

        changeMaxWalletAmount(5_000_000 * (10**9)); // 5M
        changeMaxTxAmount(5_000_000 * (10**9)); // 5M

        _updateUniswapV2Router(routerV2_);

        excludeFromFees(targetOwner_, true);
        excludeFromFees(msg.sender, true);
        excludeFromFees(address(this), true);
        excludeFromFees(devAddress_, true);
        excludeFromFees(buyBackAddress_, true);
        excludeFromFees(treasuryAddress_, true);

        excludeFromLimits(targetOwner_, true);
        excludeFromLimits(msg.sender, true);
        excludeFromLimits(address(this), true);
        excludeFromLimits(address(0xdead), true);
        excludeFromLimits(devAddress_, true);
        excludeFromLimits(buyBackAddress_, true);
        excludeFromLimits(treasuryAddress_, true);

        _mint(targetOwner_, totalSupply_ * 90 * (10**7));
        _mint(msg.sender, totalSupply_ * 10 * (10**7));
    }

    receive() external payable {}

    function _authorizeUpgrade(address newImplementation) internal onlyOwner override {}

    function decimals() public pure override returns (uint8) {
        return 9;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function excludeFromLimits(address account, bool excluded) public onlyOwner {
        isExcludedFromLimits[account] = excluded;
    }

    function changeMaxTxAmount(uint256 amount) public onlyOwner {
        maxTxAmount = amount;
    }

    function changeMaxWalletAmount(uint256 amount) public onlyOwner {
        maxWalletAmount = amount;
    }

    function setMinTokensBeforeSwap(uint256 amount) public onlyOwner {
        minTokensBeforeSwap = amount;
    }

    function _updateUniswapV2Router(address newAddress) internal {
        uniswapV2Router = IUniswapV2Router02(newAddress);
        address _uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory())
        .createPair(address(this), uniswapV2Router.WETH());

        excludeFromLimits(newAddress, true);

        uniswapV2Pair = _uniswapV2Pair;
        _setAutomatedMarketMakerPair(_uniswapV2Pair, true);

        emit UpdateUniswapV2Router(newAddress);
    }

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        isExcludedFromFees[account] = excluded;

        emit ExcludeFromFees(account, excluded);
    }

    function setDevAddress(address _devAddress) public onlyOwner {
        devAddress = _devAddress;
    }

    function setBuyBackAddress(address _buyBackAddress) public onlyOwner {
        buyBackAddress = _buyBackAddress;
    }

    function setTreasuryAddress(address _treasuryAddress) public onlyOwner {
        treasuryAddress = _treasuryAddress;
    }

    function setBuyFees(uint256 _devFee, uint256 _liquidityFee) public onlyOwner {
        devFee = _devFee;
        liquidityFee = _liquidityFee;

        totalBuyFees = devFee.add(liquidityFee);
        require(totalBuyFees <= 15, "Cannot exceed max tax rate limit of 15%");
    }

    function setSellFees(uint256 _buyBackFee, uint256 _treasuryFee) public onlyOwner {
        buyBackFee = _buyBackFee;
        treasuryFee = _treasuryFee;

        totalSellFees = buyBackFee.add(treasuryFee);
        require(totalSellFees <= 15, "Cannot exceed max tax rate limit of 15%");
    }

    function setAutomatedMarketMakerPair(address pair, bool value)
        public
        onlyOwner
    {
        require(
            pair != uniswapV2Pair,
            "ERC20DividendToken: The PancakeSwap pair cannot be removed from automatedMarketMakerPairs"
        );

        _setAutomatedMarketMakerPair(pair, value);
    }

    function blacklistAddress(address account, bool value) external onlyOwner {
        isBlacklisted[account] = value;
    }

    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        require(
            automatedMarketMakerPairs[pair] != value,
            "ERC20DividendToken: Automated market maker pair is already set to that value"
        );
        automatedMarketMakerPairs[pair] = value;

        if (value) {
            excludeFromLimits(pair, true);
        }

        emit SetAutomatedMarketMakerPair(pair, value);
    }

    function _burn(address account, uint256 amount) internal whenNotPaused override {
        require(!isBlacklisted[account], "Blacklisted address");

        super._burn(account, amount);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal whenNotPaused override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(balanceOf(from) >= amount, "ERC20: transfer amount exceeds balance");

        require(!isBlacklisted[from] && !isBlacklisted[to], "Blacklisted address");

        if (!isExcludedFromLimits[from] || (automatedMarketMakerPairs[from] && !isExcludedFromLimits[to])) {
            require(amount <= maxTxAmount, "Anti-whale: Transfer amount exceeds max limit");
        }
        if (!isExcludedFromLimits[to]) {
            require(balanceOf(to) + amount <= maxWalletAmount, "Anti-whale: Wallet amount exceeds max limit");
        }

        if (amount == 0) {
            super._transfer(from, to, 0);
            return;
        }

        uint256 contractTokenBalance = balanceOf(address(this));

        bool canSwap = contractTokenBalance >= minTokensBeforeSwap;

        if (
            canSwap &&
            !swapping &&
            !automatedMarketMakerPairs[from] &&
            from != owner() &&
            to != owner()
        ) {
            swapping = true;

            if (_devPending > 0 || _buyBackPending > 0 || _treasuryPending > 0) {
                swapAndSendDividendsToAddresses(_devPending + _buyBackPending + _treasuryPending);

                _devPending = 0;
                _buyBackPending = 0;
                _treasuryPending = 0;
            }
            if (balanceOf(address(this)) > 0) {
                uint256 liquidityTokens = balanceOf(address(this));
                swapAndLiquify(liquidityTokens);
            }

            swapping = false;
        }

        bool takeFee = !swapping && (automatedMarketMakerPairs[from] || automatedMarketMakerPairs[to]);

        // if any account belongs to _isExcludedFromFee account then remove the fee
        if (isExcludedFromFees[from] || isExcludedFromFees[to]) {
            takeFee = false;
        }

        if (takeFee) {
            uint256 fees = 0;
            
            if (automatedMarketMakerPairs[from] && totalBuyFees > 0) { // BUY
                fees = amount.mul(totalBuyFees).div(100);

                _devPending += fees.mul(devFee).div(totalBuyFees);
            } else if (totalSellFees > 0) { // SELL
                fees = amount.mul(totalSellFees).div(100);

                _buyBackPending += fees.mul(buyBackFee).div(totalSellFees);
                _treasuryPending += fees.mul(treasuryFee).div(totalSellFees);
            }

            if (fees > 0) {
                amount = amount.sub(fees);
                super._transfer(from, address(this), fees);
            }
        }

        super._transfer(from, to, amount);
    }

    function swapAndLiquify(uint256 tokens) private {
        // split the contract balance into halves
        uint256 half = tokens.div(2);
        uint256 otherHalf = tokens.sub(half);

        // capture the contract's current ETH balance.
        // this is so that we can capture exactly the amount of ETH that the
        // swap creates, and not make the liquidity event include any ETH that
        // has been manually sent to the contract
        uint256 initialBalance = address(this).balance;

        // swap tokens for ETH
        swapTokensForEth(half); // <- this breaks the ETH -> HATE swap when swap+liquify is triggered

        // how much ETH did we just swap into?
        uint256 newBalance = address(this).balance.sub(initialBalance);

        // add liquidity to uniswap
        addLiquidity(otherHalf, newBalance);

        emit SwapAndLiquify(half, newBalance, otherHalf);
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

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // add the liquidity
        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            address(0xdead),
            block.timestamp
        );
    }

    function swapAndSendDividendsToAddresses(uint256 tokens) private {
        uint256 initialBalance = address(this).balance;

        swapTokensForEth(tokens);
        
        uint256 dividends = address(this).balance.sub(initialBalance);
        uint256 sent = 0;

        if (devFee > 0) {
            uint256 devEth = dividends.mul(_devPending).div(tokens);
            (bool success,) = payable(devAddress).call{value: devEth}("");

            if (success) {
                sent += devEth;
                emit SendDividendsToDev(devEth);
            }
        }

        if (buyBackFee > 0) {
            uint256 buyBackEth = dividends.mul(_buyBackPending).div(tokens);
            (bool success,) = payable(buyBackAddress).call{value: buyBackEth}("");

            if (success) {
                sent += buyBackEth;
                emit SendDividendsToBuyBack(buyBackEth);
            }
        }

        if (treasuryFee > 0) {
            uint256 treasuryEth = dividends.sub(sent);
            (bool success,) = payable(treasuryAddress).call{value: treasuryEth}("");

            if (success) {
                emit SendDividendsToTreasury(treasuryEth);
            }
        }
    }
}

contract BATL is ERC20DividendToken {

    /**
     * @dev Choose proper router address according to your network:
     * Ethereum mainnet: 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D (Uniswap)
     * Fantom mainnet: 0xF491e7B69E4244ad4002BC14e878a34207E38c29 (SpookySwap)
     */

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address _routerAddress) initializer public {
        __ERC20DividendToken_init("Battle Bounty", "BATL", 100_000_000_000, _routerAddress, 0xb6F9839084c599A67644d6DcA0f242984F9a6593, 0xb6F9839084c599A67644d6DcA0f242984F9a6593, 0xb6F9839084c599A67644d6DcA0f242984F9a6593, 0xb6F9839084c599A67644d6DcA0f242984F9a6593);
    }

    function _mint(address account, uint256 amount)
        internal
        onlyInitializing
        override
    {
        super._mint(account, amount);
    }
}