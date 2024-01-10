// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./Ownable.sol";

import "./Context.sol";
import "./IERC20.sol";
import "./IERC20Metadata.sol";
import "./ERC20.sol";
import "./SafeMath.sol";

import "./Strings.sol";

import "./IUniswapV2Factory.sol";
import "./IUniswapV2Pair.sol";
import "./IUniswapV2Router02.sol";

abstract contract SERC20 is ERC20, Ownable {
    using SafeMath for uint256;

    uint256[] private buyTaxes;
    uint256 private buyTotalTax = 0;
    uint256 private buyTaxThreshold;

    uint256[] private sellTaxes;
    uint256 private sellTotalTax = 0;
    uint256 private sellTaxThreshold;

    bool private tradingEnabled = false;
    uint256 private tradingEnabledAt;
    uint256 private tradingEnabledBlock;

    uint256 private maxTx;
    uint256 private maxWallet;

    address private immutable pair;
    bool private pairSet;
    IUniswapV2Router02 private immutable router;
    bool private routerSet;

    mapping(address => bool) private blacklist;

    constructor(
        string memory _name,
        string memory _symbol,
        address _router,
        uint256 _buyTaxThreshold,
        uint256 _sellTaxThreshold
    ) ERC20(_name, _symbol) {
        uint256 _totalTaxThreshold = _buyTaxThreshold + _sellTaxThreshold;

        require(
            _totalTaxThreshold <= 35,
            "sERC20: Round trip taxthreshold can not be higher than 35%"
        );

        buyTaxThreshold = _buyTaxThreshold;
        sellTaxThreshold = _sellTaxThreshold;

        require(
            _router != address(0),
            "sERC20: Can not set router to 0 address"
        );

        require(
            _router != address(0x000000000000000000000000000000000000dEaD),
            "sERC20: Can not set router to NULL address"
        );

        require(
            _router != address(this),
            "sERC20: Can not set router to contract address"
        );

        require(
            !blacklist[_router],
            "sERC20: Can not set router to a blacklisted address"
        );

        router = IUniswapV2Router02(_router);
        pair = IUniswapV2Factory(router.factory()).createPair(
            address(this),
            router.WETH()
        );

        routerSet = true;
        pairSet = true;
    }

    function _sercVerifiyTaxes(uint256[] memory _taxes, bool _isBuy)
        internal
        view
    {
        uint256 total = 0;

        for (uint256 i = 0; i < _taxes.length; i++) {
            total += _taxes[i];
        }

        uint256 taxThreshold;

        if (_isBuy) {
            taxThreshold = buyTaxThreshold;
        } else {
            taxThreshold = sellTaxThreshold;
        }

        require(
            total <= taxThreshold,
            string(
                abi.encodePacked(
                    "sERC20: Tax rate can not be set higher than ",
                    Strings.toString(taxThreshold),
                    "%"
                )
            )
        );
    }

    function _sercSetTaxes(uint256[] memory _taxes, bool _isBuy) internal {
        _sercVerifiyTaxes(_taxes, _isBuy);

        uint256 total = 0;

        if (_isBuy) {
            buyTaxes = _taxes;

            for (uint256 i = 0; i < _taxes.length; i++) {
                total += _taxes[i];
            }

            buyTotalTax = total;
        } else {
            sellTaxes = _taxes;

            for (uint256 i = 0; i < _taxes.length; i++) {
                total += _taxes[i];
            }

            sellTotalTax = total;
        }
    }

    function _sercRouter() internal view returns (IUniswapV2Router02) {
        return router;
    }

    function _sercPair() internal view returns (address) {
        return pair;
    }

    function sercBuyTax() public view returns (uint256[] memory) {
        return _sercBuyTax();
    }

    function _sercBuyTax() internal view returns (uint256[] memory) {
        return buyTaxes;
    }

    function sercBuyTotalTax() public view returns (uint256) {
        return _sercBuyTotalTax();
    }

    function _sercBuyTotalTax() internal view returns (uint256) {
        return buyTotalTax;
    }

    function sercSellTax() public view returns (uint256[] memory) {
        return _sercSellTax();
    }

    function _sercSellTax() internal view returns (uint256[] memory) {
        return sellTaxes;
    }

    function sercSellTotalTax() public view returns (uint256) {
        return _sercSellTotalTax();
    }

    function _sercSellTotalTax() internal view returns (uint256) {
        return sellTotalTax;
    }

    function sercMaxTx() public view returns (uint256) {
        return _sercMaxTx();
    }

    function _sercMaxTx() internal view returns (uint256) {
        return maxTx;
    }

    function sercSetMaxTx(uint256 _maxTx) external onlyOwner {
        require(_maxTx >= maxTx, "sERC20: Can not lower the max tx amount");

        require(
            _maxTx <= maxWallet,
            "sERC20: Can not set max tx higher than the max wallet"
        );

        maxTx = _maxTx;
    }

    function sercMaxWallet() public view returns (uint256) {
        return _sercMaxWallet();
    }

    function _sercMaxWallet() internal view returns (uint256) {
        return maxWallet;
    }

    function sercSetMaxWallet(uint256 _maxWallet) external onlyOwner {
        require(
            _maxWallet >= maxWallet,
            "sERC20: Can not lower the max wallet amount"
        );

        require(
            _maxWallet >= maxTx,
            "sERC20: Can not set max wallet lower than the max tx"
        );

        maxWallet = _maxWallet;
    }

    function sercIsBlacklisted(address _addr) public view returns (bool) {
        return _sercIsBlacklisted(_addr);
    }

    function _sercIsBlacklisted(address _addr) internal view returns (bool) {
        return blacklist[_addr];
    }

    function sercSetBlacklisted(address[] memory _addrList, bool _isBlacklisted)
        external
        onlyOwner
    {
        _sercSetBlacklisted(_addrList, _isBlacklisted);
    }

    function _sercSetBlacklisted(
        address[] memory _addrList,
        bool _isBlacklisted
    ) internal {
        if (tradingEnabled) {
            require(
                block.timestamp <= tradingEnabledAt + 10 minutes,
                "sERC20: Can not blacklist more than 10 minutes after trading has been enabled"
            );
        }

        for (uint256 i = 0; i < _addrList.length; i++) {
            require(
                pair != _addrList[i],
                "sERC20: Can not blacklist the pair address"
            );
            require(
                address(router) != _addrList[i],
                "sERC20: Can not blacklist the router address"
            );
            require(
                address(this) != _addrList[i],
                "sERC20: Can not blacklist the contract address"
            );
            blacklist[_addrList[i]] = _isBlacklisted;
        }
    }

    function sercTradingEnabled() public view returns (bool) {
        return _sercTradingEnabled();
    }

    function _sercTradingEnabled() internal view returns (bool) {
        return tradingEnabled;
    }

    function sercSetTradingEnabled() public virtual onlyOwner {
        require(!tradingEnabled, "sERC20: Trading is already enabled");
        require(
            maxTx != 0,
            "sERC20: Max transaction must be initilised first."
        );
        require(maxWallet != 0, "sERC20: Max wallet must be initilised first.");

        tradingEnabledAt = block.timestamp;
        tradingEnabledBlock = block.number;
        tradingEnabled = true;
    }
}
