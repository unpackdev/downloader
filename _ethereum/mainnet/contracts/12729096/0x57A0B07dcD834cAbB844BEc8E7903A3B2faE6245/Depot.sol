// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.7.6;
pragma abicoder v2;

import "./SafeMath.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";

import "./IDepot.sol";
import "./IExchangeRates.sol";

import "./AddressResolver.sol";
import "./BasicMaths.sol";

contract Depot is IDepot, AddressResolver {
    using SafeMath for uint;
    using BasicMaths for uint;
    using BasicMaths for bool;
    using SafeERC20 for IERC20;

    mapping(address => uint8) public _powers;

    bool private _initialFundingCompleted = false;

    uint32 public _positionIndex = 0;
    mapping(uint32 => Position) public _positions;

    uint private _liquidityPool = 0;                // decimals 6
    uint public _totalMarginLong = 0;               // decimals 6
    uint public _totalMarginShort = 0;              // decimals 6
    uint public _totalLeveragedPositionsLong = 0;   // decimals 6
    uint public _totalLeveragedPositionsShort = 0;  // decimals 6
    uint public _totalShareLong = 0;                // decimals 18
    uint public _totalShareShort = 0;               // decimals 18
    uint public _totalSizeLong = 0;                 // decimals 18
    uint public _totalSizeShort = 0;                // decimals 18
    uint public _rebaseLeftLong = 0;                // decimals 18
    uint public _rebaseLeftShort = 0;               // decimals 18

    uint private constant E30 = 1e18 * 1e12;
    bytes32 private constant CONTRACT_EXCHANGERATES = "ExchangeRates";
    bytes32 private constant CONTRACT_BASECURRENCY = "BaseCurrency";
    bytes32 private constant CURRENCY_KEY_ETH_USDC = "ETH-USDC";

    constructor(address[] memory powers) AddressResolver() {
        _rebaseLeftLong = 1e18;
        _rebaseLeftShort = 1e18;
        for (uint i = 0; i < powers.length; i++) {
            _powers[powers[i]] = 1;
        }
    }

    function exchangeRates() internal view returns (IExchangeRates) {
        return IExchangeRates(requireAndGetAddress(CONTRACT_EXCHANGERATES, "Missing ExchangeRates Address"));
    }

    function baseCurrency() internal view returns (IERC20) {
        return IERC20(requireAndGetAddress(CONTRACT_BASECURRENCY, "Missing BaseCurrency Address"));
    }

    // decimals 6
    function _netValue(uint8 direction) internal view returns (uint) {
        if(direction == 1) {
            if(_totalShareLong == 0) {
                return 1e6;
            } else {
                return _totalLeveragedPositionsLong.mul(1e18) / _totalShareLong;
            }
        } else {
            if(_totalShareShort == 0) {
                return 1e6;
            } else {
                return _totalLeveragedPositionsShort.mul(1e18) / _totalShareShort;
            }
        }
    }

    // decimals 6
    function netValue(uint8 direction) external override view returns (uint) {
        return _netValue(direction);
    }

    // decimals 6
    function calMarginLoss(uint leveragedPosition, uint share, uint8 direction) external override view returns (uint) {
        return leveragedPosition.sub2Zero(share.mul(_netValue(direction)) / 1e18);
    }

    // decimals 6
    function calNetProfit(
        uint32 currencyKeyIdx,
        uint leveragedPosition,
        uint openPositionPrice,
        uint8 direction) external override view returns (bool, uint) {
        uint rateForCurrency = exchangeRates().rateForCurrencyByIdx(currencyKeyIdx);
        bool isProfit = ((rateForCurrency >= openPositionPrice) && (direction == 1)) ||
             ((rateForCurrency < openPositionPrice) && (direction != 1));

        return (isProfit, leveragedPosition.mul(rateForCurrency.diff(openPositionPrice)) / openPositionPrice);
    }

    function updateSubTotalState(bool isLong, uint liquidity, uint detaMargin,
        uint detaLeveraged, uint detaShare, uint rebaseLeft) external override onlyPower {
        if (isLong) {
            _liquidityPool = liquidity;
            _totalMarginLong = _totalMarginLong.sub(detaMargin);
            _totalLeveragedPositionsLong = _totalLeveragedPositionsLong.sub(detaLeveraged);
            _totalShareLong = _totalShareLong.sub(detaShare);
            _rebaseLeftLong = _rebaseLeftLong.mul(rebaseLeft) / 1e18;
            _totalSizeLong = _totalSizeLong.mul(rebaseLeft) / 1e18;
        } else {
            _liquidityPool = liquidity;
            _totalMarginShort = _totalMarginShort.sub(detaMargin);
            _totalLeveragedPositionsShort = _totalLeveragedPositionsShort.sub(detaLeveraged);
            _totalShareShort = _totalShareShort.sub(detaShare);
            _rebaseLeftShort = _rebaseLeftShort.mul(rebaseLeft) / 1e18;
            _totalSizeShort = _totalSizeShort.mul(rebaseLeft) / 1e18;
        }
    }

    function newPosition(
        address account,
        uint openPositionPrice,
        uint margin,
        uint32 currencyKeyIdx,
        uint16 level,
        uint8 direction) external override onlyPower returns (uint32) {
        require(_initialFundingCompleted, 'Initial Funding Has Not Completed');

        IERC20 baseCurrencyContract = baseCurrency();

        require(
            baseCurrencyContract.allowance(account, address(this)) >= margin,
            "BaseCurrency Approved To Depot Is Not Enough");
        baseCurrencyContract.safeTransferFrom(account, address(this), margin);

        uint leveragedPosition = margin.mul(level);
        uint share = leveragedPosition.mul(1e18) / _netValue(direction);
        uint size = leveragedPosition.mul(1e18).mul(1e12) / openPositionPrice;
        uint openRebaseLeft;

        if (direction == 1) {
            _totalMarginLong = _totalMarginLong.add(margin);
            _totalLeveragedPositionsLong = _totalLeveragedPositionsLong.add(leveragedPosition);
            _totalShareLong = _totalShareLong.add(share);
            _totalSizeLong = _totalSizeLong.add(size);
            openRebaseLeft = _rebaseLeftLong;
        } else {
            _totalMarginShort = _totalMarginShort.add(margin);
            _totalLeveragedPositionsShort = _totalLeveragedPositionsShort.add(leveragedPosition);
            _totalShareShort = _totalShareShort.add(share);
            _totalSizeShort = _totalSizeShort.add(size);
            openRebaseLeft = _rebaseLeftShort;
        }

        _positionIndex++;
        _positions[_positionIndex] = Position(
            share,
            openPositionPrice,
            leveragedPosition,
            margin,
            openRebaseLeft,
            account,
            currencyKeyIdx,
            direction);

        return _positionIndex;
    }

    function addDeposit(
        address account,
        uint32 positionId,
        uint margin) external override onlyPower {
        Position memory p = _positions[positionId];

        require(account == p.account, "Position Not Match");

        IERC20 baseCurrencyContract = baseCurrency();

        require(
            baseCurrencyContract.allowance(account, address(this)) >= margin,
            "BaseCurrency Approved To Depot Is Not Enough");
        baseCurrencyContract.safeTransferFrom(account, address(this), margin);

        _positions[positionId].margin = p.margin.add(margin);
        if (p.direction == 1) {
            _totalMarginLong = _totalMarginLong.add(margin);
        } else {
            _totalMarginShort = _totalMarginShort.add(margin);
        }
    }

    function liquidate(
        Position memory position,
        uint32 positionId,
        bool isProfit,
        uint fee,
        uint value,
        uint marginLoss,
        uint liqReward,
        address liquidator) external override onlyPower {
        uint liquidity = (!isProfit).addOrSub2Zero(_liquidityPool.add(fee), value)
                                    .sub(marginLoss.sub2Zero(position.margin));

        uint detaLeveraged = position.share.mul(_netValue(position.direction)) / 1e18;
        uint openSize = position.leveragedPosition.mul(1e30) / position.openPositionPrice;

        if (position.direction == 1) {
            _liquidityPool = liquidity;
            _totalMarginLong = _totalMarginLong.add(marginLoss).sub(position.margin);
            _totalLeveragedPositionsLong = _totalLeveragedPositionsLong.sub(detaLeveraged);
            _totalShareLong = _totalShareLong.sub(position.share);
            _totalSizeLong = _totalSizeLong.sub(openSize.mul(_rebaseLeftLong) / position.openRebaseLeft);
        } else {
            _liquidityPool = liquidity;
            _totalMarginShort = _totalMarginShort.add(marginLoss).sub(position.margin);
            _totalLeveragedPositionsShort = _totalLeveragedPositionsShort.sub(detaLeveraged);
            _totalShareShort = _totalShareShort.sub(position.share);
            _totalSizeShort = _totalSizeShort.sub(openSize.mul(_rebaseLeftShort) / position.openRebaseLeft);
        }

        baseCurrency().safeTransfer(liquidator, liqReward);
        delete _positions[positionId];
    }

    function bankruptedLiquidate(
        Position memory position,
        uint32 positionId,
        uint liquidateFee,
        uint marginLoss,
        address liquidator) external override onlyPower {
        uint liquidity = (position.margin > marginLoss).addOrSub(
            _liquidityPool, position.margin.diff(marginLoss)).sub(liquidateFee);

        uint detaLeveraged = position.share.mul(_netValue(position.direction)) / 1e18;
        uint openSize = position.leveragedPosition.mul(1e30) / position.openPositionPrice;

        if (position.direction == 1) {
            _liquidityPool = liquidity;
            _totalMarginLong = _totalMarginLong.add(marginLoss).sub(position.margin);
            _totalLeveragedPositionsLong = _totalLeveragedPositionsLong.sub(detaLeveraged);
            _totalShareLong = _totalShareLong.sub(position.share);
            _totalSizeLong = _totalSizeLong.sub(openSize.mul(_rebaseLeftLong) / position.openRebaseLeft);
        } else {
            _liquidityPool = liquidity;
            _totalMarginShort = _totalMarginShort.add(marginLoss).sub(position.margin);
            _totalLeveragedPositionsShort = _totalLeveragedPositionsShort.sub(detaLeveraged);
            _totalShareShort = _totalShareShort.sub(position.share);
            _totalSizeShort = _totalSizeShort.sub(openSize.mul(_rebaseLeftShort) / position.openRebaseLeft);
        }

        baseCurrency().safeTransfer(liquidator, liquidateFee);

        delete _positions[positionId];
    }

    function closePosition(
        Position memory position,
        uint32 positionId,
        bool isProfit,
        uint value,
        uint marginLoss,
        uint fee) external override onlyPower {
        uint transferOutValue = isProfit.addOrSub(position.margin, value).sub(fee).sub(marginLoss);
        if ( isProfit && (_liquidityPool.add(position.margin).sub(marginLoss) <= transferOutValue) ){
            transferOutValue = _liquidityPool.add(position.margin).sub(marginLoss);
        }
        baseCurrency().safeTransfer(position.account, transferOutValue);

        uint liquidityPoolVal = (!isProfit).addOrSub2Zero(_liquidityPool.add(fee), value);
        uint detaLeveraged = position.share.mul(_netValue(position.direction)) / 1e18;
        uint openSize = position.leveragedPosition.mul(1e30) / position.openPositionPrice;

        if (position.direction == 1) {
            _liquidityPool = liquidityPoolVal;
            _totalMarginLong = _totalMarginLong.add(marginLoss).sub(position.margin);
            _totalLeveragedPositionsLong = _totalLeveragedPositionsLong.sub(detaLeveraged);
            _totalShareLong = _totalShareLong.sub(position.share);
            _totalSizeLong = _totalSizeLong.sub(openSize.mul(_rebaseLeftLong) / position.openRebaseLeft);
        } else {
            _liquidityPool = liquidityPoolVal;
            _totalMarginShort = _totalMarginShort.add(marginLoss).sub(position.margin);
            _totalLeveragedPositionsShort = _totalLeveragedPositionsShort.sub(detaLeveraged);
            _totalShareShort = _totalShareShort.sub(position.share);
            _totalSizeShort = _totalSizeShort.sub(openSize.mul(_rebaseLeftShort) / position.openRebaseLeft);
        }

        delete _positions[positionId];
    }

    function addLiquidity(address account, uint value) external override onlyPower {
        _liquidityPool = _liquidityPool.add(value);
        baseCurrency().safeTransferFrom(account, address(this), value);
    }

    function withdrawLiquidity(address account, uint value) external override onlyPower {
        _liquidityPool = _liquidityPool.sub(value);
        baseCurrency().safeTransfer(account, value);
    }

    function position(uint32 positionId) external override view returns (address account, uint share, uint leveragedPosition,
        uint openPositionPrice, uint32 currencyKeyIdx, uint8 direction, uint margin, uint openRebaseLeft) {
        Position memory p = _positions[positionId];
        return (p.account, p.share, p.leveragedPosition, p.openPositionPrice, p.currencyKeyIdx, p.direction, p.margin, p.openRebaseLeft);
    }

    function initialFundingCompleted() external override view returns (bool) {
        return _initialFundingCompleted;
    }

    // decimals 6
    function liquidityPool() external override view returns (uint) {
        return _liquidityPool;
    }

    // decimals 6
    function totalLeveragedPositions() external override view returns (uint) {
        return _totalLeveragedPositionsLong.add(_totalLeveragedPositionsShort);
    }

    // decimals 6
    function totalValue() external override view returns (uint) {
        (, uint nowPrice) = exchangeRates().rateForCurrency(CURRENCY_KEY_ETH_USDC);
        return nowPrice.mul(_totalSizeLong.add(_totalSizeShort)) / E30;
    }

    function completeInitialFunding() external override onlyPower {
        _initialFundingCompleted = true;
    }

    // decimals 6
    function getTotalPositionState() external override view returns (uint, uint, uint, uint) {
        (, uint nowPrice) = exchangeRates().rateForCurrency(CURRENCY_KEY_ETH_USDC);

        uint totalValueLong = _totalSizeLong.mul(nowPrice) / E30;
        uint totalValueShort = _totalSizeShort.mul(nowPrice) / E30;
        return (_totalMarginLong, _totalMarginShort, totalValueLong, totalValueShort);
    }

    modifier onlyPower {
        require(_powers[msg.sender] == 1, "Only the contract owner may perform this action");
        _;
    }
}
