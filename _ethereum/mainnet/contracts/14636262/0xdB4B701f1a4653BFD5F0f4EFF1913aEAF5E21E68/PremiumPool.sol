// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.0;

import "./IERC20.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./Address.sol";
import "./IExchangeAgent.sol";
import "./TransferHelper.sol";
import "./IPremiumPool.sol";

contract PremiumPool is IPremiumPool, ReentrancyGuard, Ownable {
    using Address for address;

    address public exchangeAgent;
    address public UNO_TOKEN;
    address public USDC_TOKEN;
    mapping(address => bool) public availableCurrencies;
    address[] public availableCurrencyList;
    mapping(address => bool) public whiteList;

    address public constant burnAddress = 0x000000000000000000000000000000000000dEaD;
    mapping(address => uint256) public SSRP_PREMIUM;
    mapping(address => uint256) public SSIP_PREMIUM;
    mapping(address => uint256) public BACK_BURN_UNO_PREMIUM;
    uint256 public SSRP_PREMIUM_ETH;
    uint256 public SSIP_PREMIUM_ETH;
    uint256 public BACK_BURN_PREMIUM_ETH;

    uint256 private MAX_INTEGER = type(uint256).max;

    event PremiumWithdraw(address indexed _currency, address indexed _to, uint256 _amount);
    event LogBuyBackAndBurn(address indexed _operator, address indexed _premiumPool, uint256 _unoAmount);
    event LogCollectPremium(address indexed _from, address _premiumCurrency, uint256 _premiumAmount);
    event LogDepositToSyntheticSSRPRewarder(address indexed _rewarder, uint256 _amountDeposited);
    event LogDepositToSyntheticSSIPRewarder(address indexed _rewarder, address indexed _currency, uint256 _amountDeposited);
    event LogAddCurrency(address indexed _premiumPool, address indexed _currency);
    event LogRemoveCurrency(address indexed _premiumPool, address indexed _currency);
    event LogMaxApproveCurrency(address indexed _premiumPool, address indexed _currency, address indexed _to);
    event LogMaxDestroyCurrencyAllowance(address indexed _premiumPool, address indexed _currency, address indexed _to);
    event LogAddWhiteList(address indexed _premiumPool, address indexed _whiteListAddress);
    event LogRemoveWhiteList(address indexed _premiumPool, address indexed _whiteListAddress);

    constructor(
        address _exchangeAgent,
        address _unoToken,
        address _usdcToken,
        address _multiSigWallet
    ) {
        require(_exchangeAgent != address(0), "UnoRe: zero exchangeAgent address");
        require(_unoToken != address(0), "UnoRe: zero UNO address");
        require(_usdcToken != address(0), "UnoRe: zero USDC address");
        require(_multiSigWallet != address(0), "UnoRe: zero multisigwallet address");
        exchangeAgent = _exchangeAgent;
        UNO_TOKEN = _unoToken;
        USDC_TOKEN = _usdcToken;
        whiteList[msg.sender] = true;
        transferOwnership(_multiSigWallet);
    }

    modifier onlyAvailableCurrency(address _currency) {
        require(availableCurrencies[_currency], "UnoRe: not allowed currency");
        _;
    }

    modifier onlyWhiteList() {
        require(whiteList[msg.sender], "UnoRe: not white list address");
        _;
    }

    receive() external payable {}

    function collectPremiumInETH() external payable override nonReentrant onlyWhiteList {
        uint256 _premiumAmount = msg.value;
        uint256 _premium_SSRP = (_premiumAmount * 1000) / 10000;
        uint256 _premium_SSIP = (_premiumAmount * 7000) / 10000;
        SSRP_PREMIUM_ETH = SSRP_PREMIUM_ETH + _premium_SSRP;
        SSIP_PREMIUM_ETH = SSIP_PREMIUM_ETH + _premium_SSIP;
        BACK_BURN_PREMIUM_ETH = BACK_BURN_PREMIUM_ETH + (_premiumAmount - _premium_SSRP - _premium_SSIP);
        emit LogCollectPremium(msg.sender, address(0), _premiumAmount);
    }

    function collectPremium(address _premiumCurrency, uint256 _premiumAmount)
        external
        override
        nonReentrant
        onlyAvailableCurrency(_premiumCurrency)
        onlyWhiteList
    {
        require(IERC20(_premiumCurrency).balanceOf(msg.sender) >= _premiumAmount, "UnoRe: premium balance overflow");
        TransferHelper.safeTransferFrom(_premiumCurrency, msg.sender, address(this), _premiumAmount);
        uint256 _premium_SSRP = (_premiumAmount * 1000) / 10000;
        uint256 _premium_SSIP = (_premiumAmount * 7000) / 10000;
        SSRP_PREMIUM[_premiumCurrency] = SSRP_PREMIUM[_premiumCurrency] + _premium_SSRP;
        SSIP_PREMIUM[_premiumCurrency] = SSIP_PREMIUM[_premiumCurrency] + _premium_SSIP;
        BACK_BURN_UNO_PREMIUM[_premiumCurrency] =
            BACK_BURN_UNO_PREMIUM[_premiumCurrency] +
            (_premiumAmount - _premium_SSRP - _premium_SSIP);
        emit LogCollectPremium(msg.sender, _premiumCurrency, _premiumAmount);
    }

    function depositToSyntheticSSRPRewarder(address _rewarder) external onlyOwner nonReentrant {
        require(_rewarder != address(0), "UnoRe: zero address");
        require(_rewarder.isContract(), "UnoRe: no contract address");
        uint256 usdcAmountToDeposit = 0;
        if (SSRP_PREMIUM_ETH > 0) {
            TransferHelper.safeTransferETH(exchangeAgent, SSRP_PREMIUM_ETH);
            uint256 convertedAmount = IExchangeAgent(exchangeAgent).convertForToken(address(0), USDC_TOKEN, SSRP_PREMIUM_ETH);
            usdcAmountToDeposit += convertedAmount;
            SSRP_PREMIUM_ETH = 0;
        }
        for (uint256 ii = 0; ii < availableCurrencyList.length; ii++) {
            if (SSRP_PREMIUM[availableCurrencyList[ii]] > 0) {
                if (availableCurrencyList[ii] == USDC_TOKEN) {
                    usdcAmountToDeposit += SSRP_PREMIUM[availableCurrencyList[ii]];
                } else {
                    uint256 convertedUSDCAmount = IExchangeAgent(exchangeAgent).convertForToken(
                        availableCurrencyList[ii],
                        USDC_TOKEN,
                        SSRP_PREMIUM[availableCurrencyList[ii]]
                    );
                    usdcAmountToDeposit += convertedUSDCAmount;
                }
                SSRP_PREMIUM[availableCurrencyList[ii]] = 0;
            }
        }
        if (usdcAmountToDeposit > 0) {
            TransferHelper.safeTransfer(USDC_TOKEN, _rewarder, usdcAmountToDeposit);
            emit LogDepositToSyntheticSSRPRewarder(_rewarder, usdcAmountToDeposit);
        }
    }

    function depositToSyntheticSSIPRewarder(
        address _currency,
        address _rewarder,
        uint256 _amount
    ) external onlyOwner nonReentrant {
        require(_rewarder != address(0), "UnoRe: zero address");
        require(_rewarder.isContract(), "UnoRe: no contract address");
        if (_currency == address(0) && SSIP_PREMIUM_ETH > 0) {
            require(_amount <= SSIP_PREMIUM_ETH, "UnoRe: premium balance overflow");
            TransferHelper.safeTransferETH(_rewarder, _amount);
            SSIP_PREMIUM_ETH -= _amount;
            emit LogDepositToSyntheticSSIPRewarder(_rewarder, _currency, _amount);
        } else {
            if (availableCurrencies[_currency] && SSIP_PREMIUM[_currency] > 0) {
                require(_amount <= SSIP_PREMIUM[_currency], "UnoRe: premium balance overflow");
                TransferHelper.safeTransfer(_currency, _rewarder, _amount);
                SSIP_PREMIUM[_currency] -= _amount;
                emit LogDepositToSyntheticSSIPRewarder(_rewarder, _currency, _amount);
            }
        }
    }

    function buyBackAndBurn() external onlyOwner {
        uint256 unoAmount = 0;
        if (BACK_BURN_PREMIUM_ETH > 0) {
            TransferHelper.safeTransferETH(exchangeAgent, BACK_BURN_PREMIUM_ETH);
            unoAmount += IExchangeAgent(exchangeAgent).convertForToken(address(0), UNO_TOKEN, BACK_BURN_PREMIUM_ETH);
            BACK_BURN_PREMIUM_ETH = 0;
        }
        for (uint256 ii = 0; ii < availableCurrencyList.length; ii++) {
            if (BACK_BURN_UNO_PREMIUM[availableCurrencyList[ii]] > 0) {
                uint256 convertedAmount = IExchangeAgent(exchangeAgent).convertForToken(
                    availableCurrencyList[ii],
                    UNO_TOKEN,
                    BACK_BURN_UNO_PREMIUM[availableCurrencyList[ii]]
                );
                unoAmount += convertedAmount;
                BACK_BURN_UNO_PREMIUM[availableCurrencyList[ii]] = 0;
            }
        }
        if (unoAmount > 0) {
            TransferHelper.safeTransfer(UNO_TOKEN, burnAddress, unoAmount);
        }
        emit LogBuyBackAndBurn(msg.sender, address(this), unoAmount);
    }

    function withdrawPremium(
        address _currency,
        address _to,
        uint256 _amount
    ) external override onlyOwner {
        require(_to != address(0), "UnoRe: zero address");
        require(_amount > 0, "UnoRe: zero amount");
        if (_currency == address(0)) {
            require(address(this).balance >= _amount, "UnoRe: Insufficient Premium");
            TransferHelper.safeTransferETH(_to, _amount);
        } else {
            require(IERC20(_currency).balanceOf(address(this)) >= _amount, "UnoRe: Insufficient Premium");
            TransferHelper.safeTransfer(_currency, _to, _amount);
        }
        emit PremiumWithdraw(_currency, _to, _amount);
    }

    function addCurrency(address _currency) external onlyOwner {
        require(!availableCurrencies[_currency], "Already available");
        availableCurrencies[_currency] = true;
        availableCurrencyList.push(_currency);
        maxApproveCurrency(_currency, exchangeAgent);
        emit LogAddCurrency(address(this), _currency);
    }

    function removeCurrency(address _currency) external onlyOwner {
        require(availableCurrencies[_currency], "Not available yet");
        availableCurrencies[_currency] = false;
        uint256 len = availableCurrencyList.length;
        address lastCurrency = availableCurrencyList[len - 1];
        for (uint256 ii = 0; ii < len; ii++) {
            if (_currency == availableCurrencyList[ii]) {
                availableCurrencyList[ii] = lastCurrency;
                availableCurrencyList.pop();
                destroyCurrencyAllowance(_currency, exchangeAgent);
                return;
            }
        }
        emit LogRemoveCurrency(address(this), _currency);
    }

    function maxApproveCurrency(address _currency, address _to) public onlyOwner nonReentrant {
        if (IERC20(_currency).allowance(address(this), _to) < MAX_INTEGER) {
            TransferHelper.safeApprove(_currency, _to, MAX_INTEGER);
            emit LogMaxApproveCurrency(address(this), _currency, _to);
        }
    }

    function destroyCurrencyAllowance(address _currency, address _to) public onlyOwner nonReentrant {
        if (IERC20(_currency).allowance(address(this), _to) > 0) {
            TransferHelper.safeApprove(_currency, _to, 0);
            emit LogMaxDestroyCurrencyAllowance(address(this), _currency, _to);
        }
    }

    function addWhiteList(address _whiteListAddress) external onlyOwner {
        require(_whiteListAddress != address(0), "UnoRe: zero address");
        require(!whiteList[_whiteListAddress], "UnoRe: white list already");
        whiteList[_whiteListAddress] = true;
        emit LogAddWhiteList(address(this), _whiteListAddress);
    }

    function removeWhiteList(address _whiteListAddress) external onlyOwner {
        require(_whiteListAddress != address(0), "UnoRe: zero address");
        require(whiteList[_whiteListAddress], "UnoRe: white list removed or unadded already");
        whiteList[_whiteListAddress] = false;
        emit LogRemoveWhiteList(address(this), _whiteListAddress);
    }
}
