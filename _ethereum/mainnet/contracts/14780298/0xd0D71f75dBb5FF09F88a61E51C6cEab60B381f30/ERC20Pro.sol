//SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.0;

import "./OwnableUpgradeable.sol";
import "./IERC20Upgradeable.sol";
import "./draft-ERC20PermitUpgradeable.sol";
import "./ERC20BurnableUpgradeable.sol";
import "./SafeERC20Upgradeable.sol";
import "./AddressUpgradeable.sol";
import "./MathUpgradeable.sol";

import "./IUniswapV2Factory.sol";
import "./IUniswapV2Router02.sol";

import "./IERC20Pro.sol";

interface IUniswapV2Pair {
    function sync() external;
}

/// @notice Decent auditable erc20 token open sourced to be used instead of all those ruggy coins. See https://www.erc20pro.com for more info.
contract ERC20Pro is ERC20PermitUpgradeable, ERC20BurnableUpgradeable, OwnableUpgradeable, IERC20Pro {

    using AddressUpgradeable for address;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    /// @notice 2 decimals 100% is 10000
    uint private taxFee;
    /// @notice 2 decimals 100% is 10000
    uint private marketingFee;
    /// @notice 2 decimals 100% is 10000
    uint private burnFee;

    /// @notice 2 decimals 100% is 10000
    /// @dev no clogged routers :-)
    uint private swapImpact;

    bool private inSwapAndLiquify;
    bool private swapAndLiquifyEnabled;
    /// @notice first 15 minutes of trading there are automatic maxTxAmount and maxWalletAmount
    bool public tradingLimited;
    /// @notice without tranding is opened you cannot trade, block 0 after open trading is blacklisted
    uint public tradingOpened;

    uint public maxTxAmount;
    uint public maxWalletAmount;

    address private devWalletAddress;
    address private marketingWalletAddress;
    address private originator;

    IUniswapV2Router02 private uniswapV2Router;
    mapping(address => bool) private uniswapV2Pairs;
    mapping(address => bool) private isExcludedFromFee;
    mapping(address => bool) private isBlackListedBot;
    address[] private blackListedBots;

    ///
    /// events
    ///

    event SwapAndLiquifyEnabledUpdated(bool _enabled);

    event DirectLpBurnEnabledUpdated(bool _enabled);

    event ResuscitationEnabledUpdated(bool _enabled);

    event SwapAndLiquifyFailed(bytes _failErr);

    event RouterLpPairChanged(address _router, address _lpToken);

    event LpPairChanged(address _lpToken, bool _isPair);

    event FeesChanged(uint _devFee, uint _marketingFee, uint _burnFee);

    event BlacklistModified(address indexed _bot, bool _added);

    event ExcludedFromFee(address indexed _user, bool _added);

    event IncludedInFee(address indexed _user, bool _added);

    event AddressesChanged(address indexed _devWalletAddress, address indexed _marketingWalletAddress);

    ///
    /// modifiers
    ///

    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    ///
    /// initialization logic
    ///

    /// @notice initialize newly created contract, can be called only once
    /// @param _tickers #0 - symbol, #1 - name
    /// @param _maxTxAmount max tx amount during first 15 minutes
    /// @param _maxWalletAmount max wallet amount during first 15 minutes
    /// @param _fees #0 - dev tax fee, #1 - marketing tax fee, #2 - burn fee, #3 - direct burn fee, all with 0 decimals, so 10000 is 100%
    /// @param _addresses #0 - dev team wallet, #1 - marketing team wallet, #2 - dex router, #3 - tokens creator, #4 - tokens receiver
    function initialize(
        string[] memory _tickers,
        uint _maxTxAmount,
        uint _maxWalletAmount,
        uint[] memory _fees,
        address[] memory _addresses) external virtual override initializer {
        __Ownable_init();

        require(_tickers.length == 2, "Provide symbol and name");
        require(_addresses.length == 5, "Provide 5 addresses");
        require(_fees.length == 3, "Provide 3 fees");

        __ERC20Permit_init(_tickers[0]);
        __ERC20_init_unchained(_tickers[0], _tickers[1]);

        maxTxAmount = _maxTxAmount;
        maxWalletAmount = _maxWalletAmount;

        taxFee = _fees[0];
        marketingFee = _fees[1];
        burnFee = _fees[2];

        devWalletAddress = _addresses[0];
        marketingWalletAddress = _addresses[1];
        originator = tx.origin;

        tradingLimited = true;
        swapAndLiquifyEnabled = true;
        swapImpact = 1000;

        uniswapV2Router = IUniswapV2Router02(_addresses[2]);
        address uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());
        uniswapV2Pairs[uniswapV2Pair] = true;

        isExcludedFromFee[tx.origin] = true;
        isExcludedFromFee[owner()] = true;
        isExcludedFromFee[_addresses[4]] = true;
        isExcludedFromFee[address(this)] = true;
        isExcludedFromFee[devWalletAddress] = true;
        isExcludedFromFee[marketingWalletAddress] = true;

        _mint(_addresses[4], 100_000_000_000_000 * 1e9);

        IERC20Upgradeable(uniswapV2Pair).approve(address(uniswapV2Router), type(uint).max);
        _approve(address(this), address(uniswapV2Router), type(uint).max);
    }

    function createLiquidity(uint _amount) override external onlyOwner {
        address deployer = tx.origin;
        uint supply = balanceOf(address(this));
        uniswapV2Router.addLiquidityETH{value : address(this).balance}(address(this), _amount, 0, 0, deployer, block.timestamp);
        _transfer(address(this), deployer, supply - _amount);
    }

    function openTrading() override external onlyOwner {
        tradingOpened = block.timestamp;
    }

    /// @dev Default method required to receive eth
    receive() external payable {}

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 9;
    }

    function modifyExcludedFromFee(address _account, bool _add) external onlyOwner {
        if (_add) {
            require(!isExcludedFromFee[_account], "Account is already excluded");
            isExcludedFromFee[_account] = true;
        } else {
            require(isExcludedFromFee[_account], "Account is not excluded");
            isExcludedFromFee[_account] = false;
        }

        emit ExcludedFromFee(_account, _add);
    }

    function modifyBlacklist(address _account, bool _add) external onlyOwner {
        require(_account != address(uniswapV2Router), "WRONG_ADDRESS_ROUTER");
        if (_add) {
            require(!isBlackListedBot[_account], "ALREADY_BLACKLISTED");

            isBlackListedBot[_account] = true;
            blackListedBots.push(_account);
        } else {
            require(isBlackListedBot[_account], "NOT_BLACKLISTED");

            for (uint i = 0; i < blackListedBots.length; i++) {
                if (blackListedBots[i] == _account) {
                    blackListedBots[i] = blackListedBots[blackListedBots.length - 1];
                    isBlackListedBot[_account] = false;
                    blackListedBots.pop();
                    break;
                }
            }
        }

        emit BlacklistModified(_account, _add);
    }

    function setMainRouter(address _router, address _uniswapV2Pair) external onlyOwner {
        uniswapV2Pairs[_uniswapV2Pair] = true;
        uniswapV2Router = IUniswapV2Router02(_router);

        emit RouterLpPairChanged(_router, _uniswapV2Pair);
    }

    function setLiquidityPair(address _uniswapV2Pair, bool _isPair) external onlyOwner {
        uniswapV2Pairs[_uniswapV2Pair] = _isPair;

        emit LpPairChanged(_uniswapV2Pair, _isPair);
    }

    /// @notice modify fees
    /// @param _fees #0 - dev tax fee, #1 - marketing tax fee, #2 - burn fee, all with 0 decimals, so 10000 is 100%
    function setFees(uint[] memory _fees) external onlyOwner {
        require(_fees.length == 3, "Provide 3 fees");
        require((_fees[0] + _fees[1] + _fees[2]) / 100 <= 20, "FEES_TOO_HIGH");

        taxFee = _fees[0];
        marketingFee = _fees[1];
        burnFee = _fees[2];

        emit FeesChanged(taxFee, marketingFee, burnFee);
    }

    function setAddresses(address[] memory _addresses) external onlyOwner {
        require(_addresses.length >= 2, "Provide 2 addresses");

        devWalletAddress = _addresses[0];
        marketingWalletAddress = _addresses[1];
    }

    ///
    /// swap logic
    ///

    function setSwapAndLiquifyEnabled(bool _swapAndLiquifyEnabled) external onlyOwner {
        swapAndLiquifyEnabled = _swapAndLiquifyEnabled;

        emit SwapAndLiquifyEnabledUpdated(_swapAndLiquifyEnabled);
    }

    function swapTokens(uint _amount) private lockTheSwap {
        uint maxAddedToSlipPage = _amount * swapImpact / 10000;

        swapTokensForEth(MathUpgradeable.min(balanceOf(address(this)), maxAddedToSlipPage));
        manualSend();
    }

    function swapTokensForEth(uint _tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        // make the swap
        try uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            _tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        ) {
            // save the gas, not emit any event, its visible anyways
        } catch (bytes memory e) {
            emit SwapAndLiquifyFailed(e);
        }
    }

    function sendETHToWallet(address _wallet, uint _amount) private {
        payable(_wallet).transfer(_amount);
    }

    /// @notice manually trigger sell tokens for eth and send tokens to marketing wallet
    /// @param _amount amount in token decimals to swap from contract balance
    function manualSwapAmount(uint _amount) public onlyOwner {
        uint contractBalance = balanceOf(address(this));
        require(contractBalance >= _amount, "NOT_ENOUGH_BALANCE");

        swapTokensForEth(_amount);
    }

    /// @notice manually send gathered eth to marketing wallet
    function manualSend() public {
        uint taxFeeAmount = address(this).balance * taxFee / (taxFee + marketingFee);
        uint marketingFeeAmount = address(this).balance - taxFeeAmount;

        sendETHToWallet(devWalletAddress, taxFeeAmount);
        sendETHToWallet(marketingWalletAddress, marketingFeeAmount);
    }

    /// @notice manually swap tokens from contract balance and send all eth to marketing wallet
    /// @param _amount amount in token decimals to swap from contract balance
    function manualSwapAndSend(uint _amount) external onlyOwner {
        manualSwapAmount(_amount);
        manualSend();
    }

    /// @notice renounce-able version of recover tokens which can call anyone and send erc20 token to marketing wallet
    /// @param _token address of erc20 token
    function recoverTokens(IERC20Upgradeable _token) external virtual {
        require(address(_token) != address(this));

        _token.safeTransfer(marketingWalletAddress, _token.balanceOf(address(this)));
    }

    ///
    /// transfer logic
    ///

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint amount) public virtual override returns (bool) {
        return super.transfer(to, checkSwapTransferFees(msg.sender, to, amount));
    }


    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint`.
     *
     * Requirements:
     *
     * - `_from` and `_to` cannot be the zero address.
     * - `_from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``_from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address _from,
        address _to,
        uint _amount
    ) public virtual override returns (bool) {
        return super.transferFrom(_from, _to, checkSwapTransferFees(_from, _to, _amount));
    }

    function checkSwapTransferFees(address _from, address _to, uint _amount) private returns (uint _transferAmount) {
        // blacklisted bot cannot sell, buy again or transfer
        require(!isBlackListedBot[_from], "BLACKLISTED");
        require(!isBlackListedBot[_to], "BLACKLISTED");
        require(!isBlackListedBot[tx.origin], "BLACKLISTED");

        // trading is limited in first 15 minutes after open trading
        if (tradingLimited && tx.origin != originator) {
            require(tradingOpened > 0, "TRADING_NOT_OPENED");
            // don't allow to buy more than maxTxAmount except in block 0
            require(block.timestamp != tradingOpened && _amount <= maxTxAmount, "MAX_TX_AMOUNT_EXCEEDED");

            if (uniswapV2Pairs[_from]) {
                // don't allow to buy more than maxWalletAmount
                require(balanceOf(_to) + _amount <= maxWalletAmount, "MAX_WALLET_EXCEEDED");
                require(balanceOf(tx.origin) + _amount <= maxWalletAmount, "MAX_WALLET_EXCEEDED");

                // black list block 0 to sell what they bought
                if (block.timestamp == tradingOpened) {
                    isBlackListedBot[_to] = true;
                    blackListedBots.push(_to);
                }
            }

            // don't limit trading next time after 15 minutes
            if (block.timestamp > tradingOpened + 15 minutes) {
                tradingLimited = false;
            }
        }

        if (uniswapV2Pairs[_to] && !inSwapAndLiquify && swapAndLiquifyEnabled && tx.origin != originator) {
            swapTokens(_amount);
        }

        _transferAmount = transferFees(_from, _to, _amount);
    }

    function transferFees(address _from, address _to, uint _amount) private returns (uint) {
        (uint currentSwapFee, uint currentBurnFee) = (0, 0);
        bool includedInFee = uniswapV2Pairs[_from] || uniswapV2Pairs[_to];
        bool excludedFromFee = isExcludedFromFee[_from] || isExcludedFromFee[_to];
        if (includedInFee && !excludedFromFee) {
            (currentSwapFee, currentBurnFee) = (taxFee + marketingFee, burnFee);
        }

        (uint _transferAmount, uint _swapFeeAmount, uint _burnFeeAmount) = getValues(_amount, currentSwapFee, currentBurnFee);
        if (_swapFeeAmount > 0) _transfer(_from, address(this), _swapFeeAmount);
        if (_burnFeeAmount > 0) _burn(_from, _burnFeeAmount);
        return _transferAmount;
    }

    function getValues(uint _amount, uint _swapFee, uint _burnFee) private pure returns (uint _transferAmount, uint _swapFeeAmount, uint _burnFeeAmount) {
        _swapFeeAmount = _amount * _swapFee / 10000;
        _burnFeeAmount = _amount * _burnFee / 10000;
        _transferAmount = _amount - _swapFeeAmount - _burnFeeAmount;
    }

}