// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.2;

import "./ERC20Burnable.sol";
import "./AccessControl.sol";
import "./Pausable.sol";

import "./CamelLiquidityProcessor.sol";
import "./CamelSandstormCollector.sol";
import "./CamelConverterProcessor.sol";

/// @title Camel Coin ERC20 Token
/// @author metacrypt.org
contract CamelCoin is ERC20Burnable, Pausable, AccessControl {
    mapping(address => bool) public _isExcludedFee;
    mapping(address => bool) public _isExcludedWallet;

    CamelLiquidityProcessor public liquidityProcessor;
    CamelSandstormCollector public sandstormProcessor;
    CamelConverterProcessor public converterProcessor;

    uint256 private constant FEE_DENOMINATOR = 100_000;

    uint256 public feeLiquidity; // % div FEE_DENOMINATOR
    uint256 public feeSandstorm; // % div FEE_DENOMINATOR
    uint256 public feeConverter; // % div FEE_DENOMINATOR

    uint256 private walletLimit; // % div FEE_DENOMINATOR

    bool public isTradingEnabled = true;

    bool private inSwapAndLiquify = false;

    constructor() ERC20("Camel Coin", "CAMEL") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);

        setFeeExclusion(msg.sender, true);
        setWalletExclusion(msg.sender, true);

        _mint(_msgSender(), 5_000_000 * (10**decimals()));

        setFees(4_000, 1_000, 4_000); // Initial fees
    }

    function setFeeProcessors(
        address payable _liquidityProcessor,
        address payable _sandstormProcessor,
        address payable _converterProcessor
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_liquidityProcessor != address(0), "Invalid liquidityProcessor");
        require(_sandstormProcessor != address(0), "Invalid sandstormProcessor");
        require(_converterProcessor != address(0), "Invalid converterProcessor");

        liquidityProcessor = CamelLiquidityProcessor(_liquidityProcessor);
        sandstormProcessor = CamelSandstormCollector(_sandstormProcessor);
        converterProcessor = CamelConverterProcessor(_converterProcessor);

        setFeeExclusion(_liquidityProcessor, true);
        setFeeExclusion(_sandstormProcessor, true);
        setFeeExclusion(_converterProcessor, true);

        setWalletExclusion(_liquidityProcessor, true);
        setWalletExclusion(_sandstormProcessor, true);
        setWalletExclusion(_converterProcessor, true);

        setWalletExclusion(liquidityProcessor.uniswapPair(), true);
    }

    function setWalletLimit(uint256 _walletLimit) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_walletLimit <= 25_000 && _walletLimit >= 0, "Wallet limit must be less than 25%");
        walletLimit = _walletLimit;
    }

    function setFeeExclusion(address _wallet, bool _exclude) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_wallet != address(0), "Invalid Wallet");

        _isExcludedFee[_wallet] = _exclude;
    }

    function setFeeExclusion(address[] calldata _wallet, bool _exclude) public onlyRole(DEFAULT_ADMIN_ROLE) {
        for (uint256 i = 0; i < _wallet.length; i++) {
            setFeeExclusion(_wallet[i], _exclude);
        }
    }

    function setWalletExclusion(address _wallet, bool _exclude) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_wallet != address(0), "Invalid Wallet");

        _isExcludedWallet[_wallet] = _exclude;
    }

    function setWalletExclusion(address[] calldata _wallet, bool _exclude) public onlyRole(DEFAULT_ADMIN_ROLE) {
        for (uint256 i = 0; i < _wallet.length; i++) {
            setWalletExclusion(_wallet[i], _exclude);
        }
    }

    function setTradingEnabled(bool _enabled) external onlyRole(DEFAULT_ADMIN_ROLE) {
        isTradingEnabled = _enabled;
    }

    function setTransactionsPaused(bool _p) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (_p) {
            _pause();
        } else {
            _unpause();
        }
    }

    function setFees(
        uint256 _feeConverter,
        uint256 _feeLiquidity,
        uint256 _feeSandstorm
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_feeLiquidity <= 10_000 && _feeLiquidity >= 0, "feeLiquidity must be less than 10%");
        require(_feeSandstorm <= 10_000 && _feeSandstorm >= 0, "feeSandstorm must be less than 10%");
        require(_feeConverter <= 10_000 && _feeConverter >= 0, "feeConverter must be less than 10%");

        feeLiquidity = _feeLiquidity;
        feeSandstorm = _feeSandstorm;
        feeConverter = _feeConverter;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal override {
        // Call processors if it's a sell tx
        if (recipient == liquidityProcessor.uniswapPair() && !inSwapAndLiquify) {
            inSwapAndLiquify = true;

            liquidityProcessor.processFunds();
            sandstormProcessor.processFunds();
            converterProcessor.processFunds();

            inSwapAndLiquify = false;
        }

        if (_isExcludedFee[sender] || _isExcludedFee[recipient]) {
            ERC20._transfer(sender, recipient, amount);
        } else {
            uint256 splitLiquidity = (amount * feeLiquidity) / FEE_DENOMINATOR;
            uint256 splitSandstorm = (amount * feeSandstorm) / FEE_DENOMINATOR;
            uint256 splitConverter = (amount * feeConverter) / FEE_DENOMINATOR;

            ERC20._transfer(sender, address(liquidityProcessor), splitLiquidity);
            ERC20._transfer(sender, address(sandstormProcessor), splitSandstorm);
            ERC20._transfer(sender, address(converterProcessor), splitConverter);

            ERC20._transfer(sender, recipient, amount - splitLiquidity - splitSandstorm - splitConverter);
        }
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override whenNotPaused {
        super._beforeTokenTransfer(from, to, amount);

        if (!isTradingEnabled) {
            require(to != liquidityProcessor.uniswapPair() && from != liquidityProcessor.uniswapPair(), "Trading is disabled");
        }
    }

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        super._afterTokenTransfer(from, to, amount);

        if (walletLimit != 0) {
            if (!_isExcludedWallet[from]) {
                require(balanceOf(from) <= (totalSupply() * walletLimit) / FEE_DENOMINATOR, "Sender wallet limit reached");
            }
            if (!_isExcludedWallet[to]) {
                require(balanceOf(to) <= (totalSupply() * walletLimit) / FEE_DENOMINATOR, "Receiver wallet limit reached");
            }
        }
    }
}
