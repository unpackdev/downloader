// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.7.6;
pragma abicoder v2;

import "./SafeMath.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";

import "./IFluidity.sol";
import "./ILiquidation.sol";
import "./IExchange.sol";
import "./IExchangeRates.sol";
import "./IFundToken.sol";
import "./ISystemSetting.sol";
import "./IDepot.sol";

import "./AddressResolver.sol";
import "./BasicMaths.sol";

contract Exchange is AddressResolver, IExchange {
    using SafeMath for uint;
    using BasicMaths for uint;
    using BasicMaths for bool;
    using SafeERC20 for IERC20;

    uint public _lastRebaseTime = 0;

    uint private constant E18 = 1e18;
    bytes32 private constant CONTRACT_FUNDTOKEN = "FundToken";
    bytes32 private constant CONTRACT_EXCHANGERATES = "ExchangeRates";
    bytes32 private constant CONTRACT_DEPOT = "Depot";
    bytes32 private constant CONTRACT_SYSTEMSETTING = "SystemSetting";
    bytes32 private constant CONTRACT_BASECURRENCY = "BaseCurrency";

    function fundToken() internal view returns (address) {
        return requireAndGetAddress(CONTRACT_FUNDTOKEN, "Missing FundToken Address");
    }

    function exchangeRates() internal view returns (IExchangeRates) {
        return IExchangeRates(requireAndGetAddress(CONTRACT_EXCHANGERATES, "Missing ExchangeRates Address"));
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

    function openPosition(bytes32 currencyKey, uint8 direction, uint16 level, uint position) external override returns (uint32) {
        systemSetting().checkOpenPosition(position, level);

        require(direction == 1 || direction == 2, "Direction Only Can Be 1 Or 2");

        (uint32 currencyKeyIdx, uint openPrice) = exchangeRates().rateForCurrency(currencyKey);
        uint32 index = getDepot().newPosition(msg.sender, openPrice, position, currencyKeyIdx, level, direction);

        emit OpenPosition(msg.sender, index, openPrice, currencyKey, direction, level, position);

        return index;
    }

    function addDeposit(uint32 positionId, uint margin) external override {
        systemSetting().checkAddDeposit(margin);
        getDepot().addDeposit(msg.sender, positionId, margin);
        emit MarginCall(msg.sender, positionId, margin);
    }

    function closePosition(uint32 positionId) external override {
        ISystemSetting setting = systemSetting();
        setting.requireSystemActive();

        IDepot depot = getDepot();

        Position memory position;
        (
            position.account,
            position.share,
            position.leveragedPosition,
            position.openPositionPrice,
            position.currencyKeyIdx,
            position.direction,
            position.margin,
            position.openRebaseLeft
        ) = depot.position(positionId);

        require(position.account == msg.sender, "Position Not Match");

        uint shareSubnetValue = position.share.mul(depot.netValue(position.direction)) / 1e18;
        uint serviceFee = position.leveragedPosition.mul(setting.positionClosingFee()) / 1e18;
        uint marginLoss = position.leveragedPosition.sub2Zero(shareSubnetValue);

        uint rateForCurrency = exchangeRates().rateForCurrencyByIdx(position.currencyKeyIdx);
        uint value = position.leveragedPosition.mul(rateForCurrency.diff(position.openPositionPrice)) / position.openPositionPrice;

        bool isProfit = (rateForCurrency >= position.openPositionPrice) == (position.direction == 1);

        if ( isProfit ) {
            require(position.margin.add(value) > serviceFee.add(marginLoss), "Bankrupted Liquidation");
        } else {
            require(position.margin > value.add(serviceFee).add(marginLoss), "Bankrupted Liquidation");
        }

        depot.closePosition(
            position,
            positionId,
            isProfit,
            value,
            marginLoss,
            serviceFee);

        emit ClosePosition(msg.sender, positionId, rateForCurrency, serviceFee, marginLoss, isProfit, value);
    }

    function rebase() external override {
        IDepot depot = getDepot();
        ISystemSetting setting = systemSetting();
        uint time = block.timestamp;

        require(_lastRebaseTime + setting.rebaseInterval() <= time, "Not Meet Rebase Interval");
        require(depot.liquidityPool() > 0, "liquidity pool must more than 0");

        (uint totalMarginLong, uint totalMarginShort, uint totalValueLong, uint totalValueShort) = depot.getTotalPositionState();
        uint D = (totalValueLong.diff(totalValueShort)).mul(1e18) / depot.liquidityPool();

        require(D > setting.imbalanceThreshold(), "not meet imbalance threshold");

        uint lpd = depot.liquidityPool().mul(setting.imbalanceThreshold()) / 1e18;
        uint r = totalValueLong.diff(totalValueShort).sub(lpd) / setting.rebaseRate();
        uint rebaseLeft;

        if(totalValueLong > totalValueShort) {
            require(totalMarginLong >= r, "Long Margin Pool Has Bankrupted");
            rebaseLeft = E18.sub(r.mul(1e18) / totalValueLong);
        } else {
            require(totalMarginShort >= r, "Short Margin Pool Has Bankrupted");
            rebaseLeft = E18.sub(r.mul(1e18) / totalValueShort);
        }

        _lastRebaseTime = time;
        depot.updateSubTotalState(totalValueLong > totalValueShort,
            r.add(depot.liquidityPool()),
            r, r, 0, rebaseLeft);

        emit Rebase(time, r);
    }

    event OpenPosition(address indexed sender, uint32 positionId, uint price, bytes32 currencyKey, uint8 direction, uint16 level, uint position);
    event MarginCall(address indexed sender, uint32 positionId, uint margin);
    event ClosePosition(address indexed sender, uint32 positionId, uint price, uint serviceFee, uint marginLoss, bool isProfit, uint value);
    event Rebase(uint time, uint r);
}
