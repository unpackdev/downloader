// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.7.6;

import "./SafeMath.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";

import "./IFluidity.sol";
import "./IFundToken.sol";
import "./ISystemSetting.sol";
import "./IDepot.sol";
import "./IExchange.sol";

import "./AddressResolver.sol";

contract Fluidity is AddressResolver, IFluidity {
    using SafeMath for uint;
    using SafeERC20 for IERC20;

    bytes32 private constant CONTRACT_FUNDTOKEN = "FundToken";
    bytes32 private constant CONTRACT_DEPOT = "Depot";
    bytes32 private constant CONTRACT_SYSTEMSETTING = "SystemSetting";
    bytes32 private constant CONTRACT_BASECURRENCY = "BaseCurrency";

    function fundToken() internal view returns (address) {
        return requireAndGetAddress(CONTRACT_FUNDTOKEN, "Missing FundToken Address");
    }

    function systemSetting() internal view returns (ISystemSetting) {
        return ISystemSetting(requireAndGetAddress(CONTRACT_SYSTEMSETTING, "Missing SystemSetting Address"));
    }

    function depotAddress() internal view returns (address) {
        return requireAndGetAddress(CONTRACT_DEPOT, "Missing Depot Address");
    }

    function getDepot() internal view returns (IDepot) {
        return IDepot(depotAddress());
    }

    function baseCurrency() internal view returns (IERC20) {
        return IERC20(requireAndGetAddress(CONTRACT_BASECURRENCY, "Missing BaseCurrency Address"));
    }

    function _fundTokenPrice() internal view returns (uint) {
        uint totalSupply = IERC20(fundToken()).totalSupply();
        require(totalSupply > 0, "No Fund Token Minted");
        return getDepot().liquidityPool().mul(1e18) / totalSupply;
    }

    function initialFunding(uint value) external override {
        ISystemSetting setting = systemSetting();
        setting.requireSystemActive();

        IDepot depot = getDepot();
        IERC20 bCurrency = baseCurrency();

        address msgSender = msg.sender;
        address depotAddr = depotAddress();

        require(!depot.initialFundingCompleted(), 'Initial Funding Has Completed');
        require(bCurrency.allowance(msgSender, depotAddr) >= value, "USDT Approved To Depot Is Not Enough");
        require(
            IERC20(fundToken()).totalSupply().add(value) <= setting.maxInitialLiquidityFunding(),
            "Over Max Initial Liquidity Funding");

        depot.addLiquidity(msgSender, value);
        IFundToken(fundToken()).mint(msgSender, value);

        emit InitialFunding(msgSender, value);
    }

    function closeInitialFunding() external override onlyOwner {
        ISystemSetting setting = systemSetting();
        setting.requireSystemActive();
        require(IERC20(fundToken()).totalSupply() == setting.maxInitialLiquidityFunding(),
            "Not Meet Max Initial Liquidity Funding");
        getDepot().completeInitialFunding();
    }

    function fundLiquidity(uint value) external override {
        ISystemSetting setting = systemSetting();
        setting.requireSystemActive();
        IDepot depot = getDepot();
        require(depot.initialFundingCompleted(), 'Initial Funding Has Not Completed');

        address msgSender = msg.sender;
        uint price = _fundTokenPrice();
        require(price > 0, "lp price should bigger than 0");

        uint baseCurrencyValue = value.mul(price) / 1e18;
        require(baseCurrency().allowance(msgSender, depotAddress()) >= baseCurrencyValue,
            "USDT Approved To Exchange Is Not Enough");
        require(depot.liquidityPool().add(baseCurrencyValue) <= setting.constantMarginRatio().mul(depot.totalValue()) / 1e18,
            "Over Max Liquidity Funding");

        depot.addLiquidity(msgSender, baseCurrencyValue);
        IFundToken(fundToken()).mint(msgSender, value);

        emit FundLiquidity(msgSender, value, price);
    }

    function withdrawLiquidity(uint value) external override {
        ISystemSetting setting = systemSetting();
        setting.requireSystemActive();
        IDepot depot = getDepot();
        require(depot.initialFundingCompleted(), 'Initial Funding Has Not Completed');

        address msgSender = msg.sender;
        uint price = _fundTokenPrice();

        require(IERC20(fundToken()).balanceOf(msgSender) >= value, "Fund Token Is Not Enough");
        IFundToken(fundToken()).burn(msgSender, value);

        depot.withdrawLiquidity(msgSender, value.mul(price) / 1e18);

        emit WithdrawLiquidity(msgSender, value, price);
    }

    function fundTokenPrice() external override view returns (uint) {
        return _fundTokenPrice();
    }

    function availableToFund() external override view returns (uint) {
        ISystemSetting setting = systemSetting();
        IDepot depot = getDepot();

        if (!depot.initialFundingCompleted()) {
            return setting.maxInitialLiquidityFunding() - depot.liquidityPool();
        }

        if (depot.liquidityPool() >= setting.constantMarginRatio().mul(depot.totalValue()) / 1e18) {
            return 0;
        }

        return setting.constantMarginRatio().mul(depot.totalValue()) / 1e18 - depot.liquidityPool();
    }

    event InitialFunding(address indexed subscriber, uint value);
    event FundLiquidity(address indexed subscriber, uint value, uint price);
    event WithdrawLiquidity(address indexed redempter, uint value, uint price);
}
