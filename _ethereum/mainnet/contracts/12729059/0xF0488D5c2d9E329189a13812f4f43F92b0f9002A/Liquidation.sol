// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.7.6;
pragma abicoder v2;

import "./SafeMath.sol";
import "./IERC20.sol";

import "./AddressResolver.sol";
import "./BasicMaths.sol";

import "./ISystemSetting.sol";
import "./IDepot.sol";
import "./ILiquidation.sol";
import "./IExchangeRates.sol";

contract Liquidation is AddressResolver, ILiquidation {
    using SafeMath for uint;
    using BasicMaths for uint;
    using BasicMaths for bool;

    bytes32 private constant CONTRACT_FUNDTOKEN = "FundToken";
    bytes32 private constant CONTRACT_EXCHANGERATES = "ExchangeRates";
    bytes32 private constant CONTRACT_DEPOT = "Depot";
    bytes32 private constant CONTRACT_SYSTEMSETTING = "SystemSetting";
    bytes32 private constant CONTRACT_BASECURRENCY = "BaseCurrency";

    /* -------------  contract interfaces  ------------- */
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


    function liquidate(uint32 positionId) external override {
        ISystemSetting setting = systemSetting();
        setting.requireSystemActive();
        IDepot depot = getDepot();

        require(IERC20(fundToken()).balanceOf(msg.sender) >= setting.minFundTokenRequired(),
            "Not Meet Min Fund Token Required");

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

        require(position.account != address(0), "Position Not Match");

        uint serviceFee = position.leveragedPosition.mul(setting.positionClosingFee()) / 1e18;
        uint marginLoss = depot.calMarginLoss(position.leveragedPosition, position.share, position.direction);

        uint rateForCurrency = exchangeRates().rateForCurrencyByIdx(position.currencyKeyIdx);
        uint value = position.leveragedPosition.mul(rateForCurrency.diff(position.openPositionPrice)).div(position.openPositionPrice);

        bool isProfit = (rateForCurrency >= position.openPositionPrice) == (position.direction == 1);
        uint feeAddML = serviceFee.add(marginLoss);

        if ( isProfit ) {
            require(position.margin.add(value) > feeAddML, "Position Cannot Be Liquidated in profit");
        } else {
            require(position.margin > value.add(feeAddML), "Position Cannot Be Liquidated in not profit");
        }

        require(
            isProfit.addOrSub(position.margin, value).sub(feeAddML) < position.margin.mul(setting.marginRatio()) / 1e18,
            "Position Cannot Be Liquidated by not in marginRatio");

        uint liqReward = isProfit.addOrSub(position.margin, value).sub(feeAddML);

        depot.liquidate(
            position,
            positionId,
            isProfit,
            serviceFee,
            value,
            marginLoss,
            liqReward,
            msg.sender);

        emit Liquidate(
            msg.sender,
            positionId,
            rateForCurrency,
            serviceFee,
            liqReward,
            marginLoss,
            isProfit,
            value);
    }

    function bankruptedLiquidate(uint32 positionId) external override {
        ISystemSetting setting = systemSetting();
        setting.requireSystemActive();
        IDepot depot = getDepot();
        require(IERC20(fundToken()).balanceOf(msg.sender) >= setting.minFundTokenRequired(),
            "Not Meet Min Fund Token Required");

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
        require(position.account != address(0), "Position Not Match");

        uint serviceFee = position.leveragedPosition.mul(setting.positionClosingFee()) / 1e18;
        uint marginLoss = depot.calMarginLoss(position.leveragedPosition, position.share, position.direction);

        uint rateForCurrency = exchangeRates().rateForCurrencyByIdx(position.currencyKeyIdx);
        uint value = position.leveragedPosition.mul(rateForCurrency.diff(position.openPositionPrice)) / position.openPositionPrice;

        bool isProfit = (rateForCurrency >= position.openPositionPrice) == (position.direction == 1);

        if ( isProfit ) {
            require(position.margin.add(value) < serviceFee.add(marginLoss), "Position Cannot Be Bankrupted Liquidated");
        } else {
            require(position.margin < value.add(serviceFee).add(marginLoss), "Position Cannot Be Bankrupted Liquidated");
        }

        uint liquidateFee = position.margin.mul(setting.liquidationFee()) / 1e18;

        depot.bankruptedLiquidate(
            position,
            positionId,
            liquidateFee,
            marginLoss,
            msg.sender);

        emit BankruptedLiquidate(msg.sender, positionId, rateForCurrency, serviceFee, liquidateFee, marginLoss, isProfit, value);
    }

    function alertLiquidation(uint32 positionId) external override view returns (bool) {
        IDepot depot = getDepot();

        (
            address account,
            uint share,
            uint leveragedPosition,
            uint openPositionPrice,
            uint32 currencyKeyIdx,
            uint8 direction,
            uint margin,
        ) = depot.position(positionId);

        if (account != address(0)) {
            uint serviceFee = leveragedPosition.mul(systemSetting().positionClosingFee()) / 1e18;
            uint marginLoss = depot.calMarginLoss(leveragedPosition, share, direction);

            (bool isProfit, uint value) = depot.calNetProfit(currencyKeyIdx, leveragedPosition, openPositionPrice, direction);

            if (isProfit) {
                if (margin.add(value) > serviceFee.add(marginLoss)) {
                    return margin.add(value).sub(serviceFee).sub(marginLoss) < margin.mul(systemSetting().marginRatio()) / 1e18;
                }
            } else {
                if (margin > value.add(serviceFee).add(marginLoss)) {
                    return margin.sub(value).sub(serviceFee).sub(marginLoss) < margin.mul(systemSetting().marginRatio()) / 1e18;
                }
            }
        }

        return false;
    }

    function alertBankruptedLiquidation(uint32 positionId) external override view returns (bool) {
        IDepot depot = getDepot();

        (
            address account,
            uint share,
            uint leveragedPosition,
            uint openPositionPrice,
            uint32 currencyKeyIdx,
            uint8 direction,
            uint margin,
        ) = depot.position(positionId);

        if (account != address(0)) {
            uint serviceFee = leveragedPosition.mul(systemSetting().positionClosingFee()) / 1e18;
            uint marginLoss = depot.calMarginLoss(leveragedPosition, share, direction);

            (bool isProfit, uint value) = depot.calNetProfit(currencyKeyIdx, leveragedPosition, openPositionPrice, direction);

            if (isProfit) {
                return margin.add(value) < serviceFee.add(marginLoss);
            } else {
                return margin < value.add(serviceFee).add(marginLoss);
            }
        }

        return false;
    }

    event Liquidate(
        address indexed sender,
        uint32 positionId,
        uint price,
        uint serviceFee,
        uint liqReward,
        uint marginLoss,
        bool isProfit,
        uint value);

    event BankruptedLiquidate(address indexed sender,
        uint32 positionId,
        uint price,
        uint serviceFee,
        uint liqReward,
        uint marginLoss,
        bool isProfit,
        uint value);
}
