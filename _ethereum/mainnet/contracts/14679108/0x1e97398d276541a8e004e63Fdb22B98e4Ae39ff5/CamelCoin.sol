// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.2;

import "./ERC20Burnable.sol";
import "./AccessControl.sol";
import "./Pausable.sol";

import "./CamelLiquidityManager.sol";
import "./CamelSandstormCollector.sol";

/// @title Camel Coin ERC20 Token
/// @author metacrypt.org
contract CamelCoin is ERC20Burnable, Pausable, AccessControl {
    mapping(address => bool) private _isExcluded;

    CamelLiquidityManager public liquidityProcessor;
    CamelSandstormCollector public sandstormProcessor;

    address public walletTeam;
    address public walletMarketing;

    uint256 private constant FEE_DENOMINATOR = 10_000;

    uint256 public feeTeam; // % div FEE_DENOMINATOR
    uint256 public feeMarketing; // % div FEE_DENOMINATOR
    uint256 public feeLiquidity; // % div FEE_DENOMINATOR
    uint256 public feeSandstorm; // % div FEE_DENOMINATOR

    uint256 public walletLimit; // % div FEE_DENOMINATOR

    bool public isTradingEnabled = true;

    bool private inSwapAndLiquify = false;

    constructor() ERC20("Camel Coin", "CAMEL") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);

        setWalletLimit(1); // 0.01% initial
        setWalletExclusion(msg.sender, true);

        _mint(_msgSender(), 5_000_000 * (10**decimals()));

        setFees(200, 200, 100, 400); // Initial fees
    }

    function setFeeProcessors(address payable _liquidityProcessor, address payable _sandstormProcessor) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_liquidityProcessor != address(0), "Invalid liquidityProcessor");
        require(_sandstormProcessor != address(0), "Invalid sandstormProcessor");

        liquidityProcessor = CamelLiquidityManager(_liquidityProcessor);
        sandstormProcessor = CamelSandstormCollector(_sandstormProcessor);

        setWalletExclusion(_liquidityProcessor, true);
        setWalletExclusion(_sandstormProcessor, true);
    }

    function setWallets(address _teamWallet, address _marketingWallet) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_teamWallet != address(0), "Invalid Team Wallet");
        require(_marketingWallet != address(0), "Invalid Marketing Wallet");

        walletTeam = _teamWallet;
        walletMarketing = _marketingWallet;
    }

    function setWalletLimit(uint256 _walletLimit) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_walletLimit <= 2500 && _walletLimit >= 0, "Wallet limit must be less than 25%");
        walletLimit = _walletLimit;
    }

    function setWalletExclusion(address _wallet, bool _exclude) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _isExcluded[_wallet] = _exclude;
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
        uint256 _feeTeam,
        uint256 _feeMarketing,
        uint256 _feeLiquidity,
        uint256 _feeSandstorm
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_feeTeam <= 1000 && _feeTeam >= 0, "feeTeam must be less than 10%");
        require(_feeMarketing <= 1000 && _feeMarketing >= 0, "feeMarketing must be less than 10%");
        require(_feeLiquidity <= 1000 && _feeLiquidity >= 0, "feeLiquidity must be less than 10%");
        require(_feeSandstorm <= 1000 && _feeSandstorm >= 0, "feeSandstorm must be less than 10%");

        feeTeam = _feeTeam;
        feeMarketing = _feeMarketing;
        feeLiquidity = _feeLiquidity;
        feeSandstorm = _feeSandstorm;
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

            inSwapAndLiquify = false;
        }

        if (_isExcluded[sender] || _isExcluded[recipient]) {
            ERC20._transfer(sender, recipient, amount);
        } else {
            uint256 splitTeam = (amount * feeTeam) / FEE_DENOMINATOR;
            uint256 splitMarketing = (amount * feeMarketing) / FEE_DENOMINATOR;
            uint256 splitLiquidity = (amount * feeLiquidity) / FEE_DENOMINATOR;
            uint256 splitSandstorm = (amount * feeSandstorm) / FEE_DENOMINATOR;

            ERC20._transfer(sender, walletTeam, splitTeam);
            ERC20._transfer(sender, walletMarketing, splitMarketing);
            ERC20._transfer(sender, address(liquidityProcessor), splitLiquidity);
            ERC20._transfer(sender, address(sandstormProcessor), splitSandstorm);

            ERC20._transfer(sender, recipient, amount - splitTeam - splitMarketing - splitLiquidity - splitSandstorm);
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

        if (!_isExcluded[from] && !_isExcluded[to] && walletLimit != 0) {
            require(balanceOf(from) <= (totalSupply() * walletLimit) / FEE_DENOMINATOR, "Sender wallet limit reached");
            require(balanceOf(to) <= (totalSupply() * walletLimit) / FEE_DENOMINATOR, "Receiver wallet limit reached");
        }
    }
}
