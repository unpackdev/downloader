// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./IUniswapV2Factory.sol";
import "./IUniswapV2Router02.sol";
import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./AccessControl.sol";
import "./Address.sol";

contract MemeCoin is Context, ERC20, ERC20Burnable, AccessControl {
    using Address for address payable;

    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;

    error ZeroAddress();
    error ForbiddenWithdrawalFromOwnContract();
    error InvalidValue();
    error UserIsAbuser();
    error UserIsNotAbuser();
    error TradingNotEnabled();
    error MaxTransactionAmountExceeded();
    error MaxWalletExceeded();

    uint256 public constant MAX_TOTAL_SUPPLY = 1000000000e18;

    bool private swapping;
    bool public swapEnabled = false;
    uint256 public swapTokensAtAmount;
    bool public tradingEnabled = false;

    uint256 public maxBuyTransaction;
    uint256 public maxSellTransaction;
    uint256 public maxWalletAmount;

    uint256 public liquidityFeeOnBuy;
    uint256 public liquidityFeeOnSell;

    uint256 public marketingFeeOnBuy;
    uint256 public marketingFeeOnSell;

    uint256 private _totalFeesOnBuy;
    uint256 private _totalFeesOnSell;

    uint256 public walletToWalletTransferFee;

    address public marketingWallet;

    mapping(address => bool) private _isAbuser;

    mapping(address => bool) private _isExcludedFromFees;
    mapping(address => bool) private _isExcludedFromMaxTransaction;

    event MarketingWalletChanged(address marketingWallet);

    event AddedToAbusers(address[] users);
    event RemovedFromAbusers(address[] users);

    event TradingEnabled(bool enabled);
    event SwapEnabled(bool enabled);
    event UpdateSwapTokensAtAmount(uint256 swapTokensAtAmount);
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 bnbReceived,
        uint256 tokensIntoLiqudity
    );
    event SwapAndSendMarketing(uint256 tokensSwapped, uint256 bnbSend);

    event UpdateMaxBuyTransaction(uint256 maxBuyTransaction);
    event UpdateMaxSellTransaction(uint256 maxSellTransaction);
    event UpdateMaxWalletAmount(uint256 maxWalletAmount);

    event ExcludedFromMaxTransaction(address user, bool isExcluded);
    event ExcludeFromFees(address user, bool isExcluded);

    event UpdateBuyFees(uint256 liquidityFeeOnBuy, uint256 marketingFeeOnBuy);
    event UpdateSellFees(
        uint256 liquidityFeeOnSell,
        uint256 marketingFeeOnSell
    );
    event UpdateWalletToWalletTransferFee(uint256 walletToWalletTransferFee);

    /**
     * @dev Initializes the contract with initial settings.
     * @param name_ The name of the token.
     * @param symbol_ The symbol of the token.
     * @param admin_ The address of the admin role.
     * @param router_ Address of the Uniswap V2 Router.
     * @param marketingWallet_ Address of the marketing wallet.
     */
    constructor(
        string memory name_,
        string memory symbol_,
        address admin_,
        address router_,
        address marketingWallet_
    ) ERC20(name_, symbol_) {
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(router_);
        address _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = _uniswapV2Pair;

        _approve(address(this), address(_uniswapV2Router), type(uint256).max);

        marketingWallet = marketingWallet_;

        _isExcludedFromFees[admin_] = true;
        _isExcludedFromFees[address(0xdead)] = true;
        _isExcludedFromFees[address(this)] = true;
        _isExcludedFromFees[marketingWallet_] = true;

        _isExcludedFromMaxTransaction[address(_uniswapV2Router)] = true;
        _isExcludedFromMaxTransaction[address(_uniswapV2Pair)] = true;
        _isExcludedFromMaxTransaction[address(0xdead)] = true;
        _isExcludedFromMaxTransaction[admin_] = true;
        _isExcludedFromMaxTransaction[address(this)] = true;
        _isExcludedFromMaxTransaction[marketingWallet_] = true;

        _mint(admin_, MAX_TOTAL_SUPPLY);

        _grantRole(DEFAULT_ADMIN_ROLE, admin_);
    }

    /**
     * @dev Fallback function to receive ETH from UniswapV2Router when swapping.
     */
    receive() external payable {}

    /**
     * @notice Sets the address of the marketing wallet.
     * @param _marketingWallet New address of the marketing wallet.
     */
    function setMarketingWallet(
        address _marketingWallet
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (_marketingWallet == address(0)) {
            revert ZeroAddress();
        }
        marketingWallet = _marketingWallet;

        emit MarketingWalletChanged(marketingWallet);
    }

    /**
     * @notice Enables or disables trading.
     * @param _enabled True to enable trading, false to disable.
     */
    function enableTrading(
        bool _enabled
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        tradingEnabled = _enabled;

        emit TradingEnabled(_enabled);
    }

    /**
     * @notice Exclude or include an address from fee calculations.
     * @param _user Address to be excluded or included.
     * @param _isExcluded True to exclude, false to include.
     */
    function excludeFromFees(
        address _user,
        bool _isExcluded
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _isExcludedFromFees[_user] = _isExcluded;

        emit ExcludeFromFees(_user, _isExcluded);
    }

    /**
     * @notice Update the fees applied to buying transactions.
     * @dev Only the admin role can call this function.
     * @param _liquidityFeeOnBuy New liquidity fee percentage on buy transactions.
     * @param _marketingFeeOnBuy New marketing fee percentage on buy transactions.
     */
    function updateBuyFees(
        uint256 _liquidityFeeOnBuy,
        uint256 _marketingFeeOnBuy
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        liquidityFeeOnBuy = _liquidityFeeOnBuy;
        marketingFeeOnBuy = _marketingFeeOnBuy;
        _totalFeesOnBuy = liquidityFeeOnBuy + marketingFeeOnBuy;

        emit UpdateBuyFees(liquidityFeeOnBuy, marketingFeeOnBuy);
    }

    /**
     * @notice Update the fees applied to selling transactions.
     * @dev Only the admin role can call this function.
     * @param _liquidityFeeOnSell New liquidity fee percentage on sell transactions.
     * @param _marketingFeeOnSell New marketing fee percentage on sell transactions.
     */
    function updateSellFees(
        uint256 _liquidityFeeOnSell,
        uint256 _marketingFeeOnSell
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        liquidityFeeOnSell = _liquidityFeeOnSell;
        marketingFeeOnSell = _marketingFeeOnSell;
        _totalFeesOnSell = liquidityFeeOnSell + marketingFeeOnSell;

        emit UpdateSellFees(liquidityFeeOnSell, marketingFeeOnSell);
    }

    /**
     * @notice Update the fee applied to wallet-to-wallet transfers.
     * @dev Only the admin role can call this function.
     * @param _walletToWalletTransferFee New fee percentage for wallet-to-wallet transfers.
     */
    function updateWalletToWalletTransferFee(
        uint256 _walletToWalletTransferFee
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        walletToWalletTransferFee = _walletToWalletTransferFee;

        emit UpdateWalletToWalletTransferFee(walletToWalletTransferFee);
    }

    /**
     * @notice Updates the ability to enable or disable token swapping on Uniswap.
     * @param _enabled A boolean value indicating whether token swapping is enabled or disabled.
     * @dev Only the contract owner with the DEFAULT_ADMIN_ROLE can call this function to control token swapping.
     * Emits a SwapEnabled event to signal the change in token swapping status.
     */
    function updateSwapEnabled(
        bool _enabled
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        swapEnabled = _enabled;

        emit SwapEnabled(_enabled);
    }

    /**
     * @notice Updates the threshold amount of tokens required to trigger an automatic swap and liquidity addition.
     * @param _newAmount The new amount of tokens required for triggering swaps.
     * @dev Only the contract owner with the DEFAULT_ADMIN_ROLE can call this function to update the swap threshold.
     * Emits an UpdateSwapTokensAtAmount event to signal the change in the swap threshold.
     */
    function updateSwapTokensAtAmount(
        uint256 _newAmount
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        swapTokensAtAmount = _newAmount;

        emit UpdateSwapTokensAtAmount(_newAmount);
    }

    /**
     * @notice Withdraws stuck tokens from the contract to the specified address.
     * @param _token The address of the token to be withdrawn.
     * @param _to The address to which the tokens will be transferred.
     * @dev Only the contract owner with the DEFAULT_ADMIN_ROLE can call this function to withdraw tokens.
     * Emits no events as it is a utility function for managing stuck tokens.
     */
    function withdrawStuckTokens(
        address _token,
        address _to
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (_token == address(0)) {
            revert ZeroAddress();
        }
        if (_token == address(this)) {
            revert ForbiddenWithdrawalFromOwnContract();
        }
        uint256 balance = IERC20(_token).balanceOf(address(this));
        IERC20(_token).transfer(_to, balance);
    }

    /**
     * @notice Withdraws stuck BNB from the contract to the specified address.
     * @param _to The address to which the BNB will be transferred.
     * @dev Only the contract owner with the DEFAULT_ADMIN_ROLE can call this function to withdraw BNB.
     * Emits no events as it is a utility function for managing stuck BNB.
     */
    function withdrawStuckBNB(
        address _to
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        payable(_to).sendValue(address(this).balance);
    }

    /**
     * @notice Adds addresses to the list of abusers.
     * @param _users An array of user addresses to be marked as abusers.
     * @dev Only the contract owner with the DEFAULT_ADMIN_ROLE can call this function to add abusers.
     * Emits the AddedToAbusers event upon successful addition of abusers.
     */
    function addAbusers(
        address[] calldata _users
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _addAbusers(_users);
    }

    /**
     * @notice Removes addresses from the list of abusers.
     * @param _users An array of user addresses to be removed from the list of abusers.
     * @dev Only the contract owner with the DEFAULT_ADMIN_ROLE can call this function to remove abusers.
     * Reverts if any user address is 0 or if the user is not marked as an abuser.
     * Emits the RemovedFromAbusers event upon successful removal of abusers.
     */
    function removeAbusers(
        address[] calldata _users
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 length = _users.length;

        for (uint256 i = 0; i < length; i++) {
            address user = _users[i];
            if (user == address(0)) {
                revert ZeroAddress();
            }
            if (_isAbuser[user] == false) {
                revert UserIsNotAbuser();
            }
            _isAbuser[user] = false;
        }

        emit RemovedFromAbusers(_users);
    }

    /**
     * @notice Excludes or includes an address from max transaction limit checks.
     * @param _user The user address to be excluded or included.
     * @param _isExcluded A boolean indicating whether the user should be excluded.
     * @dev Only the contract owner with the DEFAULT_ADMIN_ROLE can call this function to manage max transaction exclusions.
     * Emits the ExcludedFromMaxTransaction event upon successful exclusion or inclusion.
     */
    function excludeFromMaxTransaction(
        address _user,
        bool _isExcluded
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _isExcludedFromMaxTransaction[_user] = _isExcluded;

        emit ExcludedFromMaxTransaction(_user, _isExcluded);
    }

    /**
     * @notice Updates the maximum allowed buy transaction amount.
     * @param _maxBuyTransaction The new maximum allowed buy transaction amount.
     * @dev Only the contract owner with the DEFAULT_ADMIN_ROLE can call this function to update the buy transaction limit.
     * Emits the UpdateMaxBuyTransaction event upon successful update of the buy transaction limit.
     */
    function updateMaxBuyTransaction(
        uint256 _maxBuyTransaction
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        maxBuyTransaction = _maxBuyTransaction;

        emit UpdateMaxBuyTransaction(_maxBuyTransaction);
    }

    /**
     * @notice Updates the maximum allowed sell transaction amount.
     * @param _maxSellTransaction The new maximum allowed sell transaction amount.
     * @dev Only the contract owner with the DEFAULT_ADMIN_ROLE can call this function to update the sell transaction limit.
     * Emits the UpdateMaxSellTransaction event upon successful update of the sell transaction limit.
     */
    function updateMaxSellTransaction(
        uint256 _maxSellTransaction
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        maxSellTransaction = _maxSellTransaction;

        emit UpdateMaxSellTransaction(_maxSellTransaction);
    }

    /**
     * @notice Updates the maximum allowed wallet balance.
     * @param _maxWalletAmount The new maximum allowed wallet balance.
     * @dev Only the contract owner with the DEFAULT_ADMIN_ROLE can call this function to update the max wallet balance.
     * Emits the UpdateMaxWalletAmount event upon successful update of the max wallet balance.
     */
    function updateMaxWalletAmount(
        uint256 _maxWalletAmount
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        maxWalletAmount = _maxWalletAmount;

        emit UpdateMaxWalletAmount(_maxWalletAmount);
    }

    /**
     * @notice Checks whether an address is excluded from max transaction limit checks.
     * @param _user The user address to check for exclusion.
     * @return A boolean indicating whether the address is excluded from max transaction limits.
     * @dev This function is publicly accessible and can be used to query the max transaction exclusion status of an address.
     */
    function isExcludedFromMaxTransaction(
        address _user
    ) public view returns (bool) {
        return _isExcludedFromMaxTransaction[_user];
    }

    /**
     * @notice Checks if an address is excluded from fees.
     * @param _user Address to be checked.
     * @return True if the address is excluded from fees, false otherwise.
     */
    function isExcludedFromFees(address _user) public view returns (bool) {
        return _isExcludedFromFees[_user];
    }

    /**
     * @notice Checks whether an address is marked as an abuser.
     * @param _user The user address to check for abuser status.
     * @return A boolean indicating whether the address is an abuser.
     * @dev This function is publicly accessible and can be used to query the abuser status of an address.
     */
    function isAbuser(address _user) public view returns (bool) {
        return _isAbuser[_user];
    }

    /**
     * @notice Adds addresses to the list of abusers.
     * @param _users An array of user addresses to be marked as abusers.
     * @dev This is a private utility function used internally to add addresses to the abusers list.
     * Reverts if any user address is 0 or if the user is already marked as an abuser.
     * Emits the AddedToAbusers event upon successful addition of abusers.
     */
    function _addAbusers(address[] memory _users) private {
        uint256 length = _users.length;

        for (uint256 i = 0; i < length; i++) {
            address user = _users[i];
            if (user == address(0)) {
                revert ZeroAddress();
            }
            if (_isAbuser[user] == true) {
                revert UserIsAbuser();
            }
            _isAbuser[user] = true;
        }

        emit AddedToAbusers(_users);
    }

    /**
     * @notice Internal function to perform token transfers with fee calculations and liquidity management.
     * @param from The address transferring tokens from.
     * @param to The address receiving tokens.
     * @param amount The amount of tokens being transferred.
     * @dev This function enforces various transfer conditions including maximum transaction limits, trading status,
     *      and abuser status. It also calculates and applies transfer fees, performs token swaps for liquidity
     *      and marketing, and enforces wallet-to-wallet transfer fees. This function is overridden from the parent
     *      ERC20 contract.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        if (from == address(0) || to == address(0)) {
            revert ZeroAddress();
        }
        if (amount == 0) {
            revert InvalidValue();
        }
        if (isAbuser(from) || isAbuser(to)) {
            revert UserIsAbuser();
        }

        // Check trading status and excluded fee status
        if (!isExcludedFromFees(from) && !isExcludedFromFees(to)) {
            if (!tradingEnabled) {
                revert TradingNotEnabled();
            }
        }

        // Check maximum transaction limits for buy and sell transfers

        //when buy
        if (from == uniswapV2Pair && !isExcludedFromMaxTransaction(to)) {
            if (amount > maxBuyTransaction) {
                revert MaxTransactionAmountExceeded();
            }

            if (amount + balanceOf(to) > maxWalletAmount) {
                revert MaxWalletExceeded();
            }
        }
        //when sell
        else if (to == uniswapV2Pair && !isExcludedFromMaxTransaction(from)) {
            if (amount > maxSellTransaction) {
                revert MaxTransactionAmountExceeded();
            }
        } else if (!isExcludedFromMaxTransaction(to)) {
            if (amount + balanceOf(to) > maxWalletAmount) {
                revert MaxWalletExceeded();
            }
        }

        uint256 contractTokenBalance = balanceOf(address(this));

        bool canSwap = contractTokenBalance != 0 &&
            contractTokenBalance >= swapTokensAtAmount;

        // Check if token swaps for liquidity and marketing should occur
        if (
            canSwap &&
            !swapping &&
            to == uniswapV2Pair &&
            _totalFeesOnBuy + _totalFeesOnSell > 0
        ) {
            swapping = true;

            uint256 totalFee = _totalFeesOnBuy + _totalFeesOnSell;
            uint256 liquidityShare = liquidityFeeOnBuy + liquidityFeeOnSell;
            uint256 marketingShare = marketingFeeOnBuy + marketingFeeOnSell;

            if (liquidityShare > 0) {
                uint256 liquidityTokens = (contractTokenBalance *
                    liquidityShare) / totalFee;
                swapAndLiquify(liquidityTokens);
            }

            if (marketingShare > 0) {
                uint256 marketingTokens = (contractTokenBalance *
                    marketingShare) / totalFee;
                swapAndSendMarketing(marketingTokens);
            }

            swapping = false;
        }

        uint256 _totalFees;

        // Calculate and apply transfer fees
        if (isExcludedFromFees(from) || isExcludedFromFees(to) || swapping) {
            _totalFees = 0;
        } else if (from == uniswapV2Pair) {
            _totalFees = _totalFeesOnBuy;
        } else if (to == uniswapV2Pair) {
            _totalFees = _totalFeesOnSell;
        } else {
            _totalFees = walletToWalletTransferFee;
        }

        if (_totalFees > 0) {
            uint256 fees = (amount * _totalFees) / 100;
            amount = amount - fees;
            super._transfer(from, address(this), fees);
        }

        // Perform the actual token transfer
        super._transfer(from, to, amount);
    }

    /**
     * @notice Private function to swap tokens for ETH and add liquidity to the Uniswap V2 pair.
     * @param tokens The amount of tokens to be swapped and liquified.
     * @dev This function performs a token-to-ETH swap using Uniswap V2 router and then adds the resulting
     *      ETH and remaining tokens to the liquidity pool of the contract's Uniswap V2 pair.
     * Emits a SwapAndLiquify event with details of the swap and added liquidity.
     */
    function swapAndLiquify(uint256 tokens) private {
        uint256 half = tokens / 2;
        uint256 otherHalf = tokens - half;

        uint256 initialBalance = address(this).balance;

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            half,
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 newBalance = address(this).balance - initialBalance;

        uniswapV2Router.addLiquidityETH{value: newBalance}(
            address(this),
            otherHalf,
            0,
            0,
            address(0xdead),
            block.timestamp
        );

        emit SwapAndLiquify(half, newBalance, otherHalf);
    }

    /**
     * @notice Private function to swap tokens for ETH and send ETH to the marketing wallet.
     * @param tokenAmount The amount of tokens to be swapped and sent as ETH to the marketing wallet.
     * @dev This function performs a token-to-ETH swap using Uniswap V2 router and sends the resulting
     *      ETH to the specified marketing wallet address.
     * Emits a SwapAndSendMarketing event with details of the swap and ETH sent to the marketing wallet.
     */
    function swapAndSendMarketing(uint256 tokenAmount) private {
        uint256 initialBalance = address(this).balance;

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

        uint256 newBalance = address(this).balance - initialBalance;

        payable(marketingWallet).sendValue(newBalance);

        emit SwapAndSendMarketing(tokenAmount, newBalance);
    }
}
