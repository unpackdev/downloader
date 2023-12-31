// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

// Website: https://stakezeus.com
// Docs: https://docs.stakezeus.com
// Telegram: https://t.me/ZeusTokenPortal
// Twitter: https://twitter.com/StakeZeusToken

import "./ERC20.sol";
import "./WETH.sol";
import "./Owned.sol";
import "./SafeTransferLib.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Router.sol";

contract Zeus is ERC20, Owned {
    using SafeTransferLib for ERC20;
    struct User {
        bool isBlacklisted;
        bool isAutomatedMarketMaker;
        bool isExcludedFromFees;
        bool isExcludedFromMaxTransactionAmount;
    }

    struct Fees {
        uint8 buy;
        uint8 sell;
        uint8 liquidity;
        uint8 development;
        uint8 staking;
    }

    struct Settings {
        bool limitsInEffect;
        bool swapEnabled;
        bool blacklistRenounced;
        bool feeChangeRenounced;
        bool tradingActive;
        /// @dev Upon enabling trading, record the end block for bot protection fee
        /// @dev This fee is a 90% fee that is reduced by 5% every block for 18 blocks.
        uint216 endBlock;
    }

    uint256 public constant MAX_SUPPLY = 10_000_000 * 1e18;
    uint256 public constant MIN_SWAP_AMOUNT = MAX_SUPPLY / 100_000; // 0.001%
    uint256 public constant MAX_SWAP_AMOUNT = (MAX_SUPPLY * 5) / 1_000; // 0.5%
    uint256 public exitTaxRate;

    IUniswapV2Router public immutable uniswapV2Router;
    address public immutable uniswapV2Pair;
    address public immutable developmentWallet;
    address public stakingAddress;

    uint256 public maxTransactionAmount;
    uint256 public swapTokensAtAmount;
    uint256 public maxWallet;
    uint256 public tokensForBotProtection;

    Fees public feeAmounts;

    bool private _swapping;

    Settings private settings =
        Settings({
            limitsInEffect: true,
            swapEnabled: true,
            blacklistRenounced: false,
            feeChangeRenounced: false,
            tradingActive: false,
            endBlock: uint216(0)
        });

    mapping(address => User) private _users;
    mapping(address => uint256) private _lastBuyTimestamp;
    address private wethAddress;

    event ExcludeFromFees(address indexed account, bool isExcluded);
    event ExcludeFromMaxTransaction(address indexed account, bool isExcluded);
    event FailedSwapBackTransfer(address indexed destination, uint256 amount);
    event MaxTransactionAmountUpdated(uint256 newAmount, uint256 oldAmount);
    event SetAutomatedMarketMakerPair(address indexed pair, bool value);
    event SwapAndLiquify(uint256 tokensSwapped, uint256 ethReceived);
    event TransferToStaking(uint256 amount);
    event SwapTokensAtAmountUpdated(uint256 newAmount, uint256 oldAmount);

    error Zeus__BlacklistModificationDisabled();
    error Zeus__BuyAmountGreaterThanMax();
    error Zeus__CannotBlacklistLPPair();
    error Zeus__CannotBlacklistRouter();
    error Zeus__CannotRemovePairFromAMMs();
    error Zeus__CannotTransferFromAddressZero();
    error Zeus__CannotTransferToAddressZero();
    error Zeus__ErrorWithdrawingEth();
    error Zeus__FeeChangeRenounced();
    error Zeus__MaxFeeFivePercent();
    error Zeus__MaxTransactionTooLow();
    error Zeus__MaxWalletAmountExceeded();
    error Zeus__MaxWalletAmountTooLow();
    error Zeus__OnlyOwner();
    error Zeus__ReceiverBlacklisted();
    error Zeus__ReceiverCannotBeAddressZero();
    error Zeus__SellAmountGreaterThanMax();
    error Zeus__SenderBlacklisted();
    error Zeus__StuckEthWithdrawError();
    error Zeus__SwapAmountGreaterThanMaximum();
    error Zeus__SwapAmountLowerThanMinimum();
    error Zeus__TokenAddressCannotBeAddressZero();
    error Zeus__TradingNotActive();

    constructor(
        address routerAddress,
        address devWallet,
        uint256 _exitTaxRate
    ) ERC20("Zeus", "Zeus", 18) Owned(msg.sender) {
        developmentWallet = devWallet;
        exitTaxRate = _exitTaxRate;
        IUniswapV2Router _uniswapV2Router = IUniswapV2Router(routerAddress);
        uniswapV2Router = _uniswapV2Router;
        wethAddress = uniswapV2Router.WETH();
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        maxTransactionAmount = MAX_SUPPLY / 200; // 0.5%
        maxWallet = MAX_SUPPLY / 100; // 1%
        swapTokensAtAmount = (MAX_SUPPLY * 5) / 10_000; // 0.05%
        feeAmounts = Fees({
            buy: 5,
            sell: 5,
            liquidity: 25,
            development: 25,
            staking: 50
        });

        _users[msg.sender] = User({
            isExcludedFromFees: true,
            isExcludedFromMaxTransactionAmount: true,
            isAutomatedMarketMaker: false,
            isBlacklisted: false
        });

        _users[address(this)] = User({
            isExcludedFromFees: true,
            isExcludedFromMaxTransactionAmount: true,
            isAutomatedMarketMaker: false,
            isBlacklisted: false
        });

        _users[address(uniswapV2Router)] = User({
            isExcludedFromMaxTransactionAmount: true,
            isAutomatedMarketMaker: false,
            isExcludedFromFees: false,
            isBlacklisted: false
        });

        _users[address(uniswapV2Pair)] = User({
            isExcludedFromMaxTransactionAmount: true,
            isAutomatedMarketMaker: true,
            isExcludedFromFees: false,
            isBlacklisted: false
        });

        _mint(msg.sender, MAX_SUPPLY);
        _approve(address(uniswapV2Router), type(uint256).max);
        _lastBuyTimestamp[devWallet] = block.timestamp;
    }

    receive() external payable {}

    function _requireIsOwner() internal view {
        require(msg.sender == owner, "!owner");
    }

    function setStakingAddress(address _staking) external {
        _requireIsOwner();
        stakingAddress = _staking;
    }

    function updateExitTaxRate(uint256 _exitTaxRate) external {
        _requireIsOwner();
        exitTaxRate = _exitTaxRate;
    }

    function updateFees(Fees memory newFees) external {
        _requireIsOwner();
        feeAmounts = newFees;
    }

    function enableTrading() external {
        _requireIsOwner();
        settings.endBlock = uint216(block.number) + 20;
        settings.tradingActive = true;
    }

    function removeLimits() external {
        _requireIsOwner();
        settings.limitsInEffect = false;
    }

    // change the minimum amount of tokens to sell from fees
    function updateSwapTokensAtAmount(uint256 newAmount) external {
        _requireIsOwner();
        if (newAmount < MIN_SWAP_AMOUNT) {
            revert Zeus__SwapAmountLowerThanMinimum();
        }
        if (newAmount > MAX_SWAP_AMOUNT) {
            revert Zeus__SwapAmountGreaterThanMaximum();
        }
        uint256 oldSwapAmount = swapTokensAtAmount;
        swapTokensAtAmount = newAmount;
        emit SwapTokensAtAmountUpdated(newAmount, oldSwapAmount);
    }

    function updateMaxTransactionAmount(uint256 newAmount) external {
        _requireIsOwner();
        if (newAmount < (MAX_SUPPLY * 5) / 1000) {
            revert Zeus__MaxTransactionTooLow();
        }
        uint256 oldMaxTransactionAmount = maxTransactionAmount;
        maxTransactionAmount = newAmount;
        emit MaxTransactionAmountUpdated(newAmount, oldMaxTransactionAmount);
    }

    function excludeFromFees(address account, bool excluded) external {
        _requireIsOwner();
        _users[account].isExcludedFromFees = excluded;
        emit ExcludeFromFees(account, excluded);
    }

    function excludeFromMaxTransaction(
        address account,
        bool isExcluded
    ) external {
        _requireIsOwner();
        _users[account].isExcludedFromMaxTransactionAmount = isExcluded;
        emit ExcludeFromMaxTransaction(account, isExcluded);
    }

    function setAutomatedMarketMakerPair(address pair, bool value) external {
        _requireIsOwner();
        if (pair == uniswapV2Pair) {
            revert Zeus__CannotRemovePairFromAMMs();
        }

        _users[pair].isAutomatedMarketMaker = value;
        emit SetAutomatedMarketMakerPair(pair, value);
    }

    function renounceBlacklist() external {
        _requireIsOwner();
        settings.blacklistRenounced = true;
    }

    function blacklist(address account) external {
        _requireIsOwner();
        if (settings.blacklistRenounced) {
            revert Zeus__BlacklistModificationDisabled();
        }
        if (account == uniswapV2Pair) {
            revert Zeus__CannotBlacklistLPPair();
        }
        if (account == address(uniswapV2Router)) {
            revert Zeus__CannotBlacklistRouter();
        }
        _users[account].isBlacklisted = true;
    }

    // @dev unblacklist address; not affected by blacklistRenounced incase team wants to unblacklist v3 pools down the
    function unblacklist(address account) external {
        _requireIsOwner();
        _users[account].isBlacklisted = false;
    }

    function isExcludedFromFees(address account) external view returns (bool) {
        return _users[account].isExcludedFromFees;
    }

    function isExcludedFromMaxTransactionAmount(
        address account
    ) external view returns (bool) {
        return _users[account].isExcludedFromMaxTransactionAmount;
    }

    function isAutomatedMarketMakerPair(
        address pair
    ) external view returns (bool) {
        return _users[pair].isAutomatedMarketMaker;
    }

    function isBlacklisted(address account) external view returns (bool) {
        return _users[account].isBlacklisted;
    }

    function isSwapEnabled() external view returns (bool) {
        return settings.swapEnabled;
    }

    function isBlacklistRenounced() external view returns (bool) {
        return settings.blacklistRenounced;
    }

    function isFeeChangeRenounced() external view returns (bool) {
        return settings.feeChangeRenounced;
    }

    function isTradingActive() external view returns (bool) {
        return settings.tradingActive;
    }

    function isLimitInEffect() external view returns (bool) {
        return settings.limitsInEffect;
    }

    function transfer(
        address to,
        uint256 amount
    ) public override returns (bool) {
        _transfer(msg.sender, to, amount);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public override returns (bool) {
        uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.
        if (allowed != type(uint256).max) {
            allowance[from][msg.sender] = allowed - amount;
        }
        _transfer(from, to, amount);
        return true;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal returns (bool) {
        User memory fromData = _users[from];
        User memory toData = _users[to];
        Settings memory settingCache = settings;

        if (!settingCache.tradingActive) {
            if (!fromData.isExcludedFromFees) {
                if (!toData.isExcludedFromFees) {
                    revert Zeus__TradingNotActive();
                }
            }
        }

        // Apply blacklist protection
        if (fromData.isBlacklisted) {
            revert Zeus__SenderBlacklisted();
        }
        if (toData.isBlacklisted) {
            revert Zeus__ReceiverBlacklisted();
        }

        // If zero amount, continue
        if (amount == 0) {
            return true;
        }

        bool excludedFromFees = fromData.isExcludedFromFees ||
            toData.isExcludedFromFees;

        // Cache transaction type for reference.
        // 1 = Buy
        // 2 = Sell
        // 3 = Transfer
        uint8 txType = 3;

        if (fromData.isAutomatedMarketMaker) {
            // Buys originate from the AMM pair
            txType = 1;
        } else if (toData.isAutomatedMarketMaker) {
            // Sells send funds to AMM pair
            txType = 2;
        }

        if (!_swapping) {
            if (settingCache.limitsInEffect) {
                //when buy
                if (txType == 1 && !toData.isExcludedFromMaxTransactionAmount) {
                    if (amount > maxTransactionAmount) {
                        revert Zeus__BuyAmountGreaterThanMax();
                    }
                    if (amount + this.balanceOf(to) > maxWallet) {
                        revert Zeus__MaxWalletAmountExceeded();
                    }
                }
                //when sell
                else if (
                    txType == 2 && !fromData.isExcludedFromMaxTransactionAmount
                ) {
                    if (amount > maxTransactionAmount) {
                        revert Zeus__SellAmountGreaterThanMax();
                    }
                } else if (!toData.isExcludedFromMaxTransactionAmount) {
                    if (amount + this.balanceOf(to) > maxWallet) {
                        revert Zeus__MaxWalletAmountExceeded();
                    }
                }
            }

            if (settingCache.swapEnabled) {
                // Only sells will trigger the fee swap
                if (txType == 2) {
                    if (this.balanceOf(address(this)) >= swapTokensAtAmount) {
                        _swapping = true;
                        _swapBack();
                        _swapping = false;
                    }
                }
            }
        }

        if (txType < 3) {
            bool takeFee = !_swapping;

            // if any account belongs to _isExcludedFromFee account then remove the fee
            if (excludedFromFees) {
                takeFee = false;
            }
            uint256 fees = 0;
            // only take fees on buys/sells, do not take on wallet transfers
            if (takeFee) {
                Fees memory feeCache = feeAmounts;
                // on sell

                if (block.number < settingCache.endBlock) {
                    uint256 blocksLeft = settingCache.endBlock - block.number;
                    uint256 botFeeMultiplier = 95;

                    // Apply sniper protection - first 18 blocks have a fee reduced 5% each block.
                    if (blocksLeft < 19) {
                        botFeeMultiplier -= (5 * (19 - blocksLeft));
                    }
                    if (txType == 1) {
                        _lastBuyTimestamp[to] = block.timestamp;
                    }
                    uint256 botFee = (amount * botFeeMultiplier) / 100;
                    _doTransfer(from, owner, fees);
                    amount -= botFee;
                    tokensForBotProtection += botFee;
                } else {
                    if (txType == 2) {
                        // from is seller
                        // to is amm
                        if (feeCache.sell > 0) {
                            uint256 feePercentage = getZeusTax(from);
                            fees = (amount * feePercentage) / 100;
                        }
                    } else if (txType == 1) {
                        // from is amm,
                        // to is buyer
                        if (feeCache.buy > 0) {
                            fees = (amount * feeCache.buy) / 100;
                            _lastBuyTimestamp[to] = block.timestamp;
                        }
                    }
                }

                amount -= fees;

                if (fees > 0) {
                    _doTransfer(from, address(this), fees);
                }
            }
        } else {
            // If not a buy or sell, then it's a transfer.
            // If the sender is not excluded from fees, then apply the exit tax.
            if (!fromData.isExcludedFromFees) {
                uint256 exitTax = (amount * getZeusTax(from)) / 100;

                amount -= exitTax;
                _doTransfer(from, address(this), exitTax);
                // update to address
                _lastBuyTimestamp[to] = block.timestamp;
            }
        }

        _doTransfer(from, to, amount);

        return true;
    }

    function getZeusTax(address from) public view returns (uint256) {
        uint256 lastBuy = _lastBuyTimestamp[from];
        if (lastBuy == 0) {
            return exitTaxRate;
        }
        uint256 timeSinceLastBuy = block.timestamp - lastBuy;
        uint256 percentageOfDay = (timeSinceLastBuy * 1000) / 8 hours;
        if (percentageOfDay >= 1000) {
            return 5;
        }
        uint256 exitTax = exitTaxRate -
            ((exitTaxRate * percentageOfDay) / 1000);
        return exitTax;
    }

    function getLastBuyTimestamp(address from) public view returns (uint256) {
        return _lastBuyTimestamp[from];
    }

    function _swapTokensForEth(uint256 tokenAmount) internal {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function _addLiquidity(uint256 tokenAmount, uint256 ethAmount) internal {
        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            developmentWallet,
            block.timestamp
        );
    }

    function _doTransfer(
        address from,
        address to,
        uint256 amount
    ) internal returns (bool) {
        balanceOf[from] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);

        return true;
    }

    function _swapBack() internal {
        // Cache values
        uint256 contractBalance = this.balanceOf(address(this));
        Fees memory feeCache = feeAmounts;

        if (contractBalance == 0) {
            return;
        }

        // Prevent too many tokens from being swapped
        uint256 maxAmount = swapTokensAtAmount * 20;
        if (contractBalance > maxAmount) {
            contractBalance = maxAmount;
        }

        uint256 liquidityAmount = (contractBalance * feeCache.liquidity) / 100;

        // Halve the amount of liquidity tokens
        uint256 liquidityTokens = liquidityAmount - (liquidityAmount / 2);

        uint256 initialETHBalance = address(this).balance;
        _swapTokensForEth(liquidityTokens);
        uint256 ethForLiquidity = address(this).balance - initialETHBalance;

        if (liquidityTokens > 0 && ethForLiquidity > 0) {
            _addLiquidity(liquidityTokens, ethForLiquidity);
            emit SwapAndLiquify(liquidityTokens, ethForLiquidity);
        }

        uint256 amountToSwapForETH = contractBalance - liquidityAmount;
        _swapTokensForEth(amountToSwapForETH);

        uint256 contractEthAmount = address(this).balance;
        uint256 initialTotalEth = contractEthAmount + (ethForLiquidity * 2);

        uint256 developmentEthAmount = (initialTotalEth *
            feeCache.development) / 100;
        (bool success, ) = address(developmentWallet).call{
            value: developmentEthAmount
        }("");
        require(success);

        uint256 stakingAmount = contractEthAmount - developmentEthAmount;
        WETH(payable(wethAddress)).deposit{value: stakingAmount}();
        ERC20(wethAddress).safeTransfer(
            stakingAddress,
            WETH(payable(wethAddress)).balanceOf(address(this))
        );
    }

    function _approve(address spender, uint256 amount) internal onlyOwner {
        allowance[address(this)][spender] = amount;
        emit Approval(address(this), spender, amount);
    }
}
